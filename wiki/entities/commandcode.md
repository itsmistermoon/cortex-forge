---
title: CommandCode
type: entity
created: 2026-06-08
updated: 2026-06-08
tags: [commandcode, agente, cli, coding-agent]
aliases: [cmd]
sources:
  - wiki/sources/commandcode-taste-blog.md
  - wiki/sources/commandcode-taste-docs.md
  - wiki/sources/commandcode-hooks-configuration.md
  - wiki/sources/commandcode-hooks-reference.md
confidence: high
schema_version: "0.3"
---

# CommandCode

AI coding agent with a CLI that integrates continuous personalization via TASTE. Shares the coding-first agent space with Claude Code, Codex, and [[wiki/entities/antigravity-cli|Antigravity CLI]].

## Identity

- **CLI**: `cmd` (alias `npx commandcode`)
- **Config project**: `.commandcode/settings.local.json`
- **Config global**: `~/.commandcode/`
- **Studio**: `commandcode.ai` — TASTE profile sync and remote skills
- **Auth**: commandcode.ai account

## Key capabilities

- **TASTE** — continuous personalization system: learns style preferences implicitly (accept/reject/edit) and persists them in `taste.md`. Underlying model: `taste-1`. See [[wiki/concepts/commandcode-taste]].
- **Skills** — markdown files in `.commandcode/skills/` or `~/.commandcode/skills/`
- **Rules** — manual user directives (layer on top of TASTE and skills)
- **Hooks** — Stop, SessionStart. Wire format: `{ hooks: [{ matcher, hooks: [{ type, command }] }] }`. See [[wiki/sources/commandcode-hooks-configuration]].
- **Plan mode** — skips hooks when active (`stop_hook_active` as anti-loop guard)

## Three-layer stack

| Layer | Source | Update |
|---|---|---|
| TASTE | Auto-learned | Each session, automatic |
| Skills | Written by user | Manual |
| Rules | Written by user | Manual |

## Relevance to cortex-forge

- The `cortex-forge-setup` skill installs a TASTE rule to invoke `/cortex-recall` automatically.
- CommandCode's Stop hook has scope restrictions: it must go in `{vault}/.commandcode/settings.local.json`, not in `cortex-forge/.commandcode/`. See [[wiki/concepts/agent-hook-compatibility]].

---

- 2026-06-08 [Claude Code]: Entity created from CommandCode TASTE + hooks sources
- 2026-06-08 [Claude Code]: Translated to English
