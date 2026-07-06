---
title: embedding-backend-selection
type: concept
created: 2026-06-28
updated: 2026-06-28
tags: [embeddings, semantic-search, mlx, ollama, cortex-forge/architecture]
confidence: high
schema_version: "0.3"
aliases: []
sources: []
---

# Embedding Backend Selection

`embeddings.py` selects the embedding backend at runtime in priority order: Ollama → mlx-embeddings (Apple Silicon) → sentence-transformers. The logic is encapsulated in `_try_ollama()` / `_try_mlx()` so callers never need to know which backend is active.

## Priority rationale

**Ollama (default):** reuses the daemon already present in most setups; avoids downloading model weights separately. The model (`nomic-embed-text`) is already pulled and produces 768-dimensional vectors. Downside: requires the daemon running — fails in sandboxed environments without explicit network access (see [[wiki/concepts/agent-hook-compatibility]] § [[wiki/entities/codex|Codex]]).

**mlx-embeddings (Apple Silicon fallback):** runs in-process via the Neural Engine — no daemon required. Same model family (`nomic-embed-text-v1.5`), same 768 dimensions, so the existing `vault.db` index remains valid without re-indexing. Activates automatically if Ollama is unreachable and the package is installed.

**sentence-transformers (universal fallback):** CPU-based, works on any platform, no prerequisites beyond the pip install. Slowest option, largest install footprint (~1 GB with torch).

## Codex sandbox note

Codex CLI blocks loopback by default (`allow_local_binding = false`), which prevents `cortex-search.py` from reaching Ollama on `localhost:11434`. Fix: add to `~/.codex/config.toml`:

```toml
[sandbox_workspace_write]
network_access = true

[features.network_proxy]
enabled = true
allow_local_binding = true
```

Without this, `cortex-recall` falls back to keyword search via `wiki/index.md`. See [[wiki/concepts/agent-hook-compatibility]] § Codex for full context.

## MLX compatibility status (2026-06-28)

`nomic-embed-text-v1.5` exists in MLX-compatible form and has identical dimensions (768) to the Ollama backend — switching would not require re-indexing `vault.db`. However, all available packages fail at runtime on the current environment (Python 3.14 + transformers 5.x):

| Package | Blocker |
|---------|---------|
| `mlx-embedding-models` 0.0.11 (taylorai) | Uses `batch_encode_plus`, removed in transformers 5.x |
| `mlx-embeddings` (Blaizzy) | Architecture `nomic_bert` not implemented |
| `mlx_lm` | Not designed for embedding inference with this model family |

Secondary blocker: `sqlite-vec` (required by `cortex-search.py`) is only available on the system Python (3.14), making it impossible to use the `mlx_lm` install in pyenv (3.13) as a workaround — the two dependencies live in different interpreters.

**Gate for switching to MLX as default:** upstream packages resolve `transformers` 5.x compatibility. When that happens, MLX becomes the clear preferred backend: in-process, Neural Engine, no daemon, works in Codex without `config.toml` changes.

## Upgrade path: nomic-embed-text-v2-moe

`nomic-embed-text-v2-moe` (NomicBertMoE, ~475M active / ~1.5B total) is the successor to v1.5: multilingual, MoE architecture, Matryoshka dimensions (256–768). It would be the natural next model for the vault.

**Gate:** ollama/ollama issue [#16076](https://github.com/ollama/ollama/issues/16076) must be resolved. As of 2026-06-28 the issue is open and unassigned. The blockers are:
- Ollama's MLX engine has no `NomicBertMoE` forward path — `ollama create --experimental` imports the weights but `/api/embed` returns `unsupported architecture: NomicBertModel`
- The Safetensors converter never emits `pooling_type` KV, so `Capabilities()` never sets `CapabilityEmbedding`

Current `nomic-embed-text` (v1, GGUF) is unaffected — it works correctly via Ollama today.

**Migration cost when the gate opens:** v2-moe produces different vectors (different model weights), so `vault.db` must be fully re-indexed with `cortex-index.py` (co-located with the `cortex-forge-setup` skill; copied to `{vault}/.cortex/db/` at setup). Matryoshka dimensions mean the target dimension (768 for maximum quality, 256 for speed) must be fixed at index time and cannot change without re-indexing again.

---

- 2026-06-28 [Claude Code]: Page created — synthesized from live testing of mlx backends and Codex sandbox investigation
- 2026-06-28 [Claude Code]: Added upgrade path section for nomic-embed-text-v2-moe — gated on ollama/ollama#16076
