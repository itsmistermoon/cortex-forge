# AGENTS.md — cortex-forge

## About this vault

Replace this section with context about yourself and your active projects. Agents use it to understand who they're working with and what knowledge domains matter.

Example:
```
I'm a [role] working on [domain]. Active projects: [project-a], [project-b].
```

## Vault architecture

Five layers, each with a distinct role:

| Layer | Path | Purpose | Rule |
|-------|------|---------|------|
| **Raw** | `.raw/` | Immutable original sources | Never modify |
| **Wiki** | `wiki/` | Synthesized knowledge | Agent writes and maintains |
| **Hot** | `.hot/` | Per-project session cache | Read on session start, write via /cortex-crystallize |
| **Meta** | `wiki/meta/` | Vault metadata and guides | Agent maintains |
| **Skills** | `skills/` | Invocable agent skills | Extend, don't modify |

## Wiki taxonomy

| Type | Path | Purpose | Template |
|------|------|---------|----------|
| **Concept** | `wiki/concepts/` | Ideas, patterns, frameworks | `templates/concept.md` |
| **Entity** | `wiki/entities/` | People, tools, services | `templates/entity.md` |
| **Source** | `wiki/sources/` | Articles, docs, external references | `templates/source.md` |
| **Page** | `wiki/pages/` | Active projects with repo and status | `templates/project.md` |

Each page follows: YAML frontmatter + compiled truth + chronological changelog.

## Ingest protocol

When the user provides new content (URL, file, or text), invoke `cortex-assimilate` without waiting for confirmation. Activation phrases: "new ingest", "process", "add source", "add content", or when a URL or file path is provided directly.

The skill accepts two input modes:
- **URL** — agent downloads content, saves to `.raw/`, synthesizes
- **`.raw/` file** — agent reads the file and synthesizes directly

See full creation/omission criteria in `skills/cortex-assimilate.md`.

## Hot Cache protocol

`.hot/{project}.md` stores session context per project for multi-agent coordination. Read it on session start. Invoke `/cortex-crystallize` after milestones. The `.hot/` directory is gitignored — it's a local agent artifact, not versioned content.

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
- `/cortex-crystallize` — Snapshot session context into `.hot/{project}.md`, works from any repo
- `/cortex-forge-setup` — Initial setup: configure vault path and install global skills

## On session close

Before `/cortex-crystallize`, evaluate whether the session produced analysis, design decisions, or synthesis worth persisting. If so, suggest `/cortex-imprint` — never archive without explicit confirmation. Add an entry to `wiki/meta/log.md` for each significant operation.
