---
"antu": patch
---

Rename all 7 skills from the suite-brand prefix to a memory-domain prefix (ADR 0003): `antu-handoff` → `hot-handoff`, `antu-triage` → `hot-triage`, `antu-ingest` → `wiki-ingest`, `antu-recall` → `wiki-recall`, `antu-imprint` → `wiki-imprint`, `antu-prune` → `wiki-prune`, `antu-setup` → `wiki-setup`. Hard cut, no aliases. `~/.cortex-forge/config.yml`'s `hot_cache_stale_days` key renamed to `playbook_stale_days`, migrated in place by `wiki-setup` on next run.
