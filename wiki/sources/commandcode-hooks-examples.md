---
title: Hooks Examples - Command Code
type: source
resource: https://commandcode.ai/docs/hooks/examples
created: 2026-06-08
updated: 2026-06-08
tags: [commandcode, hooks, examples, enforcement, quality-gate]
aliases: []
source_author: CommandCode
confidence: high
schema_version: "0.3"
raw: .raw/commandcode-hooks-examples.md
---

# Hooks Examples - Command Code

**URL:** https://commandcode.ai/docs/hooks/examples
**Author:** CommandCode

## Summary

Four ready-to-adapt hook examples covering the most common usage patterns: security enforcement (blocking dangerous commands), conditional context injection (warning on sensitive file reads), observability (tool call auditing), and a completion quality gate (Stop hook that forces a re-pass).

## Key ideas

1. **Block Dangerous Bash Commands** (PreToolUse): matcher on shell, `permissionDecision: "deny"` + explanatory `systemMessage`. Security enforcement pattern.
2. **Warn on Sensitive File Reads** (PreToolUse): always `permissionDecision: "allow"` + `additionalContext`. Non-blocking context injection pattern.
3. **Audit Tool Calls** (PreToolUse or PostToolUse): exit `0` without modifying behavior; writes to a local log. Pure observability pattern.
4. **Quality Gate** (Stop): exit `2` if it finds `DO NOT SHIP` markers; the agent retries up to 3 times. Completion gate pattern.
5. All scripts must be executable (`chmod +x`) for CommandCode to activate them.

## Connections

- Related concepts: [[wiki/concepts/agent-hook-compatibility]]
- Projects: [[wiki/projects/cortex-forge]]

---

- 2026-06-08 [claude-sonnet-4-6]: Page created
- 2026-06-08 [Claude Code]: Translated to English
