---
type: entity
title: "Antigravity CLI"
slug: antigravity-cli
fetched: 2026-06-08
---

# Antigravity CLI

The lightweight, fast, terminal-first surface to work with Antigravity agents. Run autonomous coding agents, execute shell commands directly, and manage background subagents all from the keyboard. Binary: `agy`.

## Identity

- **Binary**: `agy` (installed to `~/.local/bin/` Unix, `C:\Program Files\Google\antigravity-cli` Windows)
- **Config root**: `~/.gemini/antigravity-cli/`
  - `settings.json` — preferences (sparse, only non-defaults written)
  - `keybindings.json` — hotkey maps
  - `plugins/<name>/` — installed plugin bundles
  - `skills/` — global agent skills
  - `mcp_config.json` — global MCP servers
  - `updater/` — self-updater state (`update.lock`, `last_check.timestamp`)
- **Project config**: `.agents/` at workspace root (skills, mcp_config, AGENTS.md/GEMINI.md)
- **Auth token storage**: OS keyring (Apple Keychain / Linux secret-service via dbus / Windows Credential Manager)
- **Install script**: `curl -fsSL https://antigravity.google/cli/install.sh | bash` (mac/Linux) / `iex` PowerShell (Windows)
- **Latest tracked version**: 2.0.11 (June 3, 2026)

## Capability surface

### Security model (two layers)

1. **Fine-grained permissions** — every sensitive op is `action(target)`. Three lists: `deny` > `ask` > `allow`. Actions: `read_file`, `write_file`, `read_url`, `execute_url`, `command` (anchored regex per token), `unsandboxed` (escape sandbox), `mcp`. See [Permissions](../sources/antigravity-cli-permissions.md).
2. **OS-level terminal sandbox** — `enableTerminalSandbox: true` activates `nsjail` (Linux), `sandbox-exec` (macOS), `AppContainer` (Windows). Zero execution overhead. See [Sandbox](../sources/antigravity-cli-sandbox.md).

When sandbox is **enabled**, prompt offers "Yes, and run without sandbox restrictions" as option 2. When **disabled**, it offers "Yes, and run in sandbox" — so the TUI inverts the option to match the current state.

### Workspace context

- `GEMINI.md` or `AGENTS.md` at root auto-parsed on startup (directory standards, styling, test commands, deprecations).
- `@` in prompt → Interactive Path Suggestion overlay (imports absolute path).
- `Ctrl+V` pastes screenshots/video — agent consults the media to diagnose.
- `/add-dir <path>` adds directories to active workspace.
- `allowNonWorkspaceAccess` (default `false`) gates file tools outside Git/workspace roots.

### Customization layers

- **Plugins** — namespaced bundles: `plugin.json` (required), `mcp_config.json`, `hooks.json`, `skills/`, `agents/`, `rules/`. Subcommands: `agy plugin list|install|enable|disable|uninstall`.
- **Skills** — markdown files in workspace `.agents/skills/` or global `~/.gemini/antigravity-cli/skills/`. Auto-convert to slash commands (e.g., `/format-tests`).
- **Hooks** — pre/post tool interceptors. View with `/hooks`.
- **MCP** — local + remote servers (SSE/websocket). Workspace `.agents/mcp_config.json` or global `mcp_config.json`. Remote requires `serverUrl` field. Manager via `/mcp`.

### TUI session control

- `/rewind` (alias `/undo`) — roll back conversation to a stable checkout.
- `/fork` (alias `/branch`) — clone current thread into parallel session.
- `/resume` (alias `/switch`, `/conversation`) — load previous thread.
- `/rename <name>` — rename session.
- `Esc` — interrupt turn, regain clean prompt.
- `/clear` — reset conversation context.

### TUI rendering

- `altScreenMode`: `default` (auto-detect), `always` (alt buffer, mouse wheel), `never` (inline stdout).
- Adaptive: alt-screen on local advanced shells, inline on SSH/non-interactive.
- `colorScheme`: light, solarized light, colorblind-friendly light, dark, solarized dark, colorblind-friendly dark, tokyo night, terminal.
- `verbosity`: `high` (full thoughts) or `low` (minimal progress).
- `runningLightSpeed`: fast/medium/slow/off.

### Status line & terminal title

Both consume the same JSON state payload (`cwd`, `conversation_id`, `model`, `workspace`, `version`, `plan_tier`, `email`, `agent_state`, `vcs`, `sandbox`, `subagents`, `artifacts`, `context_window`, `background_tasks`, `terminal_width`).

- `statusLine` config in `settings.json` → pipes JSON to script's `stdin`, reads formatted string from `stdout`, full ANSI colors.
- `title` config in `settings.json` → same payload, but **strips ANSI escape sequences** before rendering.
- Built-in toggles: `/statusline`, `/title [on|off]`.
- Reference scripts: [statusline.sh](https://github.com/google-antigravity/antigravity-cli/blob/main/examples/statusline/statusline.sh), [title.sh](https://github.com/google-antigravity/antigravity-cli/blob/main/examples/title/title.sh).

### Self-updater

Native, statically linked. 15-min TTL debounce (`last_check.timestamp`) + advisory lock (`update.lock`) in `~/.gemini/antigravity-cli/updater/`. Opt-out: `AGY_CLI_DISABLE_AUTO_UPDATE=true`.

## Model context (cli-permissions table)

Permission actions and their defaults:

| Action | Target format | Default | Notes |
|---|---|---|---|
| `read_file` | `/path`, `dir`, `*` | Ask (auto-allowed in workspace) | `*` matches system-wide |
| `write_file` | `/path`, `*` | Ask (auto-allowed in workspace) | Implies read on same path |
| `read_url` | `domain`, `*` | Ask | Subdomain match |
| `execute_url` | `domain`, `*` | Ask | Web actuation |
| `command` | `prefix`, `regex`, `*` | Ask | Each token is `^(?:pattern)$` |
| `unsandboxed` | `prefix`, `*` | Ask | Escape sandbox for one run |
| `mcp` | `server/tool`, `*` | Ask | Local + remote servers |

## Subagent & concurrency model

- `/agents` opens Agent Manager Panel — monitor background subagents.
- `/tasks` opens Task Manager Panel — background shell execution logs.
- `/btw <query>` — side question in background without interrupting main thread.
- `Alt+J` (`prompt.teleport_agent`) — switch to next subagent awaiting confirmation.
- `Ctrl+K` (`prompt.fast_approve`) — approve pending subagent action.

## See also

- [Permissions](../sources/antigravity-cli-permissions.md)
- [Sandbox](../sources/antigravity-cli-sandbox.md)
- [Settings](../sources/antigravity-cli-settings.md)
- [Plugins & Skills](../sources/antigravity-cli-plugins.md)
- [Status Line](../sources/antigravity-cli-statusline.md)
- [Terminal Title](../sources/antigravity-cli-title.md)
- [Best Practices](../sources/antigravity-cli-best-practices.md)
- [Troubleshooting](../sources/antigravity-cli-troubleshooting.md)
- [CLI Reference](../sources/antigravity-cli-reference.md)
