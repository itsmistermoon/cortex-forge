---
title: "OpenHuman — SuperContext feature documentation"
type: source
resource: https://github.com/tinyhumansai/openhuman/blob/main/gitbooks/features/super-context.md
created: 2026-06-26
updated: 2026-06-26
source_author: senamakel (tinyhumansai)
tags: [agent-harness, context-injection, session-start, comparable-project]
confidence: high
schema_version: "0.3"
raw: .raw/openhuman-super-context.md
---

# OpenHuman — SuperContext feature documentation

**URL:** https://github.com/tinyhumansai/openhuman/blob/main/gitbooks/features/super-context.md
**Original date:** 2026-06-26 (last commit: Docs/overhaul readme gitbooks #4225)
**Author:** @senamakel / tinyhumansai

## Summary

SuperContext is OpenHuman's harness-level mechanism that eliminates cold starts. On the first turn of every new thread, a read-only `context_scout` sub-agent sweeps the Memory Tree, workspace files, and connected integrations, and assembles a bounded context bundle. The bundle is validated and prepended to the user's message before the orchestrator model reads it, using `[context_bundle]…[/context_bundle]` envelope tags. If the bundle is malformed or absent, the turn proceeds normally — graceful degradation is explicit.

## Key ideas

1. **Harness-level, not model-level** — context preparation is deterministic (the harness always runs it) rather than model-driven (the model decides to call a "prepare context" tool). Eliminates the round-trip and model-choice dependency.

2. **Read-only scout sub-agent** — the `context_scout` can never take actions on a fresh thread, only read. This prevents injection attacks from bootstrap context affecting the first action.

3. **Tag-delimited bundle with strip logic** — only the `[context_bundle]…[/context_bundle]` content is injected; surrounding model prose is stripped. Malformed, empty, or reversed tags fall back to no injection (cold start preferred over garbage injection).

4. **Suppresses duplicate tool call** — because the scout runs in the harness, the `agent_prepare_context` tool is suppressed for that turn so the orchestrator doesn't repeat the work.

5. **Toggleable per-thread** — `context.super_context_enabled` (default `true`); toggle appears in the UI composer for new threads. Also configurable via env var and RPC.

## Connections

- Related concepts: [[wiki/concepts/super-context]], [[wiki/concepts/progressive-disclosure-hooks]], [[wiki/concepts/memory-system]], [[wiki/concepts/handoff-artifact]]
- Entities: [[wiki/entities/openhuman]]
- Projects: [[wiki/projects/cortex-forge]] — Cortex Forge's `SessionStart` hook + `.hot/MEMORY.md` is the architectural equivalent; key difference is hook-script vs harness-level execution
- Related sources: [[wiki/sources/openhuman]]

---

- 2026-06-26 [Claude Code]: Page created — featured article ingested as primary source (raw: .raw/openhuman-super-context.md)
