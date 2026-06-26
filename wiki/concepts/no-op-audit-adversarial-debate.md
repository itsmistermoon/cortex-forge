---
title: No-Op Audit with Adversarial Subagent Debate
type: concept
created: 2026-06-24
updated: 2026-06-24
tags: [skills, agent-design, quality, workflow]
aliases: [no-op audit, skill audit, adversarial debate]
sources:
  - conversation 2026-06-24
confidence: high
schema_version: "0.3"
---

# No-Op Audit with Adversarial Subagent Debate

A methodology for identifying and rehabilitating no-op instructions in agent skills — lines that don't change model behavior — using a structured adversarial debate between subagents to decide whether each candidate should be eliminated or reformulated into a verifiable contract.

## What is a no-op instruction

A no-op is an instruction the model would satisfy by default, with no divergence in output if it were removed. Common patterns:

- Vague quality appeals: "be thorough", "write clearly", "be concise"
- Generic safety boilerplate: "do not include sensitive information"
- Metaphorical principles without falsifiable criteria: "write it as if read in 6 months"
- Temporal anchors that produce no measurable divergence: "compiled truth, not patches"

No-ops make skills harder to evaluate, harder to maintain, and consume tokens without influencing behavior. They accumulate especially in agent-authored or iteratively-grown skills.

## Non-obvious finding

The naive conclusion — remove all no-ops — is wrong. In practice, most no-op candidates cover a real risk or prevent a real failure mode; the problem is the *formulation*, not the *intent*.

The key question is not "does this change behavior?" but "can this be reformulated into a contract with a verifiable failure condition?"

## The audit process

### Step 1 — Identify candidates

Scan the skill's Rules and inline prompts for lines matching no-op patterns above. Flag them as candidates, not verdicts.

### Step 2 — Adversarial debate (per candidate)

Spawn three subagents per candidate in two phases:

**Phase A — parallel:**
- **Defender**: find the real risk the line covers; propose a concrete, testable reformulation
- **Attacker**: demonstrate the line produces no output divergence; argue for removal

**Phase B — sequential (reads A):**
- **Judge**: weighs both arguments; emits ELIMINAR, REFORMULAR, or CONSERVAR; if REFORMULAR, writes the exact replacement text

Use the lightest capable model available — this task is binary classification and structured argumentation, not deep reasoning.

### Step 3 — Apply verdicts

| Verdict | Action |
|---|---|
| ELIMINAR | Remove the line entirely |
| REFORMULAR | Replace with the judge's exact text |
| CONSERVAR | Leave unchanged; document why in a comment |

## What makes a reformulation valid

A reformulation converts a no-op into an instruction when it satisfies two conditions:

1. **Divergence**: the model produces different output with vs. without it
2. **Verifiability**: a reviewer can determine if the instruction was followed by reading the output

Concrete patterns that work:
- Replace temporal anchors with checklists: "write it durably" → enumerate what durability requires (no deictic references, decisions include justification, acronyms expanded on first use)
- Replace metaphors with failure signals: "compiled truth, not patches" → "if updating an existing page, rewrite the full body; violation signal: two blocks covering the same subtopic from different perspectives without resolving them"
- Replace vague exclusions with patterns: "no sensitive information" → explicit pattern list (`sk-*`, `Bearer *`, `ghp_*`) plus a substitution mechanism (`<REDACTED>`)
- Replace qualitative prompts with structural specs: "be concise" → "output exactly three fields: path (one line), problem (one sentence), proposed action (one imperative sentence)"

## Results from the 2026-06-24 cortex-forge audit

Five candidates across four skills — all five returned REFORMULAR (none were pure no-ops):

| Skill | Original | Verdict | Why not eliminated |
|---|---|---|---|
| cortex-crystallize | "Do not include tokens, API keys, or sensitive information" | REFORMULAR | Sessions with deploys/APIs can have credentials in fragile context; risk is real, not structural |
| cortex-imprint | "write it as if read in 6 months" | REFORMULAR | Prevents session-implicit pages (deictic references, unexpanded acronyms, unjustified decisions) |
| cortex-imprint | "Compiled truth: write in full, not in patches" | REFORMULAR | Prevents diff-writing when updating existing pages |
| cortex-assimilate | "Compiled truth is written in full, never accumulated in patches" | REFORMULAR | Same anti-pattern: pages become collages after multiple ingestions |
| cortex-prune (subagent prompt) | "Be concise. Do not add explanation beyond what's needed" | REFORMULAR | Can be made structural: three exact fields per finding |

## Related concepts

- [[wiki/concepts/multi-agent-analysis-pipeline]] — General pattern for parallel fan-out with per-layer validation; the debate harness is an instance
- [[wiki/concepts/parametric-knowledge]] — No-op instructions often arise from assuming the model's default behavior matches the intent; parametric defaults are invisible until tested

---

- 2026-06-24 [Claude Code (claude-sonnet-4-6)]: Page created — imprint from no-op audit session
