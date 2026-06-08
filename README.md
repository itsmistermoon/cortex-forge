# cortex-forge

A protocol for agent-operated knowledge vaults — five skills, one session layer, any LLM.

## What it is

Cortex Forge is a structured system for turning raw sources into synthesized, queryable knowledge. Agents operate the vault: they ingest, recall, and maintain. You define what matters and when to persist it.

The architecture works with any LLM agent — Claude Code, Codex, Antigravity, CommandCode — via a shared session file and a set of invocable skills.

## Architecture

Five layers, each with a distinct role:

| Layer | Path | Purpose | Rule |
|-------|------|---------|------|
| **Raw** | `.raw/` | Immutable original sources | Never modify |
| **Wiki** | `wiki/` | Synthesized knowledge | Agent writes and maintains |
| **Hot** | `.hot/` | Per-project session cache | Read on session start |
| **Meta** | `wiki/meta/` | Vault metadata and guides | Agent maintains |
| **Skills** | `skills/` | Invocable agent skills | Extend, don't modify |

## Skills

Five skills that map to how knowledge actually moves through a system. All are globally invocable via `/skill-name` once installed.

### `/cortex-assimilate` — Ingest

Sources land in `.raw/`: articles, PDFs, transcripts, URLs. The agent processes them and produces structured wiki pages. The brain doesn't store what it perceives — it stores what it processes. Without this step, information enters the system in name only.

### `/cortex-crystallize` — Session context

Working memory lasts seconds. `.hot/{project}.md` extends it indefinitely: current state, active decisions, open threads. The agent reads it on session start; you invoke it at the end. Without it, every conversation starts from zero. Works from any repo, not just the vault.

### `/cortex-imprint` — Permanent archive

What was worth keeping from the session becomes a stable wiki page. A memory trace is what remains after an experience ends. The session closes; the knowledge stays encoded in the vault.

### `/cortex-recall` — Query

The agent searches the vault, retrieves relevant pages, and synthesizes a response with citations. It can only return what was imprinted — if it's not in the vault, it doesn't exist for the system.

### `cortex-prune` — Vault hygiene

Detects orphan pages, dead links, contradictory claims, stale information. Forgetting in the brain isn't a failure — it's maintenance. Prune does this deliberately: removes what weakens the network so what remains is more reliable.

## Wiki Taxonomy

| Type | Path | Purpose |
|------|------|---------|
| Concept | `wiki/concepts/` | Ideas, patterns, frameworks |
| Entity | `wiki/entities/` | People, tools, services |
| Source | `wiki/sources/` | Articles, docs, external references |
| Page | `wiki/pages/` | Active projects and decisions (ADRs) |

Each page follows: YAML frontmatter + compiled truth + chronological changelog.

## Protocols

Three behaviors are mandatory for any agent operating the vault, defined in `AGENTS.md`:

**Crystallize** — before responding to the user, read `.hot/{project}.md`. After milestones, invoke `/cortex-crystallize` to snapshot progress.

**Assimilate** — when the user provides a URL, file, or uses words like "ingest" or "process", invoke `/cortex-assimilate` as the first action, no confirmation needed.

**Recall** — when the user asks about any topic that may exist in the vault, invoke `/cortex-recall` as the first action. Do not answer from active context or use `grep` as a substitute — the skill returns synthesized knowledge with citations.

**Crystallize** — before responding in any session, read `.hot/{project}.md` to resume with full context. After milestones, invoke `/cortex-crystallize` to snapshot current state and append a history entry. The file has two zones: a mutable `Current state` (max 5 pending items, max 3 active decisions) and an append-only `History`. Works from any repo — when invoked outside the vault, it snapshots that project and optionally updates the linked vault page. Three automation levels are available: manual invocation, `AGENTS.md` instructions, or lifecycle hooks configured via `/cortex-forge-setup`.

## Agent compatibility

Tested agents and their hook support:

| Agent | Session start | Session end | Status |
|-------|--------------|-------------|--------|
| Claude Code | `SessionStart` hook | `SessionEnd` (synthesized via `claude -p`) + `PreCompact` (mechanical) | ✅ automatic |
| Codex | `SessionStart` hook | `Stop` hook | ✅ automatic |
| Antigravity CLI | `PreInvocation` (first only) | `Stop` (fullyIdle) | documented, untested |
| CommandCode | none — via `AGENTS.md` | `Stop` hook | partial (close only) |

See `wiki/concepts/agent-hook-compatibility.md` for wire formats, configuration examples, and known issues per agent.

## Multi-vault

Multiple vaults are supported. The global config at `~/.cortex-forge/config.yml` maps names to paths:

```yaml
vaults:
  personal: ~/second-brain
  work: ~/work-vault
default: personal
```

Skills resolve the vault automatically: CWD inside a registered vault → that vault; otherwise → `default`. Register a vault by running `/cortex-forge-setup` from inside it. Run it again from the same vault to deregister.

## Setup

Clone the repo, then run `/cortex-forge-setup` from inside it:

```bash
git clone https://github.com/itsmistermoon/cortex-forge ~/my-vault
cd ~/my-vault
# open a session with your agent and run:
/cortex-forge-setup
```

The skill will:
1. Validate the vault structure
2. Register it in `~/.cortex-forge/config.yml`
3. Install all five skills globally (`~/.agents/skills/` + `~/.claude/skills/` symlinks for Claude Code)
4. Optionally configure lifecycle hooks for automatic session memory
5. Ask which vault to set as default if more than one is registered

After setup, all skills are available as `/cortex-assimilate`, `/cortex-crystallize`, `/cortex-imprint`, `/cortex-recall`, and `/cortex-forge-setup`.

## Usage

Fork this repo and adapt it to your knowledge domain. The `skills/`, `templates/`, and `wiki/` structure is designed to be domain-agnostic — swap out the content, keep the architecture.

Fill in the `## About this vault` section in `AGENTS.md` with 2–3 lines describing your domain and active projects. Agents use this to make better decisions about relevance and taxonomy.

See `AGENTS.md` for the full operating protocol.
