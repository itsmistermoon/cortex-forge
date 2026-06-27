---
title: agent-hook-compatibility
type: concept
created: 2026-06-07
updated: 2026-06-27
tags: [multi-agent, hooks, cortex-forge, compatibility]
aliases: [hook matrix, agent lifecycle]
sources:
  - wiki/sources/commandcode-hooks-configuration.md
  - wiki/sources/commandcode-hooks-reference.md
  - wiki/sources/commandcode-hooks-examples.md
  - wiki/sources/commandcode-hooks-best-practices.md
  - wiki/sources/antigravity-hooks-reference.md
confidence: high
schema_version: "0.3"
---

# Agent Hook Compatibility

Cortex Forge's Hot Cache Protocol requires two lifecycle events per agent: one at **session start** (inject context) and one at **close** (save snapshot). Not all agents expose both.

## Compatibility Matrix

| Agent | SessionStart equiv. | Stop equiv. | Hot cache status |
|--------|---------------------|-------------|-----------------|
| Claude Code | `SessionStart` | `SessionEnd` + `PreCompact` | ✅ full — automatic via hooks |
| Antigravity CLI | `PreInvocation (invocationNum==0)` | **no viable** | ⚠️ partial — SessionStart only; Stop hook unusable (see below) |
| Codex | `SessionStart` | `Stop` | ✅ full — automatic via hooks; hook context visible in UI |
| CommandCode | **does not exist** | `Stop` | partial — close only, automatic; IA synthesis via `cmd -p` |

## Degraded mode per agent

### Claude Code
Configured via `cortex-forge-setup`. The `load-hot-cache.sh` and `update-hot-cache.sh` hooks run automatically. No agent action required.

**SessionStart details (official docs):**
- The event has a `source` field with values `startup`, `resume`, `clear`, `compact` — same as Codex. Filter by `startup` if you want to limit the hook to the real session start.
- `asyncRewake`: field available for hooks that run in background and need to wake the agent when done — useful for slow operations that should not block startup.
- `PreCompact` can be blocked with exit 2 — Cortex Forge's `update-hot-cache.sh` hook already uses this to save a snapshot before compaction.

### Antigravity CLI
Antigravity inherits the Gemini CLI path. Global config at `~/.gemini/config/hooks.json`; project config at `.agents/hooks.json`.

**⚠ Known bug (agy-cli issue #49)**: if you use CLI commands to configure hooks, it writes to `~/.gemini/antigravity-cli/hooks.json` (incorrect) instead of `~/.gemini/config/hooks.json` (correct). **Create the file manually** or use a symlink:
```bash
ln -s ~/.gemini/config/hooks.json ~/.gemini/antigravity-cli/hooks.json
```

Configure in `~/.gemini/config/hooks.json`:
```json
{
  "PreInvocation": { "condition": "invocationNum == 0", "command": "bash ~/.gemini/config/hooks/load-hot-cache-antigravity.sh" },
  "Stop":          { "condition": "fullyIdle == true",  "command": "bash ~/.gemini/config/hooks/update-hot-cache-antigravity.sh" }
}
```

Scripts must live in `~/.gemini/config/hooks/`, not in `~/.claude/hooks/`.

**Full hook event list (Antigravity 2.0, confirmed from official docs 2026-06-26):**

| Event | When | Matcher | Input key | Output key |
|-------|------|---------|-----------|------------|
| `PreToolUse` | Before tool execution | tool name regex | `toolCall.name`, `toolCall.args`, `stepIdx` | `decision` (`allow`/`deny`/`ask`/`force_ask`), `reason`, `permissionOverrides` |
| `PostToolUse` | After tool execution | tool name regex | `stepIdx`, `error` | `{}` (observability only) |
| `PreInvocation` | Before model is called | N/A | `invocationNum`, `initialNumSteps` | `injectSteps` (array of `ephemeralMessage`/`userMessage`/`toolCall`) |
| `PostInvocation` | After tool calls finish | N/A | `invocationNum`, `initialNumSteps` | `injectSteps`, `terminationBehavior` (`force_continue`/`terminate`) |
| `Stop` | Execution loop ends | N/A | `executionNum`, `terminationReason`, `fullyIdle` | `decision: "continue"`, `reason` |

All events receive common fields: `conversationId`, `workspacePaths`, `transcriptPath`, `artifactDirectoryPath`.
Transcript path: `~/.gemini/antigravity/brain/{conversationId}/.system_generated/logs/transcript.jsonl`

**`PreInvocation` as SuperContext hook (2026-06-26):** `PreInvocation` with `invocationNum == 0` is the functional equivalent of Claude Code's `UserPromptSubmit` for first-message context injection. Key difference: the user's message is **not** delivered in the payload — it must be read from `transcriptPath` before running the semantic search. The `injectSteps.ephemeralMessage` field delivers the result to the model. This makes full SuperContext (query-aware semantic injection) achievable in Antigravity with one extra step.

**`PostInvocation` guardrail potential:** `terminationBehavior: "force_continue"` or `"terminate"` enables loops and guardrails based on tool results — no equivalent exists in Claude Code or CommandCode hooks today.

**Wire format incompatibility with Claude Code:** `PreToolUse` output in Antigravity uses `decision` (not `permissionDecision`). Hooks are not cross-compatible at the wire level even if the logic is portable.

**⚠️ Stop hook — unusable for crystallize (confirmed 2026-06-27):** Two blocking issues discovered in live testing:
1. **No `/exit` trigger:** There is no `SessionEnd` or `/exit` hook. When the user closes the CLI, the process is killed abruptly (Language Server shutting down) without giving lifecycle scripts a chance to run.
2. **Background deadlock:** If the `Stop` hook attempts to invoke `agy -p` in background (e.g. via `nohup agy -p ... &`) for AI synthesis, the execution hangs permanently. Antigravity blocks secondary instances while the primary session is alive — this makes the cortex-forge crystallize pattern (Stop hook → `agy -p` → write `.hot/MEMORY.md`) impossible.

**Consequence for cortex-forge:** `cortex-crystallize-antigravity.sh` is non-functional and has been removed from the protocol. In Antigravity, crystallize must be invoked **manually** via `/cortex-crystallize` — the hook cannot automate it. Source: `wiki/sources/antigravity-hooks.md` in moon-multivac (live testing 2026-06-27).

### Codex
Configure in `~/.codex/hooks.json`:
```json
{
  "SessionStart": [{ "command": "bash ~/.codex/hooks/cortex-reactivate.sh" }],
  "Stop":         [{ "command": "bash ~/.codex/hooks/cortex-crystallize-codex.sh" }]
}
```

**Findings validated in session (2026-06-08):**
- Use a stable global hook directory (`~/.codex/hooks/`) rather than a vault-local path. The scripts must be vault-aware at runtime so the same Codex setup works across multiple vaults and from non-vault projects.
- Wire format identical to Claude Code — the `cortex-reactivate.sh` script is compatible without modifications.
- `SessionStart` may fire more than once per session: it has a `source` field with values `startup`, `resume`, `clear`, `compact`. Filter by `source` in the matcher if you want to limit to the real start.
- Codex hooks are enabled by default. Multiple matching hooks from multiple files all run.
- The CLI exposes `/hooks` for reviewing, trusting, and disabling non-managed hooks.
- The `hook context:` is visible in chat by design in the Codex UI. There is no mechanism to suppress it today (`suppressOutput` is reserved for future use). The context reaches the model correctly — the noise is visual only.
- **Context cost**: `additionalContext` consumes tokens from the session context window like any message. For a hot cache of a few KB it is negligible with 200k+ token windows, but it is a real cost shared with Claude Code and every Layer 2 implementation.
- First run requires manual hook approval (`Trust: New hook - review required`).
- `Stop` does not use `matcher`; it expects JSON output on stdout when exiting `0`, or exit code `2` with the continuation reason on stderr.
- `transcript_path` is a convenience field, but transcript format is not a stable hook interface. Treat it as best-effort input for snapshotting, not as a contract.
- Stop hooks should call `cortex-crystallize-codex.sh`, which wraps the shared Claude-compatible implementation with Codex-specific labels and transcript fallback paths.

### CommandCode
Has no SessionStart hook. Context is injected via `AGENTS.md`: the global rule to read `.hot/MEMORY.md` on startup is fulfilled by the agent if it reads the instructions file. Closing is automatic via the `Stop` hook.

Configure under the `hooks` key in `settings.json`:
- **User scope**: `~/.commandcode/settings.json` (not committed; applies to all of the user's projects)
- **Project scope**: `.commandcode/settings.json` (committed to the repo; applies to anyone who clones)
- **Precedence**: project > user

Example (project scope) for the hot cache:
```json
{
  "hooks": {
    "Stop": [{ "command": "bash {vault}/bin/hooks/update-hot-cache.sh" }]
  }
}
```

**Execution order and short-circuit** (from the official Configuration docs):
- `PreToolUse` runs **sequentially**; if a handler blocks (exit code != 0), subsequent `PreToolUse` handlers are skipped.
- `PostToolUse` runs in **parallel** (the tool has already finished).
- Multiple handlers under the same matcher run in listed order.
- Wire format: nested array `hooks: [{ matcher, hooks: [{ type: "command", command, timeout? }] }]`, different from the flat format used by Codex/Claude Code.

**⚠ Plan mode**: CommandCode disables hooks entirely in plan mode — the `Stop` hook does not run when closing a planning session. Keep this in mind when operating the crystallize protocol.

**Synthesis upgrade (2026-06-13):** `cortex-crystallize-commandcode.sh` ahora usa `cmd -p` para sintetizar resúmenes IA, igual que la versión de Claude Code. Extrae user messages, tool calls y última respuesta del transcript JSONL via jq, construye un prompt estructurado, y escribe en `.hot/MEMORY.md` con formato `#### What was done / Discarded / Fragile context`. Esto reemplaza la entrada mínima "Session closed via Stop hook." que producía antes.

**Implication**: in CommandCode the hot cache is write-only in the first session (no SessionStart hook to load it). From the second session onward, the previous context is already in `.hot/` and `AGENTS.md` instructs the agent to read it — the cycle closes via instruction, not via hook. The Stop crystallize now produces rich IA entries that make the handoff more informative.

**Transcript location (for pipeline imprint):** Confirmed 2026-06-12 via filesystem inspection and official docs:
- **Filesystem path:** `~/.commandcode/projects/{project-slug}/{session-uuid}.jsonl`
  - Project slug mirrors the filesystem path with `/` replaced by `-` (e.g., `/Users/itsmistermoon/proyectos/cortex-forge` → `users-itsmistermoon-proyectos-cortex-forge`)
- **Hook input field:** `transcript_path` is a common field on every hook event (PreToolUse, PostToolUse, Stop) — absolute path to the JSONL transcript. Available at runtime without guessing filesystem paths.
- **Transcript format:** JSONL, one JSON object per line. Each object has `id`, `timestamp`, `sessionId`, `parentId`, `role` (user/assistant), `content` (array of content blocks), `gitBranch`, `metadata`.
- **Retention:** No documented retention period. Filesystem inspection shows sessions dating back at least 5 days (no pruning observed). Assume indefinite retention or disk-pressure-based cleanup.
- **Global history:** `~/.commandcode/history.jsonl` exists as a compact history log with `p` (prompt fragment) and `t` (timestamp) fields — not a full transcript, but useful for lightweight session tracing.

**Recall nudge port (experimental, gated):** `bin/hooks/cortex-recall-nudge.sh` is I/O-compatible with CommandCode without any script changes — both use `payload.tool_input.command` on input and `hookSpecificOutput.additionalContext` on output. To install on CommandCode, add to `.commandcode/settings.local.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "shell",
        "hooks": [
          {
            "type": "command",
            "command": "bash {vault}/bin/hooks/cortex-recall-nudge.sh"
          }
        ]
      }
    ]
  }
}
```
The port is gated on the recall nudge experiment result in AGENT-LOG — do not install until the kill criterion resolves.

### CommandCode Wire Format I/O

Hooks receive JSON on `stdin` with session context, tool details, and environment info. They return JSON on `stdout` with optional fields:

| Field | Event | Effect |
|-------|--------|--------|
| `permissionDecision: "deny"` | PreToolUse | Blocks the tool; the model receives the message |
| `permissionDecision: "allow"` | PreToolUse | Explicitly allows; useful together with `additionalContext` |
| `decision: "block"` | PostToolUse | Advisory retry (tool already executed) |
| `systemMessage` | any | Policy message injected into the model's context |
| `additionalContext` | any | Non-blocking context for the model |
| `continue` | Stop | Controls whether the session continues |

Exit codes: `0` → execute JSON output; `2` → block/retry depending on event; others → non-blocking error (tool proceeds).

### Security and performance (best practices)

- **Never `eval`**: parse stdin with `jq -r`. Inputs come from the model and are untrusted.
- **Always quote**: `grep -qE` over `printf` with quoting, not bare variables in shell.
- **Timeout**: PreToolUse < 10s to avoid lagging the UI. Slow operations → PostToolUse or background.
- **Debugging**: `--debug` flag generates logs with matcher results and payload. Can iterate with local mock payloads without launching CommandCode.
- **Plan mode**: hooks are disabled in plan mode — do not assume they always run.
- **`chmod +x`**: all scripts must be executable.

> Sources: `wiki/sources/commandcode-hooks-configuration`, `commandcode-hooks-reference`, `commandcode-hooks-examples`, `commandcode-hooks-best-practices` (2026-06-08). See [[wiki/entities/commandcode]] for the full agent profile.

## Common usage patterns (applicable to all agents)

Patterns extracted from official CommandCode examples; the output mechanism varies per agent but the logic is portable:

| Pattern | Event | Mechanism | Typical use case |
|--------|--------|-----------|-------------|
| **Security enforcement** | PreToolUse | `permissionDecision: "deny"` + `systemMessage` | Block `rm -rf /`, `curl \| sh` |
| **Conditional context injection** | PreToolUse | `permissionDecision: "allow"` + `additionalContext` | Warn about `.env`, `.pem` files without blocking |
| **Pure observability** | Pre or PostToolUse | exit `0`, writes to local log | Tool call audit with timestamp and session ID |
| **Completion gate** | Stop | exit `2` + `systemMessage` | Block close if `DO NOT SHIP` markers exist; up to 3 retries |

## Agent detection signals (for `cortex-crystallize` skill)

When `/cortex-crystallize` is invoked manually, the skill must identify the calling agent to fill `agent:` and `{Agent}` in the history header. Detection is based on environment variables set by each CLI at runtime. Check in order:

| Method | Signal | Agent | Reliability |
|--------|--------|-------|-------------|
| env var | `CLAUDECODE=1` | Claude Code | ✅ confirmed (2026-06-11) |
| env var | `AI_AGENT` starts with `claude-code` | Claude Code (fallback) | ✅ confirmed |
| process tree | `node .../commandcode` in `$PPID` ancestry | CommandCode | ✅ confirmed (2026-06-11) |
| which | `which commandcode` yields path | CommandCode | ⚠ partial (shell-level, not session-level) |
| env var | `AGY=1` | Antigravity | ❌ unconfirmed |
| process tree | `node .../agy` in `$PPID` ancestry | Antigravity | ❌ unconfirmed |
| env var | `CODEX=1` | Codex | ❌ unconfirmed |
| process tree | `codex` in `$PPID` ancestry | Codex | ❌ unconfirmed |
| none matched | — | Fall back to self-knowledge | — |

**Key finding (2026-06-11):** CommandCode 0.35.0 does **not** export any self-identifying environment variables (`COMMANDCODE`, `AI_AGENT`, or others). The `COMMANDCODE=1` signal was a false hypothesis. Detection must fall back to walking the process tree from `$PPID` upward, looking for known binary paths. This is the recommended universal fallback for any CLI that doesn't inject env vars.

**Confirmed (Claude Code, 2026-06-11):** `CLAUDECODE=1`, `AI_AGENT=claude-code_{version}_agent`, `CLAUDE_CODE_ENTRYPOINT=cli`, `CLAUDE_CODE_SESSION_ID=…`

**Pending validation:** CommandCode, Antigravity, and Codex signals — update this table when each CLI is tested in a live session with `/cortex-crystallize`.

## SuperContext injection capability per agent

Ability to run query-aware semantic search and inject context before the model processes the first user message (SuperContext pattern — see [[wiki/concepts/super-context]]):

| Agent | Hook | Query available | Inject mechanism | Status |
|-------|------|-----------------|-----------------|--------|
| Claude Code | `UserPromptSubmit` | ✅ direct in payload | `additionalContext` | ✅ implementable |
| Antigravity | `PreInvocation` (invocationNum==0) | ⚠️ via `transcriptPath` (one extra read) | `injectSteps.ephemeralMessage` | ✅ SessionStart only — Stop deadlocks |
| Codex | not documented | ❌ | — | ❌ unknown |
| CommandCode | no equivalent | ❌ | — | ❌ not feasible |

For Antigravity: read `transcriptPath` → extract last `role: user` message → run `cortex-search.py "{query}"` → return `injectSteps: [{ ephemeralMessage: "..." }]`.

## Universal fallback rule

If an agent has no startup hook, `AGENTS.md` acts as a fallback: the explicit instruction to read `.hot/MEMORY.md` is interpreted by any agent that processes the instructions file before operating. It is less reliable than a hook (depends on the agent respecting AGENTS.md), but covers the gap.

---

- 2026-06-07 [claude-sonnet-4-6]: Page created — initial matrix based on official documentation of each agent; CommandCode verified against commandcode.ai/docs/hooks/reference
- 2026-06-08 [claude-sonnet-4-6]: Codex updated with findings from real session — wire format confirmed, multi-source SessionStart behavior, hook context visibility, context cost
- 2026-06-08 [claude-sonnet-4-6]: Antigravity corrected — global config is `~/.gemini/config/hooks.json`; path alignment bug documented (agy-cli issue #49)
- 2026-06-08 [CommandCode / MiniMax-M3]: Expanded with scopes (user/project), precedence, PreToolUse order (sequential, short-circuit) vs PostToolUse (parallel), nested wire format. Source: wiki/sources/commandcode-hooks-configuration
- 2026-06-08 [claude-sonnet-4-6]: Added full CommandCode I/O schema (control fields, exit codes), security/performance section (best practices), and table of common usage patterns portable across agents. Sources: commandcode-hooks-reference, commandcode-hooks-examples, commandcode-hooks-best-practices
- 2026-06-08 [claude-sonnet-4-6]: Claude Code SessionStart — `source` field documented (startup|resume|clear|compact), `asyncRewake` added, `PreCompact` with exit 2 confirmed. CommandCode — plan mode gotcha documented. Source: handoff from second-brain
- 2026-06-08 [Claude Code]: Translated to English
- 2026-06-11 [Claude Code]: Agent detection signals section added — confirmed Claude Code env vars; other CLIs marked unconfirmed pending live validation
- 2026-06-13 [CommandCode]: CommandCode crystallize upgraded with `cmd -p` IA synthesis
- 2026-06-26 [Claude Code]: Antigravity section expanded with full hook event table (PreInvocation/PostInvocation confirmed from official docs); SuperContext injection table added; wire format incompatibility with Claude Code documented. Source: wiki/sources/antigravity-hooks-reference.md — now produces structured `#### What was done / Discarded / Fragile context` entries instead of minimal "Session closed via Stop hook."
- 2026-06-27 [Claude Code]: Antigravity Stop hook marked unusable — no /exit trigger + deadlock when launching agy -p in background confirmed in live testing. cortex-crystallize-antigravity.sh removed from protocol; crystallize is manual-only for Antigravity. Source: moon-multivac/wiki/sources/antigravity-hooks.md
