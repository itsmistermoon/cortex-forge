---
name: antu-triage
license: MIT
description: On-demand .hot/ hygiene — retrospective PLAYBOOK.md pruning, recovering pending/fragile-context items after a foreign-suite write, and validity re-checks on existing Pending/Active decisions. Use when the user asks to clean up, audit, or triage session state, or after antu-handoff suggests it.
---

Start your response with the flavor line `Triaging session state...`, translated to the language of the user's current message (Spanish: `Depurando estado de sesión...`), with nothing before it. Use that same language for every prompt, question, menu, and confirmation this skill produces.

Deep hygiene pass over `.hot/` in the active repo (the nearest `.git`) — the heavier, judgment-based counterpart to `antu-handoff`'s per-session mechanics. Mirrors the `antu-prune` pattern: a separate, on-demand skill rather than folded into the skill that runs every session close.

## Steps

1. **Resolve context** — detect the active repo (nearest `.git` from CWD; ask if none). Read `.hot/HANDOFF.md`, `.hot/PLAYBOOK.md`, and `.hot/HISTORY.md`, whichever exist. If none exist, stop and tell the user there's no session state to triage yet.

2. **PLAYBOOK.md stale-entry pruning** — if `.hot/PLAYBOOK.md` exists, remove dated subsections (`### YYYY-MM-DD`) under `## Working context` older than 15 days, per `references/PLAYBOOK-FORMAT.md` (never touch `## Permanent`). Skip silently if nothing qualifies. **Done when:** every Working-context entry older than 15 days is gone.

3. **Retrospective PLAYBOOK-candidate re-evaluation** — read the full `## History` in `.hot/HISTORY.md` (not just a recent window) and apply the gate in `references/PLAYBOOK-FORMAT.md` across that whole span: did a pattern recur across multiple past sessions — the same workaround reapplied, the same convention rediscovered — that no single session's fresh-context judgment call (the one `antu-handoff` makes per-session) would have caught? Propose each candidate with the sessions it recurred in as evidence. Never auto-write — always requires confirmation.

4. **Recover pending/fragile-context after a foreign-suite write** — scan `.hot/HISTORY.md` for whole-block archived entries carrying the cross-suite courtesy notice (`antu-handoff` writes this when it finds `suite: kuyen` or no marker: "previous HANDOFF.md was Kuyen's (free text) — archived in full, no pending/decisions recovered automatically"). For each, read the archived block and extract anything that reads like an unresolved pending item or context a next session would need. Propose restoring it into `.hot/HANDOFF.md`'s `### Pending`, respecting the 5-item cap in `references/HANDOFF-FORMAT.md`. Never auto-apply.

5. **Validity re-check on existing Pending/Active decisions** — for each item in `.hot/HANDOFF.md`'s `### Pending` and `### Active decisions`, cross-reference later `## History` entries and current repo state (e.g. does a referenced file/path still exist, does a later entry mention it was resolved) to judge whether it's stale. Propose removing stale items; leave live ones untouched.

6. **Deep HISTORY.md cleanup** — scan for near-duplicate archived blocks (overlapping date range, overlapping "What was done" bullets — likely a rotation artifact or repeated re-statement of the same fact). Propose consolidating each pair into one entry. Never auto-apply — merging history is lossy.

7. **Report** all findings from steps 2–6, grouped by step, each with: what was found, proposed action. Ask whether to proceed with each requires-confirmation item below.

## Auto-correctable (no confirmation needed)

- PLAYBOOK.md `## Working context` entries older than 15 days (step 2) — mechanical TTL rule, no judgment once the date threshold is crossed

## Requires confirmation (never auto-apply)

- Promote or add a `## Permanent` PLAYBOOK.md entry (step 3)
- Restore a recovered pending/fragile-context item into `HANDOFF.md` (step 4)
- Remove a stale `### Pending` or `### Active decisions` entry (step 5)
- Consolidate near-duplicate `HISTORY.md` blocks (step 6)

## Trigger

Purely on-demand — never auto-invoked. `antu-handoff` nudges toward this skill via a `### Pending` suggestion in two cases: it just archived a whole `HANDOFF.md` block due to a foreign-suite marker mismatch, or PLAYBOOK.md pruning is more than ~30 days overdue. Outside those two cases, the user reaches for this skill explicitly.
