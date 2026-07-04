# MEMORY.md — format reference

File: `.cortex/MEMORY.md` in the active repo root.
Gitignored — local agent artifact, not versioned content.

---

## Trigger types

The History zone records two kinds of snapshots — treat them differently when writing:

| Trigger | What it means | What to prioritize |
|---------|--------------|-------------------|
| **PreCompact** | Mid-session compaction — the session continues. Claude Code compresses context history. | Structure and decisions. The agent writing it is still alive. |
| **SessionEnd** | True handoff — session terminates, no return path. Next agent starts cold. | Completeness. Everything the next session needs to resume from scratch. |

---

## Zone 1 — Current state (MUTABLE)

Updated on every `/cortex-crystallize`. Hard limits: **max 5 pending, max 3 active decisions**.
When adding an item, evaluate whether an existing one is obsolete and remove it.

```markdown
---
agent: {agent-id}
updated: {YYYY-MM-DD}
---

# {project} — memory

## Current state

### Pending
- [ ] {concise description with enough context to resume} — {file or path if applicable}

### Active decisions
- {decision and rationale — to avoid re-litigating it}

### Suggested skills
- /{skill-name} — {why the next session should invoke this}
```

`agent:` identifies who last wrote Current state. Update it on every invocation.

`### Suggested skills` is optional — include only when the next session will need specific skills to continue. Omit entirely if not applicable.

**Current state vs. History:**
- **Current state** — requires action in a future session (tasks, decisions to revisit, incomplete work)
- **History** — complete and closed within this session; belongs only in History

---

## Zone 2 — History (APPEND-ONLY)

Never modify previous entries. Append at the end.

```markdown
## History

### {YYYY-MM-DD HH:MM UTC±N} — {Agent} ({Trigger})

#### What was done
- {bullet per significant change — file or decision, not narrative}

#### Discarded
- {options evaluated and rejected, with brief reason}

#### Attempted and failed
- {approach tried, why it failed, evidence — prevents retrying the same dead end}

#### Fragile context
- {exact numbers, commands, paths, URLs, conventions a new agent can't infer from code}
```

Empty sections (Discarded, Attempted and failed, Fragile context): omit entirely — never write `_(none)_`.
