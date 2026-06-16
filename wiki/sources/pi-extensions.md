---
type: source
title: "Pi Extensions"
source: https://pi.dev/docs/latest/extensions
slug: pi-extensions
section: extensions
fetched: 2026-06-16
tags: [pi, extensions, typescript, lifecycle, events, tools, custom-ui]
confidence: high
schema_version: "0.3"
raw: .raw/pi-extensions.md
sources:
  - .raw/pi-extensions.md
---

# Pi Extensions

**URL:** https://pi.dev/docs/latest/extensions
**Original date:** 2026-06-16
**Author:** Mario Zechner / pi-mono

## Summary

Full reference for the pi extension system — TypeScript modules that subscribe to lifecycle events, register tools/commands/shortcuts/flags, draw custom TUI components, and persist state across sessions. Documents the event taxonomy, ExtensionContext, ExtensionCommandContext, ExtensionAPI methods, custom tool definition, custom rendering, custom UI dialogs and widgets, and the async factory pattern for dynamic model discovery.

## Key ideas

1. **Auto-discovered locations** — `~/.pi/agent/extensions/` (global) and `.pi/extensions/` (project-local) are hot-reloadable via `/reload`. `pi -e ./path.ts` is a one-off for the current run only.
2. **Event taxonomy spans the full lifecycle** — startup (`startup`, `project_trust`), resource (`resource_discovery`), session (`session_start`, `session_end`, `session_fork`), agent (`before_agent_start`, `agent_start`, `agent_end`), model (`model_select`, `model_register`), tool (`tool_call`, `tool_result`), user bash (`user_bash`), and input (`user_input`). Interceptors can block or modify.
3. **ExtensionContext is the runtime handle** — `ctx.ui` (select/confirm/input/notify/custom), `ctx.mode` (text/json/rpc/print), `ctx.hasUI`, `ctx.cwd`, `ctx.isProjectTrusted()`, `ctx.sessionManager`, `ctx.modelRegistry`/`ctx.model`, `ctx.signal` (AbortSignal), `ctx.isIdle`/`ctx.abort`/`ctx.hasPendingMessages`, `ctx.shutdown`, `ctx.getContextUsage`, `ctx.compact`, `ctx.getSystemPrompt`.
4. **ExtensionCommandContext extends it for slash commands** — adds `getSystemPromptOptions`, `waitForIdle`, `newSession({ parentSession? })`, `fork(entryId, options?)`, `navigateTree(targetId, options?)`, `switchSession(sessionPath, options?)`, and `reload()`. Footgun: replacing the session mid-flight may require `ctx.reload()` to refresh the UI.
5. **Async factory for dynamic providers** — `export default async function (pi)` can fetch `/v1/models` and call `pi.registerProvider(...)` before startup finishes. The provider is then available to interactive startup and `pi --list-models`. This is the recommended way to wire Ollama/LM Studio/vLLM.
6. **State management with two entry types** — `pi.appendEntry("custom", data)` writes state that does **not** enter the LLM context; `pi.appendEntry("custom_message", ...)` writes extension messages that **do** enter context. `customType` discriminates owner on reload.
7. **Custom tools and rendering** — `pi.registerTool({ name, description, parameters, execute, truncation? })`. Registering a tool with a built-in's name overrides it. `pi.registerMessageRenderer(customType, renderer)` and `ctx.ui.custom()` give full TUI control. Theme tokens: `ctx.ui.theme.text`, `ctx.ui.theme.accent`, etc.
8. **Error/mode guards** — try/catch in async handlers; `ctx.ui.notify()` for user-facing errors. UI features require `ctx.hasUI`; non-interactive modes (`-p`, `json`, `rpc`) skip them.

## Connections
- Related concepts: [[wiki/concepts/pi-extension-lifecycle]]
- Projects: [[wiki/entities/pi-cli]]
- Sources: [[wiki/sources/pi-usage]], [[wiki/sources/pi-custom-provider]], [[wiki/sources/pi-models]]

---

- 2026-06-16 [CommandCode]: Page created
