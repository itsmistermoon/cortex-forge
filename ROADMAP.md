# Roadmap

## Phase 1 — Multi-agent parity ✓

Goal: Hot Cache Protocol working identically across coding agents, via a manual `AGENTS.md` protocol.

- [x] Skills installed and manual AGENTS.md protocol validated end-to-end on multiple agents
- [ ] Validate end-to-end on any newly supported agent: ingest source → recall → crystallize in an organic session

## Phase 2 — Protocol hardening ✓

- [x] `.cortex/` — single mutable zone for session state
- [x] `MEMORY.md` / `PRAXIS.md` split — session state vs. accumulated conventions (15-day TTL)
- [x] Multi-vault — `~/.cortex-forge/config.yml` with `vaults:` + `default:`; CWD-first resolution
- [x] Schema versioning — `schema_version: "0.3"` in `AGENTS.md` and all templates
- [x] `agent:` field in snapshot frontmatter — identifies last writer in multi-agent vaults
- [x] Stale cache detection — `hot_cache_stale_days:` in config (global); checked at MEMORY.md read time per AGENTS.md protocol
- [x] Compliance guardrails — verifiable contracts in `AGENTS.md`; mandatory output format in `cortex-recall`, `cortex-assimilate`, `cortex-crystallize`
- [x] Behavior tags in skills — `behavior:` frontmatter; 6 tags: `#ingest #synthesize #recall #prune #snapshot #configure`
- [x] Context fencing in `cortex-imprint` — source hierarchy (session > `.raw/` > `wiki/` reference only); circular synthesis test; `raw:` provenance field
- [x] Link-count scan — orphan page detection in `cortex-prune.sh`; `orphan_pages` in `vault-report.json`, surfaced via `AGENTS.md`'s mandatory read protocol
- [x] Post-commit git hooks (opt-in) — prune refreshes `vault-report.json`; reindex updates `vault.db`, both gated on `wiki/` changes
- [x] "Attempted and failed" section in crystallize template
- [x] Sanitization in `cortex-assimilate` — `bin/cortex-sanitize.sh`; scans invisible Unicode, HTML comments, base64, egress commands
- [x] Imprint candidate flagging — `cortex-crystallize` writes `#### Imprint candidate` to History when warranted; `AGENTS.md` protocol surfaces it and proposes `/cortex-imprint` at next session start

## Phase 3 — Adoptability

- [x] License added to public repo
- [x] Distribution via `npx skills add itsmistermoon/cortex-forge` — installs skills for all detected agents; supports `--skill X` for standalone installs
- [x] Changesets for `CHANGELOG.md` — one changeset per notable change, consolidated at release time (`npx changeset version`); no `npm publish` step, this repo isn't on the npm registry
- [x] PR-based workflow for skill changes — branch → PR (with its changeset) → merge, even solo; each change gets an auditable page instead of a buried commit. `.github/workflows/changesets.yml` opens/updates the "Version Packages" PR on push to `main`
- [ ] Install the [Changeset bot GitHub App](https://github.com/apps/changeset-bot) — comments on a PR if it's missing a changeset; manual step, can't be done via CLI/API
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

- [x] `embeddings.py` — backend selector with per-backend error messages (co-located with `cortex-forge-setup`)
- [x] `cortex-index.py` — heading-based chunking + 500-word/100-overlap sub-chunks; atomic updates; auto-threshold calibration (co-located with `cortex-forge-setup`)
- [x] `cortex-search.py` — KNN two-step; `--top-k`, `--threshold`, `--json` flags (co-located with `cortex-forge-setup`)
- [x] `cortex-recall` updated — invokes `cortex-search.py` if `vault.db` exists; fallback to index read
- [x] Post-commit reindex hook — re-indexes only `wiki/` files touched in each commit
- [x] `.cortex/` fully gitignored
- [ ] Validate in second vault: initial index + test query + incremental reindex after `cortex-assimilate`
- [ ] MCP server — `vault_ingest`, `vault_query`, `vault_imprint`, `session_snapshot`, `vault_prune` — **gate: Stage 1 validated in second vault**. **Distribution:** unlike the skills (installed via `npx skills add`, a static-file installer), an MCP server is a persistent process — the natural fit is publishing it as its own npm package and installing with `npx github:itsmistermoon/cortex-forge-mcp` (or `claude mcp add` once published), not through the vault's skills tarball. The [official MCP Registry](https://modelcontextprotocol.io/registry) is still in preview (breaking changes possible before GA) — track it, but don't block the server's launch on it; npm/GitHub distribution works today independent of registry maturity.

## Phase 4 — Accumulated intelligence

- [x] History archive (simple layer) — entries >15 days → `.cortex/CONSOLIDATED.md` (append-only, not injected at startup)
- [ ] History archive (structured layer) — when `CONSOLIDATED.md` exceeds N entries, crystallize parses to JSON `{ts, agent, trigger, tags, files, decisions, discarded, fragile}`; queryable via `/cortex-recall`
- [ ] Cross-session pattern detection — recurring topics in `.cortex/` that never reach `wiki/`; propose imprint candidates at crystallize time
- [ ] Progressive loading in `cortex-recall` — navigate wiki by relevance instead of loading full index at startup

### `cortex-recall` — offer to persist, rarely

Gap vs. the source pattern this project draws from (Karpathy's LLM-wiki gist): a good query answer should be able to compound into the wiki, not dead-end in chat. Design borrowed from `moon-reflex/skills/reflex-query`, which solves this leanly — an occasional offer, never automatic writing.

**Implementation:** add a 4th step to `cortex-recall/SKILL.md`, after "Answer":
- Trigger only when the answer combines ≥2 existing pages into an insight not written down anywhere, or fills a real gap the wiki had no page for.
- Skip when the answer is satisfied by pointing at a single existing page verbatim — this must stay rare, not a footer on every response.
- On trigger, end the response with one line: "This isn't written anywhere in the vault yet — want me to save it? (`/cortex-imprint`)". No auto-write, no follow-up unless the user accepts.

- [x] Add step 4 to `cortex-recall/SKILL.md` with the trigger condition above
- [ ] Verify against 10+ real queries in a populated vault: confirm the offer stays rare (not triggered on simple lookups) and fires on genuine synthesis

### `cortex-prune` — contradiction detection (folded into L2a)

Gap vs. Karpathy's gist, which lists contradictions alongside orphans and stale claims as a lint responsibility — `cortex-prune`'s Layer 2 had no check for it (L2a–L2d covered unlinked relationships, missing wikilinks, uncovered sources, and merge candidates, but never conflicting claims). Design borrowed from `moon-reflex/skills/reflex-lint` step 2.

**Implementation:** folded into L2a instead of a separate check — L2a already reads both pages in a candidate pair to classify RELATED/COINCIDENCE, so the contradiction judgment reuses that same read instead of opening the pages a second time:
- For each pair L2a classifies RELATED, compare their claims on the shared subject in the same pass.
- Classify CONTRADICTION (incompatible facts) vs CONSISTENT (differences of emphasis, scope, or vintage only).
- Report CONTRADICTION as a separate MEDIUM: both excerpts side by side, no proposed action — this needs human judgment to resolve, not a suggested fix.
- No separate hard cap needed — bounded by L2a's existing 20-candidate-pair cap.

- [x] Fold contradiction comparison into L2a's per-pair evaluation in `cortex-prune/SKILL.md`
- [x] Add contradiction findings to the `## Requires confirmation` list (resolution is never auto-applied)
- [ ] Verify against a vault with at least one known, planted contradiction

### `cortex-recall` — log misses, not queries

Considered logging every query (`log.md` as "record of ingests, queries, lint passes" per the gist) and rejected full logging as noise for a single-user vault — no audit need, no multi-user accountability case. The one real signal is recurring gaps: the same unanswered question surfacing across sessions is a concrete candidate for `/cortex-assimilate`, and today that signal is silently lost the moment step 2's "Not in vault" response is given — nothing records that it happened.

**Implementation:**
- When `cortex-recall` step 2 finds no relevant pages ("Not in vault"), append one line to `wiki/meta/log.md`: `## [YYYY-MM-DD] recall-miss | {query}`.
- No logging on hits — only misses. This keeps `log.md` from filling with routine successful lookups.
- `cortex-prune` gains a Layer 2 check (or extends L2c) that scans recent `recall-miss` entries for repeated/similar topics and reports them as MEDIUM candidates for `/cortex-assimilate`, the same way it already surfaces `NEEDS_PAGE` sources.

- [x] Add miss-logging to `cortex-recall/SKILL.md` (landed in step 3, where the "Not in vault" case is actually decided)
- [x] Add a recall-miss pattern check to `cortex-prune` (landed as L2e, its own check rather than an L2c extension — L2c reads vault pages, L2e reads `wiki/meta/log.md`, different enough to keep separate)
- [ ] Verify: repeat a query with no answer 3x across sessions, confirm `cortex-prune` surfaces it as a candidate
