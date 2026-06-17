---
type: source
title: "Pi Terminal Setup"
resource: https://pi.dev/docs/latest/terminal-setup
section: terminal-setup
created: 2026-06-16
updated: 2026-06-16
tags: [pi, terminal, kitty-keyboard-protocol, keybindings, ghostty, wezterm, alacritty, vscode, windows-terminal]
confidence: high
schema_version: "0.3"
raw: .raw/pi-terminal-setup.md
sources:
  - .raw/pi-terminal-setup.md
---

# Pi Terminal Setup

**URL:** https://pi.dev/docs/latest/terminal-setup
**Original date:** 2026-06-16
**Author:** Mario Zechner / pi-mono

## Summary

Terminal compatibility matrix and per-emulator configuration for pi, which relies on the [Kitty keyboard protocol](https://sw.kovidgoyal.net/kitty/keyboard-protocol/) to disambiguate `Shift+Enter` and `Alt+Enter` from plain Enter. Documents out-of-the-box support (Kitty, iTerm2), macOS Apple Terminal's local modifier fallback, Ghostty/WezTerm/Alacritty/VS Code/Windows Terminal config snippets, the WezTerm macOS `Option+Enter` fullscreen override, WSL/IME hardware-cursor workaround (`PI_HARDWARE_CURSOR=1`), and terminals that do not support it (xfce4-terminal, terminator, IntelliJ built-in terminal).

## Key ideas

1. **Kitty protocol is the contract** — without it, modified Enter keys cannot be distinguished from plain Enter, breaking keybindings like `submit: ["ctrl+enter"]` and the steering/follow-up queue.
2. **Work out of the box** — Kitty, iTerm2, VS Code 1.109.5+ integrated terminal. Apple Terminal falls back to a local macOS modifier hook (Shift+Enter treated as the local Return-with-Shift). The fallback only works on the same Mac — not over SSH.
3. **Ghostty needs `keybind = alt+backspace=text:\x1b\x7f`** — older Claude Code's `shift+enter=text:\n` remap sends a raw linefeed, indistinguishable from `Ctrl+J` inside pi, breaking tmux routing. Safe to remove on Claude Code 2.x+ unless used in tmux (in which case add `ctrl+j` to pi's `newLine` keybinding in `~/.pi/agent/keybindings.json`).
4. **WezTerm** — opt into the Kitty protocol with `config.enable_kitty_keyboard = true`. On macOS override the `Option+Enter` fullscreen default by sending `\x1b[13;3u`. WSL IME fix: `PI_HARDWARE_CURSOR=1` (or `showHardwareCursor: true` in settings) so CJK candidate windows follow the text cursor.
5. **Alacritty on macOS** — `Option+Enter` arrives as plain Enter by default; add `[[keyboard.bindings]] key = "Enter" mods = "Alt" chars = "\u001b[13;3u"` to `~/.config/alacritty/alacritty.toml` and restart.
6. **Windows Terminal** — Alt+Enter is fullscreen by default. Add `actions` entries to forward `shift+enter → \u001b[13;2u` and `alt+enter → \u001b[13;3u`. If the old fullscreen behavior persists, fully close and reopen.
7. **Limited support** — xfce4-terminal, terminator, and IntelliJ's built-in terminal cannot distinguish modified Enter. Recommendation: switch to Kitty / Ghostty / WezTerm / iTerm2 / Alacritty (compiled with Kitty support) for the best experience.
8. **Hardware cursor toggle** — `PI_HARDWARE_CURSOR=1` is the universal escape hatch for terminals where the IME candidate window needs a visible cursor to anchor against. Default off for compatibility.

## Connections
- Related concepts: [[wiki/concepts/pi-extension-lifecycle]]
- Projects: [[wiki/entities/pi-cli]]
- Sources: [[wiki/sources/pi-usage]], [[wiki/sources/pi-extensions]]

---

- 2026-06-16 [CommandCode]: Page created
