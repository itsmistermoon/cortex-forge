---
"antu": minor
---

Add `antu-triage`, a 7th Antu skill for on-demand `.hot/` hygiene: retrospective `PLAYBOOK.md` pruning across past sessions, recovering pending/fragile-context items buried in `HISTORY.md` after a foreign-suite (Kuyen) write, and validity re-checks on existing `### Pending`/`### Active decisions` entries. Mirrors `antu-prune`'s pattern — separate, on-demand skill rather than folded into `antu-handoff`. As part of the responsibility split, `PLAYBOOK.md`'s 15-day Working-context pruning moves out of `antu-handoff` into `antu-triage`, and `antu-handoff` now nudges toward `antu-triage` via a `### Pending` suggestion when it archives a whole foreign-suite `HANDOFF.md` block, or when PLAYBOOK pruning is more than 30 days overdue.
