---
title: cortex-forge
type: project
created: 2026-06-08
updated: 2026-07-01
tags: [vault, multi-agent, hot-cache, hooks, knowledge-management]
status: active
repo: /Users/itsmistermoon/proyectos/moon-cortexforge
domains: [agent-orchestration, knowledge-management, multi-agent-protocols]
sources:
  - wiki/sources/commandcode-hooks-configuration.md
  - wiki/sources/commandcode-headless.md
  - wiki/sources/commandcode-security.md
  - wiki/sources/codex-hooks.md
  - wiki/sources/antigravity-hooks.md
  - wiki/sources/ai-coding-dictionary.md
  - wiki/sources/obsidian-mind.md
confidence: high
schema_version: "0.3"
---

# cortex-forge

**Status:** active
**Repo:** /Users/itsmistermoon/proyectos/moon-cortexforge

## Origin

Born as a public mirror of moon-multivac (JP's private vault), created initially to apply to OpenAI Codex for OSS. After the application, JP decided to develop it as a real OSS project with an independent repo. Local development: `~/proyectos/cortex-forge/`. moon-multivac is a *consumer* of cortex-forge, not its source.

## Goal

Be the reference implementation of an LLM-native vault for multi-agent operation: any developer can fork the repo and have a knowledge base that any agent (Claude Code, Codex, Gemini, Cursor) can operate without additional configuration. Unlike tools like Obsidian or Notion, cortex-forge assumes the agent is the primary operator, not the human.

Vault with a hot cache protocol that synchronizes context across multiple agents (Claude Code, Codex, Antigravity, CommandCode) without token bloat at session start. Synthesized knowledge lives in `wiki/` (secondary sources); originals in `.raw/` (primary sources, immutable); ephemeral per-project context in `.cortex/MEMORY.md` and accumulated agent context in `.cortex/PRAXIS.md`; vault identity in `AGENTS.md` (`## Vault identity`).

## Stack / Technologies

- 5 layers: `.raw/`, `wiki/`, `.cortex/`, `wiki/meta/`, `skills/`
- 4 wiki page types: concept, entity, source, project (reference collapsed into concept — 2026-06-30)
- 6 vault skills: assimilate, recall, prune, imprint, crystallize, forge-setup
- No agent lifecycle hooks (removed 2026-07-02) — `AGENTS.md` mandates reading `.cortex/MEMORY.md` before the first response and invoking `/cortex-crystallize` manually at milestones and session close, identically on every agent
- post-commit git hook: `cortex-reindex-post-commit.sh` — re-indexes `.cortex/vault.db` automatically when the commit touches `wiki/` files (the only hook still in use — a git hook, not an agent lifecycle hook)
- Templates co-located with their skills: `MEMORY-FORMAT.md`, `TASTE-FORMAT.md`
- Shared reference files co-located with skills: `LOCALE-RESOLUTION.md`, `EMBEDDING-SETUP.md`
- CI: `bin/check-skill-sync.sh` + `.github/workflows/skill-sync.yml` — 6 cross-skill consistency invariants verified on push

## Key decisions

- **Superseded 2026-07-02:** agent lifecycle hooks (Layer 2) were removed entirely. Support was too uneven across Claude Code, Codex, Antigravity, and CommandCode to build the suite on top of it — see [[wiki/concepts/agent-hook-compatibility]] for the findings that drove this call. `AGENTS.md` (formerly "Layer 1") is now the only mechanism, identical on every agent.
- **`.cortex/MEMORY.md` — fixed name per repo.** No project-name detection needed; each repo has its own `.cortex/` directory (gitignored). Safe across multiple concurrent projects.
- **Two-zone MEMORY.md:** `## Current state` (mutable, max 5 pending / 3 decisions) + `## History` (append-only). Only Current state is reinjected at session start — History is available but not required.
- **Superseded 2026-07-02:** the PreCompact/SessionEnd distinction (and the `claude -p` synthesis behind it) no longer applies — both were hook-triggered and hooks were removed. `/cortex-crystallize` is invoked manually at milestones and at session close; there is no automatic mid-session checkpoint.
- **CODEX.md retired.** Vault identity (Mission, Owner, Domains, Vocabulary) moved into `AGENTS.md` under `## Vault identity`. CODEX.md file deleted from vault root. This unifies the two session-start reads — agents now load only `AGENTS.md` for both protocol and identity context.
- **Parametric knowledge disqualified** for vault topics. Agent training knowledge is unverified and unversioned — `cortex-recall` is mandatory even when the agent "knows" the answer.
- **Scripts co-located with their skill, not in a shared `bin/`.** As of 2026-07-03, `cortex-prune.sh`, `cortex-sanitize.sh`, `cortex-index.py`, `cortex-search.py`, `embeddings.py`, and `cortex-reindex-post-commit.sh` live inside the `skills/` directory of whichever skill uses them — so `npx skills add itsmistermoon/cortex-forge --skill X` installs a working skill without needing `~/.cortex-forge/` at all. `~/.cortex-forge/bin/` is now only a small runtime cache, populated at setup time, used exclusively by the two post-commit git hooks (which need a fixed absolute path since they run outside any agent session). Consumer vaults (`moon-multivac`, `moon-academy`, etc.) still have no `bin/` directory of their own.

- **`cortex-forge-setup` has two modes.** New vault (not in config) → full wizard, all steps in sequence. Existing vault → maintenance menu: numbered list of operations (update skills, sync, initialize semantic search, add post-commit prune/reindex git hooks, install TASTE rule, remove vault, set default). User selects one or more; only selected steps run.

- **Setup gate for semantic search corrected.** Step 6c used to skip silently if `.cortex/vault.db` was absent — which always happens on a new vault. Corrected: if `vault.db` doesn't exist, the setup asks whether to initialize it now (runs `cortex-index.py` once) or skip with an explicit note in the summary. Silent skip replaced by explicit choice.

- **`.raw/` is immutable primary source.** `wiki/` is always a derived secondary view. When they conflict, `.raw/` wins — the conflict rule is the remedy for **drift** (the primary changes, the account doesn't follow). The `raw:` frontmatter field on source pages is a **context pointer** back to the primary, and `cortex-prune.sh` (co-located with the `cortex-prune` skill) verifies it — the vault implemented the pattern before the vocabulary existed.
- **Reference taxonomy:** fifth wiki type for lookup tables, wire formats, cheat sheets — use when the content can be expressed as a table/code block without prose. Complements Concept (which requires explanation).
- **CommandCode wire format is nested** (`hooks: [{ matcher, hooks: [{ type, command, timeout? }] }]`), unlike the flat format of Claude Code/Codex. Hook scripts are not drop-in across agents.
- **Project pages only for user's own projects** — third-party entities go in `wiki/entities/`, not `wiki/pages/`.
- **[[wiki/sources/obsidian-mind]] is the closest comparable project** — both target agent-operated knowledge vaults; obsidian-mind focuses on Obsidian-native graph exploration with MCP, while cortex-forge generalizes to any agent via hot cache protocol. Key difference: obsidian-mind requires Obsidian; cortex-forge is agent-agnostic.

- **Vector retrieval over grep for `cortex-recall`** — at ~50+ wiki pages the grep-based recall degrades: the agent decides what to read rather than what exists. The fix is a pre-built vector index; `cortex-recall` queries the index and receives a bounded top-k set of paths instead of choosing files itself. The index runs as a Python script invoked via bash — the agent remains the runtime, the index is a lookup layer.
- **sqlite-vec over ChromaDB (or any other vector store)** — ChromaDB requires a client-server model and non-trivial dependencies. sqlite-vec is a SQLite extension: one `.db` file, no background process, zero server. Cortex Forge is deliberately zero-dependency; sqlite-vec maintains that principle. Any other embeddable vector library (LanceDB, Faiss) would have worked architecturally, but sqlite-vec keeps the stack the simplest.
- **Platform-aware embedding backend, not a single choice** — the embedding backend is selected at runtime by `.cortex/embeddings.py` based on OS and architecture. On Apple Silicon (`Darwin` + `arm64`), `mlx-embeddings` with `mlx-community/nomic-embed-text-v1.5` is preferred — it uses the Neural Engine and is faster than `sentence-transformers` on M-series. On Linux, Windows, and Intel Mac, `sentence-transformers` with `nomic-ai/nomic-embed-text-v1.5` is used — runs in-process, downloads weights on first use (~270 MB), falls back to CPU universally. If mlx is not installed on Apple Silicon, the code falls back to `sentence-transformers` automatically. All platform detection and fallback logic lives in `.cortex/embeddings.py`; nothing else in the stack duplicates it. `normalize_embeddings=True` is mandatory for the `sentence-transformers` path — without it, dot product and cosine are not equivalent.
- **Ollama discarded for embeddings** — requires a running server at `localhost:11434`. Breaks in post-commit hooks, CI environments, and any user who hasn't installed it. Not viable for a public project with no infrastructure prerequisites.
- **Dot product over cosine similarity** — `nomic-embed-text-v1.5` with `normalize_embeddings=True` produces unit-norm vectors. For unit-norm vectors, dot product and cosine are mathematically equivalent. sqlite-vec exposes `vec_distance_dot`, which is computationally cheaper than explicit cosine. No precision is lost.
- **`disable-model-invocation: true` is the correct mechanism for manual-only skills** — `cortex-imprint` previously tried to prevent auto-invocation through description text ("Do not invoke automatically…"). This is instruction fighting mechanism: if the description is present, the model can still fire the skill. The correct fix is the frontmatter field, which removes the skill from the model's reach entirely. Rule: when a skill must be manual-only, use the mechanism, not a verbal warning in the description.

- **Progressive disclosure for skill reference** — shared reference material that only some skill branches need should live in a co-located file, not inline in SKILL.md. Two instances: `LOCALE-RESOLUTION.md` (locale fallback chain, shared by 6 skills — was duplicated verbatim in each) and `EMBEDDING-SETUP.md` (embedding dependency check, used only when semantic search is enabled — was 25 inline lines in forge-setup step 6d). Pattern: disclose what only some branches need; inline what every branch needs.

- **CI guards skill protocol invariants** — `bin/check-skill-sync.sh` runs 6 checks on push: no legacy `vault:` format, no CODEX.md references, wiki/index.md update mentions, vault-report schema consistency between cortex-prune and AGENTS.md, non-empty descriptions, correct prune script path. GitHub Actions triggers on changes to `skills/**/SKILL.md`, `AGENTS.md`, or `bin/check-skill-sync.sh`. First failure caught: `missing_confidence` was declared in cortex-prune schema but not referenced in AGENTS.md session-start protocol.

- **wiki/meta/ convention: `_index.md` for humans, trigger rules in AGENTS.md for agents** — `_index.md` is not auto-loaded by any agent, so agent behavioral rules placed there are invisible. The convention for when to write to `wiki/meta/log.md` belongs in AGENTS.md `## On session close` — that section IS read every session. `_index.md` documents the directory for human readers (file table, what goes/doesn't, log format). Neither duplicates the other.

- **Backward enrichment — planned post-ingest step** — `cortex-assimilate` creates pages for new sources but doesn't update existing pages that should now reference the new source. Planned detection mechanism: compare the new source's `tags:` against all wiki pages; flag those whose `updated:` predates the ingestion and share at least one tag. An agent reviews each candidate and proposes updates — no write without evaluation (catches false positives where tag overlap is incidental, not topical). The same signal (tag overlap + `updated:` age) works in `cortex-prune` as a Layer 3 post-hoc check across all sources, complementing the proactive ingest-time version. Connection to git-diff-scoped pattern: both mechanisms use structured page metadata (tags, updated, raw:) to detect staleness without re-reading all content. Currently planned — not yet implemented.

- **MCP server deferred to Etapa 2** — sqlite-vec solves retrieval; MCP solves multi-client dispatch. These are separate problems. Implementing both simultaneously creates two simultaneous diagnostic surfaces if something fails. Gate: Etapa 1 validated in an organic session AND the vault is accessed from more than one client. `AGENTS.md` remains the design contract regardless — an agent without MCP can still operate the vault by reading `AGENTS.md` directly.
- **[[wiki/entities/openhuman|OpenHuman]] is the closest full-harness comparable** — both solve the agent cold-start problem via a local Karpathy-style Obsidian vault as the memory layer, and both implement the [[wiki/concepts/super-context|Super Context]] pattern (harness-level deterministic context injection on session start). Key divergences: OpenHuman is a desktop GUI application with 118+ managed OAuth integrations and automatic 20-minute auto-fetch loops that populate the vault without agent involvement; Cortex Forge is a vault protocol that any CLI agent operates via skills and `AGENTS.md` instructions (no lifecycle hooks — see [[wiki/concepts/agent-hook-compatibility]]), with knowledge synthesized manually from ingested sources. OpenHuman's SuperContext runs inside the harness (Python/Rust app); Cortex Forge's equivalent is the agent reading `.cortex/MEMORY.md` per `AGENTS.md` before the first prompt. OpenHuman is user-facing and batteries-included; Cortex Forge is agent-infrastructure and composable. TokenJuice (OpenHuman's token compression layer — up to 80% reduction via HTML→Markdown, URL shortening, dedup) has no Cortex Forge equivalent; the vault reduces token cost indirectly by replacing file-by-file retrieval with a pre-built semantic index.

- **`.cortex/` consolidates all local agent artifacts.** Previously `.hot/` held session memory and `.cortex/` held semantic search infrastructure. Now everything is under `.cortex/`: `MEMORY.md` (session snapshot), `PRAXIS.md` (accumulated agent context), `CONSOLIDATED.md` (history archive), and `db/` (vault.db, embeddings.py, cortex-search.py, config.json). A single `.cortex/` gitignore entry covers everything.

- **PRAXIS.md — two-zone accumulated agent context.** Persistent knowledge the agent builds across sessions that doesn't fit the session-scoped MEMORY.md or the wiki's synthesized knowledge. Two zones: `## Permanent` (no TTL — structural conventions, workarounds, invariants the agent writes deliberately) and `## Working context` (dated entries auto-pruned by `/cortex-crystallize` after 30 days). Unlike MEMORY.md (rewound per session), PRAXIS.md is the agent's long-term institutional memory within a vault.

- **[[wiki/entities/graphify|Graphify]] + Leiden discarded for retrieval** — Leiden is community detection over graphs inferred from code ASTs (via tree-sitter). Cortex Forge's vault contains synthesized prose knowledge in Markdown, not source code. Relationships between pages are captured by the vault taxonomy (`wiki/concepts/`, `wiki/entities/`, etc.) and don't need to be inferred from syntax. Embeddings + semantic similarity solve the actual problem with lower complexity.

## Roadmap

See [ROADMAP.md](../../ROADMAP.md).

## Next steps

## Resolved

- [x] Verificar hook Stop de CommandCode en `second-brain/` — script degradaba silenciosamente con el wire format de CommandCode. Fix: `bin/hooks/cortex-crystallize-commandcode.sh` creado (no depende de transcript, no usa `claude -p`). Hook instalado en `second-brain/.commandcode/settings.local.json` (scope correcto) y corregido también en `cortex-forge/.commandcode/settings.local.json`. (2026-06-10, CommandCode)

## Knowledge applied

- [[wiki/concepts/agent-hook-compatibility]] — Lifecycle hook matrix per agent
- [[wiki/concepts/progressive-disclosure-hooks]] — Just-in-time context loading
- [[wiki/concepts/antigravity-hooks]] — Antigravity-specific hook configuration
- [[wiki/concepts/karpathy-wiki-pattern]] — Wikis optimized for LLM consumption
- [[wiki/concepts/handoff-artifact]] — .hot/MEMORY.md as handoff artifact; two-zone design
- [[wiki/concepts/memory-system]] — Pattern for making agents stateful across sessions
- [[wiki/concepts/smart-zone]] — Motivation for crystallize (session degradation over time)
- [[wiki/concepts/parametric-knowledge]] — Why training knowledge is disqualified for vault topics
- [[wiki/concepts/contextual-knowledge]] — What cortex-recall injects: verifiable, citable facts
- [[wiki/concepts/primary-source]] — `.raw/` as the vault's instance: immutable, complete, current by definition
- [[wiki/concepts/secondary-source]] — `wiki/` as the vault's instance: lossy/drift failure modes named; `raw:` field is the context-pointer remedy, conflict rule is the drift remedy

## Recurring issues

- `cortex-recall` compliance gap — agents fall back to manual search or parametric knowledge despite `MANDATORY` in `AGENTS.md`. Compliance criteria added to the protocol (2026-06-08) but root cause unresolved. May require PostToolUse guardrail to enforce.
- Codex hooks need a stable global path (e.g., `~/.codex/hooks/`) with runtime vault resolution. Vault-local paths break multi-vault and off-vault setups.
- Antigravity `cortex-crystallize-antigravity.sh` installed but not verified in a real organic session.
- CommandCode Stop hook: requiere `cortex-crystallize-commandcode.sh` (script dedicado, no comparte con Claude Code). Resuelto: script creado, hook instalado en second-brain y cortex-forge.

## Sources

- [[wiki/sources/commandcode-hooks-configuration]] — CommandCode wire format and scopes
- [[wiki/sources/codex-hooks]] — Codex lifecycle and trust
- [[wiki/sources/antigravity-hooks]] — Antigravity/Gemini CLI configuration
- [[wiki/sources/gemini-cli-hooks-video]] — Official hooks & skills video
- [[wiki/sources/ai-coding-dictionary]] — Vocabulary source: handoff, compaction, primary/secondary source, memory system
- [[wiki/sources/openhuman]] — OpenHuman README: comparable harness with Memory Tree, SuperContext, TokenJuice
- [[wiki/sources/openhuman-super-context]] — SuperContext feature article (featured): harness-level deterministic context injection
- [[wiki/sources/openwiki]] — OpenWiki: LLM-generated codebase wiki + git-diff-scoped automated updates (LangChain AI, 2026-07-01)

---

- 2026-06-08 [CommandCode / MiniMax-M3]: Page created retroactively — vault already active since 2026-06-07 but without a project page; consolidated to enable future project linking
- 2026-06-08 [Claude Code]: Translated to English
- 2026-06-08 [Claude Code]: Updated to reflect v0.1.0 state — CODEX.md layer, fixed MEMORY.md name, 5 wiki types, PreCompact/SessionEnd distinction, parametric knowledge decision, primary/secondary source taxonomy, co-located templates, updated next steps and recurring issues
- 2026-06-10 [Claude Code]: Linked primary-source/secondary-source concepts (full-article ingestion); adopted "context pointer" and "drift" vocabulary in the `.raw/` key decision
- 2026-06-16 [Claude Code]: Added design decisions for Fase 3.6 (vector retrieval stack): sqlite-vec rationale, sentence-transformers over Ollama/mlx, dot product metric, MCP deferral gate, Graphify+Leiden discard
- 2026-06-26 [Claude Code]: Added OpenHuman as closest full-harness comparable; SuperContext pattern comparison; added openhuman sources
- 2026-06-27 [Claude Code]: Added post-commit reindex hook to stack description; corrected repo path to moon-cortexforge
- 2026-06-28 [Claude Code]: Added three key decisions — hook scripts global-only (no bin/ in consumer vaults), cortex-forge-setup maintenance menu for existing vaults, semantic search init gate corrected
- 2026-06-28 [Claude Code]: Major restructure — `.hot/` + `.cortex/` consolidated into single `.cortex/` directory (`db/` for semantic search, `MEMORY.md` + `PRAXIS.md` flat); `CODEX.md` retired and identity absorbed into `AGENTS.md`; PRAXIS.md introduced for two-zone accumulated agent context (permanent + working with 30-day TTL); updated stack layer count from 6 to 5
- 2026-07-01 [Claude Code]: Backward enrichment + drift detection patterns designed and documented — Key decisions, Roadmap Phase 4; reflected in README
- 2026-07-01 [Claude Code]: Skill suite audit (adversarial review + SkillOpt + writing-great-skills) — added CI, extracted LOCALE-RESOLUTION.md and EMBEDDING-SETUP.md, added disable-model-invocation to cortex-imprint, deduplicated Rules/Constraints across skills, removed ## When to invoke redundancy, added completion criterion to assimilate step 5, translated Spanish sediment in cortex-prune, co-located YAML block in forge-setup; wiki/meta/ convention defined; 4 key decisions added
- 2026-07-02 [Claude Code]: Agent lifecycle hooks removed entirely (SessionStart, PreCompact, SessionEnd, Stop, PreToolUse) — support was too uneven across Claude Code, Codex, Antigravity, and CommandCode to build the suite on top of it. `~/.cortex-forge/bin/hooks/` now holds only the git post-commit reindex script. `AGENTS.md` mandates the manual protocol (read `.cortex/MEMORY.md` before first response, invoke `/cortex-crystallize` manually) identically on every agent. Updated `cortex-forge-setup/SKILL.md`, `cortex-crystallize/SKILL.md`, `install.sh`, `README.md`, `AGENTS.md`. See [[wiki/concepts/agent-hook-compatibility]] for the per-agent findings that justified the decision.
- 2026-07-03 [Claude Code]: Scripts relocated to be co-located with the skill that uses them, so the vault is installable via `npx skills add` (skills.sh) without depending on the tarball runtime — see [[wiki/reference/workflow-architecture]] for the full mapping. `~/.cortex-forge/bin/` demoted from "runtime source" to "runtime cache for the two git hooks." Fixed two latent path bugs discovered in the process (reindex hook pointed at a nonexistent vault-local `bin/cortex-index.py`; `cortex-assimilate` step 7 pointed at `.cortex/cortex-index.py` instead of `.cortex/db/cortex-index.py`). `install.sh` kept working in parallel — not deprecated yet.
