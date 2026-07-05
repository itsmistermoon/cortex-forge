# cortex-assimilate — skill changelog

Change history for `skills/cortex-assimilate/SKILL.md`, moved out of the skill file to keep it lean. Newest first.

---

- 2026-07-05 [Claude Code]: Reworded step 1's vault/locale sentence to match cortex-crystallize's phrasing ("per VAULT-RESOLUTION.md, then its locale: per...") for consistency across the suite; dropped the no-op "(argument → CWD → default)" parenthetical, already fully covered by VAULT-RESOLUTION.md's own fallback chain; folded the vault-name-match bullet inline
- 2026-07-05 [Claude Code]: --research mode now saves every scraped source to .raw/ through the same SPA/sanitization checks as a normal run (was: Firecrawl wrote to .firecrawl/, plain WebFetch skipped .raw/ entirely), and its final step now runs steps 3–7 of the normal pipeline instead of 3–5 — project linking and backward enrichment no longer skipped for research-sourced pages
- 2026-07-05 [Claude Code]: Removed the AGENTS.md ## Vault identity dependency (section eliminated from the suite): dropped step 2 (Domains/Out of scope/Mission/Vocabulary) and renumbered; locale fallback no longer checks AGENTS.md
- 2026-07-05 [Claude Code]: Merged Types/paths table, type disambiguation, and per-type criteria into a single ## Page types section; moved the always-create-source rule from Rules into the Source bullet; removed the phantom "reference" type from step 4
- 2026-07-04 [Claude Code]: Centralized vault structure validation (`wiki/`+`AGENTS.md`) in `references/VAULT-RESOLUTION.md`; removed the redundant "if `{vault}/AGENTS.md` exists" guard from step 2
- 2026-07-04 [Claude Code]: Reworded "Resolve vault" step intro to distinguish VAULT-RESOLUTION.md (decision flow) from LOCALE-RESOLUTION.md (fallback chain), removing the repeated closing phrase
- 2026-07-04 [Claude Code]: Extracted "Resolve vault" logic to shared `references/VAULT-RESOLUTION.md`, co-located across 5 skills (was duplicated inline with real drift between copies)
- 2026-07-01 [Claude Code]: Added Step 9 — backward enrichment: tag-based scan of existing pages after ingest, inline ENRICHABLE/FALSE_POSITIVE classification, confirmation required before any change
- 2026-06-24 [Claude Code]: Reformulated "compiled truth" rule into a verifiable rewrite contract with a concrete violation signal (no-op audit)
