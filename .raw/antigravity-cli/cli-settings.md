---
slug: cli-settings
section: Antigravity CLI
title: Settings, Rendering & Keybindings
path:
  - Antigravity CLI
  - Settings
  - Overview
---

# Settings, rendering & keybindings

Configure persistent preferences, customize keyboard shortcuts, toggle terminal display buffers, and manage runtime CLI parameter overrides.

## Setting up preferences

Antigravity CLI stores user preferences in a minimal, forward-compatible JSON configuration profile.

### Configuration file location

The persistent settings are saved in a plain JSON format:

```text
~/.gemini/antigravity-cli/settings.json
```

The CLI leverages **sparse persistence** by writing only values to disk that differ from their system defaults. This keeps your configuration file clean, minimal, and fully forward-compatible with future updates.

### The interactive settings panel

To edit settings directly inside your active terminal session without opening raw JSON files:

1. Type `/config` (or its alias `/settings`) inside the prompt panel and press `Enter`.
2. The full-screen **Settings Editor Overlay** opens.
3. Navigate between available options using `↑`/`↓`.
4. Press `Enter` on a highlighted parameter to toggle its state or open a text insertion field.
5. Press `Esc` to save your modifications and close the editor.

## Command-line overrides

You can temporarily override persistent preferences for individual terminal sessions using CLI command flags:

```bash
agy --sandbox=false --notifications=false
```

When an override flag is active, the interactive `/config` menu displays a warning indicator alongside the modified setting:

```text
! Tool Permission: strict (overridden by command flag)
```

You can still edit the persistent value on disk during these sessions, but the CLI enforces the active runtime flag override until you close the session.

## Visual rendering modes

The TUI operates in one of two visual rendering modes depending on your terminal capability and connection latency.

### Alt-screen mode (`always`)

This mode opens a dedicated display screen using the terminal's alternate buffer, creating an immersive, standalone app interface.

- **Key features**: Integrated scrollback, mouse-wheel scrolling support, custom rendered scrollbar, and clean terminal state restoration on exit.
- **Best used for**: Standard local development sessions in advanced terminal emulators (such as iTerm2, Ghostty, or WezTerm).

### Inline mode (`never`)

This mode renders output sequentially directly within your terminal's standard stdout pipeline.

- **Key features**: Preserves entire session history inside your emulator's native scrollback buffer, does not capture mouse inputs, and works seamlessly alongside standard command outputs.
- **Best used for**: Remote SSH terminals, terminal multiplexers like `tmux` or `screen`, and low-bandwidth remote sessions.

<Announcement>
icon: info
iconColor: var(--theme-primary)
color: var(--theme-surface-surface-container)
text: **Adaptive Rendering**: Setting Alt-Screen mode to `default` allows the TUI to automatically detect your environment. It defaults to Alt-Screen on advanced local shells and degrades to Inline mode when running over SSH or in non-interactive sessions.
</Announcement>

## Custom status lines & terminal titles

For advanced TUI environment integrations, you can toggle active metrics or deploy custom scripts to generate dynamic status bars and modify your terminal window titles:

- **[Status Line Customization](/docs/cli-statusline)**: Learn how to manage the status indicator panel and construct custom formatted status line shell scripts.
- **[Terminal Title Customization](/docs/cli-title)**: Learn how to toggle window title outputs and pipe live agent states into your window headers.

## Keybindings configuration

You can customize almost all keyboard shortcuts in the TUI by mapping keys to specific workspace commands.

### Keybindings file location

Custom maps are stored alongside your primary settings profile:

```text
~/.gemini/antigravity-cli/keybindings.json
```

### Format and customization

The JSON structure maps a single TUI command action to an array of hotkey sequences:

```json
{
  "cli.clear_screen": ["ctrl+l"],
  "prompt.insert_newline": ["shift+enter", "ctrl+j"],
  "edit.open_editor": ["ctrl+g"]
}
```

To completely disable a default hotkey, map its action to an empty array `[]`. If your JSON schema is malformed or invalid, the CLI falls back to system defaults for those specific actions and loads the remaining valid mappings.

<Announcement>
icon: warning
iconColor: var(--theme-primary)
color: var(--theme-surface-surface-container)
text: **Protected Keys**: Crucial navigation shortcuts like `cli.exit` (`Ctrl+D` / `Ctrl+C`) and `cli.enter` (`Enter`) are protected by the system and cannot be disabled.
</Announcement>

### Restoring defaults

To revert all keys back to system defaults, simply delete the keybindings profile:

```bash
rm ~/.gemini/antigravity-cli/keybindings.json
```

## Next steps

Now that you have configured your environment, review security controls and extensibility options:

- **[Permissions & Sandbox](/docs/cli-sandbox)**: Manage secure execution containment boundaries.
- **[Plugins & Skills](/docs/cli-plugins)**: Create your own custom skills and import legacy plugins.
- **[CLI Reference](/docs/cli-reference)**: Access quick reference sheets listing all configuration options, commands, and default key maps.
