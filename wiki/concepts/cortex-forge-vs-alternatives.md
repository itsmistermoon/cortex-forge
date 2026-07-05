---
title: "cortex-forge vs alternative systems"
type: concept
created: 2026-06-26
updated: 2026-06-26
tags: [cortex-forge/architecture, knowledge-management, ai-agents, personal-brain, comparison]
sources:
  - wiki/sources/openhuman.md
  - wiki/sources/openhuman-super-context.md
  - wiki/sources/obsidian-mind.md
  - wiki/sources/openbrain.md
  - wiki/sources/graphify.md
aliases: [cortex-forge-comparison, alternatives-map]
confidence: medium
schema_version: "0.3"
---

# cortex-forge vs alternative systems

Map of architecturally relevant alternatives, organized by structural similarity. Synthesized from all entities, sources, and concepts in both the cortex-forge and moon-multivac vaults that document memory or knowledge management systems for AI agents.

## cortex-forge's position

cortex-forge is a direct implementation of the [[wiki/concepts/karpathy-wiki-pattern|Karpathy LLM Wiki]] pattern: the LLM is the *bookkeeper* of the vault, not the user. Three core layers: `.raw/` (immutable, raw sources), `wiki/` (LLM-owned), `.hot/` (per-session/project hot cache). No server, no database, no embeddings — pure markdown in git.

Key differentiators: full human readability, maximum portability (fork + adapt = ready), zero external dependencies, multi-agent via hot cache protocol.

---

## Comparison by system

### OpenHuman — [[wiki/entities/openhuman]] (tinyhumansai)

> The closest full-harness comparable — both solve the cold-start problem via a local Karpathy-style Obsidian vault.

Both implement the same core patterns (Karpathy-style wiki, session-start context injection, local-first storage). The architectural approaches diverge sharply:

| Dimension | OpenHuman | cortex-forge |
|-----------|-----------|--------------|
| Form factor | Desktop GUI app (Tauri) | Vault protocol (bash + markdown) |
| Context injection | SuperContext ([[wiki/concepts/super-context]]): harness-level read-only scout sub-agent | `SessionStart` hook injecting `.hot/MEMORY.md` |
| Knowledge source | Auto-fetched from 118+ OAuth integrations (20-min loop) | Agent-synthesized from manually ingested sources |
| Storage | SQLite + Obsidian-compatible `.md` files | Pure markdown in git (no database) |
| Token compression | TokenJuice: HTML→Markdown, URL shortening, dedup (up to 80%) | No equivalent |
| Multi-agent | Single harness (all models via OpenHuman router) | Protocol-level (Claude Code, Codex, Antigravity, CommandCode) |
| Cross-agent interop | Optional `agentmemory` backend proxy | AGENTS.md + hot cache protocol |
| Setup | Install desktop app, connect OAuth accounts | `git clone` + `cortex-forge-setup` |
| License | GNU | MIT |

**OpenHuman advantage:** fully automatic context building, 118+ live integrations, TokenJuice compression, UI-first onboarding, harness-level SuperContext guarantee.
**cortex-forge advantage:** zero infrastructure, agent-agnostic protocol, vault as a portable git repo, no managed backend dependency, full control over synthesized knowledge.

---

### GBrain — (garrytan)

> The most mature comparable in the personal brain space for agents.

| Dimension | GBrain | cortex-forge |
|-----------|--------|--------------|
| Storage | Postgres + pgvector / PGLite WASM | Pure markdown in git |
| Knowledge graph | Auto-built without LLM from `put_page` | Manual wikilinks |
| Synthesis | `gbrain think`: synthesized response + gap analysis | `cortex-recall`: response with citations |
| Enrichment | Dream cycle: 66 nightly autonomous cron jobs | Manual (`cortex-crystallize`, `cortex-prune`) |
| Schema | Dynamic packs (15 types), agents evolve it via CLI+MCP | Fixed templates (source, concept, entity, project) |
| Multi-user | Federated, login-scoped, fuzz-tested | Single-user |
| Multi-agent | OpenClaw, Hermes, Claude Code, Codex, Cursor | Claude Code, Codex, Antigravity, CommandCode |
| Skills | 43 curated skills (official skillpack) | User's own skills |
| Benchmarked scale | 146K pages, 24K people, 66 crons | No published benchmark |
| Retrieval benchmark | P@5 49.1%, +31.4 pts vs vector-only RAG | No published benchmark |
| Install | `bun install -g github:garrytan/gbrain` | `git clone` + setup.sh |

**GBrain advantage:** auto-built graph, dream cycle, scale, multi-user, gap analysis in synthesis.
**cortex-forge advantage:** zero-dependency, human-readable, no server, vault portable as a repo.

---

### Hermes Agent — (Nous Research)

> The closest match to cortex-forge's design philosophy.

Shared pattern: frozen snapshot injection at session start (`MEMORY.md` in Hermes = `.hot/{project}.md` in cortex-forge). Hermes adds context files with progressive subdirectory discovery and `@file:`, `@url:`, `@diff` syntax for inline injection.

Hermes has no vault of its own — it externalizes memory to 8+ plug-in providers. cortex-forge is the vault Hermes could use as a backend. Key gap: Hermes can learn from providers (trust scoring, dialectic modeling); cortex-forge requires manual invocation of crystallize.

See also: [[wiki/concepts/super-context]] — the same session cold-start problem; Hermes solves it via MEMORY.md, cortex-forge via `.hot/`, OpenHuman via SuperContext.

---

### Obsidian Mind — [[wiki/entities/codebase-memory-mcp]] (Brenno Ferrari)

Obsidian vault template with 5 TypeScript lifecycle hooks + 18 slash commands + 9 specialized sub-agents. Compatible with Claude Code, Codex and Gemini CLI simultaneously.

| Dimension | Obsidian Mind | cortex-forge |
|-----------|--------------|--------------|
| Hooks | 5 TypeScript hooks (SessionStart, UserPromptSubmit, PostToolUse, PreCompact, Stop) | Bash hooks via cortex-forge-setup |
| Sub-agents | 9 specialized (brag-spotter, cross-linker, people-profiler, etc.) | Generic skills |
| Semantic | QMD optional via MCP | sqlite-vec index (Phase 3.6) |
| SessionStart payload | ~2K tokens (North Star, projects, git summary, tasks, file listing) | `.hot/{project}.md` (variable size) |
| Multi-agent | Claude + Codex + Gemini with same scripts | Claude Code, Codex, Antigravity, CommandCode |
| Package manager | ShardMind (wizard + three-way merge upgrades) | No package manager |

**Obsidian Mind advantage:** richer hooks, specialized sub-agents, multi-CLI out-of-the-box, upgrade path via ShardMind.
**cortex-forge advantage:** domain-agnostic design, vault readable without Obsidian, skills portable across projects.

---

### OpenBrain — [[wiki/entities/openbrain-nate-jones]] (Nate B. Jones / RadixSeven)

Cross-tool memory with native embeddings. Stack: Supabase (PostgreSQL + pgvector) + OpenRouter + MCP server. Three MCP tools: `search_thoughts`, `list_thoughts`, `add_thought`. Cost ~$0.10–$0.30/mo.

Classified as **level 6** of the 6-level memory framework: complementary to cortex-forge (level 1–2), not a substitute. OpenBrain solves "same brain accessible from Claude Code, ChatGPT and Cursor simultaneously"; cortex-forge is not designed for that.

---

### Karpathy LLM Wiki pattern — [[wiki/concepts/karpathy-wiki-pattern]]

Not a product but the pattern of which cortex-forge is a direct implementation. Three core operations: Ingest, Query, Lint. The LLM as bookkeeper inverts the classic RAG model: instead of rediscovering from scratch, it accumulates knowledge in wiki pages updated with each ingest. cortex-forge extends the pattern with hot cache, skills, multi-agent support, and provenance.

---

### Intermediate-level systems (levels 3–4 of the 6-level framework)

**MemSearch (Zilliz) — Level 3**
Claude Code plugin that auto-injects top-3 semantic matches into each prompt via `UserPromptSubmit` hook. Ports the OpenClaude pattern: long-term `memory.md` + daily notes + "dreaming". Complementary to cortex-forge — could be used as a semantic layer on top of the vault.

**Mem Palace — Level 4**
Pure local RAG (SQL + ChromaDB). AAAK index: dense symbolic dialect for scanning thousands of "drawers" in a single pass. Architecture: wing → room → closet → drawer (verbatim). `SessionEnd` and `PreCompact` hooks. Focused on verbatim conversation recall, not external knowledge synthesis.

---

### External memory providers (Hermes ecosystem)

Relevant as possible backends for a future cortex-forge evolution:

| System | Storage | Unique feature | Cost |
|--------|---------|----------------|------|
| **Honcho** | Cloud | Dialectic user modeling (LLM deduces preferences) | Paid |
| **OpenViking** | Self-hosted | Tiered loading L0→L1→L2, filesystem hierarchy | Free (AGPL) |
| **Holographic** | Local SQLite | HRR algebra + asymmetric trust scoring (+0.05/−0.10) | Free |
| **Hindsight** | Cloud/Local | Knowledge graph + `hindsight_reflect` (cross-memory synthesis) | — |
| **RetainDB** | Cloud | Hybrid search + delta compression, 7 memory types | $20/mo |
| **ByteRover** | Local/Cloud | Pre-compression extraction (captures before context rotates) | — |
| **Supermemory** | Cloud | Context fencing + multi-container | — |
| **Mem0** | Cloud | Server-side automatic LLM extraction | Paid |

---

## Positioning map

```
                    ← simpler                          more powerful →

No server    cortex-forge ── Obsidian Mind ── Hermes+Holographic ── GBrain
With server  MemSearch ────── OpenBrain ─────── Hermes+Mem0 ──────── GBrain+Supabase
GUI/harness  ────────────── OpenHuman ────────────────────────────── GBrain

             ↑ pure markdown                              DB + embeddings ↑
```

---

## cortex-forge gaps from this comparison

| Gap | System that solves it | Difficulty to adopt |
|-----|-----------------------|---------------------|
| Auto-fetch from live integrations | OpenHuman | High (requires managed backend) |
| Token compression layer | OpenHuman TokenJuice | Medium (hook PreCompact) |
| Semantic search | MemSearch, OpenBrain, GBrain | Low — **Phase 3.6 implemented** (sqlite-vec) |
| Auto-built knowledge graph | GBrain, Hindsight | High (requires DB) |
| Autonomous dream cycle | GBrain | High (requires cron infrastructure) |
| Pre-compression extraction | ByteRover | Medium (hook `PreCompact`) |
| Trust scoring per fact | Holographic | Medium (frontmatter field + skill logic) |
| Multi-user | GBrain, OpenBrain | High (requires server) |
| Cross-tool (multiple AI clients) | OpenBrain, OpenHuman | High (requires remote MCP server) |
| Specialized sub-agents | Obsidian Mind | Medium (extend existing skills) |

---

## Connections

- [[wiki/concepts/karpathy-wiki-pattern]] — the pattern cortex-forge implements
- [[wiki/concepts/super-context]] — session cold-start pattern; OpenHuman's implementation vs cortex-forge's hook approach
- [[wiki/concepts/progressive-disclosure-hooks]] — just-in-time context loading; complements the comparison
- [[wiki/entities/openhuman]] — closest full-harness comparable (added 2026-06-26)
- [[wiki/entities/openbrain-nate-jones]] — cross-tool alternative with embeddings
- [[wiki/projects/cortex-forge]] — main project page

---

- 2026-06-26 [Claude Code]: Page created — consolidated from moon-multivac/wiki/concepts/cortex-forge-vs-alternatives.md (2026-06-20, 16+ systems analysis) + updated with OpenHuman and Obsidian Mind from this vault; translated to English per vault locale
