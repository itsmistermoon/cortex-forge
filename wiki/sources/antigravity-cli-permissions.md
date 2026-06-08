---
type: source
title: "Antigravity CLI — Permissions"
source: https://antigravity.google/docs/cli-permissions
slug: antigravity-cli-permissions
section: Antigravity CLI / Agent Capabilities
fetched: 2026-06-08
raw: .raw/antigravity-cli/cli-permissions.md
---

# Permissions

Fine-grained permission engine that gates every sensitive agent operation. Permissions are evaluated as `action(target)` resources across three access lists: `deny` (block), `ask` (prompt), `allow` (auto-approve). Stored in `~/.gemini/antigravity-cli/settings.json`. **Precedence: Deny > Ask > Allow.**

## Supported actions

| Action | Target format | Default |
|---|---|---|
| `read_file` | `/path`, `dir`, `*` | Ask (auto-allowed in workspace) |
| `write_file` | `/path`, `*` | Ask (auto-allowed in workspace) |
| `read_url` | `domain`, `*` | Ask |
| `execute_url` | `domain`, `*` | Ask (actuating on web elements) |
| `command` | `prefix`, `regex`, `*` (anchored regex per token) | Ask |
| `unsandboxed` | `prefix`, `*` | Ask (escape sandbox) |
| `mcp` | `server/tool`, `*` | Ask |

## Matching rules

- **Global wildcard**: `*` matches all targets within an action namespace.
- **Write implies Read**: allowing `write_file` grants `read_file` for the same path.
- **Deny Read implies Deny Write**: denying `read_file` blocks `write_file` on that path.
- **Cross-platform paths**: Windows paths auto-normalized (drive letter stripped, `\` → `/`).
- **Command regex**: each whitespace-separated token is `^(?:pattern)$`.

## Default guardrails

1. Workspaces are auto-allowed for read/write.
2. Web browsing (`read_url`, `execute_url`) defaults to Ask.
3. All other unconfigured actions default to Ask.

## Interactive prompts

When the agent hits an Ask-mode operation, the TUI shows a card. For file/URL/MCP you can **edit the target string** in the card to broaden the grant (e.g., `/project/file.txt` → `/project`) for the rest of the turn. Scope editing is not supported for commands.

## Example config

```json
{
  "permissions": {
    "allow": [
      "command(git)",
      "command(npm run (build|lint|test))",
      "unsandboxed(git push)",
      "read_file(/var/log/app)",
      "write_file(src/)",
      "read_url(google.com)",
      "mcp(linter/*)"
    ],
    "deny": [
      "command(rm -rf)",
      "command(curl .*)",
      "command(sudo)",
      "write_file(.git/)",
      "write_file(/home/user/.ssh)"
    ],
    "ask": ["command(*)", "execute_url(aws.amazon.com)", "mcp(sql/execute_mutation)"]
  }
}
```

## See also

- [Sandbox](./antigravity-cli-sandbox.md) — OS-level containment
- [Plugins & Skills](./antigravity-cli-plugins.md) — slash commands
- [Settings](./antigravity-cli-settings.md) — global key overrides
