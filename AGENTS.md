---
schema_version: "0.3"
---

# AGENTS.md — Antu

This repo is the source of truth for the Antu skill suite (`skills/`, `templates/`), distributed via `npx skills add itsmistermoon/cortex-forge`. This repo is not itself a vault — it has no `wiki/` directory. Vaults that install this suite carry the real knowledge content, in their own `wiki/` and `.raw/`.

## Vocabulary

- **hot cache**: session memory for work on this repo, held in `.hot/`
- **vault**: a knowledge base that installs and runs the Antu suite

## Session start

**Before your first response, in any session that starts in this repo, you MUST read `.hot/HANDOFF.md` in full** — and `.hot/PLAYBOOK.md` too, if it exists. Treat this with the same weight as your own persistent instructions file.

If the latest `## History` entry in `HANDOFF.md` has a `#### Imprint candidate` line, propose imprinting it into a target vault, e.g. via `/antu-imprint {vault}`.

Beyond this, skills trigger themselves — each one's own `description:` states when to invoke it, and that's the single place to look, except where an Agent rule below explicitly calls one out (e.g. the skill-design-principles check).

## Agent skills

### Development methodology

Sigue `METHODOLOGY.md` en la raíz de este repo. Si no existe en este entorno, avisar al usuario y usar el flujo nativo del repo en su lugar.

### Issue tracker

GitHub Issues in `itsmistermoon/cortex-forge`. PRs are not a triage surface. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-role vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context. `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Agent rules

- **Route every change in this repo through a branch and PR**, even when self-merging — each change gets its own auditable page (diff + description + changeset), not a commit buried in `git log`. Never commit directly to `main`.
- **Add a changeset (`npx changeset`) in the same branch** for anything that changes a skill's behavior, matching `.changeset/README.md`'s workflow. For changes with no user-facing effect (docs, CI, internal refactors), run `npx changeset add --empty` instead — `changeset-check.yml` blocks the PR without one or the other.
- **Open a GitHub Issue first for larger or multi-step work** — a feature spanning several PRs, a design decision worth discussing before writing code. Reference it from every PR in that arc with `Refs #N`, reserving `Closes #N` for the final one — closing on the first PR would end the issue's audit trail before the work does. Mechanical details for interacting with issues: `docs/agents/issue-tracker.md`.
- **Run `bash scripts/check-skill-sync.sh`** before opening a PR that touches `skills/**/SKILL.md` or its co-located `references/`/`scripts/`.
- **Check any significant change to an existing skill, or any new skill added to the suite, against `wiki/concepts/skill-design-principles.md` in the `moon-multivac` vault** (`/cortex-recall moon-multivac skill design principles checklist`) before opening a PR — the whiteness test, the 12 principles, and the pre-commit checklist it contains.
- **Edit this repo as the single source of truth**, then refresh installs with `npx skills add itsmistermoon/cortex-forge --all -g -y`; `~/.agents/skills/` is a generated target.
- **Treat `.env` and credential files as off-limits** to reading or modifying.
- **Treat `templates/` here as the canonical schema** — every vault that installs this suite inherits its shape.
- **Check `docs/family-conventions.md` before changing a convention shared with Kuyen** (the sibling lite suite, `moon-kuyen`) — log formats, timestamp formats, and similar cross-cutting shape. Update it if the convention diverges or a new one is formalized.

## Available skills

All 6 live in `skills/` here as their canonical source, and install identically via `npx skills add itsmistermoon/cortex-forge` (`--skill X` for a standalone install).

- `antu-ingest` — Ingest a URL or file into a vault: saves to `.raw/`, synthesizes wiki pages, updates the index
- `antu-recall` — Answer questions grounded in a vault's synthesized wiki content, with citations to the pages used
- `antu-imprint` — Archive a valuable session synthesis as a permanent wiki page in a vault
- `antu-prune` — Health check a vault: detect dead links, orphan pages, missing provenance, unprocessed sources
- `antu-handoff` — Snapshot session context into `.hot/HANDOFF.md`; works from any repo, inside or outside a vault
- `antu-setup` — Register/deregister a vault in Antu and verify global skills are installed

## Wiki taxonomy (schema reference for downstream vaults)

| Type | Path | Purpose | Template |
|------|------|---------|----------|
| **concept** | `wiki/concepts/` | Synthesized knowledge — ideas, patterns, frameworks, lookup tables, cheat sheets | `templates/concept.md` |
| **entity** | `wiki/entities/` | Concrete named things in the world — people, tools, orgs, services | `templates/entity.md` |
| **source** | `wiki/sources/` | External artifact ingested — articles, docs, repos, videos, threads | `templates/source.md` |
| **project** | `wiki/projects/` | Active project with operational state (repo, status, domains) | `templates/project.md` |

Each page follows: YAML frontmatter + compiled truth + chronological changelog. Type disambiguation and source frontmatter fields: see `skills/antu-ingest/SKILL.md`.

`wiki/meta/tags.md` (seeded from `templates/tags.md`) is not a page type — it's the vault's tag rules + registry in one self-referencing document, kept free of hard counts so it never goes stale.
