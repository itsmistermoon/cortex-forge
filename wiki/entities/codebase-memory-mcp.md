---
title: codebase-memory-mcp
type: entity
created: 2026-06-16
updated: 2026-06-16
tags: [mcp, code-intelligence, knowledge-graph, tree-sitter, ai-agents, tool]
aliases: [cbm, codebase-memory]
sources:
  - wiki/sources/codebase-memory-mcp.md
confidence: high
schema_version: "0.3"
---

# codebase-memory-mcp

A high-performance MCP server for persistent code intelligence via knowledge graphs, built by DeusData. Indexes codebases into a persistent SQLite-backed knowledge graph using tree-sitter AST parsing across 158 languages. Designed to be the structural backend for AI coding agents — the agent (Claude Code, Codex, Gemini CLI, etc.) is the intelligence layer; this tool answers structural graph queries.

## Core capabilities

- **Indexing**: Linux kernel (28M LOC, 75K files) in 3 minutes. Average repo in milliseconds. RAM-first pipeline (LZ4, in-memory SQLite, single dump at end).
- **14 MCP tools**: `index_repository`, `search_graph`, `trace_path`, `detect_changes`, `query_graph`, `get_architecture`, `semantic_query`, `search_code`, `manage_adr`, and more.
- **Hybrid LSP**: lightweight C type-resolution (inspired by tsserver, pyright, gopls, Roslyn, rust-analyzer) for 9 languages. Resolves cross-module call edges without a language server process.
- **Semantic search**: bundled Nomic `nomic-embed-code` embeddings (768d int8, 40K tokens) compiled into binary — no API key, no Ollama.
- **Cross-service linking**: HTTP route ↔ call-site matching, gRPC/GraphQL/tRPC detection, channel detection (EMITS/LISTENS_ON).

## Installation

```bash
# macOS/Linux
curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | bash

# Update
codebase-memory-mcp update

# Claude Code manual MCP config
# ~/.claude/.mcp.json → add "codebase-memory-mcp": {"command": "/path/to/binary"}
```

Also available on: npm, PyPI, Homebrew, Scoop, Winget, Chocolatey, AUR, `go install`.

## Claude Code integration

`install` writes to `.claude/.mcp.json`, installs 4 skills, and adds a `PreToolUse` hook that intercepts `Grep`/`Glob` calls and injects `search_graph` results as `additionalContext`. Never gates `Read` (would break read-before-edit invariant). Hook always exits 0.

## Relationships
- Built by: [[DeusData]]
- Related tools: [[graphify]] (similar team-shared graph artifact concept)
- Concepts: [[knowledge-graph-code-intelligence]], [[hybrid-lsp]], [[tree-sitter]]
- Competes with / complements: file-by-file grep exploration in agents

---

- 2026-06-16 [Claude Code]: Page created from GitHub README ingestion
