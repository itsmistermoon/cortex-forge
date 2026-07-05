---
title: "Vault MCP Server Pattern"
type: concept
created: 2026-06-26
updated: 2026-06-26
tags: [mcp-server, ai-agents, knowledge-management, architecture, cortex-forge/architecture]
aliases: [vault-as-mcp, knowledge-base-mcp]
sources: []
confidence: high
schema_version: "0.3"
---

# Vault MCP Server Pattern

Architecture pattern where a knowledge vault (local markdown directory) is exposed as an MCP server, converting vault operations into tools consumable by any MCP-compatible agent without skills or special prompts.

The concrete reference is the MCP server of `kcmd`, which exposes a Knowledge Catalog snapshot with 5 tools:

| Tool | Operation |
|------|-----------|
| `pull` | Sync vault from canonical source |
| `push` | Publish local changes |
| `list-entries` | List available concepts |
| `lookup-entry` | Retrieve a concept by ID with metadata |
| `modify-entry` | Modify a concept in the vault |

## Contrast with cortex-forge's current approach

cortex-forge today uses **skills** (markdown files the agent reads and executes) for equivalent operations: `cortex-recall` ≈ `lookup-entry`, `cortex-assimilate` ≈ `modify-entry` + ingest, `cortex-prune` ≈ validation. The architecture difference:

| Dimension | Skills (cortex-forge today) | MCP server |
|-----------|--------------------------|------------|
| Invocation | Agent reads the skill and executes it | Agent calls the tool directly |
| Cross-agent portability | Requires agent to support the skill | Works with any MCP-compatible agent |
| Interface typing | Implicit in the skill prompt | Explicit in the tool schema |
| Vault state | Agent maintains context | Server is independently stateful |
| Setup | Skills installed per agent | One server, all agents |

## Application to cortex-forge

A `cortex-forge` MCP server could expose:

```json
{
  "mcpServers": {
    "cortex-forge": {
      "command": "cortex",
      "args": ["mcp", "--vault", "/path/to/vault"]
    }
  }
}
```

With minimum tools:

| cortex-forge tool | kcmd equivalent | Description |
|-------------------|-----------------|-------------|
| `recall` | `lookup-entry` | Search and synthesize vault knowledge |
| `list-concepts` | `list-entries` | List available wiki pages |
| `assimilate` | `modify-entry` + ingest | Ingest new source into vault |
| `crystallize` | `push` | Session snapshot → `.hot/MEMORY.md` |

## When this upgrade makes sense

The MCP server pattern is justified when:
- The vault is consumed by more than one distinct agent (Claude, Codex, CommandCode, Antigravity)
- Per-agent skills generate drift — each agent learns different conventions
- You want the interface to be the stable contract, not the prompts

cortex-forge Phase 1 (multi-agent parity) is resolving exactly the problem an MCP server would solve with less friction. The trade-off: an MCP server requires process infrastructure (the server running); skills are static files.

**Gate for the MCP transition (from [[wiki/projects/cortex-forge]]):** Phase 1 validated in an organic session AND the vault is accessed from more than one client. AGENTS.md remains the design contract regardless — an agent without MCP can still operate the vault by reading AGENTS.md directly.

---

- 2026-06-26 [Claude Code]: Consolidated from moon-multivac/wiki/concepts/vault-mcp-server-pattern.md (2026-06-17); translated to English per vault locale
