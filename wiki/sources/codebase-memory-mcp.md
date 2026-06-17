---
type: source
title: "codebase-memory-mcp — GitHub README"
resource: https://github.com/DeusData/codebase-memory-mcp
created: 2026-06-16
tags: [mcp, code-intelligence, knowledge-graph, tree-sitter, ai-agents]
confidence: high
schema_version: "0.3"
raw: .raw/codebase-memory-mcp.md
---

# codebase-memory-mcp — GitHub README

**URL:** https://github.com/DeusData/codebase-memory-mcp
**Original date:** 2026-02-24 (repo created), 2026-06-16 (last updated)
**Author:** DeusData

## Summary

codebase-memory-mcp is a high-performance MCP server that indexes codebases into a persistent SQLite knowledge graph using tree-sitter AST parsing across 158 languages. Ships as a single static binary (pure C, zero dependencies). Provides 14 MCP tools for structural querying, call-graph traversal, semantic search, and architecture analysis. Claims 99.2% fewer tokens vs. file-by-file search, validated on 31 real-world repos (arXiv:2603.27277).

## Key ideas

1. **Structural graph over grep** — indexes functions, classes, call chains, HTTP routes as graph nodes/edges; answering "what calls X?" costs one BFS query instead of dozens of grep/read cycles.
2. **Hybrid LSP** — two-layer architecture: tree-sitter (syntactic, all 158 languages) + lightweight C type-resolution engine inspired by major language servers (pyright, tsserver, gopls, Roslyn, rust-analyzer) embedded in the binary. No external language server process.
3. **Non-blocking agent hooks** — for Claude Code, intercepts Grep/Glob via `PreToolUse` and injects `search_graph` results as `additionalContext`. Never gates `Read` (would break read-before-edit invariant). All hook failure paths exit 0.
4. **Team-shared graph artifact** — `.codebase-memory/graph.db.zst` committed to the repo; teammates skip full reindex, incremental sync fills local diff.

## Connections
- Related concepts: [[knowledge-graph-code-intelligence]], [[mcp-server-pattern]], [[tree-sitter]]
- Entities: [[codebase-memory-mcp-tool]], [[DeusData]]
- Related tools: [[graphify]] (comparable graph artifact approach, different scope)

---

- 2026-06-16 [Claude Code]: Page created. Sanitize findings: 5 base64 strings (shields.io badge URLs, benign).
