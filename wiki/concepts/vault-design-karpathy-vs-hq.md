---
title: "Vault design — Karpathy LLM Wiki vs. Productive Setups HQ"
type: concept
created: 2026-06-26
updated: 2026-06-26
tags: [vault-design, llm, knowledge-management, cortex-forge/architecture, design-decisions]
aliases: [karpathy-vs-hq]
sources: []
confidence: medium
schema_version: "0.3"
---

# Vault design — Karpathy LLM Wiki vs. Productive Setups HQ

Comparative analysis of two design references for cortex-forge, with evaluation of the current vault state and actionable gaps.

## Distinct mental models

**Karpathy** assumes an *epistemic* self: the problem is not knowledge acquisition but structured accumulation. The LLM has agency over structure — it decides what pages to create, how to update entities, what contradictions to flag. Out of scope: anything related to action (tasks, habits, dates). The wiki is an artifact of understanding, not planning.

**HQ (Productive Setups)** assumes an *executive* self: the problem is failed execution, not incomplete knowledge. HQ accumulates information about user behavior — what they did, how long it took, what moved the needle. Out of scope: synthesis of the external world, cross-references between ideas. A book in HQ gets a 5-star review; in Karpathy it updates concept and entity pages.

The structural difference: in Karpathy the LLM has agency over knowledge structure; in HQ the human has full agency and the LLM doesn't exist. **cortex-forge chose the Karpathy model** — which means importing HQ mechanics requires adaptation, not transplant.

## Vault state vs. objectives

**Objective 1 — warm memory and context for agents:** well-resolved in protocol (`.hot/`, hooks, skill), incomplete in content. Missing: explicit spec of what a good `.hot/` entry should contain (which decisions, which pending items, what the next agent needs). Missing: staleness signal — context from 6 weeks ago reads as fresh.

**Objective 2 — building knowledge for projects:** partially resolved. Ingest works. What's missing: when something relevant to an active project is ingested, that connection doesn't materialize in `wiki/projects/{project}.md`. Knowledge exists but doesn't flow where it's operationally needed.

**Internal tension:** the two objectives have different cadences. The hot cache ages; the wiki shouldn't. What's missing is a third layer: **project state** as distinct from domain knowledge. It partially exists in `wiki/projects/` but without the operational structure that would make that distinction explicit.

## Actionable gaps from Karpathy

- **`wiki/meta/log.md` missing** — append-only log of vault operations; allows the next agent to understand state without reading all pages. *(Resolved in cortex-forge: `wiki/meta/log.md` exists)*
- **Valuable queries not archived** — analysis responses should end as wiki pages (`cortex-recall` answers and discards)
- **Provenance missing from writes** — frontmatter has `updated:` but not `sources:` or `confidence:`; critical with multiple agents. *(Resolved: both fields in schema)*

## Actionable gaps from HQ

- **Bottleneck tracking** — when an agent detects a recurring problem in a project, there's no mechanism to generate an action entry in `.hot/` or `wiki/projects/{project}.md`
- **Reverse traceability** — no way to mark that a wiki page was used in a real project decision; without that signal it's impossible to know what knowledge is fertile vs. dead archive

## Multi-agent protocol debt

Neither Karpathy nor HQ models an async vault with multiple agents. Karpathy assumes a single LLM; HQ assumes a single human. When Claude Code, Codex, etc. write to the same wiki in independent sessions, `.hot/` is the only anti-conflict mechanism — and it's gitignored. Debt to resolve if the project scales.

## Cross-reference: Hermes Agent (Nous Research)

Analysis of Hermes Agent confirms and deepens the three gaps above, and adds new patterns.

### Confirmations

**Multi-agent debt → Honcho resolves it structurally.** The mechanism is not a shared database but **per-peer profiles**: each agent has its isolated context space. The minimum solution for cortex-forge: identify which agent wrote each snapshot — adding an `agent:` field to `.hot/` entries is enough.

**Provenance → trust scoring in Holographic.** The `sources:` and `confidence:` gap appears in Hermes as per-fact trust scoring: each entry has an asymmetric score (+0.05 positive / −0.10 negative). The cortex-forge equivalent is already in the source page frontmatter as the `confidence:` field.

**Cross-session patterns → dialectic reasoning in Honcho.** The Phase 4 roadmap item ("recurring themes in `.hot/` that never reach `wiki/`") has a concrete implementation in Hermes: after each session, an LLM analyzes the exchange and extracts conclusions about patterns. In cortex-forge, `cortex-crystallize` could review the last N history entries and propose candidates for `wiki/`.

### New patterns (not in Karpathy/HQ)

**Context fencing (Supermemory).** When updating a wiki page using other pages as context, there's a risk of circular contamination: new pages inherit amplified biases from what's already written. Solution: during `cortex-imprint`, the source of truth must be `.raw/` — existing wiki pages are reference, not source.

**Progressive loading of subdirectories (context files).** Hermes doesn't load all `AGENTS.md` files at startup — it discovers them as the agent navigates directories. For `cortex-recall`, this suggests navigating the wiki as a filesystem rather than loading the full index at startup. Reduces token bloat without sacrificing coverage.

---

- 2026-06-26 [Claude Code]: Consolidated from moon-multivac/wiki/concepts/vault-design-karpathy-vs-hq.md (2026-06-06, updated 2026-06-07); translated to English per vault locale
