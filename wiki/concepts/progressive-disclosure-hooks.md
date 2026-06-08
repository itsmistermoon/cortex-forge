---
title: Progressive Disclosure via Hooks
type: concept
created: 2026-06-08
updated: 2026-06-08
tags: [hooks, skills, context-management, token-efficiency]
aliases: [just-in-time context, lazy context loading]
sources:
  - wiki/sources/gemini-cli-hooks-video.md
confidence: medium
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

## Tension with visibility

In Codex, context injected by hooks is visible in the chat (`hook context:`). The progressive disclosure pattern reduces the impact of this visibility by minimizing the injected volume — less visible noise, fewer tokens consumed.

## Connections
- Related concepts: [[wiki/concepts/agent-hook-compatibility]], [[wiki/concepts/antigravity-hooks]]

---

- 2026-06-08 [Claude Code]: Page created — concept extracted from the Gemini CLI hooks video; instantiated in the hot cache History fix
- 2026-06-08 [Claude Code]: Translated to English
