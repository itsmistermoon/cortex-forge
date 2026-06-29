		# Roadmap

## Phase 1 — Multi-agent parity

Goal: Hot Cache Protocol working across all supported agents.

- [x] Claude Code — configured via `cortex-forge-setup`
- [x] Compatibility matrix → `wiki/concepts/agent-hook-compatibility.md`
- [x] Antigravity CLI — complete
  - [x] Run `/cortex-forge-setup` from Antigravity — displays JSON block to add
  - [x] Configure hooks in `~/.gemini/config/hooks.json` (PreInvocation + Stop) — migrated to `cortex-reactivate-antigravity.sh` + `cortex-crystallize-antigravity.sh`; symlink to `~/.gemini/antigravity-cli/hooks.json` due to agy-cli bug #49
  - [x] **TEST**: `cortex-reactivate-antigravity.sh` injects Zone 1 of `.cortex/` on startup — without payload returns `{"injectSteps":[]}` (correct); with `invocationNum=0` + workspace injects Zone 1 correctly
  - [x] **REWRITE**: `cortex-crystallize-antigravity.sh` — original script used `jq` on the transcript; Antigravity stores transcripts as SQLite+Protobuf (`.db`), not JSON. Rewritten to extract via `strings $TRANSCRIPT | grep -oE '"toolSummary":"[^"]*"'` and user messages from `history.jsonl`. Portability fix: `grep -P` → `grep -E` (BSD grep on macOS). Guard `[ -z "$TOOL_SUMMARIES" ] && exit 0` protects read-only sessions.
  - [x] **VALIDATE** in real organic session: `fullyIdle==true` fires hook → `agy -p` on real transcript → descriptive synthesis written to `.cortex/MEMORY.md` — real trigger validated in organic session (692b01be) ✅
  - [x] **VERIFY**: contradiction in `settings.json` path — `~/.gemini/config/settings.json` does not exist; real file is `~/.gemini/antigravity-cli/settings.json`
  - [x] Ingest a source with `cortex-assimilate`
  - [x] Query knowledge with `cortex-recall` — validated with citations and confidence level ✅
- [ ] Codex — partial
  - [x] Paste block into `~/.codex/hooks.json` (SessionStart + Stop) — hooks installed; symlinks via `~/.cortex-forge/bin/hooks/`
  - [x] Verify `.cortex/` is injected into context on session start — native hook confirmed; `hook context:` visible in UI is intended behavior, not a parsing error
  - [x] Create `cortex-crystallize-codex.sh` — wrapper that delegates to `cortex-crystallize-claude.sh` with `AGENT_LABEL=Codex`; installed at `~/.codex/hooks/cortex-crystallize-codex.sh`
  - [/] Run `/cortex-forge-setup` from Codex — skill supports vault detection + Update menu; pending manual verification from Codex itself
  - [ ] **VALIDATE** end-to-end flow: SessionStart injects `.cortex/` → real work → Stop fires wrapper → synthesis written — wrapper created ✅; validation in organic session pending ❌
  - [ ] Ingest a source with `cortex-assimilate`
  - [ ] Query knowledge with `cortex-recall`
- [x] CommandCode — complete
  - [x] Run `/cortex-forge-setup` from CommandCode — re-run; skills and symlinks updated
  - [x] Paste Stop hook block into CommandCode hooks file — copied to `second-brain/.commandcode/settings.local.json` with nested wire format
  - [x] Verify degraded mode session 1: agent reads `.cortex/` via `AGENTS.md` (Layer 1 confirmed — read on first turn, immediate project context)
  - [x] Verify full cycle session 2: `.cortex/` written in session 1 is read correctly in session 2
  - [x] Run `cortex-crystallize` and confirm snapshot saved
  - [x] Ingest a source with `cortex-assimilate`
  - [x] Query knowledge with `cortex-recall` — failed proactively (used `grep`); works under explicit instruction
  - [x] Install TASTE rule (`## Cortex Forge Skills`) in `taste.md` per-project (second-brain) and global (`~/.commandcode/taste/`) — setup step 7 run by Claude Code; CommandCode cannot edit `taste/` due to system policy

## Phase 2 — Protocol hardening

- [x] **Agent detection in `cortex-crystallize` (step 1a)** — 3 levels: (1) env vars (`CLAUDECODE=1`, `AI_AGENT` — Claude Code ✅); (2) process tree from `$PPID` looking for known binary — CommandCode ✅; (3) `which` as partial fallback. Antigravity and Codex: process-tree hypothesis, pending validation in real sessions.
- [x] **Multi-vault**: `~/.cortex-forge/config.yml` with `vaults: {name: path}` + `default:`; vault resolved by CWD first, then default; `cortex-forge-setup` registers/deregisters the current vault (toggle by CWD); legacy `vault:` supported in `cortex-crystallize`
- [x] Compliance guardrails for skills — verifiable contracts in `AGENTS.md` (protocol compliance criteria) + mandatory output format in `cortex-recall`, `cortex-assimilate`, `cortex-crystallize` — commit `ee7cbe5`
- [x] **Link-count scan** — orphan page detection implemented in `cortex-prune.sh` with full vault-relative path matching (eliminates basename collisions); `orphan_pages` field added to `vault-report.json` and surfaced on session start. Full `knowledge_map` dropped — no consumer. (2026-06-28)
- [-] Platform hook guardrail — **canceled** (2026-06-28)
  - [x] Grep interception: `cortex-recall-nudge.sh` implemented 2026-06-12 — **uninstalled**. The hook never logged any activations and the experiment was unmeasurable without logging. The declarative bypass (agent invokes `cortex-recall` via `AGENTS.md` instruction) covers the case with better reach and no overhead. De facto kill criterion: 0 data points in weeks. Script retained as `.retired` in `~/.cortex-forge/bin/hooks/`.
  - [-] SPA/PostToolUse — canceled. `cortex-assimilate` already covers the case by protocol; a PostToolUse hook cannot modify the agent's response and the marginal value does not justify the complexity.
- [x] Schema versioning in `AGENTS.md` and templates (`schema_version: "0.3"`) — 2026-06-15
- [x] Automatic `cortex-prune` via post-commit hook — post-commit hook refreshes `vault-report.json` on every commit (setup step 6b). Periodic hook for dormant vaults descoped: vaults without commits have no active sessions consuming the report, so staleness is not actionable. (2026-06-12)
- [x] Stale hot cache detection (not updated in N days) — `hot_cache_stale_days:` in `config.yml`; `cortex-reactivate.sh` and `cortex-reactivate-antigravity.sh` inject a warning on session start if threshold is exceeded
- [x] `agent:` field in `.cortex/` snapshot frontmatter — identifies which agent last wrote the mutable zone; needed to resolve conflicts in multi-agent vaults
- [x] Split `Project state` / `Agent context` — `.cortex/MEMORY.md` (session state) + `.cortex/PRAXIS.md` (accumulated agent context: permanent conventions + working context with 30-day TTL). `.hot/` removed; everything in `.cortex/`. `CODEX.md` absorbed into `AGENTS.md` (`## Vault identity`). (2026-06-28)
- [x] Context fencing in `cortex-imprint` — source hierarchy (session > `.raw/` > `wiki/` reference only), circular synthesis test, `raw:` field in provenance, source fencing rule in Rules. (2026-06-28)
- [x] Behavior tags in skills (`behavior:` in frontmatter) — 6 tags assigned: `#ingest`, `#synthesize`, `#recall`, `#prune`, `#snapshot`, `#configure`; `cortex-assimilate` and `cortex-prune` marked as multi-behavior (split candidates). (2026-06-28)

## Phase 2.5 — Batch 2026-06-12 (priority: implement soon)

Decisions derived from ingesting obsidian-mind + @affaan's guides (`wiki/sources/obsidian-mind.md`, `claude-code-shorthand-guide.md`, `claude-code-longform-guide.md`, `agentic-security-shorthand-guide.md`). Strategy: **Claude Code first**; if another agent blocks a step, it stays pending per-agent and is validated empirically with Claude only.

- [x] **"Attempted and failed" section in hot cache template** — added to `MEMORY-FORMAT.md` and `cortex-crystallize/SKILL.md` (alongside What was done / Fragile context). Explicit record of attempted approaches that failed, with evidence. (2026-06-12, CommandCode)
- [x] **Sanitization in `cortex-assimilate`** — `bin/cortex-sanitize.sh` created and step 4a added to the skill. Scans: invisible Unicode, HTML comments, embedded base64, egress commands, `ANTHROPIC_BASE_URL`. Finding → report to user, do not block. (2026-06-12, CommandCode)
- [x] **Imprint pipeline: detection at Stop + triage at SessionStart** — implemented 2026-06-15:
  - [x] Crystallize (Stop): Haiku detects durable synthesis → generates `#### Imprint candidate` bullet + `— transcript: <path>` in the History entry.
  - [x] SessionStart: detects candidate in the most recent History entry, checks expiration (>30 days → ignore), writes `.cortex/imprint-draft.md` with candidate + transcript path, injects nudge.
  - [x] Toggle `imprint_triage: off | suggest | auto` in `~/.cortex-forge/config.yml` (global or per-vault). Backwards compat `true`→`suggest`, `false`→`off`. Default `suggest` in global config.
  - [x] `cortex-imprint/SKILL.md` reads `.cortex/imprint-draft.md` if it exists (step 0) and removes it after reading.
  - [x] **Full `auto` mode** — `bin/hooks/cortex-imprint-auto.sh` created (2026-06-28): invoked from `cortex-reactivate.sh` in background when `imprint_triage: auto`. Reads `.cortex/imprint-draft.md` + transcript → `claude -p` (Haiku) → writes wiki page, updates `wiki/index.md` and `wiki/meta/log.md`, removes draft. Falls back gracefully: skips if page already exists, exits cleanly on missing transcript. `suggest` mode unchanged.
  - Design note: delivery guarantee comes from the **injected channel** (hot cache), not from skill/AGENTS.md wording — flags travel in the same injection that is already reliable. Anything critical enough to survive forever → distill to one line in `Current state`, long detail goes to wiki.
  - Per-agent pending: transcript location in Codex (`~/.codex/sessions/`) and Antigravity (SQLite+Protobuf — no JSONL path); **CommandCode resolved** (2026-06-12): `~/.commandcode/projects/{project-slug}/{session-uuid}.jsonl`, also available via `transcript_path` in hook stdin. Background subagent is a Claude Code capability with no verified equivalent in other agents. Sources: `wiki/sources/commandcode-hooks-reference`, `wiki/sources/commandcode-headless`, real filesystem inspection.

## Phase 3 — Adoptability

- [x] Add license to the public repo
- [x] Hook distribution architecture: `bin/hooks/` (source) → `~/.cortex-forge/bin/hooks/` (runtime) → per-agent symlinks (`~/.claude/hooks/`, `~/.gemini/config/hooks/`, `~/.codex/hooks/`, `~/.commandcode/hooks/`); `/cortex-forge-setup update` to propagate changes; `scripts/` collapsed into `bin/`
- [ ] Onboarding guide: 5 minutes from zero to first ingest
- [x] `install.sh` — curl installer: clones forge, detects vault, links hooks and skills for all detected agents, pipe-safe (2026-06-28)
- [ ] Example pages in `wiki/concepts/` (demonstrate the format, not personal content)
- [ ] `wiki/prompts/` as an optional page type — lets users archive effective agent invocations with sample output; the vault currently stores world knowledge but not operational knowledge about how to work with the agent
- [ ] MOCs per topic area — `wiki/concepts/_index.md`, `wiki/entities/_index.md` as navigable area indexes, complementary to the global index; helps the agent enter via the right MOC instead of loading the full index

## Phase 3.5 — cortex-prune dual mode

Design decision closed in session 2026-06-14, derived from ingesting SkillOpt (Microsoft) and SkillOpt-Sleep.

### `prune-vault` (current mode)
Vault maintenance: orphan pages, broken wikilinks, hot cache staleness. Existing behavior in `cortex-prune`.

### `prune-cortex` (new mode)
System self-optimization: analyzes transcripts where cortex-forge skills failed and proposes targeted edits to the corresponding `SKILL.md` files.

**Why:** cortex-forge currently improves its skills manually, by observation. SkillOpt demonstrates this process is automatable: an optimizer reads successes/failures and proposes add/delete/replace rule edits; a validation gate accepts only edits that improve a held-out set. `prune-cortex` implements this idea within the cortex-forge paradigm, without external dependencies.

**Why Phase 3 is the gate:** the example pages planned in Phase 3 (`wiki/concepts/` with canonical format cases) are exactly the answer key SkillOpt needs as a held-out set. Without those pages, `prune-cortex` can propose edits but cannot validate them objectively — the gate is empty. With them, each example page is a live test: known input → expected output. The gate runs automatically when a skill changes.

**Design consequence:** Phase 3 example pages have a dual function — onboarding for new users + quality infrastructure for `prune-cortex`. This requires keeping them up to date: a stale example produces a noisy gate.

**Skills suitable for `prune-cortex`** (verifiable outputs):
- `cortex-recall` — the citation either exists in the vault or it doesn't
- `cortex-assimilate` — files are created at the correct paths

**Skills not suitable** (subjective outputs, no canonical answer):
- `cortex-crystallize`, `cortex-imprint`

**Implementation in phases:**
- [ ] Phase 3.5a — `prune-cortex` without gate: analyze transcripts, propose edits to `SKILL.md`, user approves. No automatic scoring.
- [ ] Phase 3.5b — validation gate: plug Phase 3 example pages in as held-out set. Accept edits only if the score improves strictly.
- [ ] Phase 3.5c (optional) — integration with SkillOpt-Sleep plugin if the community demands it; the 3.5a/b design is compatible with the SkillOpt loop.

**Reference:** `wiki/concepts/skillopt-text-space-optimization.md`, `wiki/reference/skillopt-cli.md`

## Phase 3.6 — Semantic retrieval (sqlite-vec)

Full design in `CORTEX_FORGE_PLAN.md`. This phase unblocks Phase 4: without vector retrieval, `cortex-recall` cannot scale beyond ~50 pages.

**Stack:** `sqlite-vec` + platform-selected embedding backend. No Ollama or external process required.

**Backend selection (encapsulated in `.cortex/embeddings.py`):**
- Apple Silicon (`Darwin` + `arm64`): `mlx-embeddings` with `mlx-community/nomic-embed-text-v1.5` — faster via Neural Engine; automatic fallback to `sentence-transformers` if mlx is not installed.
- Linux / Windows / Intel Mac: `sentence-transformers` with `nomic-ai/nomic-embed-text-v1.5`, `normalize_embeddings=True`. Universal fallback, no prerequisites.

**Dependencies** (`pyproject.toml`): base `sentence-transformers>=2.7.0` + `sqlite-vec>=0.1.0`; optional `apple-silicon`: `mlx>=0.5.0` + `mlx-embeddings>=0.0.8`.

### Stage 1 — Local vector index

- [x] Create `.cortex/db/embeddings.py` — shared module; Ollama (default), mlx-embeddings (Apple Silicon), and sentence-transformers (fallback) backends; `search_document:`/`search_query:` prefixes for nomic-embed-text-v1.5
- [x] Update `cortex-forge-setup` (skill): detect OS/arch → offer dependency installation with explanation (value + long-term implications) → report which backend is active
- [x] Create `bin/cortex-index.py` — full indexer with heading-based chunking + 500-word/100-overlap sub-chunking; `(path, chunk_index)` index; atomic updates; deleted-file cleanup; automatic threshold calibration (inter-file p75)
- [x] Create `.cortex/db/cortex-search.py` — KNN two-step (vec_documents → documents JOIN by rowid); `--top-k`, `--threshold`, `--json` flags; threshold read from `.cortex/db/config.json`
- [x] Post-commit hook: re-index only `wiki/` files modified in the commit
- [x] Update `cortex-recall/SKILL.md`: if `.cortex/vault.db` exists → invoke `cortex-search.py`; fallback to manual index read
- [x] Add full `.cortex/` directory to `.gitignore` (entire directory, not individual files)
- [ ] Validate in second-brain: initial indexing + test query + incremental indexing after `cortex-assimilate`; verify reported backend matches the platform

### Stage 2 — MCP server (gate: Stage 1 validated + vault used from >1 client)

Do not implement before Stage 1 is validated. See full design in `CORTEX_FORGE_PLAN.md` → "Stage 2" section.

- [ ] Create `.cortex/server.py` with FastMCP — 5 tools: `vault_ingest`, `vault_query`, `vault_imprint`, `session_snapshot`, `vault_prune`
- [ ] Register in the vault's `.claude/settings.json` (stdio transport)
- [ ] Verify clean degradation: vault remains functional without MCP by reading `AGENTS.md` directly

## Phase 4 — Accumulated intelligence

- [ ] `cortex-recall` with cross-page synthesis and contradiction detection
- [ ] Cross-session pattern detection: recurring topics in `.cortex/` that never reach `wiki/` — at crystallize time, review history and propose candidates; pattern validated by Honcho's dialectic reasoning
- [ ] Progressive loading in `cortex-recall` — navigate wiki as a filesystem by relevance instead of loading the full index at startup; reduces token bloat without losing coverage
- [/] **History archive.** Simple layer implemented 2026-06-15: entries >30 days in `MEMORY.md` → `.cortex/CONSOLIDATED.md` (same Markdown format, append-only, not injected at session start). Structured layer pending: when `CONSOLIDATED.md` exceeds N entries, parse to JSON with tags `{ts, agent, trigger, tags: [], files: [], decisions: [], discarded: [], fragile: []}` extracted by crystallize at write time. JSON is not loaded at startup — queryable via `/cortex-recall` or a dedicated skill.
