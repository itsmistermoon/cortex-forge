---
title: Pi models.json schema
type: reference
created: 2026-06-16
updated: 2026-06-16
tags: [pi, models, config, json, reference]
sources:
  - wiki/sources/pi-models.md
  - wiki/sources/pi-custom-provider.md
confidence: high
schema_version: "0.3"
---

# Pi models.json schema

Schema reference for `~/.pi/agent/models.json`. Add custom providers and models (Ollama, vLLM, LM Studio, proxies). The file reloads each time you open `/model`; edit during session, no restart needed. See [[pi-provider-api-types]] for the `api` field values and [[pi-models-json#thinking-level-map]] for the `thinkingLevelMap` semantics.

## Minimal Example (Ollama, LM Studio, vLLM)

```json
{
  "providers": {
    "ollama": {
      "baseUrl": "http://localhost:11434/v1",
      "api": "openai-completions",
      "apiKey": "ollama",
      "models": [
        { "id": "llama3.1:8b" },
        { "id": "qwen2.5-coder:7b" }
      ]
    }
  }
}
```

`apiKey` is required but Ollama ignores it — any value works.

## Full Example

```json
{
  "providers": {
    "ollama": {
      "baseUrl": "http://localhost:11434/v1",
      "api": "openai-completions",
      "apiKey": "ollama",
      "models": [
        {
          "id": "llama3.1:8b",
          "name": "Llama 3.1 8B (Local)",
          "reasoning": false,
          "input": ["text"],
          "contextWindow": 128000,
          "maxTokens": 32000,
          "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 }
        }
      ]
    }
  }
}
```

## Google AI Studio Example

```json
{
  "providers": {
    "my-google": {
      "baseUrl": "https://generativelanguage.googleapis.com/v1beta",
      "api": "google-generative-ai",
      "apiKey": "$GEMINI_API_KEY",
      "models": [
        {
          "id": "gemma-4-31b-it",
          "name": "Gemma 4 31B",
          "input": ["text", "image"],
          "contextWindow": 262144,
          "reasoning": true
        }
      ]
    }
  }
}
```

`baseUrl` is required when adding custom models to the `google-generative-ai` API type.

## Provider Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | No | Display name for the provider in UI such as `/login` |
| `baseUrl` | Required when defining models | API endpoint URL |
| `api` | Required at provider or model level | API type — see [[pi-provider-api-types]] |
| `apiKey` | No | API key (see [Value Resolution](#value-resolution)) |
| `headers` | No | Custom headers (see [Value Resolution](#value-resolution)) |
| `authHeader` | No | Set `true` to add `Authorization: Bearer <apiKey>` automatically |
| `models` | No | Array of model configurations. If provided, replaces all existing models for that provider |
| `modelOverrides` | No | Per-model overrides for built-in models on this provider |
| `compat` | No | Provider compatibility overrides — see [Compat Fields](#compat-fields) |
| `streamSimple` | No | Custom streaming implementation for non-standard APIs (extension-only) |
| `oauth` | No | OAuth provider for `/login` support (extension-only) |

## Model Fields

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| `id` | Yes | — | Model identifier (passed to the API) |
| `name` | No | `id` | Human-readable label. Used for `--model` pattern matching and shown as secondary model detail text. Does NOT replace the footer/status-bar model id |
| `api` | No | provider's `api` | Override provider's API for this model |
| `reasoning` | No | `false` | Supports extended thinking |
| `thinkingLevelMap` | No | omitted | Maps pi thinking levels to provider values and marks unsupported levels (see [Thinking Level Map](#thinking-level-map)) |
| `input` | No | `["text"]` | Input types: `["text"]` or `["text", "image"]` |
| `contextWindow` | No | `128000` | Context window size in tokens |
| `maxTokens` | No | `16384` | Maximum output tokens |
| `cost` | No | all zeros | `{"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}` (per million tokens) |
| `compat` | No | provider `compat` | Provider compatibility overrides. Merged with provider-level `compat` when both are set |
| `headers` | No | — | Custom headers (used by `modelOverrides` and per-model definitions) |

Current behavior:
- `/model`, `--list-models`, and the interactive footer display entries by model `id`.
- The configured `name` is used for model matching and secondary model detail text. It does not replace the footer/status-bar model id.

## Value Resolution

The `apiKey` and `headers` fields support command execution, environment interpolation, and literals.

| Pattern | Meaning | Example |
|---------|---------|---------|
| `!command` | Shell command (whole value executed, stdout used) | `"!security find-generic-password -ws 'anthropic'"` |
| `!command` | Shell command (1Password-style) | `"!op read 'op://vault/item/credential'"` |
| `$ENV_VAR` | Environment variable interpolation | `"$MY_API_KEY"` |
| `${ENV_VAR}` | Environment variable interpolation, works inside larger literals | `"${KEY_PREFIX}_${KEY_SUFFIX}"` |
| `$$` | Escaped literal `$` | `"$$literal-dollar-prefix"` |
| `$!` | Escaped literal `!` (no command execution) | `"$!literal-bang-prefix"` |
| _(plain string)_ | Literal value | `"sk-..."` |

### Environment Interpolation Notes

- `$FOO_BAR` is the variable `FOO_BAR`; use `${FOO}_BAR` when `BAR` is literal text.
- Missing environment variables make the value unresolved.
- Plain uppercase strings such as `MY_API_KEY` are literals; use `$MY_API_KEY` for environment variables.

### Shell Command Resolution Timing

For `models.json`, shell commands are resolved at request time. pi intentionally does not apply built-in TTL, stale reuse, or recovery logic for arbitrary commands. Different commands need different caching and failure strategies, and pi cannot infer the right one.

If your command is slow, expensive, rate-limited, or should keep using a previous value on transient failures, wrap it in your own script or command that implements the caching or TTL behavior you want.

`/model` availability checks use configured auth presence and do not execute shell commands.

## Custom Headers

```json
{
  "providers": {
    "custom-proxy": {
      "baseUrl": "https://proxy.example.com/v1",
      "apiKey": "$MY_API_KEY",
      "api": "anthropic-messages",
      "headers": {
        "x-portkey-api-key": "$PORTKEY_API_KEY",
        "x-secret": "!op read 'op://vault/item/secret'"
      },
      "models": [...]
    }
  }
}
```

## Thinking Level Map

Use `thinkingLevelMap` on a model to describe model-specific thinking controls. Keys are pi thinking levels: `off`, `minimal`, `low`, `medium`, `high`, `xhigh`.

| Value | Meaning |
|-------|---------|
| omitted | Level is supported and uses the provider's default mapping |
| string | Level is supported and this value is sent to the provider |
| `null` | Level is unsupported and hidden/skipped/clamped away |

### Example: only supports `off`, `high`, and `max`

```json
{
  "id": "deepseek-v4-pro",
  "reasoning": true,
  "thinkingLevelMap": {
    "minimal": null,
    "low": null,
    "medium": null,
    "high": "high",
    "xhigh": "max"
  }
}
```

### Example: thinking cannot be disabled

```json
{
  "id": "always-thinking-model",
  "reasoning": true,
  "thinkingLevelMap": {
    "off": null
  }
}
```

Migration: older configs that used `compat.reasoningEffortMap` should move that mapping to model-level `thinkingLevelMap`. Use `null` for levels that should not appear in the UI.

## Overriding Built-in Providers

Route a built-in provider through a proxy without redefining models:

```json
{
  "providers": {
    "anthropic": {
      "baseUrl": "https://my-proxy.example.com/v1"
    }
  }
}
```

All built-in Anthropic models remain available. Existing OAuth or API key auth continues to work.

To merge custom models into a built-in provider, include the `models` array:

```json
{
  "providers": {
    "anthropic": {
      "baseUrl": "https://my-proxy.example.com/v1",
      "apiKey": "$ANTHROPIC_API_KEY",
      "api": "anthropic-messages",
      "models": [...]
    }
  }
}
```

Merge semantics:
- Built-in models are kept.
- Custom models are upserted by `id` within the provider.
- If a custom model `id` matches a built-in model `id`, the custom model replaces that built-in model.
- If a custom model `id` is new, it is added alongside built-in models.

## Per-model Overrides (modelOverrides)

Use `modelOverrides` to customize specific built-in models without replacing the provider's full model list.

```json
{
  "providers": {
    "openrouter": {
      "modelOverrides": {
        "anthropic/claude-sonnet-4": {
          "name": "Claude Sonnet 4 (Bedrock Route)",
          "compat": {
            "openRouterRouting": {
              "only": ["amazon-bedrock"]
            }
          }
        }
      }
    }
  }
}
```

Supported fields per model: `name`, `reasoning`, `input`, `cost` (partial), `contextWindow`, `maxTokens`, `headers`, `compat`.

Behavior:
- `modelOverrides` are applied to built-in provider models.
- Unknown model IDs are ignored.
- You can combine provider-level `baseUrl`/`headers` with `modelOverrides`.
- Overriding `name` changes model matching and secondary detail text only; the footer and primary model lists continue to show the model `id`.
- If `models` is also defined for a provider, custom models are merged after built-in overrides. A custom model with the same `id` replaces the overridden built-in model entry.

## Compat Fields

Provider-level `compat` applies defaults to all models under that provider. Model-level `compat` overrides provider-level values for this model. When both are set, they are merged.

### `anthropic-messages` compat fields

| Field | Default | Description |
|-------|---------|-------------|
| `supportsEagerToolInputStreaming` | `true` | Whether the provider accepts per-tool `eager_input_streaming`. Set to `false` to omit that field and use the legacy `fine-grained-tool-streaming-2025-05-14` beta header on tool-enabled requests |
| `supportsLongCacheRetention` | `true` | Whether the provider accepts Anthropic long cache retention (`cache_control.ttl: "1h"`) when cache retention is `long` |
| `sendSessionAffinityHeaders` | auto-detected | Whether to send `x-session-affinity` from the session id when caching is enabled |
| `supportsCacheControlOnTools` | `true` | Whether the provider accepts Anthropic-style `cache_control` markers on tool definitions |
| `forceAdaptiveThinking` | `false` | Whether to send adaptive thinking (`thinking.type: "adaptive"` plus `output_config.effort`) for this model. Built-in adaptive models set this automatically |
| `allowEmptySignature` | `false` | Whether to replay empty thinking signatures as `signature: ""` instead of converting thinking to text. Set to `true` only for providers that emit empty signatures and still expect them on replay; real Anthropic rejects empty thinking signatures |

### `openai-completions` compat fields

| Field | Description |
|-------|-------------|
| `supportsStore` | Provider supports `store` field |
| `supportsDeveloperRole` | Use `developer` vs `system` role |
| `supportsReasoningEffort` | Support for `reasoning_effort` parameter |
| `supportsUsageInStreaming` | Supports `stream_options: { include_usage: true }` (default: `true`) |
| `maxTokensField` | Use `max_completion_tokens` or `max_tokens` |
| `requiresToolResultName` | Include `name` on tool result messages |
| `requiresAssistantAfterToolResult` | Insert an assistant message before a user message after tool results |
| `requiresThinkingAsText` | Convert thinking blocks to plain text |
| `requiresReasoningContentOnAssistantMessages` | Include empty `reasoning_content` on all replayed assistant messages when reasoning is enabled |
| `thinkingFormat` | Use `reasoning_effort`, `openrouter`, `deepseek`, `together`, `zai`, `qwen`, or `qwen-chat-template` thinking parameters — see [thinkingFormat values](#thinkingformat-values) |
| `cacheControlFormat` | Use Anthropic-style `cache_control` markers on the system prompt, last tool definition, and last user/assistant text content. Currently only `anthropic` is supported |
| `supportsStrictMode` | Include the `strict` field in tool definitions |
| `supportsLongCacheRetention` | Whether the provider accepts long cache retention when cache retention is `long`: `prompt_cache_retention: "24h"` for OpenAI prompt caching, or `cache_control.ttl: "1h"` when `cacheControlFormat` is `anthropic`. Default: `true` |
| `openRouterRouting` | OpenRouter provider routing preferences. This object is sent as-is in the `provider` field of the [OpenRouter API request](https://openrouter.ai/docs/guides/routing/provider-selection) |
| `vercelGatewayRouting` | Vercel AI Gateway routing config for provider selection (`only`, `order`) |
| `compat` (provider-level) | Common OpenAI-compat provider setting; e.g. `{"supportsDeveloperRole": false, "supportsReasoningEffort": false}` for Ollama, vLLM, SGLang |

### thinkingFormat values

| Value | Sends |
|-------|-------|
| `openai` | `reasoning_effort` (when `supportsReasoningEffort` enabled) |
| `openrouter` | `reasoning: { effort }` |
| `deepseek` | Provider-specific DeepSeek reasoning parameter |
| `together` | `reasoning: { enabled }` and also `reasoning_effort` when `supportsReasoningEffort` is enabled |
| `zai` | Z.ai-specific reasoning parameter |
| `qwen` | Top-level `enable_thinking` |
| `qwen-chat-template` | `chat_template_kwargs.enable_thinking` (for local Qwen-compatible servers that require it) |

`openrouter` uses `reasoning: { effort }`. `together` uses `reasoning: { enabled }` and also `reasoning_effort` when `supportsReasoningEffort` is enabled. `qwen` uses top-level `enable_thinking`. Use `qwen-chat-template` for local Qwen-compatible servers that require `chat_template_kwargs.enable_thinking`.

`cacheControlFormat: "anthropic"` is for OpenAI-compatible providers that expose Anthropic-style prompt caching through `cache_control` markers on text content and tool definitions.

## OpenAI-Compatible Local Servers (Ollama/vLLM/SGLang)

Some OpenAI-compatible servers do not understand the `developer` role used for reasoning-capable models. Set `compat.supportsDeveloperRole` to `false` so pi sends the system prompt as a `system` message instead. If the server also does not support `reasoning_effort`, set `compat.supportsReasoningEffort` to `false` too.

```json
{
  "providers": {
    "ollama": {
      "baseUrl": "http://localhost:11434/v1",
      "api": "openai-completions",
      "apiKey": "ollama",
      "compat": {
        "supportsDeveloperRole": false,
        "supportsReasoningEffort": false
      },
      "models": [
        { "id": "gpt-oss:20b", "reasoning": true }
      ]
    }
  }
}
```

---

- 2026-06-16 [CommandCode]: Page created
