---
type: source
title: "Antigravity CLI — CLI Reference"
resource: https://antigravity.google/docs/cli-reference
section: Antigravity CLI / Reference
created: 2026-06-08
tags: [antigravity, cli, reference]
confidence: high
raw: .raw/antigravity-cli/cli-reference.md
---

# CLI reference

Dense tables of TUI slash commands, default keyboard shortcuts, and JSON configuration keys.

## Core slash commands

Type `/` in the prompt box to open the typeahead selector.

| Command | Category | Alias | Purpose |
|---|---|---|---|
| `/add-dir <path>` | Utilities | — | Add a directory to active workspace |
| `/agents` | Tools & Tasks | — | Agent Manager Panel (background subagents) |
| `/btw <query>` | Utilities | — | Side question without interrupting main thread |
| `/clear` | Utilities | — | Clear terminal + reset conversation context |
| `/config` | Configurations | `/settings` | Interactive Settings Editor Overlay |
| `/diff` | Utilities | — | Unified diff of all modified workspace files |
| `/exit` | Core | — | Close TUI, restore host shell |
| `/fast` | Configurations | — | Bypass reasoning plans for quick actions |
| `/fork` | Conversations | `/branch` | Clone current thread into parallel session |
| `/hooks` | Tools & Tasks | — | Browse pre/post tool script hooks |
| `/keybindings` | Configurations | — | Keyboard Shortcut Editor |
| `/logout` | Account | — | Disconnect profile, purge auth tokens |
| `/mcp` | Tools & Tasks | — | MCP server manager |
| `/model` | Configurations | — | Choose reasoning model (persists across sessions) |
| `/open <path>` | Utilities | — | Force path to open in system editor |
| `/permissions` | Configurations | — | Switch permission preset (`request-review`, `always-proceed`, `strict`) |
| `/planning` | Configurations | — | Multi-turn plan generation mode |
| `/rename <name>` | Conversations | — | Rename current session thread |
| `/resume` | Conversations | `/switch`, `/conversation` | Conversation picker overlay |
| `/rewind` | Conversations | `/undo` | Roll back to previous message |
| `/skills` | Tools & Tasks | — | Browse local + global Agent Skills |
| `/statusline` | Configurations | — | Status Bar customization overlay |
| `/tasks` | Tools & Tasks | — | Task Manager Panel (background shell logs) |
| `/title [on/off]` | Configurations | — | Toggle/set terminal window title |
| `/usage` | Utilities | — | Offline developer help manual |

## Default keybindings

### Global

| Key | TUI Command | Action |
|---|---|---|
| `Esc` | `cli.escape` | Closes panels, halts streams, clears empty prompts |
| `Ctrl+C` | `cli.exit` | Terminates session (confirms if agent working) |
| `Ctrl+L` | `cli.clear_screen` | Refresh + clear visual terminal buffer |

### Prompt focus

| Key | TUI Command | Action |
|---|---|---|
| `Enter` | `prompt.submit` | Submits prompt / active selection |
| `Shift+Enter` / `Ctrl+J` | `prompt.newline` | Newline without submit |
| `Ctrl+V` | `prompt.paste` | Pastes media / clipboard blocks |
| `Ctrl+O` | `prompt.toggle_trajectory` | Expand/collapse tool reasoning |
| `Ctrl+R` | `prompt.open_review` | Opens Artifact Review Panel |
| `Ctrl+G` | `prompt.external_editor` | Launches `$EDITOR` to compose |
| `Alt+J` | `prompt.teleport_agent` | Switch to next subagent awaiting confirmation |
| `Ctrl+K` | `prompt.fast_approve` | Approve pending subagent action |
| `Ctrl+A` | `prompt.cursor_start` | Cursor to line start |
| `Ctrl+E` | `prompt.cursor_end` | Cursor to line end |
| `Ctrl+Z` | `prompt.undo_text` | Revert last edit |
| `Ctrl+Shift+Z` | `prompt.redo_text` | Redo last undone operation |

### Navigation & scrolling

| Key | TUI Command | Action |
|---|---|---|
| `↑` / `↓` | `navigation.up` / `.down` | Scroll highlighted selection |
| `PgUp` / `Shift+↑` | `navigation.page_up` | Viewport up one page |
| `PgDn` / `Shift+↓` | `navigation.page_down` | Viewport down one page |
| `←` / `→` | `navigation.left` / `.right` | Swap pages (Session Picker) |
| `Tab` | `navigation.tab` | Confirm highlighted slash-command autofill |

### Tool confirmations

| Key | TUI Command | Action |
|---|---|---|
| `y` | `confirm.yes` | Authorize tool/command/artifact |
| `n` | `confirm.no` | Reject tool/command/artifact |
| `A` | — | (Review Panel) Approve all artifacts in one action |

## `settings.json` configuration keys

| Key | Type | Default | Notes |
|---|---|---|---|
| `colorScheme` | string | `"terminal"` | `light`, `solarized light`, `colorblind-friendly light`, `dark`, `solarized dark`, `colorblind-friendly dark`, `tokyo night`, `terminal` |
| `altScreenMode` | string | `"default"` | `default` (auto), `always` (alt buffer), `never` (inline) |
| `toolPermission` | string | `"request-review"` | `request-review`, `proceed-in-sandbox`, `always-proceed`, `strict` |
| `artifactReviewPolicy` | string | `"asks-for-review"` | `asks-for-review`, `agent-decides`, `always-proceed` |
| `notifications` | boolean | `false` | System desktop + terminal bell on task completion |
| `showTips` | boolean | `true` | Show agentic tips above prompt |
| `showFeedbackSurvey` | boolean | `true` | Show quality surveys on task completion |
| `editor` | string | `"auto"` | `auto` (consults `$EDITOR`), `vim`, `emacs`, or custom |
| `allowNonWorkspaceAccess` | boolean | `false` | Permit file tools outside Git/workspace roots |
| `enableTerminalSandbox` | boolean | `false` | Restrict local execution to OS rings |
| `enableTelemetry` | boolean | `true` | Permit metric collection + crash log streaming |
| `verbosity` | string | `"high"` | `high` (full thoughts) or `low` (minimal progress) |
| `runningLightSpeed` | string | `"medium"` | `fast`, `medium`, `slow`, `off` |

## See also

- [Permissions & Sandbox](./antigravity-cli-permissions.md)
- [Plugins & Skills](./antigravity-cli-plugins.md)
- [Installation & Auth](./antigravity-cli-install)
