---
title: "Handoff Artifact"
type: concept
created: 2026-06-08
updated: 2026-06-08
tags: [handoffs, session-management, memory]
aliases: [carry artifact, session artifact]
sources:
  - wiki/sources/ai-coding-dictionary.md
confidence: high
---

# Handoff Artifact

A document used as the carry mechanism for a handoff — written by one session to be read by another. The bridge across the stateless gap between sessions.

**Supertype:** handoff (transferring agent context from one session to another, with no return path)

## Variants in the dictionary

| Artifact | Purpose |
|----------|---------|
| **Spec** | Describes a multi-session piece of work — what's being built, not how. Made of tickets. |
| **Ticket** | Scopes one session of work. Stands alone or hangs off a spec. Can block/be blocked by siblings. |
| **Compaction summary** | Produced by compaction — the previous session's history condensed to seed a fresh session. Lossy. |

## In the context of this vault

`.hot/MEMORY.md` is a handoff artifact. It is:
- Written by `cortex-crystallize` at session end
- Read by the next agent at session start (via hook or manually)
- Structured to minimize loss: mutable Current state + append-only History

The two-zone structure of `MEMORY.md` addresses the core tension of handoff artifacts: Current state is optimized for the next session to act on immediately; History preserves the audit trail without cluttering the working context.

## Related

- [[memory-system]] — the broader system that uses handoff artifacts
- [[smart-zone]] — why handoffs are necessary (sessions degrade over time)

---

- 2026-06-08 [Claude Code]: Page created from AI Coding Dictionary ingestion
