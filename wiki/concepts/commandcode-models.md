---
title: CommandCode Models
type: concept
created: 2026-06-13
updated: 2026-06-13
tags: [commandcode, models, cli, reference]
sources:
  - .raw/commandcode-models-reference.md
confidence: high
schema_version: "0.3"
aliases: []
---

# [[wiki/entities/commandcode|CommandCode]] Models

Model ids for `cmd -m` / `cmd --model` and `/model` in-session. Run `cmd --list-models` for the live list — this table may drift.

**Default model:** `moonshotai/Kimi-K2.5`

**Matching:** case-insensitive, accepts full id or name after `/` (e.g. `moonshotai/kimi-k2.5` or just `kimi-k2.5`). Unknown ids are rejected upfront.

## Anthropic

| Model id | Name | Capabilities |
|---|---|---|
| `claude-sonnet-4-6` | Claude Sonnet 4.6 | text, vision |
| `claude-fable-5` | Claude Fable 5 | text, vision |
| `claude-opus-4-8` | Claude Opus 4.8 | text, vision |
| `claude-opus-4-7` | Claude Opus 4.7 | text, vision |
| `claude-haiku-4-5` | Claude Haiku 4.5 | text, vision |

## OpenAI

| Model id | Name | Capabilities |
|---|---|---|
| `gpt-5.5` | GPT-5.5 | text, vision |
| `gpt-5.4` | GPT-5.4 | text, vision |
| `gpt-5.3-codex` | GPT-5.3 Codex | text, vision |
| `gpt-5.4-mini` | GPT-5.4 Mini | text, vision |

## Google

| Model id | Name | Capabilities |
|---|---|---|
| `google/gemini-3.5-flash` | Gemini 3.5 Flash | text, vision |
| `google/gemini-3.1-flash-lite` | Gemini 3.1 Flash Lite | text, vision |

## Open Source

| Model id | Name | Capabilities |
|---|---|---|
| `moonshotai/Kimi-K2.6` | Kimi K2.6 | text, vision |
| `moonshotai/Kimi-K2.5` | Kimi K2.5 (default) | text, vision |
| `zai-org/GLM-5.1` | GLM-5.1 | text |
| `zai-org/GLM-5` | GLM-5 | text |
| `MiniMaxAI/MiniMax-M3` | MiniMax M3 | text, vision |
| `MiniMaxAI/MiniMax-M2.7` | MiniMax M2.7 | text |
| `MiniMaxAI/MiniMax-M2.5` | MiniMax M2.5 | text |
| `deepseek/deepseek-v4-pro` | DeepSeek V4 Pro | text |
| `deepseek/deepseek-v4-flash` | DeepSeek V4 Flash | text |
| `Qwen/Qwen3.6-Max-Preview` | Qwen 3.6 Max Preview | text |
| `Qwen/Qwen3.6-Plus` | Qwen 3.6 Plus | text, vision |
| `Qwen/Qwen3.7-Max` | Qwen 3.7 Max | text |
| `Qwen/Qwen3.7-Plus` | Qwen 3.7 Plus | text, vision |
| `stepfun/Step-3.7-Flash` | Step 3.7 Flash | text, vision |
| `stepfun/Step-3.5-Flash` | Step 3.5 Flash | text |
| `xiaomi/mimo-v2.5-pro` | MiMo V2.5 Pro | text |
| `xiaomi/mimo-v2.5` | MiMo V2.5 | text, vision |
| `nvidia/nemotron-3-ultra-550b-a55b` | Nemotron 3 Ultra | text |

---

- 2026-06-13 [CommandCode]: Page created from official models reference
