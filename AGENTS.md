---
schema_version: "0.3"
---

# AGENTS.md — cortex-forge

## Vocabulary

- **hot cache**: session memory per project (`.cortex/`), not persistent knowledge
- **vault**: a knowledge base managed by Cortex Forge, not a password manager

## Session start

**Before your first response, in any session that starts in this vault, you MUST read `.cortex/MEMORY.md` in full** — and `.cortex/PRAXIS.md` too, if it exists. Failure to do so is a protocol violation, equivalent to ignoring `CLAUDE.md` in Claude Code.

If the latest `## History` entry in `MEMORY.md` has a `#### Imprint candidate` line, propose running `/cortex-imprint`.

Beyond this, skills trigger themselves — each one's own `description:` states when to invoke it (a URL for `cortex-assimilate`, a question about the vault for `cortex-recall`, and so on). This file does not duplicate that.

## Agent rules

- **Propose creating/updating pages** in `wiki/` when something warrants persistence beyond the session.
- **Detect contradictions** between pages and report them.
- **Never modify files in `.raw/`**.
- **Never read or modify `.env` or credential files.**
- **Ask before creating new directories** if uncertain.

## Available skills

**Vault** (`skills/` — operate inside the vault):
- `cortex-assimilate` — Ingest a source: `.raw/` → synthesized wiki page
- `cortex-recall` — Query the vault: search → synthesize answer with citations
- `cortex-imprint` — Archive a valuable session synthesis as a permanent wiki page
- `cortex-prune` — Health check: detect orphans, dead links, stale claims, missing provenance

**Global** (`skills/{name}/SKILL.md` — installed to `~/.agents/skills/` via `/cortex-forge-setup`):
- `/cortex-crystallize` — Snapshot session context into `.cortex/MEMORY.md`, works from any repo
- `/cortex-forge-setup` — Initial setup: configure vault path and install global skills

## Vault architecture

Six layers, each with a distinct role:

| Layer | Path | Purpose | Rule |
|-------|------|---------|------|
| **Raw** | `.raw/` | Primary sources — immutable originals (articles, docs, transcripts) | Never modify |
| **Wiki** | `wiki/` | Secondary sources — synthesized knowledge; one step removed from primaries | Agent writes and maintains |
| **Hot** | `.cortex/` | Per-project session cache (MEMORY.md, PRAXIS.md) and semantic search DB (`db/`) | Read on session start, write via /cortex-crystallize |
| **Consolidated** | `.cortex/CONSOLIDATED.md` | Archive of MEMORY.md History entries older than 15 days | Never read automatically — consult on-demand only when a session needs older history |
| **Meta** | `wiki/meta/` | Vault metadata and guides | Agent maintains |
| **Skills** | `skills/` | Invocable agent skills | Extend, don't modify |
| **Docs** | `docs/` | Design notes, protocol rationale, resilience proposals | Reference before implementing changes |

`.raw/` is the authoritative record. `wiki/` is always a derived view — cheaper to load, but lossy by construction, and subject to drift (the primary changes, the account doesn't follow). When they conflict, `.raw/` wins. Every source page carries a **context pointer** back to its original — the `raw:` frontmatter field; follow it whenever the synthesized account isn't enough.

## Wiki taxonomy

| Type | Path | Purpose | Template |
|------|------|---------|----------|
| **concept** | `wiki/concepts/` | Synthesized knowledge — ideas, patterns, frameworks, lookup tables, cheat sheets | `templates/concept.md` |
| **entity** | `wiki/entities/` | Concrete named things in the world — people, tools, orgs, services | `templates/entity.md` |
| **source** | `wiki/sources/` | External artifact ingested — articles, docs, repos, videos, threads | `templates/source.md` |
| **project** | `wiki/projects/` | Active project with operational state (repo, status, domains) | `templates/project.md` |

Each page follows: YAML frontmatter + compiled truth + chronological changelog. **All wiki content must be written in English** — this is a public repo. Type disambiguation and source frontmatter fields: see `skills/cortex-assimilate/SKILL.md`.

## On session close

Before `/cortex-crystallize`, evaluate whether the session produced analysis, design decisions, or synthesis worth persisting. If so, suggest `/cortex-imprint` — never archive without explicit confirmation.

Add an entry to `wiki/meta/log.md` for each significant operation. Significant operations include:

- Ingesting a new source (`/cortex-assimilate`)
- Creating or updating wiki pages (`/cortex-imprint`)
- Running a vault health check (`/cortex-prune`)
- Improving or refactoring skills (any edit to `skills/**/SKILL.md`)
- Changing vault protocol or architecture (edits to `AGENTS.md`, `bin/`, CI)

Log format: `## [YYYY-MM-DD] {operation} | {one-line description}`

**`wiki/meta/log.md` vs `/cortex-imprint`:**
- Log entry → always, for any significant operation. One line, operational.
- `/cortex-imprint` → only when the session produced a durable insight or decision worth consulting in future sessions (design rationale, ADR, analysis). Requires explicit confirmation.
