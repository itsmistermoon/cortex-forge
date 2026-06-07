---
name: cortex-crystallize
description: Snapshot session context into .hot/{project}.md. Works from any repo — inside the vault or from a linked project.
argument-hint: "Project name (optional, inferred from CWD if omitted)"
---

Save a session snapshot to `.hot/{project}.md` in the active repo (the nearest `.git`), so any agent can resume without losing context.

## Modes

Behavior depends on where the skill is invoked:

- **Inside the vault** — standard snapshot: update current state, append history entry.
- **Outside the vault** (e.g., `loyalty-platform/`) — cross-vault mode: snapshot the project repo AND update the linked vault page with knowledge applied and recurring issues.

## Steps

1. Detect active repo: find nearest `.git` from CWD. If none, ask.
2. Read `~/.cortex-forge/config.yml` to get vault path. If missing, prompt to run `/cortex-forge-setup` first.
3. Compare active repo with vault path to determine mode.
4. Create `.hot/` if it doesn't exist. Add `.hot/` to `.gitignore` if not already there.
5. Read `.hot/{project}.md` in full if it exists.
6. **Update current state** (see limits below).
7. **Append snapshot to history** using the template.
8. If cross-vault mode: **run cross-vault update** (see section below).

Do not include tokens, API keys, or sensitive information.

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

```markdown
## Current state
### Pending
- [ ] {concise description with enough context to resume} — {file or path if applicable}
_(none)_ if empty

### Active decisions
- {decision and rationale — to avoid re-litigating it}
_(none)_ if empty
```

## Zone 2 — History (APPEND-ONLY)

Append at the end, never modify previous entries.

```markdown
## History

### {YYYY-MM-DD HH:MM TZ} — {Agent} ({Trigger})

#### What was done
- {bullet per significant change — file or decision, not narrative}

#### Discarded
- {options evaluated and rejected, with brief reason}
- _(none)_ if empty

#### Fragile context
- {exact numbers, commands, paths, URLs, conventions a new agent can't infer from code}
```

## Rules

- Language: match the vault's language (check `AGENTS.md`).
- Empty sections: write `_(none)_`, never omit.
- Pending items live in **Current state**, not in the snapshot — so they don't get buried.
- The history snapshot **has no pending section** — that's Current state's responsibility.
- Don't duplicate content already in ADRs, PRDs, issues, or commits — reference by path.
- `.hot/` must be in `.gitignore` — it's a local agent artifact, not project content.
