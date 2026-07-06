---
title: crystallize vs imprint — design boundary
type: concept
created: 2026-06-30
updated: 2026-07-06
tags: [cortex-forge/protocol, skills, memory, knowledge-management, design-decision]
aliases: [crystallize vs imprint, memory vs wiki, hot cache vs knowledge graph]
sources:
  - conversation 2026-06-30
confidence: high
schema_version: "0.3"
---

# crystallize vs imprint — design boundary

Two skills in Cortex Forge that both "preserve something valuable from a session", but solve fundamentally different problems. The surface similarity is what makes the boundary worth documenting.

## The distinction

| | `cortex-crystallize` | `cortex-imprint` |
|---|---|---|
| **Destination** | `.cortex/MEMORY.md` (gitignored) | `wiki/` (versioned) |
| **Permanence** | Mutable — overwritten on every session | Immutable — updated as a document |
| **Audience** | The next agent in this same session or project | Any agent in any future project |
| **Trigger** | Manual, but routine — invoked at milestones and session close every session | Manual, exceptional — invoked only when something is worth permanent archiving |
| **What it captures** | Operational state: what's pending, what was decided, what to resume | Distilled knowledge: principles, analyses, decisions that outlast the project |
| **Scope** | Project-scoped — tied to the active repo's context | Vault-scoped — part of the knowledge graph, queryable by any skill |

## Why the confusion arises

Both skills run at the end of a session. Both write something that persists. But they write to different layers of the system:

- **crystallize writes to the hot cache** — ephemeral, local, session-oriented. It answers "where did we leave off?" It degrades gracefully: stale entries get pruned, the zone has hard size limits, and its value decays as the project evolves.
- **imprint writes to the knowledge graph** — permanent, versioned, cross-session. It answers "what did we learn that's worth consulting forever?" It doesn't degrade — it either stays relevant or gets explicitly updated.

## The handoff mechanism

crystallize is the upstream step. The `#### Imprint candidate` section in a history entry flags a synthesis produced during the session that *might* deserve permanent archiving. `AGENTS.md`'s mandatory session-start read protocol surfaces this flag the next session as a nudge to run `/cortex-imprint`. The user decides whether to act on it.

This means:
- crystallize runs at every milestone and session close — manually invoked, never via a hook.
- imprint runs only when something exceptional happened — a non-obvious conclusion, a grounded design decision, a pattern worth consulting in unrelated future projects.

## Decision rule

**Use crystallize** if the information answers "what's next for this project?".

**Use imprint** if the information answers "what would I want to know in a completely different project, 6 months from now?".

If neither question fits cleanly, it belongs in crystallize and can be reconsidered later — the cost of a missed imprint is lower than the cost of a wiki page that isn't self-contained or doesn't generalize.

## Related

- [[wiki/concepts/memory-system]] — broader context on stateful agents
- [[wiki/concepts/handoff-artifact]] — MEMORY.md as an instance of this pattern
- [[wiki/concepts/primary-source]] — why imprint requires tracing to primary sources before writing
- [[wiki/concepts/agent-hook-compatibility]] — why cortex-forge removed agent lifecycle hooks entirely (2026-07-02), replacing them with the manual protocol both skills now rely on
- [[wiki/concepts/workflow-architecture]] — the current session flow (hooks-free) this page's Trigger row describes

---

- 2026-07-06 [Claude Code]: Corrected "Trigger" row and handoff mechanism — both described SessionEnd/PreCompact/SessionStart hooks removed 2026-07-02; crystallize is manually invoked, not automatic.
