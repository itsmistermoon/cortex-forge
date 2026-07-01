# Changelog

Protocol-significant changes to cortex-forge are documented here.

**What counts as protocol-significant:**
- Changes to `AGENTS.md` compliance criteria or session startup sequence
- Changes to skill contracts (input, output, steps, compliance criteria)
- Changes to template frontmatter schema
- Changes to `vault-report.json` schema
- New files added to `bin/` or `docs/` that alter vault operation
- Changes to `~/.cortex-forge/config.yml` structure

**What does not count:** rewording, typos, README prose, cosmetic changes.

Format: `[semver] — YYYY-MM-DD`

---

## [Unreleased]

## [0.5.0] — 2026-07-01

- `fix:` `27d1164` `cortex-prune` Layer 2: hard cap (20 pairs, 20 sources); replace "spawn subagents" language with always-inline evaluation.
- `fix:` `b613627` `bin/cortex-prune.sh`: `sources:` YAML frontmatter now counts as a valid reference — pages linked via `sources:` are no longer reported as orphans.
- `protocol:` `4273eee` Skill suite quality audit: no-op audit criteria made concrete and verifiable across all 6 skills; `cortex-crystallize` PRAXIS-FORMAT updated.
- `schema:` `43605e6` Vault taxonomy consolidated to 4 canonical types: `source`, `concept`, `entity`, `project`. Type `reference` deprecated; existing pages migrated to `concept`.
- `feat:` `3c3d63e` `bin/cortex-validate-schema.sh`: support for `type: series` in `wiki/pages/`.
- `protocol:` `99dccc5` Locale resolution extracted to `skills/LOCALE-RESOLUTION.md` — single source of truth replacing 5 inline duplicate blocks. `cortex-crystallize` description enriched with session-close trigger phrases.
- `protocol:` `d3f6b2e` Writing-great-skills audit: `cortex-assimilate` step 5 gains checkable completion criterion; `cortex-imprint` gains `disable-model-invocation: true`; `cortex-forge-setup` step 6d extracted to `EMBEDDING-SETUP.md` via context pointer; duplication and sediment removed across 5 skills.
- `protocol:` `7c8afe5` `cortex-assimilate` gains Step 9 — Backward enrichment: scan existing wiki pages for tag overlap after ingestion; propose additions per candidate with confirmation required.
- `protocol:` `7c8afe5` `cortex-prune` gains Layer 3 — Drift detection: compare `.raw/` mtime against `updated:` in `wiki/sources/`; MEDIUM finding when `.raw/` is newer.
- `schema:` `7c8afe5` Slash-tag convention (`project/subtopic`) adopted in all vault `AGENTS.md` files and templates; applied retroactively to 11 cortex-forge wiki pages.

## [0.4.0] — 2026-06-29

- `breaking:` `.hot/` → `.cortex/` consolidation. All mutable state (`MEMORY.md`, `PRAXIS.md`, `imprint-draft.md`, `db/`) now under `.cortex/`. Existing vaults: rename `.hot/` to `.cortex/` or re-run `/cortex-forge-setup`.
- `protocol:` `cortex-imprint` autonomous mode (`imprint_triage: auto`): `bin/hooks/cortex-imprint-auto.sh` runs at SessionStart (background), reads `.cortex/imprint-draft.md` + transcript, calls `claude -p` (Haiku), writes wiki page, updates index and log, removes draft. Never blocks session start.
- `protocol:` Hook distribution architecture: `bin/hooks/` (git-tracked source) → `~/.cortex-forge/bin/hooks/` (runtime) → symlinks in `~/.claude/`, `~/.gemini/`, `~/.codex/`. `/cortex-forge-setup update` propagates all changes.
- `protocol:` `.cortex/PRAXIS.md` — permanent agent context split from `MEMORY.md`. `CODEX.md` absorbed into `AGENTS.md` under `## Vault identity`. `CONSOLIDATED.md` fallback added for history archive.
- `feat:` Multi-vault: `~/.cortex-forge/config.yml` with `vaults: {name: path}` + `default:`. Vault resolved by CWD then default. `/cortex-forge-setup` registers/deregisters by CWD. Legacy `vault:` key supported.
- `feat:` Stale cache detection: `hot_cache_stale_days:` in `config.yml`; `cortex-reactivate.sh` injects warning at session start if `.cortex/MEMORY.md` exceeds threshold.
- `protocol:` Context fencing in `cortex-imprint`: source hierarchy session > `.raw/` > `wiki/`. `raw:` field added to provenance.
- `feat:` `behavior:` frontmatter tags on all skills: `#ingest`, `#synthesize`, `#recall`, `#prune`, `#snapshot`, `#configure`.
- `feat:` `cortex-prune.sh` link-count scan — orphan page detection; `orphan_pages` added to `vault-report.json`.
- `fix:` `cortex-recall` blocks Explore as bypass; accounts for optional embedding index; fallback behavior clarified.
- `feat:` Semantic search backend stable: `bin/embeddings.py` (Ollama → mlx → sentence-transformers), `bin/cortex-index.py`, `bin/cortex-search.py`. Auto-reindex on assimilate + post-commit hook.
- `fix:` Antigravity crystallize hook removed — `agy -p` deadlocks from hook; no `/exit` trigger. Crystallize in Antigravity is manual-only.
- `fix:` Multiple path corrections for `cortex-sanitize.sh`, `cortex-prune` executable, and hooks after `.cortex/` migration.

## [0.3.0] — 2026-06-15

- `schema:` `AGENTS.md` gains YAML frontmatter with `schema_version: "0.3"`. All six templates (`concept`, `entity`, `project`, `reference`, `source`, `wiki-page`) gain `schema_version: "0.3"` in their frontmatter. Pages with an older `schema_version` (or none) may be missing fields introduced after their creation — detectable by `cortex-prune`.
- `protocol:` Pipeline imprint implemented end-to-end: `cortex-crystallize-claude.sh` detects durable insights via Haiku and emits `#### Imprint candidate` with `— transcript: <path>` in History. `cortex-reactivate.sh` (SessionStart) detects the candidate in the most recent History entry, checks 30-day expiry, writes `.hot/imprint-draft.md`, and injects a nudge. Toggle `imprint_triage: off | suggest | auto` in `~/.cortex-forge/config.yml` (global or per-vault; backwards compat `true`→`suggest`, `false`→`off`; default `suggest`). `cortex-imprint/SKILL.md` gains step 0: read and delete `.hot/imprint-draft.md` if present.
- `protocol:` History archival: `cortex-crystallize-claude.sh` moves History entries older than 30 days from `.hot/MEMORY.md` to `.hot/CONSOLIDATED.md` (append-only, not injected at session start) on every crystallize run.
- `feat:` `bin/hooks/cortex-recall-nudge.sh` — PreToolUse nudge (Bash matcher, Claude Code only, v1) that injects a `/cortex-recall` reminder when a search command targets `wiki/` or `.raw/` inside a registered vault. Once per session, fail-open on every branch, inert outside vaults. Installed via `cortex-forge-setup` step 6a into the vault's `.claude/settings.local.json`. Ports to other agents gated on the AGENT-LOG behavior experiment (backlog #2, Item 1).
- `protocol:` `cortex-forge-setup` gains steps 6a (recall nudge, Claude Code only) and 6b (opt-in post-commit hook refreshing `vault-report.json`, marked block, backgrounded, summary line to `.git/cortex-prune.log`) — backlog #2, Item 2.
- `protocol:` `skills/cortex-crystallize/MEMORY-FORMAT.md` and `SKILL.md` gain `#### Attempted and failed` section in the History template — records approaches that failed, with evidence, to prevent retrying dead ends (Fase 2.5, Item 1).
- `feat:` `bin/cortex-sanitize.sh` — sanitization scan for injection/exfiltration vectors (invisible Unicode, HTML comments, embedded base64, egress commands, `ANTHROPIC_BASE_URL`). `skills/cortex-assimilate/SKILL.md` gains step 4a: before saving to `.raw/`, scans content and reports findings to the user. Findings don't block — they inform (Fase 2.5, Item 2).
- `protocol:` `cortex-recall` output contract appends `[confidence: {value}]` to every citation — `unset` and `read-error` are flagged as findings; `medium`/`low` are valid states. `AGENTS.md` Recall compliance criterion updated to match.
- `schema:` `wiki/meta/vault-report.json` canonical minimal schema defined in `cortex-prune` step 4a (`generated` + `health.dead_links` / `health.raw_without_source_page` / `health.missing_confidence`). Written on every prune run, read at session start per `AGENTS.md` startup step 3, gitignored.
- `protocol:` `AGENTS.md` session startup sequence gains step 3: read `vault-report.json` and surface non-empty `dead_links` / `raw_without_source_page`.
- `feat:` `docs/obsidian-visualization.md` — `wiki/` documented as a native Obsidian vault; linked from `README.md` § Visualization.
- `docs:` platform compatibility table and commit convention added to `README.md`.
- `protocol:` `vault-report.json` is now written directly by `bin/cortex-prune.sh` (Layer 1) — single writer, structured output, no stdout parsing. `cortex-prune` step 4a verifies the file instead of writing it.
- `schema:` `templates/source.md` frontmatter aligned with the convention every existing source page uses and `bin/cortex-prune.sh` verifies: `source:` / `slug:` / `section:` / `fetched:` / `raw:` replace `source_url:` / `source_date:` / `source_author:` / `created:` / `updated:`. `raw:` is the page's context pointer to its `.raw/` primary.

## [0.2.0] — 2026-06-09

See full release notes: https://github.com/itsmistermoon/cortex-forge/releases/tag/v0.2.0

**Summary:**
- Fixed PreCompact mechanical branch in `cortex-crystallize`
- `.hot/MEMORY.md` fixed filename (no project name detection)
- Added `reference.md` to wiki taxonomy
- Created `CODEX.md` for vault context
- Architecture expanded to six layers with primary/secondary source conflict rule
- Parametric knowledge explicitly disqualified in Recall protocol

## [0.1.0] — 2026-06-08

See full release notes: https://github.com/itsmistermoon/cortex-forge/releases/tag/v0.1.0

**Summary:**
- Initial release of the 6 skills and 3 mandatory protocols
- Five-layer vault architecture (later expanded to six)
- Global skills path and multi-vault registry via `~/.cortex-forge/config.yml`
