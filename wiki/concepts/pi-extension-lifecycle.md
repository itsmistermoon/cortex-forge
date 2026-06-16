---
title: Pi Extension Lifecycle
type: concept
created: 2026-06-16
updated: 2026-06-16
tags: [pi, extensions, lifecycle, events, typescript, hot-reload, modes, oauth, providers]
aliases: [pi-extension-system, pi lifecycle, ExtensionContext]
sources:
  - wiki/sources/pi-extensions.md
  - wiki/sources/pi-usage.md
confidence: high
schema_version: "0.3"
---

# Pi Extension Lifecycle

[Compiled truth — best current understanding. Rewrite in full when new evidence arrives.]

Pi's extension system is a TypeScript-first lifecycle hook framework that turns the agent's runtime into an event-sourced, provider-pluggable substrate. It is the load-bearing abstraction for everything pi does not bake into the core: tools, commands, custom UI, OAuth flows, custom streaming APIs, and state persistence.

## The mental model

An extension is a default-exported function — sync or `async` — that receives a single `ExtensionAPI` argument and uses it to register behaviour. pi auto-discovers `*.ts`/`*.js` from `~/.pi/agent/extensions/` (global) and `.pi/extensions/` (project-local) at startup; `pi -e ./path.ts` is a one-off for the current run. The discovered set is hot-reloadable via `/reload` — the canonical reason to use auto-discovered locations rather than the `-e` flag.

Because the factory is allowed to be `async`, an extension can perform network I/O (model discovery, OAuth, schema fetches) before startup finishes. The runtime guarantees that any provider registered from the factory is visible to the interactive startup banner and to `pi --list-models`. This is the only sanctioned way to add a dynamic provider: don't try to register from a `session_start` handler.

## Event taxonomy (one axis)

Pi fires events at the points in a session where a meaningful state transition happens. The events fall into eight categories:

| Category | Events | When it fires | What you can do |
|----------|--------|---------------|-----------------|
| Startup | `startup` | When pi starts | Register providers, prompt templates, themes |
| Startup | `project_trust` | Before the project trust decision | Advise on the trust verdict |
| Resource | `resource_discovery` | Custom resource discovery hook | Inject skills/prompts/themes from outside the conventions |
| Session | `session_start` / `session_end` / `session_fork` | New or resumed session; session closing; session forked from another | Inject context, persist final state, rewire context for forks |
| Agent | `before_agent_start` / `agent_start` / `agent_end` | Wrap an agent turn | Modify the system prompt, observe turn boundaries |
| Model | `model_select` / `model_register` | User picked a model; provider/model registered | React to user choices, finalize model registration |
| Tool | `tool_call` / `tool_result` | LLM invoked a tool; tool returned | Block or modify; render custom output |
| User bash | `user_bash` | User ran `!command` | Inspect, sanitize, gate |
| Input | `user_input` | Generic user input | Preprocess before it reaches the agent |

The `tool_call` and `tool_result` events are interceptors: returning a non-null value from the handler can block or modify the call. The `before_agent_start` event is the equivalent place to rewrite the system prompt or inject context. Together these three are the closest analogue to a `PreToolUse`/`PostToolUse`/`SessionStart` hook in a hooks-based agent — except the wire format is a function call, not a JSON-on-stdin shell command.

## ExtensionContext (the runtime handle)

Every event handler receives `(event, ctx)`. `ctx` is the runtime handle; it changes shape between contexts:

- `ExtensionContext` (everywhere) — `ui` (`select`/`confirm`/`input`/`notify`/`custom`/`setStatus`/`theme`), `mode` (`text`/`json`/`rpc`/`print`), `hasUI`, `cwd`, `isProjectTrusted()`, `sessionManager`, `modelRegistry`, `model`, `signal` (AbortSignal), `isIdle`/`abort`/`hasPendingMessages`, `shutdown()`, `getContextUsage()`, `compact()`, `getSystemPrompt()`.
- `ExtensionCommandContext` (slash commands) — adds `getSystemPromptOptions()`, `waitForIdle()`, `newSession({ parentSession? })`, `fork(entryId, options?)`, `navigateTree(targetId, options?)`, `switchSession(sessionPath, options?)`, `reload()`.

The most common footgun: replacing the current session (`newSession`/`switchSession`/`fork`) while the UI is still showing the old one. If your handler mutates session state significantly, call `ctx.reload()` so the TUI re-reads from disk.

## ExtensionAPI (the registration surface)

The `pi` argument is the registration surface. The most-used methods:

- **Events:** `pi.on(event, handler)`
- **Tools:** `pi.registerTool({ name, description, parameters, execute, truncation? })`. Registering a tool with a built-in's name overrides it. Tools can call `ctx.exec()` for remote execution.
- **LLM messages:** `pi.sendMessage(message, options?)`, `pi.sendUserMessage(content, options?)`
- **Persistence:** `pi.appendEntry(customType, data?)` (state, **not** in LLM context) vs `pi.appendEntry("custom_message", ...)` (extension message, **in** LLM context)
- **UI:** `pi.registerMessageRenderer(customType, renderer)`, `pi.registerShortcut(shortcut, options)`, `pi.registerFlag(name, options)`, `pi.registerCommand(name, options)`, `pi.getCommands()`
- **Models:** `pi.setModel(model)`, `pi.getThinkingLevel()` / `pi.setThinkingLevel(level)`, `pi.registerProvider(name, config)` / `pi.unregisterProvider(name)`
- **Tools as a set:** `pi.getActiveTools()` / `pi.getAllTools()` / `pi.setActiveTools(names)`
- **Session meta:** `pi.setSessionName(name)` / `pi.getSessionName()`, `pi.setLabel(entryId, label)`, `pi.exec(command, args, options?)`, `pi.events`

## State and the custom-vs-custom_message split

Pi gives extensions two persistence primitives, distinguished by whether they enter the LLM context:

| Entry kind | Type discriminator | In LLM context? | Typical use |
|------------|--------------------|------------------|--------------|
| `CustomEntry` | `type: "custom"` | No | Per-session state that survives restart (counters, caches, config) |
| `CustomMessageEntry` | `type: "custom_message"` | Yes | Context injection that should be visible to the model |

Both share `customType` (your extension's namespace) and a `details` field for per-extension metadata (not sent to the LLM for `custom_message`). The `display: true|false` flag on `custom_message` controls TUI visibility. The `appendEntry` API on `pi` maps to the first; the JSONL format docs name the second explicitly.

## Provider registration as lifecycle

A provider is just data registered against the runtime. Two equivalent ways:

1. **Declarative** in `~/.pi/agent/models.json` — static, reloaded each time `/model` opens. Best for built-in providers, proxies, and self-hosted endpoints with fixed model lists. The value-resolution syntax (`!command`, `$ENV`, `$$`, `$!`) lets `apiKey` and `headers` defer to shell or environment.
2. **Programmatic** in an extension — `pi.registerProvider(name, config)` (sync handler) or from an async factory (dynamic model discovery). `pi.unregisterProvider(name)` reverses it: dynamic models, API key fallback, OAuth registration, and custom stream handlers are removed; overridden built-ins are restored. Applied immediately, no `/reload` needed.

The OAuth block on a provider wires it into `/login`: `login(callbacks)`, `refreshToken(credentials)`, `getApiKey(credentials)`, optional `modifyModels(models, credentials)`. Credentials are persisted in `~/.pi/agent/auth.json` as `{ refresh, access, expires }`. The four callback shapes (`onAuth`, `onDeviceCode`, `onPrompt`, `onSelect`) cover browser, device-code, manual, and interactive-selector flows without the extension needing to know which the user prefers.

For non-standard streaming APIs, the provider config carries a `streamSimple` function built on `createAssistantMessageEventStream()`. The protocol is strictly ordered: `start` → content blocks (`text_*` / `thinking_*` / `toolcall_*` with `contentIndex` and accumulating `partial`) → `done({reason, message})` or `error({reason, error})`. Tool calls require accumulating partial JSON and parsing as it streams.

## Context-overflow recovery as a lifecycle event

When the provider returns an error whose message doesn't match pi's known overflow patterns, the extension that registered the provider can normalize it on a `message_end` handler:

```ts
pi.on("message_end", (event, ctx) => {
  const m = event.message;
  if (m.role !== "assistant" || m.stopReason !== "error") return;
  if (m.provider !== "my-provider" && ctx.model?.provider !== "my-provider") return;
  if (m.errorMessage?.includes("context_length_exceeded")) return;
  if (!MY_PATTERN.test(m.errorMessage ?? "")) return;
  return { message: { ...m, errorMessage: `context_length_exceeded: ${m.errorMessage}` } };
});
```

The returned object's `errorMessage` is the new one; the LLM sees a unified phrase, and pi auto-compacts and retries. This is the canonical extension-side cooperation with pi's built-in recovery loop.

## Modes and UI gating

`ctx.mode` is one of `text` (interactive), `json`, `rpc`, or `print` (`pi -p`). Most UI features are no-ops in non-interactive modes — check `ctx.hasUI` before calling `ctx.ui.*` and always prefer `ctx.ui.notify()` for error reporting across modes. The `print` mode reads piped stdin and merges it into the initial prompt, which is the only mode that supports `cat README.md | pi -p "…"`.

## Why the design is the way it is

Pi's design principle is "small core, opt-in everything else." The lifecycle shape is the mechanism: the core fires events, the extensions subscribe. MCP, sub-agents, permission popups, plan mode, to-dos, and background bash are all moved to extensions or packages (or out to containers/tmux) rather than built in. The async factory pattern in particular is the seam that makes the runtime "wait" for extensions to register providers before startup — without it, dynamic model discovery would have to live in `session_start`, racing the user's first model pick.

## Cross-references

- Source: [[wiki/sources/pi-extensions]]
- Source: [[wiki/sources/pi-usage]]
- Source: [[wiki/sources/pi-custom-provider]] (programmatic providers, OAuth, streamSimple)
- Source: [[wiki/sources/pi-models]] (declarative providers, `compat` flags)
- Source: [[wiki/sources/pi-session-format]] (JSONL tree that the lifecycle writes into)
- Entity: [[wiki/entities/pi-cli]]

---

- 2026-06-16 [CommandCode]: Page created
