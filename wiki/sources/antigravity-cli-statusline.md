---
type: source
title: "Antigravity CLI — Status Line Customization"
resource: https://antigravity.google/docs/cli-statusline
section: Antigravity CLI / Customizations
created: 2026-06-08
updated: 2026-06-08
tags: [antigravity, cli, statusline, tui]
confidence: high
schema_version: "0.3"
raw: .raw/antigravity-cli/cli-statusline.md
---

# Status line customization

Bottom-of-TUI status indicator showing active agent cycles, workspace, context-window usage, and background tasks. Users can toggle built-in metrics or pipe live state to a custom script.

## Interactive toggling

`/statusline` opens the **Status Picker Panel** overlay. Use `↑`/`↓` to toggle metrics, `Enter` to commit, and `Esc` to cancel.

## Custom status line scripting

Add to `~/.gemini/antigravity-cli/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.gemini/antigravity-cli/statusline.sh"
  }
}
```

The CLI pipes JSON state to `stdin`, reads a formatted string from `stdout`, and renders it in the prompt status line. Full ANSI colors are supported.

## JSON payload fields

| Field | Type | Description |
|---|---|---|
| `cwd` | string | Current working directory |
| `conversation_id` | string | Current conversation ID |
| `model` | object | `id`, `display_name` of active model |
| `product` | string | App name (e.g., `antigravity-cli`) |
| `workspace` | object | `current_dir`, `project_dir` |
| `version` | string | CLI version |
| `plan_tier` | string | Subscription tier |
| `email` | string | Authenticated user email |
| `agent` | object | Active agent profile name |
| `context_window` | object | `total_input_tokens`, `total_output_tokens`, `context_window_size`, `used_percentage`, `remaining_percentage`, `current_usage` |
| `agent_state` | string | `idle` / `thinking` / `working` / `tool_use` / `initializing` |
| `vcs` | object | `type` (git/jj/fig), `branch`, `client`, `dirty` |
| `sandbox` | object | `enabled`, `allow_network` |
| `subagents` | array | `name`, `role`, `status` |
| `artifacts` | array | `uri`, `status`, `type` |
| `pending_input_count` | int | Queued user messages |
| `background_tasks` | array | `name`, `status`, `index` |
| `tool_confirmation_pending` | bool | Confirmation dialog showing |
| `terminal_width` | int | Live terminal width |

## Example payload

```json
{
  "cwd": "/home/user/my-project",
  "conversation_id": "12345678-abcd-ef01-2345-6789abcdef01",
  "model": {"id": "Gemini", "display_name": "Gemini"},
  "workspace": {
    "current_dir": "/home/user/my-project",
    "project_dir": "file:///home/user/my-project"
  },
  "version": "2026.04.15",
  "context_window": {
    "total_input_tokens": 88244,
    "total_output_tokens": 61074,
    "context_window_size": 1048576,
    "used_percentage": 8.42,
    "remaining_percentage": 91.58,
    "current_usage": {
      "input_tokens": 63382,
      "output_tokens": 346,
      "cache_creation_input_tokens": 0,
      "cache_read_input_tokens": 20857
    }
  },
  "product": "antigravity-cli",
  "agent_state": "idle",
  "vcs": {"type": "git", "client": "my-project", "branch": "dev", "dirty": false},
  "sandbox": {"enabled": false},
  "plan_tier": "Pro",
  "email": "developer@email.com",
  "terminal_width": 111
}
```

## Reference implementation

[statusline.sh on GitHub](https://github.com/google-antigravity/antigravity-cli/blob/main/examples/statusline/statusline.sh) — renders state badges, branches, context window progress bars.

```bash
chmod +x ~/.gemini/antigravity-cli/statusline.sh
```

## See also

- [Terminal Title Customization](./antigravity-cli-title.md) — same JSON, window header target
- [Settings](./antigravity-cli-settings.md) — keybindings + buffers
- [Permissions & Sandbox](./antigravity-cli-permissions.md)

---

- 2026-06-08 [Claude Code]: Re-synthesized from the official status-line page after SPA fallback handling
