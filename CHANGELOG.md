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

- `feat:` `bin/hooks/cortex-recall-nudge.sh` — PreToolUse nudge (Bash matcher, Claude Code only, v1) that injects a `/cortex-recall` reminder when a search command targets `wiki/` or `.raw/` inside a registered vault. Once per session, fail-open on every branch, inert outside vaults. Installed via `cortex-forge-setup` step 6a into the vault's `.claude/settings.local.json`. Ports to other agents gated on the AGENT-LOG behavior experiment (backlog #2, Item 1).
- `protocol:` `cortex-forge-setup` gains steps 6a (recall nudge, Claude Code only) and 6b (opt-in post-commit hook refreshing `vault-report.json`, marked block, backgrounded, summary line to `.git/cortex-prune.log`) — backlog #2, Item 2.

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
