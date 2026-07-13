# MEMORY.md — format reference

File: `.cortex/MEMORY.md` in the active repo root.
Gitignored — local agent artifact, not versioned content.

---

## Zone 1 — Current state (MUTABLE)

Updated on every `/antu-handoff`. Hard limits: **max 5 pending, max 3 active decisions**.
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
```

`agent:` identifies who last wrote Current state. Update it on every invocation.

`### Pending`: only what requires action in a future session — if a next agent doesn't need to act on it, it belongs in History instead. If a specific skill would help resume, mention it inline in the relevant item rather than a dedicated section.

---

## Zone 2 — History (APPEND-ONLY)

Never modify previous entries. Append at the end. `CONSOLIDATED.md` is never read automatically — consult it directly only when a session needs older history.

```markdown
## History

### {YYYY-MM-DD HH:MM UTC±N} — {Agent}
<!-- Exact timestamp with local offset. Example: 2026-06-08 14:30 -04. Never omit time or offset. -->

#### What was done
- {bullet per significant change — file or decision, not narrative} (considered {alternative}, discarded because {reason} — only if a discarded alternative is relevant to this specific bullet)

#### Attempted and failed
- {approach tried, why it failed, evidence — prevents retrying the same dead end}

#### Fragile context
- {exact numbers, commands, paths, URLs, conventions a new agent can't infer from code}

#### Imprint candidate
- {only if the session produced a durable insight, design decision, or analysis worth a permanent wiki page. One line: what to imprint and suggested type. Omit if nothing qualifies.}
```

Empty sections (Attempted and failed, Fragile context, Imprint candidate): omit entirely — never write `_(none)_`.

Don't duplicate content already in ADRs, PRDs, issues, or commits — reference by path.

In `#### Fragile context` and any other section, omit tokens, API keys, and credentials (patterns: `sk-*`, `Bearer *`, `ghp_*`, `?token=*`, flags `--password`/`-u user:pass`). If fragile context requires a credential to reproduce, replace it with `<REDACTED>` and note where to obtain it (e.g. `export ANTHROPIC_API_KEY=<REDACTED>  # see .env.local`).
