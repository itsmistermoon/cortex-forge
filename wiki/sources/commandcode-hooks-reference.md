---
title: Hooks Reference - Command Code
type: source
created: 2026-06-08
updated: 2026-06-08
tags: [commandcode, hooks, reference, wire-format, exit-codes]
source_url: https://commandcode.ai/docs/hooks/reference
source_date:
source_author: CommandCode
sources:
  - .raw/commandcode-hooks-reference.md
confidence: high
---

# Hooks Reference - Command Code

**URL:** https://commandcode.ai/docs/hooks/reference
**Author:** CommandCode

## Summary

Complete technical reference for the CommandCode hooks system. Defines the HookDefinition/HookEntry data structure, the three event types (PreToolUse, PostToolUse, Stop), the wire format for input/output (JSON on stdin/stdout), the behavioral control fields, and the semantics of exit codes.

## Key ideas

1. Input wire format: JSON on stdin with session context, tool details, and environment info. Output: JSON on stdout with optional fields `continue`, `systemMessage`, `permissionDecision`, `decision`, `additionalContext`.
2. Exit codes: `0` → execute JSON output; `2` → block (PreToolUse) / retry (PostToolUse/Stop); others → non-blocking error.
3. Three events: `PreToolUse` (sequential, can block), `PostToolUse` (parallel, can retry), `Stop` (parallel, can retry the response).
4. `permissionDecision: "deny"` in PreToolUse blocks the tool with feedback to the model. `additionalContext` injects context without blocking.
5. Each hook receives isolated stdin — hooks cannot communicate with each other within the same event.

## Connections

- Related concepts: [[wiki/concepts/agent-hook-compatibility]]
- Projects: [[wiki/pages/cortex-forge]]

---

- 2026-06-08 [claude-sonnet-4-6]: Page created
- 2026-06-08 [Claude Code]: Translated to English
