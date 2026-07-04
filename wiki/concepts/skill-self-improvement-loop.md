---
title: Skill Self-Improvement Loop
type: concept
created: 2026-07-01
updated: 2026-07-01
tags: [skills, agent-design, skill-optimization, observer-pattern, evals, self-improvement, cortex-forge/skills]
aliases: [observer skill, outer loop, skill optimization loop]
sources:
  - wiki/sources/skill-optimization-loop.md
  - wiki/sources/anthropic-skill-creator.md
  - wiki/sources/agentskills-best-practices.md
confidence: high
schema_version: "0.3"
---

# Skill Self-Improvement Loop

A pattern for automatically improving a skill by running it, evaluating its output, and generating diffs to the skill file. Applicable any time a skill has clear validation criteria — verifiable output, measurable quality signal.

## Inner vs outer loop

| Loop | Purpose | Who runs it |
|---|---|---|
| **Inner** | Make sure this specific run worked — per-execution quality gate | Human or CI |
| **Outer** | Make the Skill itself more likely to work better next time | A separate "observer" skill |

The outer loop treats the **skill file** as the artifact to improve, not the skill's output. Because skills are just Markdown files, any coding agent can apply improvements and open a PR.

## The observer skill pattern

An observer skill wraps an inner skill and implements the outer loop:

1. **Run** the inner skill against N examples (representative corpus)
2. **Evaluate** output quality — visually with computer use + browser vision, structurally with scripts
3. **Measure** efficiency — token counts, latency
4. **Synthesize** results with a SOTA model — find failure patterns, not just failures
5. **Generate a diff** to the inner SKILL.md — evidence-backed, not speculative
6. **Exit** when diffs become less meaningful (baked-in convergence criterion)

The observer uses **structured data results** for intelligent failure analysis — not just pass/fail, but enough context for the synthesizer to distinguish between "the skill's instructions were wrong" and "the model's execution was wrong".

## Anthropic's variant: eval-based optimization

Anthropic's `skill-creator` implements a similar outer loop focused on **description triggering accuracy**:

1. Generate 20 trigger eval queries (should-trigger + should-not-trigger near-misses)
2. Evaluate current description 3× per query for reliability signal
3. Propose improved description based on failures
4. Select best by test score (not train score — avoids overfitting)
5. Iterate up to N times

Key constraint: simple queries don't trigger skills regardless of description quality — Claude only consults skills for complex, multi-step tasks. Eval queries must be substantive.

## When to apply

| Condition | Outer loop appropriate? |
|---|---|
| Output is verifiable (visual parity, test pass, format correct) | Yes |
| Quality signal is measurable (token count, build success, diff size) | Yes |
| Output is subjective (writing style, design taste) | No — human review only |
| Skill has a bounded, clear definition of done | Yes |

## Manual variant: reading execution traces

agentskills.io's best-practices guide describes a lighter-weight version of the same outer loop, without requiring observer-skill infrastructure: run the skill against real tasks, then read the agent's **execution traces** (not just final outputs) to diagnose *why* a run went wrong. Three recurring causes it names:

- Instructions too vague — the agent tries several approaches before finding one that works
- Instructions that don't apply to the current task, but the agent follows them anyway
- Too many options presented without a clear default (see [[wiki/concepts/skill-design-principles]] Principle "provide defaults, not menus")

Feed back *all* results, not just failures — a single execute-then-revise pass measurably improves quality; complex domains benefit from several. This is the same outer-loop shape as the observer skill pattern above, minus the automation: a human (or the authoring agent itself) plays the role of observer, reading traces instead of running a structured eval harness.

## Limitations

- Susceptible to **local maxima**: the observer's quality signal only captures what the observer can measure. Failure modes outside the observer's perception go undetected.
- Requires orchestration infrastructure: computer use, multi-agent dispatch, metrics capture
- Works for description optimization but can't detect all classes of no-ops (requires execution delta comparison, not just static analysis)

## Connection to cortex-forge

Cortex-forge's skill suite could benefit from this pattern. The `skill-design-principles` whiteness test provides a static analysis layer; an observer skill could add a dynamic layer — running each cortex-forge skill against known test inputs, evaluating the output against the completion criterion, and detecting premature completion or missing output types. The check-skill-sync CI already covers structural invariants; an observer would cover behavioral ones.

## Related patterns

- [[wiki/concepts/no-op-audit-adversarial-debate]] — Static analysis variant (adversarial debate about whether a line changes behaviour); complementary to the outer loop
- [[wiki/concepts/multi-agent-analysis-pipeline]] — General orchestration pattern; the observer skill is an instance
- [[wiki/concepts/skill-design-principles]] — What the observer is trying to optimize toward

---

- 2026-07-01 [Claude Code]: Page created — synthesized from Zach Lloyd's replatformer (outer loop pattern) and Anthropic's skill-creator (description optimization loop)
- 2026-07-03 [Claude Code]: Added "Manual variant" section — agentskills.io's execution-trace-reading approach as the lightweight version of the same outer loop, no observer infrastructure required
