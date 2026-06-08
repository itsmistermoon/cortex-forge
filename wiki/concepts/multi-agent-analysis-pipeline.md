---
title: Multi-agent analysis pipeline
type: concept
created: 2026-06-08
updated: 2026-06-08
tags: [multi-agent, pipeline, code-analysis, knowledge-graph, parallel]
aliases: [analysis pipeline, agent orchestration]
sources:
  - wiki/sources/understand-anything.md
confidence: high
---

# Multi-agent analysis pipeline

Orchestration pattern where a single command triggers **N specialized agents** that collaborate to analyze a corpus (code, wiki, documentation) and produce a structured artifact (graph, index, report). Implemented by Understand Anything in `/understand` with 5-7 agents.

## Typical structure

**Orchestrator command** (`/understand`) that:
1. Receives input (project path, scope, flags).
2. Passes to `project-scanner` to discover files.
3. Distributes work to `file-analyzer`s **in parallel** (batches of 20-30 files, up to 5 concurrent).
4. Consolidates results in `architecture-analyzer` and `tour-builder`.
5. Validates with `graph-reviewer` (inline by default; opt-in for full LLM review).
6. Persists final graph as JSON.

**Optional agents depending on command:**
- `domain-analyzer` → for `/understand-domain`.
- `article-analyzer` → for `/understand-knowledge` (Karpathy wikis).

## What each agent has

| Property | Value |
|----------|-------|
| Role | A single, nameable responsibility |
| Input | Output of the previous agent, or subset of the corpus |
| Output | Validatable structure (JSON, list, index) |
| State | Stateless between invocations (each agent is stateless) |
| Validation | Fast inline heuristic; full LLM review only if `--review` |

## Why split into agents instead of a monolithic prompt

**Three technical reasons:**

1. **Real parallelization.** File analyzers run concurrently. A monolithic prompt is sequential by construction (generation is linear within a context window).
2. **Manageable context window.** Each agent operates on a small batch (20-30 files). A monolithic prompt loading the entire codebase blows up the context in medium-sized projects.
3. **Per-layer validation.** The `graph-reviewer` can detect "this node has no edges, this function is duplicated across two files" without being contaminated by the generation work. With a monolithic prompt, the validator and generator compete for the same context.

**Design reason:**

4. **Composable.** If you change `file-analyzer` (e.g. to support a new language), the rest of the pipeline is unaffected. A monolithic prompt is fragile to changes.

## Orchestration pattern

It is not a full DAG nor a reactive loop. It is a **linear pipeline with a fan-out** at the file analyzer step:

```
project-scanner
       ↓
   file-analyzer (×N parallel, batches)
       ↓
   architecture-analyzer
       ↓
   tour-builder ←─┐
       ↓          │
   graph-reviewer ┘ (loop if validation fails)
       ↓
   output
```

`graph-reviewer` can re-invoke a sub-step if it detects problems (e.g. "edges missing in these 3 files" → re-triggers file-analyzer on them).

## Incremental

If the corpus already has a previous graph, `project-scanner` compares fingerprints (see [[wiki/concepts/treesitter-llm-hybrid-parsing]]) and only enqueues file-analyzer for files whose fingerprint changed. Result: re-analyzing a 10k-file project after editing 3 files takes seconds, not hours.

**Trade-off:** the previous graph must be trusted as the structural base. If there were errors in previous runs, they persist. That is why `--review` (full re-validation) exists as an opt-in.

## When NOT to use this pattern

- **Corpus <100 files.** The orchestration overhead does not amortize. A single agent with good prompts works fine.
- **Analysis requiring global context of the corpus** (e.g. "explain the entire system architecture"). Here specialized agents lose the big picture; a single agent with a lot of context does it better.
- **When roles do not divide cleanly.** If the "agents" end up doing overlapping work, they are not agents — they are disguised prompts.

## Applicability in the vault

The `cortex-forge` vault does not implement this pattern (its pipeline is single-agent: the `cortex-assimilate` skill reads → synthesizes → writes). It could apply to:

- `cortex-prune` if it grows: split into `orphan-detector`, `link-validator`, `staleness-checker`, executed in parallel over `wiki/`.
- Full vault analysis with `/understand-knowledge` (third project, via Understand Anything).

---

- 2026-06-08 [CommandCode]: Page created — concept extracted from the `/understand` pipeline, with emphasis on the technical reasons for the split (parallelization, context window, per-layer validation) and the pattern's trade-offs
- 2026-06-08 [Claude Code]: Translated to English
