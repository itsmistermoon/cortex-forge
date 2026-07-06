---
title: "Handoff Artifact"
type: concept
created: 2026-06-08
updated: 2026-07-06
tags: [handoffs, session-management, memory]
aliases: [carry artifact, session artifact]
sources:
  - wiki/sources/ai-coding-dictionary.md
confidence: high
schema_version: "0.3"
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

`.cortex/MEMORY.md` is a handoff artifact. It is:
- Written by `cortex-crystallize` at milestones and session close (manually invoked)
- Read by the next agent before its first response — `AGENTS.md`'s mandatory read protocol, identical on every agent, no hook involved
- Structured to minimize loss: mutable Current state + append-only History

The two-zone structure of `MEMORY.md` addresses the core tension of handoff artifacts: Current state is optimized for the next session to act on immediately; History preserves the audit trail without cluttering the working context.

## Design decisions in this vault

The `.cortex/MEMORY.md` format was designed with explicit tradeoffs relative to other handoff implementations (notably Matt Pocock's `/handoff` skill):

| Decision | This vault | Alternative |
|----------|-----------|-------------|
| **Location** | `.cortex/` inside the repo (gitignored) | OS `/tmp` (Matt Pocock's approach) |
| **Why** | The next agent starts in the same repo and must find the artifact without extra coordination. `/tmp` is fine for human-readable handoffs, but agents need a stable, discoverable path relative to the project root. |  |
| **Structure** | Two zones: mutable Current state + append-only History | Single compacted document |
| **Why** | Current state stays small and actionable (injected fresh each session); History accumulates context without polluting the working zone. A single doc grows unbounded and degrades. | |
| **Naming** | Fixed name `MEMORY.md` per repo | Named after the project (e.g., `cortex-forge.md`) |
| **Why** | One file per repo — no project-name detection needed. Each repo has its own `.cortex/` so there's no collision risk across projects. | |

### Mid-session vs Handoff

The same file serves two distinct triggers, inferred from the user's invocation intent rather than any agent-specific hook name (cortex-forge removed all agent lifecycle hooks 2026-07-02 — see [[wiki/concepts/agent-hook-compatibility]]):

- **Mid-session**: the user wants a checkpoint but the conversation continues. The artifact is a snapshot — prioritize structure and decisions.
- **Handoff**: a real close, no return path — the next agent starts cold from this artifact alone. Prioritize completeness and "enough to resume from scratch."

The History zone labels each entry with its trigger so readers know what kind of snapshot it is.

### Pending, not a fixed section

An earlier design had a rigid `### Suggested skills` subsection for naming what the next session should invoke. It was removed in favor of folding that suggestion, when there is one, into `### Pending` — one less structural section to keep populated on every write, same information when it's actually needed.

## Related

- [[memory-system]] — the broader system that uses handoff artifacts
- [[smart-zone]] — why handoffs are necessary (sessions degrade over time)
- [[wiki/concepts/agent-hook-compatibility]] — why cortex-forge removed agent lifecycle hooks entirely (2026-07-02)

---

- 2026-06-08 [Claude Code]: Page created from AI Coding Dictionary ingestion
- 2026-06-08 [Claude Code]: Added design decisions section: location rationale, two-zone structure, compaction vs handoff distinction, suggested skills
- 2026-07-06 [Claude Code]: Corrected throughout: `.hot/MEMORY.md` path (moved to `.cortex/MEMORY.md`), PreCompact/SessionEnd hook-based triggers (agent lifecycle hooks removed 2026-07-02 — reframed as Mid-session/Handoff, inferred from user intent), and the rigid `### Suggested skills` section (removed from the actual format, folded into `### Pending` instead)
