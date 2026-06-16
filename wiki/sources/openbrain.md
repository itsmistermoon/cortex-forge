---
title: "OpenBrain — Personal Semantic Memory with MCP"
type: source
created: 2026-06-15
updated: 2026-06-15
tags: [memory-systems, mcp, pgvector, embeddings, semantic-search, supabase]
source_url: https://github.com/RadixSeven/OpenBrain
source_author: Nate B. Jones (original); RadixSeven (fork with privacy improvements)
sources:
  - .raw/openbrain-guide.md
confidence: high
---

# OpenBrain — Personal Semantic Memory with MCP

**Original author:** Nate B. Jones — https://natebjones.com  
**Original guide:** https://natesnewsletter.substack.com/p/every-ai-you-use-forgets-you-heres  
**Fork studied:** https://github.com/RadixSeven/OpenBrain (privacy-first edition)  
**Video:** https://www.youtube.com/watch?v=2JiMmye2ezg

## What it is

A self-hosted personal knowledge system where you capture thoughts via a web form, and any AI agent can query your brain by meaning via MCP. Core idea: one Postgres database (Supabase) with pgvector, one MCP server (Supabase Edge Function), any agent plugs in with a URL and a key.

Positioned in [[wiki/sources/yt-claude-code-memory-compared]] as **Level 6** — the most future-proof architecture because it's multi-agent, not tied to any single tool.

## Stack

| Layer | Technology |
|-------|-----------|
| Storage | Supabase (PostgreSQL) |
| Vector search | pgvector extension (`vector(1536)`) |
| Embeddings | OpenRouter → text-embedding-3-small |
| Metadata extraction | OpenRouter → gpt-4o-mini (or newer) |
| Capture form | GitHub Pages (static HTML) |
| MCP server | Supabase Edge Function |
| Auth | Per-key filter profiles in `access_keys` table |

## Database schema (core)

### `thoughts` table

The central storage unit. Every thought has:
- `content` — raw text
- `embedding` — 1536-dim vector for semantic search
- `metadata` — JSONB with LLM-extracted fields: `type`, `topics`, `people`, `action_items`, `dates_mentioned`, `visibility`
- `submitted_by` + `evidence_basis` — provenance trail (who captured it, how)
- `visibility_verified_by_human_at` — NULL = LLM classification unverified by a human

### `access_keys` table

Each key has a `filters` JSONB profile. `{}` = see everything. `{"visibility":["sfw"]}` = only thoughts tagged sfw. Multiple agents can have different keys with different scopes. Keys are revocable individually.

### `tag_rules` table

Post-LLM deterministic safety layer. Seeded rules: `romance → remove sfw`, `sexuality → remove sfw`, `health → remove sfw`, `financial → remove sfw`. The LLM might accidentally tag a sensitive thought as sfw — tag rules strip it before storage, no redeployment needed.

### `prompt_templates` + `current_prompt` tables

Version-tracked prompts. Edge functions read the active prompt from the DB at runtime. Swap prompts by inserting a new row — no code deploy.

## Key SQL functions

- **`match_thoughts`** — semantic search via cosine distance (`<=>` operator), with visibility filtering
- **`list_thoughts_filtered`** — keyword/attribute filtering (type, topic, person, date range, regex), no embeddings needed
- **`validate_access_key`** — validates key, updates `last_used_at`, returns filter profile

## Capture pipeline

```
Web form → Edge Function → OpenRouter (embed + classify) → tag_rules → thoughts table
```

LLM extraction returns: `type` (observation/task/idea/reference/person_note), `topics[]`, `people[]`, `action_items[]`, `dates_mentioned[]`, `visibility[]`.

## MCP interface

- Transport: HTTP, hosted on Supabase Edge Functions
- Auth: `x-brain-key` header or `?key=` query param (for clients without header support)
- Tools exposed:
  - `search_thoughts` — semantic similarity search
  - `list_thoughts` — filtered listing
  - `add_thought` — write a thought directly from the agent

## Privacy model

Original OpenBrain used Slack as capture channel. This fork replaces it with a private password-protected web form. Key additions:
- Multiple access keys with independent filter profiles
- Tag rules engine as deterministic post-LLM privacy enforcement
- Row Level Security (service role only)
- `visibility_verified_by_human_at` for audit

## Cost

~$0.10–0.30/month for 20 thoughts/day. Supabase free tier + GitHub Pages free tier; only cost is OpenRouter tokens.

## Comparison with cortex-forge

| Dimension | OpenBrain | cortex-forge |
|-----------|-----------|--------------|
| Architecture | Postgres + pgvector + MCP server | Files + hooks + hot cache |
| Retrieval | Semantic (embedding similarity) | Keyword + LLM reasoning over wiki |
| Multi-agent | Yes (any MCP client) | Yes (any agent reading shared files) |
| Infrastructure | Supabase + OpenRouter (cloud) | Zero — filesystem only |
| Setup cost | ~45 min + $5 OpenRouter credits | Zero |
| Maintenance | DB migrations, edge functions | None beyond file edits |
| Vault size sweet spot | Large (thousands of thoughts) | Small-medium (hundreds of pages) |

## Connections

- Referenced in: [[wiki/sources/yt-claude-code-memory-compared]] (Level 6)
- Related concept: [[wiki/concepts/memory-system]]
- Related entity: [[wiki/entities/openbrain-nate-jones]]
- Related concepts: [[wiki/concepts/iterative-retrieval]]

---

- 2026-06-15 [Claude Code]: Page created — ingested from RadixSeven/OpenBrain (fork of Nate B. Jones original); covers schema, MCP interface, capture pipeline, and privacy model
