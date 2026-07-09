# cortex-forge

![cortex-forge](cortex-forge-promo.png)

## What it is

Cortex Forge is a set of skills you can use to turn raw sources into synthesized, queryable knowledge. Agents operate the vault: they ingest, recall, and maintain. You define what matters and when to persist it.

The system separates two kinds of memory:
- **Operational memory** — what's happening now and what was decided. Lives in `.cortex/MEMORY.md` (session cache), read by the agent at every session start per `AGENTS.md` instructions. Small, fast, always loaded.
- **Knowledge base** — what the vault knows about the world. Lives in `wiki/` (synthesized pages). Large, deep, consulted on demand.

**The skills work from anywhere.** Installed globally, they let you recall knowledge, ingest sources, or snapshot context from any project, in any session, into a vault that lives somewhere else entirely — the vault is a target, addressed by name, not a place you need to be.

## Setup

1. Run the [skills.sh](https://www.skills.sh/) installer:

```bash
npx skills add itsmistermoon/cortex-forge
```

2. See the [Supported Agents table](https://github.com/vercel-labs/skills#supported-agents) to pick the exact flag value per agent.

3. Run `/cortex-forge-setup` in your agent — from a fresh git repo or an existing vault. This skill will:
- Scaffold `wiki/` and a starter `AGENTS.md` if they don't exist yet (asks first — never overwrites an existing vault), detect your locale, and register the vault in `~/.cortex-forge/config.yml`
- Verify all six skills are actually installed, and tell you to re-run `npx skills add` if any are missing
- Offer to set up semantic search, with a dependency check that runs before asking
- Offer optional extras: syncing infrastructure from upstream, a stale-cache warning threshold, and post-commit git hooks for prune/reindex
- Ask which vault to set as default if more than one is registered

After setup, all skills are available as `/cortex-assimilate`, `/cortex-crystallize`, `/cortex-imprint`, `/cortex-recall`, `/cortex-prune`, and `/cortex-forge-setup`.

## Architecture

Six layers, each with a distinct role:

| Layer | Path | Purpose | Rule |
|-------|------|---------|------|
| **Raw** | `.raw/` | Primary sources — immutable originals | Read-only |
| **Wiki** | `wiki/` | Secondary sources — synthesized knowledge | Agent writes and maintains |
| **Hot** | `.cortex/` | Per-project session cache | Read on session start |
| **Instructions** | `AGENTS.md` | Agent protocols (crystallize, assimilate, recall) | Read on session start |
| **Meta** | `wiki/meta/` | Vault metadata and guides | Agent maintains |
| **Skills** | `skills/` | Invocable agent skills | Extend, don't modify |

## The Skills

Six skills that map to how knowledge actually moves through a system.

### `/cortex-assimilate` — Ingest

Sources land in `.raw/`: articles, PDFs, transcripts, URLs. The agent processes them and produces structured wiki pages — the step that turns perceived input into stored, queryable knowledge.

After synthesizing new pages, it scans existing wiki pages and selects those who are candidates for backward enrichment — existing concept pages, entity entries, and comparison tables that should now mention the new source but don't. An agent evaluates each candidate before any change is made.

### `/cortex-crystallize` — Session context

`.cortex/MEMORY.md` extends working memory indefinitely across two zones: a mutable `Current state` (max 5 pending items, max 3 active decisions) and an append-only `History`. The agent reads it on session start per `AGENTS.md` instructions; you invoke `/cortex-crystallize` at milestones and before closing a session, carrying context forward into the next one. Works from any repo, not just the vault.

### `/cortex-imprint` — Permanent archive

What was worth keeping from the session becomes a stable wiki page. A memory trace is what remains after an experience ends. The session closes; the knowledge stays encoded in the vault.

### `/cortex-recall` — Query

The agent searches the vault, retrieves relevant pages, and synthesizes a response with citations, drawn from what's been assimilated or imprinted into it.

### `/cortex-prune` — Vault hygiene

Detects orphan pages, dead links, contradictory claims, stale information. Forgetting functions as maintenance: prune removes what weakens the network deliberately, so what remains stays reliable.

### `/cortex-forge-setup` — Setup and configuration

Registers the vault and installs global skills. Run from inside a vault directory. Run again from the same vault to deregister.

## Wiki Taxonomy

| Type | Path | Purpose |
|------|------|---------|
| Concept | `wiki/concepts/` | Synthesized knowledge — ideas, patterns, frameworks, lookup tables, cheat sheets |
| Entity | `wiki/entities/` | Concrete named things in the world — people, tools, orgs, services |
| Source | `wiki/sources/` | External artifact ingested — articles, docs, repos, videos, threads |
| Project | `wiki/projects/` | Active project with operational state (repo, status, domains) |

Each page follows: YAML frontmatter + compiled truth + chronological changelog.

## Protocols

Three behaviors are mandatory for any agent operating the vault, defined in `AGENTS.md`:

**Crystallize** — before responding to the user, read `.cortex/MEMORY.md` and `AGENTS.md`. After milestones, invoke `/cortex-crystallize` to snapshot current state and append a history entry.

**Assimilate** — when the user provides a URL, file, or uses words like "ingest" or "process", invoke `/cortex-assimilate` as the first action.

**Recall** — when the user asks about any topic that may exist in the vault, invoke `/cortex-recall` as the first action. The skill returns synthesized knowledge with citations; treat that as the authoritative answer over active context, `grep`, or training knowledge on vault topics.

## Design principles

**One consumption channel, identical everywhere.** `AGENTS.md` mandates reading `.cortex/MEMORY.md` (hard size caps) before the first response, on every agent, with no hook wiring required. The guarantee comes from the protocol itself — unconditional, explicit, and simple enough to follow the same way across any coding agent.

**State and lessons as separate artifacts.** Session-end snapshots capture *state* — pending work, decisions, fragile context. Lessons get a dedicated path: at session end, `/cortex-crystallize` flags imprint candidates in the history entry, invoked manually with full context; at the next session start, reading `.cortex/MEMORY.md` surfaces that flag and the agent proposes `/cortex-imprint` with fresh eyes. Detection happens where context is richest; the decision happens where judgment is freshest.

**Memory as an audited surface.** `.raw/` stays immutable, keeping provenance auditable at every point. Ingestion scans foreign content for hidden Unicode, embedded payloads, and egress commands before it enters the vault. The crystallize-flags → imprint-proposes handoff defaults to *suggest*, putting a human approval step between session output and anything becoming ground truth.

**Failed attempts as first-class knowledge.** The hot cache contract records attempted-and-failed approaches, with evidence, as a dedicated section — carrying forward what didn't work alongside what did.

## Multi-vault

Skills resolve the target vault from wherever you are — no `cd` required. The global config at `~/.cortex-forge/config.yml` maps names to a path and locale:

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
| `/cortex-assimilate` | ✅ `/cortex-assimilate <vault-name> <url-or-file>` |
| `/cortex-recall` | ✅ `/cortex-recall <vault-name> <query>` |
| `/cortex-crystallize` | ✅ `/cortex-crystallize <vault-name> [project-name] [next: <focus>]` |
| `/cortex-imprint` | ✅ `/cortex-imprint <vault-name>` |
| `/cortex-prune` | ✅ `/cortex-prune <vault-name>` — asks for confirmation before proceeding |
