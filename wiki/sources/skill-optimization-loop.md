---
title: "Zach Lloyd — Building a skill optimization loop (replatformer)"
type: source
resource: https://github.com/warpdotdev-demos/replatformer
created: 2026-07-01
updated: 2026-07-01
source_author: Zach Lloyd (Warp)
tags: [skills, skill-optimization, observer-pattern, computer-use, evals, self-improvement]
aliases: []
confidence: high
schema_version: "0.3"
raw: .raw/skill-optimization-loop.md
---

# Zach Lloyd — Building a skill optimization loop (replatformer)

**Post:** https://x.com/zachlloydtweets/status/2069428152338665622
**Repo:** https://github.com/warpdotdev-demos/replatformer
**Author:** Zach Lloyd, Warp

## Summary

Demonstrates an **outer loop** skill optimization pattern: an "observer" skill that runs an inner skill against N examples, evaluates output quality with computer use + browser vision, and generates diffs to improve the inner skill. Skills are just files — any coding agent can apply the diff and open a PR.

## Inner vs outer loop

| Loop | Purpose |
|---|---|
| **Inner** | Make sure this specific run worked (per-execution quality gate) |
| **Outer** | Make the Skill itself more likely to work better next time (skill improvement) |

The outer loop is a meta-level operation: it treats the skill file as the artifact to improve, not the output of the skill.

## The observer skill pattern

The `replatforming-observer` skill:
1. Takes N sites as input
2. Calls `/replatform-site` on each
3. Builds generated sites locally
4. Examines source vs generated with **computer use + browser vision**
5. Tracks token counts
6. Synthesizes results with a SOTA model
7. Finds failure patterns
8. Generates a **diff** for the inner SKILL.md

The observer uses structured data results for intelligent failure analysis, and has baked-in exit criteria to avoid burning tokens optimizing forever.

## Replatformer architecture

```
.agents/skills/
├── replatform-site/          — Inner skill + references/ (progressive disclosure)
├── replatforming-observer/   — Outer loop: visual grader + diff generator
└── oz-orchestrated-replatforming/ — Cloud parallel execution driver (Oz/Warp)
```

Progressive disclosure: provider-specific and framework-specific details are in `references/`, not in SKILL.md, keeping core instructions concise.

## Key insight: skills are files

Skills are just Markdown files. Any coding agent can:
1. Read failure patterns from the observer
2. Generate a diff to the inner SKILL.md
3. Apply the diff and open a PR

This enables **automated skill improvement loops** for any skill with clear validation criteria (verifiable output, measurable quality signal).

## Limitations

- Susceptible to local maxima (the observer's feedback is bounded by its own perspective)
- Requires a platform with orchestration + computer use
- Less effective when quality is subjective (no grounding signal for the observer)

## Connections

- Concepts: [[wiki/concepts/skill-design-principles]], [[wiki/concepts/multi-agent-analysis-pipeline]]
- Related source: [[wiki/sources/anthropic-skill-creator]]
- Entity: `Warp` (agent used for orchestration; not yet in vault)

---

- 2026-07-01 [Claude Code]: Page created — Zach Lloyd's outer-loop skill optimization pattern, demonstrated via the replatformer skill suite
