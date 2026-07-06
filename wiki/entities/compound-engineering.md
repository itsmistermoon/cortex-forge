---
title: Compound Engineering
type: entity
created: 2026-07-01
updated: 2026-07-01
tags: [skills, plugin, agent-design, multi-harness, every-inc]
aliases: [compound-engineering-plugin, CE]
sources:
  - wiki/sources/compound-engineering-plugin.md
confidence: high
schema_version: "0.3"
---

# Compound Engineering

AI plugin for engineering work by Every Inc (Trevin Chow). 27 skills organized around a compound loop where each engineering cycle leaves behind learnings that make the next cycle cheaper. Cross-harness: Claude Code, [[wiki/entities/codex|Codex]], Cursor, Pi, OpenCode.

**Repo:** https://github.com/EveryInc/compound-engineering-plugin
**Stars:** 22,410 (2026-07-01)
**License:** MIT

## The compound loop

```
/ce-brainstorm → /ce-plan → /ce-work → /ce-simplify-code → /ce-code-review → /ce-compound → (repeat)
```

`/ce-compound` writes learnings to `docs/solutions/`. The next brainstorm and plan read these as grounding — the return arrow is the mechanism that makes it compound.

## Autonomous mode

`/lfg` after `/ce-brainstorm`: plan → work → simplify → review → fix → browser tests → commit → push → open PR → watch CI → repair until green. No human in the loop beyond the initial plan handoff.

## Architecture: skills-only (post June 2026)

**Before:** dedicated standalone agent definitions + skills. Broken across most harnesses outside Claude Code.

**After:** 27 skills, 0 standalone agents. Specialist behavior (code reviewer personas, research subagents) lives inside skills as **skill-local prompt assets** — co-located files in the skill's folder, not separate agent definitions.

This is the canonical example of the architectural insight: skills are a more portable primitive than standalone agents. A plugin can slot into any harness that supports skills; a plugin with standalone agents requires harness-specific agent support.

## Skill inventory (selected)

| Skill | Purpose |
|---|---|
| `/ce-ideate` | Generate grounded ideas before the loop starts |
| `/ce-strategy` | Create/maintain `STRATEGY.md` — read as grounding by ideate, brainstorm, plan |
| `/ce-brainstorm` | Interactive Q&A → requirements-only unified plan |
| `/ce-plan` | Enrich to implementation-ready plan with clear definition of done |
| `/ce-work` | Execute plans with worktrees and task tracking |
| `/ce-code-review` | Multi-agent review with cross-model adversarial pass |
| `/ce-compound` | Capture learnings into `docs/solutions/` |
| `/ce-debug` | Bug-path alternative to brainstorm→plan→work |
| `/lfg` | Full autonomous loop |

## Key design patterns visible in CE

1. **Skill-local prompt assets** — specialist behavior co-located in the skill folder, not separate agent definitions
2. **Unified plan document** — one artifact replaces two (requirements doc + implementation plan) to prevent drift
3. **Knowledge accumulation** (`/ce-compound`) — explicit loop-closing step that feeds the next iteration
4. **Cross-model adversarial review** — a second model tries to break the first model's work
5. **Central judgment before parallel dispatch** — `ce-resolve-pr-feedback` judges findings centrally before dispatching fixers (vs parallel fire-and-hope)

## Relevance to cortex-forge

CE's `/ce-compound` is the closest comparable to cortex-forge's `/cortex-imprint`: both capture session-produced knowledge as a permanent artifact that the next session reads as grounding. Key difference: CE stores learnings in `docs/solutions/` (project-scoped, code-adjacent); cortex-forge stores synthesized knowledge in `wiki/` (vault-scoped, agent-accessible).

The cross-model adversarial review pattern in `ce-code-review` is the same pattern as the adversarial audit applied to cortex-forge skills (see [[wiki/concepts/no-op-audit-adversarial-debate]]).

The skill-local prompt assets pattern is what cortex-forge uses with LOCALE-RESOLUTION.md and EMBEDDING-SETUP.md — co-located reference files that the skill discloses progressively.

## Relationships

- Concepts: [[wiki/concepts/skill-design-principles]], [[wiki/concepts/continuous-learning-loop]], [[wiki/concepts/no-op-audit-adversarial-debate]]
- Sources: [[wiki/sources/compound-engineering-plugin]]
- Comparable: [[wiki/projects/cortex-forge]] (`/cortex-imprint` ≈ `/ce-compound`)

---

- 2026-07-01 [Claude Code]: Page created — entity for Compound Engineering (Every Inc), post June 2026 architecture
