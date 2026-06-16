---
title: "OpenBrain (Nate B. Jones)"
type: entity
created: 2026-06-15
updated: 2026-06-15
tags: [memory-systems, mcp, pgvector, semantic-search, tool]
sources:
  - wiki/sources/openbrain.md
confidence: high
---

# OpenBrain (Nate B. Jones)

Personal semantic memory system created by Nate B. Jones. Postgres database (Supabase + pgvector) with an MCP server that lets any AI agent query and write to a personal knowledge base by meaning.

**Author:** Nate B. Jones — https://natebjones.com  
**Original guide:** https://natesnewsletter.substack.com/p/every-ai-you-use-forgets-you-heres  
**Notable fork:** RadixSeven/OpenBrain (privacy-first edition, replaces Slack with web form)

## Role in the vault

Studied as the canonical implementation of Level 6 memory (cross-platform semantic brain) from [[wiki/sources/yt-claude-code-memory-compared]]. Represents the opposite architectural pole from cortex-forge: cloud infrastructure + vector search vs filesystem + keyword/LLM reasoning.

## Key characteristics

- Core abstraction: `thoughts` table with `content` + `embedding` + `metadata` (JSONB)
- Multi-agent by design: any MCP client connects with URL + access key
- Per-key filter profiles: different agents see different subsets of the brain
- Deterministic post-LLM safety: `tag_rules` table strips conflicting visibility tags
- ~$0–0.30/month to run

## Connections

- Detailed breakdown: [[wiki/sources/openbrain.md]]
- Compared with cortex-forge: [[wiki/pages/cortex-forge]]
- Context: [[wiki/sources/yt-claude-code-memory-compared]]

---

- 2026-06-15 [Claude Code]: Entity created
