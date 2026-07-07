---
title: "Antigravity 2.0 — Hooks Reference"
type: source
resource: https://antigravity.google/docs/hooks
created: 2026-06-26
updated: 2026-06-26
source_author: Google (Antigravity team)
tags: [antigravity, hooks, agent-hook-compatibility, pre-invocation, inject-steps]
aliases: []
confidence: high
schema_version: "0.3"
raw: .raw/antigravity-hooks-reference.md
---

# Antigravity 2.0 — Hooks Reference

**URL:** https://antigravity.google/docs/hooks
**Original date:** 2026-06-26
**Author:** Google / Antigravity team

## Summary

Official reference for Antigravity 2.0's hook system. Five hook events: `PreToolUse`, `PostToolUse`, `PreInvocation`, `PostInvocation`, `Stop`. The key finding for cortex-forge: `PreInvocation` and `PostInvocation` support `injectSteps` output, enabling ephemeral message injection before model calls — the functional equivalent of Claude Code's `UserPromptSubmit` for context injection patterns like SuperContext.

## Key ideas

1. **`PreInvocation` + `injectSteps`** — fires before the model is called; output can include `injectSteps` with `ephemeralMessage`, `userMessage`, or `toolCall` objects. Gating on `invocationNum == 0` gives first-message behavior. The user's message is not in the payload but is available via `transcriptPath` → `transcript.jsonl`.

2. **`PostInvocation` + `terminationBehavior`** — fires after tool calls finish; output can include `injectSteps` AND `terminationBehavior: "force_continue"` or `"terminate"`. Enables guardrail patterns that loop or halt based on tool results.

3. **`PreToolUse` output schema differs from Claude Code** — returns `decision` (`"allow"` / `"deny"` / `"ask"` / `"force_ask"`) + optional `reason` and `permissionOverrides`. Claude Code uses `permissionDecision`; Antigravity uses `decision`. Not wire-compatible.

4. **`PostToolUse` returns `{}`** — no injection capability on post-tool. Only observability (logging, auditing).

5. **Common fields on all events** — `conversationId`, `workspacePaths`, `transcriptPath`, `artifactDirectoryPath`. Transcript lives at `~/.gemini/antigravity/brain/{conversationId}/.system_generated/logs/transcript.jsonl`.

6. **Tool name taxonomy** — 20+ named tools for `PreToolUse`/`PostToolUse` matchers: `view_file`, `write_to_file`, `replace_file_content`, `grep_search`, `run_command`, `invoke_subagent`, `define_subagent`, etc. Regex matchers supported (`"browser_.*"`).

## Connections

- Related concepts: [[wiki/concepts/agent-hook-compatibility]], [[wiki/concepts/super-context]], [[wiki/concepts/progressive-disclosure-hooks]]
- Entities: [[wiki/entities/antigravity-cli]]

---

- 2026-06-26 [Claude Code]: Page created — ingested from antigravity.google/docs/hooks; key finding: PreInvocation injectSteps enables SuperContext equivalent for Antigravity
