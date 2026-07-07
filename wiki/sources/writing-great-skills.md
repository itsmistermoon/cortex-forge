---
title: "Matt Pocock — writing-great-skills (SKILL.md + GLOSSARY.md)"
type: source
resource: https://github.com/mattpocock/skills/tree/main/skills/productivity/writing-great-skills
created: 2026-07-01
updated: 2026-07-01
source_author: Matt Pocock
tags: [skills, agent-design, skill-quality, vocabulary, predictability]
aliases: []
confidence: high
schema_version: "0.3"
raw: .raw/writing-great-skills.md
---

# Matt Pocock — writing-great-skills (SKILL.md + GLOSSARY.md)

**URL:** https://github.com/mattpocock/skills/tree/main/skills/productivity/writing-great-skills
**Author:** Matt Pocock

## Summary

A reference skill (user-invoked, `disable-model-invocation: true`) that defines the vocabulary and principles for writing skills that are **predictable** — the agent taking the same *process* every run. The SKILL.md is itself all reference (no steps), demonstrating the pattern. GLOSSARY.md is the disclosed reference reached via a context pointer.

The root virtue: **Predictability** — not output determinism, but process determinism. A brainstorming skill should predictably diverge.

## Key concepts

### Two loads, two invocation modes

| Mode | Mechanism | Cost | When |
|---|---|---|---|
| Model-invoked | Description present | Context load (permanent) | Agent must fire it autonomously, or another skill must reach it |
| User-invoked | `disable-model-invocation: true` | Cognitive load (human memory) | Never fires except by hand |

- There is no model-only state: a description always includes user reach
- A **router skill** cures cognitive load when user-invoked skills multiply past what the human can remember

### Information hierarchy (three rungs)

1. **In-skill step** — in SKILL.md, primary; ends on a **completion criterion**
2. **In-skill reference** — in SKILL.md, secondary; consulted on demand
3. **External reference** — behind a context pointer; disclosed file (e.g., GLOSSARY.md) or external

**Progressive disclosure**: move reference down the ladder so the top stays legible. Branching is the disclosure test — inline what every branch needs, push behind a pointer what only some branches reach.

**Co-location**: keep a concept's definition, rules, and caveats under one heading, not scattered.

### Leading word

A compact concept already in the model's pretraining (_lesson_, _fog of war_, _tracer bullets_). Repeated as a token — never as a sentence — it accumulates a distributed definition and anchors a region of behaviour. Works twice:
- **Body**: anchors execution — same behaviour each time the word appears
- **Description**: anchors invocation — when the same word lives in your prompts and code, the model links it to the skill and fires more reliably

Opportunity: most skills carry restatements that a single leading word could retire. "Fast, deterministic, low-overhead" → *tight*. "A loop you believe in" → *red*.

### Completion criterion

The condition that tells the agent a step is done. Two axes:
- **Clarity** (checkable) — resists premature completion
- **Demand** (exhaustive) — drives legwork. "Every modified model accounted for" forces thorough work where "produce a change list" doesn't

Applies to flat reference too — "every rule applied" is a demand criterion on a skill with no steps.

### Failure modes

| Mode | Definition | Cure |
|---|---|---|
| Premature completion | Agent ends step before done; attention slips to *being done* | Sharpen completion criterion first; hide post-completion steps only if criterion is irreducibly fuzzy AND rush is observed |
| Duplication | Same meaning in more than one place | Single source of truth |
| Sediment | Stale content that accumulated because adding feels safe, removing feels risky | Pruning discipline |
| Sprawl | Skill too long even when every line is live and unique | Progressive disclosure + splitting |
| No-op | Instruction the model already follows by default | Delete (test: does it change behaviour vs default?) |

### When to split

- **By invocation**: split off a model-invoked skill when you have a distinct leading word to trigger it, or another skill must reach it. You pay context load for the new description.
- **By sequence**: split a run of steps when post-completion steps tempt premature completion. Hiding them in a separate context forces legwork on the current step.

## Applied to cortex-forge (2026-07-01 audit)

This skill was applied as a second audit pass over the cortex-forge skill suite. Findings resolved:
- Locale resolution block duplicated in 5 skills → extracted to LOCALE-RESOLUTION.md (progressive disclosure, single source of truth)
- `## When to invoke` sections removed (duplicated description)
- `cortex-imprint` manual-only enforcement moved from verbal to `disable-model-invocation: true` (mechanism over instruction)
- `## Rules` / `## Constraints` duplication resolved
- `cortex-prune` Spanish sediment removed
- `cortex-forge-setup` floating YAML block co-located with its step
- `cortex-crystallize` description updated to include model-invoked + user-invoked trigger phrases

## Connections

- Related concepts: [[wiki/concepts/skill-design-principles]], [[wiki/concepts/no-op-audit-adversarial-debate]], [[wiki/concepts/progressive-disclosure-hooks]]
- Source: [[wiki/sources/anthropic-skill-creator]]

---

- 2026-07-01 [Claude Code]: Page created — SKILL.md + GLOSSARY.md from mattpocock/skills; this source was applied as a second audit pass over cortex-forge skills same session
