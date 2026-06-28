---
name: cortex-crystallize
description: Snapshot session context into .cortex/MEMORY.md. Works from any repo — inside the vault or from a linked project.
argument-hint: "[vault-name] [project-name] [next: <focus>]"
---

Begin your response by outputting exactly: `Crystallizing memory...`

Save a session snapshot to `.cortex/MEMORY.md` in the active repo (the nearest `.git`), so any agent can resume without losing context.

## Modes

Behavior depends on where the skill is invoked:

- **Inside the vault** — standard snapshot: update current state, append history entry.
- **Outside the vault** (e.g., `loyalty-platform/`) — cross-vault mode: snapshot the project repo AND update the linked vault page with knowledge applied and recurring issues.

## Steps

1. Detect active repo: find nearest `.git` from CWD. If none, ask.
1a. **Detect invoking agent** — run `env` and check these signals in order:
   - `CLAUDECODE=1` → **Claude Code**; append model from `AI_AGENT` if set (e.g. `claude-code_2-1-172_agent` → `Claude Code (claude-sonnet-4-6)`)
   - `COMMANDCODE=1` or `AI_AGENT` starts with `commandcode` → **CommandCode**
   - `AGY=1` or `AI_AGENT` starts with `agy` or `antigravity` → **Antigravity**
   - `CODEX=1` or `AI_AGENT` starts with `codex` → **Codex**
   - None matched → use self-knowledge (you know what CLI you are)
   Use the detected identity as `{Agent}` in the history header and in the `agent:` frontmatter field.
2. **Resolve vault** from `~/.cortex-forge/config.yml`. If missing, prompt to run `/cortex-forge-setup` first.
   Also read `locale:` from the vault's entry — use it for all agent-generated content. Fallback if absent: `.cortex/MEMORY.md` title line (`— locale: {lang}`) → `AGENTS.md` Vault identity (`**locale**:`) → default `en`.
   - Config supports two formats — handle both:
     - New: `vaults: {name: path, ...}` + `default: name`
     - Legacy: `vault: path` (treat as single vault named after its `basename`)
   - If the first argument matches a registered vault name (e.g., `/cortex-crystallize second-brain`) → use that vault; treat the second argument (if any) as the project name override.
   - Otherwise: check if CWD is inside any registered vault (CWD starts with a vault path) → use that vault.
   - If not, use the `default` vault.
   - If no default and multiple vaults → ask the user to pick one.
3. Determine mode:
   - If active repo contains `wiki/`, `AGENTS.md`, and `skills/` → **it IS a vault** → standard mode.
   - Otherwise → cross-vault mode (snapshot project repo + update linked vault page).
4. Create `.cortex/` if it doesn't exist. Add `.cortex/` to `.gitignore` if not already there.
5. Read `.cortex/MEMORY.md` in full if it exists.
5b. **Prune PRAXIS.md working context** — if `.cortex/PRAXIS.md` exists, remove any `### Working context` entries older than 30 days (compare entry date against today). Do not touch `## Permanent`. If nothing to prune, skip silently.
6. **Update current state** (see limits below). Update `agent:` and `updated:` in the file frontmatter to reflect the current agent and date.
   - If an argument with `next: <focus>` was provided (e.g., `/cortex-crystallize next: PostToolUse hook`), add a `### Suggested skills` entry and tailor `### Pending` toward the declared next focus.
7. **Append snapshot to history** using the format in `MEMORY-FORMAT.md` (co-located with this skill).
8. If cross-vault mode: **run cross-vault update** (see section below).

In `#### Fragile context` and any other section, omit tokens, API keys, and credentials (patterns: `sk-*`, `Bearer *`, `ghp_*`, `?token=*`, flags `--password`/`-u user:pass`). If fragile context requires a credential to reproduce, replace it with `<REDACTED>` and note where to obtain it (e.g. `export ANTHROPIC_API_KEY=<REDACTED>  # see .env.local`).

## Cross-vault update

When invoked from outside the vault, after completing the snapshot:

1. Locate `{vault}/wiki/pages/{project-name}.md`. If the file doesn't exist, skip and note it.
2. Ask the user two questions:
   - **Knowledge applied:** "Which vault pages influenced decisions this session? (e.g., `wiki/concepts/deep-modules`) — or 'none'"
   - **Recurring issues:** "Any recurring problems worth tracking? — or 'none'"
3. If the user provides answers, **propose** the exact text to add to `wiki/pages/{project}.md` before writing.
4. On confirmation, append to the relevant sections:
   - `## Knowledge applied` → `- [[{page}]] — {how it was applied} ({date})`
   - `## Recurring issues` → `- {description} (first seen: {date})`
5. Update `updated:` in the project page frontmatter.

Never write to the vault without explicit confirmation.

## Zone 1 — Current state (MUTABLE)

Update on every `/cortex-crystallize`. Hard limits: **max 5 pending items, max 3 active decisions**.

When adding a new item, evaluate whether an existing one has become obsolete and remove it. The size constraint is what makes this zone reliable — if it grows unbounded, it degrades.

**What goes in Current state vs. History:**

- **Current state** — work that requires action in a future session: tasks to resume, decisions to revisit, things left incomplete. If the next agent needs to act on it, it goes here.
- **History** — work that is complete and closed within this session. If nothing is left to do, it belongs only in History.

When in doubt: ask "does the next session need to act on this?" If no → History only. If yes → add to `### Pending` in Current state.

```markdown
---
agent: {agent-id}
updated: {YYYY-MM-DD}
---

# {project} — hot cache

## Current state
### Pending
- [ ] {concise description with enough context to resume} — {file or path if applicable}

### Active decisions
- {decision and rationale — to avoid re-litigating it}
```

`agent:` identifies who last wrote Current state — the mutable zone. When multiple agents operate the same vault across sessions, this field makes it immediately clear whose snapshot is active without reading git history. Update it on every `/cortex-crystallize` invocation.

## Zone 2 — History (APPEND-ONLY)

Append at the end, never modify previous entries.

```markdown
## History

### {YYYY-MM-DD HH:MM UTC±N} — {Agent} ({Trigger})
<!-- Timestamp exacto con offset local. Ejemplo: 2026-06-08 14:30 -04. Nunca omitir hora ni offset. -->

#### What was done
- {bullet per significant change — file or decision, not narrative}

#### Discarded
- {options evaluated and rejected, with brief reason}

#### Attempted and failed
- {approach tried, why it failed, evidence — prevents retrying the same dead end}

#### Fragile context
- {exact numbers, commands, paths, URLs, conventions a new agent can't infer from code}

#### Imprint candidate
- {only if the session produced a durable insight, design decision, or analysis worth a permanent wiki page. One line: what to imprint and suggested type. Omit if nothing qualifies.}
```

`#### Imprint candidate` is detected by the SessionStart hook on the next session and surfaced as a nudge to run `/cortex-imprint`. Disable globally by setting `imprint_triage: false` in `~/.cortex-forge/config.yml`.

## Output format

After completing the snapshot, confirm:
1. What changed in `### Pending` (items added, removed, or kept)
2. What was appended to `## History` (one-line summary of the new entry)
3. If cross-vault mode ran: which vault page was updated

## Rules

- Language: use the locale resolved in step 2b — do not default to your training language.
- Empty sections: omit entirely — never write `_(none)_` or other placeholders. This applies to `#### Attempted and failed` and `#### Discarded` and `#### Fragile context` equally.
- Pending items live in **Current state**, not in the snapshot — so they don't get buried.
- The history snapshot **has no pending section** — that's Current state's responsibility.
- Don't duplicate content already in ADRs, PRDs, issues, or commits — reference by path.
- `.cortex/` must be in `.gitignore` — it's a local agent artifact, not project content.
