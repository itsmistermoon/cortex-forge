---
title: codebase-memory-mcp — MCP Tools Reference
type: concept
created: 2026-06-16
updated: 2026-06-16
tags: [mcp, code-intelligence, reference]
sources:
  - wiki/sources/codebase-memory-mcp.md
confidence: high
schema_version: "0.3"
aliases: []
---

# [[wiki/entities/codebase-memory-mcp|codebase-memory-mcp]] — MCP Tools Reference

14 tools exposed via MCP. Run `get_graph_schema` first to understand a new project's structure.

## Indexing

| Tool | Description |
|------|-------------|
| `index_repository` | Index a repo. Pass absolute path. Writes `.codebase-memory/graph.db.zst` artifact. |
| `list_projects` | List all indexed projects with node/edge counts. Use to find project names. |
| `delete_project` | Remove a project and all its graph data. |
| `index_status` | Check indexing status. |

## Querying

| Tool | Key params | Notes |
|------|-----------|-------|
| `get_graph_schema` | — | Node/edge counts + property definitions per label. Run this first. |
| `search_graph` | `name_pattern`, `label`, `file_pattern`, `limit`, `offset` | Regex name, label filter, degree filters. Pagination supported. |
| `trace_path` | `function_name`, `direction` (`inbound`/`outbound`/`both`), depth 1-5 | BFS traversal of call graph. Alias: `trace_call_path`. |
| `detect_changes` | — | Maps uncommitted git diff to affected symbols + blast radius + risk class. |
| `query_graph` | `query` (Cypher string) | Read-only openCypher subset. |
| `get_code_snippet` | qualified name | Format: `<project>.<path_parts>.<name>`. Use `search_graph` first. |
| `get_architecture` | — | Languages, packages, entry points, routes, hotspots, Louvain clusters, ADR. |
| `search_code` | — | Grep-like within indexed files only (graph-augmented). |
| `semantic_query` | — | Vector search via bundled Nomic embeddings. No API key needed. |
| `manage_adr` | — | CRUD for Architecture Decision Records. Persists across sessions. |
| `ingest_traces` | — | Ingest runtime traces to validate `HTTP_CALLS` edges. |

## Node Labels

`Project` `Package` `Folder` `File` `Module` `Class` `Function` `Method` `Interface` `Enum` `Type` `Route` `Resource`

## Edge Types

| Category | Types |
|----------|-------|
| Structure | `CONTAINS_PACKAGE` `CONTAINS_FOLDER` `CONTAINS_FILE` `DEFINES` `DEFINES_METHOD` `MEMBER_OF` |
| Dependencies | `IMPORTS` `CALLS` `IMPLEMENTS` `INHERITS` `USAGE` `USES_TYPE` `TESTS` |
| Cross-service | `HTTP_CALLS` `ASYNC_CALLS` `HANDLES` `CONFIGURES` `WRITES` |
| Channels | `EMITS` `LISTENS_ON` |
| Similarity | `SIMILAR_TO` (MinHash + LSH, Jaccard) `SEMANTICALLY_RELATED` (score ≥ 0.80) |
| Data | `DATA_FLOWS` (arg-to-param + field access chains) |
| Change | `FILE_CHANGES_WITH` |

## Cypher Read Subset (`query_graph`)

Supported: `MATCH`, `OPTIONAL MATCH`, `WHERE`, `WITH`, `RETURN`, `ORDER BY`, `SKIP`, `LIMIT`, `DISTINCT`, `UNWIND`, `UNION`/`UNION ALL`, `CASE`, `MERGE` (no), write clauses (no).

Useful pattern — dead code detection:
```cypher
MATCH (f:Function)
WHERE NOT EXISTS { (f)<-[:CALLS]-() }
RETURN f.name, f.file
LIMIT 20
```

## CLI Mode

```bash
codebase-memory-mcp cli index_repository '{"repo_path": "/absolute/path"}'
codebase-memory-mcp cli search_graph '{"name_pattern": ".*Handler.*", "label": "Function"}'
codebase-memory-mcp cli trace_path '{"function_name": "Search", "direction": "both"}'
codebase-memory-mcp cli query_graph '{"query": "MATCH (f:Function) RETURN f.name LIMIT 5"}'
codebase-memory-mcp cli --raw search_graph '{"label": "Function"}' | jq '.results[].name'
```

## Configuration

```bash
codebase-memory-mcp config set auto_index true      # auto-index on session start
codebase-memory-mcp config set auto_index_limit 50000
codebase-memory-mcp config list
codebase-memory-mcp config reset auto_index
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CBM_CACHE_DIR` | `~/.cache/codebase-memory-mcp` | Database storage dir |
| `CBM_DIAGNOSTICS` | `false` | Enable diagnostics to `/tmp/cbm-diagnostics-<pid>.json` |
| `CBM_LOG_LEVEL` | `info` | `debug`/`info`/`warn`/`error`/`none` |
| `CBM_WORKERS` | detected | Parallel-indexing worker count (range 1-256) |

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Server not showing in `/mcp` | Check `.mcp.json` path is absolute. Restart agent. |
| `index_repository` fails | Pass absolute path. |
| `trace_path` returns 0 results | Use `search_graph(name_pattern=".*PartialName.*")` first. |
| Wrong project results | Add `project="name"` param. Use `list_projects`. |
| Binary not found after install | `export PATH="$HOME/.local/bin:$PATH"` |

---

- 2026-06-16 [Claude Code]: Page created from GitHub README ingestion
