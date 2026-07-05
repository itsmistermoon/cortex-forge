# cortex-forge

![cortex-forge](cortex-forge-promo.png)

## What it is

Cortex Forge is a set of skills you can use to turn raw sources into synthesized, queryable knowledge. Agents operate the vault: they ingest, recall, and maintain. You define what matters and when to persist it.

The system separates two kinds of memory:
- **Operational memory** — what's happening now and what was decided. Lives in `.cortex/MEMORY.md` (session cache), read by the agent at every session start per `AGENTS.md` instructions. Small, fast, always loaded.
- **Knowledge base** — what the vault knows about the world. Lives in `wiki/` (synthesized pages). Large, deep, consulted on demand.

**You never have to be inside the vault to use it.** The skills are installed globally. From any project, in any session, you can recall knowledge, ingest sources, or snapshot context into a vault that lives somewhere else entirely. The vault is a target, not a working directory.

## Setup

1. Run the [skills.sh](https://www.skills.sh/) installer:

```bash
npx skills add itsmistermoon/cortex-forge
```

2. See the [Supported Agents table](https://github.com/vercel-labs/skills#supported-agents) to pick the exact flag value per agent.

3. Run `/cortex-forge-setup` in your agent. This skill will:
- Validate the vault structure and register it in `~/.cortex-forge/config.yml`
- Verify all six skills are actually installed (recommended), and tells you to re-run `npx skills add` if any are missing
- Offer to set up semantic search, with a dependency check that runs before asking
- Ask which vault to set as default if more than one is registered

After setup, all skills are available as `/cortex-assimilate`, `/cortex-crystallize`, `/cortex-imprint`, `/cortex-recall`, `/cortex-prune`, and `/cortex-forge-setup`.

## Architecture

Six layers, each with a distinct role:

| Layer | Path | Purpose | Rule |
|-------|------|---------|------|
| **Raw** | `.raw/` | Primary sources — immutable originals | Never modify |
| **Wiki** | `wiki/` | Secondary sources — synthesized knowledge | Agent writes and maintains |
| **Hot** | `.cortex/` | Per-project session cache | Read on session start |
| **Identity** | `AGENTS.md` | Vault identity: mission, owner, domains, vocabulary | Read on session start |
| **Meta** | `wiki/meta/` | Vault metadata and guides | Agent maintains |
| **Skills** | `skills/` | Invocable agent skills | Extend, don't modify |

## The Skills

Six skills that map to how knowledge actually moves through a system.

### `/cortex-assimilate` — Ingest

Sources land in `.raw/`: articles, PDFs, transcripts, URLs. The agent processes them and produces structured wiki pages. The brain doesn't store what it perceives — it stores what it processes. Without this step, information enters the system in name only.

After synthesizing new pages, it scans existing wiki pages and selects those who are candidates for backward enrichment — existing concept pages, entity entries, and comparison tables that should now mention the new source but don't. An agent evaluates each candidate before any change is made.

### `/cortex-crystallize` — Session context

Working memory lasts seconds, `.cortex/MEMORY.md` extends it indefinitely in two zones: a mutable `Current state` (max 5 pending items, max 3 active decisions) and an append-only `History`. The agent reads it on session start per `AGENTS.md` instructions; you invoke `/cortex-crystallize` at milestones and before closing a session. Without it, every conversation starts from zero. Works from any repo, not just the vault. 

### `/cortex-imprint` — Permanent archive

What was worth keeping from the session becomes a stable wiki page. A memory trace is what remains after an experience ends. The session closes; the knowledge stays encoded in the vault.

### `/cortex-recall` — Query

The agent searches the vault, retrieves relevant pages, and synthesizes a response with citations. It can only return what was assimilated — if it's not in the vault, it doesn't exist for the system.

### `/cortex-prune` — Vault hygiene

Detects orphan pages, dead links, contradictory claims, stale information. Forgetting in the brain isn't a failure — it's maintenance. Prune does this deliberately: removes what weakens the network so what remains is more reliable.

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

**Recall** — when the user asks about any topic that may exist in the vault, invoke `/cortex-recall` as the first action. Do not answer from active context or use `grep` as a substitute — the skill returns synthesized knowledge with citations. Agent training knowledge is disqualified for vault topics.

## Design rationale

Most agent-memory systems fail in the same places. These are the failure modes we found studying comparable projects, and the design decisions that answer them.

**There is only one reliable consumption channel, and it's not a hook.** Instructions in `AGENTS.md`, skill descriptions, and "the agent will remember to check" are best-effort — but so is lifecycle hook support: it varies too much across Claude Code, Codex, Antigravity, and CommandCode to be a foundation. Cortex Forge doesn't try to guarantee delivery via automatic injection; instead it makes the read/write contract explicit and identical everywhere — `AGENTS.md` mandates reading `.cortex/MEMORY.md` (hard size caps) before the first response, on every agent, with no hook wiring required. The guarantee comes from the protocol being unconditional and simple to follow, not from a mechanism only some agents support.

**State and lessons are different artifacts.** Session-end snapshots capture *state* (pending work, decisions, fragile context). Lessons — the workaround you'd otherwise re-explain next week — get lost because nobody archives them at the moment of fatigue. Cortex Forge splits the work across the session boundary: at session end, `/cortex-crystallize` (invoked manually, with full context) *flags* imprint candidates in the history entry. At the next session start, reading `.cortex/MEMORY.md` surfaces that flag and the agent proposes `/cortex-imprint` with fresh eyes. Detection happens where context is richest; the decision happens where judgment is freshest — no separate automation needed.

**Memory is attack surface.** A vault that auto-loads files nobody re-reads is exactly where injection payloads persist (see Microsoft's AI Recommendation Poisoning report, Feb 2026). Cortex Forge treats this structurally: `.raw/` is immutable so provenance is always auditable; ingestion scans foreign content for hidden Unicode, embedded payloads, and egress commands before it enters the vault; and automated archiving defaults to *suggest* *(imprint pipeline landing in v0.4)* — a human approves before anything becomes ground truth. Convenience never outruns the isolation layer.

**Failed attempts are knowledge.** Session memory that only records what worked condemns the next session to retry what didn't. The hot cache contract records attempted-and-failed approaches, with evidence, as a first-class section.

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
