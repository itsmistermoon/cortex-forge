---
title: Pi provider API types
type: reference
created: 2026-06-16
updated: 2026-06-16
tags: [pi, provider, api, streaming, reference]
sources:
  - wiki/sources/pi-custom-provider.md
  - wiki/sources/pi-models.md
confidence: high
schema_version: "0.3"
---

# Pi provider API types

Reference for the `api` field in provider/model configuration. The `api` field determines which streaming implementation is used. Used in `~/.pi/agent/models.json` and `pi.registerProvider()`. See [[pi-models-json]] for the surrounding schema.

## Supported APIs

| API | Use for |
|-----|---------|
| `anthropic-messages` | Anthropic Claude API and compatibles |
| `openai-completions` | OpenAI Chat Completions API and compatibles (most compatible) |
| `openai-responses` | OpenAI Responses API |
| `azure-openai-responses` | Azure OpenAI Responses API |
| `openai-codex-responses` | OpenAI Codex Responses API |
| `mistral-conversations` | Mistral SDK Conversations/Chat streaming |
| `google-generative-ai` | Google Generative AI API |
| `google-vertex` | Google Vertex AI API |
| `bedrock-converse-stream` | Amazon Bedrock Converse API |

Most OpenAI-compatible providers work with `openai-completions`. Use model-level `thinkingLevelMap` for model-specific thinking levels, and `compat` for provider quirks.

> **Migration note:** Mistral moved from `openai-completions` to `mistral-conversations`. Use `mistral-conversations` for native Mistral models. If you intentionally route Mistral-compatible/custom endpoints through `openai-completions`, set `compat` flags explicitly as needed.

## Setting `api`

`api` can be set at provider level (default for all models) or model level (override per model):

```json
{
  "providers": {
    "my-provider": {
      "baseUrl": "https://api.example.com",
      "apiKey": "$MY_KEY",
      "api": "openai-completions",
      "models": [
        { "id": "model-a" },
        { "id": "model-b", "api": "openai-responses" }
      ]
    }
  }
}
```

## compat Flags by API

| API | compat fields |
|-----|---------------|
| `anthropic-messages` | `supportsEagerToolInputStreaming`, `supportsLongCacheRetention`, `sendSessionAffinityHeaders`, `supportsCacheControlOnTools`, `forceAdaptiveThinking`, `allowEmptySignature` |
| `openai-completions` | `supportsStore`, `supportsDeveloperRole`, `supportsReasoningEffort`, `supportsUsageInStreaming`, `maxTokensField`, `requiresToolResultName`, `requiresAssistantAfterToolResult`, `requiresThinkingAsText`, `requiresReasoningContentOnAssistantMessages`, `thinkingFormat`, `cacheControlFormat`, `supportsStrictMode`, `supportsLongCacheRetention`, `openRouterRouting`, `vercelGatewayRouting` |
| `openai-responses` / `azure-openai-responses` / `openai-codex-responses` | `openai-completions` compat subset (`supportsStore`, `supportsDeveloperRole`, `supportsReasoningEffort`, `supportsUsageInStreaming`, `maxTokensField`, `requiresToolResultName`, `requiresAssistantAfterToolResult`, `requiresThinkingAsText`, `requiresReasoningContentOnAssistantMessages`, `thinkingFormat`, `supportsStrictMode`, `supportsLongCacheRetention`) |
| `mistral-conversations` | Provider-specific (consult docs) |
| `google-generative-ai` / `google-vertex` | Provider-specific (consult docs) |
| `bedrock-converse-stream` | Provider-specific (consult docs) |

For the full `anthropic-messages` and `openai-completions` compat field tables, see [[pi-models-json#compat-fields]].

## thinkingFormat values (`openai-completions` only)

| Value | Sends |
|-------|-------|
| `openai` | `reasoning_effort` (when `supportsReasoningEffort` enabled) |
| `openrouter` | `reasoning: { effort }` |
| `deepseek` | Provider-specific DeepSeek reasoning parameter |
| `together` | `reasoning: { enabled }` and also `reasoning_effort` when `supportsReasoningEffort` is enabled |
| `zai` | Z.ai-specific reasoning parameter |
| `qwen` | Top-level `enable_thinking` |
| `qwen-chat-template` | `chat_template_kwargs.enable_thinking` (for local Qwen-compatible servers that require it) |

Notes:
- `openrouter` uses `reasoning: { effort }`.
- `together` uses `reasoning: { enabled }` and also `reasoning_effort` when `supportsReasoningEffort` is enabled.
- `qwen` uses top-level `enable_thinking`. Use `qwen-chat-template` for local Qwen-compatible servers that require `chat_template_kwargs.enable_thinking`.

## cacheControlFormat values

| Value | Description |
|-------|-------------|
| `anthropic` | Use Anthropic-style `cache_control` markers on the system prompt, last tool definition, and last user/assistant text content. For OpenAI-compatible providers that expose Anthropic-style prompt caching through `cache_control` markers |

## Custom Streaming API

For non-standard APIs, implement `streamSimple` and pass it to `pi.registerProvider()`:

```ts
pi.registerProvider("my-provider", {
  baseUrl: "https://api.example.com",
  apiKey: "$MY_API_KEY",
  api: "my-custom-api",
  models: [...],
  streamSimple: streamMyProvider
});
```

### Stream Pattern

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

### Stream Event Types

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

### Reference Implementations

Study the existing provider implementations before writing your own:
- `anthropic.ts` — Anthropic Messages API
- `mistral.ts` — Mistral Conversations API
- `openai-completions.ts` — OpenAI Chat Completions
- `openai-responses.ts` — OpenAI Responses API
- `google.ts` — Google Generative AI
- `amazon-bedrock.ts` — AWS Bedrock

## Context Overflow Errors

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

## Test Suites

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

---

- 2026-06-16 [CommandCode]: Page created
