---
type: source
title: "The Longform Guide to Everything Claude Code"
resource: https://x.com/affaan
created: 2026-06-12
updated: 2026-06-12
tags: [claude-code, memory, hooks, evals, subagents, token-efficiency, parallelization]
confidence: medium
schema_version: "0.3"
raw: .raw/claude-code-longform-guide.md
---

# The Longform Guide to Everything Claude Code

**URL:** X/Twitter thread (pasted by user); companion repo github.com/affaan-m/everything-claude-code
**Original date:** 2026-01-21
**Author:** cogsec (@affaan) — sequel to [[wiki/sources/claude-code-shorthand-guide]]

## Summary

Advanced-techniques sequel to the Shorthand Guide: token economics, memory persistence, verification/evals, parallelization, and compounding reusable workflows. Most relevant to Cortex Forge: it independently converges on the same memory architecture (PreCompact/Stop/SessionStart hook chain writing per-session files with worked/failed/untried/pending state) and adds two named patterns Cortex Forge lacks — a continuous-learning loop that distills sessions into skills, and iterative retrieval between orchestrator and subagents.

## Key ideas

1. **Memory persistence hook chain** — PreCompact saves state, Stop persists learnings to `~/.claude/sessions/`, SessionStart loads recent session files (last 7 days). Same architecture as Cortex Forge's hot cache; the 7-day recency window and the per-session-file (vs single-file) layout are the deltas.
2. **Session file contract** — each log must state: what worked (with evidence), what was attempted and failed, what was not attempted, what's left. The "attempted and failed" category is one `.hot/MEMORY.md`'s template doesn't make explicit.
3. **Continuous learning loop** — a Stop hook evaluates the whole session and extracts non-trivial patterns (debugging techniques, workarounds) as reusable skills in `skills/learned/`; `/learn` does it manually mid-session. See [[wiki/concepts/continuous-learning-loop]].
4. **Stop over UserPromptSubmit for evaluation** — per-message classification adds latency and evaluates piecemeal; session-end evaluates the complete arc. Direct counterpoint to [[wiki/concepts/prompt-classification-hook]] — they solve different problems (routing hints vs knowledge extraction).
5. **Iterative retrieval** — orchestrator evaluates subagent summaries and asks follow-ups (max 3 cycles), passing objective context, not just the query. See [[wiki/concepts/iterative-retrieval]].
6. **Strategic compaction** — disable auto-compact; compact at phase boundaries (after exploration, before execution), nudged by a PreToolUse tool-call counter.
7. **Evals vocabulary** — checkpoint-based vs continuous; code/model/human graders; pass@k vs pass^k (Anthropic "Demystifying evals", Jan 2026).
8. **MCP → CLI + skills** — wrap robust CLIs (gh, supabase) in skills instead of loading MCPs; with lazy-loading MCPs the context issue faded but the token-cost argument stands.
9. **Minimum viable parallelization** — instances out of necessity, not arbitrary counts; 2-3 usually; worktrees mandatory when code overlaps.
10. **Model-tiering subagents** — cheapest sufficient model per task; Haiku+Opus combo over Sonnet middle ground (5x vs 1.67x cost spread).

## Connections
- Related concepts: [[wiki/concepts/continuous-learning-loop]], [[wiki/concepts/iterative-retrieval]], [[wiki/concepts/prompt-classification-hook]], [[wiki/concepts/memory-system]], [[wiki/concepts/handoff-artifact]], [[wiki/concepts/smart-zone]], [[wiki/concepts/progressive-disclosure-hooks]], [[wiki/concepts/commandcode-taste]]
- Projects: cortex-forge (convergencia independiente en la arquitectura del hot cache; candidatos de roadmap diferidos a la decisión post-batch)

---

- 2026-06-12 [Claude Code]: Page created from pasted X thread (batch 2/3 — decisions deferred until all three are ingested)
