# OpenBrain — Complete Setup Guide (Privacy-First Edition)

Source: https://github.com/RadixSeven/OpenBrain (fork of Nate B. Jones original)
Original author: Nate B. Jones — https://natebjones.com
Fork author: RadixSeven (minor improvements, Slack replaced by private web form)
Fetched: 2026-06-15

## What Is OpenBrain

A personal knowledge system with semantic search and an open MCP protocol.
You type a thought → it gets embedded + classified by LLM → stored in Postgres (Supabase).
An MCP server exposes the brain to any AI assistant via semantic search and direct write.

## Stack

- **Supabase** (PostgreSQL + pgvector extension): storage, embeddings, edge functions, RLS
- **OpenRouter**: AI gateway for embeddings (text-embedding-3-small) and metadata extraction (gpt-4o-mini)
- **GitHub Pages**: static HTML capture form
- **MCP server**: hosted on Supabase Edge Functions; any MCP-compatible agent connects with URL + key

## Database Schema

### Table: `thoughts`
Core storage unit.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | PK, auto-generated |
| content | text | Raw thought text |
| embedding | vector(1536) | pgvector embedding for semantic search |
| metadata | jsonb | LLM-extracted: type, topics, people, action_items, dates_mentioned, visibility |
| submitted_by | text | 'user' or agent name |
| evidence_basis | text | Provenance: 'user typed in web form', 'dictated via MCP', etc. |
| created_at | timestamptz | |
| updated_at | timestamptz | |
| visibility_verified_by_human_at | timestamptz | NULL = unverified |

### Table: `access_keys`
Multi-key authentication for MCP server. Each key maps to a filter profile.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | PK |
| name | text | Human label: 'work-copilot', 'personal-claude' |
| key | text | Random hex secret |
| filters | jsonb | `{}` = no restriction; `{"visibility":["sfw"]}` = only sfw thoughts |
| active | boolean | Revocable |
| last_used_at | timestamptz | Audit trail |

### Table: `tag_rules`
Deterministic post-LLM safety layer. If a thought has tag A, strip tag B.

Seeded rules: romance→remove sfw, sexuality→remove sfw, health→remove sfw, financial→remove sfw.

### Tables: `prompt_templates` + `current_prompt`
Version-tracked prompts. Edge functions read the active prompt from DB at runtime — no redeployment needed to swap prompts.

## Key Functions (PostgreSQL)

### `match_thoughts(query_embedding, match_threshold, match_count, filter, visibility_filter)`
Semantic similarity search using cosine distance (`<=>` operator).
Returns rows ordered by similarity, filtered by visibility_filter (OR logic via `?|`).

### `list_thoughts_filtered(result_count, filter_type, filter_topic, filter_person, filter_days, content_pattern, visibility_filter)`
Keyword/attribute filtering without embeddings. Uses Postgres native `~*` regex (injection-safe via parameterized query).

### `validate_access_key(raw_key)`
Validates key, updates `last_used_at`, returns `(key_id, key_name, filters)`.

## Capture Pipeline (Part 1)

1. User types thought in GitHub Pages HTML form
2. Form POSTs to Supabase Edge Function (`capture`)
3. Edge function calls OpenRouter for:
   - Embedding (text-embedding-3-small, 1536 dims)
   - Metadata extraction (LLM classifies type, topics, people, action_items, visibility)
4. Tag rules engine strips conflicting visibility tags
5. Thought stored in `thoughts` table

## Retrieval + MCP (Part 2)

- MCP server is a Supabase Edge Function
- Authentication: `x-brain-key` header (or `?key=` query param for clients that don't support headers)
- Each key has a filter profile → controls which thoughts the agent can see/write
- MCP tools exposed: `search_thoughts` (semantic), `list_thoughts` (filtered), `add_thought` (write)
- Any MCP-compatible client connects with URL + key: Claude Desktop, Claude Web, ChatGPT, etc.

## Privacy Model

- No Slack dependency (original used Slack as capture channel)
- Multiple access keys with independent filter profiles (work key only sees `sfw` thoughts)
- Tag rules engine enforces privacy constraints deterministically, post-LLM
- Row Level Security: service role only; all access goes through validated keys
- `visibility_verified_by_human_at` tracks unverified LLM classifications

## Cost

~$0.10–0.30/month for 20 thoughts/day (embeddings + LLM metadata extraction via OpenRouter).
Supabase free tier, GitHub Pages free tier.

## Original Source

Nate B. Jones's original guide: https://natesnewsletter.substack.com/p/every-ai-you-use-forgets-you-heres
Video: https://www.youtube.com/watch?v=2JiMmye2ezg
Fork with privacy improvements: https://github.com/RadixSeven/OpenBrain
