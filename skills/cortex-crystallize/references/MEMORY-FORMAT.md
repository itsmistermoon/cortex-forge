# MEMORY.md — format reference

File: `.cortex/MEMORY.md` in the active repo root.
Gitignored — local agent artifact, not versioned content.

---

## Trigger types

The History zone records two kinds of snapshots — treat them differently when writing:

| Trigger | What it means | What to prioritize |
|---------|--------------|-------------------|
| **Mid-session** | The user wants a checkpoint but the conversation continues (e.g. "save context", "snapshot this", or ahead of a context compaction the agent anticipates). | Structure and decisions. The agent writing it is still alive and can fill gaps next turn if something's missing. |
| **Handoff** | True close — the user is ending the session, no return path in this conversation (e.g. "wrap up", "I'm done for now", explicitly closing). | Completeness. Everything the next session needs to resume from scratch, since nothing more can be added after this. |

Infer which applies from how the user invoked it (their own phrasing is usually enough — see the trigger phrases in `SKILL.md`'s `description:`) rather than asking every time. If genuinely ambiguous, ask once.

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

Never modify previous entries. Append at the end. Entries older than 30 days are rotated to `.cortex/CONSOLIDATED.md` — MEMORY.md's History always reflects only the last 30 days (see SKILL.md step 5c).

```markdown
## History

### {YYYY-MM-DD HH:MM UTC±N} — {Agent} ({Trigger})
<!-- Exact timestamp with local offset. Example: 2026-06-08 14:30 -04. Never omit time or offset. -->

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

Empty sections (Discarded, Attempted and failed, Fragile context, Imprint candidate): omit entirely — never write `_(none)_`.
