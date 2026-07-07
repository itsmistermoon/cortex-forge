---
title: Hooks Configuration - Command Code
type: source
resource: https://commandcode.ai/docs/hooks/configuration
created: 2026-06-08
updated: 2026-06-08
tags: [commandcode, hooks, configuration, settings.json]
aliases: []
source_author: CommandCode
confidence: high
schema_version: "0.3"
raw: .raw/commandcode-hooks-configuration.md
---

# Hooks Configuration - Command Code

**URL:** https://commandcode.ai/docs/hooks/configuration
**Author:** CommandCode

## Summary

Command Code hooks are configured under the `hooks` key in a `settings.json` file. The doc specifies two scopes — user (`~/.commandcode/settings.json`) and project (`.commandcode/settings.json`) — with project taking precedence over user.

Within a single event, hooks fire in declared order; `PreToolUse` runs sequentially (a blocker stops the chain), while `PostToolUse` runs in parallel because the tool has already finished. Multiple hooks can be wired under a single matcher and run in listed order.

## Key ideas

1. Two config scopes: user (`~/.commandcode/settings.json`) and project (`.commandcode/settings.json`); precedence is project > user.
2. Within the same event, hook order is the order they appear in `settings.json` (project first, then user).
3. `PreToolUse` is sequential — first blocker short-circuits the rest. `PostToolUse` is parallel.
4. Multiple handlers under one matcher run in listed order; one is `command` typed with optional `timeout` (in seconds).
5. Wire format example shown uses nested `hooks` arrays per matcher, distinct from a flat array of handlers.

## Connections
- Related concepts: [[wiki/concepts/agent-hook-compatibility]]
- Projects: [[wiki/projects/cortex-forge]]

---

- 2026-06-08 [CommandCode / MiniMax-M3]: Page created
