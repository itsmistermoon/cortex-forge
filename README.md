# cortex-forge

![cortex-forge](cortex-forge-promo.png)

A protocol for agent-operated knowledge vaults — six skills, one session layer, any LLM.

## What it is

Cortex Forge is a structured system for turning raw sources into synthesized, queryable knowledge. Agents operate the vault: they ingest, recall, and maintain. You define what matters and when to persist it.

The architecture works with any LLM agent — Claude Code, Codex, Antigravity, CommandCode — via a shared session file and a set of invocable skills.

## Architecture

Six layers, each with a distinct role:

| Layer | Path | Purpose | Rule |
|-------|------|---------|------|
| **Raw** | `.raw/` | Primary sources — immutable originals | Never modify |
| **Wiki** | `wiki/` | Secondary sources — synthesized knowledge | Agent writes and maintains |
| **Hot** | `.hot/` | Per-project session cache | Read on session start |
| **Codex** | `CODEX.md` | Vault identity: mission, owner, domains, vocabulary | Read on session start |
| **Meta** | `wiki/meta/` | Vault metadata and guides | Agent maintains |
| **Skills** | `skills/` | Invocable agent skills | Extend, don't modify |

`.raw/` is authoritative. `wiki/` is a derived view — cheaper to load, but lossy by construction. When they conflict, `.raw/` wins.

## Visualization

Open `wiki/` as an [Obsidian](https://obsidian.md) vault to get a live knowledge graph — nodes are pages, edges are `[[wikilinks]]`, clusters emerge from link density. No configuration needed. See `docs/obsidian-visualization.md`.

## Skills

Six skills that map to how knowledge actually moves through a system. All are globally invocable via `/skill-name` once installed.

### `/cortex-assimilate` — Ingest

Sources land in `.raw/`: articles, PDFs, transcripts, URLs. The agent processes them and produces structured wiki pages. The brain doesn't store what it perceives — it stores what it processes. Without this step, information enters the system in name only.

### `/cortex-crystallize` — Session context

Working memory lasts seconds. `.hot/MEMORY.md` extends it indefinitely: current state, active decisions, open threads. The agent reads it on session start; you invoke it at milestones. Without it, every conversation starts from zero. Works from any repo, not just the vault.

The file has two zones: a mutable `Current state` (max 5 pending items, max 3 active decisions) and an append-only `History`. Two triggers are supported — `PreCompact` (mid-session checkpoint, session continues) and `SessionEnd` (true handoff, no return path) — each producing an appropriately scoped summary via `claude -p`.

### `/cortex-imprint` — Permanent archive

What was worth keeping from the session becomes a stable wiki page. A memory trace is what remains after an experience ends. The session closes; the knowledge stays encoded in the vault.

### `/cortex-recall` — Query

The agent searches the vault, retrieves relevant pages, and synthesizes a response with citations. It can only return what was imprinted — if it's not in the vault, it doesn't exist for the system.

### `/cortex-prune` — Vault hygiene

Detects orphan pages, dead links, contradictory claims, stale information. Forgetting in the brain isn't a failure — it's maintenance. Prune does this deliberately: removes what weakens the network so what remains is more reliable.

### `/cortex-forge-setup` — Setup and configuration

Registers the vault, installs global skills, and configures lifecycle hooks. Run from inside a vault directory. Run again from the same vault to deregister.

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

**Crystallize** — before responding to the user, read `.hot/MEMORY.md` and `CODEX.md`. After milestones, invoke `/cortex-crystallize` to snapshot current state and append a history entry. Three automation levels: manual invocation, `AGENTS.md` instructions, or lifecycle hooks configured via `/cortex-forge-setup`.

**Assimilate** — when the user provides a URL, file, or uses words like "ingest" or "process", invoke `/cortex-assimilate` as the first action, no confirmation needed.

**Recall** — when the user asks about any topic that may exist in the vault, invoke `/cortex-recall` as the first action. Do not answer from active context or use `grep` as a substitute — the skill returns synthesized knowledge with citations. Agent training knowledge is disqualified for vault topics.

## Design rationale

Most agent-memory systems fail in the same places. These are the failure modes we found studying comparable projects, and the design decisions that answer them.

**There is only one reliable consumption channel.** Instructions in `AGENTS.md`, skill descriptions, and "the agent will remember to check" are all best-effort: agents ignore them often enough that anything critical cannot depend on them. The only channel an agent cannot ignore is unconditional injection at session start — and it's expensive in tokens, so it only scales for small content. Cortex Forge is built around this asymmetry: anything that must survive is distilled into the injected hot cache (`.hot/MEMORY.md`, hard size caps); everything else — wiki, skills — is consultable best-effort backup. The guarantee comes from the channel, not from the wording.

**State and lessons are different artifacts.** Session-end snapshots capture *state* (pending work, decisions, fragile context). Lessons — the workaround you'd otherwise re-explain next week — get lost because nobody archives them at the moment of fatigue. Cortex Forge splits the work across the session boundary *(landing in v0.4)*: at session end, crystallize (which already runs enforced, with full context) only *flags* imprint candidates with a pointer to the transcript. At the next session start, a cheap background subagent triages the flags with fresh eyes and proposes the archive. Detection happens where context is richest; the decision happens where judgment is freshest. No flags, zero overhead.

**Memory is attack surface.** A vault that auto-loads files nobody re-reads is exactly where injection payloads persist (see Microsoft's AI Recommendation Poisoning report, Feb 2026). Cortex Forge treats this structurally: `.raw/` is immutable so provenance is always auditable; ingestion scans foreign content for hidden Unicode, embedded payloads, and egress commands before it enters the vault *(sanitization landing in v0.4)*; and automated archiving defaults to *suggest* *(imprint pipeline landing in v0.4)* — a human approves before anything becomes ground truth. Convenience never outruns the isolation layer.

**Failed attempts are knowledge.** Session memory that only records what worked condemns the next session to retry what didn't. The hot cache contract records attempted-and-failed approaches, with evidence, as a first-class section *(landing in v0.4)*.

## Agent compatibility

Tested agents and their hook support:

| Agent | Session start | Session end | Status |
|-------|--------------|-------------|--------|
| Claude Code | `SessionStart` hook | `SessionEnd` + `PreCompact` (both synthesized via `claude -p`) | ✅ automatic |
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

Skills resolve the vault automatically: CWD inside a registered vault → that vault; otherwise → `default`. Register a vault by running `/cortex-forge-setup` from inside it.

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
4. Optionally configure lifecycle hooks for automatic session memory
5. Ask which vault to set as default if more than one is registered

After setup, all skills are available as `/cortex-assimilate`, `/cortex-crystallize`, `/cortex-imprint`, `/cortex-recall`, `/cortex-prune`, and `/cortex-forge-setup`.

## Platform compatibility

`/cortex-forge-setup` installs skills to `~/.agents/skills/` — the cross-platform convention adopted by most AI coding agents — and creates agent-specific symlinks where detected.

| Agent | Skills path (global) | Hook support | Notes |
|---|---|---|---|
| Claude Code | `~/.agents/skills/` + `~/.claude/skills/` (symlinks) | Auto (SessionStart, PreCompact, SessionEnd) | Full support |
| Codex | `~/.agents/skills/` | Manual — see setup step 6 | Hooks in `~/.codex/hooks.json` |
| Antigravity (Gemini CLI) | `~/.agents/skills/` | Manual — see setup step 6 | Hooks in `~/.gemini/config/hooks.json` |
| CommandCode | `~/.agents/skills/` | Manual (Stop hook) | TASTE rule available via setup step 7 |
| Cursor | `.cursor/rules/` (project-local) | Not tested | Copy `AGENTS.md` content to `.cursor/rules/cortex-forge.mdc` |
| Other agents | `~/.agents/skills/` | Varies | Check agent docs for skill resolution path |

**If your agent does not read `~/.agents/skills/` automatically:**
Copy `skills/cortex-*.md` (or the full skill folder, if your agent requires it) to your agent's configured skills path. `AGENTS.md` must always be present at the vault root regardless of agent.

Run `/cortex-forge-setup hooks` to reinstall hooks only.
Run `/cortex-forge-setup skills` to reinstall skills only.

## Usage

Fork this repo and adapt it to your knowledge domain. The `skills/`, `templates/`, and `wiki/` structure is designed to be domain-agnostic — swap out the content, keep the architecture.

Fill in `CODEX.md` with your vault's mission, domains, vocabulary, and out-of-scope rules. Agents read this at session start to ground relevance and taxonomy decisions.

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
