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

Format: `[semver] — título — YYYY-MM-DD`

---

## [Unreleased]

## [0.6.0] — Hookless Protocol & skills.sh Compatibility — 2026-07-03

Removes agent lifecycle hooks entirely and makes cortex-forge installable via [skills.sh](https://www.skills.sh/) (`npx skills add itsmistermoon/cortex-forge`), independent of the tarball/curl installer. Support for lifecycle hooks was too uneven across Claude Code, Codex, Antigravity, and CommandCode to build the suite on top of them; `AGENTS.md` now mandates one identical manual protocol on every agent instead.

- `protocol:` Agent lifecycle hooks (`SessionStart`, `PreCompact`, `SessionEnd`, `Stop`, `PreToolUse`) removed entirely — support was too uneven across Claude Code, Codex, Antigravity, and CommandCode to build the suite on top of it. `AGENTS.md` now mandates reading `.cortex/MEMORY.md` before the first response and invoking `/cortex-crystallize` manually, identically on every agent. `cortex-forge-setup` and `install.sh` no longer install any hook symlinks or merge `settings.json`/`hooks.json`. `bin/hooks/` reduced to the one script that remains — `cortex-reindex-post-commit.sh`, a git hook, not an agent lifecycle hook. See `wiki/concepts/agent-hook-compatibility.md` for the per-agent findings that drove the decision.
- `protocol:` `cortex-crystallize` — imprint-candidate detection moved from the (now-removed) SessionStart hook chain to a manual check: `AGENTS.md` step 6 instructs the agent to inspect the latest `## History` entry for `#### Imprint candidate` when reading `.cortex/MEMORY.md`.
- `protocol:` Scripts that skills invoke (`cortex-prune.sh`, `cortex-sanitize.sh`, `cortex-index.py`, `cortex-search.py`, `embeddings.py`, `cortex-reindex-post-commit.sh`) moved out of `bin/` to be co-located inside the `skills/<name>/` directory that uses them — so `npx skills add itsmistermoon/cortex-forge --skill X` (skills.sh) installs a fully functional skill without needing `~/.cortex-forge/` (the tarball runtime). `~/.cortex-forge/bin/` is now only a runtime cache, populated at setup time, used exclusively by the two post-commit git hooks (which need a fixed absolute path since they run outside any agent session). `install.sh` updated to match and kept working in parallel — not deprecated. Fixed two latent path bugs found in the process: `cortex-reindex-post-commit.sh` pointed at a nonexistent `{vault}/bin/cortex-index.py`, and `cortex-assimilate` step 7 pointed at `.cortex/cortex-index.py` instead of `.cortex/db/cortex-index.py`.

## [0.5.0] — Backward Enrichment, Drift Detection & Skill Quality Hardening — 2026-07-01

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

## [0.4.0] — Protocol Hardening & Autonomous Imprint — 2026-06-29

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

## [0.3.0] — Multi-vault, cortex-prune global — 2026-06-15

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

## [0.2.0] — CODEX.md, Reference taxonomy, AI Coding Dictionary, handoff improvements — 2026-06-09

- `protocol:` `CODEX.md` — new vault identity file (Mission, Owner, Domains, Vocabulary, Out of scope), read at session start after `.hot/MEMORY.md`. All skills check it for relevance and vocabulary decisions.
- `protocol:` Parametric knowledge explicitly disqualified in `cortex-recall` — vault is always source of truth for vault topics, regardless of training knowledge.
- `schema:` `wiki/reference/` — fifth wiki type for lookup tables, wire formats, and cheat sheets (`templates/reference.md`). Distinct from Concept: scannable, not explanatory.
- `fix:` `cortex-crystallize` PreCompact now uses `claude -p` — previously generated a raw list of file paths with no description. Both PreCompact and SessionEnd synthesize descriptive bullets. Prompts distinguish compaction (mid-session) from handoff (no return path).
- `protocol:` `MEMORY-FORMAT.md` gains trigger table (PreCompact vs SessionEnd), optional `### Suggested skills` section, and `next: <focus>` argument to orient snapshots.
- `protocol:` Templates co-located with their skills: `MEMORY-FORMAT.md`, `CODEX-FORMAT.md`, `TASTE-FORMAT.md`.
- `fix:` `.hot/MEMORY.md` fixed filename — removed project-name detection; one file per repo.
- `protocol:` `AGENT-LOG.md` — append-only session bitácora with minimal template and drift-prevention rules.
- `schema:` `AGENTS.md` architecture table labels `.raw/` as primary sources and `wiki/` as secondary sources, with conflict resolution rule.
- `knowledge:` AI Coding Dictionary ingested (68 entries). New concepts: `parametric-knowledge`, `contextual-knowledge`, `memory-system`, `handoff-artifact`, `smart-zone`.

## [0.1.0] — First usable release — 2026-06-08

- `feat:` 6 skills: `cortex-crystallize`, `cortex-assimilate`, `cortex-recall`, `cortex-imprint`, `cortex-prune`, `cortex-forge-setup`.
- `protocol:` `AGENTS.md` with MANDATORY protocols and verifiable compliance criteria for recall, assimilation, and crystallize.
- `protocol:` Parametric knowledge disqualified as source for vault topics — epistemological rule, not workflow instruction.
- `feat:` Multi-vault support via `~/.cortex-forge/config.yml`. Vault selectable as explicit argument: `/cortex-recall second-brain <query>`.
- `schema:` `CODEX.md` — vault context file (Mission, Owner, Domains, Vocabulary, Out of scope).
- `schema:` `wiki/reference/` — taxonomy type for lookup tables and wire formats.
- `feat:` SPA detection fallback in `cortex-assimilate` — JS bundle inspection + static asset reconstruction.
- `protocol:` Invoke messages per skill (`Crystallizing memory...`, `Recalling memory...`, etc.).
- `feat:` Agent compatibility: Claude Code (full hook support), Codex (SessionStart confirmed), Antigravity (hooks configured), CommandCode (AGENTS.md MANDATORY confirmed).
