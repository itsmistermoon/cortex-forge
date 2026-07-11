---
"cortex-forge": patch
---

Added an explicit `skills` array to `.claude-plugin/plugin.json`, listing each of the 6 skill directories. This is the convention `npx skills` (skills.sh) reads to group a plugin's skills under its `name` when installed and shown via `npx skills ls -g` — without it, the 6 skills would list ungrouped despite coming from one plugin. Matches the pattern used by `mattpocock/skills`. No effect on Claude Code's own plugin loading (the `skills` field adds to, rather than replaces, the default `skills/` directory scan already in effect).
