# cortex-forge

A protocol for agent-operated knowledge vaults — five skills, one session layer, any LLM.

## What it is

Cortex Forge is a structured system for turning raw sources into synthesized, queryable knowledge. Agents operate the vault: they ingest, recall, and maintain. You define what matters and when to persist it.

The architecture works with any LLM agent — Claude Code, Codex, Gemini, Cursor — via a shared session file and a set of invocable skills.

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

Five skills that map to how knowledge actually moves through a system:

### `cortex-assimilate` — Ingest

Sources land in `.raw/`: articles, PDFs, transcripts, URLs. The agent processes them and produces structured wiki pages. The brain doesn't store what it perceives — it stores what it processes. Without this step, information enters the system in name only.

### `cortex-crystallize` — Session context

Working memory lasts seconds. `.hot/{project}.md` extends it indefinitely: current state, active decisions, open threads. The agent reads it on session start; you invoke it at the end. Without it, every conversation starts from zero.

### `cortex-imprint` — Permanent archive

What was worth keeping from the session becomes a stable wiki page. A memory trace is what remains after an experience ends. The session closes; the knowledge stays encoded in the vault.

### `cortex-recall` — Query

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

## Protocol Specs

- **[Hot Cache Protocol](docs/hot-cache-protocol.md)** — Session memory and multi-agent coordination: how `.hot/{project}.md` works, hook compatibility table (Claude Code, Codex, Antigravity), and graceful degradation across agents.

## Usage

Fork this repo and adapt it to your knowledge domain. The `skills/`, `templates/`, and `wiki/` structure is designed to be domain-agnostic — swap out the content, keep the architecture.

See `AGENTS.md` for agent operating rules.
