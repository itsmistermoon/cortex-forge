# cortex-prune — skill changelog

Change history for `skills/cortex-prune/SKILL.md`, moved out of the skill file to keep it lean. Newest first.

---

- 2026-07-05 [Claude Code]: Removed the AGENTS.md ## Vault identity dependency (section eliminated from the suite): dropped the Domains/Out of scope check from step 1
- 2026-07-05 [Claude Code]: Compressed the flavor-line instruction to a single sentence — removed the duplicated position instruction and the "literally" vs "translated" contradiction
- 2026-07-04 [Claude Code]: Centralized vault structure validation (`wiki/`+`AGENTS.md`) in `references/VAULT-RESOLUTION.md`; removed the now-redundant explicit "Confirm vault is a Cortex Forge vault" line from step 1 (confirmation gate left untouched)
- 2026-07-04 [Claude Code]: Reworded "Resolve vault" step intro to point directly at VAULT-RESOLUTION.md's decision flow, removing the vague closing phrase
- 2026-07-04 [Claude Code]: Extracted "Resolve vault" logic to shared `references/VAULT-RESOLUTION.md`, co-located across 5 skills (was duplicated inline with real drift between copies)
- 2026-07-01 [Claude Code]: Added Layer 3 — drift detection: mtime of `.raw/` vs `updated:` in `wiki/sources/`; intro updated from two to three layers
