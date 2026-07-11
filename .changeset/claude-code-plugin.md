---
"cortex-forge": minor
---

Packaged the skill suite as a self-hosted Claude Code plugin marketplace (`.claude-plugin/plugin.json` + `marketplace.json`), installable with `/plugin marketplace add itsmistermoon/cortex-forge` and `/plugin install cortex-forge@cortex-forge`, alongside the existing `npx skills add` distribution. `bin/check-skill-sync.sh` (a repo-internal CI check, not an end-user tool) moved to `scripts/check-skill-sync.sh` so the plugin's `bin/` — added to the user's `PATH` when the plugin is enabled — only exposes `cortex-embed.sh`, `setup-vault.sh`, and `tags-audit.py`.
