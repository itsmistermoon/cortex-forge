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

## Design decisions in this vault

The `.hot/MEMORY.md` format was designed with explicit tradeoffs relative to other handoff implementations (notably Matt Pocock's `/handoff` skill):

| Decision | This vault | Alternative |
|----------|-----------|-------------|
| **Location** | `.hot/` inside the repo (gitignored) | OS `/tmp` (Matt Pocock's approach) |
| **Why** | The next agent starts in the same repo and must find the artifact without extra coordination. `/tmp` is fine for human-readable handoffs, but agents need a stable, discoverable path relative to the project root. |  |
| **Structure** | Two zones: mutable Current state + append-only History | Single compacted document |
| **Why** | Current state stays small and actionable (injected fresh each session); History accumulates context without polluting the working zone. A single doc grows unbounded and degrades. | |
| **Naming** | Fixed name `MEMORY.md` per repo | Named after the project (e.g., `cortex-forge.md`) |
| **Why** | One file per repo — no project-name detection needed. Each repo has its own `.hot/` so there's no collision risk across projects. | |

### Compaction vs Handoff

The same file serves two distinct triggers — but they are epistemologically different:

- **PreCompact** (compaction): the session continues after this snapshot. Claude Code's harness compresses history. The artifact is a mid-session checkpoint — prioritize structure and decisions.
- **SessionEnd** (handoff): the session terminates. No return path — the next agent starts cold from this artifact alone. Prioritize completeness and "enough to resume from scratch."

The History zone labels each entry with its trigger so readers know what kind of snapshot it is.

### Suggested skills

A handoff artifact can optionally include a `### Suggested skills` section listing skills the next session should invoke to continue the work. This makes the artifact self-contained for any agent that starts cold from it.

## Related

- [[memory-system]] — the broader system that uses handoff artifacts
- [[smart-zone]] — why handoffs are necessary (sessions degrade over time)

---

- 2026-06-08 [Claude Code]: Page created from AI Coding Dictionary ingestion
- 2026-06-08 [Claude Code]: Added design decisions section: location rationale, two-zone structure, compaction vs handoff distinction, suggested skills
