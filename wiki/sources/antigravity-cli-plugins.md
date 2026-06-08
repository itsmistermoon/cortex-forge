---
type: source
title: "Antigravity CLI — Plugins & Skills"
source: https://antigravity.google/docs/cli-plugins
slug: antigravity-cli-plugins
section: Antigravity CLI / Customizations
fetched: 2026-06-08
raw: .raw/antigravity-cli/cli-plugins.md
---

# Plugins & skills

Two customization layers: **Plugins** (namespaced bundles of skills + subagents + MCP + hooks) and **Skills** (declarative markdown blueprints that auto-convert into slash commands).

## Antigravity plugins

### Filesystem layout

```text
~/.gemini/antigravity-cli/plugins/<plugin_name>/
├── plugin.json                 # Required package marker
├── mcp_config.json             # Optional MCP server defs
├── hooks.json                  # Optional pre/post tool hooks
├── skills/                     # Optional specialized skills
├── agents/                     # Optional subagent templates
└── rules/                      # Optional custom codebase rules
```

### CLI subcommands

| Command | Purpose |
|---|---|
| `agy plugin list` | Show active packages and loaded components |
| `agy plugin install /path` | Stage a local or remote package into the profile |
| `agy plugin disable <name>` | Suspend a plugin's tools without deleting assets |
| `agy plugin enable <name>` | Re-enable a suspended plugin |
| `agy plugin uninstall <name>` | Purge the package directory and registries |

## Agent skills

Declarative markdown files → slash commands inside the TUI (e.g., `/refactor-ui`).

### Local workspace skills

1. Create `.agents/skills/` at project root.
2. Draft `<name>.md`:
   ```yaml
   ---
   name: format-tests
   description: Standardize and re-format Python unittest assertions
   ---
   ```
3. Write instructions below. When `agy` runs in this directory, `/format-tests` is available.

### Global skills

Place `.md` files in `~/.gemini/antigravity-cli/skills/` — auto-imported as global slash commands on every `agy` launch.

## Hooks

Pre/post-execution interceptors. Use cases: pre-flight checks, post-format (`prettier` after writes).

- Defined in a plugin's `hooks.json` or in primary `settings.json`.
- Inspect active hooks via `/hooks` in the TUI.

## Model Context Protocol (MCP)

Open standard for foundation models to interface with local APIs, parsers, custom tools. Supports local processes and remote hosts.

### Accessing the MCP manager

`/mcp` + `Enter` → **MCP Manager Overlay** with live status rings, manual reload, connection logs.

### Config locations

- **Global**: `~/.gemini/antigravity-cli/mcp_config.json`
- **Workspace local**: `.agents/mcp_config.json`

```json
{
  "mcpServers": {
    "sqlite-explorer": {
      "command": "node",
      "args": ["/usr/local/bin/sqlite-mcp-server.js"],
      "env": {
        "SQLITE_DB_PATH": "/var/data/app.db"
      }
    }
  }
}
```

**Remote schema**: SSE/websocket connections require `serverUrl`. Legacy `url`/`httpUrl` not supported.

## See also

- [Migration from Gemini CLI](./gcli-migration) — legacy extension conversion
- [Troubleshooting](./antigravity-cli-troubleshooting.md) — hook/lockout/network errors
- [Permissions & Sandbox](./antigravity-cli-permissions.md) — containment rings
