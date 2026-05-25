+++
date = 2025-11-24T16:05:24-05:00
title = "Building a search engine that fits in your L3 cache"
description = "A systems deep dive into building a tiny ranked search engine with FST dictionaries, compact postings, BM25, reranking, reciprocal rank fusion, and cache-aware scoring."
slug = ""
authors = []
tags = ["rust", "search", "performance", "systems", "ranking"]
categories = []
externalLink = ""
series = []
+++

{{< rawhtml >}}
<style>
pre {
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}

table {
  display: block;
  max-width: 100%;
  overflow-x: auto;
}
</style>
{{< /rawhtml >}}

The first version of my search engine was slower after I added an index.

That sounds backwards, but it is a real failure mode. A bad index can turn a simple sequential scan into a pile of cache misses, hash lookups, tiny heap allocations, branchy score calculations, and random memory walks. The CPU stops doing search and starts waiting for memory.

The target I wanted was intentionally unreasonable: a local search engine for a few hundred thousand short technical records that could answer ranked queries inside an interactive UI budget, while keeping the hot path small enough to stay friendly to an L3 cache.

Not "web search". Not "vector database". Not "throw Elasticsearch at it".

Something closer to this:

```text
$ tinysearch "tls timeout shard migration"

score   doc       title
12.91   inc_042   TLS handshakes stall during shard move
10.44   note_118  Connection pool timeout under deploy load
 8.02   pr_077    Retry budget for migration workers
```

The interesting part is not that this can be built. The interesting part is where the naive version falls apart.

## The naive implementation

The first implementation usually looks like this:

```rust
fn search(query: &str, docs: &[Doc]) -> Vec<ScoredDoc> {
    let query_terms = tokenize(query);
    let mut hits = Vec::new();

    for doc in docs {
        let text = doc.search_text.to_lowercase();
        let mut score = 0.0;

        for term in &query_terms {
            if text.contains(term) {
                score += 1.0;
            }
        }

        if score > 0.0 {
            hits.push(ScoredDoc { id: doc.id, score });
        }
    }

    hits.sort_by(|a, b| b.score.total_cmp(&a.score));
    hits
}
```

This is a great prototype. It is also a trap.

It fails in four different ways:

| Failure | Why it hurts |
| --- | --- |
| Every query scans every document | Latency grows with corpus size, not result set size |
| `contains` is not retrieval | It has no document frequency, no term saturation, no field weighting |
| Strings dominate runtime | Lowercasing, allocation, and UTF-8 scans repeat per query |
| Ranking is fake | A document with one rare exact term can lose to a long noisy document |

The bad version gets worse when you try to fix it casually. A `HashMap<String, Vec<DocId>>` inverted index is faster than scanning, but still allocates heavily and jumps around memory. A fuzzy layer adds more candidate terms, which adds more postings lists, which adds more random reads. A reranker improves quality, but if it receives 5,000 bad candidates, it just makes the slow path more expensive.

The lesson is uncomfortable: search quality and memory layout are the same problem earlier than you expect.

## The better shape

The design I like for this size of engine has five layers:

```mermaid
flowchart LR
    Q["query text"] --> N["normalize + tokenize"]
    N --> D["FST term dictionary"]
    D --> P["compact postings"]
    P --> B["BM25 top-k"]
    B --> R["feature rerank"]
    R --> F["rank fusion + explanation"]
```

The split matters because every stage has a different job:

| Stage | Job | Output |
| --- | --- | --- |
| Normalizer | Make equivalent strings comparable | query terms |
| FST dictionary | Map term bytes to term ids and support prefix/fuzzy lookup | candidate terms |
| Postings store | Return doc ids and term frequencies cheaply | candidate docs |
| BM25 scorer | Do fast sparse ranking | top-k docs |
| Reranker | Apply slower contextual signals to a small set | final docs |
| RRF/fusion | Blend independent rankers without trusting raw score scales | final order |

The rule is simple: broad operations must be cheap, and expensive operations must be narrow.

## Build the dictionary first

A finite-state transducer is a compact way to represent a sorted set or map of strings. In Rust, the `fst` crate is a good mental model: it can store ordered byte keys and associate each key with a value. For a search engine, the value is usually a term id.

The dictionary answers:

- Does this term exist?
- What is its internal term id?
- Which terms match this prefix?
- Which terms are close enough for typo tolerance?

The important property is that the dictionary is immutable and compact. That makes it boring in the best way: build it once, memory-map it, and keep query-time work predictable.

```rust
use fst::Map;

struct TermDict {
    map: Map<Vec<u8>>,
}

impl TermDict {
    fn term_id(&self, term: &str) -> Option<u32> {
        self.map.get(term).map(|id| id as u32)
    }
}
```

The input has to be sorted:

```rust
let mut terms: Vec<(String, u64)> = vocabulary
    .into_iter()
    .enumerate()
    .map(|(id, term)| (term, id as u64))
    .collect();

terms.sort_by(|a, b| a.0.cmp(&b.0));

let mut builder = fst::MapBuilder::memory();
for (term, id) in terms {
    builder.insert(term, id)?;
}
let bytes = builder.into_inner()?;
```

This is not the whole index. It is the front door. The dictionary should be tiny compared to the postings.

## Postings are where performance is won

An inverted index is just:

```text
term -> [(doc_id, term_frequency), ...]
```

The layout decides whether queries are fast.

The naive representation is a map of vectors:

```rust
HashMap<TermId, Vec<Posting>>
```

That is fine while building. It is not ideal for query-time. The query path wants contiguous memory:

```text
postings.bin
  [doc_delta, tf, doc_delta, tf, doc_delta, tf, ...]

terms.meta
  term_id -> { offset, len, doc_freq }
```

Instead of storing absolute doc ids, store deltas:

```text
docs:   101, 108, 130, 131
deltas: 101,   7,  22,   1
```

Then encode small integers with a variable-length format. For small corpora, even a plain `u32` array can be faster because decoding is branchless and simple. Compression is not automatically a win. The question is whether you are limited by memory bandwidth, cache capacity, or integer decode overhead.

For the fake corpus I used while tuning, the layouts looked like this:

| Layout | Index size | Median query | Notes |
| --- | ---: | ---: | --- |
| `HashMap<String, Vec<Posting>>` | 74 MB | 18.4 ms | too many pointer jumps |
| sorted term ids + `Vec<Posting>` | 41 MB | 7.9 ms | less allocation, still bulky |
| delta encoded `u32` blocks | 26 MB | 4.6 ms | best simple version |
| varint blocks | 17 MB | 5.1 ms | smaller, slightly more CPU |

Those numbers are fictional but the tradeoff is real: "smaller" and "faster" overlap until decoding work becomes the bottleneck.

## BM25 is a good first scorer

Term overlap is not enough. A rare term should matter more than a common term. A term repeated 40 times should help, but not linearly. Long documents should not win just because they contain more words.

BM25 handles those cases well enough to be the first real scorer:

```text
score(q, d) = sum over query terms:

  idf(term) *
  (tf * (k1 + 1)) /
  (tf + k1 * (1 - b + b * doc_len / avg_doc_len))
```

The useful parts:

- `idf` rewards rare terms.
- `tf` saturates, so repeated terms stop helping after a point.
- `doc_len / avg_doc_len` normalizes long documents.

The hot path becomes:

```rust
fn score_term(
    acc: &mut [f32],
    postings: &[Posting],
    idf: f32,
    norms: &[f32],
) {
    const K1: f32 = 1.2;

    for posting in postings {
        let tf = posting.tf as f32;
        let norm = norms[posting.doc_id as usize];
        let score = idf * (tf * (K1 + 1.0)) / (tf + K1 * norm);
        acc[posting.doc_id as usize] += score;
    }
}
```

That array write is the first serious design fork.

If the corpus has 200,000 docs, a dense `Vec<f32>` accumulator is tiny and fast. If the corpus has 200 million docs, it is absurd. For the local-search shape, a dense accumulator plus a touched-doc list is excellent:

```rust
if acc[doc] == 0.0 {
    touched.push(doc);
}
acc[doc] += score;
```

After scoring, only sort the touched docs, or keep a bounded heap if the touched set is large.

## The query planner matters

The cheapest query is not always "score every term".

For:

```text
"timeout during shard migration"
```

`during` is probably useless. `timeout` is broad. `shard` and `migration` are more selective. Score the selective terms first.

The planner can use document frequency:

```rust
terms.sort_by_key(|term| term.doc_freq);
```

Then apply gates:

| Gate | Example |
| --- | --- |
| Drop stopwords | `the`, `during`, `with` |
| Cap very broad terms | ignore `error` if it hits 80% of docs |
| Require at least one selective term | `shard` or `migration` must match |
| Expand only rare prefixes | `migr*` is okay, `e*` is not |

This is where FST prefix lookup can hurt you. Prefix search is seductive:

```text
mig -> migration, migrate, migrated, migrator
```

But a short prefix can explode into thousands of terms. The dictionary lookup is cheap. The postings are not.

I like explicit expansion budgets:

```rust
struct ExpansionBudget {
    max_terms: usize,
    max_total_doc_freq: u32,
}
```

When the expansion crosses the budget, degrade gracefully:

- use only exact terms
- use top-N rare expansions
- ask the reranker to handle fuzzy similarity later

## Reranking should be boring and narrow

BM25 is lexical. It does not understand every signal you care about.

For a local technical corpus, I usually want extra signals:

| Signal | Why it helps |
| --- | --- |
| title match | titles are dense summaries |
| path or namespace match | `auth/cache` beats random mentions of cache |
| recency | recent notes may be more actionable |
| exact phrase | "token refresh" is stronger than separate words |
| proximity | words near each other usually mean more |
| source type | incident, PR, doc, note, log |

The mistake is applying those signals to the full corpus. Rerank the top 100 or 200 BM25 candidates.

```rust
fn rerank(query: &Query, mut docs: Vec<ScoredDoc>) -> Vec<ScoredDoc> {
    for doc in &mut docs {
        doc.score += 1.7 * title_overlap(query, doc);
        doc.score += 1.2 * exact_phrase(query, doc);
        doc.score += 0.8 * path_overlap(query, doc);
        doc.score += 0.4 * recency_boost(doc);
    }

    docs.sort_by(|a, b| b.score.total_cmp(&a.score));
    docs
}
```

This looks unsophisticated because it is. That is the point. A small deterministic reranker is debuggable. You can print the score breakdown:

```json
{
  "doc": "inc_042",
  "score": 12.91,
  "features": {
    "bm25": 8.14,
    "title_overlap": 1.70,
    "phrase": 1.20,
    "path": 0.80,
    "recency": 0.32
  },
  "matched_terms": ["tls", "timeout", "shard", "migration"]
}
```

This kind of explanation is more useful than a mysterious score with four decimal places.

## RRF is a better blender than score normalization

At some point you will have more than one retriever:

- BM25 over body text
- exact title matcher
- prefix/fuzzy term matcher
- vector search
- recent-document retriever

The obvious move is to normalize scores and add them. That gets messy because every retriever has a different score distribution. A BM25 score of `12` and a vector similarity of `0.82` do not mean comparable things.

Reciprocal Rank Fusion avoids that by using ranks:

```text
rrf_score(doc) = sum over rankers 1 / (k + rank(doc))
```

A simple implementation:

```rust
fn rrf(lists: &[Vec<DocId>], k: f32) -> HashMap<DocId, f32> {
    let mut scores = HashMap::new();

    for list in lists {
        for (rank, doc) in list.iter().enumerate() {
            let contribution = 1.0 / (k + rank as f32 + 1.0);
            *scores.entry(*doc).or_insert(0.0) += contribution;
        }
    }

    scores
}
```

RRF has a nice failure mode: one weird retriever can suggest candidates without dominating the result set. But it is not magic. If every retriever shares the same blind spot, fusion just agrees with itself confidently.

I like using RRF when the retrievers are genuinely different. BM25 plus title exact plus vector search is useful. BM25 body plus BM25 body with a different boost is less useful.

## Cache-aware scoring

The phrase "fits in L3 cache" is a forcing function, not a universal requirement. Modern CPUs vary wildly. The point is to budget the hot query path like it has to live in a small memory neighborhood.

The hot data is:

| Data | Access pattern |
| --- | --- |
| term metadata | tiny random reads |
| postings blocks | sequential reads per term |
| doc length norms | random reads by doc id |
| score accumulator | random writes by doc id |
| top-k heap | tiny |

Three tactics helped more than clever scoring:

1. Keep doc ids dense.
2. Store postings contiguously.
3. Keep the accumulator reusable.

Do not allocate a new score vector for every query:

```rust
struct QueryScratch {
    scores: Vec<f32>,
    touched: Vec<u32>,
}

impl QueryScratch {
    fn reset(&mut self) {
        for doc in self.touched.drain(..) {
            self.scores[doc as usize] = 0.0;
        }
    }
}
```

This clears only the docs touched by the previous query. It is a small trick, but it removes a full-corpus memset from every request.

## Testing search without lying to yourself

Search tests are easy to make useless.

This test is weak:

```rust
assert!(search("timeout").len() > 0);
```

It proves the engine returns something. It says nothing about ranking.

Better tests use named queries with expected top results:

```json
{
  "query": "tls timeout shard migration",
  "must_include_top_3": ["inc_042"],
  "must_not_include_top_5": ["note_991"],
  "why": "rare terms should beat generic timeout notes"
}
```

I like keeping a small eval file with adversarial cases:

| Case | What it catches |
| --- | --- |
| rare term beats common term | broken IDF |
| long noisy doc loses | missing length normalization |
| prefix expansion budget | runaway fuzzy lookup |
| exact phrase boost | bag-of-words weakness |
| title beats body mention | field weighting |
| stale note loses tie | recency tie-break |

For performance, keep benchmark queries separate from quality queries. A query like `error` is a stress test, not a quality test. A query like `oauth token refresh race` is closer to what a real user asks.

## What surprised me

The most counterintuitive part was that the "smart" pieces were rarely the bottleneck.

BM25 was not expensive. Bad candidate generation was expensive.

Fuzzy search was not expensive. Unbounded fuzzy expansion was expensive.

Reranking was not expensive. Reranking thousands of weak candidates was expensive.

The dictionary was not expensive. Turning dictionary matches into scattered postings reads was expensive.

Most of the work was making each stage return a small, useful frontier to the next stage.

## Tradeoffs

I would not build this for every search problem.

Use a real search engine when you need distributed indexing, complex query syntax, operational tooling, per-tenant isolation, analyzers for many languages, or petabyte-scale retention.

Use a small embedded search engine when:

- the corpus fits on one machine
- rebuilds are acceptable
- query latency matters more than write latency
- explainability matters
- you want deterministic behavior in tests
- the index can be memory-mapped or loaded at startup

The tiny version is not less serious. It just has fewer places to hide mistakes.

## Conclusion

Building a small search engine is mostly an exercise in refusing to waste work.

Do not scan documents if you can scan postings. Do not expand prefixes without a budget. Do not rerank the whole world. Do not normalize unrelated scores when rank fusion is enough. Do not allocate on the query path if scratch space will do.

The final design is simple:

```text
FST dictionary
  -> compact postings
  -> BM25 candidate generation
  -> narrow deterministic rerank
  -> optional RRF blend
  -> score explanation
```

That is enough to make a local search box feel instant, and still keep the ranking behavior understandable when it is wrong.

## References

- [Rust `fst` crate documentation](https://docs.rs/fst/latest/fst/) for finite-state transducer backed sets and maps.
- [SQLite FTS5 documentation](https://www.sqlite.org/fts5.html) for full-text indexing and the built-in `bm25()` ranking function.
- [Tantivy documentation](https://docs.rs/tantivy/latest/tantivy/) for a Rust full-text search engine and its indexing/query model.
- [Introduction to Information Retrieval: Okapi BM25](https://nlp.stanford.edu/IR-book/html/htmledition/okapi-bm25-a-non-binary-model-1.html) for the scoring formula, term frequency scaling, and document length normalization.
- [Reciprocal Rank Fusion paper](https://plg.uwaterloo.ca/~gvcormac/cormacksigir09-rrf.pdf) by Cormack, Clarke, and Buettcher for rank-based result fusion.
