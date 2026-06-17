---
title: "Iterative Retrieval"
type: concept
created: 2026-06-12
updated: 2026-06-12
tags: [subagents, orchestration, context-management]
aliases: [sub-agent context negotiation, follow-up retrieval loop]
sources:
  - wiki/sources/claude-code-longform-guide.md
confidence: medium
schema_version: "0.3"
---

# Iterative Retrieval

Orchestration pattern where the orchestrator treats a subagent's summary as a draft, not a final answer: it evaluates sufficiency, sends follow-up questions back to the subagent (which returns to the source), and loops until the summary is sufficient — bounded (e.g. max 3 cycles) to prevent infinite loops.

## The problem it solves

Subagents exist to save context by returning summaries, but the orchestrator holds semantic context the subagent lacks — it knows only the literal query, not the purpose behind it. Summaries therefore systematically miss details the orchestrator needed (@PerceptualPeak's analogy: your meeting summary never answers all your boss's follow-ups, because you lack his implicit context).

## The pattern

1. Dispatch with **query + objective** — the broader goal helps the subagent prioritize what to include.
2. Orchestrator evaluates every return before accepting it.
3. Insufficient → follow-up questions; subagent re-queries the source.
4. Accept when sufficient, or stop at the cycle cap.

## Application in Cortex Forge

`cortex-recall` is a single-shot retrieval: question in, cited pages out. If recall ever runs as a subagent of a working session, the calling agent should pass the *objective* (why it's asking) along with the question, and treat an insufficient answer as grounds for a follow-up query rather than a dead end.

## Connections
- Related concepts: [[wiki/concepts/multi-agent-analysis-pipeline]], [[wiki/concepts/smart-zone]], [[wiki/concepts/progressive-disclosure-hooks]]

---

- 2026-06-12 [Claude Code]: Page created from Longform Guide ingestion
