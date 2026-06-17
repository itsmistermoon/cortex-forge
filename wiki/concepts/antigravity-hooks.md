---
title: Antigravity Hooks
type: concept
created: 2026-06-07
updated: 2026-06-08
tags: [hooks, lifecycle, configurations, gemini-cli]
aliases: [lifecycle-hooks]
sources:
  - wiki/sources/antigravity-hooks.md
  - wiki/sources/gemini-cli-hooks-video.md
confidence: medium
schema_version: "0.3"
---

# Antigravity Hooks

Antigravity Hooks define the configuration and execution pattern for extending the agent lifecycle in the [[google-antigravity]] / Gemini CLI ecosystem. They allow inserting verification, initialization, and context loading steps into the agent loop.

## Configuration file

Antigravity inherits the Gemini CLI path. Global hooks are read from:

```
~/.gemini/config/hooks.json
```

The difference from Gemini CLI (which uses `settings.json`) is that Antigravity uses a separate `hooks.json` — same directory, different file.

### Known bug in agy-cli (issue #49)

There is a path alignment bug in the CLI:

- **Read path (correct)**: `~/.gemini/config/hooks.json`
- **Write path (incorrect)**: `~/.gemini/antigravity-cli/hooks.json`

If hooks are created or modified using CLI commands, the file is written to the wrong path and hooks are not executed.

**Workaround until patched**: create and edit `hooks.json` manually at the correct path, or create a symlink:

```bash
ln -s ~/.gemini/config/hooks.json ~/.gemini/antigravity-cli/hooks.json
```

## Scopes

- **Global**: `~/.gemini/config/hooks.json` — available in all projects
- **Workspace**: `.agents/hooks.json` in the project root

## Scripts path

There is no platform-imposed path. Scripts can live in any absolute directory. Recommended convention for Cortex Forge: `~/.gemini/config/hooks/` (aligned with the global scope).

## Mechanisms

### 1. JSON configuration
Static mapping of events to scripts or commands. Supported events include session lifecycle (`SessionStart`, `Stop`) and tool events.

### 2. SDK (Python)
Programmatic hooks to observe, modify, or block tool calls and agent actions dynamically.

### 3. SessionStart
Event fired at session start. Primary use case: load previous session context (hot cache), verify environment state, initialize dependencies.

## Skills folder

The standardized provider-agnostic folder is `.agents/skills/`. Gemini CLI also reads from `.gemini/skills/`. For maximum multi-agent compatibility, use `.agents/skills/`.

## Connections
- Related concepts: [[wiki/concepts/agent-hook-compatibility]], [[wiki/concepts/progressive-disclosure-hooks]]
- Entities: [[wiki/entities/google-antigravity]], [[wiki/entities/antigravity-cli]]

---

- 2026-06-07 [Antigravity]: Page created
- 2026-06-08 [Claude Code]: Updated with findings from official Gemini CLI video — scopes and scripts path clarified; skills folder standardized
- 2026-06-08 [Claude Code]: Path alignment bug documented (agy-cli issue #49) — CLI read vs write paths differ; workaround: manual edit or symlink
- 2026-06-08 [Claude Code]: Translated to English
