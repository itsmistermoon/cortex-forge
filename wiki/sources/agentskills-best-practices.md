---
title: "agentskills.io — Best practices for skill creation"
type: source
resource: https://agentskills.io/skill-creation/best-practices
created: 2026-07-03
updated: 2026-07-03
timestamp: 2026-07-03
source_author: agentskills.io
tags: [skills, agent-design, skill-quality, progressive-disclosure, scripts]
confidence: high
schema_version: "0.3"
raw: .raw/agentskills-best-practices.md
---

# agentskills.io — Best practices for skill creation

**URL:** https://agentskills.io/skill-creation/best-practices
**Author:** agentskills.io (maintainers of the Agent Skills specification)

## Summary

Practical guidance for authoring effective `SKILL.md` files: ground skills in real expertise rather than generic LLM knowledge, spend the context budget deliberately (omit what the agent already knows, keep `SKILL.md` under ~500 lines / 5,000 tokens via progressive disclosure into `references/`), calibrate instruction specificity to task fragility, and use a set of named patterns (gotchas sections, output templates, checklists, validation loops, plan-validate-execute) for recurring problems in skill design.

## Key ideas

1. **Extract from hands-on tasks or existing project artifacts, not generic references.** A skill synthesized from a team's actual incident reports and runbooks outperforms one synthesized from a generic "best practices" article — the value is in project-specific schemas, failure modes, and conventions, not restated general knowledge.
2. **"Would the agent get this wrong without this instruction?"** — the litmus test for whether a line of `SKILL.md` earns its place. Functionally identical to cortex-forge's own whiteness test (divergence + verifiability) in [[wiki/concepts/skill-design-principles]], reached independently.
3. **Match specificity to fragility.** Give the agent freedom (and explain *why*, not just *what*) when multiple approaches are valid and the task tolerates variation; be rigidly prescriptive ("run exactly this sequence, do not add flags") when operations are fragile or consistency matters. Most skills mix both — calibrate per-section, not globally.
4. **Provide defaults, not menus.** Listing "you can use pypdf, pdfplumber, PyMuPDF, or pdf2image" forces the agent to choose blind; picking one default and mentioning an escape hatch for the edge case is more reliable.
5. **Favor procedures over declarations.** A skill should teach *how to approach a class of problem* (read schema → join on `_id` convention → apply filters → aggregate) rather than *what to produce for one instance* (the specific query for one report). The approach should generalize even when some details in the skill are necessarily specific (output templates, hard constraints).
6. **Named patterns for recurring problems**: gotchas sections (environment facts that defy assumption — kept inline in `SKILL.md`, never in a reference file the agent might not think to load); output templates over prose format description (agents pattern-match against concrete structure better than descriptions); explicit checklists for multi-step workflows with dependencies; validation loops (do work → run validator → fix → repeat until passing); plan-validate-execute for batch/destructive operations (produce a structured plan, validate it against a source of truth, only then execute).
7. **Bundling reusable scripts is a *signal-driven* decision, not a default.** The trigger for moving logic into `scripts/` is observing the agent reinvent the same logic across execution traces (parsing a format, building a chart) — not writing scripts preemptively. See [[wiki/sources/agentskills-using-scripts]] for the mechanics.
8. **Refine with real execution, not just the first draft.** Run the skill against real tasks, feed back *all* results (not just failures), and read the agent's execution traces — not just final outputs — to diagnose whether wasted steps came from vague instructions, inapplicable instructions the agent followed anyway, or too many undifferentiated options.

## Connections
- Related concepts: [[wiki/concepts/skill-design-principles]] — this source's "would the agent get this wrong without it" test is the same check as the whiteness test's divergence condition, arrived at independently by a different framework
- Related sources: [[wiki/sources/writing-great-skills]], [[wiki/sources/anthropic-skill-creator]], [[wiki/sources/agentskills-using-scripts]]

---

- 2026-07-03 [Claude Code]: Page created
