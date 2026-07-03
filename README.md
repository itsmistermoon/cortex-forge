# cortex-forge

![cortex-forge](cortex-forge-promo.png)

A protocol for agent-operated knowledge vaults — six skills, one session layer, any LLM.

> The vault lives wherever you put it. The skills work from anywhere.

## What it is

Cortex Forge is a structured system for turning raw sources into synthesized, queryable knowledge. Agents operate the vault: they ingest, recall, and maintain. You define what matters and when to persist it.

The system separates **two kinds of memory** that most tools conflate:
- **Operational memory** — what's happening now and what was decided. Lives in `.cortex/MEMORY.md` (session cache), read by the agent at every session start per `AGENTS.md` instructions. Small, fast, always loaded.
- **Knowledge base** — what the vault knows about the world. Lives in `wiki/` (synthesized pages). Large, deep, consulted on demand.

Session memory keeps context across conversations. The wiki keeps knowledge across projects. They serve different purposes, use different retrieval patterns, and neither can replace the other.

The architecture works with any LLM agent — Claude Code, Codex, Antigravity, CommandCode — via a shared session file and a set of invocable skills.

**You never have to be inside the vault to use it.** The skills are installed globally. From any project, in any session, you can recall knowledge, ingest sources, or snapshot context into a vault that lives somewhere else entirely:

```
# Working on a client project, querying your personal vault
/cortex-recall What are the trade-offs of single-table DynamoDB?

# Ingesting a URL from a work session into the personal vault
/cortex-assimilate personal https://...

# Crystallizing a session from inside any repo
/cortex-crystallize personal
```

The vault is a target, not a working directory.

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

`.raw/` is authoritative. `wiki/` is a derived view — cheaper to load, but lossy by construction. When they conflict, `.raw/` wins.

## Visualization

Open `wiki/` as an [Obsidian](https://obsidian.md) vault to get a live knowledge graph — nodes are pages, edges are `[[wikilinks]]`, clusters emerge from link density. No configuration needed. See `docs/obsidian-visualization.md`.

## Skills

Six skills that map to how knowledge actually moves through a system. All are globally invocable via `/skill-name` once installed.

### `/cortex-assimilate` — Ingest

Sources land in `.raw/`: articles, PDFs, transcripts, URLs. The agent processes them and produces structured wiki pages. The brain doesn't store what it perceives — it stores what it processes. Without this step, information enters the system in name only.

**Backward enrichment** *(planned)*: after synthesizing new pages, assimilate scans existing wiki pages that share `tags:` with the new source and whose `updated:` date predates the ingestion. These are candidates for backward enrichment — existing concept pages, entity entries, and comparison tables that should now mention the new source but don't. An agent evaluates each candidate before any change is made. This closes the gap where ingesting a new tool updates the vault going forward but leaves prior knowledge incomplete.

### `/cortex-crystallize` — Session context

Working memory lasts seconds. `.cortex/MEMORY.md` extends it indefinitely: current state, active decisions, open threads. The agent reads it on session start per `AGENTS.md` instructions; you invoke `/cortex-crystallize` at milestones and before closing a session. Without it, every conversation starts from zero. Works from any repo, not just the vault.

The file has two zones: a mutable `Current state` (max 5 pending items, max 3 active decisions) and an append-only `History`. Crystallize is invoked manually — the same way on every agent (Claude Code, Codex, Antigravity, CommandCode) — so there's no dependency on lifecycle hook support, which varies too much across agents to build on top of.

### `/cortex-imprint` — Permanent archive

What was worth keeping from the session becomes a stable wiki page. A memory trace is what remains after an experience ends. The session closes; the knowledge stays encoded in the vault.

### `/cortex-recall` — Query

The agent searches the vault, retrieves relevant pages, and synthesizes a response with citations. It can only return what was imprinted — if it's not in the vault, it doesn't exist for the system.

### `/cortex-prune` — Vault hygiene

Detects orphan pages, dead links, contradictory claims, stale information. Forgetting in the brain isn't a failure — it's maintenance. Prune does this deliberately: removes what weakens the network so what remains is more reliable.

### `/cortex-forge-setup` — Setup and configuration

Registers the vault and installs global skills. Run from inside a vault directory. Run again from the same vault to deregister.

## Wiki Taxonomy

| Type | Path | Purpose |
|------|------|---------|
| Concept | `wiki/concepts/` | Ideas, patterns, frameworks |
| Entity | `wiki/entities/` | People, tools, services |
| Source | `wiki/sources/` | Articles, docs, external references |
| Page | `wiki/pages/` | Active projects and decisions |
| Reference | `wiki/reference/` | Lookup tables, wire formats, cheat sheets |

**Concept vs Reference:** use Reference when the content is a table or code block you scan to find a specific value. Use Concept when understanding the idea requires reading prose.

Each page follows: YAML frontmatter + compiled truth + chronological changelog.

## Protocols

Three behaviors are mandatory for any agent operating the vault, defined in `AGENTS.md`:

**Crystallize** — before responding to the user, read `.cortex/MEMORY.md` and `AGENTS.md`. After milestones, invoke `/cortex-crystallize` to snapshot current state and append a history entry. This is mandated directly by `AGENTS.md` instructions — the same on every agent, with no dependency on lifecycle hooks.

**Assimilate** — when the user provides a URL, file, or uses words like "ingest" or "process", invoke `/cortex-assimilate` as the first action, no confirmation needed.

**Recall** — when the user asks about any topic that may exist in the vault, invoke `/cortex-recall` as the first action. Do not answer from active context or use `grep` as a substitute — the skill returns synthesized knowledge with citations. Agent training knowledge is disqualified for vault topics.

## Design rationale

Most agent-memory systems fail in the same places. These are the failure modes we found studying comparable projects, and the design decisions that answer them.

**There is only one reliable consumption channel, and it's not a hook.** Instructions in `AGENTS.md`, skill descriptions, and "the agent will remember to check" are best-effort — but so is lifecycle hook support: it varies too much across Claude Code, Codex, Antigravity, and CommandCode to be a foundation. Cortex Forge doesn't try to guarantee delivery via automatic injection; instead it makes the read/write contract explicit and identical everywhere — `AGENTS.md` mandates reading `.cortex/MEMORY.md` (hard size caps) before the first response, on every agent, with no hook wiring required. The guarantee comes from the protocol being unconditional and simple to follow, not from a mechanism only some agents support.

**State and lessons are different artifacts.** Session-end snapshots capture *state* (pending work, decisions, fragile context). Lessons — the workaround you'd otherwise re-explain next week — get lost because nobody archives them at the moment of fatigue. Cortex Forge splits the work across the session boundary: at session end, `/cortex-crystallize` (invoked manually, with full context) *flags* imprint candidates in the history entry. At the next session start, reading `.cortex/MEMORY.md` surfaces that flag and the agent proposes `/cortex-imprint` with fresh eyes. Detection happens where context is richest; the decision happens where judgment is freshest — no separate automation needed.

**Memory is attack surface.** A vault that auto-loads files nobody re-reads is exactly where injection payloads persist (see Microsoft's AI Recommendation Poisoning report, Feb 2026). Cortex Forge treats this structurally: `.raw/` is immutable so provenance is always auditable; ingestion scans foreign content for hidden Unicode, embedded payloads, and egress commands before it enters the vault *(sanitization landing in v0.4)*; and automated archiving defaults to *suggest* *(imprint pipeline landing in v0.4)* — a human approves before anything becomes ground truth. Convenience never outruns the isolation layer.

**Failed attempts are knowledge.** Session memory that only records what worked condemns the next session to retry what didn't. The hot cache contract records attempted-and-failed approaches, with evidence, as a first-class section *(landing in v0.4)*.

## Agent compatibility

Cortex Forge doesn't rely on agent lifecycle hooks (`SessionStart`, `PreCompact`, `SessionEnd`, `Stop`) — support for those events is too uneven across agents to build the suite on top of them. Instead, every agent works the same way, mandated by `AGENTS.md`:

| Agent | Session start | Session end |
|-------|--------------|-------------|
| Claude Code | Read `.cortex/MEMORY.md` per `AGENTS.md` | `/cortex-crystallize` invoked manually |
| Codex | Read `.cortex/MEMORY.md` per `AGENTS.md` | `/cortex-crystallize` invoked manually |
| Antigravity CLI | Read `.cortex/MEMORY.md` per `AGENTS.md` | `/cortex-crystallize` invoked manually |
| CommandCode | Read `.cortex/MEMORY.md` per `AGENTS.md` | `/cortex-crystallize` invoked manually |

No per-agent wire formats, no hook configuration, nothing to keep in sync across `settings.json`/`hooks.json` variants.

## Multi-vault

Skills resolve the target vault from wherever you are — no `cd` required. The global config at `~/.cortex-forge/config.yml` maps names to paths:

```yaml
vaults:
  personal: ~/second-brain
  work: ~/work-vault
default: personal
```

Skills resolve the vault automatically: if you're inside a registered vault → that vault; otherwise → `default`. Pass an explicit vault name as the first argument to override from anywhere:

```
/cortex-assimilate personal <url>
/cortex-recall work <query>
/cortex-crystallize personal
```

| Skill | Explicit vault arg |
|---|---|
| `/cortex-assimilate` | ✅ `/cortex-assimilate <vault-name> <url-or-file>` |
| `/cortex-recall` | ✅ `/cortex-recall <vault-name> <query>` |
| `/cortex-crystallize` | ✅ `/cortex-crystallize <vault-name> [project-name] [next: <focus>]` |
| `/cortex-imprint` | ✅ `/cortex-imprint <vault-name>` |
| `/cortex-prune` | ✅ `/cortex-prune <vault-name>` — asks for confirmation before proceeding |

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
3. Install all six skills globally (`~/.agents/skills/` + `~/.claude/skills/` symlinks for Claude Code)
4. Ask which vault to set as default if more than one is registered

After setup, all skills are available as `/cortex-assimilate`, `/cortex-crystallize`, `/cortex-imprint`, `/cortex-recall`, `/cortex-prune`, and `/cortex-forge-setup`.

**Alternative: install via [skills.sh](https://www.skills.sh/)** — every script a skill needs is co-located inside its own `skills/<name>/` directory, so each skill is fully self-contained and installable independently:

```bash
npx skills add itsmistermoon/cortex-forge --all
# or a specific skill:
npx skills add itsmistermoon/cortex-forge --skill cortex-prune
```

`/cortex-forge-setup` still works exactly the same afterward — it's a prompt-driven skill (no external script dependency), so it registers the vault in `~/.cortex-forge/config.yml` regardless of which installer brought it in.

## Platform compatibility

`/cortex-forge-setup` installs skills to `~/.agents/skills/` — the cross-platform convention adopted by most AI coding agents — and creates agent-specific symlinks where detected.

| Agent | Skills path (global) | Notes |
|---|---|---|
| Claude Code | `~/.agents/skills/` + `~/.claude/skills/` (symlinks) | Full support |
| Codex | `~/.agents/skills/` | — |
| Antigravity (Gemini CLI) | `~/.agents/skills/` | — |
| CommandCode | `~/.agents/skills/` | TASTE rule available via setup step 7 |
| Cursor | `.cursor/rules/` (project-local) | Not tested — copy `AGENTS.md` content to `.cursor/rules/cortex-forge.mdc` |
| Other agents | `~/.agents/skills/` | Check agent docs for skill resolution path |

**If your agent does not read `~/.agents/skills/` automatically:**
Copy `skills/cortex-*.md` (or the full skill folder, if your agent requires it) to your agent's configured skills path. `AGENTS.md` must always be present at the vault root regardless of agent — it's what makes session memory work the same way on every agent, without any hook configuration.

Run `/cortex-forge-setup skills` to reinstall skills only.

## Usage

Fork this repo and adapt it to your knowledge domain. The `skills/`, `templates/`, and `wiki/` structure is designed to be domain-agnostic — swap out the content, keep the architecture.

Fill in the `## Vault identity` section of `AGENTS.md` with your vault's mission, domains, vocabulary, and out-of-scope rules. Agents read this at session start to ground relevance and taxonomy decisions.

See `AGENTS.md` for the full operating protocol.

## Commit convention

```
protocol:  changes to AGENTS.md, skill steps, or compliance criteria
schema:    changes to template frontmatter or vault-report.json schema
feat:      new skill, new script, new document
fix:       incorrect instruction in a skill or broken script
docs:      README, prose, non-protocol documentation
chore:     dependency updates, tooling changes
refactor:  reorganization without contract change
```

`protocol:`, `schema:`, and `feat:` commits require a `CHANGELOG.md` entry.
`fix:` requires an entry only if it corrects a behavior agents were relying on.
`docs:`, `chore:`, and `refactor:` never require an entry.
