---
title: Pi extension event types
type: reference
created: 2026-06-16
updated: 2026-06-16
tags: [pi, extensions, events, lifecycle, reference]
sources:
  - wiki/sources/pi-extensions.md
confidence: high
schema_version: "0.3"
---

# Pi extension event types

Pi fires events at lifecycle points. Extensions subscribe via `pi.on(event, handler)`. See [[pi-extension-api]] for the registration method.

## Event Categories

Startup, Resource, Session, Agent, Model, Tool, User, Bash, Input.

## Startup Events

| Event | When | What it can do |
|-------|------|----------------|
| `startup` | Fired when pi starts | Register providers, prompt templates, etc. |
| `project_trust` | Fired before project trust decision | Extensions can advise |

## Resource Events

| Event | When | What it can do |
|-------|------|----------------|
| `resource_discovery` | Custom resource discovery | Add custom resources |

## Session Events

| Event | When | What it can do |
|-------|------|----------------|
| `session_start` | New or resumed session | Initialize per-session state |
| `session_end` | Session closing | Clean up resources |
| `session_fork` | Session forked from another | Adjust for new context |

## Agent Events

| Event | When | What it can do |
|-------|------|----------------|
| `before_agent_start` | Before an agent turn | Modify system prompt or context |
| `agent_start` | An agent turn begins | Track turn boundary |
| `agent_end` | An agent turn ends | Track turn boundary, post-process |

## Model Events

| Event | When | What it can do |
|-------|------|----------------|
| `model_select` | User picked a model | React to user choice |
| `model_register` | Provider/model registered | React to registration |

## Tool Events

| Event | When | What it can do |
|-------|------|----------------|
| `tool_call` | LLM invoked a tool | Block or modify the call |
| `tool_result` | Tool returned | Block or modify the result |

## User Bash Events

| Event | When | What it can do |
|-------|------|----------------|
| `user_bash` | User ran a shell command (`!command`) | Inspect, log, or block |

## Input Events

| Event | When | What it can do |
|-------|------|----------------|
| `user_input` | Generic user input | Inspect or transform user input |

## ExtensionContext

`ctx` passed to handlers. Properties:

| Property | Type | Description |
|----------|------|-------------|
| `ctx.ui` | UI API | `select()`, `confirm()`, `input()`, `notify()`, `custom()`, `setStatus()`, theme access |
| `ctx.mode` | `"text" \| "json" \| "rpc" \| "print"` | Current mode (e.g. `print` = `pi -p`) |
| `ctx.hasUI` | `boolean` | True in interactive mode |
| `ctx.cwd` | `string` | Current working directory |
| `ctx.isProjectTrusted()` | `() => boolean` | Project trust state |
| `ctx.sessionManager` | `SessionManager` | Session management API |
| `ctx.modelRegistry` | `ModelRegistry` | Current model registry |
| `ctx.model` | `Model` | Selected model |
| `ctx.signal` | `AbortSignal` | AbortSignal for cancellation |
| `ctx.isIdle()` | `() => boolean` | Check if agent is idle |
| `ctx.abort()` | `() => void` | Abort the current operation |
| `ctx.hasPendingMessages()` | `() => boolean` | Check for queued messages |
| `ctx.shutdown()` | `() => void` | Request shutdown of current session |
| `ctx.getContextUsage()` | `() => ContextUsage` | Current context token usage |
| `ctx.compact()` | `() => Promise<void>` | Trigger context compaction |
| `ctx.getSystemPrompt()` | `() => string` | Read current system prompt |
| `ctx.reload()` | `() => void` | Reload current session from disk |

## ExtensionCommandContext

When a slash command runs, a richer context is passed.

| Property | Description |
|----------|-------------|
| `ctx.getSystemPromptOptions()` | Get current system prompt composition options |
| `ctx.waitForIdle()` | Wait for the agent to finish its current work |
| `ctx.newSession(options?)` | Start a new session. Options: `{ parentSession?: string }` |
| `ctx.fork(entryId, options?)` | Fork from a specific entry |
| `ctx.navigateTree(targetId, options?)` | Jump to a tree position |
| `ctx.switchSession(sessionPath, options?)` | Switch to a different session file |
| `ctx.reload()` | Reload current session from disk |

### Session Replacement Footgun

When you replace the current session, ongoing UI may need to reload — extensions should use `ctx.reload()` if they mutate session state significantly.

## Mode Behavior

Some features only work in interactive mode (e.g., `ctx.ui`). Check `ctx.hasUI` first.

## Error Handling

Try/catch in async handlers; `ctx.ui.notify()` for user-facing errors.

## Long-lived Resources and Shutdown

Use `ctx.shutdown()` to clean up. Async abort signals via `ctx.signal`.

## Examples

See `examples/extensions/` in the [pi-mono repository](https://github.com/earendil-works/pi-mono/tree/main/packages/coding-agent/examples/extensions) for:
- Custom tools
- Custom providers
- UI components
- OAuth flows
- Compaction overrides

---

- 2026-06-16 [CommandCode]: Page created
