---
title: Pi terminal compatibility
type: concept
created: 2026-06-16
updated: 2026-06-16
tags: [pi, terminal, keybindings, reference]
sources:
  - wiki/sources/pi-terminal-setup.md
confidence: high
schema_version: "0.3"
aliases: []
---

# Pi terminal compatibility

Pi uses the [Kitty keyboard protocol](https://sw.kovidgoyal.net/kitty/keyboard-protocol/) for reliable modifier key detection. Most modern terminals support this protocol, but some require configuration. See [[pi-cli-flags]] for the `PI_HARDWARE_CURSOR` environment variable and message queue keybindings.

## Compatibility Matrix

| Terminal | Works out of box | Needs config | Notes |
|----------|------------------|--------------|-------|
| Kitty | ✅ | — | Native support |
| iTerm2 | ✅ | — | Native support |
| Ghostty | — | ⚠️ | Add `keybind` for `alt+backspace`; older `shift+enter` remap interferes with pi |
| WezTerm | ✅ for `Shift+Enter` | ⚠️ for `Option+Enter` (macOS) | Enable Kitty protocol explicitly; remap `Option+Enter` to escape sequence on macOS |
| Alacritty | ✅ for `Shift+Enter` | ⚠️ for `Option+Enter` (macOS) | Add `Option+Enter` binding to `alacritty.toml` on macOS |
| VS Code (Integrated) | ✅ (≥ 1.109.5) | ⚠️ (< 1.109.5) | Older versions need explicit `shift+enter` keybinding |
| Windows Terminal | — | ⚠️ | Remap `Alt+Enter` away from fullscreen; forward `shift+enter`/`alt+enter` via `sendInput` |
| Apple Terminal | Partial | — | Uses local macOS modifier fallback for `Shift+Enter` (no SSH support) |
| xfce4-terminal | — | ❌ | Limited escape sequence support — `Shift+Enter` indistinguishable from `Enter` |
| terminator | — | ❌ | Limited escape sequence support — same as xfce4-terminal |
| IntelliJ IDEA (Integrated) | — | ❌ | `Shift+Enter` indistinguishable from `Enter` |

## Ghostty

Add to Ghostty config (`~/Library/Application Support/com.mitchellh.ghostty/config` on macOS, `~/.config/ghostty/config` on Linux):

```
keybind = alt+backspace=text:\x1b\x7f
```

Older Claude Code versions may have added:

```
keybind = shift+enter=text:\n
```

That mapping sends a raw linefeed byte. Inside pi, that is indistinguishable from `Ctrl+J`, so tmux and pi no longer see a real `shift+enter` key event. If Claude Code 2.x or newer is the only reason for the mapping, you can remove it, unless you want Claude Code in tmux where it is still required.

To keep `Shift+Enter` working in tmux via that remap, add `ctrl+j` to your `newLine` keybinding in `~/.pi/agent/keybindings.json`:

```json
{
  "newLine": ["shift+enter", "ctrl+j"]
}
```

## WezTerm

WezTerm usually works out of the box for `Shift+Enter` via xterm modifyOtherKeys. To use the Kitty keyboard protocol explicitly, create `~/.wezterm.lua`:

```lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()
config.enable_kitty_keyboard = true
return config
```

On macOS, WezTerm binds `Option+Enter` to fullscreen by default. To use `Option+Enter` for pi follow-up queueing, add this key override:

```lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()
config.keys = {
  {
    key = 'Enter',
    mods = 'ALT',
    action = wezterm.action.SendString('\x1b[13;3u'),
  },
}
return config
```

If you already have a `config.keys` table, add the entry to it.

On WSL, WezTerm may require a visible hardware cursor for IME candidate window positioning. If CJK IME candidates do not follow the text cursor, set `PI_HARDWARE_CURSOR=1` before running pi or set `showHardwareCursor` to `true` in settings.

## Alacritty

Alacritty usually works out of the box for `Shift+Enter`. On macOS, `Option+Enter` may arrive as plain `Enter`. To use `Option+Enter` for pi follow-up queueing, add to `~/.config/alacritty/alacritty.toml`:

```toml
[[keyboard.bindings]]
key = "Enter"
mods = "Alt"
chars = "\u001b[13;3u"
```

Restart Alacritty after changing the config.

## VS Code (Integrated Terminal)

VS Code 1.109.5 and newer enable Kitty keyboard protocol in the integrated terminal by default, so `Shift+Enter` works out of the box.

VS Code versions older than 1.109.5 need an explicit terminal keybinding for `Shift+Enter`.

`keybindings.json` locations:
- macOS: `~/Library/Application Support/Code/User/keybindings.json`
- Linux: `~/.config/Code/User/keybindings.json`
- Windows: `%APPDATA%\\Code\\User\\keybindings.json`

Add to `keybindings.json`:

```json
{
  "key": "shift+enter",
  "command": "workbench.action.terminal.sendSequence",
  "args": { "text": "\u001b[13;2u" },
  "when": "terminalFocus"
}
```

## Windows Terminal

Add to `settings.json` (Ctrl+Shift+, or Settings → Open JSON file) to forward the modified Enter keys pi uses:

```json
{
  "actions": [
    {
      "command": { "action": "sendInput", "input": "\u001b[13;2u" },
      "keys": "shift+enter"
    },
    {
      "command": { "action": "sendInput", "input": "\u001b[13;3u" },
      "keys": "alt+enter"
    }
  ]
}
```

- `Shift+Enter` inserts a new line.
- Windows Terminal binds `Alt+Enter` to fullscreen by default — that prevents pi from receiving `Alt+Enter` for follow-up queueing.
- Remapping `Alt+Enter` to `sendInput` forwards the real key chord to pi instead.

If you already have an `actions` array, add the objects to it. If the old fullscreen behavior persists, fully close and reopen Windows Terminal.

## Apple Terminal

Pi enables enhanced key reporting when available. If Terminal.app still sends plain `Return` for `Shift+Enter`, pi uses a local macOS modifier fallback to treat that `Return` as `Shift+Enter`.

This fallback only works when pi runs on the same Mac as Terminal.app. It cannot detect the local keyboard over remote SSH.

## IntelliJ IDEA (Integrated Terminal)

The built-in terminal has limited escape sequence support. `Shift+Enter` cannot be distinguished from `Enter` in IntelliJ's terminal.

If you want the hardware cursor visible, set `PI_HARDWARE_CURSOR=1` before running pi (disabled by default for compatibility).

Consider using a dedicated terminal emulator for the best experience.

## Recommended Terminals

For the best experience, use a terminal that supports the Kitty keyboard protocol:
- [Kitty](https://sw.kovidgoyal.net/kitty/)
- [Ghostty](https://ghostty.org/)
- [WezTerm](https://wezfurlong.org/wezterm/)
- [iTerm2](https://iterm2.com/)
- [Alacritty](https://github.com/alacritty/alacritty) (requires compilation with Kitty protocol support)

## Escape Sequence Reference

| Key | Sequence |
|-----|----------|
| `Shift+Enter` | `\u001b[13;2u` |
| `Alt+Enter` / `Option+Enter` | `\u001b[13;3u` |
| `Alt+Backspace` | `\u001b\x7f` |

---

- 2026-06-16 [CommandCode]: Page created
