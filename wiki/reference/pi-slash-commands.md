---
title: Pi slash commands
type: concept
created: 2026-06-16
updated: 2026-06-16
tags: [pi, slash-commands, reference]
sources:
  - wiki/sources/pi-usage.md
confidence: high
schema_version: "0.3"
aliases: []
---

# Pi slash commands

Type `/` in the editor to open command completion. Extensions can register custom commands. Skills are available as `/skill:name`. Prompt templates expand via `/templatename`.

## Built-in Commands

| Command | Description |
|---------|-------------|
| `/login` | Manage OAuth or API-key credentials |
| `/logout` | Manage OAuth or API-key credentials |
| `/model` | Switch models |
| `/scoped-models` | Enable/disable models for Ctrl+P cycling |
| `/settings` | Thinking level, theme, message delivery, transport |
| `/resume` | Pick from previous sessions |
| `/new` | Start a new session |
| `/name <name>` | Set session display name |
| `/session` | Show session file, ID, messages, tokens, and cost |
| `/tree` | Jump to any point in the session and continue from there |
| `/fork` | Create a new session from a previous user message |
| `/clone` | Duplicate the current active branch into a new session |
| `/compact [prompt]` | Manually compact context, optionally with custom instructions |
| `/copy` | Copy last assistant message to clipboard |
| `/export [file]` | Export session to HTML |
| `/share` | Upload as private GitHub gist with shareable HTML link |
| `/reload` | Reload keybindings, extensions, skills, prompts, and context files |
| `/hotkeys` | Show all keyboard shortcuts |
| `/changelog` | Display version history |
| `/trust` | Save a project trust decision for future sessions |
| `/quit` | Quit pi |

## Editor Input Prefixes

| Prefix | Behavior |
|--------|----------|
| `@` | Fuzzy-search project files; inserts reference into the message |
| `!command` | Run shell command; output sent to the model |
| `!!command` | Run shell command; output NOT sent to the model |
| `path` + `Tab` | Path completion |

## Editor Shortcuts

| Shortcut | Action |
|----------|--------|
| `Shift+Enter` | Insert newline (multi-line input) |
| `Ctrl+Enter` | Multi-line input on Windows Terminal |
| `Ctrl+V` | Paste image |
| `Alt+V` | Paste image on Windows |
| `Ctrl+G` | Open external editor (`$VISUAL` or `$EDITOR`) |

## Extension-Registered Commands

Extensions register slash commands via `pi.registerCommand()`. After registration, they appear in the `/` completion list with the extension's provided description. See [[pi-extension-api]] for the registration method and [[pi-event-types]] for related lifecycle hooks.

## Skill and Template Commands

| Pattern | Behavior |
|---------|----------|
| `/skill:name` | Invoke a skill |
| `/templatename` | Expand a prompt template |

Skills are loaded from `~/.pi/agent/skills/` and `.pi/skills/`. Prompt templates from `~/.pi/agent/prompts/` and `.pi/prompts/`. Both are auto-discovered unless `--no-skills` / `--no-prompt-templates` is set. See [[pi-cli-flags]] for discovery flags.

## Session-Specific Notes

- `/session` shows the current session file and ID.
- `/tree` navigates the in-file session tree and can summarize abandoned branches.
- `/fork` creates a new session from an earlier user message.
- `/clone` duplicates the current active branch into a new session file.
- `/compact` summarizes older messages to free context.
- `/export` writes the session to HTML.
- `/share` uploads a private GitHub gist with a shareable HTML link.

---

- 2026-06-16 [CommandCode]: Page created
