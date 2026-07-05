---
title: agent-hook-compatibility
type: concept
created: 2026-06-07
updated: 2026-07-02
tags: [multi-agent, hooks, cortex-forge/protocol, compatibility, decision-record]
aliases: [hook matrix, agent lifecycle, why no hooks, crystallize-automation-architecture]
sources:
  - wiki/sources/commandcode-hooks-configuration.md
  - wiki/sources/commandcode-hooks-reference.md
  - wiki/sources/commandcode-hooks-examples.md
  - wiki/sources/commandcode-hooks-best-practices.md
  - wiki/sources/antigravity-hooks-reference.md
confidence: high
schema_version: "0.3"
---

# Agent Hook Compatibility — why cortex-forge doesn't use agent lifecycle hooks

Cortex Forge does not use agent lifecycle hooks (`SessionStart`, `PreCompact`, `SessionEnd`, `Stop`, `PreToolUse`) anywhere, as of 2026-07-02. This page is the decision record: what was tried, what broke, and why the fix was to remove hooks entirely rather than patch around each agent's quirks. It also absorbs the former `crystallize-automation-architecture.md` page, which covered the same ground from the crystallize-specific angle.

**Current mechanism (all agents, identical):** `AGENTS.md` mandates reading `.cortex/MEMORY.md` before the first response, and invoking `/cortex-crystallize` manually at milestones and session close. See [[wiki/concepts/workflow-architecture]] for the operational protocol.

## Why hooks were dropped, not fixed

Only Claude Code had genuinely complete, reliable hook support (`SessionStart`, `PreCompact`, `SessionEnd` all exist and fire predictably). Every other agent required either a workaround, a no-op guard, or turned out to be structurally incompatible with the pattern cortex-forge needed (inject at start, synthesize at close):

| Agent | What was tried | Root problem found in live testing |
|-------|----------------|--------------------------------------|
| **Codex** | `SessionStart` → inject MEMORY.md; `Stop` → synthesize snapshot | Live transcripts use a Codex-specific JSONL schema (`session_meta`, `event_msg`, `response_item`), not Claude's `.message.content[]` — the crystallize script couldn't parse it without a dedicated extractor. `Stop` also fires at the end of *every* turn, not only on session close — a hook there would run after every response. Codex also renders injected `additionalContext` as visible `hook context:` in the conversation, which meant full `.cortex/MEMORY.md` injection created user-visible noise and token bloat regardless. |
| **CommandCode** | `Stop` → synthesize snapshot via `cmd -p` | Same turn-scoped firing problem as Codex: `Stop` fires on every agent pause, not only on session close. Background `cmd -p` synthesis left `__PENDING_SYNTHESIS_*__` placeholders and orphan `.synthesize-*.sh` helper files when the subprocess died before its cleanup ran, because the hook's parent process timed out before synthesis finished. The hook could not reliably distinguish "session end" from "agent idle between turns." Also: no `SessionStart` hook exists at all — context could only load via `AGENTS.md`. Plan mode disables hooks entirely, so even the unreliable `Stop` didn't fire there. |
| **Antigravity** | `PreInvocation` (invoc. 0) → inject; `Stop` (`fullyIdle`) → synthesize via `agy -p` | Two blocking issues confirmed in live testing (2026-06-27): (1) no `SessionEnd`/`/exit` event — the CLI kills the process abruptly on close, no hook fires; (2) `agy -p` invoked from a `Stop` hook deadlocks permanently, because Antigravity blocks secondary instances while the primary session is alive. The crystallize pattern (hook → headless call → write file) was structurally impossible here, not just unreliable. |
| **Claude Code** | `SessionStart`, `PreCompact`, `SessionEnd` — all worked | No blocking constraint on its own. But building the *whole system* around a mechanism only one of four target agents fully supported meant every other agent needed a different bespoke workaround (no-op guards, manual fallback text, agent-specific wire formats) — the inconsistency itself was the cost, independent of Claude Code's individual reliability. |

## The actual decision (2026-07-02)

Rather than maintain four different degradation strategies (full hooks / no-op guards / manual-only / structurally-impossible), cortex-forge dropped agent lifecycle hooks everywhere, including Claude Code, and standardized on one mechanism: `AGENTS.md` instructions, identical on every agent. This trades "automatic when it works" for "always the same, everywhere" — the guarantee comes from the protocol being unconditional and simple to follow, not from a harness feature only some agents implement. See [[wiki/projects/cortex-forge]] key decisions and the README "Design rationale" section for the fuller argument.

## What was removed

- Runtime hook scripts in `~/.cortex-forge/bin/hooks/`: `cortex-reactivate.sh`, `cortex-reactivate-codex.sh`, `cortex-reactivate-antigravity.sh`, `cortex-crystallize-claude.sh`, `cortex-crystallize-codex.sh`, `cortex-crystallize-antigravity.sh`, `cortex-crystallize-commandcode.sh` (already retired before this cleanup, see changelog), `cortex-imprint-auto.sh`, `cortex-recall-nudge.sh`.
- All hook-installation logic in `cortex-forge-setup/SKILL.md` and `install.sh` (settings.json/hooks.json merges, symlink creation for `~/.claude/hooks/`, `~/.codex/hooks/`, `~/.gemini/config/hooks/`, `~/.commandcode/hooks/`).
- The imprint-triage subagent that would have run at `SessionStart` (never fully implemented as designed — `imprint_triage: auto` briefly existed as a config flag but its trigger point no longer exists).

**Kept, deliberately:** `cortex-reindex-post-commit.sh` and the prune post-commit block. These are **git hooks**, not agent lifecycle hooks — they fire on `git commit`, run identically regardless of which agent (or human) made the commit, and don't depend on any agent harness supporting a specific event. The distinction that matters isn't "hook vs. no hook," it's "does this depend on uneven per-agent support."

## Agent-specific technical facts (kept for reference, no longer load-bearing)

These remain true about each CLI's native hook system — useful if you're building something else that needs them, irrelevant to how cortex-forge itself now works:

- **Codex:** supports `SessionStart`, `SessionEnd`, `PreToolUse`, `PostToolUse`, `SubagentStop`, `Stop`, `PromptSubmit`, `Compaction`. Config at `~/.codex/hooks.json` (global) or `.codex/hooks.json` (project, requires trust review). `SessionStart` can fire multiple times per session (`source`: `startup`/`resume`/`clear`/`compact`). Also requires explicit sandbox config for `cortex-search.py` to reach Ollama on localhost — see `cortex-forge-setup/SKILL.md` Codex embedding note, unrelated to lifecycle hooks and still relevant.
- **Antigravity:** inherits the Gemini CLI hook path (`~/.gemini/config/hooks.json`). Full event list: `PreToolUse`, `PostToolUse`, `PreInvocation`, `PostInvocation`, `Stop`. Known bug (agy-cli issue #49): CLI-based hook config writes to the wrong path (`~/.gemini/antigravity-cli/hooks.json` instead of `~/.gemini/config/hooks.json`) — edit the file directly or symlink.
- **CommandCode:** hooks configured under `hooks` key in `settings.json` (user or project scope, project wins). Wire format is a nested array (`hooks: [{ matcher, hooks: [{ type, command, timeout? }] }]`), unlike the flat format Codex/Claude Code use — not drop-in portable. `PreToolUse` runs sequentially with short-circuit on block; `PostToolUse` runs in parallel.
- **Claude Code:** `SessionStart`/`PreCompact`/`SessionEnd` all exist and fire reliably; wire format is flat JSON via `settings.json`.

## Agent detection signals (still used by `cortex-crystallize`)

When `/cortex-crystallize` is invoked manually, the skill identifies the calling agent via environment variables, to fill the `agent:` frontmatter field:

| Method | Signal | Agent | Reliability |
|--------|--------|-------|-------------|
| env var | `CLAUDECODE=1` | Claude Code | ✅ confirmed |
| env var | `AI_AGENT` starts with `claude-code` | Claude Code (fallback) | ✅ confirmed |
| env var | `COMMANDCODE=1` or `AI_AGENT` starts with `commandcode` | CommandCode | ✅ confirmed |
| env var | `AGY=1` or `AI_AGENT` starts with `agy`/`antigravity` | Antigravity | ⚠ documented, less tested |
| env var | `CODEX=1` or `AI_AGENT` starts with `codex` | Codex | ⚠ documented, less tested |
| none matched | — | Fall back to self-knowledge | — |

**Note (2026-06-11):** CommandCode does not export a dedicated env var by default in all versions — process-tree walking from `$PPID` is the fallback if env detection fails.

---

- 2026-06-07 [claude-sonnet-4-6]: Page created — initial matrix based on official documentation of each agent
- 2026-06-08 to 2026-06-28: Iteratively expanded with live-testing findings per agent (wire formats, trust models, sandbox constraints, plan-mode gotchas, Antigravity deadlock, CommandCode Stop retirement, Codex sandbox network restriction) — see prior versions in git history for the full incremental record
- 2026-07-02 [Claude Code]: Full rewrite — condensed from an operational hook-configuration reference (wire formats, JSON configs, per-agent setup instructions) into a decision record: what was tried, what broke, why hooks were removed entirely rather than patched further. Merged in `crystallize-automation-architecture.md` (deleted as a separate page — same ground, crystallize-specific angle). Kept the causal findings (Antigravity deadlock, CommandCode Stop turn-scoping, Codex transcript/format incompatibility) since those are the actual evidence for the decision; dropped the JSON hook-config snippets and setup instructions since nothing consumes them anymore.
