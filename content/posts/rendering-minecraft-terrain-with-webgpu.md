+++
date = 2026-04-24T16:05:24-04:00
title = "Rendering Minecraft terrain with WebGPU"
description = "A practical deep dive into building a Minecraft-style voxel renderer in the browser without sending a million cubes to the GPU."
slug = ""
authors = []
tags = ["webgpu", "graphics", "javascript", "games", "systems"]
categories = []
externalLink = ""
series = []
+++

The dumbest way to render Minecraft is also the first way everyone tries:

```js
for (const block of world) {
  drawCube(block.x, block.y, block.z, block.texture);
}
```

It is a beautiful disaster.

A 16x16x16 chunk has 4,096 blocks. Each cube has 6 faces. Each face has 2 triangles. Each triangle has 3 vertices. If you submit the world as cubes, one tiny chunk can turn into 147,456 vertices before you have drawn a tree, a cave, a torch, water, fog, or the second chunk.

Minecraft does not look expensive, which is exactly why it is a fun graphics problem. The geometry is made of boxes, but the world is huge. The hard part is not drawing one cube. The hard part is refusing to draw the millions of faces the player will never see.

WebGPU makes this more interesting because the browser now has a real modern GPU API: render pipelines, storage buffers, bind groups, compute shaders, and WGSL. You can build something that feels much closer to a native renderer than an old WebGL demo. You also get a lot more rope.

This is the renderer I would build if I wanted a Minecraft-like world running in a browser tab without cheating with a game engine.

## Start with the lie: cubes are the wrong primitive

The world is made of cubes. The renderer should not be.

The renderer should be made of **visible faces**.

If a dirt block has another dirt block directly above it, the top face is invisible. If it has neighbors on all six sides, the entire block is invisible. In a dense chunk, most blocks do not contribute any geometry.

The simplest useful mesh builder is:

```ts
const DIRECTIONS = [
  [1, 0, 0],
  [-1, 0, 0],
  [0, 1, 0],
  [0, -1, 0],
  [0, 0, 1],
  [0, 0, -1],
] as const;

function buildChunkMesh(chunk: Chunk): Mesh {
  const vertices: Vertex[] = [];
  const indices: number[] = [];

  for (let z = 0; z < 16; z++) {
    for (let y = 0; y < 16; y++) {
      for (let x = 0; x < 16; x++) {
        const block = chunk.get(x, y, z);
        if (block === AIR) continue;

        for (const dir of DIRECTIONS) {
          const neighbor = chunk.get(
            x + dir[0],
            y + dir[1],
            z + dir[2],
          );

          if (isTransparent(neighbor)) {
            pushFace(vertices, indices, x, y, z, dir, block);
          }
        }
      }
    }
  }

  return { vertices, indices };
}
```

That one change turns "draw cubes" into "draw only exposed surfaces." On a flat grass chunk, almost every underground block disappears from the mesh. The terrain still exists in the simulation data, but the GPU only sees what can matter visually.

This is the first rule of voxel rendering:

> Store the world as blocks. Render the world as surfaces.

## The chunk is the unit of sanity

Do not build one giant mesh for the whole world. Do not build one mesh per block. Both are bad.

The natural unit is a chunk:

```text
world
  chunk(-1, 0)
  chunk( 0, 0)
  chunk( 1, 0)
  chunk( 0, 1)
```

Each chunk owns:

```ts
type Chunk = {
  key: string;          // "12:-4"
  origin: Vec3;         // world-space origin
  blocks: Uint16Array;  // 16 * 16 * 16 block ids
  mesh: GpuMesh | null;
  dirty: boolean;
};
```

This gives you a clean update model:

- if a player breaks one block, mark one chunk dirty
- if the block is on a chunk boundary, mark the neighbor dirty too
- rebuild dirty meshes off the render path
- upload only the changed chunk buffers

The chunk is also the right place to do culling. If the chunk's bounding box is outside the camera frustum, skip the draw call entirely.

```ts
for (const chunk of visibleChunks(camera, world)) {
  if (!frustum.intersects(chunk.bounds)) continue;
  renderChunk(pass, chunk);
}
```

You can get surprisingly far with only face culling + chunk culling. The renderer becomes understandable before it becomes clever.

## WebGPU wants stable buffers, not chaos

In WebGL, many examples teach you to push values into global state and hope the driver forgives you. WebGPU is much more explicit.

The draw path has a few major objects:

```text
GPUDevice
  -> GPUBuffer
  -> GPUBindGroupLayout
  -> GPUBindGroup
  -> GPURenderPipeline
  -> GPUCommandEncoder
  -> GPURenderPassEncoder
```

The important mental model: pipelines describe how shaders run, bind groups describe what resources shaders can see, and command encoders record the actual work.

For a voxel renderer, I would keep the hot path boring:

```ts
function renderChunk(pass: GPURenderPassEncoder, chunk: Chunk) {
  if (!chunk.mesh) return;

  pass.setPipeline(voxelPipeline);
  pass.setBindGroup(0, frameBindGroup);
  pass.setBindGroup(1, textureBindGroup);
  pass.setVertexBuffer(0, chunk.mesh.vertexBuffer);
  pass.setIndexBuffer(chunk.mesh.indexBuffer, "uint32");
  pass.drawIndexed(chunk.mesh.indexCount);
}
```

The frame bind group contains camera data:

```wgsl
struct FrameUniforms {
  view_proj: mat4x4<f32>,
  camera_pos: vec4<f32>,
  time: f32,
};

@group(0) @binding(0)
var<uniform> frame: FrameUniforms;
```

The texture bind group contains a block atlas and sampler:

```wgsl
@group(1) @binding(0)
var blockAtlas: texture_2d<f32>;

@group(1) @binding(1)
var blockSampler: sampler;
```

Bind group layouts look ceremonial at first. They are worth it. They make resource compatibility explicit, which is exactly what you want once the renderer has terrain, water, sky, particles, and post-processing.

## Pack vertices like you mean it

A naive vertex has position, normal, UV, block id, light, and maybe color:

```ts
type FatVertex = {
  position: [number, number, number];
  normal: [number, number, number];
  uv: [number, number];
  blockId: number;
  light: number;
};
```

That is easy to write and wasteful to stream.

Voxel faces have structure. Positions are grid-aligned. Normals only have six possible values. UVs are usually corners. Block ids fit in small integers. You can pack a lot.

One practical layout:

```ts
// 16 bytes per vertex, aligned for the GPU.
type PackedVertex = {
  posAndFace: uint32;   // x:5 y:5 z:5 face:3 spare:14
  uvAndBlock: uint32;   // u:1 v:1 block:14 light:8 spare:8
  chunkOffset: uint32;  // optional local offset or material flags
  extra: uint32;        // AO, biome tint, animation flags
};
```

The shader unpacks it:

```wgsl
fn unpack_pos(v: u32) -> vec3<f32> {
  let x = f32(v & 31u);
  let y = f32((v >> 5u) & 31u);
  let z = f32((v >> 10u) & 31u);
  return vec3<f32>(x, y, z);
}
```

Do this after the first working renderer, not before. But do it eventually. Minecraft-style terrain is bandwidth-heavy. Smaller vertices mean more chunks can move through the GPU before bandwidth becomes the limit.

## Greedy meshing is the first magic trick

Face culling removes hidden faces. Greedy meshing removes unnecessary edges between visible faces.

Imagine a 16x16 floor of grass. The simple mesh emits one quad per top face: 256 quads. Greedy meshing can merge that into one large quad if all faces share the same material and lighting.

The algorithm is easiest to think about one slice at a time:

```text
for each axis:
  for each slice:
    build a 2D mask of visible faces
    merge rectangles with the same material
    emit one quad per rectangle
```

Pseudo-code:

```ts
function greedySlice(mask: FaceCell[][]) {
  for (let y = 0; y < mask.height; y++) {
    for (let x = 0; x < mask.width; x++) {
      const cell = mask[y][x];
      if (!cell) continue;

      const w = scanWidth(mask, x, y, cell);
      const h = scanHeight(mask, x, y, w, cell);

      emitQuad(x, y, w, h, cell);
      clear(mask, x, y, w, h);
    }
  }
}
```

This is where the renderer stops feeling like a toy. Flat terrain, walls, tunnels, and cliffs collapse into far fewer triangles. The world still looks blocky, but the GPU workload becomes much less silly.

There are tradeoffs:

| Technique | Good | Bad |
| --- | --- | --- |
| Per-block cubes | trivial | explodes vertex count |
| Exposed faces | simple, big win | still many quads |
| Greedy meshing | huge reduction | rebuild logic is more complex |
| Instancing blocks | simple GPU path | draws hidden faces unless paired with culling |
| GPU mesh generation | fancy, parallel | harder debugging and browser compatibility concerns |

I would start with exposed faces, then add greedy meshing when profiling says geometry is the bottleneck.

## Lighting without a real lighting engine

Voxel lighting can be fake and still look good.

The cheapest version is per-face brightness:

```ts
const FACE_LIGHT = {
  top: 1.00,
  north: 0.82,
  south: 0.82,
  east: 0.72,
  west: 0.72,
  bottom: 0.55,
};
```

That alone gives the world shape. Without it, a dirt cliff looks like a flat texture sheet.

The next step is ambient occlusion at the vertex level. For each vertex of a face, inspect the nearby side blocks and corner block. If neighboring blocks occupy the corner, darken that vertex.

```ts
function vertexAO(side1: boolean, side2: boolean, corner: boolean) {
  if (side1 && side2) return 0;
  return 3 - Number(side1) - Number(side2) - Number(corner);
}
```

The value can be packed into the vertex and applied in the fragment shader:

```wgsl
let ao = f32(vertex.ao) / 3.0;
let color = textureSample(blockAtlas, blockSampler, uv);
return color * vec4<f32>(face_light * mix(0.65, 1.0, ao));
```

This is fake, but it is the right kind of fake. It makes block intersections readable while staying deterministic and cheap.

## Texture atlases beat texture chaos

Do not bind a different texture for every block type. Use an atlas.

```text
atlas.png
  grass_top
  grass_side
  dirt
  stone
  sand
  water
```

Each face stores a tile id. The shader computes the atlas UV:

```wgsl
fn atlas_uv(tile: u32, local_uv: vec2<f32>) -> vec2<f32> {
  let tiles_per_row = 16u;
  let tile_x = tile % tiles_per_row;
  let tile_y = tile / tiles_per_row;
  let tile_size = 1.0 / f32(tiles_per_row);

  return (vec2<f32>(f32(tile_x), f32(tile_y)) + local_uv) * tile_size;
}
```

The annoying part is texture bleeding. If mipmaps sample across tile boundaries, grass can bleed into stone. The usual fixes are:

- pad each tile with duplicated edge pixels
- keep UVs slightly inside tile bounds
- generate mipmaps that respect tile padding

This is one of those details that separates "it rendered once" from "it survives movement."

## World generation is a streaming problem

Once rendering works, the next bottleneck is not shaders. It is chunk lifecycle.

The player moves. Chunks enter the view radius. Chunks leave it. Some are generated, some are meshed, some are uploaded, and some should be evicted.

The state machine is small:

```text
missing
  -> generating blocks
  -> meshing
  -> uploading
  -> resident
  -> evicting
```

The render loop should never generate terrain synchronously. It should render the chunks it already has and let workers prepare future chunks.

```ts
function tick() {
  scheduleMissingChunks(camera.position);
  uploadFinishedMeshes(device.queue);
  drawResidentChunks();
}
```

For procedural terrain, a worker can generate block arrays and build meshes without touching WebGPU. The main thread receives packed arrays and uploads them.

```ts
worker.postMessage({
  type: "build-chunk",
  chunkKey,
  seed,
});

worker.onmessage = ({ data }) => {
  pendingUploads.push(data.mesh);
};
```

This keeps camera movement smooth even when terrain generation spikes.

## Debug views are not optional

Voxel renderers fail in visual ways. You need debug views.

I would add toggles for:

- chunk boundaries
- face normals
- wireframe-ish edge overlay
- chunk mesh triangle count
- culled vs drawn chunks
- texture tile id
- ambient occlusion value
- rebuild queue length

The most useful overlay is usually boring:

```text
chunks: 289 resident / 74 drawn
triangles: 118,432
dirty chunks: 3
mesh upload: 1.8 ms
frame: 11.4 ms
```

If a mountain tanks the frame rate, I want to know whether the problem is triangle count, upload churn, shader cost, or chunk scheduling. Guessing from visuals is a waste of time.

## What I would not optimize first

There are many tempting rabbit holes:

- GPU-driven meshing
- sparse voxel octrees
- clipmaps
- bindless-style material systems
- compute-generated indirect draw calls
- raymarching the world instead of rasterizing it

All of those are interesting. Most are the wrong first move.

The boring renderer gets you far:

1. chunked block storage
2. exposed-face meshing
3. texture atlas
4. camera uniforms
5. per-face light
6. frustum culling
7. worker-based mesh generation
8. greedy meshing
9. ambient occlusion
10. debug overlays

At that point you have enough measurements to decide whether the next trick is worth it.

## A tiny WebGPU render skeleton

The render loop shape is straightforward:

```ts
const encoder = device.createCommandEncoder();
const pass = encoder.beginRenderPass({
  colorAttachments: [{
    view: context.getCurrentTexture().createView(),
    clearValue: { r: 0.55, g: 0.75, b: 1.0, a: 1.0 },
    loadOp: "clear",
    storeOp: "store",
  }],
  depthStencilAttachment,
});

pass.setPipeline(voxelPipeline);
pass.setBindGroup(0, frameBindGroup);
pass.setBindGroup(1, textureBindGroup);

for (const chunk of visibleChunks) {
  pass.setVertexBuffer(0, chunk.vertexBuffer);
  pass.setIndexBuffer(chunk.indexBuffer, "uint32");
  pass.drawIndexed(chunk.indexCount);
}

pass.end();
device.queue.submit([encoder.finish()]);
```

The code is not the hard part. The hard part is making sure the loop is only drawing geometry that deserves to exist.

## The fun part

The fun part is that the renderer can stay simple and still feel impossible.

You open a browser tab. It asks the GPU for a device. JavaScript generates terrain. A worker crushes block arrays into greedy quads. WGSL shades grass and stone. The camera flies through a world made of tiny integer decisions.

No install. No native binary. No engine. Just a tab pretending to be a voxel game.

That is why WebGPU is exciting. It makes the browser feel less like a document viewer and more like a weird little operating system for graphics experiments.

## References

- [MDN WebGPU API](https://developer.mozilla.org/en-US/docs/Web/API/WebGPU_API) - overview of devices, buffers, bind groups, compute pipelines, and render pipelines.
- [Chrome for Developers: From WebGL to WebGPU](https://developer.chrome.com/docs/web-platform/webgpu/from-webgl-to-webgpu) - useful comparison of WebGL and WebGPU concepts, including storage buffers.
- [Chrome for Developers: GPU compute on the web](https://developer.chrome.com/docs/capabilities/web-apis/gpu-compute) - introductory compute shader and storage buffer examples.
- [WebGPU Fundamentals: bind group layouts](https://webgpufundamentals.org/webgpu/lessons/webgpu-bind-group-layouts.html) - clear explanation of pipeline layouts and bind group compatibility.
- [WebGPU is now supported in major browsers](https://web.dev/blog/webgpu-supported-major-browsers) - browser support context and why WebGPU matters for graphics and compute.
