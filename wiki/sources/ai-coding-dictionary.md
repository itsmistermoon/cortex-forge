---
title: "AI Coding Dictionary"
type: source
resource: 
created: 2026-06-08
updated: 2026-06-10
tags: [ai-agents, vocabulary, reference]
source_url: https://www.aihero.dev/ai-coding-dictionary
source_date: 2026
source_author: Matt Pocock
sources: []
confidence: high
schema_version: "0.3"
raw: 
---

# AI Coding Dictionary

**URL:** https://www.aihero.dev/ai-coding-dictionary
**Author:** Matt Pocock (AI Hero)

## Summary

68 plain-English definitions for the vocabulary of AI coding, organized into 7 sections. Skimmable, opinionated, precise. Intended as a shared vocabulary for AI engineers — each term is a concept that makes agentic coding click.

## Key ideas

1. The model is stateless and does only next-token prediction — everything agentic comes from the harness around it.
2. Parametric knowledge (training) and contextual knowledge (context window) are the two distinct epistemic layers — most agent failures come from confusing them.
3. Sessions degrade over time (smart zone → dumb zone) due to attention budget dilution — handoffs and compaction are the structural remedy.
4. Memory systems make agents stateful across sessions by persisting to the environment and reloading at session start — `AGENTS.md` is a canonical example.
5. Skills, context pointers, and progressive disclosure are the vocabulary for managing what enters the context window and when.

## Sections

| Section | Terms |
|---------|-------|
| The Model | 15 |
| Sessions, Context Windows & Turns | 8 |
| Tools & Environment | 10 |
| Failure Modes | 9 |
| Handoffs | 9 |
| Memory and Steering | 6 |
| Patterns of Work | 11 |

## Connections

- Related concepts: [[parametric-knowledge]], [[contextual-knowledge]], [[memory-system]], [[handoff-artifact]], [[smart-zone]], [[progressive-disclosure-hooks]], [[primary-source]], [[secondary-source]]
- Expanded entries (full articles, ingested separately): [[ai-coding-dictionary-primary-source]], [[ai-coding-dictionary-secondary-source]]

---

- 2026-06-08 [Claude Code]: Page created
- 2026-06-10 [Claude Code]: Primary source and Secondary source entries expanded with full articles (this page covers only the one-line index definitions)
