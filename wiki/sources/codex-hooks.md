---
title: Hooks - Codex
type: source
resource: 
created: 2026-06-08
updated: 2026-06-10
tags: [codex, hooks, lifecycle, configuration]
source_url: https://developers.openai.com/codex/hooks
source_date:
source_author: OpenAI
sources:
  - .raw/codex-hooks.md
confidence: high
schema_version: "0.3"
raw: 
---

# Hooks - Codex

**URL:** https://developers.openai.com/codex/hooks
**Original date:** 
**Author:** OpenAI

## Summary

Codex hooks let you attach commands or logic to session and tool lifecycle events, with matcher-based routing, trust review for non-managed hooks, and structured outputs that can add context, block actions, or control continuation.

The page describes how hooks are grouped, how trust works, and which events are supported across session start, tool use, prompt submission, compaction, subagent stop, and stop/continue behavior.

It also clarifies that hooks are enabled by default, that multiple matching hooks from multiple files all run, and that several events are turn-scoped while `SessionStart` and `SubagentStart` are thread/subagent-scope events.

The doc also clarifies that project-local hooks require a trusted `.codex/` layer, plugin-bundled hooks follow the same trust flow, and managed hooks are policy-trusted and not user-disableable. The CLI exposes `/hooks` for reviewing, trusting, and disabling non-managed hooks.

## Key ideas

1. Hooks are defined as event + matcher group + handler list.
2. Non-managed hooks require explicit review and trust before execution.
3. Supported events cover session, tool, compaction, prompt, subagent, and stop lifecycle points.
4. Hook outputs can inject extra context, block behavior, or continue a turn depending on the event.
5. `Stop` does not use `matcher`; it expects JSON output on stdout when exiting `0`, or exit code `2` with the continuation reason on stderr.
6. `transcript_path` is available as a convenience field, but the docs warn that transcript format is not a stable hook interface.

## Connections
- Related concepts: [[wiki/concepts/agent-hook-compatibility]]
- Projects: 

---

- 2026-06-08 [Claude Code]: Page created
