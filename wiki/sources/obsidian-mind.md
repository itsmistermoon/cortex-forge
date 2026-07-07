---
type: source
title: "Obsidian Mind — persistent memory vault for coding agents"
resource: https://github.com/breferrari/obsidian-mind
created: 2026-06-12
updated: 2026-06-12
tags: [memory, hooks, obsidian, multi-agent, token-efficiency]
aliases: []
confidence: high
schema_version: "0.3"
raw: .raw/obsidian-mind.md
---

# Obsidian Mind — persistent memory vault for coding agents

**URL:** https://github.com/breferrari/obsidian-mind
**Author:** breferrari

## Summary

An Obsidian vault template that gives coding agents (Claude Code, Codex CLI, Gemini CLI) persistent memory. Same problem space as Cortex Forge, different emphasis: it targets the *work journal / performance tracking* use case (1:1s, incidents, brag doc, review season) rather than knowledge synthesis. Five lifecycle hooks in shared TypeScript handle classification, validation, and context injection; 18 slash commands and 9 subagents handle workflows.

## Key ideas

1. **Procedural code owns the environment, the agent owns content** — hooks do the deterministic work (classify, validate, index, inject); the agent does the judgment work (write, file, link). They meet at small handoffs.
2. **UserPromptSubmit as classifier** — every message is classified (decision, incident, win, 1:1, person, project update) by a lightweight Node call (~100 tokens) that injects *routing hints*, not content. See [[wiki/concepts/prompt-classification-hook]].
3. **PostToolUse as schema enforcer** — after every `.md` write, a hook validates frontmatter and checks for wikilinks ("a note without links is a bug"). Validation is procedural, not left to agent discipline.
4. **Explicit token tiers** — Always (~2K) / On-demand (semantic search) / Triggered (~100–200) / Rare (full reads). Same pattern as [[wiki/concepts/progressive-disclosure-hooks]], but with the budget made explicit per tier.
5. **MEMORY.md as pointer index, never storage** — Claude Code's auto-memory points to vault locations; durable knowledge lives in git-tracked `brain/` notes. Matches the context-pointer vocabulary Cortex Forge already adopted.
6. **Shared hook scripts across agents** — one set of TypeScript scripts (Node `--experimental-strip-types`), three thin config wrappers (`.claude/settings.json`, `.codex/hooks.json`, `.gemini/settings.json`). Contrast with Cortex Forge's one-shell-script-per-agent approach.
7. **QMD semantic search exposed via MCP** — optional SQLite index per vault; agent queries by meaning before reading files, with grep fallback when absent.
8. **PreCompact hook** backs up the session transcript before compaction — a lifecycle event Cortex Forge doesn't use yet.

## Connections
- Related concepts: [[wiki/concepts/prompt-classification-hook]], [[wiki/concepts/progressive-disclosure-hooks]], [[wiki/concepts/memory-system]], [[wiki/concepts/agent-hook-compatibility]], [[wiki/concepts/contextual-knowledge]]
- Projects: cortex-forge (comparable directo — mismo problema, distinto énfasis)

---

- 2026-06-12 [Claude Code]: Page created from README ingestion
