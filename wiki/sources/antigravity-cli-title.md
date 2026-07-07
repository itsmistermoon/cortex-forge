---
type: source
title: "Antigravity CLI — Terminal Title Customization"
resource: https://antigravity.google/docs/cli-title
created: 2026-06-08
updated: 2026-06-08
tags: [antigravity, cli, title, tui]
confidence: high
schema_version: "0.3"
raw: .raw/antigravity-cli/cli-title.md
---

# Terminal title customization

Displays agent details, workspace basename, and conversation parameters in your terminal emulator's title bar. Visible even when the window is minimized or unfocused.

## Interactive toggling

- `/title` → toggle on/off.
- `/title on` / `/title off` → explicit state.

## Custom title scripting

```json
{
  "title": {
    "type": "command",
    "command": "~/.gemini/antigravity-cli/title.sh"
  }
}
```

On every state change, the TUI runs your script with the same JSON payload used for statusline (via `stdin`), reads the formatted string from `stdout`, and updates the terminal title. **Non-printable characters and ANSI escape sequences are stripped** before rendering.

## JSON payload

The payload is identical to the [Status Line schema](./antigravity-cli-statusline.md) — `cwd`, `conversation_id`, `agent_state`, `vcs`, context window, etc.

## Reference implementation

[title.sh on GitHub](https://github.com/google-antigravity/antigravity-cli/blob/main/examples/title/title.sh) — extracts workspace folder basename, renders structured title with live agent state and conversation session prefixes.

```bash
chmod +x ~/.gemini/antigravity-cli/title.sh
```

## See also

- [Status Line Customization](./antigravity-cli-statusline.md) — same payload, status bar target
- [Settings](./antigravity-cli-settings.md)
- [Permissions & Sandbox](./antigravity-cli-permissions.md)
