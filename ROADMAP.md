# Roadmap

## Phase 1 — Multi-agent parity ✓

Goal: Hot Cache Protocol working across all supported agents.

- [x] Claude Code — hooks + skills via `cortex-forge-setup`
- [x] Compatibility matrix → `wiki/concepts/agent-hook-compatibility.md`
- [x] Antigravity CLI — reactivate + crystallize hooks; TASTE; validate end-to-end ✅
- [x] CommandCode — Stop hook; TASTE rule (per-project + global); validate end-to-end ✅
- [ ] Codex — partial
  - [x] Hooks installed (`SessionStart` + `Stop` no-op guards); symlinks via `~/.cortex-forge/bin/hooks/`
  - [x] `cortex-reactivate-codex.sh` confirmed: context injected on startup (visible as `hook context:` in UI — intended)
  - [ ] Validate end-to-end: ingest source → recall → crystallize in organic session

## Phase 2 — Protocol hardening ✓

- [x] `.hot/` → `.cortex/` consolidation — single mutable zone; `CODEX.md` absorbed into `AGENTS.md`
- [x] `MEMORY.md` / `PRAXIS.md` split — session state vs. accumulated conventions (30-day TTL)
- [x] Multi-vault — `~/.cortex-forge/config.yml` with `vaults:` + `default:`; CWD-first resolution
- [x] Hook distribution architecture — `bin/hooks/` (source) → `~/.cortex-forge/bin/hooks/` (runtime) → per-agent symlinks; `/cortex-forge-setup update` to propagate
- [x] Schema versioning — `schema_version: "0.3"` in `AGENTS.md` and all templates
- [x] `agent:` field in snapshot frontmatter — identifies last writer in multi-agent vaults
- [x] Stale cache detection — `hot_cache_stale_days:` in config; warning injected at SessionStart
- [x] Compliance guardrails — verifiable contracts in `AGENTS.md`; mandatory output format in `cortex-recall`, `cortex-assimilate`, `cortex-crystallize`
- [x] Behavior tags in skills — `behavior:` frontmatter; 6 tags: `#ingest #synthesize #recall #prune #snapshot #configure`
- [x] Context fencing in `cortex-imprint` — source hierarchy (session > `.raw/` > `wiki/` reference only); circular synthesis test; `raw:` provenance field
- [x] Link-count scan — orphan page detection in `cortex-prune.sh`; `orphan_pages` in `vault-report.json`, surfaced at SessionStart
- [x] Post-commit hooks — prune refreshes `vault-report.json`; reindex updates `vault.db` (opt-in, both gated on `wiki/` changes)
- [x] "Attempted and failed" section in crystallize template
- [x] Sanitization in `cortex-assimilate` — `bin/cortex-sanitize.sh`; scans invisible Unicode, HTML comments, base64, egress commands
- [x] Imprint pipeline — detection at Stop (Haiku), triage at SessionStart (`off | suggest | auto`), draft written to `.cortex/imprint-draft.md`
- [x] Imprint `auto` mode — `cortex-imprint-auto.sh` runs `claude -p` (Haiku) in background at SessionStart; writes page, updates index + log, removes draft

## Phase 3 — Adoptability

- [x] License added to public repo
- [x] `install.sh` — curl installer: clones forge, detects vault, links hooks and skills for all detected agents, pipe-safe
- [ ] Onboarding guide: 5 minutes from zero to first ingest
- [ ] Example pages in `wiki/concepts/` (canonical format reference, not personal content)
- [ ] `wiki/prompts/` page type — archive effective agent invocations with sample output
- [ ] MOCs per topic area — `wiki/concepts/_index.md`, `wiki/entities/_index.md` as navigable area indexes

## Phase 3.5 — cortex-prune dual mode

**Gate:** Phase 3 example pages (they double as the held-out validation set).

### `prune-vault` (current)
Vault maintenance: orphan pages, broken wikilinks, stale hot cache.

### `prune-cortex` (new)
Self-optimization: reads transcripts where skills failed → proposes targeted edits to `SKILL.md` → validation gate accepts only edits that improve the held-out set.

Skills suitable (verifiable outputs): `cortex-recall`, `cortex-assimilate`.
Skills not suitable (subjective): `cortex-crystallize`, `cortex-imprint`.

Reference: `wiki/concepts/skillopt-text-space-optimization.md`

- [ ] Phase 3.5a — propose edits to `SKILL.md` from transcripts; user approves (no scoring)
- [ ] Phase 3.5b — validation gate: example pages as held-out set; accept edits only if score improves
- [ ] Phase 3.5c (optional) — SkillOpt-Sleep integration if community demands it

## Phase 3.6 — Semantic retrieval (sqlite-vec)

**Stack:** `sqlite-vec` + Ollama (default) → mlx-embeddings (Apple Silicon) → sentence-transformers. Model: `nomic-embed-text-v1.5` (768 dims).

**Known limitations:**
- MLX packages blocked on Python 3.14 + transformers 5.x — see `wiki/concepts/embedding-backend-selection.md`
- `nomic-embed-text-v2-moe` upgrade gated on ollama/ollama#16076

- [x] `embeddings.py` — backend selector with per-backend error messages (co-located with `cortex-forge-setup`, 2026-07-03: moved out of `bin/` so it ships with `npx skills add`)
- [x] `cortex-index.py` — heading-based chunking + 500-word/100-overlap sub-chunks; atomic updates; auto-threshold calibration (co-located with `cortex-forge-setup`)
- [x] `cortex-search.py` — KNN two-step; `--top-k`, `--threshold`, `--json` flags (co-located with `cortex-forge-setup`)
- [x] `cortex-recall` updated — invokes `cortex-search.py` if `vault.db` exists; fallback to index read
- [x] Post-commit reindex hook — re-indexes only `wiki/` files touched in each commit
- [x] `.cortex/` fully gitignored
- [ ] Validate in second vault: initial index + test query + incremental reindex after `cortex-assimilate`
- [ ] MCP server — `vault_ingest`, `vault_query`, `vault_imprint`, `session_snapshot`, `vault_prune` — **gate: Stage 1 validated in second vault**. **Distribution:** unlike the skills (installed via `npx skills add`, a static-file installer), an MCP server is a persistent process — the natural fit is publishing it as its own npm package and installing with `npx github:itsmistermoon/cortex-forge-mcp` (or `claude mcp add` once published), not through the vault's skills tarball. The [official MCP Registry](https://modelcontextprotocol.io/registry) is still in preview (breaking changes possible before GA) — track it, but don't block the server's launch on it; npm/GitHub distribution works today independent of registry maturity.

## Phase 4 — Accumulated intelligence

- [x] History archive (simple layer) — entries >30 days → `.cortex/CONSOLIDATED.md` (append-only, not injected at startup)
- [ ] History archive (structured layer) — when `CONSOLIDATED.md` exceeds N entries, crystallize parses to JSON `{ts, agent, trigger, tags, files, decisions, discarded, fragile}`; queryable via `/cortex-recall`
- [ ] `cortex-recall` cross-page synthesis + contradiction detection
- [ ] Cross-session pattern detection — recurring topics in `.cortex/` that never reach `wiki/`; propose imprint candidates at crystallize time
- [ ] Progressive loading in `cortex-recall` — navigate wiki by relevance instead of loading full index at startup
