---
title: Headless Agent Mode
type: concept
created: 2026-06-16
updated: 2026-06-16
tags: [headless, non-interactive, hooks, permissions, sessions]
aliases: [non-interactive mode, headless mode, -p flag]
sources:
  - wiki/sources/commandcode-headless.md
  - wiki/sources/commandcode-security.md
confidence: high
schema_version: "0.3"
---

# Headless Agent Mode

Non-interactive execution mode where an agent processes a prompt and exits, printing its response to stdout. The canonical use case for cortex-forge is synthesis hooks: running the agent at session end to produce a `.hot/MEMORY.md` snapshot without user interaction.

## Cross-agent surface

| Agent | Flag | Write permissions | Notes |
|-------|------|-------------------|-------|
| Claude Code | `claude -p "..."` | Allowed by default | Standard headless mode |
| CommandCode | `cmd -p "..."` | **Blocked by default** | Requires `--yolo` / `--dangerously-skip-permissions` to enable file writes and shell commands |
| Antigravity CLI | `agy -p "..."` | Ask (sandbox controls apply) | Equivalent surface; headless sessions tagged separately |
| Codex | `codex -p "..."` | Controlled by permission mode | Session persisted; resumable via `--resume <uuid>` |

## Critical detail for cortex-forge hooks

CommandCode's `cmd -p` blocks writes by default. The `cortex-crystallize-commandcode.sh` hook calls `cmd -p --yolo` to enable writing to `.hot/MEMORY.md`. Without `--yolo`, the synthesis completes but the file write silently fails. This is the most common failure mode when porting Claude Code hook scripts to CommandCode.

## Session persistence

Headless sessions are persisted to disk and resumable:

- **CommandCode:** `~/.commandcode/projects/{project-slug}/{session-uuid}.jsonl`; resume with `cmd --resume <uuid>` or `cmd --continue` (most recent); `transcript_path` field injected into hook stdin at runtime
- **Claude Code:** sessions stored locally; `claude --resume` for interactive resume of headless transcript
- **Codex:** session ID output via `--verbose` to stderr; `codex --resume <uuid>` for interactive resume

## Permission modes (CommandCode)

| Mode | Flag | Behavior |
|------|------|----------|
| Default | (none) | Writes require approval — interactive only |
| Plan | `--plan` | Read-only; no writes or shell commands |
| Auto-Accept | `--yolo` / `--dangerously-skip-permissions` | All actions allowed — required for headless synthesis |

## Hook design implication

Hooks that call an agent in headless mode must:
1. Use the agent-specific flag (`-p`, `--print`)
2. Pass the correct permissions flag for write-heavy operations (`--yolo` for CommandCode)
3. Not assume the agent binary is in PATH — resolve the absolute path at hook runtime
4. Background the call if the hook has a timeout constraint (CommandCode Stop hook: 120s)

## Relationships
- Sources: [[wiki/sources/commandcode-headless]], [[wiki/sources/commandcode-security]]
- Concepts: [[wiki/concepts/agent-hook-compatibility]]
- Entities: [[wiki/entities/antigravity-cli]], [[wiki/entities/codex]], [[wiki/entities/pi-cli]], [[wiki/entities/commandcode]]
- Project: [[wiki/pages/cortex-forge]]

---

- 2026-06-16 [Claude Code]: Page created from cortex-prune check 2c — commandcode-headless.md and commandcode-security.md had no covering concept page; cross-agent pattern warrants its own page
