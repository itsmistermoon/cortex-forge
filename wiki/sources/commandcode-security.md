---
type: source
title: "Security & Privacy — Command Code"
resource: https://commandcode.ai/docs/resources/security
created: 2026-06-13
updated: 2026-06-13
tags: [commandcode, security, permissions, headless, privacy]
aliases: []
confidence: high
schema_version: "0.3"
raw: .raw/commandcode-security.md
---

# Security & Privacy — Command Code

**URL:** https://commandcode.ai/docs/resources/security
**Original date:** 2026-06-13
**Author:** CommandCode

## Summary

Official documentation for Command Code's security model: permission modes (Default/Plan/Auto-Accept), headless mode permissions (`--yolo` requirement), data handling (code never stored or trained on), network access, MCP security, checkpoint safety nets, and enterprise options.

## Key ideas

1. **Headless mode blocks writes by default** — `cmd -p` requires `--yolo` (or `--dangerously-skip-permissions`) to enable file writes and shell commands. Critical for crystallize hooks: the script needs write access to `.hot/MEMORY.md`.
2. **Three permission modes**: Default (writes need approval), Plan (read-only), Auto-Accept (all allowed). Modes switchable mid-session with `shift+tab` or at start with flags.
3. **Project trust model**: first `cmd` in a project prompts for trust. Skip with `cmd --trust`.
4. **No telemetry without consent**: network calls are limited to API, OAuth, Taste sync, and configured MCPs.
5. **Conversation history is local only**: stored at `~/.commandcode/projects/`, never leaves the machine.

## Connections
- Related concepts: [[wiki/concepts/agent-hook-compatibility]], [[wiki/concepts/progressive-disclosure-hooks]]
- Projects: [[wiki/projects/cortex-forge]]
- Sources: [[wiki/sources/commandcode-headless]], [[wiki/sources/commandcode-hooks-configuration]], [[wiki/sources/commandcode-hooks-reference]]

---

- 2026-06-13 [CommandCode]: Page created — ingested from official security docs. Key finding: `cmd -p --yolo` is the equivalent of `claude -p` for headless synthesis in hooks, but requires explicit write permission.
