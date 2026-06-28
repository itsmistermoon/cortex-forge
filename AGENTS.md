---
schema_version: "0.3"
---

# AGENTS.md — cortex-forge

## Vault identity

**locale**: en — locale for agent-generated content (hot cache entries, skill acknowledgments).

**Vocabulary:**
- **hot cache**: session memory per project (`.cortex/`), not persistent knowledge
- **vault**: a knowledge base managed by Cortex Forge, not a password manager

## Crystallize protocol — MANDATORY

`.cortex/MEMORY.md` exists in this vault. It has two zones: a mutable `Current state` (`### Pending` items and `### Active decisions`) and an append-only `History` of session snapshots. Both must inform every session.

**Before your first response to the user, in any session that starts in this vault, you MUST:**

1. Read `.cortex/MEMORY.md` in full.
2. If `.cortex/PRAXIS.md` exists, read it — it provides accumulated agent context (structural conventions and working context) that grounds decisions for the session.
3. If `wiki/meta/vault-report.json` exists, read it. If `health.dead_links`, `health.raw_without_source_page`, or `health.orphan_pages` is non-empty, surface these to the user in your first message as actionable issues — not background noise.
4. Treat all of the above as required context — not optional background.
5. If `MEMORY.md` contains `### Pending` items, acknowledge them in your first message or surface them before starting new work.

**Failure to load hot cache before first response is a protocol violation**, equivalent to ignoring `CLAUDE.md` in Claude Code.

**After milestones**, invoke `/cortex-crystallize` to snapshot progress back into `.cortex/MEMORY.md`. The entire `.cortex/` directory is gitignored — it's a local agent artifact, not versioned content.

**Compliance criterion:** after invoking `/cortex-crystallize`, confirm what changed — state which items moved to Current state and what was appended to History. If the session produced analysis or synthesis worth persisting, propose `/cortex-imprint` before closing.

## Assimilate protocol — MANDATORY

**When the user provides a URL, file path, or uses phrases like "ingest", "process", "add source", "add content", you MUST invoke `cortex-assimilate` as your first action — no confirmation needed.**

The skill accepts two input modes:
- **URL** — agent downloads content, saves to `.raw/`, synthesizes
- **`.raw/` file** — agent reads the file and synthesizes directly

See full creation/omission criteria in `skills/cortex-assimilate.md`.

**Compliance criterion:** after completing ingestion, your response must confirm: (1) `.raw/` file path saved, (2) wiki pages created or updated. If the URL returned HTML with no readable body text, declare `SPA detected` before attempting content extraction — never save an empty HTML shell to `.raw/`. If extraction fails after the SPA fallback, tell the user explicitly and stop.

## Recall protocol — MANDATORY

**Parametric knowledge** is what you know from training. It is unverified, unversioned, and may contradict what this vault has synthesized. For any topic this vault may cover, parametric knowledge is not a valid source — the vault is.

**When the user asks about any topic that may exist in the vault — concepts, sources, agents, tools, past analysis, or anything previously ingested — you MUST invoke `cortex-recall` as your first action.**

This applies even if:
- The content was ingested earlier in this same session (do not answer from active context).
- You could find the answer with `grep` or `find` (manual search is a protocol violation).
- You believe you already know the answer — that belief is parametric knowledge, which is disqualified.

Trigger phrases include: "what does the vault say about", "recall", "what do we know about", "is this documented", "what was ingested about", or any question about a topic covered in `wiki/`.

**Do not use `grep`, `find`, `Explore`, or direct file reads as a substitute for `cortex-recall`.** Those tools do text matching; `cortex-recall` runs semantic vector search over the embedding index in `.cortex/db/` (1800+ indexed chunks) and returns synthesized knowledge with citations. They are not equivalent.

**Compliance criterion:** every response that draws on vault knowledge must include at least one citation to a `wiki/` page with its `confidence:` value appended. If `cortex-recall` is unavailable in this session, declare it explicitly before answering — do not answer as if recall occurred.

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
- `/cortex-crystallize` — Snapshot session context into `.cortex/MEMORY.md`, works from any repo
- `/cortex-forge-setup` — Initial setup: configure vault path and install global skills

## Vault architecture

Six layers, each with a distinct role:

| Layer | Path | Purpose | Rule |
|-------|------|---------|------|
| **Raw** | `.raw/` | Primary sources — immutable originals (articles, docs, transcripts) | Never modify |
| **Wiki** | `wiki/` | Secondary sources — synthesized knowledge; one step removed from primaries | Agent writes and maintains |
| **Hot** | `.cortex/` | Per-project session cache (MEMORY.md, PRAXIS.md) and semantic search DB (`db/`) | Read on session start, write via /cortex-crystallize |
| **Meta** | `wiki/meta/` | Vault metadata and guides | Agent maintains |
| **Skills** | `skills/` | Invocable agent skills | Extend, don't modify |
| **Docs** | `docs/` | Design notes, protocol rationale, resilience proposals | Reference before implementing changes |

`.raw/` is the authoritative record. `wiki/` is always a derived view — cheaper to load, but lossy by construction, and subject to drift (the primary changes, the account doesn't follow). When they conflict, `.raw/` wins. Every source page carries a **context pointer** back to its original — the `raw:` frontmatter field; follow it whenever the synthesized account isn't enough.

See `CHANGELOG.md` for protocol version history (current: **0.3**). When operating in a vault that may have been created before a recent protocol change, check the changelog to identify missing fields or behaviors. Pages with `schema_version` lower than the current protocol version may be missing fields introduced after their creation.

## Wiki taxonomy

| Type | Path | Purpose | Template |
|------|------|---------|----------|
| **Concept** | `wiki/concepts/` | Ideas, patterns, frameworks | `templates/concept.md` |
| **Entity** | `wiki/entities/` | People, tools, services | `templates/entity.md` |
| **Source** | `wiki/sources/` | Articles, docs, external references | `templates/source.md` |
| **Page** | `wiki/pages/` | Active projects with repo and status | `templates/project.md` |
| **Reference** | `wiki/reference/` | Lookup tables, wire formats, cheat sheets | `templates/reference.md` |

**Reference vs Concept:** use Reference when the content is a table, code block, or checklist you scan in seconds to find a specific value. Use Concept when understanding the idea requires reading prose. If in doubt: does it need explanation to be useful? → Concept. Can it be expressed as a table or code block alone? → Reference.

Each page follows: YAML frontmatter + compiled truth + chronological changelog. **All wiki content must be written in English** — this is a public repo.

### Source frontmatter fields

| Field | Required | Description |
|-------|----------|-------------|
| `type` | yes | Always `source` |
| `title` | yes | Display name of the source |
| `resource` | yes | Canonical URI of the original resource (OKF-aligned; replaces former `source:`) |
| `fetched` | yes | Date this source was ingested into the vault (`YYYY-MM-DD`) |
| `timestamp` | recommended | Publication or last-known-accurate date of the resource (OKF-aligned) |
| `source_author` | recommended | Author(s) of the original resource |
| `tags` | recommended | Cross-cutting categorization strings |
| `confidence` | yes | `high` (primary source) · `medium` (blog, video) · `low` (inference) |
| `schema_version` | yes | Protocol version this page was written against |
| `raw` | yes | Path to the immutable primary source in `.raw/` |
| `section` | optional | Grouping label for multi-part sources from the same origin (e.g. `Antigravity CLI`) |

## On session close

Before `/cortex-crystallize`, evaluate whether the session produced analysis, design decisions, or synthesis worth persisting. If so, suggest `/cortex-imprint` — never archive without explicit confirmation. Add an entry to `wiki/meta/log.md` for each significant operation.
