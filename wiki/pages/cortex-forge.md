---
title: cortex-forge
type: project
created: 2026-06-08
updated: 2026-06-10
tags: [vault, multi-agent, hot-cache, hooks, knowledge-management]
status: active
repo: /Users/itsmistermoon/proyectos/cortex-forge
domains: [agent-orchestration, knowledge-management, multi-agent-protocols]
sources:
  - wiki/sources/commandcode-hooks-configuration.md
  - wiki/sources/codex-hooks.md
  - wiki/sources/antigravity-hooks.md
  - wiki/sources/ai-coding-dictionary.md
confidence: high
---

# cortex-forge

**Status:** active
**Repo:** /Users/itsmistermoon/proyectos/cortex-forge

## Goal

Vault with a hot cache protocol that synchronizes context across multiple agents (Claude Code, Codex, Antigravity, CommandCode) without token bloat at session start. Synthesized knowledge lives in `wiki/` (secondary sources); originals in `.raw/` (primary sources, immutable); ephemeral per-project context in `.hot/MEMORY.md`; vault identity in `CODEX.md`.

## Stack / Technologies

- 6 layers: `.raw/`, `wiki/`, `.hot/`, `CODEX.md`, `wiki/meta/`, `skills/`
- 5 wiki page types: concepts, entities, sources, projects, reference
- 6 vault skills: assimilate, recall, prune, imprint, crystallize, forge-setup
- Native hooks: PreCompact + SessionEnd (Claude Code), Stop (Antigravity) — bash scripts in `bin/hooks/`
- `AGENTS.md` fallback for agents without native session-start hooks (CommandCode, Codex pre-init)
- Templates co-located with their skills: `MEMORY-FORMAT.md`, `CODEX-FORMAT.md`, `TASTE-FORMAT.md`
- `AGENT-LOG.md` — append-only session bitácora (self-report per session, not per file)

## Key decisions

- **Layer 1 (AGENTS.md) + Layer 2 (native hooks)** are complementary. Layer 1 covers agents without a session-start hook; Layer 2 is more reliable when available.
- **`.hot/MEMORY.md` — fixed name per repo.** No project-name detection needed; each repo has its own `.hot/` directory (gitignored). Safe across multiple concurrent projects.
- **Two-zone MEMORY.md:** `## Current state` (mutable, max 5 pending / 3 decisions) + `## History` (append-only). Only Current state is reinjected at session start — History is available but not required.
- **PreCompact ≠ SessionEnd.** PreCompact is a mid-session compaction checkpoint (session continues); SessionEnd is a true handoff with no return path. Both use `claude -p` synthesis, but the prompt notes the distinction so the agent writes accordingly.
- **CODEX.md** — vault identity file (Mission, Owner, Domains, Vocabulary, Out of scope), read at session start after `.hot/MEMORY.md`. Empty sections are ignored; partial CODEX.md is valid.
- **Parametric knowledge disqualified** for vault topics. Agent training knowledge is unverified and unversioned — `cortex-recall` is mandatory even when the agent "knows" the answer.
- **`.raw/` is immutable primary source.** `wiki/` is always a derived secondary view. When they conflict, `.raw/` wins — the conflict rule is the remedy for **drift** (the primary changes, the account doesn't follow). The `raw:` frontmatter field on source pages is a **context pointer** back to the primary, and `bin/cortex-prune.sh` verifies it — the vault implemented the pattern before the vocabulary existed.
- **Reference taxonomy:** fifth wiki type for lookup tables, wire formats, cheat sheets — use when the content can be expressed as a table/code block without prose. Complements Concept (which requires explanation).
- **CommandCode wire format is nested** (`hooks: [{ matcher, hooks: [{ type, command, timeout? }] }]`), unlike the flat format of Claude Code/Codex. Hook scripts are not drop-in across agents.
- **Project pages only for user's own projects** — third-party entities go in `wiki/entities/`, not `wiki/pages/`.

## Next steps

- [ ] Validar `cortex-crystallize-antigravity.sh` en sesión real (flujo orgánico completo, no mock)
- [ ] Implementar PostToolUse como guardrail de plataforma (detección SPA + intercepción grep/find) — Roadmap Fase 2
- [ ] MOCs por área temática (Fase 3)

## Resolved

- [x] Verificar hook Stop de CommandCode en `second-brain/` — script degradaba silenciosamente con el wire format de CommandCode. Fix: `bin/hooks/cortex-crystallize-commandcode.sh` creado (no depende de transcript, no usa `claude -p`). Hook instalado en `second-brain/.commandcode/settings.local.json` (scope correcto) y corregido también en `cortex-forge/.commandcode/settings.local.json`. (2026-06-10, CommandCode)

## Knowledge applied

- [[wiki/concepts/agent-hook-compatibility]] — Lifecycle hook matrix per agent
- [[wiki/concepts/progressive-disclosure-hooks]] — Just-in-time context loading
- [[wiki/concepts/antigravity-hooks]] — Antigravity-specific hook configuration
- [[wiki/concepts/karpathy-wiki-pattern]] — Wikis optimized for LLM consumption
- [[wiki/concepts/handoff-artifact]] — .hot/MEMORY.md as handoff artifact; two-zone design
- [[wiki/concepts/memory-system]] — Pattern for making agents stateful across sessions
- [[wiki/concepts/smart-zone]] — Motivation for crystallize (session degradation over time)
- [[wiki/concepts/parametric-knowledge]] — Why training knowledge is disqualified for vault topics
- [[wiki/concepts/contextual-knowledge]] — What cortex-recall injects: verifiable, citable facts
- [[wiki/concepts/primary-source]] — `.raw/` as the vault's instance: immutable, complete, current by definition
- [[wiki/concepts/secondary-source]] — `wiki/` as the vault's instance: lossy/drift failure modes named; `raw:` field is the context-pointer remedy, conflict rule is the drift remedy

## Recurring issues

- `cortex-recall` compliance gap — agents fall back to manual search or parametric knowledge despite `MANDATORY` in `AGENTS.md`. Compliance criteria added to the protocol (2026-06-08) but root cause unresolved. May require PostToolUse guardrail to enforce.
- Codex hooks need a stable global path (e.g., `~/.codex/hooks/`) with runtime vault resolution. Vault-local paths break multi-vault and off-vault setups.
- Antigravity `cortex-crystallize-antigravity.sh` installed but not verified in a real organic session.
- CommandCode Stop hook: requiere `cortex-crystallize-commandcode.sh` (script dedicado, no comparte con Claude Code). Resuelto: script creado, hook instalado en second-brain y cortex-forge.

## Sources

- [[wiki/sources/commandcode-hooks-configuration]] — CommandCode wire format and scopes
- [[wiki/sources/codex-hooks]] — Codex lifecycle and trust
- [[wiki/sources/antigravity-hooks]] — Antigravity/Gemini CLI configuration
- [[wiki/sources/gemini-cli-hooks-video]] — Official hooks & skills video
- [[wiki/sources/ai-coding-dictionary]] — Vocabulary source: handoff, compaction, primary/secondary source, memory system

---

- 2026-06-08 [CommandCode / MiniMax-M3]: Page created retroactively — vault already active since 2026-06-07 but without a project page; consolidated to enable future project linking
- 2026-06-08 [Claude Code]: Translated to English
- 2026-06-08 [Claude Code]: Updated to reflect v0.1.0 state — CODEX.md layer, fixed MEMORY.md name, 5 wiki types, PreCompact/SessionEnd distinction, parametric knowledge decision, primary/secondary source taxonomy, co-located templates, updated next steps and recurring issues
- 2026-06-10 [Claude Code]: Linked primary-source/secondary-source concepts (full-article ingestion); adopted "context pointer" and "drift" vocabulary in the `.raw/` key decision
