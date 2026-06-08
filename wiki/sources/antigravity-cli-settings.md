---
type: source
title: "Antigravity CLI — Settings, Rendering & Keybindings"
source: https://antigravity.google/docs/cli-settings
slug: antigravity-cli-settings
section: Antigravity CLI / Settings
fetched: 2026-06-08
tags: [antigravity, cli, settings, configuration]
confidence: high
raw: .raw/antigravity-cli/cli-settings.md
---

# Settings, rendering & keybindings

Persistent preferences stored in a minimal, forward-compatible JSON profile. **Sparse persistence** — only values differing from system defaults are written to disk.

## Configuration file

```text
~/.gemini/antigravity-cli/settings.json
```

## Interactive settings panel

1. Type `/config` (alias `/settings`) → full-screen **Settings Editor Overlay** opens.
2. Navigate with `↑`/`↓`, press `Enter` to toggle, `Esc` to save and close.

## Command-line overrides

Temporarily override persistent preferences per session:

```bash
agy --sandbox=false --notifications=false
```

Active overrides show a warning indicator in `/config`. Persistent on-disk edits are shadowed by the runtime flag until session ends.

## Visual rendering modes

### Alt-screen (`always`)

- Integrated scrollback, mouse-wheel support, custom scrollbar, clean state restoration.
- Best for: local development in iTerm2, Ghostty, WezTerm.

### Inline (`never`)

- Sequential output into native stdout, preserved in emulator's scrollback, no mouse capture.
- Best for: remote SSH, `tmux`/`screen`, low-bandwidth sessions.

### Adaptive (`default`)

TUI auto-detects environment — Alt-Screen on local advanced shells, Inline on SSH / non-interactive.

## Custom status lines & titles

- [Status Line Customization](./antigravity-cli-statusline.md) — status bar scripting.
- [Terminal Title Customization](./antigravity-cli-title.md) — window title piping.

## Keybindings

```text
~/.gemini/antigravity-cli/keybindings.json
```

```json
{
  "cli.clear_screen": ["ctrl+l"],
  "prompt.insert_newline": ["shift+enter", "ctrl+j"],
  "edit.open_editor": ["ctrl+g"]
}
```

- Map action to an array of hotkey sequences.
- Empty array `[]` disables a default hotkey.
- Malformed JSON → fallback to system defaults for invalid actions only.
- **Protected**: `cli.exit` (`Ctrl+D`/`Ctrl+C`) and `cli.enter` (`Enter`) cannot be disabled.

To restore all defaults: `rm ~/.gemini/antigravity-cli/keybindings.json`.

## See also

- [Permissions & Sandbox](./antigravity-cli-permissions.md)
- [Plugins & Skills](./antigravity-cli-plugins.md)
- [CLI Reference](./antigravity-cli-reference.md)
