---
title: "Every Claude Code Memory System Compared"
type: source
created: 2026-06-12
updated: 2026-06-12
tags: [youtube, memory-systems, claude-code, hooks, knowledge-base, cross-platform, review]
source_url: https://www.youtube.com/watch?v=UHVFcUzAGlM
source_date: 2026-06-12
source_author: Simon Scrapes
sources:
  - .raw/yt-claude-code-memory-compared.txt
confidence: medium
---

# Every Claude Code Memory System Compared (So You Don't Have To)

**URL:** https://www.youtube.com/watch?v=UHVFcUzAGlM
**Author:** Simon Scrapes (@simonscrapes)
**Duration:** 41:21

## Summary

Comparison of 6 levels of Claude Code memory systems, from native tools to cross-platform unified brains. The core thesis: these aren't competing tools, they're different approaches for different use cases, distinguished by storage mechanism and retrieval method.

## The 6 Levels

### Level 1 — Native Claude Code Memory
CLAUDE.md + auto memory (MEMORY.md). CLAUDE.md is always loaded at session start (system prompt). MEMORY.md is auto-populated from conversations. Key insight: keep CLAUDE.md under 200 lines — stuff too much in and context rot degrades recall. Use it as an index pointing to separate files.

### Level 2 — Forcing Reliable Memory Recall (cortex-forge territory)
John Connolly + Pavel Huryn's system: structured `.claude/memory/` with memory.md as index + domain/topic files + tool-specific files. Uses a **SessionStart hook** to inject the memory index at session start. Auto-reorganize memory via "reorganize memory" prompt. Enables team sharing of domain memory files. **This is exactly what cortex-forge's hot cache protocol does.**

### Level 3 — Search by Meaning (Vector/RAG)
Embedding-based search. Not just keyword matching. Mem0, MemPalace, vector databases.

### Level 4 — Recall Verbatim Conversations
Full conversation history storage and retrieval.

### Level 5 — Self-Organizing Knowledge Base (Wiki pattern)
Karpathy's LLM Wiki / Obsidian wiki. Builds interconnected Wikipedia-like knowledge bases. Deep research on interconnected topics. Alternatives compared:
- **Karpathy's LLM Wiki**: Free, self-hosted, Obsidian-based. Requires setup. Best for maximum control.
- **Recall** (recall.it): Hosted service, browser extension, auto-summarizes/tags, builds knowledge graph. MCP access. Downsides: don't own data (renting), built for content consumption not operational memory, pricing.
- **LightRAG**: Enterprise-grade knowledge graph. Overkill for most use cases.

### Level 6 — Single Brain For ALL AI Tools (Cross-platform)
**OpenBrain** by Nate Jones. Postgres database (Supabase) with a single "thoughts" table: text + embedding vector + tags + timestamp. Any AI tool can connect to it. Infrastructure layer for thinking. One database, one chat channel, any AI plugs in. No SAS lock-in, ~$1/month to run. Uses PostgreSQL pgvector extension for semantic search. Most future-proof and portable system.

## Key insights for cortex-forge

1. **Level 2 validates cortex-forge's core design**: SessionStart hook to inject structured memory at session start + memory index pattern. The video treats this as the right approach for reliable recall.

2. **Level 5 positions Karpathy's wiki as complementary to operational memory**: The video argues wiki-based knowledge bases are for deep research, not operational memory. cortex-forge's hot cache is operational memory (Level 2), its wiki is knowledge base (Level 5) — the distinction is intentional.

3. **Level 6 (OpenBrain) is the closest comparable to cortex-forge's multi-agent goal** but uses a fundamentally different approach: shared database vs shared hot cache file. OpenBrain requires Postgres; cortex-forge works with any filesystem.

4. **Mem0, MemPalace, LightRAG** are listed but dismissed for 99% of use cases — overengineered for what most users need.

5. **The "context rot" problem** (diminishing recall as context grows) is the same problem cortex-forge's progressive disclosure and hot cache solve.

## Connections
- Related concepts: [[wiki/concepts/agent-hook-compatibility]], [[wiki/concepts/progressive-disclosure-hooks]], [[wiki/concepts/handoff-artifact]], [[wiki/concepts/karpathy-wiki-pattern]], [[wiki/concepts/memory-system]]
- Projects: [[wiki/pages/cortex-forge]]
- Sources: [[wiki/sources/graphify]], [[wiki/sources/obsidian-mind]]
- Entities: [[wiki/entities/commandcode]]

---

- 2026-06-12 [CommandCode]: Page created — transcript extracted via yt-dlp. 6 levels of Claude Code memory compared, with direct relevance to cortex-forge's hook protocol and wiki architecture.
