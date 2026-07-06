---
title: Progressive Disclosure via Hooks
type: concept
created: 2026-06-08
updated: 2026-06-08
tags: [hooks, skills, context-management, token-efficiency]
aliases: [just-in-time context, lazy context loading]
sources:
  - wiki/sources/gemini-cli-hooks-video.md
  - wiki/sources/obsidian-mind.md
confidence: medium
schema_version: "0.3"
---

# Progressive Disclosure via Hooks

Context loading pattern that avoids injecting everything at session start, instead loading information only when it is relevant to the current task.

## The problem it solves

Loading all available context at session start has two costs:
- **Tokens consumed** before the user asks their first question
- **Context noise**: irrelevant information competes with relevant information

## The pattern

Instead of a monolithic instructions file that is always loaded in full, context is distributed across hooks and skills:

- **Hooks (SessionStart)**: load only the minimum necessary state — pending items, active decisions, fragile context (hot cache)
- **Skills**: load specific expertise when activated for a concrete task; remain inactive (consuming no context) until needed

## Application in Cortex Forge

The separation between hot cache and wiki is an instance of this pattern:
- The hot cache (`## Current state` only) is injected at startup — it is the minimum viable
- The content of `wiki/` is loaded on demand via `cortex-recall` when the user queries a topic
- The History section of the hot cache is **not** injected (this was the 2026-06-08 fix to `load-hot-cache.sh`)

## Explicit tier model (Obsidian Mind)

Obsidian Mind makes the same pattern explicit with a per-tier token budget:

| Tier | What | Cost |
|------|------|------|
| Always | Operating manual + SessionStart excerpts (goals, git summary, file listing) | ~2K tokens |
| On-demand | Semantic search results when the agent needs specific context | Targeted |
| Triggered | Classification hints (per message) and write validation (per `.md` write) | ~100–200 tokens |
| Rare | Full file reads, only when explicitly needed | Variable |

The useful addition is the *budget*: each tier has a known cost ceiling, so the loading strategy can be reasoned about quantitatively instead of just "load less upfront."

## Tension with visibility

In [[wiki/entities/codex|Codex]], context injected by hooks is visible in the chat (`hook context:`). The progressive disclosure pattern reduces the impact of this visibility by minimizing the injected volume — less visible noise, fewer tokens consumed.

## Connections
- Related concepts: [[wiki/concepts/agent-hook-compatibility]], [[wiki/concepts/antigravity-hooks]], [[wiki/concepts/prompt-classification-hook]]

---

- 2026-06-08 [Claude Code]: Page created — concept extracted from the Gemini CLI hooks video; instantiated in the hot cache History fix
- 2026-06-08 [Claude Code]: Translated to English
- 2026-06-12 [Claude Code]: Added explicit tier model from Obsidian Mind ingestion
