---
title: OpenHuman
type: entity
created: 2026-06-26
updated: 2026-06-26
tags: [agent-harness, memory, obsidian, open-source, comparable-project]
aliases: [openhuman, tinyhumansai/openhuman]
sources:
  - wiki/sources/openhuman.md
  - wiki/sources/openhuman-super-context.md
confidence: high
schema_version: "0.3"
---

# OpenHuman

Open-source agentic desktop assistant by @senamakel / tinyhumansai (33k stars, early beta). Its differentiating thesis is eliminating the "agent cold start" problem: rather than requiring weeks of passive use before the agent knows the user's context, OpenHuman pulls all connected data (Gmail, Notion, GitHub, Slack, Calendar, Drive, Linear, Jira — 118+ integrations via OAuth) on a 20-minute auto-fetch loop and canonicalizes it into a local Memory Tree: ≤3k-token Markdown chunks stored in SQLite, simultaneously available as `.md` files in a Karpathy-style Obsidian-compatible vault. Context is immediately available on the first session.

In this vault's context, OpenHuman is the closest known comparable project to Cortex Forge at the harness level. Both solve the agent cold-start problem via a local Karpathy-style Obsidian vault as a memory layer. The architectural approaches diverge significantly: OpenHuman is a full desktop application with managed integrations, automatic data ingestion, and harness-level context injection (SuperContext); Cortex Forge is a vault protocol that any CLI agent can operate via hooks, skills, and a structured wiki taxonomy, with knowledge synthesized manually from ingested sources.

## Relationships

- Comparable project: [[wiki/projects/cortex-forge]] — shared problem (agent memory / cold start), different architecture (harness app vs vault protocol)
- Concept origin: [[wiki/concepts/karpathy-wiki-pattern]] — both implement this pattern
- Concept: [[wiki/concepts/super-context]] — OpenHuman's harness-level context injection feature
- Related entity: [[wiki/entities/openbrain-nate-jones]] — also builds on local Postgres+pgvector; different scope (developer-only, MCP-first)
- Source: [[wiki/sources/openhuman]]
- Source (featured): [[wiki/sources/openhuman-super-context]]

---

- 2026-06-26 [Claude Code]: Entity created from GitHub README + SuperContext feature article
