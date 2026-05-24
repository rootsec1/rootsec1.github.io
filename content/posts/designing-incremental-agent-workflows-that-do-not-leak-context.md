+++
date = 2026-05-23T21:02:29-04:00
title = "Designing incremental agent workflows that do not leak context"
description = "A practical deep dive into designing long-running agentic workflows with checkpoints, replay safety, privacy boundaries, observability, and enough state to avoid reprocessing the world on every run."
slug = ""
authors = []
tags = ["AI", "architecture", "infra", "observability"]
categories = []
externalLink = ""
series = []
+++

Most agent workflows start as a chat window with a filesystem. Then they become a recurring job. Then they become a thing that reads repos, issues, browser state, logs, docs, previous decisions, and half your life.

That is where the design gets interesting.

The hard part is not making an agent do one useful task. The hard part is making it run repeatedly without re-reading the entire universe, leaking private context, or slowly turning into a prompt-shaped cron job with no operational boundaries.

This post is about designing those workflows properly: incremental state, source cursors, privacy filters, replayable decisions, observability, and verification loops.

The examples are fictional, but the failure modes are very real.

## The naive version

Imagine RelayOps has a weekly engineering-writing workflow. It looks at:

- recent commits across local repos
- merged pull requests
- design docs
- incident notes
- browser-tested prototypes
- previous posts
- recurring prompts and review comments

Then it writes one deep technical post.

The naive implementation is simple:

```shell
scan-everything \
  --repos ~/code \
  --messages ~/.local-history \
  --github rootsec1 \
  --output content/posts/new-post.md
```

This works exactly once.

On the fifth run, it is expensive. On the tenth run, it repeats itself. On the twentieth run, it starts mixing old and new signals in ways that are almost impossible to debug.

The core bug is that the workflow has no memory of what it already consumed.

> If every run starts from genesis, every run is a migration.

That is fine for a one-off script. It is a bad default for a recurring system.

## Treat agent inputs like event streams

The better model is to treat every source as a stream with a cursor.

| Source | Cursor | Why it matters |
| --- | --- | --- |
| Git repo | last scanned commit SHA | Avoid rereading old diffs |
| GitHub activity | updated timestamp or GraphQL cursor | Avoid duplicate PR/issue signals |
| Local notes | modified timestamp | Capture new docs without rereading the archive |
| Browser/test results | run id or timestamp | Keep validation tied to the generated artifact |
| Prior posts | slug/title registry | Prevent topic duplicates |
| Workflow state | last successful run | Separate successful progress from failed attempts |

The workflow should not ask, "What has ever happened?"

It should ask:

1. What changed since the last successful run?
2. Is the change safe to use as inspiration?
3. Does the new signal justify a new artifact?
4. Can I prove the artifact builds, renders, and says nothing private?

That one shift turns a vague agent into a small data pipeline.

## State is a product surface

A recurring workflow needs a state file. Not a huge database, not a distributed scheduler on day one, just a boring checkpoint that is easy to inspect.

```json
{
  "lastSuccessfulRunAt": "2026-05-23T21:02:29-04:00",
  "sourceCursors": {
    "blogRepoCommit": "3d464f7",
    "githubActivityUpdatedAfter": "2026-05-23T19:32:02Z",
    "localActivityScannedUntil": "2026-05-23T21:02:29-04:00"
  },
  "recentTopics": [
    {
      "slug": "incremental-agent-workflows-context",
      "title": "Designing incremental agent workflows that do not leak context"
    }
  ],
  "publicReferences": [
    "https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html",
    "https://docs.github.com/en/webhooks/using-webhooks/handling-webhook-deliveries",
    "https://www.w3.org/TR/trace-context/",
    "https://genai.owasp.org/llmrisk/llm01-prompt-injection/"
  ]
}
```

The important part is what is **not** in the state file:

- no private repo names
- no customer names
- no internal URLs
- no raw prompts
- no issue titles from private systems
- no copied conversation text
- no secrets

The state file should let the workflow resume. It should not become a second archive of private data.

This is the same reason durable workflow systems separate event history from arbitrary side effects. Replay only works if the state you keep is deterministic enough to resume from, but constrained enough to avoid becoming the whole world.

## Use private signal, publish fictional examples

There is a difference between learning from private work and publishing private work.

A sane workflow can inspect private activity for patterns:

- lots of retry/resume fixes
- repeated schema validation work
- recurring scaling changes
- frequent browser verification
- queue consumers behaving badly
- too many manual review loops

Those are useful signals. They say what the author is thinking about.

They are not publishable details.

The public post should convert them into fictional systems:

```text
At AtlasCart, imagine a workflow that enriches 50k product updates per hour.
Each update can trigger OCR, schema extraction, fraud checks, and downstream
index refreshes. The bad implementation treats every retry as a fresh run.
The better implementation resumes from a checkpointed step boundary.
```

That example carries the systems lesson without leaking the source.

I like this rule:

> Private data can influence the question. Public references must support the answer.

The workflow can use private activity to decide that "incremental replay" is an interesting topic. The claims inside the post still need to stand on public docs, specs, and reproducible examples.

## Design the workflow as stages

Agentic systems get messy when the same step does discovery, reasoning, writing, validation, and publishing.

Split the workflow into stages with explicit artifacts.

```text
discover -> filter -> choose topic -> research -> draft -> verify -> render -> publish
```

Each stage should have a narrow contract.

| Stage | Input | Output |
| --- | --- | --- |
| Discover | source cursors | candidate signals |
| Filter | candidate signals | sanitized themes |
| Choose topic | themes + recent topics | one topic |
| Research | topic | public references |
| Draft | topic + references + style sample | markdown post |
| Verify | markdown post | issues or pass |
| Render | local site | browser findings |
| Publish | validated diff | branch and PR |

This makes failures recoverable. If browser validation fails, the workflow should not rescan every repo. If reference checking fails, it should not rewrite the topic from scratch.

Each stage should be restartable from the previous artifact.

## Checkpoints need commit semantics

The most common bug in incremental systems is advancing the cursor too early.

RelayOps should not update `lastSuccessfulRunAt` after generating the draft. The run is not successful yet. It still needs to build, render, and publish.

The cursor advances only after the durable external effect succeeds.

For a blog workflow, that means:

1. New post created.
2. Hugo build passes.
3. Browser review passes.
4. Privacy scan passes.
5. Branch is pushed.
6. PR is opened.
7. State file is updated.
8. State file is included in the same PR.

If step 4 fails, the next run should see the same input window again. That is not waste. That is correctness.

The pattern is basically a small two-phase commit:

```text
prepare artifact -> validate artifact -> publish artifact -> advance cursor
```

Do not checkpoint intent. Checkpoint completed work.

## Make privacy a pipeline stage

Privacy should not be a line in the prompt. It should be a stage that can fail the run.

For a generated post, I would scan at least:

```shell
rg -i \
  'private-company-name|internal-host|customer-name|ticket-prefix|secret|token|api[_-]?key' \
  content/posts/new-post.md
```

That is the crude version. The better version has three layers:

1. **Denylist:** exact private strings that must never appear.
2. **Shape checks:** internal hostnames, emails, commit hashes, ticket ids, tokens.
3. **Semantic review:** "does this fictional example map too closely to real work?"

Shape checks catch the boring leaks:

```regex
[A-Z]{2,10}-[0-9]{2,}
gh[pousr]_[A-Za-z0-9_]{20,}
[a-f0-9]{40}
https?://[a-z0-9.-]+\.internal
```

Semantic review is harder. You cannot solve it with regex alone.

The best practical approach is to force a rewrite boundary:

- source signal: private
- extracted theme: sanitized
- example: fictional
- factual support: public reference

If the post cannot survive that transformation, it should not be published.

## Research should be public and boring

The agent can learn what to write about from private activity. It should verify what it says through public sources.

For this kind of workflow, public references usually fall into four buckets:

| Claim type | Good source |
| --- | --- |
| workflow determinism/replay | durable execution docs |
| idempotent task design | scheduler or orchestration docs |
| event delivery/retries | webhook/provider docs |
| trace propagation | W3C/OpenTelemetry specs |
| prompt/data leakage risks | OWASP/NIST-style security docs |

This matters because private experience can be correct and still not be enough. A post should teach the reader something they can verify.

For example, if the post says webhook handlers need idempotency, GitHub's webhook delivery docs are a better reference than "I have seen this break." If the post says distributed traces need propagated context, W3C Trace Context is a better anchor than a vendor dashboard screenshot.

## Observability for the workflow itself

An agent workflow that produces artifacts should have its own operational telemetry.

Minimum useful fields:

```json
{
  "runId": "2026-05-23-blog-incremental-workflows",
  "stage": "render",
  "topic": "incremental agent workflows",
  "sourcesScanned": {
    "repos": 9,
    "activityItems": 20,
    "stylePosts": 4
  },
  "checks": {
    "build": "pass",
    "privacy": "pass",
    "browser": "pass"
  }
}
```

Do not log raw private inputs. Log counts, categories, durations, and decisions.

When the generated post is weak, you need to know why:

- Was there not enough new signal?
- Did topic selection choose something already covered?
- Did research fail?
- Did the draft violate privacy rules?
- Did browser review find rendering issues?
- Did the PR fail to open?

If the only output is "agent failed", the system is not debuggable.

## Browser review is not optional

Markdown that looks fine in a terminal can be ugly on the actual site.

Code blocks overflow. Tables get cramped. Heading levels feel wrong. Links render weirdly. Long titles wrap badly. A post can pass build validation and still feel off.

A serious workflow should open the local site and inspect the generated page like a reader:

- Does the first screen make the topic clear?
- Are code blocks readable?
- Are tables usable on mobile?
- Do headings create a real path through the post?
- Does the writing feel specific or generic?
- Are references visible and clickable?
- Does the post feel like it belongs with the rest of the site?

This is not cosmetic. Visual review catches structural writing problems.

If the page looks like a blob, the post probably reads like one too.

## When not to build this

Do not build an incremental agent workflow if:

- the job runs once
- source data is tiny
- privacy risk is high and cannot be filtered
- the output does not need review
- a deterministic script would solve the problem
- the workflow cannot be evaluated objectively

Agents are useful when the work has judgment in the loop: choosing a topic, synthesizing themes, checking tone, deciding whether a post is too generic.

They are less useful when the work is pure transformation. If a cron job and `jq` can solve it, use that and move on with life.

## The design I would start with

For AtlasCart's fictional engineering blog workflow, I would start with this:

```text
state.json
  last successful run
  source cursors
  recent topics
  public references used

discover
  read only net-new commits, PRs, docs, and local notes
  store sanitized themes, not raw content

topic
  choose one topic with novelty and enough technical depth

research
  gather public references
  reject claims without sources

draft
  write one post
  use fictional examples only

verify
  build site
  scan for private strings and secret-shaped data
  open page locally
  inspect layout and reading quality

publish
  branch
  commit
  push
  open PR
  advance state only after success
```

That is not complicated. It is just disciplined.

The real trick is resisting the urge to make the agent omniscient. Good long-running workflows do not remember everything. They remember the minimum required to make the next run correct.

## Conclusion

Recurring agent workflows should be treated like production systems.

They need checkpoints, idempotency, privacy boundaries, public verification, observable stages, and visual review. Otherwise they become expensive scripts that are hard to trust.

The best version is not the one that reads the most context. It is the one that knows what changed, what to ignore, what must never be published, and what needs to be proven before it opens a PR.

That is the difference between a clever demo and a workflow I would actually let run every week.

## References

- [Apache Airflow best practices](https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html)
- [GitHub Docs: Handling webhook deliveries](https://docs.github.com/en/webhooks/using-webhooks/handling-webhook-deliveries)
- [W3C Trace Context](https://www.w3.org/TR/trace-context/)
- [OpenTelemetry Context](https://opentelemetry.io/docs/concepts/context-propagation/)
- [AWS Docs: Determinism and durable execution](https://docs.aws.amazon.com/durable-execution/patterns/best-practices/determinism/)
- [OWASP GenAI Security Project: Prompt Injection](https://genai.owasp.org/llmrisk/llm01-prompt-injection/)
- [OWASP GenAI Security Project: Sensitive Information Disclosure](https://genai.owasp.org/llmrisk/llm02-sensitive-information-disclosure/)
