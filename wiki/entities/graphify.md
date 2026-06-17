---
title: Graphify
type: entity
created: 2026-06-16
updated: 2026-06-16
tags: [graphify, knowledge-graph, multi-agent, yc-s26, code-intelligence]
aliases: []
sources:
  - wiki/sources/graphify.md
  - wiki/sources/graphify-readme.md
  - wiki/sources/graphify-agents.md
  - wiki/sources/graphify-architecture.md
  - wiki/sources/graphify-how-it-works.md
confidence: high
schema_version: "0.3"
---

# Graphify

Graphify is a multi-agent skill by Graphify Labs (Safi Shamsi, YC S26) that indexes codebases, docs, PDFs, images, and video into a knowledge graph (`graph.html` + `GRAPH_REPORT.md` + `graph.json`). Invoked with `/graphify .`. Supports 20+ agent platforms with per-platform install commands (`graphify install --platform <name>`).

## Architecture

7-stage pipeline: `detect() → extract() → build_graph() → cluster() → analyze() → report() → export()`

- **Local (free):** tree-sitter for code AST — no API key, no cost
- **Optional API:** Claude subagents for docs/images/PDFs; faster-whisper for video/audio
- **Clustering:** Leiden algorithm for community detection
- **Confidence tagging:** `EXTRACTED` / `INFERRED` / `AMBIGUOUS` per node/edge

Three cost tiers: free (AST only), local (whisper), API (Claude subagents). Users choose based on budget and corpus type.

## Multi-agent compatibility

| Platform | Mechanism |
|----------|-----------|
| Claude Code | `~/.claude/skills/` + PreToolUse hooks (`.claude/settings.local.json`) |
| Codex | `AGENTS.md` + PreToolUse hooks (`.codex/hooks.json`) |
| Gemini CLI / Antigravity | `GEMINI.md` + BeforeTool hook |
| Cursor | `.cursor/rules/graphify.mdc` (`alwaysApply: true`) |
| Kilo Code | Native skill + `tool.execute.before` plugin |
| Aider, OpenClaw, Trae | `AGENTS.md` fallback |
| **CommandCode** | **Not supported** — gap cortex-forge fills |

Platform pattern mirrors cortex-forge: PreToolUse hooks where available, AGENTS.md as universal fallback.

## Token efficiency

71.5x token reduction benchmark vs. raw file reads — same value proposition as [[wiki/concepts/knowledge-graph-code-intelligence]]. Team-shared artifact (`graphify-out/` directory) committed to repo lets teammates skip reindex — conceptually equivalent to `.codebase-memory/graph.db.zst` in [[wiki/entities/codebase-memory-mcp]].

## Key differences from codebase-memory-mcp

| Dimension | Graphify | codebase-memory-mcp |
|-----------|----------|---------------------|
| Scope | Code + docs + PDFs + video | Code only |
| Distribution | npm skill | Static binary |
| MCP tools | None (skill-based) | 14 MCP tools |
| Query language | GRAPH_REPORT.md + graph.json | Cypher-like + semantic search |
| Semantic layer | Leiden clustering | Hybrid LSP + nomic embeddings |

## Relationships
- Comparable: [[wiki/entities/codebase-memory-mcp]] (MCP-native alternative)
- Concept: [[wiki/concepts/knowledge-graph-code-intelligence]]
- Concept: [[wiki/concepts/treesitter-llm-hybrid-parsing]] (shared parsing layer)
- Project: [[wiki/pages/cortex-forge]] (CommandCode gap)

---

- 2026-06-16 [Claude Code]: Page created from cortex-prune check 2c — graphify had 4 source pages but no entity
