---
title: "Continuous Learning Loop"
type: concept
created: 2026-06-12
updated: 2026-06-12
tags: [memory, skills, hooks, self-improvement]
aliases: [session-to-skill extraction, learned skills]
sources:
  - wiki/sources/claude-code-longform-guide.md
confidence: medium
schema_version: "0.3"
---

# Continuous Learning Loop

Pattern where the agent's sessions are evaluated for non-trivial discoveries — debugging techniques, workarounds, project-specific patterns — and those discoveries are persisted as reusable skills, so the correction never has to be repeated.

## The problem it solves

Users re-issue the same corrective prompts across sessions ("don't do X, I already told you"). Each repetition wastes tokens and trust. The knowledge existed in a past session but had nowhere durable to live.

## The pattern

1. A **Stop hook** evaluates the complete session for extractable patterns and saves them as skill files (e.g. `skills/learned/`), loaded automatically when a similar problem appears.
2. A manual command (`/learn`) extracts a pattern mid-session right after solving something non-trivial, with user confirmation.
3. Variants: a reflection agent distilling user preferences from session logs into a memory file (RLanceMartin's "diary"), or periodic proactive suggestions the user approves/rejects (alexhillman).

Session-end evaluation is deliberately preferred over per-message evaluation (UserPromptSubmit): it sees the complete arc, adds no latency, and runs once. Contrast with [[wiki/concepts/prompt-classification-hook]], which optimizes for *routing* mid-session, not extraction.

## Application in Cortex Forge

`cortex-crystallize` already runs at Stop, but it extracts *state* (pending, decisions, fragile context), not *lessons*. A learning loop would extract the reusable correction — closer to what CommandCode's TASTE does implicitly ([[wiki/concepts/commandcode-taste]]). The output target differs too: skills (executable behavior) rather than wiki pages (knowledge). Security note: skills extracted automatically are supply-chain artifacts — see [[wiki/concepts/memory-as-attack-surface]].

## Connections
- Related concepts: [[wiki/concepts/commandcode-taste]], [[wiki/concepts/memory-system]], [[wiki/concepts/prompt-classification-hook]], [[wiki/concepts/handoff-artifact]]

---

- 2026-06-12 [Claude Code]: Page created from Longform Guide ingestion
