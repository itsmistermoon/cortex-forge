---
name: cortex-crystallize
behavior: ["snapshot"]
description: Snapshot session context into .cortex/MEMORY.md — preserves pending tasks, active decisions, and session history so future sessions resume without losing context. Invoke when the user says "save context", "crystallize", "snapshot this", "wrap up", "I'm done for now", or when the session is about to close. Works from any repo, inside or outside the vault.
argument-hint: "[vault-name] [project-name] [next: <focus>]"
---

Begin your response with a short flavor line announcing the skill started, translated to the language of the user's current message (anchor: `Crystallizing memory...`; Spanish: `Cristalizando memoria...`; translate analogously for other languages). Output this literally as the first thing in your response.

Save a session snapshot to `.cortex/MEMORY.md` in the active repo (the nearest `.git`), so any agent can resume without losing context.

## Modes

Behavior depends on where the skill is invoked:

- **Inside the vault** — standard snapshot: update current state, append history entry.
- **Outside the vault** (e.g., `loyalty-platform/`) — cross-vault mode: snapshot the project repo AND update the linked vault page with knowledge applied and recurring issues.

## Steps

1. Detect active repo: find nearest `.git` from CWD. If none, ask.
1a. **Detect invoking agent** — identify yourself primarily via self-knowledge: you know which CLI/agent you are running as, regardless of which one it is. Corroborate with `env` only if it surfaces something more specific (e.g. a model identifier) — read whatever agent-identifying variables are actually present rather than checking a fixed list of hardcoded agent names, since new agents are added to the ecosystem continuously and a hardcoded list goes stale. If still undetermined, walk the process tree from `$PPID` upward (`ps -o comm= -p <pid>`, repeating with each parent's PPID) looking for a known CLI binary name — more reliable than env vars since it doesn't depend on the CLI self-reporting. Append the model, if determinable, in parentheses (e.g. `Claude Code (claude-sonnet-5)`). If truly undetermined, use `Unknown agent` rather than guessing.
   Use the detected identity as `{Agent}` in the history header and in the `agent:` frontmatter field.
2. **Resolve vault** — follow `references/VAULT-RESOLUTION.md` (argument → CWD → default). If missing, prompt to run `/cortex-forge-setup` first. Then read `locale:`, using the fallback chain in `references/LOCALE-RESOLUTION.md`.
   - If the first argument matches a registered vault name (e.g., `/cortex-crystallize second-brain`) → use that vault; treat the second argument (if any) as the project name override.
3. Determine mode:
   - If active repo contains `wiki/` and `AGENTS.md` → **it IS a vault** → standard mode. Same criteria `cortex-forge-setup` uses to validate a vault.
   - Otherwise → cross-vault mode (snapshot project repo + update linked vault page).
4. Create `.cortex/` if it doesn't exist. Add `.cortex/` to `.gitignore` if not already there.
5. Read `.cortex/MEMORY.md` in full if it exists. If the file has malformed YAML frontmatter (parse error on the `---` block), do not stop — read the body as plain text, skip the frontmatter fields, and note the issue in the next `#### Fragile context` entry. Overwrite the frontmatter with correct values in step 6.
5b. **Prune PRAXIS.md working context** — if `.cortex/PRAXIS.md` exists, remove any `### Working context` entries older than 30 days (compare entry date against today). Do not touch `## Permanent`. If nothing to prune, skip silently.
5c. **Rotate History entries older than 30 days to CONSOLIDATED.md** — for each `### {date}` entry under `## History` in `.cortex/MEMORY.md`, compare its date against today. If more than 30 days old:
   1. Append the entry verbatim (unmodified, same template) to `.cortex/CONSOLIDATED.md`, creating the file with a one-line header if it doesn't exist (`# {vault-name} — consolidated history`).
   2. Remove it from `.cortex/MEMORY.md`'s `## History` — MEMORY.md must only ever contain History entries from the last 30 days.
   3. Preserve chronological order (oldest-first, matching History's own append order) — never reorder entries in either file.
   If no entries qualify, skip silently. **Done when:** every History entry older than 30 days has been moved — zero left behind in MEMORY.md.
6. **Update current state** (see limits below). Update `agent:` and `updated:` in the file frontmatter to reflect the current agent and date.
   - If an argument with `next: <focus>` was provided (e.g., `/cortex-crystallize next: PostToolUse hook`), add a `### Suggested skills` entry and tailor `### Pending` toward the declared next focus.
6a. **Consider PRAXIS.md updates** — a deliberate judgment call, not an automatic log entry. PRAXIS is semantic memory: durable knowledge about *how to operate*, distinct from MEMORY.md's working state (what's active now) and its History zone's episodic record (what happened). Ask: did this session surface operational knowledge — an environment workaround, an operator preference, a vault-specific convention, a recurring failure pattern, or similar — that the next agent needs to avoid re-discovering? These are examples, not an exhaustive list; anything of the same shape qualifies. See `references/PRAXIS-FORMAT.md` for the write format.

   **Gate for which zone**:
   - **Confirmed** — the user stated it explicitly as a standing rule ("always confirm before deleting", "respond in Chilean Spanish"), or it already appears once in `## Working context` from a prior session and has now held true again. In the latter case, promote it: move the entry to `## Permanent` and remove it from `## Working context` — never leave the same fact logged in both zones. → `## Permanent`.
   - **Provisional** — a single-session observation not yet confirmed: a workaround that worked once but wasn't tested for generality, a suspected failure pattern seen for the first time, an inferred convention the user hasn't explicitly confirmed. → `## Working context` (dated; auto-pruned by step 5b after 30 days if never confirmed again).
   - **Genuinely ambiguous** — if a candidate doesn't clearly fit either bucket (e.g. it feels durable but was never stated as a rule, or it's a repeat that might be coincidence rather than a confirmed pattern), ask the user once rather than guessing: "This looks like it might be a standing convention — write it to PRAXIS.md's Permanent zone, or keep it as working context for now?" Only write to `## Permanent` on explicit approval; otherwise default to `## Working context`. Do not ask for candidates that already clearly resolve via the two rules above — this is for the genuinely unclear case only, not a blanket confirmation step.

   If nothing from this session qualifies, skip — do not write to PRAXIS.md by default. **Done when:** every candidate insight from this session has been written to the correct zone or explicitly evaluated and rejected — not silently forgotten.
6b. **Vault health triage** — if `wiki/meta/vault-report.json` exists and any of `health.dead_links`, `health.raw_without_source_page`, `health.orphan_pages`, or `health.missing_confidence` is non-empty, add a dated entry to `### Pending` in Current state (respecting the 5-item limit — if full, this takes priority over the least-recent item): `- [ ] Vault health: {N} finding(s) unresolved ({types}) — see wiki/meta/vault-report.json`. If Current state already has a Pending item for vault health, update its count instead of duplicating. If the report has zero findings across all four categories, and a prior "Vault health" Pending item exists, remove it — it's resolved.

   This item is never optional to report: regardless of what else changed this session, call it out explicitly in this invocation's own confirmation (Output format, point 1) whenever the report has non-empty findings — do not fold it silently into a generic "Pending updated" summary.
7. **Append snapshot to history** using the format in `references/MEMORY-FORMAT.md` (co-located with this skill).
8. If cross-vault mode: **run cross-vault update** (see section below).

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

## Zone 1 — Current state (MUTABLE)

Update on every `/cortex-crystallize`. Use the canonical format in `references/MEMORY-FORMAT.md` (co-located with this skill) — do not reproduce it here.

Hard limits: **max 5 pending items, max 3 active decisions**. When adding an item, evaluate whether an existing one is obsolete and remove it. The size constraint is what makes this zone reliable — if it grows unbounded, it degrades.

**What goes in Current state vs. History:**
- **Current state** — requires action in a future session: tasks to resume, decisions to revisit, incomplete work. If the next agent needs to act on it, it goes here.
- **History** — complete and closed within this session. If nothing is left to do, it belongs only in History.

When in doubt: ask "does the next session need to act on this?" If no → History only. If yes → add to `### Pending` in Current state.

`agent:` identifies who last wrote Current state. Update it on every invocation — when multiple agents operate the same vault, this field shows whose snapshot is active without reading git history.

## Zone 2 — History (APPEND-ONLY)

Append at the end, never modify previous entries. Use the canonical format in `references/MEMORY-FORMAT.md` (co-located with this skill) — do not reproduce it here. Entries older than 30 days are rotated out to `.cortex/CONSOLIDATED.md` by step 5c — `MEMORY.md`'s History always reflects only the last 30 days. `CONSOLIDATED.md` is never read automatically; consult it directly only when a session needs to reference older history.

`#### Imprint candidate` is surfaced manually — when a new session starts and the agent reads `.cortex/MEMORY.md` (per `AGENTS.md` instructions), it should check the most recent history entry for this field and nudge the user to run `/cortex-imprint` if present. Disable globally by setting `imprint_triage: false` in `~/.cortex-forge/config.yml`.

## Output format

After completing the snapshot, confirm:
1. What changed in `### Pending` (items added, removed, or kept)
2. What was appended to `## History` (one-line summary of the new entry)
3. If cross-vault mode ran: which vault page was updated
4. **State whether the session is safe to end** — say so explicitly: "Safe to end — everything durable from this session is captured" or "Not fully captured: {what's missing and why}" (e.g. malformed frontmatter noted in step 5, a fragile-context item that couldn't be resolved, an ambiguous PRAXIS candidate left unwritten). Do not omit this line even when nothing is wrong — silence should never be read as an implicit "all good."

## Rules

- Language: use the locale resolved in step 2b — do not default to your training language.
- Empty sections: omit entirely — never write `_(none)_` or other placeholders. This applies to `#### Attempted and failed` and `#### Discarded` and `#### Fragile context` equally.
- Pending items live in **Current state**, not in the snapshot — so they don't get buried.
- The history snapshot **has no pending section** — that's Current state's responsibility.
- Don't duplicate content already in ADRs, PRDs, issues, or commits — reference by path.
- `.cortex/` must be in `.gitignore` — it's a local agent artifact, not project content.

## Changelog

- 2026-07-04 [Claude Code]: Added process-tree walk (`$PPID` upward via `ps -o comm=`) as a fallback method for detecting the invoking agent in step 1a when self-knowledge and env vars aren't enough — rescued from a finding in `wiki/meta/agent-diagnostics.md` (2026-06-11) about CommandCode, which exposes no self-identifying environment variable
- 2026-07-04 [Claude Code]: Added step 6b (vault health triage) that propagates findings from `vault-report.json` to `### Pending` on every crystallize, closing a gap where nobody recorded whether the vault health triage (AGENTS.md step 3) was actually addressed
- 2026-07-04 [Claude Code]: Centralized vault structure validation (`wiki/`+`AGENTS.md`) in `references/VAULT-RESOLUTION.md`; the standard-vs-cross-vault mode detection in step 3 is unrelated routing logic and was left untouched
- 2026-07-04 [Claude Code]: Reworded "Resolve vault" step intro to distinguish VAULT-RESOLUTION.md (decision flow) from LOCALE-RESOLUTION.md (fallback chain), removing the repeated closing phrase
- 2026-07-04 [Claude Code]: Added an explicit "safe to end" verdict to the output format, inspired by a comparative analysis with the `stow` skill (from another repo), so malformed frontmatter or unresolved context doesn't stay buried only in History
- 2026-07-04 [Claude Code]: Extracted "Resolve vault" logic to shared `references/VAULT-RESOLUTION.md`, co-located across 5 skills (was duplicated inline with real drift between copies)
- 2026-07-04 [Claude Code]: Added a third "genuinely ambiguous" case to the step 6a PRAXIS.md gate — ask the user once instead of guessing, inspired by a comparative analysis with the `stow` skill; also removed a parenthetical historical-context phrase ("confidence, not category, decides") from the same gate
