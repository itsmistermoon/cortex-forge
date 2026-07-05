# cortex-imprint — skill changelog

Change history for `skills/cortex-imprint/SKILL.md`, moved out of the skill file to keep it lean. Newest first.

---

- 2026-07-05 [Claude Code]: Removed the AGENTS.md ## Vault identity dependency (section eliminated from the suite): dropped step 2 and renumbered — the Provenance "(step 5)" reference is accurate again; locale fallback no longer checks AGENTS.md
- 2026-07-05 [Claude Code]: Compressed the flavor-line instruction to a single sentence — removed the duplicated position instruction and the "literally" vs "translated" contradiction
- 2026-07-04 [Claude Code]: Centralized vault structure validation (`wiki/`+`AGENTS.md`) in `references/VAULT-RESOLUTION.md`, closing a gap where step 2 assumed `AGENTS.md` existed without validating it
- 2026-07-04 [Claude Code]: Reworded "Resolve vault" step intro to distinguish VAULT-RESOLUTION.md (decision flow) from LOCALE-RESOLUTION.md (fallback chain), removing the repeated closing phrase
- 2026-07-04 [Claude Code]: Extracted "Resolve vault" logic to shared `references/VAULT-RESOLUTION.md`, co-located across 5 skills (was duplicated inline with real drift between copies)
- 2026-07-04 [Claude Code]: Removed dead step 0 (pending draft check) — `.cortex/imprint-draft.md` was never created by any process; it was a vestige of a superseded design
- 2026-06-28 [Claude Code]: Context fencing — added source hierarchy section, circular synthesis test, source fencing rule, and `raw:` provenance field; updated step 2 (CODEX.md → AGENTS.md vault identity) and step 3 (references source hierarchy)
- 2026-06-24 [Claude Code]: Reformulated vague Rules into verifiable criteria (no-op audit — "durable page" → 4 testable conditions; "compiled truth" → explicit rewrite contract)
