---
title: Understand Anything
type: source
resource: 
created: 2026-06-08
updated: 2026-06-08
tags: [codebase-analysis, knowledge-graph, multi-agent, ai-tooling, karpathy-wiki]
aliases: [Understand-Anything, UA, Lum1104/Understand-Anything]
sources:
  - .raw/understand-anything.md
confidence: high
schema_version: "0.3"
raw: 
---

# Understand Anything

Multi-platform plugin that converts a codebase, knowledge base, or documentation into an **interactive knowledge graph** that is browsable, searchable, and queryable. Compatible with Claude Code, Codex, Cursor, Copilot, Gemini CLI, OpenCode, Vibe CLI, Trae, Hermes, Cline, KIMI CLI, and Antigravity.

**Origin:** [github.com/Lum1104/Understand-Anything](https://github.com/Lum1104/Understand-Anything) — MIT License, Lum1104.
**Ingested:** 2026-06-08 from main README (350 lines).

## What it offers

- **Structural graph** of files, functions, classes, and dependencies — browsable, searchable, with natural-language summaries per node.
- **Domain view** that maps code to business processes (domains, flows, steps).
- **Karpathy-style knowledge base analysis** — extracts wikilinks, categories, entities, claims, and implicit relationships.
- **Auto-generated guided tours**, fuzzy + semantic search, diff impact analysis, persona-adaptive UI (junior dev / PM / power user), architectural layer visualization, callouts for 12 programming patterns.

## Main Commands

| Command | Function |
|---------|---------|
| `/understand` | Multi-agent pipeline that scans the project and builds the graph → `.understand-anything/knowledge-graph.json` |
| `/understand-dashboard` | Opens the interactive web dashboard |
| `/understand-chat {query}` | Free-form question about the codebase |
| `/understand-diff` | Impact of uncommitted changes |
| `/understand-explain {path}` | Deep-dive into a file or function |
| `/understand-onboard` | Generates an onboarding guide for new team members |
| `/understand-domain` | Extracts business domain knowledge |
| `/understand-knowledge {path}` | Analyzes a Karpathy-style wiki |

Supports incremental mode (re-analyzes only changed files), scoped subdirectory, configurable language (`--language zh|ja|ko|ru|...`), and post-commit hook with `--auto-update`.

## Internal Architecture

**tree-sitter + LLM hybrid.** The deterministic side (tree-sitter) parses syntax, extracts imports/exports/definitions/inheritance, builds a pre-resolved `importMap`, and performs fingerprint-based change detection. The semantic side (LLM) produces summaries, tags, architectural layer assignment, business domain mapping, guided tours, and concept callouts.

**Multi-agent pipeline (5 base agents + 1 for domain + 1 for knowledge base):**

| Agent | Role |
|--------|-----|
| `project-scanner` | Discover files, detect languages and frameworks |
| `file-analyzer` | Extract functions, classes, imports; produce nodes and edges |
| `architecture-analyzer` | Identify architectural layers |
| `tour-builder` | Generate guided learning tours |
| `graph-reviewer` | Validate completeness and referential integrity (inline by default; `--review` for full LLM review) |
| `domain-analyzer` | Extract domains, flows, and steps (used by `/understand-domain`) |
| `article-analyzer` | Extract entities, claims, and implicit relationships (used by `/understand-knowledge`) |

File analyzers run in parallel (up to 5 concurrent, batches of 20-30 files).

## Multi-platform Compatibility

| Platform | Status | Installation |
|------------|--------|-------------|
| Claude Code | Native | Plugin marketplace |
| Cursor | Auto-discovery | `.cursor-plugin/plugin.json` |
| VS Code + Copilot | Auto-discovery | `.copilot-plugin/plugin.json` |
| Copilot CLI | Supported | `copilot plugin install` |
| Codex, OpenCode, Antigravity, Gemini CLI, Pi Agent, Vibe CLI, Hermes, Cline, KIMI CLI, Trae | Supported | `curl … install.sh \| bash -s <platform>` |

## Graph Sharing Model

The graph is pure JSON. It is committed once and the team consumes it without re-running the pipeline. Ignore `.understand-anything/intermediate/` and `.understand-anything/diff-overlay.json` (local scratch). For graphs >10 MB use **git-lfs**.

## Relevance to the vault

Three areas of direct transfer to user projects:

1. **Karpathy wiki pattern** — the `cortex-assimilate` skill produces pages that could feed `/understand-knowledge` to graph the entire vault.
2. **tree-sitter + LLM hybrid** — replicable pattern for incremental code analysis.
3. **Multi-platform compatibility matrix** — overlaps with [[wiki/concepts/agent-hook-compatibility|Agent Hook Compatibility]] (the vault's page on lifecycle hooks). Both maintain a platform × event matrix, but this one measures plugin installation; the vault's measures lifecycle hooks.

---

- 2026-06-08 [CommandCode]: Page created — synthesis of main README (350 lines, downloaded to `.raw/understand-anything.md`)
- 2026-06-08 [Claude Code]: Translated to English
