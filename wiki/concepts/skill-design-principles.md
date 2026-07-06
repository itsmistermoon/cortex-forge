---
title: Skill Design Principles
type: concept
created: 2026-07-01
updated: 2026-07-06
tags: [skills, agent-design, quality, writing-great-skills, cortex-forge/skills]
aliases: [good skill checklist, skill quality, writing skills, skill whiteness test]
sources:
  - wiki/sources/writing-great-skills.md
  - wiki/sources/anthropic-skill-creator.md
  - wiki/sources/skill-optimization-loop.md
  - wiki/sources/agentskills-best-practices.md
  - wiki/sources/agentskills-using-scripts.md
  - conversation 2026-06-24 (no-op audit)
confidence: high
schema_version: "0.3"
---

# Skill Design Principles

A compiled checklist of what separates a skill that works from one that appears to work. Derived from five primary sources: Matt Pocock's [[wiki/sources/writing-great-skills|writing-great-skills framework]] (vocabulary and failure modes), Anthropic's [[wiki/sources/anthropic-skill-creator|skill-creator]] (creation loop and description optimization), agentskills.io's [[wiki/sources/agentskills-best-practices|best-practices]] and [[wiki/sources/agentskills-using-scripts|using-scripts]] guides (the Agent Skills specification's own authoring guidance), and two audit passes over the cortex-forge skill suite (2026-06-24 no-op audit, 2026-07-01 writing-great-skills audit). Use this page to evaluate any new or modified skill before committing.

Two of these sources converge independently on the same core test: this page's whiteness test ("does the agent produce different, verifiable output with vs. without this instruction?") and agentskills.io's best-practices phrasing ("would the agent get this wrong without this instruction?") are the same check, reached from different frameworks. Convergence across independently-authored sources is treated as corroboration, not redundancy — see Principle 1 below.

## The whiteness test

A skill passes if every instruction in it satisfies two conditions:

1. **Divergence** — the agent produces different output with vs. without this instruction.
2. **Verifiability** — a reviewer can determine from the output whether the instruction was followed.

If an instruction fails either condition, it is a no-op or needs reformulation. See [[wiki/concepts/no-op-audit-adversarial-debate]] for the methodology to decide which.

agentskills.io's [[wiki/sources/agentskills-best-practices|best-practices guide]] independently arrives at the same test, phrased as "would the agent get this wrong without this instruction?" — evaluate every line of a skill against it, not just the ones that look suspicious.

---

## Principles

### 1. Description is a classifier, not a summary

The `description:` field is what the model reads to decide whether to invoke the skill. It must classify invocation triggers precisely — wrong invocations cost tokens and produce wrong output.

- **User-invoked skill**: list the exact phrases or signals that should trigger it ("says 'ingest this'", "pastes a URL with no other context").
- **Model-invoked skill at session close**: list both user-triggered and automatic triggers explicitly (e.g., "invoke when the user says 'save context', 'crystallize', 'I'm done for now', or when the session is about to close").
- **Manual-only skill**: do not use description text to prevent auto-invocation — use `disable-model-invocation: true` in frontmatter. Verbal warnings in descriptions are instruction fighting mechanism: the model can still fire the skill. The frontmatter field removes it from the model's reach entirely.

### 2. No duplication between sections

Two sections covering the same ground weaken both. Common violations:

- `## When to invoke` that restates the `description:` → eliminate the section; description is the canonical trigger list.
- `## Rules` that repeats items already in `## Constraints` → each section must own distinct content; Rules for execution behavior, Constraints for invariants and hard limits.
- Locale resolution block appearing verbatim in 5 skills → extract to a co-located reference file (`LOCALE-RESOLUTION.md`) and replace all instances with a single context pointer.

**Signal**: if you can delete a section and the skill loses no information, the section is sediment.

### 3. Progressive disclosure — steps vs reference

Not all branches need all content. Content that only some branches need should live in a co-located file, not inline in SKILL.md.

- **Inline**: what every branch needs (vault resolution, locale, core steps).
- **Co-located file**: what only some branches need (embedding setup, locale fallback chain, platform-specific detection). Reached via a context pointer: "See `EMBEDDING-SETUP.md` (co-located with this skill)."

**Threshold**: if a block is used by fewer than half the skill's execution paths, it belongs in a co-located file.

### 4. Completion criterion must be checkable

A step is not done unless a reviewer can determine it is done from the output alone.

- ❌ "Evaluate the source and create pages" — passes even if qualifying types were silently skipped.
- ✓ "Create pages for every qualifying type. **Done when:** every content type (concept, entity, reference, project) that meets its creation criteria has a page — zero qualifying types skipped."

Every multi-output step needs a completion criterion with a falsifiable failure condition.

### 5. No sediment

Sediment is content that once had a reason but no longer does:

- **Language inconsistency** — "Capa 1 / Capa 2" in a skill that is otherwise in English. Rule: pick one language and apply it uniformly. Spanish sediment accumulates when skills are drafted bilingually and not cleaned up.
- **Stale vocabulary** — references to files or layers that no longer exist (e.g., "CODEX.md", old path formats).
- **Orphan config blocks** — YAML or code blocks that floated away from the step they belong to during edits.

### 6. No sprawl

Sprawl is content in the wrong place:

- Reference material (wire formats, lookup tables) inside a step that's about something else → move to a reference section or co-located file.
- Step-specific config that separated from its step during refactoring → re-anchor to the step it belongs to.
- Instructions scoped to one branch in the middle of shared steps → move inside the branch block.

### 7. Mechanism over verbal instruction

When a behavior constraint can be enforced mechanically, use the mechanism — not a verbal warning that the model can ignore.

| Constraint | Verbal (weak) | Mechanism (strong) |
|---|---|---|
| Manual-only skill | "Do not invoke automatically" in description | `disable-model-invocation: true` in frontmatter |
| Sensitive content blocking | "Do not include API keys" | Explicit pattern list (`sk-*`, `Bearer *`) + `<REDACTED>` substitution rule |
| Output structure | "Be concise" | "Output exactly three fields: path (one line), problem (one sentence), proposed action (one imperative sentence)" |

### 8. No-ops fail the whiteness test

A no-op is an instruction the model satisfies by default. Removing it produces no output divergence. Common patterns:

- Vague quality appeals: "be thorough", "write clearly"
- Metaphorical principles without falsifiable criteria: "write it as if read in 6 months"
- Generic exclusions without patterns: "do not include sensitive information"

**Non-obvious finding**: most no-op candidates cover a real risk — the problem is the formulation, not the intent. The right action is usually reformulation, not deletion. See [[wiki/concepts/no-op-audit-adversarial-debate]] for the defender/attacker/judge process.

### 9. Leading words

Every step and instruction should open with an imperative verb or a condition. This is ergonomic but has a real effect: instructions starting with conditions or hedges ("if possible, try to...") are weaker signal than those starting with the action ("Run / Read / Evaluate / Report").

### 10. Scripts live in `scripts/`, listed up front

Bundled executable scripts belong in a `scripts/` subdirectory of the skill, referenced with paths relative to the skill root (the agent runs commands from there — no absolute paths needed). List every co-located script in a `## Available scripts` section immediately after the skill's intro paragraph, before `## Steps`/`## Sub-tasks`, so the agent knows what exists before reading the full procedure. Source: [[wiki/sources/agentskills-using-scripts]] — this is the Agent Skills specification's own convention, not a cortex-forge-specific choice; cortex-forge adopted it directly on 2026-07-03 (see `wiki/projects/cortex-forge.md` changelog) after having previously kept scripts flat in the skill root.

The same source's guidance on *designing* scripts for agentic callers — non-interactive input only (no TTY prompts, since agents cannot respond to them and a blocking prompt hangs forever instead of failing loud), `--help` as the primary interface documentation, error messages that state what went wrong and what to try next, structured stdout with diagnostics on stderr, idempotency, `--dry-run` for destructive operations, and capped/paginated output for anything that could exceed a harness's truncation threshold — was audited against cortex-forge's own scripts the same day (2026-07-03): unbounded waits, silent mid-run corruption, and broken path references across every script in the suite. See [[wiki/concepts/fail-loud-design]] for the resulting principle and its concrete manifestations.

Reasonable to bundle a script only when the trigger has actually occurred: the agent reinventing the same logic across multiple execution traces (parsing a format, running a repeated multi-flag command). Writing scripts preemptively, before that signal appears, adds maintenance surface without a demonstrated need.

---

## Checklist for new or modified skills

Run this against any SKILL.md before committing:

- [ ] `description:` triggers correctly for both intended callers (user-invoked / model-invoked)?
- [ ] Manual-only skills use `disable-model-invocation: true`, not verbal instruction?
- [ ] No `## When to invoke` section (content belongs in `description:`)?
- [ ] `## Rules` and `## Constraints` cover distinct content with no overlap?
- [ ] Locale block not duplicated inline — context pointer to `LOCALE-RESOLUTION.md` instead?
- [ ] Reference material used by fewer than half the paths is in a co-located file?
- [ ] Every multi-output step has a checkable completion criterion?
- [ ] No language mixing (Spanish/English within the same skill)?
- [ ] No orphaned config blocks or YAML that floated from their step?
- [ ] Every "constraint" is a mechanism or has a falsifiable failure condition?
- [ ] No obvious no-ops (quality appeals, metaphorical principles, generic exclusions)?
- [ ] Bundled scripts live in `scripts/`, listed in a `## Available scripts` section before `## Steps`?

---

## Related concepts

- [[wiki/concepts/no-op-audit-adversarial-debate]] — Methodology for identifying and rehabilitating no-op instructions via adversarial subagent debate
- [[wiki/concepts/progressive-disclosure-hooks]] — Just-in-time context loading pattern; same progressive disclosure principle applied to context injection
- [[wiki/concepts/fail-loud-design]] — Script-design principle referenced in Principle 10 above

---

- 2026-07-01 [Claude Code]: Page created — consolidated from two audit passes: no-op audit (2026-06-24) and writing-great-skills framework audit (2026-07-01)
- 2026-07-06 [Claude Code]: Corrected Principle 10 — claimed the fail-loud audit against cortex-forge's own scripts "has not yet been audited", but it was completed the same day (2026-07-03) mentioned earlier in the same paragraph. Linked to new [[wiki/concepts/fail-loud-design]] page.
- 2026-07-01 [Claude Code]: Sources updated to primary sources — writing-great-skills SKILL.md+GLOSSARY.md, Anthropic skill-creator SKILL.md, skill-optimization-loop (replatformer)
- 2026-07-03 [Claude Code]: Added Principle 10 (scripts live in `scripts/`, listed in `## Available scripts`) and a corroboration note on the whiteness test, both from agentskills.io's best-practices and using-scripts guides. Checklist item added for script organization.
