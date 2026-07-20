---
"almagest-antu": minor
---

Define the minimal vault AGENTS.md and wire handoff auto-loading into every repo:

- New `templates/AGENTS-vault.md` — the canonical minimal AGENTS.md for vaults (session-start block, vault working rules, "Vault identity" placeholder). `wiki-setup`'s scaffold now copies from it instead of improvising, and never mirrors the suite repo's production AGENTS.md.
- New shared reference `references/SESSION-START-BLOCK.md` — canonical text + detection/append rules for the `<!-- antu:session-start -->` block that makes agents read `.hot/HANDOFF.md` at session start.
- `wiki-setup`: existing AGENTS.md without the marker gets a confirmation-gated append-only offer of the Antu block (new-vault flow and maintenance menu option 11).
- `hot-handoff`: on the first handoff in a repo (when `.hot/` is created), offers once to add the session-start instruction to AGENTS.md — works in any repo, vault or not.
- `hot-triage`: new step checks that repos with a `HANDOFF.md` also have the session-start instruction, proposing the append as backfill.
- Fixed deprecated vocabulary in the repo's own `AGENTS.md` (Principle 5, skill-design-principles): "skills trigger themselves" → user-invoked wording (skills are `disable-model-invocation: true`), and a stale `/cortex-recall` invocation → `/wiki-query`.
