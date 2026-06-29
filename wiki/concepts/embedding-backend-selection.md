---
title: embedding-backend-selection
type: concept
created: 2026-06-28
updated: 2026-06-28
tags: [embeddings, semantic-search, mlx, ollama, cortex-forge]
confidence: high
schema_version: "0.3"
---

# Embedding Backend Selection

`embeddings.py` selects the embedding backend at runtime in priority order: Ollama → mlx-embeddings (Apple Silicon) → sentence-transformers. The logic is encapsulated in `_try_ollama()` / `_try_mlx()` so callers never need to know which backend is active.

## Priority rationale

**Ollama (default):** reuses the daemon already present in most setups; avoids downloading model weights separately. The model (`nomic-embed-text`) is already pulled and produces 768-dimensional vectors. Downside: requires the daemon running — fails in sandboxed environments without explicit network access (see [[wiki/concepts/agent-hook-compatibility]] § Codex).

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

---

- 2026-06-28 [Claude Code]: Page created — synthesized from live testing of mlx backends and Codex sandbox investigation
