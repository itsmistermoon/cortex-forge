# Context

Domain vocabulary for this repo and its sibling suite (Kuyen, `moon-kuyen`). See `docs/adr/` for the decisions behind these terms.

## Glossary

- **`.hot/`** — the per-vault session-state directory, shared by Antu and Kuyen. Named for its role (a fast, always-loaded cache), not for any single file or skill inside it. Never committed to git.
- **`HANDOFF.md`** — the current session snapshot inside `.hot/`, written by `/antu-handoff` or `/kuyen-handoff`. Replaces the old `MEMORY.md` name.
- **`HISTORY.md`** — the append-only archive inside `.hot/` that past `HANDOFF.md` content rotates or dumps into. Replaces the old `CONSOLIDATED.md` name.
- **`PLAYBOOK.md`** — Antu-only durable operational knowledge (workarounds, conventions, recurring failure patterns) inside `.hot/`, distinct from the session-scoped `HANDOFF.md`. Kuyen has no equivalent and never touches this file. Replaces the old `PRAXIS.md` name.
- **`suite:` marker** — a single frontmatter key (`suite: antu` / `suite: kuyen`) at the top of `HANDOFF.md`, identifying which suite wrote it last. Lets either skill detect foreign-format content without parsing the rest of the file.
- **`antu-triage`** — Antu-only, on-demand skill for `.hot/` hygiene: recovering pending/fragile-context items buried in `HISTORY.md` after a cross-suite write, re-evaluating `### Pending`/`### Active decisions` validity, retrospective `PLAYBOOK.md` candidate review, and deeper `HISTORY.md` cleanup. Mirrors `antu-prune`'s pattern (separate hygiene skill vs. folding into a skill that runs every session). No Kuyen equivalent.
