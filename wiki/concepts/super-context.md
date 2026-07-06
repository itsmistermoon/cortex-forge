---
title: Super Context
type: concept
created: 2026-06-26
updated: 2026-07-06
tags: [session-start, context-injection, harness, cold-start]
aliases: [supercontext, super-context, context-scout]
sources:
  - wiki/sources/openhuman-super-context.md
confidence: high
schema_version: "0.3"
---

# Super Context

A harness-level pattern that eliminates agent cold starts by deterministically preparing context before the model reads the user's first message, rather than relying on the model to decide whether and when to fetch context.

## The problem

Most agents start every session blank. If context retrieval is exposed as a tool, the model must decide to call it — adding a round-trip, spending tokens on the decision, and depending on the model choosing correctly. Even when the model decides well, the first reply is already partially uninformed.

## The pattern

On the first turn of a new thread:

1. A read-only **context scout** sub-agent (spawned by the harness, not the model) sweeps available memory: notes, workspace files, connected data sources.
2. The scout assembles a bounded **context bundle** tagged with an envelope (`[context_bundle]…[/context_bundle]`).
3. The bundle is validated. If well-formed, it is prepended to the user's message before the orchestrator model sees the turn.
4. The orchestrator model answers already grounded in context.

Key properties:
- **Deterministic** — the harness always runs this; the model cannot skip it.
- **Read-only scout** — prevents injection or side effects at bootstrap.
- **Graceful degradation** — malformed, empty, or absent bundle → cold start, not garbage injection.
- **Dedup suppression** — the `agent_prepare_context` tool is suppressed for that turn to avoid repeating the work.

## Cortex Forge equivalent

Cortex Forge pursues the same guarantee via a different mechanism: `AGENTS.md` mandates that the agent read `.cortex/MEMORY.md` before its first response — identically on every agent, with no hook wiring required. This wasn't the original design: Cortex Forge used a `SessionStart` hook for this until 2026-07-02, when it was removed because hook support was too uneven across Claude Code, Codex, Antigravity, and CommandCode to build the suite on top of it (see [[wiki/concepts/agent-hook-compatibility]]). The tradeoff was deliberate: giving up harness-guaranteed determinism (the model literally cannot skip a hook) for cross-agent portability (a written protocol works anywhere, a hook only works where the harness supports one) — the same result depends on the agent following an instruction rather than an OS-level guarantee.

| | OpenHuman SuperContext | Cortex Forge |
|---|---|---|
| **Execution layer** | Harness-internal (Python/Rust app) | Manual protocol — `AGENTS.md` instructs the agent, no hook or harness-level guarantee |
| **Context source** | Memory Tree (auto-fetched from integrations) | `.cortex/MEMORY.md` (agent-synthesized from wiki) |
| **Scout** | Dedicated read-only sub-agent | Not applicable — file read is direct |
| **Portability** | OpenHuman-only | Any agent capable of reading a file and following a written instruction — no hook support required |
| **Content origin** | Automatic (integrations pull data) | Manual / agent-synthesized (cortex-crystallize) |
| **Guarantee** | Harness-enforced — the model cannot skip it | Protocol-enforced — depends on the agent following `AGENTS.md` |

## When to use this pattern

Any agent system where:
- Sessions are stateless by default
- The relevant context is known in advance (not discovered mid-conversation)
- Token budget at session start is more constrained than mid-session
- Model reliability in calling "prepare context" tools is below acceptable threshold

## See also

- [[wiki/concepts/progressive-disclosure-hooks]] — complementary: loads context just-in-time for specific queries rather than upfront
- [[wiki/concepts/handoff-artifact]] — `.cortex/MEMORY.md` as the Cortex Forge instance of the context bundle
- [[wiki/concepts/memory-system]] — broader pattern of which super-context is a session-start component
- [[wiki/entities/openhuman]] — origin of the term and reference implementation
- [[wiki/concepts/agent-hook-compatibility]] — why the SessionStart hook this page originally described was removed (2026-07-02)

---

- 2026-06-26 [Claude Code]: Concept created from OpenHuman SuperContext feature article; Cortex Forge equivalence mapped
- 2026-07-06 [Claude Code]: Corrected the "Cortex Forge equivalent" section and comparison table — described a `SessionStart` hook and `.hot/MEMORY.md` path that no longer exist (hooks removed 2026-07-02, path moved to `.cortex/`). Rewrote as the current manual `AGENTS.md` protocol, and added the harness-guarantee-vs-portability tradeoff this change represents.
