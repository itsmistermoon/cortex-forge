"""
Embedding backend selector for cortex-forge.
Priority: Ollama → mlx-embeddings (Apple Silicon) → sentence-transformers

Ollama is the default: it reuses the daemon already present in most setups
and avoids downloading model weights separately. Requires the daemon running
on localhost:11434 — fails in sandboxed environments (e.g. Codex CLI without
network_access enabled in ~/.codex/config.toml). See agent-hook-compatibility.md.

mlx-embeddings is the in-process fallback for Apple Silicon: no daemon, Neural
Engine, ~270 MB download on first use. Activates automatically if Ollama is
unreachable and mlx-embeddings is installed.

sentence-transformers is the universal fallback (CPU, any platform).
"""
import platform
import struct
import sys
import urllib.request

MODEL_NAME = "nomic-embed-text-v1.5"
OLLAMA_URL = "http://localhost:11434/api/embeddings"
DIMENSIONS = 768

_backend: str | None = None
_st_model = None
_mlx_model = None
_mlx_tokenizer = None


def _is_apple_silicon() -> bool:
    return platform.system() == "Darwin" and platform.machine() == "arm64"


def _try_ollama() -> bool:
    import json
    payload = json.dumps({"model": "nomic-embed-text", "prompt": "test"}).encode()
    req = urllib.request.Request(OLLAMA_URL, data=payload, method="POST",
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=3) as r:
            return r.status == 200
    except Exception:
        return False


def _try_mlx() -> bool:
    global _mlx_model, _mlx_tokenizer
    if not _is_apple_silicon():
        return False
    try:
        from mlx_embeddings import load as mlx_load
        _mlx_model, _mlx_tokenizer = mlx_load(f"mlx-community/{MODEL_NAME}")
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
        payload = json.dumps({"model": "nomic-embed-text", "prompt": full_text}).encode()
        req = urllib.request.Request(OLLAMA_URL, data=payload, method="POST",
                                     headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(req) as r:
            data = json.loads(r.read())
        return data["embedding"]

    if backend == "mlx":
        import mlx.core as mx
        tokens = _mlx_tokenizer(full_text, return_tensors="mlx", padding=True, truncation=True)
        output = _mlx_model(**tokens)
        vec = output.last_hidden_state[0].mean(axis=0)
        return vec.tolist()

    if backend == "sentence-transformers":
        return _st_model.encode(full_text, normalize_embeddings=True).tolist()

    raise RuntimeError(f"Unknown backend: {backend}")


def embed_document(text: str) -> list[float]:
    return embed(text, prefix="search_document: ")


def embed_query(text: str) -> list[float]:
    return embed(text, prefix="search_query: ")


def vec_to_bytes(vec: list[float]) -> bytes:
    return struct.pack(f"{len(vec)}f", *vec)
