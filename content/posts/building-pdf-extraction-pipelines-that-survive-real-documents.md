+++
date = 2026-05-23T21:22:16-04:00
title = "Durable OCR pipelines with Restate, Rust, and agent workers"
description = "A deep dive into building page-level document pipelines that survive large PDFs, OCR provider failures, retry storms, agent handoffs, and debugging at scale."
slug = ""
authors = []
tags = ["AI", "python", "rust", "infra", "architecture"]
categories = []
externalLink = ""
series = []
+++

Most document extraction systems start life as a three-line demo:

```python
text = pdf.extract_text()
result = model.extract(schema, text)
save(result)
```

That demo is useful because it proves the shape of the product. It is also where the architecture usually starts lying to you.

The real system is not "PDF in, JSON out". It is a distributed rendering, OCR, indexing, retrieval, agent execution, validation, and evaluation pipeline with unreliable inputs at every layer. The failure modes are not just "the model got the answer wrong". They are:

- the PDF has 180 pages and half of them are scans
- the text layer exists but the reading order is unusable
- a provider returns great table cells but times out on dense pages
- a fallback model reads the page but loses bounding boxes
- retries race with the first invocation and perform duplicate OCR
- one CPU-heavy render blocks the worker long enough for the orchestrator to think it died
- the agent solves the workbook, but you cannot prove which page supported a value

The unit of design has to change. I would not build this as a document pipeline. I would build it as a **page pipeline** with durable orchestration around it.

## The architecture

The core shape looks like this:

```text
uploaded PDF
  -> stable document id
  -> Rust/PyO3 page renderer
  -> page image artifacts
  -> OCR readiness check
  -> one durable OCR workflow per page
  -> normalized block + bbox store
  -> source catalog
  -> agent workspace
  -> solver / reviewer / evaluator agents
  -> trace report + structured output
```

This is more moving parts than the demo. It is also simpler operationally because every expensive or unreliable step now has a stable boundary.

| Boundary | Key | Artifact | Retry behavior |
| --- | --- | --- | --- |
| PDF render | document id + render profile | `page-001.png` | repeatable, CPU-bound |
| Page OCR | page id + OCR profile | text blocks + bounding boxes | dedupe by page |
| Source catalog | document id + extraction version | chunks, bboxes, page URLs | append or replace version |
| Agent workspace | execution id | deterministic file tree | resumable across runners |
| Evaluation | execution id + fixture version | report, diffs, traces | replayable |

The important decision is making the page the smallest expensive unit. PDFs are too coarse. Words are too fine. Pages are the level where rendering, OCR, visual evidence, and concurrency all line up.

## Rendering pages is not boring plumbing

I used to think PDF rendering was an implementation detail. It is not.

If the OCR provider wants images, you have to turn PDF pages into PNGs. Doing that inside a Python web worker seems fine until a large document hits the service. The path is usually:

```python
page_images = render_pages(
    pdf_bytes,
    dpi=150,
)
upload(page_images)
```

That hides three separate resource problems:

1. Rendering is CPU-heavy.
2. Image bytes can get huge at high DPI.
3. Python workers still need to respond to health checks, keep-alives, and orchestration calls while rendering runs.

A better implementation is a Rust extension called from Python:

```rust
let threads = min(cpu_budget(), page_count);
let chunk_size = page_count.div_ceil(threads);

let results = py.allow_threads(|| {
    thread_pool.install(|| {
        page_chunks
            .into_par_iter()
            .map(|pages| {
                render_chunk(
                    pdf_bytes.clone(),
                    pages,
                    target_dpi,
                )
            })
            .collect::<Vec<_>>()
    })
});
```

The details matter:

- bound the Rayon thread pool instead of blindly using every core
- compute a worker budget from container CPU limits, not laptop assumptions
- sort rendered page results before returning them
- reduce DPI when an encoded page image would exceed a payload limit
- release the Python GIL during the Rust/Rayon phase

That last point is the sort of issue that only shows up under real pressure. If a Python worker calls into Rust and the extension holds the GIL for the entire render, the asyncio loop can stop making progress. The render may still be "fast" in isolation, but the service around it becomes unhealthy. Keep-alive pings miss. The durable runtime retries. Now you have a rendering problem pretending to be a workflow problem.

The test for this is not a golden image snapshot. It is a heartbeat test:

```python
async def test_renderer_keeps_loop_alive():
    pdf = make_large_pdf(page_count=80)
    heartbeats = []

    async def heartbeat():
        while not done.is_set():
            heartbeats.append(time.monotonic())
            await asyncio.sleep(0.05)

    extraction = loop.run_in_executor(
        pool,
        render_pdf_pages,
        pdf,
    )
    await asyncio.gather(
        heartbeat(),
        extraction,
    )

    assert max_gap(heartbeats) < 1_000  # ms
```

This catches the actual class of failure: CPU-bound native code starving the Python runtime around it.

## Upload pages in batches, not in a loop

After rendering, each page should become an addressable artifact:

```text
documents/{document_id}/pages/page-001.png
documents/{document_id}/pages/page-002.png
documents/{document_id}/pages/page-003.png
```

The naive upload loop is easy:

```python
for page in pages:
    await upload(page)
```

At scale, this creates two problems. It underutilizes the network for big documents, and it gives you terrible partial-failure behavior. I prefer fixed-size batches with a bounded fan-out:

```python
batch_futures = [
    upload_page_batch(ctx, batch)
    for batch in chunked(
        page_images,
        batch_size=50,
    )
]

completed = await restate_gather(*batch_futures)
```

The batch size becomes a real tuning knob. Too small and overhead dominates. Too large and one failed upload retries too much work. The page count and total output bytes should be span tags, not log trivia:

```text
pdf.download       input_bytes=18_423_311
pdf.render_pages   pages=173 split_ms=42_810
pdf.upload_batch   bytes=97_044_182
pdf.upload_batch   upload_ms=8_902
```

Those three numbers explain most performance incidents in this part of the system.

## OCR readiness is a state machine

Once pages exist, the next mistake is to run OCR for every page every time. That is expensive and makes retries noisy.

The readiness function should answer a narrower question:

> For this request, which page ids still lack acceptable OCR artifacts?

That means the system checks existing state before it does work:

```python
async def ensure_pages_ocr_ready(ctx, page_ids):
    unique_page_ids = dedupe(page_ids)

    existing = await ctx.run(
        "check-existing-ocr",
        lambda: db.fetch_pages_with_ocr(
            unique_page_ids,
        ),
    )

    missing = [
        page_id
        for page_id in unique_page_ids
        if page_id not in existing
    ]

    for batch in chunked(missing, size=64):
        await restate_gather(*[
            perform_page_ocr(ctx, page_id)
            for page_id in batch
        ])

    return unique_page_ids
```

There are two subtle but important choices here.

First, dedupe page ids before dispatch. A source catalog, a user selection, and an agent request can all point at the same page. The OCR layer should not care how many upstream paths reached it.

Second, treat "OCR workflow already exists" as a success path with waiting, not as an error. In a distributed system, two callers will eventually ask for the same page at the same time. One should win. The other should poll for the resulting OCR chunks and continue.

```python
try:
    await start_ocr_workflow(page_id)
except AlreadyInvoked:
    await wait_until(
        lambda: ocr_chunks_exist(page_id),
        timeout=120,
    )
```

That one branch prevents retry storms from becoming duplicate provider bills.

## Provider fallback is a capability problem

OCR providers are not interchangeable. Some are better at dense tables. Some preserve bounding boxes more reliably. Some handle watermarks. Some are cheaper. Some are more available.

So the abstraction should not be:

```python
class OcrProvider:
    async def extract(image: bytes) -> str: ...
```

That throws away the only facts that matter. I want the interface to expose capabilities and return normalized blocks:

```python
class OcrProvider(Protocol):
    name: str
    timeout: timedelta
    capabilities: set[Capability]

    async def extract(
        self,
        image: bytes,
    ) -> list[Block]:
        ...

@dataclass(frozen=True)
class Block:
    text: str
    kind: BlockKind
    page: int
    bbox: BBox
    confidence: float | None
```

Then routing becomes explicit:

```python
required = {Capability.TABLE_BBOX}
primary = registry.match(required)
fallback = registry.rest(primary)

for provider in [*primary, *fallback]:
    try:
        blocks = await ctx.run(
            f"ocr-{provider.name}",
            lambda: provider.extract(image),
        )
        return normalize(blocks)
    except ProviderFailed:
        continue

raise TerminalError("ocr failed")
```

The `ctx.run` boundary is non-negotiable. OCR is an external side effect. If the worker dies after the provider returns but before the workflow completes, replay should use the journaled provider result instead of charging the provider again.

I also like a two-stage model fallback for pages that look table-heavy:

```text
cheap vision pass:
  "Is this page mostly a dense table?"

if yes:
  use stricter table prompt
  use stronger model
else:
  use normal block extraction prompt
```

The goal is not to build a clever router. The goal is to pay for the expensive path only when the page shape justifies it.

## Store evidence, not just answers

The output of OCR should not be a blob of text. It should be a source catalog:

```json
{
  "chunk_id": "chunk_742",
  "page_id": "page_018",
  "page_number": 18,
  "text": "Revenue increased 14.2%",
  "bbox": {
    "left": 0.12,
    "top": 0.44,
    "width": 0.51,
    "height": 0.03
  },
  "source_image": "pages/page-018.png",
  "provider": "layout-ocr",
  "profile": "ocr-v7"
}
```

This is what makes the rest of the system debuggable. When an agent writes `14.2%` into a spreadsheet, I want the reviewer to be able to click the value and see the exact page crop that supported it.

Flattened text is fine for search. It is not enough for trustworthy automation.

## Agent workers need stable workspaces

Once the source catalog exists, agents can do the higher-level work: fill a model, reconcile a workbook, produce a narrative summary, or inspect conflicts. The agent should not be handed random signed URLs and a giant prompt. It should get a stable workspace.

```text
input/
  document.pdf
  pages/
    page-001.png
    page-002.png
  sources/
    chunks.jsonl
    bboxes.jsonl
  task.md

output/
  answer.xlsx
  notes.md
```

The file references inside that workspace should be deterministic. If the primary runner fails and the job moves to a fallback runner, the same logical inputs should appear at the same paths. Otherwise, retries turn into prompt drift.

The orchestration layer should also treat agent runners like providers:

```python
for attempt in failover_chain:
    prompt = render_prompt(
        driver=attempt.driver,
        workspace=workspace,
    )

    try:
        result = await run_agent_with_retries(
            attempt=attempt,
            prompt=prompt,
            workspace=workspace,
        )
        return result
    except RetryableAgentFailure:
        await ctx.sleep(backoff(attempt))
        continue
```

A fallback runner may need a different prompt shape or tool envelope. Re-rendering the prompt per runner is cleaner than pretending every agent runtime speaks the same dialect.

The useful thing here is not "multi-agent" as a buzzword. It is separating roles:

| Role | Job |
| --- | --- |
| OCR worker | produce page-grounded evidence |
| Solver agent | complete the user-facing artifact |
| Reviewer agent | verify evidence and catch contradictions |
| Evaluator | compare traces and outputs against fixtures |

That split lets you improve one role without rewriting the entire pipeline.

## Durable execution changes how you write code

Restate is useful here because document pipelines are full of long-running steps and external side effects. The mental model is that every meaningful operation either becomes a journaled durable step or remains deterministic code that can safely replay.

That changes small coding habits:

```python
# Good: external I/O is journaled
ocr_blocks = await ctx.run(
    "provider-ocr",
    call_provider,
)

# Good: durable sleep, not asyncio.sleep
await ctx.sleep(timedelta(seconds=10))

# Good: Restate-aware gather
results = await restate_gather(*page_workflows)
```

The anti-pattern is hiding orchestration inside a durable step:

```python
# Bad: ctx operations inside ctx.run
await ctx.run(
    "do-everything",
    lambda: start_child_workflow(ctx, page_id),
)
```

Durable execution is not magic. It rewards boring boundaries. Provider calls, DB writes, blob uploads, and notification sends get wrapped. Pure transformations stay pure. Child workflows stay visible as child workflows.

When this discipline is followed, a crash during a 170-page document is annoying but not mysterious. The workflow resumes from the journal. Already-uploaded pages remain uploaded. Already-completed OCR calls are not repeated. In-flight child workflows can be attached to, waited on, or observed.

## Evaluation has to include the trace

For agentic document systems, evaluating only the final answer is too weak.

Imagine a workbook cell is correct:

```text
Revenue growth = 14.2%
```

That can still hide bad behavior:

- the agent copied the value from a nearby example
- it used the wrong document version
- it ignored a contradicting footnote
- it got lucky because the fixture was easy
- it wrote the right number but left no evidence trail

I want eval reports that include:

```text
final output diff
stdout / stderr timeline
tool calls
source chunks used
page crops referenced
provider fallback path
agent runner attempts
elapsed time by phase
```

This makes regressions much easier to reason about. A model upgrade that keeps accuracy flat but doubles fallback usage is not free. A prompt change that improves one fixture by reading entire PDFs instead of using source chunks may be worse operationally.

## Metrics I would page on

The dashboard for this system should be built around phase behavior, not just request success rate.

| Metric | Why I care |
| --- | --- |
| render time per page | catches pathological PDFs and CPU starvation |
| rendered bytes per page | catches DPI and payload explosions |
| OCR reuse rate | measures whether dedupe/idempotency works |
| OCR provider fallback rate | detects quality or availability drift |
| duplicate invocation waits | shows concurrent demand for same page |
| source chunks per page | catches over/under segmentation |
| agent retry count | detects flaky runners or weak prompts |
| eval pass rate by fixture family | prevents silent degradation |
| evidence coverage | tells whether answers are grounded |

The last one matters the most. If a system produces polished artifacts without evidence coverage, it is just automation theater.

## Tests that pay for themselves

The tests for this kind of pipeline should look like production incidents in miniature.

```text
[x] large PDF render keeps the event loop alive
[x] upload batching preserves page order
[x] OCR readiness skips existing chunks
[x] duplicate OCR waits for the winner
[x] provider failure falls through
[x] fallback result normalizes
[x] replay does not repeat side effects
[x] failover recreates the workspace
[x] eval includes diff and evidence
```

The point is not high coverage for its own sake. The point is to encode the failures that are expensive to rediscover.

## The part that feels counterintuitive

The more agentic the system becomes, the more deterministic the infrastructure around it needs to be.

Agents are useful because they can handle messy tasks. They are also harder to reason about than normal code. So the surrounding system should remove as much ambiguity as possible:

- stable page ids
- stable workspace paths
- explicit provider capabilities
- bounded concurrency
- journaled side effects
- source-grounded outputs
- replayable eval traces

That is the actual architecture. Not "use OCR". Not "use an LLM". Not "add retries". The system works when every expensive action has a durable identity, every answer has evidence, and every fallback leaves a trace.

## References

- [Restate durable steps for Python](https://docs.restate.dev/develop/python/journaling-results/) - durable `ctx.run` boundaries and replay behavior.
- [Restate durable execution overview](https://www.restate.dev/what-is-durable-execution/) - the execution log model behind retries and recovery.
- [PyO3 parallelism guide](https://pyo3.rs/v0.25.0/parallelism) - releasing the GIL around Rust parallel work.
- [Rayon `ThreadPoolBuilder`](https://docs.rs/rayon/latest/rayon/struct.ThreadPoolBuilder.html) - explicit thread pool sizing for CPU-heavy work.
- [PyMuPDF `Page.get_pixmap`](https://pymupdf.readthedocs.io/en/latest/page.html) - rendering PDF pages with DPI and pixmap controls.
- [OpenTelemetry context propagation](https://opentelemetry.io/docs/concepts/context-propagation/) - carrying trace context across service boundaries.
- [Gemini structured output docs](https://ai.google.dev/gemini-api/docs/structured-output) - schema-constrained model outputs and their limits.
- [Reducto parse documentation](https://docs.reducto.ai/parse/overview) - an example of document parsing APIs that preserve layout chunks and tables.
