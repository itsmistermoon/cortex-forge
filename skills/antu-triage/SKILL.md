---
name: antu-triage
license: MIT
description: On-demand .hot/ hygiene — PLAYBOOK.md pruning, foreign-suite pending recovery, and Pending/Active decisions validity re-checks. Use when the user asks to clean up, audit, or triage session state.
argument-hint: ""
---

Start your response with the flavor line `Triaging session state...`, translated to the language of the user's current message (Spanish: `Depurando estado de sesión...`), with nothing before it. Use that same language for every prompt, question, menu, and confirmation this skill produces.

Deep hygiene pass over `.hot/` in the active repo (the nearest `.git`) — judgment-based work that can lag behind the session it concerns, so it runs as its own on-demand pass rather than during a session close.

## Steps

1. **Resolve context** — detect the active repo (nearest `.git` from CWD; ask if none). Read `.hot/HANDOFF.md`, `.hot/PLAYBOOK.md`, and `.hot/HISTORY.md`, whichever exist. If none exist, stop and tell the user there's no session state to triage yet.

2. **PLAYBOOK.md stale-entry pruning** — if `.hot/PLAYBOOK.md` exists, remove dated subsections (`### YYYY-MM-DD`) under `## Working context` older than 15 days, per `references/PLAYBOOK-FORMAT.md` (never touch `## Permanent`). Skip silently if nothing qualifies. **Done when:** every Working-context entry older than 15 days is gone.

3. **Retrospective PLAYBOOK-candidate re-evaluation** — read the full `## History` in `.hot/HISTORY.md` (not just a recent window) and apply the gate in `references/PLAYBOOK-FORMAT.md` across that whole span: did a pattern recur across multiple past sessions — the same workaround reapplied, the same convention rediscovered — that no single session's fresh-context judgment call would have caught? Propose each candidate with the sessions it recurred in as evidence. Never auto-write — always requires confirmation. **Done when:** every recurring pattern found in `## History` has been proposed or explicitly considered and rejected — none silently skipped.

4. **Recover pending/fragile-context after a foreign-suite write** — scan `.hot/HISTORY.md` for whole-block archived entries carrying this courtesy notice: "previous HANDOFF.md was Kuyen's (free text) — archived in full, no pending/decisions recovered automatically". For each, read the archived block and extract anything that reads like an unresolved pending item or context a next session would need. Propose restoring it into `.hot/HANDOFF.md`'s `### Pending`, respecting the 5-item cap in `references/HANDOFF-FORMAT.md`. Never auto-apply; on confirmation, refresh `HANDOFF.md`'s frontmatter (`suite: antu`, `agent:`, `updated:`) per `references/HANDOFF-FORMAT.md` — a stale or missing `suite: antu` marker makes the next `/antu-handoff` treat the file as foreign and archive it whole again. **Done when:** every whole-block archived entry carrying the courtesy notice has been scanned and its recoverable items, if any, proposed — zero matching blocks left unchecked.

5. **Validity re-check on existing Pending/Active decisions** — for each item in `.hot/HANDOFF.md`'s `### Pending` and `### Active decisions`, cross-reference later `## History` entries and current repo state (e.g. does a referenced file/path still exist, does a later entry mention it was resolved) to judge whether it's stale. Propose removing stale items; leave live ones untouched. On confirmation, refresh `HANDOFF.md`'s frontmatter (`suite: antu`, `agent:`, `updated:`) per `references/HANDOFF-FORMAT.md`, same as step 4. **Done when:** every `### Pending` and `### Active decisions` item has been checked against later History and current repo state — none left unevaluated.

6. **Deep HISTORY.md cleanup** — scan for near-duplicate archived blocks (overlapping date range, overlapping "What was done" bullets — likely a rotation artifact or repeated re-statement of the same fact). `HISTORY.md` is append-only per `references/HANDOFF-FORMAT.md` — never edit, merge, or remove an existing block. Propose appending a superseding note instead: `### {today} — antu-triage` / `Supersedes {earlier timestamps}: {one-line summary of what the duplicate blocks actually recorded}`. Never auto-apply. **Done when:** every archived block has been compared against the others for near-duplication — none left unchecked.

7. **Report** all findings from steps 2–6, grouped by step, each with: what was found, proposed action. Ask whether to proceed with each proposal from steps 3–6 — step 2 already ran without asking, since it's a mechanical TTL rule with no judgment call.
