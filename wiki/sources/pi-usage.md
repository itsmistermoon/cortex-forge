---
type: source
title: "Using Pi"
resource: https://pi.dev/docs/latest/usage
section: usage
created: 2026-06-16
tags: [pi, coding-agent, cli, tui, sessions, slash-commands, modes]
confidence: high
schema_version: "0.3"
raw: .raw/pi-usage.md
sources:
  - .raw/pi-usage.md
---

# Using Pi

**URL:** https://pi.dev/docs/latest/usage
**Original date:** 2026-06-16
**Author:** Mario Zechner / pi-mono

## Summary

Official guide to operating pi in interactive and non-interactive modes. Covers the four-area TUI layout, slash commands, the message queue (steering vs follow-up), session persistence and forking, context file discovery, project trust flow, export/share, and the full CLI surface. The "design principles" section confirms that pi keeps the core small and pushes MCP, sub-agents, plan mode, to-dos, and background bash into extensions.

## Key ideas

1. **Four-area TUI** — startup header, messages, editor, footer. Editor border color encodes the current thinking level. Editor can be temporarily replaced by built-in UI (`/settings`) or custom extension UI.
2. **Message queue with two delivery modes** — Enter queues a steering message (after current tool calls), Alt+Enter queues a follow-up (after the whole turn). Escape aborts; Alt+Up retrieves. Modes are configurable in `/settings` via `steeringMode` and `followUpMode`.
3. **Sessions are JSONL with a tree** — saved under `~/.pi/agent/sessions/--{cwd-as-path}--/{ts}_{uuid}.jsonl`. `-c` continues most recent, `-r` browses, `--fork` and `/fork` create new sessions from earlier user messages, `/clone` duplicates the active branch, `/compact` summarizes older messages.
4. **Project trust gates project-local resources** — `.pi/settings.json`, `.pi` resources, and project package-managed extensions only load after a trust decision (`~/.pi/agent/trust.json`). Before trust: only context files, global/CLI `-e` extensions, and the `project_trust` event fire. Non-interactive modes honor `defaultProjectTrust` from global settings (`ask` / `always` / `never`) and accept `--approve` / `--no-approve` per run.
5. **CLI surface split by concern** — model options (`--provider`, `--model`, `--thinking`, `--list-models`), session options (`-c`, `-r`, `--session`, `--fork`, `--no-session`, `--name`), tool options (`--tools`, `--exclude-tools`, `--no-builtin-tools`, `--no-tools`), resource options (`-e`, `--no-extensions`, `--skill`, `--prompt-template`, `--theme`, `--no-context-files`), and modes (`-p`, `--mode json`, `--mode rpc`, `--export`).
6. **File arguments with `@` prefix** — `pi @prompt.md "answer"`, `pi -p @screenshot.png "describe"`. Combined with piped stdin in `-p` mode: `cat README.md | pi -p "summarize"`.
7. **Editor features** — `@` fuzzy-search files, Tab for path completion, Shift+Enter for multi-line, Ctrl+V to paste images, `!cmd` runs shell and sends output to model, `!!cmd` runs without sending, Ctrl+G opens `$VISUAL`/`$EDITOR`.
8. **Design philosophy: small core** — no built-in MCP, sub-agents, permission popups, plan mode, to-dos, or background bash. Workflow is opt-in via extensions/skills/packages. Rationale: [mariozechner.at blog post](https://mariozechner.at/posts/2025-11-30-pi-coding-agent/).

## Connections
- Related concepts: [[wiki/concepts/pi-extension-lifecycle]], [[wiki/concepts/agent-hook-compatibility]]
- Projects: [[wiki/entities/pi-cli]]
- Sources: [[wiki/sources/pi-extensions]], [[wiki/sources/pi-session-format]], [[wiki/sources/pi-models]], [[wiki/sources/pi-packages]]

---

- 2026-06-16 [CommandCode]: Page created
