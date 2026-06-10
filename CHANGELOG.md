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
