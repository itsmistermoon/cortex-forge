# Available Models | Command Code

Source: https://commandcode.ai/docs/reference/cli/models
Fetched: 2026-06-13

Pass any of these ids to `-m`, `--model`, or pick them in-session with `/model`. Run `cmd --list-models` for the live list.

Default model: `moonshotai/Kimi-K2.5`.

`--model` matching is case-insensitive and accepts either the full id or just the name after the `/` (e.g., `moonshotai/Kimi-K2.5`, `moonshotai/kimi-k2.5`, and `kimi-k2.5` all resolve to the same model). Unknown id is rejected up front pointing at `cmd --list-models`.

## Anthropic
| Model id | Name | Best for | Capabilities |
|---|---|---|---|
| `claude-sonnet-4-6` | Claude Sonnet 4.6 | best combo of speed & intelligence (recommended) | text, vision |
| `claude-fable-5` | Claude Fable 5 | most capable for demanding reasoning & long-horizon agents | text, vision |
| `claude-opus-4-8` | Claude Opus 4.8 | most capable for complex reasoning & agentic coding | text, vision |
| `claude-opus-4-7` | Claude Opus 4.7 | most intelligent for agents and coding | text, vision |
| `claude-haiku-4-5` | Claude Haiku 4.5 | fastest & most compact, great for quick tasks | text, vision |

## OpenAI
| Model id | Name | Best for | Capabilities |
|---|---|---|---|
| `gpt-5.5` | GPT-5.5 | latest frontier model for general complex work | text, vision |
| `gpt-5.4` | GPT-5.4 | frontier model for general complex work | text, vision |
| `gpt-5.3-codex` | GPT-5.3 Codex | frontier coding model | text, vision |
| `gpt-5.4-mini` | GPT-5.4 Mini | fast, cost-effective model for everyday tasks | text, vision |

## Google
| Model id | Name | Best for | Capabilities |
|---|---|---|---|
| `google/gemini-3.5-flash` | Gemini 3.5 Flash | Pro-level coding proficiency, parallel agentic execution | text, vision |
| `google/gemini-3.1-flash-lite` | Gemini 3.1 Flash Lite | high-volume workhorse model with implicit caching | text, vision |

## Open Source
| Model id | Name | Best for | Capabilities |
|---|---|---|---|
| `moonshotai/Kimi-K2.6` | Kimi K2.6 | long-horizon coding with vision | text, vision |
| `moonshotai/Kimi-K2.5` (default) | Kimi K2.5 | multimodal frontend coding | text, vision |
| `zai-org/GLM-5.1` | GLM-5.1 | long-horizon autonomous coding agent | text |
| `zai-org/GLM-5` | GLM-5 | multi-mode thinking & long-range planning | text |
| `MiniMaxAI/MiniMax-M3` | MiniMax M3 | frontier coding, agents & native multimodality | text, vision |
| `MiniMaxAI/MiniMax-M2.7` | MiniMax M2.7 | end-to-end software engineering agent | text |
| `MiniMaxAI/MiniMax-M2.5` | MiniMax M2.5 | cross-platform full-stack agentic dev | text |
| `deepseek/deepseek-v4-pro` | DeepSeek V4 Pro | hybrid-attention long-context reasoning | text |
| `deepseek/deepseek-v4-flash` | DeepSeek V4 Flash | fast hybrid-attention reasoning | text |
| `Qwen/Qwen3.6-Max-Preview` | Qwen 3.6 Max Preview | vibe coding & efficient agent execution | text |
| `Qwen/Qwen3.6-Plus` | Qwen 3.6 Plus | agentic coding & reasoning | text, vision |
| `Qwen/Qwen3.7-Max` | Qwen 3.7 Max | frontier coding & long-horizon agent execution | text |
| `Qwen/Qwen3.7-Plus` | Qwen 3.7 Plus | agentic coding & reasoning at lower cost | text, vision |
| `stepfun/Step-3.7-Flash` | Step 3.7 Flash | multimodal sparse-MoE reasoning | text, vision |
| `stepfun/Step-3.5-Flash` | Step 3.5 Flash | fast sparse-MoE agentic reasoning | text |
| `xiaomi/mimo-v2.5-pro` | MiMo V2.5 Pro | high-capability long-context agentic coding | text |
| `xiaomi/mimo-v2.5` | MiMo V2.5 | efficient long-context agentic coding | text, vision |
| `nvidia/nemotron-3-ultra-550b-a55b` | Nemotron 3 Ultra | open reasoning model for long-horizon autonomous agents | text |

## Next steps
- CLI Reference
- Interactive mode — switching models in-session with `/model`
