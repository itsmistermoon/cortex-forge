---
url: https://pi.dev/docs/latest/extensions
fetched: 2026-06-16
agent: CommandCode
locale: en
note: SPA-rendered page; content extracted from rendered HTML inside <main>
---

# Extensions — pi.dev/docs/latest/extensions

Source: https://pi.dev/docs/latest/extensions

> pi can create extensions. Ask it to build one for your use case.

Extensions are TypeScript modules that extend pi's behavior. They can subscribe to lifecycle events, register custom tools callable by the LLM, add commands, and more.

## Quick Start

**Placement for `/reload`:** Put extensions in `~/.pi/agent/extensions/` (global) or `.pi/extensions/` (project-local) for auto-discovery. Use `pi -e ./path.ts` only for quick tests. Extensions in auto-discovered locations can be hot-reloaded with `/reload`.

### Key capabilities
- **Custom tools** — Register tools the LLM can call via `pi.registerTool()`
- **Event interception** — Block or modify tool calls, inject context, customize compaction
- **User interaction** — Prompt users via `ctx.ui` (select, confirm, input, notify)
- **Custom UI components** — Full TUI components with keyboard input via `ctx.ui.custom()` for complex interactions
- **Custom commands** — Register commands like `/mycommand` via `pi.registerCommand()`
- **Session persistence** — Store state that survives restarts via `pi.appendEntry()`
- **Custom rendering** — Control how tool calls/results and messages appear in TUI

### Example use cases
- Permission gates (confirm before `rm -rf`, `sudo`, etc.)
- Git checkpointing (stash at each turn, restore on branch)
- Path protection (block writes to `.env`, `node_modules/`)
- Custom compaction (summarize conversation your way)
- Conversation summaries (see `summarize.ts` example)
- Interactive tools (questions, wizards, custom dialogs)
- Stateful tools (todo lists, connection pools)
- External integrations (file watchers, webhooks, CI triggers)
- Games while you wait (see `snake.ts` example)

## Extension Locations

Auto-discovered locations:
- `~/.pi/agent/extensions/` — global
- `.pi/extensions/` — project-local

Non-discovery (one-off): `pi -e ./path.ts` loads for the current run only.

## Available Imports

Extensions import from `@earendil-works/pi-coding-agent` and related packages:

```
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import type { OAuthCredentials, OAuthLoginCallbacks } from "@earendil-works/pi-ai";
```

## Writing an Extension

A minimal extension:

```ts
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  // Register a tool, command, or event handler
  pi.on("session_start", async (event, ctx) => {
    ctx.ui.notify("Extension loaded!");
  });
}
```

### Async factory functions

The extension factory can also be `async`. For dynamic model discovery, fetch and register models in the factory instead of `session_start`. pi waits for the factory before startup continues, so the provider is available during interactive startup and to `pi --list-models`.

```ts
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default async function (pi: ExtensionAPI) {
  const response = await fetch("http://localhost:1234/v1/models");
  const payload = (await response.json()) as { data: Array<{ id: string }> };
  pi.registerProvider("local-openai", {
    baseUrl: "http://localhost:1234/v1",
    api: "openai-completions",
    models: payload.data.map((m) => ({ id: m.id, ... }))
  });
}
```

### Long-lived resources and shutdown

Use `ctx.shutdown()` to clean up. Async abort signals via `ctx.signal`.

## Extension Styles

Extensions can include CSS-style files for custom TUI rendering (via `ctx.ui.custom()`).

## Events

Pi fires events at lifecycle points. Extensions subscribe via `pi.on(event, handler)`.

### Lifecycle Overview

Categories of events: Startup, Resource, Session, Agent, Model, Tool, User, Bash, Input.

### Startup Events

- `startup` — Fired when pi starts. Register providers, prompt templates, etc.
- `project_trust` — Fired before project trust decision; extensions can advise.

### Resource Events

- `resource_discovery` — Custom resource discovery.

### Session Events

- `session_start` — New or resumed session.
- `session_end` — Session closing.
- `session_fork` — Session forked from another.

### Agent Events

- `before_agent_start` — Modify system prompt or context.
- `agent_start` / `agent_end` — Wrap an agent turn.

### Model Events

- `model_select` — User picked a model.
- `model_register` — Provider/model registered.

### Tool Events

- `tool_call` — LLM invoked a tool.
- `tool_result` — Tool returned.
- Interceptors can block or modify.

### User Bash Events

- `user_bash` — User ran a shell command (`!command`).

### Input Events

- `user_input` — Generic user input.

## ExtensionContext

`ctx` passed to handlers. Properties include:

### `ctx.ui`

User interaction primitives: `select()`, `confirm()`, `input()`, `notify()`, `custom()`.

### `ctx.mode`

`text`, `json`, `rpc`, or `print` (pi -p).

### `ctx.hasUI`

Boolean — true in interactive mode.

### `ctx.cwd`

Current working directory.

### `ctx.isProjectTrusted()`

Boolean.

### `ctx.sessionManager`

Access to session management API.

### `ctx.modelRegistry` / `ctx.model`

Current model registry / selected model.

### `ctx.signal`

AbortSignal for cancellation.

### `ctx.isIdle()` / `ctx.abort()` / `ctx.hasPendingMessages()`

Agent state checks.

### `ctx.shutdown()`

Request shutdown of current session.

### `ctx.getContextUsage()`

Current context token usage.

### `ctx.compact()`

Trigger context compaction.

### `ctx.getSystemPrompt()`

Read current system prompt.

## ExtensionCommandContext

When a slash command runs, a richer context is passed.

### `ctx.getSystemPromptOptions()`

Get current system prompt composition options.

### `ctx.waitForIdle()`

Wait for the agent to finish its current work.

### `ctx.newSession(options?)`

Start a new session. Options: `{ parentSession?: string }`.

### `ctx.fork(entryId, options?)`

Fork from a specific entry.

### `ctx.navigateTree(targetId, options?)`

Jump to a tree position.

### `ctx.switchSession(sessionPath, options?)`

Switch to a different session file.

### Session replacement lifecycle and footguns

When you replace the current session, ongoing UI may need to reload — extensions should use `ctx.reload()` if they mutate session state significantly.

### `ctx.reload()`

Reload current session from disk.

## ExtensionAPI Methods

Top-level `pi` object methods:

### `pi.on(event, handler)`
### `pi.registerTool(definition)`
### `pi.sendMessage(message, options?)`
### `pi.sendUserMessage(content, options?)`
### `pi.appendEntry(customType, data?)`
### `pi.setSessionName(name)` / `pi.getSessionName()`
### `pi.setLabel(entryId, label)`
### `pi.registerCommand(name, options)`
### `pi.getCommands()`
### `pi.registerMessageRenderer(customType, renderer)`
### `pi.registerShortcut(shortcut, options)`
### `pi.registerFlag(name, options)`
### `pi.exec(command, args, options?)`
### `pi.getActiveTools()` / `pi.getAllTools()` / `pi.setActiveTools(names)`
### `pi.setModel(model)`
### `pi.getThinkingLevel()` / `pi.setThinkingLevel(level)`
### `pi.events`
### `pi.registerProvider(name, config)`
### `pi.unregisterProvider(name)`

## State Management

- `pi.appendEntry(customType, data?)` — Persist extension state to session.
- Session-scoped: data lives for the session.
- `custom` entry type is not in LLM context; `custom_message` is.

## Custom Tools

### Tool Definition

```ts
pi.registerTool({
  name: "my_tool",
  description: "Does something useful",
  parameters: {
    type: "object",
    properties: {
      input: { type: "string", description: "Input value" }
    },
    required: ["input"]
  },
  execute: async (args, ctx) => {
    return { type: "text", text: `Got: ${args.input}` };
  }
});
```

### Overriding Built-in Tools

Register a tool with the same name as a built-in to override.

### Remote Execution

Tools can run commands on remote systems via `ctx.exec()`.

### Output Truncation

Tool results are truncated by default; configure via `truncation` field in tool definition.

### Multiple Tools

One extension can register many tools.

## Custom Rendering

### `pi.registerMessageRenderer(customType, renderer)`

Render extension messages with custom UI.

## Custom UI

### Dialogs

`ctx.ui.select()`, `ctx.ui.confirm()`, `ctx.ui.input()` — built-in dialogs.

### Widgets, Status, and Footer

`ctx.ui.setStatus()` for footer status indicators.

### Autocomplete Providers

Register autocompletion sources for the editor.

### Custom Components

Full custom TUI components via `ctx.ui.custom()`.

### Custom Editor

Replace the entire editor with custom logic.

## Message Rendering

### Theme Colors

Use theme color tokens: `ctx.ui.theme.text`, `ctx.ui.theme.accent`, etc.

## Error Handling

Try/catch in async handlers; `ctx.ui.notify()` for user-facing errors.

## Mode Behavior

Some features only work in interactive mode (e.g., `ctx.ui`). Check `ctx.hasUI` first.

## Examples Reference

See `examples/extensions/` in the [pi-mono repository](https://github.com/earendil-works/pi-mono/tree/main/packages/coding-agent/examples/extensions) for:
- Custom tools
- Custom providers
- UI components
- OAuth flows
- Compaction overrides
