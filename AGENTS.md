---
schema_version: "0.3"
---

# AGENTS.md — cortex-forge

This repo is the source of truth for the Cortex Forge skill suite (`skills/`, `templates/`), distributed via `npx skills add itsmistermoon/cortex-forge`. `wiki/` here holds only the canonical taxonomy as empty scaffolding. Vaults that install this suite carry the real knowledge content, in their own `wiki/` and `.raw/`.

## Vocabulary

- **hot cache**: session memory for work on this repo, held in `.cortex/`
- **vault**: a knowledge base that installs and runs the Cortex Forge suite

## Session start

**Before your first response, in any session that starts in this repo, you MUST read `.cortex/MEMORY.md` in full** — and `.cortex/PRAXIS.md` too, if it exists. Treat this with the same weight as your own persistent instructions file.

If the latest `## History` entry in `MEMORY.md` has a `#### Imprint candidate` line, propose imprinting it into a target vault, e.g. via `/cortex-imprint {vault}`.

Beyond this, skills trigger themselves — each one's own `description:` states when to invoke it, and that's the single place to look.

## Agent rules

- **Route every edit to `skills/**/SKILL.md` or its co-located `references/`/`scripts/` through a branch and PR**, even when self-merging — each change gets its own auditable page (diff + description + changeset), not a commit buried in `git log`. Add a changeset (`npx changeset`) in the same branch, matching `.changeset/README.md`'s workflow.
- **Run `bash bin/check-skill-sync.sh`** before opening that PR.
- **Edit this repo as the single source of truth**, then refresh installs with `npx skills add itsmistermoon/cortex-forge --all -g -y`; `~/.agents/skills/` is a generated target.
- **Treat `.env` and credential files as off-limits** to reading or modifying.
- **Treat `wiki/` and `templates/` here as the canonical schema** — every vault that installs this suite inherits their shape.

## Available skills

All 6 live in `skills/` here as their canonical source, and install identically via `npx skills add itsmistermoon/cortex-forge` (`--skill X` for a standalone install).

- `cortex-assimilate` — Ingest a URL or file into a vault: saves to `.raw/`, synthesizes wiki pages, updates the index
- `cortex-recall` — Answer questions grounded in a vault's synthesized wiki content, with citations to the pages used
- `cortex-imprint` — Archive a valuable session synthesis as a permanent wiki page in a vault
- `cortex-prune` — Health check a vault: detect dead links, orphan pages, missing provenance, unprocessed sources
- `cortex-crystallize` — Snapshot session context into `.cortex/MEMORY.md`; works from any repo, inside or outside a vault
- `cortex-forge-setup` — Register/deregister a vault in Cortex Forge and verify global skills are installed

## Wiki taxonomy (schema reference for downstream vaults)

| Type | Path | Purpose | Template |
|------|------|---------|----------|
| **concept** | `wiki/concepts/` | Synthesized knowledge — ideas, patterns, frameworks, lookup tables, cheat sheets | `templates/concept.md` |
| **entity** | `wiki/entities/` | Concrete named things in the world — people, tools, orgs, services | `templates/entity.md` |
| **source** | `wiki/sources/` | External artifact ingested — articles, docs, repos, videos, threads | `templates/source.md` |
| **project** | `wiki/projects/` | Active project with operational state (repo, status, domains) | `templates/project.md` |

Each page follows: YAML frontmatter + compiled truth + chronological changelog. Type disambiguation and source frontmatter fields: see `skills/cortex-assimilate/SKILL.md`.
