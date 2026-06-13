---
title: "Prompt Classification Hook"
type: concept
created: 2026-06-12
updated: 2026-06-12
tags: [hooks, context-management, routing, token-efficiency]
aliases: [classification routing, UserPromptSubmit classifier]
sources:
  - wiki/sources/obsidian-mind.md
confidence: high
---

# Prompt Classification Hook

Pattern where a `UserPromptSubmit` hook classifies each incoming user message into known content categories and injects *routing hints* — not content — so the agent files information correctly without the user issuing explicit commands.

## The problem it solves

Capturing knowledge mid-conversation usually requires the user to invoke a command ("save this as a decision"). Without that discipline, decisions, wins, and context get lost in the transcript. Relying on the agent to spontaneously notice and route every capturable item is unreliable.

## The pattern

1. A lightweight deterministic script (one Node call, ~100 tokens of output) runs on every user message.
2. It classifies the message against a fixed taxonomy — in Obsidian Mind: decision, incident, win, 1:1, architecture, person, project update.
3. On a match, it injects a short hint into context ("this looks like a decision — route it to a decision record"), nudging the agent to apply the corresponding capture protocol.

The hook never writes content. Classification is procedural; the writing and linking remain agent judgment. This is an instance of "procedural code owns the environment, the agent owns content."

## Application in Cortex Forge

Cortex Forge captures at session boundaries (`cortex-crystallize` on Stop/SessionEnd) but has nothing mid-session: a decision made at minute 5 only survives if it's still salient at crystallize time. A classification hook on `UserPromptSubmit` would close that gap — e.g., detecting "decidimos X" and hinting the agent to append it to the hot cache's Active decisions immediately. Requires `UserPromptSubmit` support per agent — see [[wiki/concepts/agent-hook-compatibility]].

## Connections
- Related concepts: [[wiki/concepts/progressive-disclosure-hooks]], [[wiki/concepts/agent-hook-compatibility]], [[wiki/concepts/memory-system]]

---

- 2026-06-12 [Claude Code]: Page created from Obsidian Mind ingestion
