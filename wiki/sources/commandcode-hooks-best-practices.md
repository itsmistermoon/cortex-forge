---
title: Hooks Best Practices - Command Code
type: source
created: 2026-06-08
updated: 2026-06-08
tags: [commandcode, hooks, best-practices, security, debugging]
source_url: https://commandcode.ai/docs/hooks/best-practices
source_date:
source_author: CommandCode
sources:
  - .raw/commandcode-hooks-best-practices.md
confidence: high
---

# Hooks Best Practices - Command Code

**URL:** https://commandcode.ai/docs/hooks/best-practices
**Author:** CommandCode

## Summary

Operational guide for writing safe and efficient hooks in CommandCode. Covers input security (never `eval`, always `jq -r`), performance limits (10s for synchronous hooks), debugging with `--debug`, and a table of common issues with their root causes.

## Key ideas

1. **Input security**: treat model inputs as untrusted — parse with `jq -r`, never `eval`. Always quote variables.
2. **Performance**: PreToolUse < 10s; slow operations → PostToolUse or background. Hooks run on every tool call — latency accumulates.
3. **Debugging**: `--debug` generates detailed logs with matcher results and payload data. You can iterate with local mock payloads without spinning up CommandCode.
4. **Common issues**: script not executable (`chmod +x`), incorrect matcher regex, hooks disabled in plan mode, malformed JSON in output, timeout exceeded.
5. **Guidance to the model**: `additionalContext` to instruct, `systemMessage` to explain policy violations.

## Connections

- Related concepts: [[wiki/concepts/agent-hook-compatibility]]
- Projects: [[wiki/pages/cortex-forge]]

---

- 2026-06-08 [claude-sonnet-4-6]: Page created
- 2026-06-08 [Claude Code]: Translated to English
