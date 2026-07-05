---
title: "OpenHuman — GitHub README"
type: source
resource: https://github.com/tinyhumansai/openhuman
section: README
created: 2026-06-26
updated: 2026-06-26
timestamp: 2026-06-26
source_author: senamakel (tinyhumansai)
tags: [agent-harness, memory, obsidian, open-source, comparable-project]
confidence: high
schema_version: "0.3"
raw: .raw/openhuman.md
---

# OpenHuman — GitHub README

**URL:** https://github.com/tinyhumansai/openhuman
**Original date:** active (33k stars, early beta as of 2026-06-26)
**Author:** @senamakel / tinyhumansai

## Summary

OpenHuman is an open-source agentic assistant desktop app designed to integrate with daily life. Its core thesis: get to know the user in minutes rather than weeks by pulling all their data (email, calendar, repos, docs, messages) into a local Memory Tree — hierarchical ≤3k-token Markdown chunks stored in SQLite — and surfacing it as a Karpathy-style Obsidian vault. Includes 118+ one-click OAuth integrations with 20-minute auto-fetch loops, model routing, native voice (ElevenLabs TTS + mascot), and TokenJuice (up to 80% token reduction via HTML→Markdown compression, URL shortening, dedup).

## Key ideas

1. **Memory Tree + Obsidian vault** — local-first knowledge base; all connected data is canonicalized into ≤3k-token Markdown chunks scored and stored in SQLite on-device, simultaneously available as `.md` files in an Obsidian-compatible vault. Directly inspired by Karpathy's obsidian-wiki workflow. Functionally similar to Cortex Forge's `wiki/` layer + `.hot/MEMORY.md`, but fully automated from live integrations rather than agent-synthesized from ingested sources.

2. **SuperContext** — harness-level deterministic context injection: on the first turn of every new thread, a read-only `context_scout` sub-agent sweeps the Memory Tree and prepends a validated `[context_bundle]` to the user's message before the orchestrator model reads it. The model is never cold. Architecturally parallel to Cortex Forge's `SessionStart` hook injection from `.hot/MEMORY.md`, but implemented inside the harness rather than via an OS-level hook script.

3. **TokenJuice** — automatic token compression layer applied to every tool call result, scrape, email body, and search payload before any LLM sees it. HTML→Markdown, URL shortening, dedup/summarization via configurable rule overlays. Preserves CJK and multi-byte text grapheme-by-grapheme. Claims up to 80% token reduction.

4. **118+ integrations via Composio connector layer** — Gmail, Notion, GitHub, Slack, Stripe, Calendar, Drive, Linear, Jira. OAuth managed through OpenHuman's backend by default; direct Composio mode available. Auto-fetch runs every 20 minutes per active connection.

5. **agentmemory backend interop** — optional `memory.backend = "agentmemory"` config makes OpenHuman share a durable memory store with Claude Code, Cursor, Codex, and OpenCode. Enables cross-agent memory without coupling to OpenHuman's format.

## Connections

- Related concepts: [[wiki/concepts/karpathy-wiki-pattern]], [[wiki/concepts/memory-system]], [[wiki/concepts/tool-context-budget]], [[wiki/concepts/progressive-disclosure-hooks]], [[wiki/concepts/super-context]]
- Entities: [[wiki/entities/openhuman]]
- Projects: [[wiki/projects/cortex-forge]] — comparable project (agent-operated knowledge vault); key differences documented in that page's Key decisions section
- Related sources: [[wiki/sources/obsidian-mind]], [[wiki/sources/openbrain]], [[wiki/sources/openhuman-super-context]]

---

- 2026-06-26 [Claude Code]: Page created from GitHub README (raw: .raw/openhuman.md)
