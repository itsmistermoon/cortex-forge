---
title: "Memory System"
type: concept
created: 2026-06-08
updated: 2026-06-08
tags: [memory, session-management, architecture]
aliases: [agent memory, persistent memory]
sources:
  - wiki/sources/ai-coding-dictionary.md
  - wiki/sources/yt-claude-code-memory-compared.md
confidence: high
schema_version: "0.3"
---

# Memory System

A system that attempts to make an agent stateful across sessions by persisting information to the environment and reloading it at session start.

Agents are stateless by default — each session starts empty. A memory system is the structural solution to this.

## Mechanism

1. **Persist** — at session end, write relevant context to the environment (filesystem, database, etc.)
2. **Reload** — at session start, read that context back into the context window

The environment is the only place information can survive across sessions. A memory system is just a disciplined use of that fact.

## In the context of this vault

Cortex Forge is a memory system. Its components map directly to the pattern:

| Component | Role |
|-----------|------|
| `.hot/MEMORY.md` | Persistence artifact — written at session end, read at session start |
| `cortex-crystallize` | The persist step |
| `cortex-reactivate` (hook) | The reload step |
| `wiki/` | Long-term synthesized memory — persisted across all sessions |
| `cortex-recall` | Selective reload — loads only relevant vault pages into context |

`AGENTS.md` is the minimal memory system: a single file the harness loads at session start, giving the agent its standing brief.

## Related concepts

- [[handoff-artifact]] — the document used to carry context across sessions
- [[progressive-disclosure-hooks]] — loading only the context needed right now
- [[contextual-knowledge]] — what the memory system injects into the context window

---

- 2026-06-08 [Claude Code]: Page created from AI Coding Dictionary ingestion
