# Antu

![Antu](almagest-antu-promo.png)

Antu is the full suite of the [Almagest](https://github.com/itsmistermoon/almagest) family — its lite sibling is [Kuyen](https://github.com/itsmistermoon/almagest-kuyen). See the Almagest README for how to choose between them.

## What it is

Antu is a set of skills you can use to turn raw sources into synthesized, queryable knowledge. Agents operate the vault: they ingest, query, and maintain. You define what matters and when to persist it.

The system separates two kinds of memory:
- **Operational memory** — what's happening now and what was decided. Lives in `.hot/HANDOFF.md` (session cache), read by the agent at every session start per `AGENTS.md` instructions. Small, fast, always loaded.
- **Knowledge base** — what the vault knows about the world. Lives in `wiki/` (synthesized pages). Large, deep, consulted on demand.

**The skills work from anywhere.** Installed globally, they let you recall knowledge, ingest sources, or snapshot context from any project, in any session, into a vault that lives somewhere else entirely — the vault is a target, addressed by name, not a place you need to be.

## Setup

Two ways to install, depending on your agent.

### Option A: skills.sh (any supported agent)

1. Run the [skills.sh](https://www.skills.sh/) installer:

```bash
npx skills add itsmistermoon/almagest-antu
```

2. See the [Supported Agents table](https://github.com/vercel-labs/skills#supported-agents) to pick the exact flag value per agent.

Skills install unnamespaced: `/wiki-ingest`, `/hot-handoff`, `/wiki-imprint`, `/wiki-query`, `/wiki-lint`, `/hot-triage`, `/wiki-setup`.

### Option B: Claude Code plugin

This repo is also a self-hosted [Claude Code plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces) — one repo, one plugin.

```bash
/plugin marketplace add itsmistermoon/almagest-antu
/plugin install antu@antu
```

Skills install namespaced: `/antu:wiki-ingest`, `/antu:hot-handoff`, etc. To test a local checkout before installing, use `claude --plugin-dir .` from the repo root.

### Then, either way

Run `/wiki-setup` (or `/antu:wiki-setup`) in your agent — from a fresh git repo or an existing vault. This skill will:
- Scaffold `wiki/` and a starter `AGENTS.md` if they don't exist yet (asks first — never overwrites an existing vault), detect your locale, and register the vault in `~/.almagest/config.yml`
- Verify all seven skills are actually installed, and tell you to re-run `npx skills add` (or `/plugin update`) if any are missing
- Offer to set up semantic search, with a dependency check that runs before asking
- Offer optional extras: syncing infrastructure from upstream, a stale-cache warning threshold, and post-commit git hooks for prune/reindex
- Ask which vault to set as default if more than one is registered

## Architecture

Six layers, each with a distinct role:

| Layer | Path | Purpose | Rule |
|-------|------|---------|------|
| **Raw** | `.raw/` | Primary sources — immutable originals | Read-only |
| **Wiki** | `wiki/` | Secondary sources — synthesized knowledge | Agent writes and maintains |
| **Hot** | `.hot/` | Per-project session cache | Read on session start |
| **Instructions** | `AGENTS.md` | Agent protocols (handoff, ingest, recall) | Read on session start |
| **Meta** | `meta/` | Vault metadata and guides (sibling of `wiki/`, not part of the OKF bundle) | Agent maintains |
| **Skills** | `skills/` | Invocable agent skills | Extend, don't modify |

## The Skills

Seven skills that map to how knowledge actually moves through a system.

### `/wiki-ingest` — Ingest

Sources land in `.raw/`: articles, PDFs, transcripts, URLs. The agent processes them and produces structured wiki pages — the step that turns perceived input into stored, queryable knowledge.

After synthesizing new pages, it scans existing wiki pages and selects those who are candidates for backward enrichment — existing concept pages, entity entries, and comparison tables that should now mention the new source but don't. An agent evaluates each candidate before any change is made.

### `/hot-handoff` — Session context

`.hot/HANDOFF.md` extends working memory indefinitely across two zones: a mutable `Current state` (max 5 pending items, max 3 active decisions) and an append-only `History`. The agent reads it on session start per `AGENTS.md` instructions; you invoke `/hot-handoff` at milestones and before closing a session, carrying context forward into the next one. Works from any repo, not just the vault.

### `/wiki-imprint` — Permanent archive

What was worth keeping from the session becomes a stable wiki page. A memory trace is what remains after an experience ends. The session closes; the knowledge stays encoded in the vault.

### `/wiki-query` — Query

The agent searches the vault, retrieves relevant pages, and synthesizes a response with citations, drawn from what's been ingested or imprinted into it.

### `/wiki-lint` — Vault hygiene

Detects orphan pages, dead links, contradictory claims, stale information. Forgetting functions as maintenance: prune removes what weakens the network deliberately, so what remains stays reliable.

`wiki/` is [OKF](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf)-compatible (see `docs/adr/0005-okf-adoption.md`): pages cross-reference each other with markdown links, not `[[wikilinks]]`, and cite their sources in a `# Citations` section instead of `sources:` frontmatter.

### `/hot-triage` — Session-state hygiene

On-demand deep clean of `.hot/` (the active repo's session state, not the vault): retrospective `PLAYBOOK.md` pruning, recovering pending/fragile-context items after a foreign-suite (Kuyen) write, and validity re-checks on existing `### Pending`/`### Active decisions` entries. Mirrors `/wiki-lint`'s pattern — a separate hygiene skill, not folded into `/hot-handoff`'s per-session mechanics.

### `/wiki-setup` — Setup and configuration

Registers the vault and installs global skills. Run from inside a vault directory. Run again from the same vault to deregister.

## CLI tools

Installed via the Claude Code plugin, these are available as bare commands (`bin/` is on the plugin's `PATH`). With the skills.sh install, run them with their path from a checkout instead, e.g. `bash bin/antu-embed.sh`.

- **`antu-embed.sh`** — bootstrap the semantic index for a vault
- **`setup-vault.sh`** — scaffold an Obsidian vault (directories, graph colors by type, theme, community plugins) for a fresh Antu vault
- **`tags-audit.py`** — audit `tags:` usage across a vault's wiki pages (`tags-audit.py <vault-path> [--write-snapshot]`)

## Wiki Taxonomy

| Type | Path | Purpose |
|------|------|---------|
| Concept | `wiki/concepts/` | Synthesized knowledge — ideas, patterns, frameworks, lookup tables, cheat sheets |
| Entity | `wiki/entities/` | Concrete named things in the world — people, tools, orgs, services |
| Source | `wiki/sources/` | External artifact ingested — articles, docs, repos, videos, threads |
| Project | `wiki/projects/` | Active project with operational state (repo, status, domains) |

Each page follows: YAML frontmatter + compiled truth + a `# Citations` section (concept/entity/project only) + chronological changelog.

## Protocols

Three behaviors are mandatory for any agent operating the vault, defined in `AGENTS.md`:

**Handoff** — before responding to the user, read `.hot/HANDOFF.md` and `AGENTS.md`. After milestones, invoke `/hot-handoff` to snapshot current state and append a history entry.

**Ingest** — when the user provides a URL, file, or uses words like "ingest" or "process", invoke `/wiki-ingest` as the first action.

**Recall** — when the user asks about any topic that may exist in the vault, invoke `/wiki-query` as the first action. The skill returns synthesized knowledge with citations; treat that as the authoritative answer over active context, `grep`, or training knowledge on vault topics.

## Design principles

**One consumption channel, identical everywhere.** `AGENTS.md` mandates reading `.hot/HANDOFF.md` (hard size caps) before the first response, on every agent, with no hook wiring required. The guarantee comes from the protocol itself — unconditional, explicit, and simple enough to follow the same way across any coding agent.

**State and lessons as separate artifacts.** Session-end snapshots capture *state* — pending work, decisions, fragile context. Lessons get a dedicated path: at session end, `/hot-handoff` flags imprint candidates in the history entry, invoked manually with full context; at the next session start, reading `.hot/HANDOFF.md` surfaces that flag and the agent proposes `/wiki-imprint` with fresh eyes. Detection happens where context is richest; the decision happens where judgment is freshest.

**Memory as an audited surface.** `.raw/` stays immutable, keeping provenance auditable at every point. Ingestion scans foreign content for hidden Unicode, embedded payloads, and egress commands before it enters the vault. The handoff-flags → imprint-proposes step defaults to *suggest*, putting a human approval step between session output and anything becoming ground truth.

**Failed attempts as first-class knowledge.** The hot cache contract records attempted-and-failed approaches, with evidence, as a dedicated section — carrying forward what didn't work alongside what did.

## Full vs. lite

Antu has a sibling suite, **[Kuyen](https://github.com/itsmistermoon/almagest-kuyen)**, built later as a from-scratch reapplication of what Antu's growth taught: minimal dependencies, no scripts, no reference docs, no multi-vault machinery — just skills (installed as `kyn-*` so both suites coexist on the same machine). Both are Almagest vault suites; neither depends on the other. Pick per vault, not once for everything you do — the canonical chooser table lives in the [Almagest README](https://github.com/itsmistermoon/almagest), and conventions the two suites deliberately share (not features — just shared shape, like log entry formatting) are tracked in Almagest's [`docs/family-conventions.md`](https://github.com/itsmistermoon/almagest/blob/main/docs/family-conventions.md).

## Multi-vault

Skills resolve the target vault from wherever you are — no `cd` required. The global config at `~/.almagest/config.yml` maps names to a path and locale:

```yaml
vaults:
  personal:
    path: ~/second-brain
    locale: en
  work:
    path: ~/work-vault
    locale: en
default: personal
```

Skills resolve the vault automatically: if you're inside a registered vault → that vault; otherwise → `default`. You can pass an explicit vault name as the first argument to override from anywhere:

| Skill | Explicit vault arg |
|---|---|
| `/wiki-ingest` | ✅ `/wiki-ingest <vault-name> <url-or-file>` |
| `/wiki-query` | ✅ `/wiki-query <vault-name> <query>` |
| `/hot-handoff` | ✅ `/hot-handoff <vault-name> [project-name] [next: <focus>]` |
| `/wiki-imprint` | ✅ `/wiki-imprint <vault-name>` |
| `/wiki-lint` | ✅ `/wiki-lint <vault-name>` — asks for confirmation before proceeding |
| `/hot-triage` | ⛔ — resolves the active repo (nearest `.git`), not a vault |
