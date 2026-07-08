"""
Embedding backend selector. Priority: Ollama → mlx-embeddings → sentence-transformers.
See wiki/concepts/embedding-backend-selection.md for rationale and known limitations.
"""
import platform
import struct
import sys
import urllib.request

MODEL_NAME = "nomic-embed-text-v1.5"
MLX_MODEL_NAME = "mlx-community/nomicai-modernbert-embed-base-bf16"
OLLAMA_URL = "http://localhost:11434/api/embeddings"
DIMENSIONS = 768
OLLAMA_EMBED_TIMEOUT = 30  # seconds — real embed calls take longer than the 3s detection ping

_backend: str | None = None
_st_model = None
_mlx_model = None
_mlx_tokenizer = None


def _is_apple_silicon() -> bool:
    return platform.system() == "Darwin" and platform.machine() == "arm64"


class EmbeddingBackendError(RuntimeError):
    """Raised when a single embed call fails (e.g. Ollama timeout) — recoverable
    per-call, unlike total backend unavailability (which exits at load time)."""


def _ollama_post(prompt: str, timeout: float):
    import json
    payload = json.dumps({"model": "nomic-embed-text", "prompt": prompt}).encode()
    req = urllib.request.Request(OLLAMA_URL, data=payload, method="POST",
                                 headers={"Content-Type": "application/json"})
    return urllib.request.urlopen(req, timeout=timeout)


def _try_ollama() -> bool:
    try:
        with _ollama_post("test", timeout=3) as r:
            return r.status == 200
    except Exception:
        return False


def _try_mlx() -> bool:
    global _mlx_model, _mlx_tokenizer
    if not _is_apple_silicon():
        return False
    try:
        from mlx_embeddings import load as mlx_load
        _mlx_model, _mlx_tokenizer = mlx_load(MLX_MODEL_NAME)
        return True
    except Exception:
        return False


def load_embedding_model() -> str:
    global _backend, _st_model, _mlx_model, _mlx_tokenizer

    if _backend:
        return _backend

    if _try_ollama():
        _backend = "ollama"
        return _backend

    if _try_mlx():
        _backend = "mlx"
        return _backend

    try:
        from sentence_transformers import SentenceTransformer
        _st_model = SentenceTransformer(f"nomic-ai/{MODEL_NAME}", trust_remote_code=True)
        _backend = "sentence-transformers"
        return _backend
    except Exception:
        pass

    print(
        "ERROR: No embedding backend available.\n"
        "  Option A (recommended): start Ollama and run `ollama pull nomic-embed-text`\n"
        "  Option B (in-process, Apple Silicon): pip install mlx-embeddings\n"
        "  Option C (universal): pip install sentence-transformers\n"
        "  If running inside Codex CLI: enable network access in ~/.codex/config.toml\n"
        "    [sandbox_workspace_write]\n"
        "    network_access = true\n"
        "    [features.network_proxy]\n"
        "    enabled = true\n"
        "    allow_local_binding = true",
        file=sys.stderr,
    )
    sys.exit(1)


def embed(text: str, prefix: str = "") -> list[float]:
    backend = load_embedding_model()
    full_text = f"{prefix}{text}" if prefix else text

    if backend == "ollama":
        import json
        try:
            with _ollama_post(full_text, timeout=OLLAMA_EMBED_TIMEOUT) as r:
                data = json.loads(r.read())
        except (TimeoutError, OSError) as e:
            raise EmbeddingBackendError(
                f"Ollama did not respond within {OLLAMA_EMBED_TIMEOUT}s while embedding "
                f"({e}). Check `ollama ps` / restart the Ollama server."
            ) from e
        vec = data["embedding"]

    elif backend == "mlx":
        import mlx.core as mx
        tokens = _mlx_tokenizer(full_text, return_tensors="mlx", padding=True, truncation=True)
        output = _mlx_model(**tokens)
        vec = output.last_hidden_state[0].mean(axis=0).tolist()

    elif backend == "sentence-transformers":
        vec = _st_model.encode(full_text, normalize_embeddings=True).tolist()

    else:
        raise RuntimeError(f"Unknown backend: {backend}")

    if len(vec) != DIMENSIONS:
        raise EmbeddingBackendError(
            f"Backend '{backend}' returned a {len(vec)}-dim vector, expected {DIMENSIONS}"
        )
    return vec


def embed_document(text: str) -> list[float]:
    return embed(text, prefix="search_document: ")


def embed_query(text: str) -> list[float]:
    return embed(text, prefix="search_query: ")


def vec_to_bytes(vec: list[float]) -> bytes:
    return struct.pack(f"{len(vec)}f", *vec)
