---
title: "Anthropic — skill-creator SKILL.md"
type: source
resource: https://github.com/anthropics/claude-plugins-official/tree/main/plugins/skill-creator/skills/skill-creator
created: 2026-07-01
updated: 2026-07-01
source_author: Anthropic
tags: [skills, agent-design, evals, skill-optimization, claude-code]
confidence: high
schema_version: "0.3"
raw: .raw/anthropic-skill-creator.md
---

# Anthropic — skill-creator SKILL.md

**URL:** https://github.com/anthropics/claude-plugins-official/tree/main/plugins/skill-creator/skills/skill-creator
**Author:** Anthropic
**Part of:** claude-plugins-official (official Anthropic plugin repo)

## Summary

Anthropic's official skill for creating and iteratively improving other skills. Covers the full lifecycle: capture intent → interview → draft → run evals → review → improve → repeat. Includes a description optimization loop that uses 60/40 train/test splits and automated triggering tests to improve how reliably the model fires a skill.

## Skill creation process

1. **Capture intent** — extract from current conversation first, then fill gaps with the user. Key questions: what should Claude do, when should it trigger, expected output format, need for test cases.
2. **Interview and research** — edge cases, dependencies, success criteria. Research via subagents if MCPs useful.
3. **Write SKILL.md** — name + description + body. Description is the primary trigger mechanism; make it slightly "pushy" to combat Claude's tendency to undertrigger.
4. **Test and iterate** — spawn with-skill AND baseline subagents in the same turn; draft assertions while runs are in progress; grade, aggregate, launch eval viewer; read feedback; improve.

## Skill anatomy

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name, description required)
│   └── Markdown instructions
└── Bundled Resources (optional)
    ├── scripts/    — Executable code for deterministic/repetitive tasks
    ├── references/ — Docs loaded into context as needed
    └── assets/     — Files used in output (templates, icons, fonts)
```

Progressive disclosure, three levels:
1. Metadata (name + description) — always in context
2. SKILL.md body — in context when skill triggers (<500 lines ideal)
3. Bundled resources — loaded as needed (unlimited)

## Description optimization loop

After the skill is working, Anthropic provides an automated loop to optimize the description for triggering accuracy:

1. Generate 20 eval queries (8-10 should-trigger, 8-10 should-not-trigger). Near-miss negatives are the most valuable — queries that share keywords but need something different.
2. Review queries with the user via `assets/eval_review.html`
3. Run `scripts.run_loop` — evaluates current description 3×/query, proposes improvements based on failures, selects best description by **test** score to avoid overfitting to train.

## How triggering works

Skills appear in Claude's `available_skills` list with name + description. Claude only consults skills for complex, multi-step tasks — simple one-step queries may not trigger even if description matches perfectly.

## Writing principles (from this skill's own style)

- Explain the *why* rather than issuing heavy-handed MUSTs
- Use theory of mind; try to make skills general, not narrow to specific examples
- "ALWAYS" or "NEVER" in all caps is a yellow flag — reframe with reasoning
- Remove things that aren't pulling their weight
- Generalize from feedback — skills run millions of times; avoid overfitting to test examples

## Connections

- Related concepts: [[wiki/concepts/skill-design-principles]], [[wiki/concepts/no-op-audit-adversarial-debate]]
- Related entities: [[wiki/entities/compound-engineering]]
- Source: [[wiki/sources/skill-optimization-loop]]

---

- 2026-07-01 [Claude Code]: Page created — Anthropic's official skill-creator SKILL.md ingested from claude-plugins-official
