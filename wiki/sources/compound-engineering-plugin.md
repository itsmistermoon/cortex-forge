---
title: "Compound Engineering Plugin — README + June 2026 update"
type: source
resource: https://github.com/EveryInc/compound-engineering-plugin
created: 2026-07-01
updated: 2026-07-01
source_author: Every Inc (Trevin Chow)
tags: [skills, agent-design, skill-architecture, plugin-design, multi-harness]
confidence: high
schema_version: "0.3"
raw: .raw/compound-engineering-plugin.md
---

# Compound Engineering Plugin — README + June 2026 update

**URL:** https://github.com/EveryInc/compound-engineering-plugin
**Author:** Every Inc, Trevin Chow (CTO)
**Stars:** 22,410 (2026-07-01)
**Update post:** @trevin on X, 2026-06-26

## Summary

Compound Engineering is an AI plugin that implements a "compound loop" for engineering work: each cycle leaves behind knowledge that makes the next cycle easier. 27 skills, 0 standalone agents (post June 2026 architecture change), cross-harness compatible.

## The compound loop

```
brainstorm → plan → work → simplify → review → compound → (repeat)
```

`/ce-compound` writes learnings to `docs/solutions/` that the next `/ce-brainstorm` and `/ce-plan` read as grounding. The return arrow — compounding — is the whole point.

## June 2026 architectural shift: agents → skill-local prompt assets

**Before:** dedicated standalone agent definitions (great in Claude Code, broken across Codex/Cursor/Gemini/Pi/OpenCode)

**After:** every skill is self-contained; specialist behavior lives in skill-local prompt assets, not formal agent definitions

**Key insight:** standalone agent definitions are not a reliable cross-harness denominator. Skills are. A skills-only plugin can slot into any plugin system; a plugin with standalone agents requires harness-specific agent support.

**Practical effects:**
- Codex CLI + Codex desktop: works cleanly, including as full plugin with auto-updates
- OpenCode, Pi, Cursor: much better native support
- No "you need to re-run setup after updating"

## Unified plan document

Previously: two documents (requirements doc + implementation plan) that drift from each other.

**Now:** one unified plan document.
- `/ce-brainstorm` produces requirements
- `/ce-plan` enriches it into an implementation-ready plan
- One doc has a clear definition of done + bounded scope + explicit implementation approach

At end of `/ce-plan`, offers option to feed the plan into `/goal` for autonomous execution. In testing: 6-hour multi-agent runs that implemented features fully, wrote tests, opened PRs, and shipped with no human in the loop beyond the initial plan handoff.

## `/lfg` — full autonomous loop

After `/ce-brainstorm`, run `/lfg` for hands-off execution: plan → work → simplify → code review → apply fixes → browser tests → commit → push → PR → watch CI → repair until green.

## Architecture

See [[wiki/entities/compound-engineering]] for the full skill inventory and entity entry.

## Connections

- Entity: [[wiki/entities/compound-engineering]]
- Related concepts: [[wiki/concepts/skill-design-principles]], [[wiki/concepts/continuous-learning-loop]]
- Related source: [[wiki/sources/skill-optimization-loop]]

---

- 2026-07-01 [Claude Code]: Page created — README + June 26 2026 architectural update from Every Inc
