# The Longform Guide to Everything Claude Code

Author: cogsec (@affaan) — X/Twitter, 2026-01-21
Source: pasted by user. Sequel to "The Shorthand Guide to Everything Claude Code" (see .raw/claude-code-shorthand-guide.md).
Companion repo: https://github.com/affaan-m/everything-claude-code

Themes: token economics, memory persistence, verification patterns, parallelization strategies, compound effects of reusable workflows.

## Context & Memory Management

For sharing memory across sessions: a skill/command that summarizes progress and saves to a `.tmp` file in `.claude/`, appending until session end. Next day it uses that as context and picks up where you left off. One file per session to avoid polluting old context into new work. Session files should contain: what approaches worked (verifiably, with evidence), which attempted approaches did NOT work, which approaches have not been attempted, and what's left to do.

Session log pattern: `~/.claude/sessions/YYYY-MM-DD-topic.tmp` — current state, completed items, blockers, key decisions, context for next session.

### Clearing context strategically

Work from the plan after clearing exploration context (default in plan mode now). For strategic compacting: disable auto-compact, manually compact at logical intervals — compact after exploration before execution; after a milestone before the next.

Strategic Compact Suggester (PreToolUse hook): counts tool calls in /tmp, at threshold (default 50) emits "[StrategicCompact] consider /compact if transitioning phases" to stderr. Rationale: auto-compact fires at arbitrary points, often mid-task; strategic compacting preserves context through logical phases.

### Dynamic system prompt injection

Instead of CLAUDE.md / .claude/rules/ (loads every session), inject per-scenario context via CLI:

```bash
claude --system-prompt "$(cat memory.md)"
alias claude-dev='claude --system-prompt "$(cat ~/.claude/contexts/dev.md)"'
alias claude-review='claude --system-prompt "$(cat ~/.claude/contexts/review.md)"'
alias claude-research='claude --system-prompt "$(cat ~/.claude/contexts/research.md)"'
```

Difference vs @ file references: @ / rules come in as tool output during conversation; --system-prompt injects into the actual system prompt before it starts. Instruction hierarchy: system prompt > user messages > tool results. Marginal for day-to-day; matters for strict behavioral rules. Faster (no tool call), more reliable, slightly more token efficient — but minor and may be more overhead than it's worth.

### Memory persistence hooks

Chain for continuous memory across sessions without manual intervention:
- PreCompact hook: before compaction, save important state to a file (logs compaction events, timestamps the active session file)
- Stop hook (session-end): persist learnings to ~/.claude/sessions/ — creates/updates daily session file from template, tracks start/end times
- SessionStart hook: on new session, check recent session files (last 7 days), notify of available context and learned skills

## Continuous Learning / Memory

The Problem: repeating the same corrective prompts across sessions — wasted tokens, context, time.

The Solution: when Claude discovers something non-trivial (debugging technique, workaround, project-specific pattern), save it as a new skill in `~/.claude/skills/learned/`. Next time a similar problem appears, the skill loads automatically.

Why Stop hook instead of UserPromptSubmit: UserPromptSubmit runs on every message — overhead, latency, overkill. Stop runs once at session end — lightweight, evaluates the complete session rather than piecemeal.

Manual extraction with /learn: run mid-session when you've just solved something non-trivial; drafts a skill file, asks confirmation before saving.

Other self-improving memory patterns:
- @RLanceMartin: reflection agent over session logs distills user preferences — a "diary" of what works/doesn't; learnings update a memory file loaded in subsequent sessions.
- @alexhillman: system proactively suggests improvements every 15 minutes; you approve/reject; over time it learns from approval patterns.

## Token Optimization

Primary strategy: subagent architecture delegating the cheapest sufficient model. Default Sonnet for 90% of coding. Upgrade to Opus when: first attempt failed, task spans 5+ files, architectural decisions, security-critical. Downgrade to Haiku when: repetitive, very clear instructions, "worker" role in multi-agent. Haiku+Opus combo makes most sense (5x cost difference vs 1.67x for Sonnet/Opus).

In agent definitions, specify model (e.g. `model: haiku` for a quick-search agent with Glob/Grep only).

Benchmarking approach: same repo+plan across git worktrees, all subagents of one model per worktree, uniform tests across worktrees → numerical benchmark.

Tool-specific: mgrep over grep (~half the tokens on average). Background processes outside Claude via tmux — summarize or copy only the needed part of output; input tokens are where most cost comes from.

Modular codebase benefits: main files in hundreds of lines, not thousands — fewer re-reads, fewer lost details mid-read, right-on-first-try correlates with cost. Lean codebase = cheaper tokens; continuously remove dead code via refactor skills.

System prompt slimming (advanced): Claude Code's system prompt ~18k tokens (~9% of 200k); patches can cut to ~10k. (YK's system-prompt-patches; author doesn't do this.)

## Verification Loops and Evals

Observability: tmux processes tracing thinking stream on skill triggers; PostToolUse hook logging what Claude enacted and exact change/output.

Benchmarking workflow: fork conversation, worktree A WITH skill vs worktree B WITHOUT, git diff at end, compare logs/token usage/output quality.

Eval pattern types:
- Checkpoint-based: explicit checkpoints, verify criteria, fix before proceeding. Best for linear workflows with clear milestones.
- Continuous: run every N minutes or after major changes — tests, build, lint; report regressions immediately, stop and fix. Best for long exploratory sessions.

Grader types (Anthropic, "Demystifying evals for AI agents", Jan 2026):
- Code-based: string match, binary tests, static analysis — fast, cheap, objective, brittle to valid variations
- Model-based: rubric scoring, NL assertions, pairwise comparison — flexible, non-deterministic, more expensive
- Human: SME review, spot-check sampling — gold standard, expensive, slow

Key metrics: pass@k (at least one of k attempts succeeds — k=1: 70%, k=3: 91%, k=5: 97%) vs pass^k (ALL k succeed — k=3: 34%, k=5: 17%). pass@k when any verified success is enough; pass^k when consistency is essential.

Eval roadmap (Anthropic): start early with 20-50 simple tasks from real failures; convert user-reported failures into test cases; unambiguous tasks (two experts, same verdict); balanced problem sets; clean environment per trial; grade what the agent produced, not the path; read transcripts; monitor saturation (100% pass = add tests).

## Parallelization

Forks: well-defined scope, minimal overlap, orthogonal tasks. Preferred pattern: main chat does code changes; forks do codebase questions and external research (docs, GitHub search).

Against arbitrary terminal counts (contra Boris Cherny's 5 local + 5 upstream): instances should exist out of true necessity. "Minimum viable parallelization." Author typically uses 2-3 instances, 4 terminals max. Newcomers: master a single instance first.

When scaling with overlapping code: git worktrees mandatory + well-defined plan per worktree; `/rename` chats to track them.

Cascade method: new tasks in new tabs to the right, sweep left→right oldest→newest, at most 3-4 tasks at a time — beyond that mental overhead grows faster than productivity.

## Groundwork

Two-instance kickoff pattern on an empty repo:
- Instance 1, scaffolding agent: project structure, configs (CLAUDE.md, rules, agents), conventions, skeleton.
- Instance 2, deep research agent: connects to services/web search, detailed PRD, architecture mermaid diagrams, references with actual clips from documentation.

llms.txt pattern: many doc sites expose /llms.txt (e.g. https://www.helius.dev/docs/llms.txt) — clean LLM-optimized documentation to feed directly.

## Philosophy: Build Reusable Patterns

@omarsar0: "Early on, I spent time building reusable workflows/patterns. Tedious to build, but this had a wild compounding effect as models and agent harnesses improved." Workflows are transferable to other agents (Codex). Investment in patterns > investment in model-specific tricks.

## Best Practices for Agents & Sub-Agents

The sub-agent context problem: sub-agents save context by returning summaries, but the orchestrator has semantic context the sub-agent lacks — it knows only the literal query, not the purpose/reasoning. Summaries miss key details. (@PerceptualPeak analogy: boss sends you to a meeting, your summary never includes everything he needs because you lack his implicit context.)

Iterative retrieval pattern: orchestrator dispatches query + objective → sub-agent returns summary → orchestrator evaluates sufficiency → follow-up questions → sub-agent goes back to source → loop until sufficient (max 3 cycles). Pass objective context, not just the query.

Orchestrator with sequential phases: RESEARCH (Explore) → PLAN (planner) → IMPLEMENT (tdd-guide) → REVIEW (code-reviewer) → VERIFY (build-error-resolver). Key rules: each agent ONE clear input, ONE clear output; outputs become next phase's inputs; never skip phases; /clear between agents; store intermediate outputs in files, not just memory.

Agent abstraction tierlist (@menhguin):
- Tier 1 (direct buffs, easy): subagents (half as useful as multi-agent, much less complexity); metaprompting ("3 minutes to prompt a 20-minute task"); asking the user more at the beginning.
- Tier 2 (high skill floor): long-running agents; parallel multi-agent (very high variance, only for highly complex or well-segmented tasks); role-based multi-agent ("models evolve too fast for hard-coded heuristics"); computer-use agents (very early).
Start with Tier 1; graduate to Tier 2 only with mastery and genuine need.

## Tips: Replacing MCPs with CLI + skills

For MCPs wrapping platforms with robust CLIs (GitHub, Supabase, Vercel, Railway): bundle the functionality into skills/commands wrapping the CLI — e.g. /gh-pr wrapping `gh pr create`. Same functionality, similar convenience, freed context window.

Note: Claude Code now lazy-loads MCPs, so the context-window issue is mostly solved — but token usage/cost is not. CLI + skills remains a token optimization; running MCP-equivalent operations via CLI instead of in-context reduces tokens significantly, especially for heavy operations (database queries, deployments).

## References

- Anthropic: Demystifying evals for AI agents (Jan 2026)
- Anthropic: Claude Code Best Practices (Apr 2025)
- Fireworks AI: Eval Driven Development with Claude Code (Aug 2025)
- YK: 32 Claude Code Tips (Dec 2025)
- Addy Osmani: My LLM coding workflow going into 2026
- @PerceptualPeak: Sub-Agent Context Negotiation
- @menhguin: Agent Abstractions Tierlist
- @omarsar0: Compound Effects Philosophy
- RLanceMartin: Session Reflection Pattern (claude_diary)
- @alexhillman: Self-Improving Memory System
