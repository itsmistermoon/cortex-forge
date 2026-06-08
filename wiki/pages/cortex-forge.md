---
title: cortex-forge
type: project
created: 2026-06-08
updated: 2026-06-08
tags: [vault, multi-agent, hot-cache, hooks, knowledge-management]
status: active
repo: /Users/itsmistermoon/proyectos/cortex-forge
domains: [agent-orchestration, knowledge-management, multi-agent-protocols]
sources:
  - wiki/sources/commandcode-hooks-configuration.md
  - wiki/sources/codex-hooks.md
  - wiki/sources/antigravity-hooks.md
confidence: high
---

# cortex-forge

**Status:** active
**Repo:** /Users/itsmistermoon/proyectos/cortex-forge

## Goal

Vault with a hot cache protocol that synchronizes context across multiple agents (Claude Code, Codex, Antigravity, CommandCode) without token bloat at session start. Synthesized knowledge lives in `wiki/`; ephemeral per-project context lives in `.hot/{project}.md`; originals in `.raw/`.

## Stack / Technologies
- 5 layers: `.raw/`, `wiki/`, `.hot/`, `wiki/meta/`, `skills/`
- 4 wiki page types: concepts, entities, sources, projects
- 6 vault skills: assimilate, recall, prune, imprint, crystallize, forge-setup
- Native hooks (Stop/SessionStart) + `AGENTS.md` fallback (Layer 1) for agents without a session-start hook
- Portable bash scripts: `load-hot-cache*.sh` (input) and `update-hot-cache*.sh` (output)

## Key decisions

- **Layer 1 (AGENTS.md) + Layer 2 (native hooks)** are complementary, not exclusive. Layer 1 covers agents without a session-start hook (CommandCode); Layer 2 is more reliable.
- **Hot cache cuts at `## History`** — only `## Current state` is injected into context. Decision made 2026-06-08 after observing that History filled tokens without operational value.
- **CommandCode's official wire format is nested** (`hooks: [{ matcher, hooks: [{ type, command, timeout? }] }]`), unlike the flat format used by Claude Code/Codex. Hot cache scripts are not drop-in across agents.
- **Project pages only for user's own projects** — third-party entities (Understand Anything, Antigravity) go in `entities/`, not `pages/`.
- **Do not retrowrite `.raw/`** — it is immutable. Any correction goes in the wiki page that references it.

## Next steps

- [ ] Re-test Antigravity CLI with Layer 2 verified in a real session
- [ ] Re-test CommandCode as a control experiment post-Layer 1
- [ ] Run `/understand-knowledge` on the vault itself (graph of `wiki/`)
- [ ] Resolve Phase 1 ROADMAP.md pending items for each agent
- [ ] MOCs by thematic area (Phase 3)

## Knowledge applied

- [[wiki/concepts/agent-hook-compatibility]] — Lifecycle hook matrix per agent
- [[wiki/concepts/progressive-disclosure-hooks]] — Just-in-time context loading
- [[wiki/concepts/antigravity-hooks]] — Antigravity-specific configuration
- [[wiki/concepts/karpathy-wiki-pattern]] — Wikis optimized for LLM consumption
- [[wiki/concepts/treesitter-llm-hybrid-parsing]] — Deterministic parser + LLM for interpretations
- [[wiki/concepts/multi-agent-analysis-pipeline]] — Orchestration of N specialized agents

## Recurring issues

- `cortex-recall` fails in all agents tested during session — they fall back to manual search despite MANDATORY in `AGENTS.md`. Root cause pending diagnosis.
- Codex hooks point to `~/.claude/hooks/` by pending convention; functional but not idiomatic.
- Antigravity Layer 2 installed but not verified in a real session.

## Sources

- [[wiki/sources/commandcode-hooks-configuration]] — CommandCode wire format and scopes
- [[wiki/sources/codex-hooks]] — Codex lifecycle and trust
- [[wiki/sources/antigravity-hooks]] — Antigravity/Gemini CLI configuration
- [[wiki/sources/gemini-cli-hooks-video]] — Official hooks & skills video
- [[wiki/sources/understand-anything]] — Knowledge graph pattern

---

- 2026-06-08 [CommandCode / MiniMax-M3]: Page created retroactively — vault already active since 2026-06-07 but without a project page; consolidated to enable future project linking
- 2026-06-08 [Claude Code]: Translated to English
