---
type: source
title: "AI Coding Dictionary — Secondary source (full article)"
resource: https://www.aihero.dev/ai-coding-dictionary/secondary-source
created: 2026-06-10
updated: 2026-06-10
tags: [epistemology, context-engineering, provenance]
aliases: []
confidence: high
schema_version: "0.3"
raw: .raw/ai-coding-dictionary-secondary-source.md
---

# AI Coding Dictionary — Secondary source (full article)

**URL:** https://www.aihero.dev/ai-coding-dictionary/secondary-source
**Author:** Matt Pocock (AI Hero)

## Summary

Full dictionary article expanding the one-line index definition. A secondary source is an account of a primary source, one step removed — cheaper to load, lossy by construction. The article frames context engineering as the manufacture of secondary sources, names their two failure modes, and describes the context-pointer remedy.

## Key ideas

1. A lot of context engineering is the manufacture of secondary sources: compaction summaries, subagent reports, handoff artifacts, memory notes. Each trades fidelity for headroom.
2. Two failure modes: **lossy** (the summary dropped the detail that mattered) and **drift** (the primary changed and the account didn't follow). An agent acting on either works confidently from wrong information.
3. Neither failure makes secondary sources a mistake — the context window is finite. The skill is knowing which details survive the loss, and verifying against the primary when one can't.
4. A well-made secondary source carries a **context pointer** back to its original — the summary that names its transcript, the doc that names its file — so the reader can follow the pointer rather than work from the loss.

## Connections

- Related concepts: [[primary-source]], [[secondary-source]], [[handoff-artifact]], [[memory-system]]
- Sibling source: [[ai-coding-dictionary]] (index, one-line definitions)

---

- 2026-06-10 [Claude Code]: Page created from full-article ingestion
