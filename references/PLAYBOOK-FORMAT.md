# PLAYBOOK.md — format reference

File: `.hot/PLAYBOOK.md` in the active repo root.
Gitignored — local agent artifact, not versioned content.

---

## Zone 1 — Permanent (NO TTL)

Structural conventions, architecture invariants, and confirmed technical workarounds. No TTL — an entry stays until the convention it describes no longer applies.

Write here when the user stated it explicitly as a standing rule, or it already appears once in `## Working context` from a prior session and has now held true again — promote it: remove the old entry, never keep the same fact in both zones.

```markdown
---
schema_version: "0.1"
updated: YYYY-MM-DD
---

# PLAYBOOK — {vault-name}

## Permanent

- **{convention}** — {concise description of why it exists and what breaks if violated}
- **{workaround}** — {unexpected behavior, cause, fix applied, date confirmed: YYYY-MM-DD}
```

---

## Zone 2 — Working context (15-DAY TTL)

Active context with a date. Pruned by `/hot-triage` when older than 15 days.

Write here for a single-session observation not yet confirmed: an untested workaround, a first-seen failure pattern, an inferred convention. If genuinely ambiguous whether it belongs in Permanent instead, ask once: "This looks like it might be a standing convention — write it to Permanent, or keep it as working context for now?" Default here unless the user approves Permanent.

```markdown
## Working context

### YYYY-MM-DD
- {active context entry — removed when older than 15 days}
```

---

## Rules

- **`## Permanent`** — can be removed if the convention no longer applies; whoever deletes, explains.
- **`## Working context`** — pruning is automatic, the agent does not ask.
- **Not a session log**: neither section is a session log — that is what `HANDOFF.md` is for. PLAYBOOK captures learning that outlasts the session.
