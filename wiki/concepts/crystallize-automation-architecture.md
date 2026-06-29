---
title: Crystallize Automation Architecture
type: concept
created: 2026-06-28
updated: 2026-06-28
tags: [crystallize, hooks, agents, architecture, cortex-forge]
aliases: [agent-specific-crystallize, per-agent-crystallize]
sources:
  - wiki/concepts/agent-hook-compatibility.md
  - .raw/codex-hooks.md
  - .raw/commandcode-hooks-reference.md
confidence: high
schema_version: "0.3"
---

# Crystallize Automation Architecture

How session synthesis is automated — or not — for each agent in Cortex Forge. Crystallize saves a structured snapshot to `.cortex/MEMORY.md` at session close. The automation model differs per agent based on concrete constraints discovered in live testing.

## Crystallize automation matrix

| Agent | Automation | Root constraint |
|-------|-----------|----------------|
| **Claude Code** | ✓ Automatic (Stop + PreCompact hooks) | None |
| **Codex** | ✗ Manual only | Transcript format incompatible; Stop not a reliable close boundary |
| **CommandCode** | ✗ Manual only | Stop fires on every agent pause, not only on session close |
| **Antigravity** | ✗ Manual only | No `/exit` hook; `agy -p` deadlocks inside a running session |

## Hook distribution architecture

```
bin/hooks/                            [source — git tracked]
~/.cortex-forge/bin/hooks/            [runtime copies — via /cortex-forge-setup]
~/.claude/hooks/      → runtime       [Claude Code symlinks]
~/.codex/hooks/       → runtime       [Codex symlinks]
~/.commandcode/hooks/ → runtime       [CommandCode symlinks]
~/.gemini/config/hooks/ → runtime     [Antigravity symlinks]
```

Propagate changes with `/cortex-forge-setup update`.

## Why automation differs per agent

### Claude Code — automatic

The `cortex-crystallize-claude.sh` hook runs on `SessionEnd` and `PreCompact`. It extracts user messages, tool calls, and the last assistant reply from the transcript JSONL (`~/.claude/projects/.../*.jsonl`), sends them to `claude -p` (Haiku) for synthesis, and writes the result to `.cortex/MEMORY.md`.

No blocking constraint — the hook runs as a normal subprocess with full shell access and file I/O.

### Codex — manual only

Two independent constraints make automatic crystallize unreliable in Codex:

1. **Transcript format incompatibility.** Live Codex transcripts use a Codex-specific JSONL schema (`session_meta`, `event_msg`, `response_item`, `turn_context` under `payload`) — not the Claude `.message.content[]` format. The crystallize script cannot parse it without a separate Codex-specific extractor. Source: `.raw/codex-hooks.md`, live session inspection 2026-06-08.

2. **Stop is not a reliable session-close boundary.** The `Stop` event fires at the end of each agent turn, not only when the user exits. A crystallize hook on `Stop` would run after every response, not just at the end of the session. Source: `.raw/codex-hooks.md` — "Stop/continue control" event list.

**Current state:** `cortex-crystallize-codex.sh` is a no-op JSON guard (`{}`). Codex reads `.cortex/MEMORY.md` via `AGENTS.md` instructions and snapshots manually with `/cortex-crystallize`.

### CommandCode — manual only

The Stop hook was implemented and then retired (2026-06-28) after live testing revealed the same turn-scoped firing problem:

- **Stop fires on every agent pause**, not only on session close. A `Stop` hook with background `cmd -p` synthesis produces `__PENDING_SYNTHESIS_*__` placeholders and orphan `.synthesize-*.sh` helper files when the subprocess dies before completing — because the hook parent times out before the synthesis finishes.
- The hook cannot distinguish "session end" from "agent idle between turns."

Source: `wiki/concepts/agent-hook-compatibility.md` changelog 2026-06-28; `bin/hooks/cortex-crystallize-commandcode.sh.retired`.

**Current state:** `"hooks": {}` in `.commandcode/settings.local.json` — empty placeholder. Crystallize is manual-only via `/cortex-crystallize`.

### Antigravity — manual only

Two blocking issues confirmed in live testing (2026-06-27):

1. **No session-close hook.** There is no `SessionEnd` or `/exit` event. When the user closes Antigravity, the process is killed abruptly without firing any hook. The `Stop` hook exists but fires on `fullyIdle == true` — an idle signal, not a close signal.

2. **Deadlock when calling `agy -p` from a hook.** Antigravity blocks secondary instances while a primary session is alive. Any `nohup agy -p ... &` invocation from a Stop hook hangs permanently until the primary session exits — which it never does cleanly. This makes the crystallize pattern (Stop hook → `agy -p` → write MEMORY.md) structurally impossible.

Source: `wiki/concepts/agent-hook-compatibility.md` § Antigravity Stop hook (confirmed 2026-06-27).

**Current state:** `cortex-crystallize-antigravity.sh` retired. Crystallize is manual-only via `/cortex-crystallize`.

## Connections

- [[wiki/concepts/agent-hook-compatibility]] — Full lifecycle hook matrix and wire formats per agent
- [[wiki/concepts/progressive-disclosure-hooks]] — Just-in-time context loading pattern
- [[wiki/concepts/headless-agent-mode]] — Headless flags per agent (`-p` / `--print`)

---

- 2026-06-28 [Claude Code]: Page created via cortex-imprint-auto.sh (auto mode)
- 2026-06-28 [Claude Code]: Corrected factual errors — Codex constraint (transcript format + Stop boundary, not "no bash"), CommandCode constraint (Stop fires every pause, not "headless mode"), Antigravity constraint (no /exit + deadlock, not "nsjail sandbox"). Sources: agent-hook-compatibility.md, .raw/codex-hooks.md, .raw/commandcode-hooks-reference.md
