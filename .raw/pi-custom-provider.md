---
url: https://pi.dev/docs/latest/custom-provider
fetched: 2026-06-16
agent: CommandCode
locale: en
---

# Custom Providers — pi.dev/docs/latest/custom-provider

Source: https://pi.dev/docs/latest/custom-provider

Extensions can register custom model providers via `pi.registerProvider()`. This enables:
- **Proxies** — Route requests through corporate proxies or API gateways
- **Custom endpoints** — Use self-hosted or private model deployments
- **OAuth/SSO** — Add authentication flows for enterprise providers
- **Custom APIs** — Implement streaming for non-standard LLM APIs

## Example Extensions

See these complete provider examples:
- [`examples/extensions/custom-provider-anthropic/`](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/examples/extensions/custom-provider-anthropic)
- [`examples/extensions/custom-provider-gitlab-duo/`](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/examples/extensions/custom-provider-gitlab-duo)

## Quick Reference

```ts
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  // Override baseUrl for existing provider
  pi.registerProvider("anthropic", {
    baseUrl: "https://proxy.example.com"
  });

  // Register new provider with models
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
}
```

The extension factory can also be `async`. For dynamic model discovery, fetch and register models in the factory instead of `session_start`. pi waits for the factory before startup continues, so the provider is available during interactive startup and to `pi --list-models`.

## Override Existing Provider

The simplest use case: redirect an existing provider through a proxy.

```ts
// All Anthropic requests now go through your proxy
pi.registerProvider("anthropic", {
  baseUrl: "https://proxy.example.com"
});

// Add custom headers to OpenAI requests
pi.registerProvider("openai", {
  headers: {
    "X-Custom-Header": "value"
  }
});

// Both baseUrl and headers
pi.registerProvider("google", {
  baseUrl: "https://ai-gateway.corp.com/google",
  headers: {
    "X-Corp-Auth": "$CORP_AUTH_TOKEN" // env var or literal
  }
});
```

When only `baseUrl` and/or `headers` are provided (no `models`), all existing models for that provider are preserved with the new endpoint.

## Register New Provider

To add a completely new provider, specify `models` along with the required configuration.

If the model list comes from a remote endpoint, use an async extension factory:

```ts
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default async function (pi: ExtensionAPI) {
  const response = await fetch("http://localhost:1234/v1/models");
  const payload = (await response.json()) as {
    data: Array<{
      id: string;
      name?: string;
      context_window?: number;
      max_tokens?: number;
    }>;
  };
  pi.registerProvider("local-openai", {
    baseUrl: "http://localhost:1234/v1",
    apiKey: "$LOCAL_OPENAI_API_KEY",
    api: "openai-completions",
    models: payload.data.map((model) => ({
      id: model.id,
      name: model.name ?? model.id,
      reasoning: false,
      input: ["text"],
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
      contextWindow: model.context_window ?? 128000,
      maxTokens: model.max_tokens ?? 4096,
    })),
  });
}
```

This registers the fetched models before startup finishes.

When `models` is provided, it **replaces** all existing models for that provider.

`apiKey` and custom header values use the same config value syntax as `models.json`: `!command` at the start executes a command for the whole value, `$ENV_VAR` and `${ENV_VAR}` interpolate environment variables, `$$` emits a literal `$`, and `$!` emits a literal `!`.

## Unregister Provider

Use `pi.unregisterProvider(name)` to remove a provider that was previously registered via `pi.registerProvider(name, ...)`:

```ts
// Later, remove it
pi.unregisterProvider("my-llm");
```

Unregistering removes that provider's dynamic models, API key fallback, OAuth provider registration, and custom stream handler registrations. Any built-in models or provider behavior that were overridden are restored.

Calls made after the initial extension load phase are applied immediately, so no `/reload` is required.

### API Types

The `api` field determines which streaming implementation is used:

| API | Use for |
|-----|---------|
| `anthropic-messages` | Anthropic Claude API and compatibles |
| `openai-completions` | OpenAI Chat Completions API and compatibles |
| `openai-responses` | OpenAI Responses API |
| `azure-openai-responses` | Azure OpenAI Responses API |
| `openai-codex-responses` | OpenAI Codex Responses API |
| `mistral-conversations` | Mistral SDK Conversations/Chat streaming |
| `google-generative-ai` | Google Generative AI API |
| `google-vertex` | Google Vertex AI API |
| `bedrock-converse-stream` | Amazon Bedrock Converse API |

Most OpenAI-compatible providers work with `openai-completions`. Use model-level `thinkingLevelMap` for model-specific thinking levels, and `compat` for provider quirks.

> Migration note: Mistral moved from `openai-completions` to `mistral-conversations`. Use `mistral-conversations` for native Mistral models. If you intentionally route Mistral-compatible/custom endpoints through `openai-completions`, set `compat` flags explicitly as needed.

### Auth Header

If your provider expects `Authorization: Bearer <key>` but doesn't use a standard API, set `authHeader: true`:

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

Add OAuth/SSO authentication that integrates with `/login`:

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

After registration, users can authenticate via `/login corporate-ai`.

### OAuthLoginCallbacks

The `callbacks` object provides four ways to authenticate:
- `onAuth({ url })` — Open URL in browser
- `onDeviceCode({ userCode, verificationUri, intervalSeconds?, expiresInSeconds? })` — Device authorization flow
- `onPrompt({ message })` — Manual token entry
- `onSelect({ message, options })` — Interactive selector

### OAuthCredentials

Credentials are persisted in `~/.pi/agent/auth.json`:

```ts
interface OAuthCredentials {
  refresh: string;   // Refresh token (for refreshToken())
  access: string;    // Access token (returned by getApiKey())
  expires: number;   // Expiration timestamp in milliseconds
}
```

## Custom Streaming API

For providers with non-standard APIs, implement `streamSimple`. Study the existing provider implementations before writing your own:

**Reference implementations:**
- `anthropic.ts` — Anthropic Messages API
- `mistral.ts` — Mistral Conversations API
- `openai-completions.ts` — OpenAI Chat Completions
- `openai-responses.ts` — OpenAI Responses API
- `google.ts` — Google Generative AI
- `amazon-bedrock.ts` — AWS Bedrock

### Stream Pattern

All providers follow the same pattern using `createAssistantMessageEventStream()`:

```ts
import {
  type AssistantMessage,
  type AssistantMessageEventStream,
  type Context,
  type Model,
  type SimpleStreamOptions,
  calculateCost,
  createAssistantMessageEventStream,
} from "@earendil-works/pi-ai";

function streamMyProvider(
  model: Model<any>,
  context: Context,
  options?: SimpleStreamOptions
): AssistantMessageEventStream {
  const stream = createAssistantMessageEventStream();

  (async () => {
    const output: AssistantMessage = {
      role: "assistant",
      content: [],
      api: model.api,
      provider: model.provider,
      model: model.id,
      usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, totalTokens: 0, cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 } },
      stopReason: "stop",
      timestamp: Date.now(),
    };

    try {
      stream.push({ type: "start", partial: output });
      // Make API request and process response...
      stream.push({ type: "done", reason: "stop", message: output });
      stream.end();
    } catch (error) {
      output.stopReason = options?.signal?.aborted ? "aborted" : "error";
      output.errorMessage = error instanceof Error ? error.message : String(error);
      stream.push({ type: "error", reason: output.stopReason, error: output });
      stream.end();
    }
  })();

  return stream;
}
```

### Event Types

Push events via `stream.push()` in order:
1. `{ type: "start", partial: output }` — Stream started
2. Content events (repeatable, track `contentIndex` for each block):
   - `{ type: "text_start", contentIndex, partial }` — Text block started
   - `{ type: "text_delta", contentIndex, delta, partial }` — Text chunk
   - `{ type: "text_end", contentIndex, content, partial }` — Text block ended
   - `{ type: "thinking_start", contentIndex, partial }` — Thinking started
   - `{ type: "thinking_delta", contentIndex, delta, partial }` — Thinking chunk
   - `{ type: "thinking_end", contentIndex, content, partial }` — Thinking ended
   - `{ type: "toolcall_start", contentIndex, partial }` — Tool call started
   - `{ type: "toolcall_delta", contentIndex, delta, partial }` — Tool call JSON chunk
   - `{ type: "toolcall_end", contentIndex, toolCall, partial }` — Tool call ended
3. `{ type: "done", reason, message }` or `{ type: "error", reason, error }` — Stream ended

### Content Blocks

Add blocks to `output.content` as they arrive:

```ts
// Text block
output.content.push({ type: "text", text: "" });
stream.push({ type: "text_start", contentIndex: output.content.length - 1, partial: output });

// As text arrives
const block = output.content[contentIndex];
if (block.type === "text") {
  block.text += delta;
  stream.push({ type: "text_delta", contentIndex, delta, partial: output });
}
```

### Tool Calls

Tool calls require accumulating JSON and parsing:

```ts
output.content.push({ type: "toolCall", id: toolCallId, name: toolName, arguments: {} });
stream.push({ type: "toolcall_start", contentIndex: output.content.length - 1, partial: output });

let partialJson = "";
partialJson += jsonDelta;
try {
  block.arguments = JSON.parse(partialJson);
} catch {}
stream.push({ type: "toolcall_delta", contentIndex, delta: jsonDelta, partial: output });
```

### Usage and Cost

Update usage from API response:

```ts
output.usage.input = response.usage.input_tokens;
output.usage.output = response.usage.output_tokens;
output.usage.cacheRead = response.usage.cache_read_tokens ?? 0;
output.usage.cacheWrite = response.usage.cache_write_tokens ?? 0;
output.usage.totalTokens = output.usage.input + output.usage.output + output.usage.cacheRead + output.usage.cacheWrite;
calculateCost(model, output.usage);
```

### Context Overflow Errors

When a request exceeds the model's context window, pi can recover automatically by compacting and retrying. Detection runs on the finalized assistant message:
- `stopReason === "error"`
- `errorMessage` matches one of pi's known overflow patterns (see `packages/ai/src/utils/overflow.ts`)

If your provider returns overflow errors with a message pi does not recognize, normalize the error from the same extension that registers the provider. Use a `message_end` handler to rewrite the assistant message so its `errorMessage` starts with a phrase pi recognizes. The generic fallback `context_length_exceeded` is the safest choice.

```ts
const MY_PROVIDER_OVERFLOW_PATTERN = /your provider's overflow phrase/i;

export default function (pi: ExtensionAPI) {
  pi.registerProvider("my-provider", { /* ... */ });

  pi.on("message_end", (event, ctx) => {
    const message = event.message;
    if (message.role !== "assistant") return;
    if (message.stopReason !== "error") return;
    if (message.provider !== "my-provider" && ctx.model?.provider !== "my-provider") return;

    const errorMessage = message.errorMessage ?? "";
    if (errorMessage.includes("context_length_exceeded")) return;
    if (!MY_PROVIDER_OVERFLOW_PATTERN.test(errorMessage)) return;

    return {
      message: { ...message, errorMessage: `context_length_exceeded: ${errorMessage}` },
    };
  });
}
```

### Registration

Register your stream function:

```ts
pi.registerProvider("my-provider", {
  baseUrl: "https://api.example.com",
  apiKey: "$MY_API_KEY",
  api: "my-custom-api",
  models: [...],
  streamSimple: streamMyProvider
});
```

## Testing Your Implementation

Test your provider against the same test suites used by built-in providers. Copy and adapt from `packages/ai/test/`:

| Test | Purpose |
|------|---------|
| `stream.test.ts` | Basic streaming, text output |
| `tokens.test.ts` | Token counting and usage |
| `abort.test.ts` | AbortSignal handling |
| `empty.test.ts` | Empty/minimal responses |
| `context-overflow.test.ts` | Context window limits |
| `image-limits.test.ts` | Image input handling |
| `unicode-surrogate.test.ts` | Unicode edge cases |
| `tool-call-without-result.test.ts` | Tool call edge cases |
| `image-tool-result.test.ts` | Images in tool results |
| `total-tokens.test.ts` | Total token calculation |
| `cross-provider-handoff.test.ts` | Context handoff between providers |

Run tests with your provider/model pairs to verify compatibility.

## Config Reference

```ts
interface ProviderConfig {
  /** Display name for the provider in UI such as /login. */
  name?: string;
  /** API endpoint URL. Required when defining models. */
  baseUrl?: string;
  /** API key literal, env interpolation ($ENV_VAR or ${ENV_VAR}), or !command. */
  apiKey?: string;
  /** API type for streaming. Required at provider or model level when defining models. */
  api?: Api;
  /** Custom streaming implementation for non-standard APIs. */
  streamSimple?: (model: Model<Api>, context: Context, options?: SimpleStreamOptions) => AssistantMessageEventStream;
  /** Custom headers to include in requests. */
  headers?: Record<string, string>;
  /** If true, adds Authorization: Bearer header with the resolved API key. */
  authHeader?: boolean;
  /** Models to register. If provided, replaces all existing models for this provider. */
  models?: ProviderModelConfig[];
  /** OAuth provider for /login support. */
  oauth?: {
    name: string;
    login(callbacks: OAuthLoginCallbacks): Promise<OAuthCredentials>;
    refreshToken(credentials: OAuthCredentials): Promise<OAuthCredentials>;
    getApiKey(credentials: OAuthCredentials): string;
    modifyModels?(models: Model<Api>[], credentials: OAuthCredentials): Model<Api>[];
  };
}
```

## Model Definition Reference

```ts
interface ProviderModelConfig {
  id: string;
  name: string;
  api?: Api;
  baseUrl?: string;
  reasoning: boolean;
  thinkingLevelMap?: Partial<Record<"off" | "minimal" | "low" | "medium" | "high" | "xhigh", string | null>>;
  input: ("text" | "image")[];
  cost: { input: number; output: number; cacheRead: number; cacheWrite: number };
  contextWindow: number;
  maxTokens: number;
  headers?: Record<string, string>;
  compat?: {
    // openai-completions
    supportsStore?: boolean;
    supportsDeveloperRole?: boolean;
    supportsReasoningEffort?: boolean;
    supportsUsageInStreaming?: boolean;
    maxTokensField?: "max_completion_tokens" | "max_tokens";
    requiresToolResultName?: boolean;
    requiresAssistantAfterToolResult?: boolean;
    requiresThinkingAsText?: boolean;
    requiresReasoningContentOnAssistantMessages?: boolean;
    thinkingFormat?: "openai" | "openrouter" | "deepseek" | "together" | "zai" | "qwen" | "qwen-chat-template";
    cacheControlFormat?: "anthropic";
    // anthropic-messages
    supportsEagerToolInputStreaming?: boolean;
    supportsLongCacheRetention?: boolean;
    sendSessionAffinityHeaders?: boolean;
    supportsCacheControlOnTools?: boolean;
    forceAdaptiveThinking?: boolean;
    allowEmptySignature?: boolean;
  };
}
```
