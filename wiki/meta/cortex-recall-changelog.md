# cortex-recall — skill changelog

Change history for `skills/cortex-recall/SKILL.md`, moved out of the skill file to keep it lean. Newest first.

---

- 2026-07-05 [Claude Code]: Synced this skill's `embeddings.py` copy with the fixes made while auditing cortex-assimilate's scripts (they were byte-identical duplicates, no prior drift) — adds `EmbeddingBackendError`, `DIMENSIONS` validation, and a shared `_ollama_post()` helper. Updated `cortex-search.py`'s single `emb.embed_query()` call to catch `EmbeddingBackendError` and exit the same way `embeddings.py` used to internally — no behavior change, just moved the exit point to the caller since embeddings.py no longer exits on its own for a per-call timeout. See cortex-assimilate's changelog for the full rationale

- 2026-07-05 [Claude Code]: Removed the AGENTS.md ## Vault identity dependency (section eliminated from the suite): dropped step 2 (Vocabulary/Domains) and renumbered
- 2026-07-05 [Claude Code]: Compressed the flavor-line instruction to a single sentence — removed the duplicated position instruction and the "literally" vs "translated" contradiction
- 2026-07-04 [Claude Code]: Centralized vault structure validation (`wiki/`+`AGENTS.md`) in `references/VAULT-RESOLUTION.md`, closing a gap where step 2 assumed `AGENTS.md` existed without validating it
- 2026-07-04 [Claude Code]: Reworded "Resolve vault" step intro to point directly at VAULT-RESOLUTION.md's decision flow, removing the vague closing phrase
- 2026-07-04 [Claude Code]: Extracted "Resolve vault" logic to shared `references/VAULT-RESOLUTION.md`, co-located across 5 skills (was duplicated inline with real drift between copies)
