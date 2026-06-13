---
title: Graphify
type: source
created: 2026-06-12
updated: 2026-06-12
tags: [graphify, knowledge-graph, multi-agent, yc-s26, comparable]
source_url: https://github.com/safishamsi/graphify
source_date: 2026-06-12
source_author: Safi Shamsi / Graphify Labs
sources:
  - .raw/graphify-readme.md
  - .raw/graphify-agents.md
  - .raw/graphify-architecture.md
  - .raw/graphify-how-it-works.md
confidence: high
---

# Graphify

**URL:** https://github.com/safishamsi/graphify
**Author:** Safi Shamsi / Graphify Labs (YC S26)
**Stars:** 66.3k

## Summary

AI coding assistant skill that turns any folder into a queryable knowledge graph. Type `/graphify .` to build graph.html + GRAPH_REPORT.md + graph.json from code, docs, PDFs, images, and videos. 733 commits on v8 branch, 134 releases. MIT license.

Architecture: detect() → extract() → build_graph() → cluster() → analyze() → report() → export(). Uses tree-sitter for local code AST (free, no API), faster-whisper for video/audio, and Claude subagents for docs/images/PDFs. Leiden algorithm for community detection. Confidence tagging: EXTRACTED/INFERRED/AMBIGUOUS.

## Multi-agent compatibility

Supports 20+ platforms with per-platform install commands (`graphify install --platform <name>`):

| Platform | Mechanism |
|----------|-----------|
| Claude Code | CLAUDE.md + PreToolUse hooks (payload-bearing, fire before search and file reads) |
| Codex | AGENTS.md + PreToolUse hooks in `.codex/hooks.json` |
| CodeBuddy | CODEBUDDY.md + PreToolUse hooks |
| Cursor | `.cursor/rules/graphify.mdc` with `alwaysApply: true` |
| Gemini CLI / Antigravity | GEMINI.md + BeforeTool hook |
| Kilo Code | Native skill + `/graphify` command + AGENTS.md + `.kilo` plugin |
| OpenCode | AGENTS.md + `tool.execute.before` plugin |
| GitHub Copilot CLI | Skill file |
| Aider, OpenClaw, Factory Droid, Trae | AGENTS.md |
| Hermes | AGENTS.md + `~/.hermes/skills/` |
| Others | Skill file or AGENTS.md |

**CommandCode is NOT in the supported list.** This is a gap cortex-forge fills.

## Key insights for cortex-forge

1. **Per-platform mechanism varies by hook availability.** Platforms with PreToolUse hooks get automatic nudging; platforms without get persistent instruction files (AGENTS.md, .cursor/rules/). Same pattern cortex-forge uses (Layer 1 = AGENTS.md, Layer 2 = hooks).

2. **Trae explicitly noted as not supporting PreToolUse hooks** — AGENTS.md is the always-on mechanism. Validates cortex-forge's design of having AGENTS.md as universal fallback.

3. **CodeBuddy** uses the same Agent tool and PreToolUse hook mechanism as Claude Code. Clone of the Claude Code approach.

4. **`graphify install`** is a CLI command that writes skill files, hook configs, and AGENTS.md per platform — same concept as `cortex-forge-setup` but more granular (per-platform commands vs one unified setup).

5. **Token benchmark** (71.5x reduction) validates the value of pre-built knowledge structures vs raw file reads — similar value proposition to cortex-forge's wiki synthesis.

6. **The "always-on" guarantee** uses the same insight as cortex-forge's "reliable consumption channel" — hooks for platforms that support them, persistent instructions for those that don't.

## Connections
- Related concepts: [[wiki/concepts/agent-hook-compatibility]], [[wiki/concepts/progressive-disclosure-hooks]]
- Projects: [[wiki/pages/cortex-forge]] (comparable direct)
- Sources: [[wiki/sources/obsidian-mind]] (another comparable)

---

- 2026-06-12 [CommandCode]: Page created — ingested from GitHub README, AGENTS.md, ARCHITECTURE.md, and docs/how-it-works.md. Multi-agent compatibility compared with cortex-forge.
