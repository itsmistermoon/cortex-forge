---
type: source
title: "The Shorthand Guide to Everything Claude Code"
resource: https://x.com/affaan
created: 2026-06-12
updated: 2026-06-12
tags: [claude-code, hooks, skills, subagents, mcp, token-efficiency, workflow]
confidence: medium
schema_version: "0.3"
raw: .raw/claude-code-shorthand-guide.md
---

# The Shorthand Guide to Everything Claude Code

**URL:** X/Twitter thread (pasted by user)
**Original date:** 2026-01-17
**Author:** cogsec (@affaan) — 10 months of daily Claude Code use; hackathon Anthropic x Forum Ventures winner

## Summary

Power-user setup guide covering the full Claude Code surface: skills vs commands, the six hook events, subagents with scoped permissions, MCPs, plugins, and workflow tips. The recurring thesis is that **context window is the scarce resource**: every enabled MCP/plugin pays rent in tokens, so configuration discipline (configure many, enable few) matters more than configuration breadth. Secondary source — practitioner opinion, not official docs.

## Key ideas

1. **Tool-context budget** — with too many MCPs/tools enabled, an effective 200K window can shrink to ~70K before compaction. Rule of thumb: 20–30 MCPs configured, <10 enabled, <80 active tools; disable per project via `disabledMcpServers`. The "Always" tier of [[wiki/concepts/progressive-disclosure-hooks]] includes tool schemas, not just instruction files.
2. **Codemap skill** — a skill that regenerates a codebase map at checkpoints so the agent navigates without burning context on exploration. Same motivation as the wiki index: a cheap pointer layer over an expensive corpus.
3. **Hooks for procedural enforcement** — formatting (prettier), type checks (`tsc --noEmit`), console.log audits on Stop, and *blocking unnecessary `.md` creation* via PreToolUse. Reinforces the "procedural code owns the environment" split from [[wiki/sources/obsidian-mind]].
4. **Subagents scoped by skill subset** — a subagent restricted to specific tools and skills executes delegated tasks autonomously without polluting the orchestrator's context.
5. **Modular rules folder** (`~/.claude/rules/*.md` by concern) as alternative to a monolithic CLAUDE.md.
6. **Configuration as fine-tuning, not architecture** — explicit warning against over-engineering the agent setup.
7. Workflow misc: /fork + git worktrees for parallelism, tmux for long-running processes, hookify for conversational hook creation, LSP plugins outside IDEs, mgrep over ripgrep.

## Connections
- Related concepts: [[wiki/concepts/progressive-disclosure-hooks]], [[wiki/concepts/agent-hook-compatibility]], [[wiki/concepts/smart-zone]], [[wiki/concepts/prompt-classification-hook]]
- Projects: cortex-forge (el tool-context budget aplica al diseño de skills/hooks del template)

---

- 2026-06-12 [Claude Code]: Page created from pasted X thread (batch 1/3 — decisions deferred until all three are ingested)
