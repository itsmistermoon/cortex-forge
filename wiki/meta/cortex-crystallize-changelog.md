# cortex-crystallize — skill changelog

Change history for `skills/cortex-crystallize/SKILL.md`, moved out of the skill file to keep it lean. Newest first.

---

- 2026-07-05 [Claude Code]: Locale fallback (references/LOCALE-RESOLUTION.md) no longer checks the AGENTS.md Vault identity section — section eliminated from the suite
- 2026-07-05 [Claude Code]: Compressed the flavor-line instruction to a single sentence — removed the duplicated position instruction and the "literally" vs "translated" contradiction
- 2026-07-04 [Claude Code]: Added process-tree walk (`$PPID` upward via `ps -o comm=`) as a fallback method for detecting the invoking agent in step 1a when self-knowledge and env vars aren't enough — rescued from a finding in `wiki/meta/agent-diagnostics.md` (2026-06-11) about CommandCode, which exposes no self-identifying environment variable
- 2026-07-04 [Claude Code]: Added step 6b (vault health triage) that propagates findings from `vault-report.json` to `### Pending` on every crystallize, closing a gap where nobody recorded whether the vault health triage (AGENTS.md step 3) was actually addressed
- 2026-07-04 [Claude Code]: Centralized vault structure validation (`wiki/`+`AGENTS.md`) in `references/VAULT-RESOLUTION.md`; the standard-vs-cross-vault mode detection in step 3 is unrelated routing logic and was left untouched
- 2026-07-04 [Claude Code]: Reworded "Resolve vault" step intro to distinguish VAULT-RESOLUTION.md (decision flow) from LOCALE-RESOLUTION.md (fallback chain), removing the repeated closing phrase
- 2026-07-04 [Claude Code]: Added an explicit "safe to end" verdict to the output format, inspired by a comparative analysis with the `stow` skill (from another repo), so malformed frontmatter or unresolved context doesn't stay buried only in History
- 2026-07-04 [Claude Code]: Extracted "Resolve vault" logic to shared `references/VAULT-RESOLUTION.md`, co-located across 5 skills (was duplicated inline with real drift between copies)
- 2026-07-04 [Claude Code]: Added a third "genuinely ambiguous" case to the step 6a PRAXIS.md gate — ask the user once instead of guessing, inspired by a comparative analysis with the `stow` skill; also removed a parenthetical historical-context phrase ("confidence, not category, decides") from the same gate
