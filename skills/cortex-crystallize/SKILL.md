---
name: cortex-crystallize
license: MIT
description: Snapshot session context into .cortex/MEMORY.md — pending tasks, decisions, and history — so future sessions resume without losing context. Use on "save context", "crystallize", or "wrap up".
argument-hint: "[vault-name] [project-name] [next: <focus>]"
---

Start your response with the flavor line `Crystallizing memory...`, translated to the language of the user's current message (Spanish: `Cristalizando memoria...`), with nothing before it. Use that same language for every prompt, question, menu, and confirmation this skill produces — persisted vault content (if any) still follows the vault's locale, not the conversation language.

Save a session snapshot to `.cortex/MEMORY.md` in the active repo (the nearest `.git`), so any agent can resume without losing context.

## Steps

1. **Resolve context** — detect the active repo (nearest `.git` from CWD; ask if none) and the invoking agent: identify via self-knowledge first, corroborate with agent-identifying `env` vars if present (don't rely on a fixed hardcoded list — new agents appear continuously), and if still undetermined walk the process tree from `$PPID` upward (`ps -o comm= -p <pid>`) for a known CLI binary name. Append the model in parentheses if known (e.g. `{agent-name} ({model-id})`); otherwise use `Unknown agent`. Use this identity as `{Agent}` in the history header and the `agent:` frontmatter field.

   Resolve the vault per `references/VAULT-RESOLUTION.md`, then its `locale:` per `references/LOCALE-RESOLUTION.md`. If the first argument matches a registered vault name, use that vault and treat the remaining argument as a project-name override.

   Determine mode: `wiki/` + `AGENTS.md` present → standard mode; otherwise → cross-vault mode.

2. **Prepare state** — create `.cortex/` if it doesn't exist and add it to `.gitignore`. Read `.cortex/MEMORY.md` in full if it exists; on malformed YAML frontmatter, don't stop — read the body as plain text, note the issue in the next `#### Fragile context` entry, and overwrite the frontmatter in step 4.

   If `.cortex/PRAXIS.md` exists, remove dated subsections (`### YYYY-MM-DD`) under `## Working context` older than 15 days (never touch `## Permanent`); skip silently if nothing qualifies.

   Rotate `## History` entries older than 15 days out of `.cortex/MEMORY.md`: append each verbatim, oldest-first, to `.cortex/CONSOLIDATED.md` (if it doesn't exist, create it with a one-line header — `# {vault-name} — consolidated history`), then remove it from `MEMORY.md`. Never reorder entries in either file. **Done when:** every History entry older than 15 days has been moved — zero left behind in `MEMORY.md`.

3. **Consider PRAXIS.md updates** — a deliberate judgment call, not an automatic log entry: does this session surface durable operational knowledge (an environment workaround, operator preference, vault-specific convention, recurring failure pattern, or similar) the next agent needs to avoid re-discovering? Classify per the gate in `references/PRAXIS-FORMAT.md`. **Done when:** every candidate insight has been written to the correct zone or explicitly evaluated and rejected — not silently forgotten.
4. **Write the snapshot** — update Current state and append the History entry in `.cortex/MEMORY.md`, per `references/MEMORY-FORMAT.md`; never modify previous History entries.
   - If an argument with `next: <focus>` was provided (e.g., `/cortex-crystallize next: PostToolUse hook`), mention relevant skills inline and tailor `### Pending` toward the declared next focus.
   - **Vault health triage** — if `wiki/meta/vault-report.json` exists and any of `health.dead_links`, `health.raw_without_source_page`, `health.orphan_pages`, or `health.missing_confidence` is non-empty, add a dated entry to `### Pending` (if full, this takes priority over the least-recent item): `- [ ] Vault health: {N} finding(s) unresolved ({types}) — see wiki/meta/vault-report.json`. If a Pending item for vault health already exists, update its count instead of duplicating; if the report has zero findings and a prior item exists, remove it. Never optional to report — call it out explicitly in the confirmation whenever the report has non-empty findings, don't fold it silently into a generic summary.

## Cross-vault update

If cross-vault mode (step 1), after completing the snapshot:

1. Locate `{vault}/wiki/projects/{project-name}.md` (`{vault}` is the vault resolved in ## Steps, step 1). If the file doesn't exist, skip and note it.
2. **Knowledge applied** — scan the session for vault pages actually consulted (`/cortex-recall` citations, wiki pages read directly). If any surfaced, propose them: "This session referenced {pages} — add to Knowledge applied?" If none surfaced, skip silently instead of asking a blind question.
3. **Recurring issues** — if step 3's PRAXIS gate surfaced a recurring failure pattern, propose it here too: "{pattern} — also track as a recurring issue on this project's page?" Otherwise ask once: "Any recurring problems worth tracking? — or 'none'."
4. If the user provides answers, **propose** the exact text to add to `wiki/projects/{project}.md` before writing.
5. On confirmation, append to the relevant sections:
   - `## Knowledge applied` → `- [[{page}]] — {how it was applied} ({date})`
   - `## Recurring issues` → `- {description} (first seen: {date})`
6. Update `updated:` in the project page frontmatter.

Never write to the vault without explicit confirmation.

## Output format

After completing the snapshot, confirm:
1. What changed in `### Pending` (items added, removed, or kept)
2. What was appended to `## History` (one-line summary of the new entry)
3. If cross-vault mode ran: which vault page was updated
4. **State whether the session is safe to end** — say so explicitly: "Safe to end — everything durable from this session is captured" or "Not fully captured: {what's missing and why}" (e.g. malformed frontmatter noted in step 2, a fragile-context item that couldn't be resolved, an ambiguous PRAXIS candidate left unwritten). Do not omit this line even when nothing is wrong — silence should never be read as an implicit "all good."
