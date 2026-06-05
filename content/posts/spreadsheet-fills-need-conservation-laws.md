+++
date = 2026-06-05T11:00:33-04:00
title = "Spreadsheet fills need conservation laws"
description = "A practical deep dive into filling template workbooks from messy source documents with source coverage, formula safety, deterministic validation, and evals that catch the failures humans actually care about."
slug = ""
authors = []
tags = ["excel", "python", "systems", "evals", "data-engineering"]
categories = []
externalLink = ""
series = []
+++

The fastest way to make an automated spreadsheet fill look impressive is to only measure the cells it touched.

That metric is almost useless.

I have seen a workbook pipeline fill thousands of cells, preserve most formatting, attach plausible source comments, and still be wrong in the way that matters: it wrote a value into the wrong period, shifted a formula one column too far, and left a silent hole in a repeated entity section. The output looked dense. The eval was green enough. The reviewer found the problem in five minutes because spreadsheet users do something our systems often do not: they check whether the workbook still balances.

Spreadsheets are not just grids. They are weakly typed programs with hidden state, sparse storage, formulas, styles, merged cells, comments, cached calculation values, and human conventions layered on top. Filling them from PDFs, CSVs, and other workbooks is not a text extraction problem. It is a conservation problem.

Every write should preserve a few invariants:

- The target cell is actually fillable.
- The source fact is compatible with the target row, column, period, unit, and entity.
- The output carries enough evidence for a reviewer to inspect it.
- Formula cells remain formulas unless there is an explicit reason to replace them.
- Workbook-level totals, roll-forwards, and coverage obligations still make sense after the fill.

When those invariants are missing, more automation usually means more confidently wrong spreadsheets.

## The naive implementation

The first version usually looks like this:

```python
facts = extract_facts(source_files)
template = load_workbook("template.xlsx")

for blank in find_blank_cells(template):
    match = search(facts, query=nearby_labels(blank))
    if match:
        template[blank.sheet][blank.address] = match.value
        add_comment(template, blank, match.source)

template.save("output.xlsx")
```

This is a reasonable prototype. It proves that source extraction, workbook writing, and comments can talk to each other.

It fails because it assumes "blank cell near label" means "safe target".

Real templates are full of traps:

| Template pattern | Why the naive fill breaks |
| --- | --- |
| Blank but styled cells | Some blanks are visual spacing, not data targets |
| Formula rows | The blank cell may need a formula, not a copied source value |
| Hidden comparison columns | "Budget", "Prior year", and "Variance %" are different roles under the same period |
| Repeated sections | The same row label appears once per entity, scenario, or source file |
| Unit headers far above the cell | The value is correct but off by 1,000x |
| Sparse answer workbooks | Eval row offsets make good output look bad or bad output look good |
| Placeholder labels | `[Company]` or `[Metric]` is a target shape, not a source key |

The naive pipeline also has a bad feedback loop. When accuracy is low, the natural instinct is to add more search, more fuzzy matching, or a model fallback. Those can help, but they do not fix the core issue: the system does not know what must be conserved.

## Treat the workbook as a program

An `.xlsx` file is a ZIP package containing XML parts. The worksheet XML stores sparse cells, formulas, styles, dimensions, comments, relationships, and sometimes cached formula results. Microsoft's Open XML documentation describes SpreadsheetML workbooks as a set of parts: workbook metadata, separate worksheet files, tables, shared strings, and related components. That structure matters because workbook behavior is distributed across parts, not isolated to cell text.

For fill systems, the useful mental model is:

```text
source documents                 template workbook
---------------                  -----------------
pages                            sheets
tables                           bands
cells                            rows
facts                            target cells
evidence ids                     formulas
                                 comments
                                 styles
        \                         /
         \                       /
          -> fill plan -> workbook writer -> validator -> eval trace
```

Do not write directly from search results into the workbook. Build a fill plan first.

```json
{
  "run_id": "exec_742",
  "target": {
    "sheet": "Operating Model",
    "cell": "H42",
    "row_path": ["Revenue", "North America"],
    "column_path": ["FY2025", "Actual"],
    "unit": "USD",
    "scale": "millions",
    "target_type": "source_value"
  },
  "source": {
    "fact_id": "fact_0192",
    "document_id": "doc_123",
    "page": 18,
    "bbox": [0.62, 0.31, 0.69, 0.34],
    "row_path": ["Revenue", "North America"],
    "column_path": ["FY2025"],
    "value": "184.2",
    "scale": "millions"
  },
  "decision": {
    "score": 0.94,
    "method": "table_path_alignment",
    "checks": ["entity_match", "period_match", "unit_match", "value_family_match"]
  }
}
```

That object is more important than the final write. It gives the system something to validate before mutating the workbook and something to inspect after the workbook is produced.

## Compile both sides into tables

Cell-level matching is too local. Most spreadsheet fills are table alignment problems.

A target cell gets its meaning from at least four axes:

- row path: `Revenue -> North America`
- column path: `FY2025 -> Actual`
- sheet or section path: `Operating Model -> Segment Summary`
- workbook role: historical value, forecast formula, variance check, note, or placeholder

Source cells have similar axes, but they come from OCR tables, CSV sheets, extracted workbook cells, or manually parsed sections. If both sides are compiled into a common table model, matching gets much less magical.

```python
@dataclass(frozen=True)
class CanonicalCell:
    id: str
    table_id: str
    row_path: tuple[str, ...]
    column_path: tuple[str, ...]
    value: Decimal | str | None
    value_family: str          # money, count, pct, date, text
    unit: str | None
    scale: str | None
    entity: str | None
    role: str                  # actual, budget, prior_year, variance_pct
    evidence_id: str | None
```

The table compiler does the boring work:

- resolve merged headers into column paths
- carry section headers down to rows
- distinguish labels from data cells
- infer period grain from nearby headers
- mark formula rows separately from value rows
- detect repeated entity bands
- preserve source evidence at the cell level

After that, matching becomes a constrained assignment problem:

```python
def compatible(source: CanonicalCell, target: CanonicalCell) -> bool:
    return (
        same_value_family(source, target)
        and same_entity(source, target)
        and compatible_period(source.column_path, target.column_path)
        and compatible_unit_scale(source, target)
        and row_paths_close(source.row_path, target.row_path)
        and role_can_flow(source.role, target.role)
    )
```

The exact scoring can evolve. The compatibility gates should be boring and explicit.

## Coverage is a first-class output

Most pipelines report:

```text
filled_cells = 4,812
```

That number hides the denominator.

A better report separates accuracy, completeness, citation coverage, and blocked targets:

| Metric | Definition | Why it matters |
| --- | --- | --- |
| Target cells | Cells the system believes are fillable | Prevents hiding missing work |
| Filled cells | Target cells with a write | Measures completeness, not correctness |
| Correct cells | Filled cells matching an answer/eval oracle | Measures precision |
| Cited cells | Filled cells with source evidence | Measures reviewability |
| Bbox-backed cells | Cited cells with inspectable page regions | Measures audit usefulness |
| Blocked cells | Targets deliberately left blank with a reason | Distinguishes caution from failure |

The most useful failure reports are not global scores. They are grouped obligations:

```json
{
  "sheet": "Operating Model",
  "section": "Revenue build",
  "targets": 96,
  "filled": 81,
  "correct": 78,
  "missing_by_reason": {
    "no_compatible_source_fact": 7,
    "ambiguous_entity": 4,
    "unit_scale_conflict": 2,
    "formula_region": 2
  }
}
```

This is where the word "conservation" becomes practical. If the source table has twelve monthly revenue facts and the target has twelve monthly revenue slots, the fill plan should either map twelve values or explain the deficit. If the source has one total and the target has three segment rows, the system should not invent segment values just to improve completeness.

Completeness without conservation creates hallucinated spreadsheets.

## Formula cells need a separate policy

Formulas are where a lot of spreadsheet systems become subtly wrong.

Libraries like openpyxl can write and parse formulas, but openpyxl explicitly does not evaluate them. XlsxWriter makes the same tradeoff: it writes formulas and relies on spreadsheet applications to calculate them later. The Open XML calculation chain records cells that contain formulas and the order in which they were last calculated, but it is not a full dependency tree and does not force an application's runtime calculation order.

That means a server-side workbook writer needs a formula policy, not just a cell writer.

I usually split targets into three buckets:

| Target type | Write policy |
| --- | --- |
| Source-backed historical value | Write value and evidence |
| Forecast/model region | Write formula only if inferred from nearby observable formulas |
| Existing formula cell | Do not overwrite unless the workflow explicitly allows formula replacement |

A conservative formula pass looks like this:

```python
def maybe_fill_formula(target, sheet_context):
    if target.col <= sheet_context.latest_source_col:
        return None
    if not target.is_blank:
        return None
    if target.row_type in {"section_header", "spacer"}:
        return None

    neighbor = find_nearby_same_axis_formula(target, sheet_context)
    if neighbor and references_stay_on_same_axis(neighbor, target):
        return translate_formula(neighbor, target)

    relationship = infer_visible_relationship(target, sheet_context)
    if relationship:
        return relationship.as_formula()

    return None
```

The important part is the cutoff: source-backed periods and model periods are different regions. Historical actuals should come from evidence. Forecast columns can use formulas, but only when the relationship is observable in the workbook.

This rule prevents a common failure: taking a shifted formula from one part of the workbook and using it as if it were a source fact. Formula translation can create many correct-looking cells quickly. It can also spread one wrong structural assumption across hundreds of columns.

## Units are not metadata decoration

Unit errors are some of the most expensive spreadsheet mistakes because they survive visual review.

`184.2` and `184,200` can both look reasonable depending on whether the workbook is in dollars, thousands, or millions. The source may say "USD in thousands" on page 3 while the target unit appears once at the top of a sheet. Sometimes the target has no explicit unit at all because humans infer it from neighboring columns.

The safest design is to make scale compatibility a hard gate:

```python
def compatible_unit_scale(source, target):
    if source.unit != target.unit:
        return False

    if source.scale == target.scale:
        return True

    ratio = implied_ratio_from_neighbors(source, target)
    if ratio in {Decimal("1000"), Decimal("0.001")}:
        return "convertible"

    return False
```

The neighbor check is the part that matters. If the same row has a prior-year value already present in the template, compare the candidate source value against that nearby workbook value. A 1,000x ratio is a strong signal. A random magnitude gap is not.

Do not silently normalize everything. Emit the conversion decision into the trace:

```json
{
  "event": "scale_conversion",
  "target": "Operating Model!H42",
  "source_value": "184200",
  "source_scale": "thousands",
  "target_scale": "millions",
  "written_value": "184.2",
  "reason": "neighbor_ratio_1000x",
  "neighbor": "Operating Model!G42"
}
```

This makes unit fixes reviewable instead of mystical.

## Repeated sections are not duplicate labels

The row label `Revenue` might appear twenty times in a workbook. That does not mean there are twenty equally valid targets.

Repeated sections usually encode an entity axis:

```text
Portfolio company: Atlas Foods
  Revenue
  Gross profit
  EBITDA

Portfolio company: Beacon Health
  Revenue
  Gross profit
  EBITDA
```

If extraction collapses this into a flat list of rows, matching becomes label roulette. The system will eventually place a correct value into the wrong entity block.

The compiler should promote repeated section headers into the target path:

```json
{
  "sheet": "Portfolio Summary",
  "row_path": ["Beacon Health", "Revenue"],
  "column_path": ["FY2025", "Actual"],
  "entity": "Beacon Health",
  "cell": "F81"
}
```

The source side needs the same treatment. A PDF may contain one page per entity, one table per entity, or one huge matrix with entity columns. Those are different source shapes and should be routed differently:

| Source shape | Better strategy |
| --- | --- |
| One document per entity | Build entity record from document-level facts |
| One page per entity | Use page heading as entity scope |
| One matrix with entity columns | Treat entity as a column axis |
| One table with repeated row groups | Carry group header into row path |

This is why generic "top-k facts for target label" retrieval hits a wall. It has no structural memory.

## The eval can be wrong too

One counterintuitive lesson: sometimes the solver improves and the score gets worse because the eval is measuring the wrong thing.

Spreadsheet evals are surprisingly easy to botch:

- The answer workbook may omit empty header rows that the template kept.
- Formula cells may compare as blank if the evaluator reads cached values instead of formula strings.
- Row matching by position breaks when repeated sections expand.
- Placeholder keys like `[Entity]` should not be treated as real row identifiers.
- Leading-zero identifiers may be equivalent in some sheets and distinct in others.
- Comments may exist but lack parseable source metadata.

A useful eval reads the workbook structurally, not only positionally.

```python
def compare_rows(answer, output, key_col):
    answer_key = normalize_key(answer[key_col])
    output_row = output.rows_by_key.get(answer_key)

    if output_row is None:
        return MissingRow(answer_key)

    return compare_cells(
        answer=answer,
        output=output_row,
        compare_formulas_as_formulas=True,
        require_comments_for_source_values=True,
    )
```

For formula targets, compare the formula text or a normalized formula AST when possible. Do not compare stale cached values unless the workflow includes a trusted recalculation step. For source-backed values, compare normalized values and evidence coverage separately. A cell can be numerically correct and still fail the citation obligation.

The best eval output is a debugging artifact, not just a score:

```json
{
  "mismatch_id": "mis_118",
  "class": "wrong_period",
  "target": "Portfolio Summary!F81",
  "expected": {
    "row_path": ["Beacon Health", "Revenue"],
    "column_path": ["FY2025"]
  },
  "actual_source": {
    "fact_id": "fact_441",
    "row_path": ["Beacon Health", "Revenue"],
    "column_path": ["FY2024"]
  },
  "likely_fix": "period_parser"
}
```

That last field does not have to be perfect. Even a rough failure class is enough to turn an accuracy number into an engineering queue.

## Observability should follow the cell

Distributed traces usually follow requests. Spreadsheet fill traces need to follow cells too.

A single workbook run may fan out across OCR, workbook parsing, source indexing, table retrieval, matching, formula generation, writing, validation, and eval. If the trace only says "match phase took 18 seconds", it is not enough. You need to answer:

- Why did this cell get this value?
- Which candidates lost?
- Which compatibility gate rejected the obvious-looking source?
- Was the cell skipped because it was non-fillable or because retrieval failed?
- Did formula generation write this cell or did source matching write it?
- Which source artifact backs the comment?

OpenTelemetry's trace model gives you request-level structure and context propagation. Use it, but also write domain events keyed by stable workbook identifiers:

```json
{
  "trace_id": "trace_6f2",
  "run_id": "exec_742",
  "event": "candidate_rejected",
  "target_cell": "Operating Model!H42",
  "candidate_fact": "fact_771",
  "gate": "period_match",
  "target_period": "FY2025",
  "source_period": "FY2024"
}
```

For production debugging, I want three views:

| View | Question it answers |
| --- | --- |
| Run timeline | Where did time and retries go? |
| Cell trace | Why did this cell get this result? |
| Coverage report | Which obligations remain uncovered? |

The cell trace is the one reviewers ask for when something is wrong.

## Retry safety and idempotent writes

Long workbook jobs fail in boring ways: OCR provider timeout, worker restart, corrupted upload, rate limit, bad source file, process killed during save. If retrying the job creates a different workbook without explanation, debugging gets painful fast.

The fill plan should be deterministic for the same inputs:

```text
input bundle hash
template hash
source extraction version
matching config version
formula policy version
        |
        v
fill plan hash
        |
        v
output workbook
```

Retries should resume from named artifacts:

- extracted source catalog
- compiled target catalog
- candidate sets
- fill plan
- write report
- validation report
- eval report

The workbook writer should be idempotent at the cell level. Applying the same fill plan twice should not duplicate comments, drift styles, or rewrite formulas differently. If the writer needs to preserve template formatting, copy the template first and apply minimal cell mutations afterward.

That sounds obvious until you hit a sparse workbook edge case. Blank cells may not exist in the worksheet XML. Writing into a blank-but-styled cell can accidentally drop style if the library creates a fresh cell object without copying style state. A safe writer treats style preservation as part of the write contract, not an afterthought.

## A practical validation checklist

Before shipping a generated workbook, I want these checks:

- Every source-backed write has a source fact id.
- Every cited fact has a document/page/table/cell location when available.
- Every target write satisfies row, period, unit, entity, and value-family gates.
- No section headers, spacer rows, hidden helper columns, or placeholder-only rows were filled accidentally.
- Existing formulas were not overwritten outside an explicit formula-replacement mode.
- New formulas are restricted to model regions and reference valid cells.
- Comment metadata parses as structured data, not just free text.
- Coverage is reported against the full target set.
- Blocked cells have reason codes.
- Eval mismatches are grouped by likely failure class.
- The workbook opens in a real spreadsheet application when that is part of the delivery contract.

This checklist catches more real failures than another prompt tweak.

## Tradeoffs

The conservative design leaves cells blank.

That is usually the right failure mode. A blank cell with `blocked: ambiguous_entity` is cheaper to review than a wrong value with a confident comment. Completeness can be improved iteratively by adding better source schemas, table compilers, and formula policies. Recovering trust after silent wrong writes is much harder.

There are still tradeoffs:

| Decision | Upside | Cost |
| --- | --- | --- |
| Hard compatibility gates | Prevents bad fills | More blocked cells early |
| Table-first matching | Better structure and fewer duplicate-label errors | More compiler work |
| Formula policy | Avoids mass formula corruption | Requires workbook-specific reasoning |
| Structured comments | Better auditability | Comment format becomes a contract |
| Cell-level traces | Debuggable failures | More event volume |
| Deterministic fill plan | Replayable jobs | Less room for ad hoc fallback behavior |

The point is not to make the system timid. The point is to make it explain itself.

## Conclusion

Spreadsheet automation fails when it treats the workbook as a prettier CSV.

A reliable fill system needs a stronger contract: compile sources and targets into comparable structures, generate an explicit fill plan, preserve formulas deliberately, attach evidence at the cell level, measure coverage against the real target surface, and make every skipped or written cell explainable.

Search finds candidates. Models can resolve ambiguity. OCR can recover facts from hostile documents. None of those pieces remove the need for deterministic validation.

The useful question is not "did the system fill a lot of cells?"

The useful question is "what did the workbook have to conserve, and can the output prove that it conserved it?"

## References

- [ECMA-376 Office Open XML File Formats](https://ecma-international.org/publications-and-standards/standards/ecma-376/) defines the standardized Office Open XML packaging and document representation used by `.xlsx` files.
- [Microsoft: Structure of a SpreadsheetML document](https://learn.microsoft.com/en-us/office/open-xml/spreadsheet/structure-of-a-spreadsheetml-document) explains workbook parts, worksheet parts, sheet data, and SpreadsheetML document structure.
- [Microsoft: Working with the calculation chain](https://learn.microsoft.com/en-us/office/open-xml/spreadsheet/working-with-the-calculation-chain) describes how calculation chains record formula cells and why they are not a complete dependency tree.
- [openpyxl: Simple formulae](https://openpyxl.readthedocs.io/en/3.1.2/simple_formulae.html) documents formula writing and explicitly notes that openpyxl does not evaluate formulas.
- [openpyxl: Parsing formulas](https://openpyxl.readthedocs.io/en/stable/formula.html) documents tokenization support for formulas, which is useful for validation and safe translation policies.
- [XlsxWriter FAQ](https://xlsxwriter.readthedocs.io/faq.html) explains why XlsxWriter writes formulas but does not calculate formula results.
- [OpenTelemetry specification overview](https://opentelemetry.io/docs/reference/specification/overview/) covers traces, span context, and propagation concepts useful for request-level observability.
