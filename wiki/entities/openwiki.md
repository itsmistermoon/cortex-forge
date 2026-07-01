---
title: OpenWiki
type: entity
created: 2026-07-01
updated: 2026-07-01
tags: [codebase-documentation, agent-tools, github-actions, langchain, typescript]
aliases: [openwiki, open-wiki]
sources:
  - wiki/sources/openwiki.md
confidence: high
schema_version: "0.3"
---

# OpenWiki

Open-source TypeScript CLI by LangChain AI that generates and maintains codebase documentation for AI coding agents. Installs globally via `npm install -g openwiki`, runs `openwiki --init` to generate a `openwiki/` wiki directory from the repo, and injects a reference into `AGENTS.md`/`CLAUDE.md`. Maintains docs automatically via a daily GitHub Actions workflow that uses git diffs to update only what changed.

**Repo:** https://github.com/langchain-ai/openwiki
**License:** MIT
**Language:** TypeScript
**Created:** 2026-06-22
**Stars:** ~43 (2026-07-01)
**Stack:** DeepAgents (LangChain), Ink (terminal UI), SQLite checkpointing

## What makes it distinct from comparable tools

| Differentiator | OpenWiki | Comparable |
|---|---|---|
| Automated maintenance | GitHub Actions, git-diff-scoped, SHA-256 guard | [[wiki/entities/graphify]] requires `/graphify update .` manually |
| Output format | Markdown wiki in `openwiki/` | [[wiki/entities/graphify]]: graph.html + JSON; [[wiki/entities/codebase-memory-mcp]]: SQLite graph |
| Agent integration | Reference injected into AGENTS.md/CLAUDE.md | [[wiki/entities/understand-anything]]: per-platform install |
| Parsing strategy | LLM-driven (not deterministic) | [[wiki/entities/codebase-memory-mcp]]: tree-sitter AST (deterministic) |
| Observability | LangSmith tracing built-in | None in comparable tools |

## Key mechanisms

- **`--update` + git diff window** — reads `.last-update.json` (stores `gitHead` of last successful run), feeds only `git log <lastHead>..HEAD` to the agent. Incremental, not full regeneration.
- **Content snapshot guard** — SHA-256 of `openwiki/` before and after run; metadata written only if changed. Prevents PR churn in scheduled CI.
- **AGENTS.md/CLAUDE.md injection** — agent is explicitly instructed to insert/refresh a standardized section referencing `openwiki/quickstart.md`. If neither file exists, OpenWiki creates it.
- **DeepAgents LocalShellBackend** — `virtualMode: true`, 120s timeout, SQLite checkpointer keyed by repo path hash. Agent has filesystem access scoped to the repo root.

## Relevance to cortex-forge

The git-diff-scoped update pattern is the most transferable idea: cortex-forge's `wiki/` could use the same approach — on commit, scope the re-synthesis to only `wiki/sources/` pages whose `.raw/` file was recently modified, rather than re-indexing everything. The content snapshot guard is already partially implemented in cortex-forge via `cortex-reindex-post-commit.sh` (self-gates when no `wiki/` files changed).

The AGENTS.md injection pattern is the inverse of cortex-forge's approach: OpenWiki writes into the instruction file; cortex-forge reads from it. Both are valid; OpenWiki's pattern is better suited for repos without a pre-existing agent protocol.

## Relationships

- Built on: DeepAgents (LangChain), Ink
- Comparable to: [[wiki/entities/graphify]], [[wiki/entities/understand-anything]], [[wiki/entities/codebase-memory-mcp]]
- Concepts: [[wiki/concepts/karpathy-wiki-pattern]], [[wiki/concepts/knowledge-graph-code-intelligence]]
- Source: [[wiki/sources/openwiki]]

---

- 2026-07-01 [Claude Code]: Page created — entity for OpenWiki (LangChain AI), ingested from github.com/langchain-ai/openwiki
