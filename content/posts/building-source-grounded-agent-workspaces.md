+++
date = 2026-04-24T16:05:24-04:00
title = "Every spreadsheet agent needs a black box recorder"
description = "A deep dive into building flight-recorder-style workspaces for document agents: source catalogs, chunk-level evidence, workbook citations, trace graphs, and evals that catch polished wrong answers."
slug = ""
authors = []
tags = ["AI", "python", "typescript", "observability", "infra"]
categories = []
externalLink = ""
series = []
+++

A spreadsheet agent can crash loudly, or it can do something much worse: produce a beautiful workbook full of numbers that no one can prove.

That second failure is the scary one. The formatting is clean. The formulas recalculate. The executive summary sounds confident. The file looks like it came from someone who knew what they were doing.

Then someone asks the only question that matters:

> Which source page supports this value?

If the answer is "the model probably saw it in the prompt", the system is not production-ready. It is a demo with file I/O.

The fix is not a bigger prompt. It is a black box recorder.

For document-heavy workflows, every generated artifact needs a flight record: what sources were loaded, which chunks were used, which tools ran, which cells were written, which citations survived validation, and what changed between runs. A value is not just `14.2`. It is:

- the value
- the source document
- the page or sheet
- the chunk id
- the bounding box
- the transformation that produced the final cell
- the trace that explains which tool or agent wrote it

That sounds heavy until the first incident. Without that structure, debugging becomes archaeology. With it, the system can answer the operational questions that actually matter: what changed, what evidence was used, what was skipped, and whether a retry would reproduce the same output.

## The version that looks fine until it doesn't

The first version usually looks like this:

```text
input/
  document.pdf
  template.xlsx

output/
  completed.xlsx
```

The agent prompt says something like:

```text
Read the source document, fill the spreadsheet, and cite your sources.
```

This works on small examples. It fails when the workflow becomes long-running, multi-step, or rerunnable.

The weak points show up quickly:

| Failure | What it looks like |
| --- | --- |
| Source drift | rerun uses a newer file with the same display name |
| Citation drift | final cell cites a row label instead of the numeric value |
| Workspace drift | fallback runner sees different paths than the first runner |
| Trace gaps | output exists but no one knows which step wrote it |
| Eval blindness | final value is correct but came from the wrong source |
| Privacy risk | debug export includes local secrets or unrelated files |

The common root cause is that the workspace treats files as unstructured context. A production workspace needs to behave less like a folder and more like an investigation kit: explicit identity, stable paths, typed evidence, and reproducible views over the same inputs.

## Build the evidence catalog first

The smallest useful unit is not a document. It is not a sentence either. It is usually a chunk with position and lineage.

For a PDF page, a chunk might be a paragraph, table cell, or detected heading. For a spreadsheet, it might be an original cell, merged range, or named table region. The important part is that every chunk has a durable id and enough metadata to recover what the user would see.

```json
{
  "chunk_id": "chunk_018_0042",
  "document_id": "doc_123",
  "document_name": "board_deck_q3.pdf",
  "page_number": 18,
  "kind": "TABLE_CELL",
  "text": "Revenue growth",
  "normalized_text": "revenue growth",
  "bbox": {
    "x": 0.12,
    "y": 0.41,
    "w": 0.18,
    "h": 0.03
  },
  "extractor": "layout_ocr_v5",
  "source_sha256": "b7f4..."
}
```

This is the difference between "the agent read the PDF" and "the agent used `chunk_018_0042` from `doc_123`." The latter can be indexed, validated, rendered as a crop, attached to a workbook comment, and compared across runs.

The workspace then becomes a set of contracts. It should feel less like "some files the agent can read" and more like the sealed evidence bag for a run:

```text
input/
  manifest.json
  documents/
    doc_123/source.pdf
    doc_123/pages/page_018.png
  evidence/
    chunks.jsonl
    bboxes.jsonl
    source_index.json
  task.md

output/
  cell_writes.csv
  completed.xlsx
  trace.jsonl
  validation.json
```

The agent can still operate over files. The difference is that the files now encode the provenance model directly.

## Give every source a real identity

Humans use names like `Q3 Board Deck.pdf`. Systems should not.

Display names collide. They get normalized by browsers. They change when someone downloads a file twice. They also create subtle citation bugs because a model may reference a name that is visually correct but operationally ambiguous.

The source manifest should make ambiguity impossible:

```json
{
  "workspace_id": "ws_742",
  "source_version": "srcv_2026_05_24_01",
  "sources": [
    {
      "document_id": "doc_123",
      "display_name": "Q3 Board Deck.pdf",
      "media_type": "application/pdf",
      "sha256": "b7f4...",
      "page_count": 42,
      "workspace_path": "documents/doc_123/source.pdf"
    },
    {
      "document_id": "doc_456",
      "display_name": "Operating Model.xlsx",
      "media_type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "sha256": "31ac...",
      "workspace_path": "documents/doc_456/source.xlsx"
    }
  ]
}
```

Then every downstream artifact references `document_id`, not a file name. The display name is for humans. The id and hash are for correctness.

This also makes retries safer. If a run is replayed or moved to a different worker, the orchestrator can verify that `doc_123` still means the same bytes before allowing reuse.

## Make citations point at the number, not the vibe

One bug that is easy to miss: search-based citation recovery often picks the label near a number instead of the number itself.

Imagine a table like this:

```text
Revenue growth       14.2%
Gross margin         61.8%
```

If the output cell contains `14.2%`, the citation should normally point at the `14.2%` table cell. The `Revenue growth` label is useful for disambiguation, but it is not the data point.

That distinction matters because a user reviewing a workbook comment expects the source to prove the value, not merely the row name.

A simple resolver can encode the policy:

```python
def resolve_numeric_citation(value, row_label, candidates):
    value_phrases = numeric_variants(value)

    data_points = [
        c for c in candidates
        if c.kind == "TABLE_CELL"
        and normalize(c.text) in value_phrases
    ]

    if row_label:
        anchors = [
            c for c in candidates
            if fuzzy_match(c.text, row_label)
        ]
        data_points = rank_by_anchor_distance(
            data_points,
            anchors,
        )

    if data_points:
        return data_points[0].chunk_id

    return fallback_label_chunk(row_label, candidates)
```

The important part is not the exact scoring formula. It is the contract:

- search discovers candidates
- labels and headers rank candidates
- final citations prefer the value-bearing chunk
- fallback citations are explicit, not silent

This turns a fuzzy retrieval problem into a deterministic selection problem. That is where most of the reliability comes from.

## Write intermediate results as rows, not prose

Agents are good at messy reasoning. They are not good storage engines. Any intermediate result that must survive retries, review, or evaluation should be written in a boring format.

For a workbook workflow, I like `cell_writes.csv` as the handoff:

```csv
sheet,cell,value,formula,source_document_id,source_page,chunk_ids,reason
Summary,B12,14.2%,,doc_123,18,chunk_018_0091,"reported growth"
Summary,B13,61.8%,,doc_123,18,chunk_018_0104,"reported margin"
Summary,B14,,=B12-B13,,,, "derived from cited rows"
```

The final writer can turn this into an `.xlsx` with comments, formulas, formatting, and validation. The agent does not need to directly manipulate every low-level workbook detail.

This separation pays off in three ways:

1. The row format is easy to diff.
2. The citation writer can enforce one policy everywhere.
3. The eval can inspect provenance without opening Excel.

The writer should fail closed when source-backed rows lose provenance:

```python
def validate_cell_write(row):
    if row.is_source_backed and not row.chunk_ids:
        raise ValidationError(
            code="MISSING_CHUNK_IDS",
            cell=row.cell,
            message="source-backed write has no evidence"
        )
```

It is tempting to downgrade missing citations to plain comments to keep the run green. That makes the system worse. A polished wrong artifact is more expensive than a failed run.

## Validate the output format, not just the JSON

Structured model output helps, but it is only one layer. If the final artifact is a spreadsheet, validate the spreadsheet package.

An `.xlsx` file is a ZIP package of XML parts. Cell comments, relationships, worksheets, and legacy VML drawings can disagree. A file may open locally but still have broken or incomplete citation metadata.

The validator should inspect the package directly:

```text
open zip
  enumerate worksheets
  read worksheet relationships
  parse comments XML
  parse VML drawing anchors
  parse citation JSON in comment text
  cross-check cited cells against cell_writes.csv
```

A useful validation report is machine-readable:

```json
{
  "valid": false,
  "issues": [
    {
      "code": "MISSING_COMMENT_SHAPE",
      "severity": "error",
      "sheet": "Summary",
      "cell": "B12"
    },
    {
      "code": "MISSING_SOURCE_DOCUMENT",
      "severity": "error",
      "sheet": "Summary",
      "cell": "B13"
    }
  ]
}
```

This is not glamorous work, but it catches failures that a model-level schema never sees. The model can return perfect JSON and the workbook can still be invalid.

## Turn the run into a flight recorder

Most systems keep logs as an operational side channel. For agent workflows, the execution trace is part of the product. If the generated workbook is the aircraft, the trace is the black box.

The trace should tell you:

- which runner handled the job
- which workspace snapshot it saw
- which tools were called
- which artifacts were read or written
- which delegated tasks ran
- how long each phase took
- where errors or retries happened

I prefer newline-delimited JSON because it streams well and survives partial writes:

```json
{"type":"session.started","trace_id":"trace_742","workspace_id":"ws_742"}
{"type":"tool.started","tool":"read_csv","path":"evidence/chunks.jsonl","id":"tool_001"}
{"type":"tool.completed","id":"tool_001","rows":1842,"duration_ms":82}
{"type":"artifact.written","path":"output/cell_writes.csv","bytes":9142}
{"type":"validation.failed","code":"MISSING_CHUNK_IDS","cell":"Summary!B14"}
```

That trace can be rendered as a graph. This is where the system starts to feel alive instead of bureaucratic:

```mermaid
flowchart LR
  A["Workspace snapshot"] --> B["Source scan"]
  B --> C["Fact extraction"]
  C --> D["Cell writes"]
  D --> E["XLSX writer"]
  E --> F["Citation validator"]
  F --> G["Eval report"]
```

The graph is not just a visualization. It is an index over the run. When a cell is wrong, the reviewer should be able to jump from the cell to the source chunk, then to the tool call that selected it, then to the validation decision that allowed it.

OpenTelemetry gives a useful mental model here: spans represent operations, attributes carry searchable metadata, and context propagation stitches work across process boundaries. For agent systems, I still keep the domain trace as a product artifact because it needs richer domain events than generic infrastructure tracing usually carries. The two should share ids.

## Evals should investigate the crime scene

Final-output evals are necessary and insufficient.

A generated workbook can match the expected values while still being operationally bad. It might have used the wrong source version, skipped evidence, relied on a fallback path that is too expensive, or produced comments that Excel cannot anchor correctly.

A better eval has multiple score layers:

| Layer | Example checks |
| --- | --- |
| Output | expected cells, formulas, formatting |
| Evidence | citation coverage, chunk type, page match |
| Trace | tool failures, retries, delegated task status |
| Cost | OCR reuse, token count, runner time |
| Reviewability | clickable bboxes, readable comments, export hygiene |

The output score asks "is the answer right?" The evidence score asks "can we prove it?" The trace score asks "would we trust the path that produced it?" A good eval should read like a tiny incident report, not a green checkmark.

Here is a compact eval fixture shape:

```json
{
  "fixture_id": "fixture_fin_018",
  "workspace_snapshot": "ws_742",
  "expected_cells": [
    {
      "sheet": "Summary",
      "cell": "B12",
      "value": "14.2%",
      "required_chunk_kind": "TABLE_CELL",
      "required_document_id": "doc_123"
    }
  ],
  "max_runner_seconds": 420,
  "required_trace_events": [
    "artifact.written",
    "validation.completed"
  ]
}
```

When this fails, the report should say which contract broke:

```text
Summary!B12
  value: pass
  citation: fail
  expected chunk kind: TABLE_CELL
  actual chunk kind: TEXT
  actual chunk id: chunk_018_0042
```

That failure is much easier to fix than "the workbook is suspicious."

## Export the crash kit, not the whole machine

Debug exports are useful. They are also a common way to leak secrets.

The export path should be intentionally boring:

```python
DENYLIST_DIRS = {".git", ".cache"}
DENYLIST_NAMES = {".env"}
DENYLIST_PREFIXES = (".env.",)
DENYLIST_SUFFIXES = (".pem", ".key", ".p12")

def should_export(path):
    if any(part in DENYLIST_DIRS for part in path.parts):
        return False
    if path.name in DENYLIST_NAMES:
        return False
    if path.name.startswith(DENYLIST_PREFIXES):
        return False
    if path.name.endswith(DENYLIST_SUFFIXES):
        return False
    return True
```

I also like putting a manifest in the archive:

```text
trace-export.zip
  manifest/run.json
  logs/stdout.txt
  logs/stderr.txt
  workspace/input/manifest.json
  workspace/output/cell_writes.csv
  workspace/output/validation.json
```

The manifest should include logical ids and timestamps, not local machine paths. If a local path must appear in an internal tool, do not ship it in the portable export.

## Operational metrics that matter

The dashboard should not stop at request success rate.

| Metric | Why it matters |
| --- | --- |
| citation coverage | catches evidence loss |
| data-point citation rate | catches label-citation regressions |
| chunk reuse rate | shows whether reruns are deterministic |
| validation failure code count | turns bad outputs into searchable classes |
| trace parse rate | catches runner event schema drift |
| workspace materialization time | catches storage or snapshot issues |
| export skipped-file count | catches accidental secret-adjacent output |

I would rather page on a sudden drop in citation coverage than on a small latency increase. Latency is visible. Silent loss of evidence is not.

## Tradeoffs

This design adds files, ids, and validators. There is no point pretending it is free.

The tradeoff is worth it when outputs are reviewed, audited, reused, or used to make decisions. It may be too much for a throwaway summarizer. The line I use is simple: if a user can ask "why did this value appear here?", the system needs a source-grounded answer.

There are a few counterintuitive lessons:

- The agent can be flexible only if the workspace is rigid.
- Search should find candidates, not decide truth.
- Comments are not evidence unless they are validated.
- A failed validation report is a successful safety mechanism.
- The trace is not only for engineers; it is part of the review surface.

The biggest simplification is to stop asking the agent to remember provenance in prose. Put provenance in the input files, require it in intermediate rows, validate it in the final artifact, and score it in evals.

## Conclusion

Document agents become useful when they can produce artifacts people trust. Trust does not come from a longer prompt. It comes from stable source identity, chunk-level evidence, deterministic workspace paths, validated output packages, and traces that explain what happened.

The architecture is not "agent reads files and writes output." The architecture is:

```text
source snapshot
  -> evidence catalog
  -> deterministic workspace
  -> structured intermediate writes
  -> validated final artifact
  -> replayable trace
  -> eval report
```

Once those boundaries exist, the agent becomes easier to change. You can swap a model, add a reviewer, change a citation scorer, or rerun a failed job without losing the ability to prove where the answer came from.

That is the bar I want for serious document agents: not "it generated a spreadsheet", but "it generated a spreadsheet and left behind enough evidence to replay the investigation."

## References

- [OpenTelemetry traces](https://opentelemetry.io/docs/concepts/signals/traces/) - spans, attributes, events, and trace structure.
- [W3C Trace Context](https://www.w3.org/TR/trace-context/) - standard trace propagation headers.
- [PyMuPDF text extraction appendix](https://pymupdf.readthedocs.io/en/latest/app1.html) - text blocks and bounding boxes for PDF extraction.
- [ECMA-376 Office Open XML](https://ecma-international.org/publications-and-standards/standards/ecma-376/) - the standard behind `.xlsx` package structure.
- [JSON Schema specification](https://json-schema.org/specification) - validation vocabulary for structured contracts.
- [OpenAI structured outputs](https://platform.openai.com/docs/guides/structured-outputs) - schema-constrained model responses and their limits.
