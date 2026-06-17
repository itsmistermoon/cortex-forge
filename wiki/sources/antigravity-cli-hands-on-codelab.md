---
type: source
title: "Antigravity CLI — Hands-on Codelab (Step 5)"
resource: https://codelabs.developers.google.com/antigravity-cli-hands-on#5
section: Antigravity CLI / Getting Started
created: 2026-06-08
updated: 2026-06-08
tags: [antigravity, cli, installation, flags, configuration, models]
raw: .raw/antigravity-cli-hands-on-codelab.md
confidence: high
schema_version: "0.3"
---

# Antigravity CLI — Hands-on Codelab (Step 5)

Official Google codelab covering installation, CLI flags, slash commands, configuration, and available models.

## Key finding: non-interactive mode

`agy` supports a `-p` / `--print` flag for non-interactive (headless) use:

```bash
agy -p "your prompt here"
```

Equivalent to `claude -p` in Claude Code. Relevant for [[wiki/entities/antigravity-cli]] hooks that need LLM synthesis without launching the full TUI.

## Installation

```bash
# macOS / Linux
curl -fsSL https://antigravity.google/cli/install.sh | bash

# Windows PowerShell
irm https://antigravity.google/cli/install.ps1 | iex
```

## CLI flags

| Flag | Description |
|---|---|
| `-p` / `--print` | Non-interactive mode — direct prompt, prints response, exits |
| `--model` | Specify model for the session |
| `-c` / `--continue` | Resume most recent conversation |
| `--conversation <id>` | Resume previous conversation by ID |
| `--dangerously-skip-permissions` | Auto-approve all tool requests |
| `--sandbox` | Run with terminal restrictions enabled |
| `--add-dir <path>` | Add directory to workspace |

## Configuration

Location: `~/.gemini/antigravity-cli/settings.json`

> **Note**: the codelab lists `~/.gemini/antigravity-cli/settings.json` as the config location. Other sources reference `~/.gemini/config/`. [!contradiction] — verify which path is canonical in production.

| Key | Values |
|---|---|
| `colorScheme` | `dark`, `light`, `solarized light`, `solarized dark`, colorblind variants |
| `model` | Currently selected model |
| `trustedWorkspaces` | Folders where permissions are pre-granted |
| `toolPermission` | `request-review` \| `proceed-in-sandbox` \| `always-proceed` \| `strict` |

## Tool permission modes

- **`request-review`** (default) — pauses before system-affecting actions
- **`proceed-in-sandbox`** — automatic execution within isolated container
- **`always-proceed`** — full autonomy without prompts
- **`strict`** — read-only; all non-read operations require approval

## Available models

- Gemini 3.5 Flash (Low / Medium / High)
- Gemini 3.1 Pro (Low / High)
- Claude Sonnet 4.6 (Thinking)
- Claude Opus 4.6 (Thinking)

List via: `agy models`

## Slash commands

`/help`, `/config`, `/artifact`, `/model`, `/clear`, `/exit`, `/quit`,
`/planning`, `/fast`, `/context`, `/permissions`, `/hooks`, `/mcp`

Shell mode: press `!` to toggle shell access within the TUI.

## Connections

- [[wiki/entities/antigravity-cli]] — entity page for the CLI
- [[wiki/concepts/antigravity-hooks]] — hooks system

---

- 2026-06-08 [Claude Code]: Page created from Google Codelab step 5
