---
title: Pi ExtensionAPI methods
type: concept
created: 2026-06-16
updated: 2026-06-16
tags: [pi, extensions, api, reference]
sources:
  - wiki/sources/pi-extensions.md
confidence: high
schema_version: "0.3"
aliases: []
---

# Pi ExtensionAPI methods

Top-level `pi` object methods available to extensions. The `pi` parameter is the `ExtensionAPI` instance. See [[pi-event-types]] for the lifecycle events you can subscribe to and the `ExtensionContext` (ctx) shape.

## Quick Start

```ts
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (event, ctx) => {
    ctx.ui.notify("Extension loaded!");
  });
}
```

The factory can also be `async`. For dynamic model discovery, fetch and register models in the factory instead of `session_start` — pi waits for the factory before startup continues, so the provider is available during interactive startup and to `pi --list-models`.

## Methods

| Method | Purpose |
|--------|---------|
| `pi.on(event, handler)` | Subscribe to a lifecycle event — see [[pi-event-types]] |
| `pi.registerTool(definition)` | Register a custom tool callable by the LLM |
| `pi.sendMessage(message, options?)` | Send a message into the conversation |
| `pi.sendUserMessage(content, options?)` | Send a user message into the conversation |
| `pi.appendEntry(customType, data?)` | Persist extension state to the session (session-scoped) |
| `pi.setSessionName(name)` | Set the session display name |
| `pi.getSessionName()` | Get the session display name |
| `pi.setLabel(entryId, label)` | Set/clear a label on a session entry |
| `pi.registerCommand(name, options)` | Register a custom slash command |
| `pi.getCommands()` | List all registered commands |
| `pi.registerMessageRenderer(customType, renderer)` | Render extension messages with custom UI |
| `pi.registerShortcut(shortcut, options)` | Register a keybinding |
| `pi.registerFlag(name, options)` | Register a custom CLI flag |
| `pi.exec(command, args, options?)` | Execute an external command (process spawning) |
| `pi.getActiveTools()` | Get currently active tool names |
| `pi.getAllTools()` | Get all available tool names |
| `pi.setActiveTools(names)` | Set the active tool list |
| `pi.setModel(model)` | Switch the active model |
| `pi.getThinkingLevel()` | Get current thinking level |
| `pi.setThinkingLevel(level)` | Set the thinking level |
| `pi.events` | Access to the event system / bus |
| `pi.registerProvider(name, config)` | Register or override a model provider |
| `pi.unregisterProvider(name)` | Unregister a previously-registered provider |

## Custom Tools

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

- Registering a tool with the same name as a built-in overrides it.
- Tools can run commands on remote systems via `ctx.exec()`.
- Tool results are truncated by default; configure via `truncation` field in tool definition.
- One extension can register many tools.

## State Management

| Method | LLM Context | Scope |
|--------|-------------|-------|
| `pi.appendEntry(customType, data?)` | No (uses `custom` entry type) | Session-scoped |
| `pi.sendUserMessage(content, options?)` | Yes (uses `custom_message` entry type) | Session-scoped |
| `pi.sendMessage(message, options?)` | Yes (uses `custom_message` entry type) | Session-scoped |

`custom` entry type is NOT in LLM context; `custom_message` IS. See [[pi-session-file-format]] for entry type details.

## Custom Rendering

| Method | Purpose |
|--------|---------|
| `pi.registerMessageRenderer(customType, renderer)` | Render extension messages with custom UI |
| `ctx.ui.setStatus()` | Footer status indicator |
| `ctx.ui.custom()` | Full custom TUI component with keyboard input |
| `ctx.ui.theme.*` | Theme color tokens (`text`, `accent`, etc.) |

## Custom UI Dialogs (ctx.ui)

| Method | Purpose |
|--------|---------|
| `ctx.ui.select()` | Selection dialog |
| `ctx.ui.confirm()` | Confirmation dialog |
| `ctx.ui.input()` | Text input dialog |
| `ctx.ui.notify()` | Notification message |
| `ctx.ui.custom()` | Full custom TUI component |
| `ctx.ui.setStatus()` | Footer status indicator |

## Autocomplete

Register autocompletion sources for the editor (provider API on the `pi` object). Consult the [extensions docs](https://pi.dev/docs/latest/extensions) for the specific method name.

## Custom Editor

Replace the entire editor with custom logic (extension API on `pi`). Consult the [extensions docs](https://pi.dev/docs/latest/extensions) for the specific method name.

## Provider Registration

```ts
pi.registerProvider("my-provider", {
  name: "My Provider",
  baseUrl: "https://api.example.com",
  apiKey: "$MY_API_KEY",
  api: "openai-completions",
  models: [
    {
      id: "my-model",
      name: "My Model",
      reasoning: false,
      input: ["text", "image"],
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
      contextWindow: 128000,
      maxTokens: 4096
    }
  ]
});
```

`apiKey` and custom header values use the same syntax as `models.json`: `!command` at the start, `$ENV_VAR` / `${ENV_VAR}` for env interpolation, `$$` for literal `$`, `$!` for literal `!`. See [[pi-models-json#value-resolution]].

When only `baseUrl` and/or `headers` are provided (no `models`), all existing models for that provider are preserved with the new endpoint. When `models` is provided, it **replaces** all existing models.

```ts
// Unregister — removes dynamic models, API key fallback, OAuth provider registration, custom stream handler
pi.unregisterProvider("my-llm");
```

Calls made after the initial extension load phase are applied immediately, so no `/reload` is required.

## Auth Header

```ts
pi.registerProvider("custom-api", {
  baseUrl: "https://api.example.com",
  apiKey: "$MY_API_KEY",
  authHeader: true, // adds Authorization: Bearer header
  api: "openai-completions",
  models: [...]
});
```

## OAuth Support

```ts
import type { OAuthCredentials, OAuthLoginCallbacks } from "@earendil-works/pi-ai";

pi.registerProvider("corporate-ai", {
  baseUrl: "https://ai.corp.com/v1",
  api: "openai-responses",
  models: [...],
  oauth: {
    name: "Corporate AI (SSO)",
    async login(callbacks: OAuthLoginCallbacks): Promise<OAuthCredentials> {
      const method = await callbacks.onSelect({
        message: "Select login method:",
        options: [
          { id: "browser", label: "Browser OAuth" },
          { id: "device", label: "Device code" }
        ]
      });
      if (!method) throw new Error("Login cancelled");
      // ... exchange code for tokens
    },
    async refreshToken(credentials: OAuthCredentials): Promise<OAuthCredentials> {
      // ... refresh logic
    },
    getApiKey(credentials: OAuthCredentials): string {
      return credentials.access;
    },
  }
});
```

After registration, users authenticate via `/login corporate-ai`.

### OAuthLoginCallbacks

| Callback | Purpose |
|----------|---------|
| `onAuth({ url })` | Open URL in browser |
| `onDeviceCode({ userCode, verificationUri, intervalSeconds?, expiresInSeconds? })` | Device authorization flow |
| `onPrompt({ message })` | Manual token entry |
| `onSelect({ message, options })` | Interactive selector |

### OAuthCredentials

```ts
interface OAuthCredentials {
  refresh: string;   // Refresh token (for refreshToken())
  access: string;    // Access token (returned by getApiKey())
  expires: number;   // Expiration timestamp in milliseconds
}
```

Credentials are persisted in `~/.pi/agent/auth.json`.

## Available Imports

Extensions import from `@earendil-works/pi-coding-agent` and related packages:

```ts
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import type { OAuthCredentials, OAuthLoginCallbacks } from "@earendil-works/pi-ai";
```

## Bundled Pi Packages (peerDependencies)

Pi bundles core packages for extensions and skills. If you import any of these, list them in `peerDependencies` with a `"*"` range and do not bundle them:
- `@earendil-works/pi-ai`
- `@earendil-works/pi-agent-core`
- `@earendil-works/pi-coding-agent`
- `@earendil-works/pi-tui`
- `typebox`

Other pi packages must be bundled in your tarball. Add them to `dependencies` and `bundledDependencies`, then reference their resources through `node_modules/` paths. Pi loads packages with separate module roots.

## Examples

See `examples/extensions/` in the [pi-mono repository](https://github.com/earendil-works/pi-mono/tree/main/packages/coding-agent/examples/extensions) for:
- Custom tools
- Custom providers
- UI components
- OAuth flows
- Compaction overrides

---

- 2026-06-16 [CommandCode]: Page created
