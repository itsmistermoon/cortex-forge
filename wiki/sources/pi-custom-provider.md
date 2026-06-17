---
type: source
title: "Pi Custom Providers"
resource: https://pi.dev/docs/latest/custom-provider
section: custom-provider
created: 2026-06-16
updated: 2026-06-16
tags: [pi, providers, oauth, streaming, streamSimple, registerProvider]
confidence: high
schema_version: "0.3"
raw: .raw/pi-custom-provider.md
sources:
  - .raw/pi-custom-provider.md
---

# Pi Custom Providers

**URL:** https://pi.dev/docs/latest/custom-provider
**Original date:** 2026-06-16
**Author:** Mario Zechner / pi-mono

## Summary

How extensions register new model providers via `pi.registerProvider()` — proxies, custom endpoints, OAuth/SSO flows, and non-standard streaming APIs. Documents the ProviderConfig interface, the nine supported API types, `unregisterProvider`, the OAuth integration (callbacks, credentials, persistence in `~/.pi/agent/auth.json`), and the full `streamSimple` event protocol (`createAssistantMessageEventStream`, content blocks, tool-call JSON accumulation, usage/cost updates, context-overflow normalization).

## Key ideas

1. **Two main flows** — override an existing provider by name with only `baseUrl`/`headers` (preserves all built-in models), or register a new provider with `models` defined (replaces that provider's model list). Async factory is the recommended way to fetch dynamic model lists before startup finishes.
2. **Nine supported `api` types** — `anthropic-messages`, `openai-completions`, `openai-responses`, `azure-openai-responses`, `openai-codex-responses`, `mistral-conversations`, `google-generative-ai`, `google-vertex`, `bedrock-converse-stream`. Migration note: Mistral moved from `openai-completions` to `mistral-conversations`.
3. **OAuth integration via `/login`** — provider config carries an `oauth` block with `login(callbacks)`, `refreshToken(credentials)`, `getApiKey(credentials)`, optional `modifyModels(models, credentials)`. `OAuthLoginCallbacks` exposes `onAuth({url})`, `onDeviceCode({userCode, verificationUri, intervalSeconds?, expiresInSeconds?})`, `onPrompt({message})`, `onSelect({message, options})`. Credentials are persisted in `~/.pi/agent/auth.json` with `{ refresh, access, expires }`.
4. **streamSimple event protocol** — `createAssistantMessageEventStream()` returns a stream; push events in order: `start` → content blocks (`text_start`/`text_delta`/`text_end`, `thinking_start`/`thinking_delta`/`thinking_end`, `toolcall_start`/`toolcall_delta`/`toolcall_end`) → `done({reason, message})` or `error({reason, error})`. Tool calls require accumulating partial JSON and parsing as it arrives.
5. **Content blocks and usage** — `output.content` is an array of `text | image | thinking | toolCall` blocks. Update `output.usage.{input, output, cacheRead, cacheWrite, totalTokens}` and call `calculateCost(model, usage)` once the API returns usage.
6. **Context-overflow recovery** — pi auto-compacts and retries when `stopReason === "error"` and `errorMessage` matches a known pattern. Extensions can normalize a provider's overflow phrase to `context_length_exceeded: <original>` via a `message_end` handler that returns `{ message: { ...message, errorMessage } }`.
7. **Unregister semantics** — `pi.unregisterProvider(name)` removes dynamic models, API key fallback, OAuth registration, and custom stream handler registrations. Built-in models and overrides that were replaced are restored. Applied immediately (no `/reload`).
8. **authHeader** — set `true` to add `Authorization: Bearer <apiKey>` for providers that expect it but don't follow a standard API.

## Connections
- Related concepts: [[wiki/concepts/pi-extension-lifecycle]]
- Projects: [[wiki/entities/pi-cli]]
- Sources: [[wiki/sources/pi-extensions]], [[wiki/sources/pi-models]], [[wiki/sources/pi-usage]]

---

- 2026-06-16 [CommandCode]: Page created
