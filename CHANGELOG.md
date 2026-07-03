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

- `protocol:` Eliminated all vault-local code execution. `cortex-recall` was flagged CRITICAL by the same Snyk audit (`E006: Malicious code pattern detected` — "executes arbitrary Python from vault paths ... permits RCE and covert data exfiltration/backdoors if a vault or its scripts are malicious"), because it ran `{vault}/.cortex/db/cortex-search.py` — a script `cortex-forge-setup` had copied into the vault. `cortex-assimilate`'s reindex step (7) had the identical pattern with `cortex-index.py`, unreported by the scanner but the same risk category. Fix: `cortex-search.py`+`embeddings.py` moved into `skills/cortex-recall/`; `cortex-index.py`+`embeddings.py` duplicated into `skills/cortex-assimilate/`; `cortex-forge-setup` no longer copies any of these into `{vault}/.cortex/db/` at all — it runs its own co-located `cortex-index.py` directly for setup, and stages `cortex-index.py`+`embeddings.py` at `~/.cortex-forge/bin/` only for the post-commit git hook (which structurally can't resolve "co-located with caller"). `{vault}/.cortex/db/` now holds only `vault.db` and `config.json` — no vault, however malicious, can plant code that any skill will execute. The intentional duplication (embeddings.py now in 3 skills, cortex-index.py in 2) is guarded by a new `bin/check-skill-sync.sh` invariant (`duplicated-script-sync`) that fails CI if the copies ever diverge — the alternative (a shared `bin/`) was rejected because it's exactly what broke independent `npx skills add --skill X` installs in the first place.
- `fix:` `cortex-sanitize.sh` — added credential detection (API keys `sk-*`, `Bearer *` tokens, `ghp_*`, `?token=*`, AWS `AKIA*` keys, basic-auth `user:pass` in URLs/flags) with **mandatory in-place redaction** — unlike other finding types, credentials are never just reported: the script rewrites the file itself before `cortex-assimilate` ever sees the JSON output, so there's no path (including explicit user insistence) to save the real value to `.raw/`. Found via a Snyk security audit on [skills.sh](https://www.skills.sh/) (`W007: Insecure credential handling`, risk 0.80) — the sanitize step previously only reported injection/exfiltration vectors and let the user override with "proceed anyway." `cortex-assimilate/SKILL.md` step 4a and Rules updated to match; the redaction logic mirrors the pattern already used (text-only, no script) in `cortex-crystallize/SKILL.md`. Two bugs caught while testing the fix: `sk-` pattern didn't allow hyphens (real keys look like `sk-ant-api03-...`), and patterns starting with `-` (`--password`, `-u user:pass`) were silently swallowed as flags by `rg`/`sed` instead of being treated as the search pattern — fixed by passing `--` before the pattern.
- `fix:` `cortex-forge-setup` step 3b (sync from upstream) — `templates/*.md` updates now require one batch confirmation before writing anything, instead of overwriting silently whenever local content differs from upstream. Found via the same Snyk audit (`W012: Unverifiable external dependency`, risk 0.85 for this skill) — a compromised `upstream:` (or a fork pointed at via config) could previously modify local skill templates with no visibility to the user. The confirmation batches all pending file changes into one list + one yes/no, matching the pattern the adjacent "Deletions" sub-step already used.

## [0.6.0] — Hookless Protocol & skills.sh Compatibility — 2026-07-03

Removes agent lifecycle hooks entirely and makes cortex-forge installable via [skills.sh](https://www.skills.sh/) (`npx skills add itsmistermoon/cortex-forge`), independent of the tarball/curl installer. Support for lifecycle hooks was too uneven across Claude Code, Codex, Antigravity, and CommandCode to build the suite on top of them; `AGENTS.md` now mandates one identical manual protocol on every agent instead. A follow-up fail-loud audit closed every silent-failure path this change touched — including a same-day regression the audit caught before it caused real damage.

- `protocol:` Agent lifecycle hooks (`SessionStart`, `PreCompact`, `SessionEnd`, `Stop`, `PreToolUse`) removed entirely — support was too uneven across Claude Code, Codex, Antigravity, and CommandCode to build the suite on top of it. `AGENTS.md` now mandates reading `.cortex/MEMORY.md` before the first response and invoking `/cortex-crystallize` manually, identically on every agent. `cortex-forge-setup` and `install.sh` no longer install any hook symlinks or merge `settings.json`/`hooks.json`. `bin/hooks/` reduced to the one script that remains — `cortex-reindex-post-commit.sh`, a git hook, not an agent lifecycle hook. See `wiki/concepts/agent-hook-compatibility.md` for the per-agent findings that drove the decision.
- `protocol:` `cortex-crystallize` — imprint-candidate detection moved from the (now-removed) SessionStart hook chain to a manual check: `AGENTS.md` step 6 instructs the agent to inspect the latest `## History` entry for `#### Imprint candidate` when reading `.cortex/MEMORY.md`.
- `protocol:` Scripts co-located with the skill that uses them (`cortex-prune.sh`, `cortex-sanitize.sh`, `cortex-validate-schema.sh`, `cortex-index.py`, `cortex-search.py`, `embeddings.py`, `cortex-reindex-post-commit.sh`) instead of living in a shared `bin/` that only the source repo ever had — so `npx skills add itsmistermoon/cortex-forge --skill X` installs a fully self-contained, working skill without depending on `~/.cortex-forge/` (the tarball runtime) at all. `~/.cortex-forge/bin/` is now only a runtime cache, populated at setup time, used exclusively by the two post-commit git hooks (which need a fixed absolute path since they run outside any agent session). `install.sh` kept working in parallel, not deprecated. Fixed two latent path bugs found in the process: `cortex-reindex-post-commit.sh` pointed at a nonexistent `{vault}/bin/cortex-index.py`, and `cortex-assimilate` step 7 pointed at `.cortex/cortex-index.py` instead of `.cortex/db/cortex-index.py`.
- `protocol:` `cortex-forge-setup` step 4 gains a pre-check (4-pre): before symlinking skills from `~/.cortex-forge/skills/` (the tarball runtime), verify all 6 skills are actually present there. If `~/.cortex-forge/skills/` is missing or incomplete, tell the user instead of silently creating broken symlinks — recommend `npx skills add itsmistermoon/cortex-forge --all -g -y` (doesn't depend on the tarball runtime at all) as the primary fix, with re-running the curl installer as the alternative.
- `fix:` Fail-loud audit across every script (`cortex-prune.sh`, `cortex-validate-schema.sh`, `cortex-sanitize.sh`, `embeddings.py`, `cortex-reindex-post-commit.sh`, `install.sh`, `cortex-embed.sh`, `check-skill-sync.sh`) — closes silent-failure paths found by reviewing each for unbounded waits, unchecked `mktemp`, and broken path references:
  - **Regression caught same-day:** the script co-location above moved `cortex-prune.sh` to `skills/cortex-prune/` but left `cortex-validate-schema.sh` behind in `bin/`, silently disabling schema-drift checks for every install. Co-located now; `check-skill-sync.sh` gained a new invariant (`colocated-script-exists`, later hardened to only match backtick-quoted filenames after it flagged a false positive on its own prose) that fails CI if any skill claims a co-located script that isn't actually present, specifically to catch this class of bug before it ships again.
  - `embeddings.py`: the real Ollama embed call had no timeout (only the 3s backend-detection ping did) — a stalled Ollama server could hang indexing/search indefinitely with no error. Added a 30s timeout with a clear message.
  - `cortex-reindex-post-commit.sh`: wrapped the backgrounded reindex in `timeout 300` (falls back to `gtimeout`, or runs unwrapped if neither exists — macOS ships no `timeout` by default) so a hang doesn't accumulate orphan processes across commits; timeouts are now distinguished from other errors in the log.
  - `cortex-prune.sh`: `mktemp` failures now abort loudly instead of writing to an empty path; the final exit-code computation no longer silently reports "no findings" (exit 0) if the findings file becomes unreadable mid-run.
  - `cortex-sanitize.sh`: added a `jq` availability check alongside the existing `rg` check — previously, a missing `jq` produced empty/invalid JSON output that `cortex-assimilate` could misread as "no findings."
  - `install.sh`: added `--max-time` to all `curl` calls (previously unbounded); `git pull --ff-only` against a local dev forge checkout now checks for uncommitted changes first and fails with an actionable message instead of a cryptic git error.
  - **Atomicity (follow-up pass):** `cortex-prune.sh`'s `vault-report.json` and `install.sh`'s `config.yml` writes went directly to the final path — a kill/crash mid-write could leave `vault-report.json` truncated, or worse, zero out `config.yml` (losing every registered vault). Both now write to a temp file in the same directory and `mv` atomically into place. Verified with a simulated config.yml update (existing entries survive) and a vault path containing spaces.
  - **Investigated, not changed:** paths with spaces (tested clean across `cortex-prune.sh`, `cortex-index.py`, `cortex-sanitize.sh`, `cortex-embed.sh`'s hand-rolled YAML lookup); sqlite concurrent-write handling (Python's 5s default `busy_timeout` plus a visible traceback on failure is adequate for this single-user usage pattern); unbounded `.git/cortex-*.log` growth (8KB after months of real use — not a practical risk). Manual YAML parsing in 4 scripts remains fragile against non-standard `config.yml` formatting, but adopting a real parser was judged not worth the added dependency (no native YAML in Python's stdlib, no clean option from bash) given `config.yml`'s schema is small and machine-generated.
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
