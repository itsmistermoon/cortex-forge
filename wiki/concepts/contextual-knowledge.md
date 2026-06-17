---
title: "Contextual Knowledge"
type: concept
created: 2026-06-08
updated: 2026-06-08
tags: [memory, context-window, epistemology]
aliases: [context knowledge, in-context knowledge]
sources:
  - wiki/sources/ai-coding-dictionary.md
confidence: high
schema_version: "0.3"
---

# Contextual Knowledge

Facts the agent can read directly from the context window right now. Counterpart to [[parametric-knowledge]].

## Properties

- **Current and verifiable.** Unlike parametric knowledge, contextual knowledge can be traced to a specific source in the context — a file, a doc, a vault page.
- **Ephemeral by default.** Lives only for the duration of the session. Without a memory system, it evaporates when the session ends.
- **The remedy for parametric gaps.** When parametric knowledge is too rare, too old, or explicitly disqualified — load the authoritative source into context instead.

## In the context of this vault

[[cortex-recall]] is the mechanism for loading contextual knowledge from the vault into the agent's context. When the agent reads a `wiki/` page, that content becomes contextual knowledge for the session.

The Cortex Forge protocol makes the distinction operational: vault knowledge loaded via `cortex-recall` is contextual (verifiable, citable). Knowledge from training alone is parametric (unverified, disqualified for vault topics).

---

- 2026-06-08 [Claude Code]: Page created from AI Coding Dictionary ingestion
