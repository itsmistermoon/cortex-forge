---
type: source
title: "Pi Custom Models"
resource: https://pi.dev/docs/latest/models
created: 2026-06-16
updated: 2026-06-16
tags: [pi, models, providers, ollama, vllm, lm-studio, openai, anthropic, google, compat]
confidence: high
schema_version: "0.3"
raw: .raw/pi-models.md
sources:
  - .raw/pi-models.md
---

# Pi Custom Models

**URL:** https://pi.dev/docs/latest/models
**Original date:** 2026-06-16
**Author:** Mario Zechner / pi-mono

## Summary

Reference for adding custom providers and models to pi via `~/.pi/agent/models.json`. Covers the minimal example (Ollama-style, only `id` required), the full field schema (name, reasoning, thinkingLevelMap, input, contextWindow, maxTokens, cost), the four supported API types (openai-completions, openai-responses, anthropic-messages, google-generative-ai), the value-resolution syntax for `apiKey` and `headers` (shell command `!cmd`, env interpolation `$VAR`/`${VAR}`, escapes `$$`/`$!`), per-model and per-provider `compat` flags, the `modelOverrides` mechanism, and the `thinkingLevelMap` migration from the older `compat.reasoningEffortMap`.

## Key ideas

1. **Two-level config** — provider-level fields default to all models; model-level fields override. `compat` merges: model-level values override provider-level per flag.
2. **Value resolution** — `"!command"` runs the whole value as a shell command (`!security find-generic-password -ws 'anthropic'`, `!op read ...`). `"$ENV_VAR"` and `"${ENV_VAR}"` interpolate (use `${FOO}_BAR` to disambiguate from literal). `"$$"` = literal `$`; `"$!"` = literal `!` without triggering command mode. Plain uppercase strings are literals. Commands are resolved at request time with no built-in TTL — wrap your own caching if needed.
3. **Anthropic-messages compat knobs** — `supportsEagerToolInputStreaming` (default true, set false to omit and use the legacy fine-grained-tool-streaming beta header), `supportsLongCacheRetention` (1h cache TTL), `sendSessionAffinityHeaders` (auto-detected for known providers), `supportsCacheControlOnTools`, `forceAdaptiveThinking` (send `thinking.type: "adaptive"` + `output_config.effort`), `allowEmptySignature` (only for proxies that emit empty thinking signatures).
4. **OpenAI compat knobs** — `supportsStore`, `supportsDeveloperRole` (set false for servers that don't understand the `developer` role), `supportsReasoningEffort`, `supportsUsageInStreaming` (default true), `maxTokensField` (`max_completion_tokens` vs `max_tokens`), `requiresToolResultName`, `requiresAssistantAfterToolResult`, `requiresThinkingAsText`, `requiresReasoningContentOnAssistantMessages`, `thinkingFormat` (`openai`/`openrouter`/`deepseek`/`together`/`zai`/`qwen`/`qwen-chat-template`), `cacheControlFormat` (currently only `anthropic`), `supportsStrictMode`, `supportsLongCacheRetention`, `openRouterRouting`, `vercelGatewayRouting`.
5. **thinkingLevelMap replaces the older reasoningEffortMap** — keys are `off`/`minimal`/`low`/`medium`/`high`/`xhigh`. Values are tristate: omitted = default, string = send to provider, `null` = unsupported (hidden/skipped/clamped). Example: a model that only supports off, high, max uses `null` for minimal/low/medium, `"high"` for high, `"max"` for xhigh.
6. **Override built-in providers** — define a provider with the same name (e.g. `anthropic`) and only `baseUrl`/`headers`; all built-in models are preserved with the new endpoint. Adding `models` merges by id: new ids added, matching ids replace, built-in ids preserved when unmatched.
7. **Per-model overrides** — `modelOverrides: { "anthropic/claude-sonnet-4": { name, reasoning, input, cost, contextWindow, maxTokens, headers, compat } }`. Unknown model ids are ignored. Overriding `name` changes matching and detail text only — footer/primary lists still show `id`.
8. **Reload semantics** — `models.json` reloads each time `/model` opens. Edit during a session; no restart needed. `/model` availability checks use configured auth presence only (do not run shell commands).

## Connections
- Related concepts: [[wiki/concepts/pi-extension-lifecycle]]
- Projects: [[wiki/entities/pi-cli]]
- Sources: [[wiki/sources/pi-custom-provider]], [[wiki/sources/pi-extensions]], [[wiki/sources/pi-usage]]

---

- 2026-06-16 [CommandCode]: Page created
