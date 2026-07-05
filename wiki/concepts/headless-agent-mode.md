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

Non-interactive execution mode where an agent processes a prompt and exits, printing its response to stdout. **Superseded for cortex-forge (2026-07-02):** headless mode was used to run agent lifecycle hooks (e.g. `claude -p`/`cmd -p` synthesizing a `.cortex/MEMORY.md` snapshot at session end). Those hooks were removed — crystallize is now always invoked manually, interactively, via `/cortex-crystallize`. The reference below remains valid general knowledge about each CLI's headless surface, useful for anyone scripting these agents outside cortex-forge.

## Cross-agent surface

| Agent | Flag | Write permissions | Notes |
|-------|------|-------------------|-------|
| Claude Code | `claude -p "..."` | Allowed by default | Standard headless mode |
| CommandCode | `cmd -p "..."` | **Blocked by default** | Requires `--yolo` / `--dangerously-skip-permissions` to enable file writes and shell commands |
| Antigravity CLI | `agy -p "..."` | Ask (sandbox controls apply) | Equivalent surface; headless sessions tagged separately |
| Codex | `codex -p "..."` | Controlled by permission mode | Session persisted; resumable via `--resume <uuid>` |

## Critical detail (historical — applied while cortex-forge used hooks)

CommandCode's `cmd -p` blocks writes by default; enabling them required `cmd -p --yolo`. Without `--yolo`, the synthesis completes but the file write silently fails — the most common failure mode when porting Claude Code hook scripts to CommandCode. Kept here as a fact about the CLI, in case a future headless integration (not cortex-forge's own hooks, which no longer exist) needs it.

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

## Hook design implication (general knowledge, not applicable to cortex-forge anymore)

Any hook that calls an agent in headless mode must:
1. Use the agent-specific flag (`-p`, `--print`)
2. Pass the correct permissions flag for write-heavy operations (`--yolo` for CommandCode)
3. Not assume the agent binary is in PATH — resolve the absolute path at hook runtime
4. Background the call if the hook has a timeout constraint

## Relationships
- Sources: [[wiki/sources/commandcode-headless]], [[wiki/sources/commandcode-security]]
- Concepts: [[wiki/concepts/agent-hook-compatibility]]
- Entities: [[wiki/entities/antigravity-cli]], [[wiki/entities/codex]], [[wiki/entities/pi-cli]], [[wiki/entities/commandcode]]
- Project: [[wiki/projects/cortex-forge]]

---

- 2026-06-16 [Claude Code]: Page created from cortex-prune check 2c — commandcode-headless.md and commandcode-security.md had no covering concept page; cross-agent pattern warrants its own page
- 2026-07-02 [Claude Code]: Marked cortex-forge-specific sections as historical — agent lifecycle hooks (and the headless synthesis calls they made) were removed from cortex-forge; this page's cross-agent headless reference remains valid outside that context
