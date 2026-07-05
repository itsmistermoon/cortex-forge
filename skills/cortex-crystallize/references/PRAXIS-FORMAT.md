# PRAXIS.md — format reference

File: `.cortex/PRAXIS.md` in the active repo root.
Gitignored — local agent artifact, not versioned content.

---

## When to write

The agent decides when something deserves to go into PRAXIS. It is not an automatic log — it is a deliberate decision.

- **`## Permanent`** — structural conventions, architecture invariants, confirmed technical workarounds. No TTL. Write here if the next agent, 6 months from now, needs to know this to avoid breaking something.
- **`## Working context`** — active context with a date. Automatically pruned by `/cortex-crystallize` when older than 30 days.

---

## Zone 1 — Permanent (NO TTL)

Structural conventions, architecture invariants, and confirmed technical workarounds. No TTL — an entry stays until the convention it describes no longer applies.

```markdown
---
schema_version: "0.1"
updated: YYYY-MM-DD
---

# PRAXIS — {vault-name}

## Permanent

- **{convention}** — {concise description of why it exists and what breaks if violated}
- **{workaround}** — {unexpected behavior, cause, fix applied, date confirmed: YYYY-MM-DD}
```

---

## Zone 2 — Working context (30-DAY TTL)

Active context with a date. Automatically pruned by `/cortex-crystallize` when older than 30 days.

```markdown
## Working context

### YYYY-MM-DD
- {active context entry — removed when older than 30 days}
```

---

## Rules

- **`## Permanent`**: has no TTL, but can be removed if the convention no longer applies. Whoever deletes, explains.
- **`## Working context`**: each block under `### YYYY-MM-DD` is removed by `/cortex-crystallize` when `today - date > 30 days`. The agent does not ask — it prunes automatically.
- **Not a session log**: neither section is a session log — that is what `MEMORY.md` is for. PRAXIS captures learning that outlasts the session.
