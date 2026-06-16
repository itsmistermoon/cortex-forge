---
title: Pi CLI flags
type: reference
created: 2026-06-16
updated: 2026-06-16
tags: [pi, cli, flags, reference]
sources:
  - wiki/sources/pi-usage.md
confidence: high
schema_version: "0.3"
---

# Pi CLI flags

Complete reference of every `pi` command-line flag and environment variable. Use with [[pi-slash-commands]] for in-session commands and [[pi-models-json]] for provider/model configuration.

## Syntax

```
pi [options] [@files...] [messages...]
```

## Package Commands

| Command | Description |
|---------|-------------|
| `pi install <source> [-l]` | Install package (`-l` for project-local) |
| `pi remove <source> [-l]` | Remove package |
| `pi uninstall <source> [-l]` | Alias for `remove` |
| `pi update [source\|self\|pi]` | Update pi and packages; reconcile pinned git refs |
| `pi update --extensions` | Update packages only; reconcile pinned git refs |
| `pi update --self` | Update pi only |
| `pi update --extension <src>` | Update one package |
| `pi list` | List installed packages |
| `pi config` | Enable/disable package resources |

`pi config` and project package commands accept `--approve`/`--no-approve` to trust or ignore project-local settings for one command. `pi update` never prompts for project trust.

## Modes

| Flag | Description |
|------|-------------|
| _(default)_ | Interactive mode |
| `-p`, `--print` | Print response and exit |
| `--mode json` | Output all events as JSON lines |
| `--mode rpc` | RPC mode over stdin/stdout |
| `--export <in> [out]` | Export a session to HTML |

In print mode, pi reads piped stdin and merges it into the initial prompt:

```
cat README.md | pi -p "Summarize this text"
```

## Model Options

| Option | Description |
|--------|-------------|
| `--provider <name>` | Provider (e.g. `anthropic`, `openai`, `google`) |
| `--model <pattern>` | Model pattern or ID; supports `provider/id` and optional `:<thinking>` |
| `--api-key <key>` | API key, overriding environment variables |
| `--thinking <level>` | `off`, `minimal`, `low`, `medium`, `high`, `xhigh` |
| `--models <patterns>` | Comma-separated patterns for Ctrl+P cycling |
| `--list-models [search]` | List available models |

## Session Options

| Option | Description |
|--------|-------------|
| `-c`, `--continue` | Continue the most recent session |
| `-r`, `--resume` | Browse and select a session |
| `--session <path\|id>` | Use a specific session file or partial UUID |
| `--fork <path\|id>` | Fork a session file or partial UUID into a new session |
| `--session-dir <dir>` | Custom session storage directory |
| `--no-session` | Ephemeral mode; do not save |
| `--name <name>`, `-n <name>` | Set session display name at startup |

## Tool Options

| Option | Description |
|--------|-------------|
| `--tools <list>`, `-t <list>` | Allowlist specific built-in, extension, and custom tools |
| `--exclude-tools <list>`, `-xt <list>` | Disable specific built-in, extension, and custom tools |
| `--no-builtin-tools`, `-nbt` | Disable built-in tools but keep extension/custom tools enabled |
| `--no-tools`, `-nt` | Disable all tools |

Built-in tools: `read`, `bash`, `edit`, `write`, `grep`, `find`, `ls`.

## Resource Options

| Option | Description |
|--------|-------------|
| `-e`, `--extension <source>` | Load an extension from path, npm, or git; repeatable |
| `--no-extensions` | Disable extension discovery |
| `--skill <path>` | Load a skill; repeatable |
| `--no-skills` | Disable skill discovery |
| `--prompt-template <path>` | Load a prompt template; repeatable |
| `--no-prompt-templates` | Disable prompt template discovery |
| `--theme <path>` | Load a theme; repeatable |
| `--no-themes` | Disable theme discovery |
| `--no-context-files`, `-nc` | Disable `AGENTS.md` and `CLAUDE.md` discovery |

Combine `--no-*` with explicit flags to load exactly what you need, ignoring settings:

```
pi --no-extensions -e ./my-extension.ts
```

## Other Options

| Option | Description |
|--------|-------------|
| `--system-prompt <text>` | Replace default prompt; context files and skills are still appended |
| `--append-system-prompt <text>` | Append to system prompt |
| `--verbose` | Force verbose startup |
| `-a`, `--approve` | Trust project-local files for this run |
| `-na`, `--no-approve` | Ignore project-local files for this run |
| `-h`, `--help` | Show help |
| `-v`, `--version` | Show version |

## File Arguments

Prefix files with `@` to include them in the message:

```
pi @prompt.md "Answer this"
pi -p @screenshot.png "What's in this image?"
pi @code.ts @test.ts "Review these files"
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `PI_CODING_AGENT_DIR` | Override config directory; default is `~/.pi/agent` |
| `PI_CODING_AGENT_SESSION_DIR` | Override session storage directory; overridden by `--session-dir` |
| `PI_PACKAGE_DIR` | Override package directory, useful for Nix/Guix store paths |
| `PI_OFFLINE` | Disable startup network operations (update checks, package update checks, install/update telemetry) |
| `PI_SKIP_VERSION_CHECK` | Skip the Pi version update check at startup (prevents `pi.dev` latest-version request) |
| `PI_TELEMETRY` | Override install/update telemetry and provider attribution headers: `1`/`true`/`yes` or `0`/`false`/`no`. Does NOT disable update checks |
| `PI_CACHE_RETENTION` | Set to `long` for extended prompt cache where supported |
| `PI_HARDWARE_CURSOR` | Set to `1` to force a visible hardware cursor (for IME on WSL WezTerm and IntelliJ) |
| `VISUAL`, `EDITOR` | External editor for Ctrl+G |
| `GIT_TERMINAL_PROMPT` | Set to `0` to disable credential prompts during non-interactive git operations |
| `GIT_SSH_COMMAND` | Override SSH options (e.g. `ssh -o BatchMode=yes -o ConnectTimeout=5`) |

## Examples

```
# Interactive with initial prompt
pi "List all .ts files in src/"

# Non-interactive
pi -p "Summarize this codebase"

# Non-interactive with piped stdin
cat README.md | pi -p "Summarize this text"

# Named one-shot session
pi --name "release audit" -p "Audit this repository"

# Different model
pi --provider openai --model gpt-4o "Help me refactor"

# Model with provider prefix
pi --model openai/gpt-4o "Help me refactor"

# Model with thinking level shorthand
pi --model sonnet:high "Solve this complex problem"

# Limit model cycling
pi --models "claude-*,gpt-4o"

# Read-only mode
pi --tools read,grep,find,ls -p "Review the code"

# Disable one extension or built-in tool while keeping the rest
pi --exclude-tools ask_question
```

## Message Queue Keybindings (Interactive)

| Key | Action |
|-----|--------|
| `Enter` | Queue steering message (delivered after current assistant turn's tool calls) |
| `Alt+Enter` | Queue follow-up message (delivered after all work finishes) |
| `Escape` | Abort and restore queued messages to editor |
| `Alt+Up` | Retrieve queued messages back to editor |

On Windows Terminal, `Alt+Enter` is fullscreen by default — remap per [[pi-terminal-compat]]. Configure delivery in settings with `steeringMode` and `followUpMode`.

---

- 2026-06-16 [CommandCode]: Page created
