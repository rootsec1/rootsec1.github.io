+++
date = 2026-04-24T16:05:24-04:00
title = "XLSX files are little filesystems"
description = "A deep dive into opening an Excel workbook like a ZIP archive, parsing the XML parts, rebuilding the sheet grid, and discovering why comments, formulas, styles, and merged cells are stranger than they look."
slug = ""
authors = []
tags = ["excel", "xml", "go", "python", "reverse-engineering"]
categories = []
externalLink = ""
series = []
+++

The first surprising thing about an `.xlsx` file is that it is not really a file.

It is a ZIP archive wearing a spreadsheet costume.

Rename `budget.xlsx` to `budget.zip`, unzip it, and the workbook falls open into a small filesystem:

```text
budget.xlsx
  [Content_Types].xml
  _rels/.rels
  xl/
    workbook.xml
    _rels/workbook.xml.rels
    worksheets/sheet1.xml
    worksheets/_rels/sheet1.xml.rels
    sharedStrings.xml
    styles.xml
    comments1.xml
    drawings/vmlDrawing1.vml
```

That is the moment Excel stops being "a grid" and starts looking like a tiny operating system. There is a package manifest, relationship graph, string table, style table, worksheet storage, drawing layer, comments subsystem, formulas, dimensions, merged ranges, hyperlinks, and sometimes a pile of legacy VML that refuses to die.

I like this kind of file format because it looks boring until you try to build anything real with it. Reading a cell value is easy. Rendering a workbook, validating comments, preserving formulas, or producing a stable diff is where the weirdness starts.

This is the mental model I use for working with `.xlsx` files without pretending Excel is simpler than it is.

## Start by treating the workbook as a package

The naive way to parse a workbook is to jump straight into `xl/worksheets/sheet1.xml`.

That works for toy files. It fails as soon as sheet names, relationships, shared strings, comments, drawings, or external links enter the picture.

The package has a graph. Follow it.

```text
_rels/.rels
  -> xl/workbook.xml

xl/workbook.xml
  -> sheet metadata

xl/_rels/workbook.xml.rels
  -> worksheets/sheet1.xml
  -> sharedStrings.xml
  -> styles.xml
```

The relationship files are not decoration. They are the pointers that tell you what each part means.

```xml
<Relationship
  Id="rId1"
  Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"
  Target="worksheets/sheet1.xml" />
```

The workbook points at a sheet by relationship id:

```xml
<sheet
  name="Summary"
  sheetId="1"
  r:id="rId1" />
```

So a real parser starts with a package index:

```python
from zipfile import ZipFile
from xml.etree import ElementTree as ET

def load_package(path):
    with ZipFile(path) as z:
        return {
            name: z.read(name)
            for name in z.namelist()
            if name.endswith((".xml", ".rels", ".vml"))
        }
```

Then it resolves relationships instead of guessing paths:

```python
def relationships(package, rels_path):
    root = ET.fromstring(package[rels_path])
    out = {}
    for rel in root:
        rid = rel.attrib["Id"]
        out[rid] = {
            "type": rel.attrib["Type"],
            "target": rel.attrib["Target"],
        }
    return out
```

That tiny indirection saves you from a long list of bad assumptions.

## Cells are sparse, not rectangular

A worksheet XML file does not store a nice 2D array. It stores the cells that exist.

```xml
<sheetData>
  <row r="1">
    <c r="A1" t="s"><v>0</v></c>
    <c r="C1"><v>42</v></c>
  </row>
</sheetData>
```

There is no `<c r="B1">`. It is absent.

That means the in-memory model should not start as `rows x cols`. It should start as a sparse map:

```ts
type CellRef = string; // "C12"

type Cell = {
  ref: CellRef;
  row: number;
  col: number;
  type: "number" | "shared-string" | "inline-string" | "formula" | "blank";
  raw: string | null;
  styleId: number | null;
  formula: string | null;
};

type Sheet = {
  name: string;
  cells: Map<CellRef, Cell>;
  merges: Range[];
};
```

A grid view can be derived later. The file format itself is sparse.

This matters for performance too. A workbook can claim a large dimension and still contain relatively few real cells. If you allocate the rectangle first, malicious or just ugly workbooks can waste a surprising amount of memory.

## Shared strings are a global dictionary

Strings often do not live inside cells. They live in `xl/sharedStrings.xml`.

```xml
<sst count="2" uniqueCount="2">
  <si><t>Revenue</t></si>
  <si><t>Margin</t></si>
</sst>
```

The worksheet cell stores an index:

```xml
<c r="A1" t="s">
  <v>0</v>
</c>
```

So `A1` means "look up string 0." If you render the sheet without resolving shared strings, the workbook looks like it is full of random integers.

The resolver is simple:

```python
def cell_text(cell, shared_strings):
    cell_type = cell.get("t")
    value = cell.findtext("main:v", namespaces=NS)

    if value is None:
        return ""

    if cell_type == "s":
        return shared_strings[int(value)]

    return value
```

The annoying part is rich text. A shared string item can contain multiple runs:

```xml
<si>
  <r><rPr><b /></rPr><t>Total</t></r>
  <r><t> revenue</t></r>
</si>
```

If you only read direct `<t>` nodes, you lose text. If you flatten all text nodes, you keep the value but lose formatting. Both may be correct depending on whether you are building a data extractor or a visual renderer.

That is a recurring theme with Excel: every "simple" field has at least two meanings.

## Styles are indexes into indexes

Cell formatting is not stored as direct CSS-like properties on the cell.

A cell has a style id:

```xml
<c r="B2" s="5"><v>1234.5</v></c>
```

That points into `styles.xml`, where `cellXfs` points at font ids, fill ids, border ids, number format ids, alignment settings, and protection flags.

```xml
<xf
  numFmtId="4"
  fontId="2"
  fillId="0"
  borderId="1"
  applyNumberFormat="1" />
```

So rendering one cell can require walking a small object graph:

```text
cell.s = 5
  -> cellXfs[5]
    -> numFmtId = 4
    -> fontId = 2
    -> borderId = 1
    -> fillId = 0
```

That is why "just read the value" and "show what Excel shows" are different problems.

For example, the raw value may be:

```text
45123
```

But with a date number format it should render like:

```text
Jul 16, 2023
```

Or the raw value may be:

```text
0.142
```

But the displayed value should be:

```text
14.2%
```

A useful renderer keeps both:

```ts
type RenderedCell = {
  ref: string;
  rawValue: string | null;
  displayValue: string;
  style: ResolvedStyle;
};
```

If you throw away the raw value, formulas and diffs become worse. If you throw away the display value, humans cannot read the output.

## Formulas are source code with cached output

A formula cell can contain both the formula and the last calculated value:

```xml
<c r="C10">
  <f>SUM(C2:C9)</f>
  <v>9123</v>
</c>
```

The `<f>` is the source code. The `<v>` is the cached result.

That distinction matters. A library that edits inputs might not recalculate formulas. Excel may recalculate when the file opens, or it may trust cached values depending on workbook settings.

For an inspector, I want to show both:

```text
C10
  formula: =SUM(C2:C9)
  cached:  9123
```

For a writer, I want an explicit policy:

| Policy | Behavior |
| --- | --- |
| preserve | keep formula and cached value |
| clear cache | keep formula, remove cached value |
| value only | replace formula with literal |
| recalc engine | evaluate and write new cached value |

The dangerous path is accidentally converting formulas into stale constants. That kind of bug can survive for months because the sheet still opens and the number still looks plausible.

## Merged cells are a visual trick

Merged cells look like one cell. In the file, they are a range overlay:

```xml
<mergeCells count="1">
  <mergeCell ref="A1:D1" />
</mergeCells>
```

Usually the value lives in the top-left cell. The other cells in the range may not exist at all.

For rendering, you need to expand the merge region:

```ts
function ownerOf(ref: CellRef, merges: Range[]) {
  for (const merge of merges) {
    if (merge.contains(ref)) {
      return merge.topLeft;
    }
  }
  return ref;
}
```

For data extraction, you have to be careful. If a merged header spans `A1:D1`, should it apply to all four columns? Visually yes. Structurally, the file only says "these cells are merged."

Excel lets users encode meaning with layout. Machines then have to reverse engineer that meaning from geometry.

## Comments live in two worlds

Comments are where `.xlsx` gets especially weird.

The comment text can live in `comments1.xml`:

```xml
<comment ref="B12" authorId="0">
  <text>
    <r><t>Check this assumption</t></r>
  </text>
</comment>
```

But the visible comment box may be described by a VML drawing:

```xml
<v:shape id="_x0000_s1025" type="#_x0000_t202">
  <x:ClientData ObjectType="Note">
    <x:Row>11</x:Row>
    <x:Column>1</x:Column>
  </x:ClientData>
</v:shape>
```

So a workbook can have comment text without a proper shape, or a shape that does not line up with the comment. Some apps tolerate this. Some repair the file. Some silently drop the visual artifact.

If you care about producing workbooks that survive Excel, validators should inspect both layers:

```text
worksheet relationships
  -> comments XML
  -> VML drawing
  -> cell references
  -> row/column anchors
```

A comment validator might emit:

```json
{
  "sheet": "Summary",
  "cell": "B12",
  "text": true,
  "vml_shape": false,
  "severity": "warning"
}
```

This is the part of Excel automation that feels like archaeology. A modern `.xlsx` file can still require understanding a legacy drawing format because users expect a little yellow note to show up in the right place.

## Rendering is a pipeline, not a parser

Once you account for all of this, a workbook renderer starts looking like a compiler pipeline:

```text
zip package
  -> content type index
  -> relationship graph
  -> workbook metadata
  -> sheet XML
  -> shared strings
  -> styles
  -> comments and drawings
  -> sparse cell model
  -> resolved display model
  -> visual grid
```

The intermediate representation matters. If you go directly from XML nodes to HTML table cells, every later feature becomes a patch.

I like this split:

```ts
type WorkbookPackage = {
  parts: Map<string, Uint8Array>;
  relationships: RelationshipIndex;
};

type WorkbookModel = {
  sheets: SheetModel[];
  sharedStrings: string[];
  styles: StyleTable;
};

type RenderModel = {
  sheets: RenderSheet[];
  warnings: RenderWarning[];
};
```

Warnings are first-class. Real workbooks are messy. A renderer that only returns "success" or "failed" is not giving you enough information.

Useful warning classes:

| Warning | Meaning |
| --- | --- |
| missing relationship | XML points at a part that does not exist |
| unknown style id | cell references a style outside the table |
| unsupported number format | raw value shown without full formatting |
| comment without shape | text exists but visual note may not render |
| formula cache stale | formula and cached value may disagree |
| merge conflict | overlapping merge ranges |

Warnings let you build tools that are honest without being fragile.

## The debugging trick: explode the workbook

When a workbook looks wrong, I do not start with Excel. I start by exploding the ZIP.

```bash
mkdir /tmp/book
unzip report.xlsx -d /tmp/book
find /tmp/book/xl -maxdepth 3 -type f | sort
```

Then inspect the exact part:

```bash
python -m xml.dom.minidom /tmp/book/xl/worksheets/sheet1.xml | less
```

For comments:

```bash
python -m xml.dom.minidom /tmp/book/xl/comments1.xml | less
python -m xml.dom.minidom /tmp/book/xl/drawings/vmlDrawing1.vml | less
```

For styles:

```bash
python -m xml.dom.minidom /tmp/book/xl/styles.xml | less
```

This is faster than guessing. Excel is a GUI over a package. If the GUI is confusing, inspect the package.

## What makes this fun

The fun part is that `.xlsx` sits in a strange middle ground.

It is a user-facing document format, but it behaves like a miniature application bundle. It has source code, cached execution output, layout instructions, shared resources, relationship graphs, compatibility layers, and rendering quirks accumulated over years.

That makes it a great engineering playground:

- ZIP parsing
- XML namespaces
- sparse data structures
- graph resolution
- rendering
- validation
- compatibility archaeology
- performance tuning
- diffing and golden fixtures

It is not glamorous in the way a shader demo is glamorous. It is glamorous in the way a weird machine is glamorous: the more panels you remove, the more mechanisms you find.

## Conclusion

If you want to work seriously with Excel files, stop thinking of them as tables.

Think of them as little filesystems with a spreadsheet UI on top.

That mental model changes how you build tools. You follow relationships instead of guessing paths. You keep sparse cells sparse. You resolve shared strings and styles explicitly. You treat formulas as source code plus cached output. You validate comments across both XML and VML. You build a render model instead of stitching strings into an HTML table.

The reward is control. Once the workbook is a package, not a mystery, you can inspect it, render it, diff it, repair it, and generate it without hoping Excel forgives you.

## References

- [ECMA-376 Office Open XML](https://ecma-international.org/publications-and-standards/standards/ecma-376/) - the standard behind modern Office Open XML packages.
- [Microsoft Learn: Structure of a SpreadsheetML document](https://learn.microsoft.com/en-us/office/open-xml/spreadsheet/structure-of-a-spreadsheetml-document) - workbook, worksheet, shared string, and style part structure.
- [Microsoft Learn: Working with sheets](https://learn.microsoft.com/en-us/office/open-xml/spreadsheet/working-with-sheets) - how sheets are represented and related in Open XML.
- [Microsoft Learn: Working with comments](https://learn.microsoft.com/en-us/office/open-xml/spreadsheet/working-with-comments) - SpreadsheetML comments and comment authors.
- [Excelize documentation](https://xuri.me/excelize/) - a Go library for reading and writing XLSX files.
