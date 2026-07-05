---
name: cortex-crystallize
behavior: ["snapshot"]
description: Snapshot session context into .cortex/MEMORY.md — preserves pending tasks, active decisions, and session history so future sessions resume without losing context. Invoke when the user says "save context", "crystallize", "snapshot this", "wrap up", "I'm done for now", or when the session is about to close. Works from any repo, inside or outside the vault.
argument-hint: "[vault-name] [project-name] [next: <focus>]"
---

Start your response with the flavor line `Crystallizing memory...`, translated to the language of the user's current message (Spanish: `Cristalizando memoria...`), with nothing before it.

Save a session snapshot to `.cortex/MEMORY.md` in the active repo (the nearest `.git`), so any agent can resume without losing context.

## Steps

1. **Resolve context** — detect the active repo (nearest `.git` from CWD; ask if none) and the invoking agent: identify via self-knowledge first, corroborate with agent-identifying `env` vars if present (don't rely on a fixed hardcoded list — new agents appear continuously), and if still undetermined walk the process tree from `$PPID` upward (`ps -o comm= -p <pid>`) for a known CLI binary name. Append the model in parentheses if known (e.g. `Claude Code (claude-sonnet-5)`); otherwise use `Unknown agent`. Use this identity as `{Agent}` in the history header and the `agent:` frontmatter field.

   Resolve the vault per `references/VAULT-RESOLUTION.md` (argument → CWD → default; prompt to run `/cortex-forge-setup` if missing), then its `locale:` per `references/LOCALE-RESOLUTION.md`. If the first argument matches a registered vault name, use that vault and treat the remaining argument as a project-name override.

   Determine mode: `wiki/` + `AGENTS.md` present → standard mode (same criteria `cortex-forge-setup` uses to validate a vault); otherwise → cross-vault mode (snapshot the project repo and update the linked vault page).

2. **Prepare state** — create `.cortex/` if it doesn't exist and add it to `.gitignore`. Read `.cortex/MEMORY.md` in full if it exists; on malformed YAML frontmatter, don't stop — read the body as plain text, note the issue in the next `#### Fragile context` entry, and overwrite the frontmatter in step 3.

   If `.cortex/PRAXIS.md` exists, remove any `### Working context` entries older than 30 days (never touch `## Permanent`); skip silently if nothing qualifies.

   Rotate `## History` entries older than 30 days out of `.cortex/MEMORY.md`: append each verbatim, oldest-first, to `.cortex/CONSOLIDATED.md` (create it with a one-line header — `# {vault-name} — consolidated history` — if it doesn't exist), then remove it from `MEMORY.md`. Never reorder entries in either file. **Done when:** every History entry older than 30 days has been moved — zero left behind in `MEMORY.md`.

3. **Update current state** per `references/MEMORY-FORMAT.md` (format, hard limits, zone semantics). Update `agent:` and `updated:` in the file frontmatter to reflect the current agent and date.
   - If an argument with `next: <focus>` was provided (e.g., `/cortex-crystallize next: PostToolUse hook`), add a `### Suggested skills` entry and tailor `### Pending` toward the declared next focus.
3a. **Consider PRAXIS.md updates** — a deliberate judgment call, not an automatic log entry: does this session surface durable operational knowledge (an environment workaround, operator preference, vault-specific convention, recurring failure pattern, or similar) the next agent needs to avoid re-discovering? Classify per the gate in `references/PRAXIS-FORMAT.md`. **Done when:** every candidate insight has been written to the correct zone or explicitly evaluated and rejected — not silently forgotten.
3b. **Vault health triage** — if `wiki/meta/vault-report.json` exists and any of `health.dead_links`, `health.raw_without_source_page`, `health.orphan_pages`, or `health.missing_confidence` is non-empty, add a dated entry to `### Pending` in Current state (respecting the 5-item limit — if full, this takes priority over the least-recent item): `- [ ] Vault health: {N} finding(s) unresolved ({types}) — see wiki/meta/vault-report.json`. If Current state already has a Pending item for vault health, update its count instead of duplicating. If the report has zero findings across all four categories, and a prior "Vault health" Pending item exists, remove it — it's resolved.

   This item is never optional to report: regardless of what else changed this session, call it out explicitly in this invocation's own confirmation (Output format, point 1) whenever the report has non-empty findings — do not fold it silently into a generic "Pending updated" summary.
4. **Append snapshot to history** per `references/MEMORY-FORMAT.md` (co-located with this skill) — never modify previous entries.
5. If cross-vault mode: **run cross-vault update** (see section below).

In `#### Fragile context` and any other section, omit tokens, API keys, and credentials (patterns: `sk-*`, `Bearer *`, `ghp_*`, `?token=*`, flags `--password`/`-u user:pass`). If fragile context requires a credential to reproduce, replace it with `<REDACTED>` and note where to obtain it (e.g. `export ANTHROPIC_API_KEY=<REDACTED>  # see .env.local`).

## Cross-vault update

When invoked from outside the vault, after completing the snapshot:

1. Locate `{vault}/wiki/projects/{project-name}.md`. If the file doesn't exist, skip and note it.
2. Ask the user two questions:
   - **Knowledge applied:** "Which vault pages influenced decisions this session? (e.g., `wiki/concepts/deep-modules`) — or 'none'"
   - **Recurring issues:** "Any recurring problems worth tracking? — or 'none'"
3. If the user provides answers, **propose** the exact text to add to `wiki/projects/{project}.md` before writing.
4. On confirmation, append to the relevant sections:
   - `## Knowledge applied` → `- [[{page}]] — {how it was applied} ({date})`
   - `## Recurring issues` → `- {description} (first seen: {date})`
5. Update `updated:` in the project page frontmatter.

Never write to the vault without explicit confirmation.

## Output format

After completing the snapshot, confirm:
1. What changed in `### Pending` (items added, removed, or kept)
2. What was appended to `## History` (one-line summary of the new entry)
3. If cross-vault mode ran: which vault page was updated
4. **State whether the session is safe to end** — say so explicitly: "Safe to end — everything durable from this session is captured" or "Not fully captured: {what's missing and why}" (e.g. malformed frontmatter noted in step 2, a fragile-context item that couldn't be resolved, an ambiguous PRAXIS candidate left unwritten). Do not omit this line even when nothing is wrong — silence should never be read as an implicit "all good."

## Rules

- Language: use the locale resolved in step 1 — do not default to your training language.
- Don't duplicate content already in ADRs, PRDs, issues, or commits — reference by path.
- `.cortex/` must be in `.gitignore` — it's a local agent artifact, not project content.
