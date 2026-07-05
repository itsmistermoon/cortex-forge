---
title: Tool Context Budget
type: concept
created: 2026-06-16
updated: 2026-06-16
tags: [tokens, context-window, tool-schema, mcp, claude-code]
aliases: [tool schema cost, tool budget, context budget]
sources:
  - wiki/sources/claude-code-shorthand-guide.md
confidence: medium
schema_version: "0.3"
---

# Tool Context Budget

Tool schemas consume a fixed slice of the context window before the first user message. In Claude Code with a 200K token window, tool definitions alone consume ~30K tokens — shrinking the effective working window to ~170K. Adding MCP servers compounds this: each server exposes additional tool schemas loaded at session start.

## Why it matters

The context window limit is nominal, not effective. The practical limit is:

```
effective_window = context_limit - tool_schema_cost - system_prompt - hot_cache_injection
```

For a standard Claude Code session with several MCPs:
- Context limit: 200K tokens
- Tool schemas (built-in + MCP): ~30–50K tokens
- System prompt + AGENTS.md: ~5–10K tokens
- Hot cache injection: ~2–5K tokens
- **Effective working window: ~135–163K tokens**

Sessions that hit the smart zone degradation early (see [[wiki/concepts/smart-zone]]) are often not hitting the nominal limit — they're hitting the effective limit.

## Cost by tool category

| Tool category | Approximate schema cost |
|---------------|------------------------|
| Built-in Claude Code tools (~15 tools) | ~15K tokens |
| Each MCP server (avg 5–10 tools) | ~3–8K tokens per server |
| Large reference MCP (e.g. 14 tools like codebase-memory-mcp) | ~10–15K tokens |
| Custom skill definitions | Minimal (text only) |

## Design implication for cortex-forge

Skills (text injected via AGENTS.md or hooks) have near-zero schema cost. MCP servers have fixed schema cost at session start regardless of whether their tools are used. This is the reason cortex-forge uses script-based hooks + skills rather than MCP tools for the core protocol — see [[wiki/projects/cortex-forge]] key decision "MCP deferral."

When Fase 3.6 (semantic retrieval) adds a FastMCP server, it adds ~10–15K tokens of schema cost to every session. This cost is gated: the MCP is installed only after Etapa 1 is validated and there is >1 client requesting it.

## Progressive disclosure relationship

Tool context budget is the quantitative extension of [[wiki/concepts/progressive-disclosure-hooks]]: progressive disclosure minimizes context loaded *per message*; tool budget accounts for the fixed context consumed *before any message* by the session's capability surface.

## Relationships
- Concepts: [[wiki/concepts/progressive-disclosure-hooks]], [[wiki/concepts/smart-zone]]
- Project: [[wiki/projects/cortex-forge]] (MCP deferral decision)
- Entity: [[wiki/entities/codebase-memory-mcp]] (high-schema-cost MCP example)

---

- 2026-06-16 [Claude Code]: Page created from claude-code-shorthand-guide.md ingestion — tool schema cost is a standalone quantitative concept distinct from progressive disclosure
