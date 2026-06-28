"""
Embedding backend selector for cortex-forge.
Priority: Ollama → mlx-embeddings (Apple Silicon) → sentence-transformers
"""
import os
import platform
import struct
import sys
import urllib.error
import urllib.request

MODEL_NAME = "nomic-embed-text-v1.5"
OLLAMA_URL = "http://localhost:11434/api/embeddings"
DIMENSIONS = 768

_backend: str | None = None
_st_model = None
_mlx_model = None
_mlx_tokenizer = None


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


def _is_apple_silicon() -> bool:
    return platform.system() == "Darwin" and platform.machine() == "arm64"


def load_embedding_model() -> str:
    global _backend, _st_model, _mlx_model, _mlx_tokenizer

    if _backend:
        return _backend

    if _try_ollama():
        _backend = "ollama"
        return _backend

    if _is_apple_silicon():
        try:
            import mlx_embeddings
            from mlx_embeddings import load as mlx_load
            _mlx_model, _mlx_tokenizer = mlx_load(f"mlx-community/{MODEL_NAME}")
            _backend = "mlx"
            return _backend
        except Exception:
            pass

    try:
        from sentence_transformers import SentenceTransformer
        _st_model = SentenceTransformer(f"nomic-ai/{MODEL_NAME}", trust_remote_code=True)
        _backend = "sentence-transformers"
        return _backend
    except Exception:
        pass

    print("ERROR: No embedding backend available. Install Ollama, mlx-embeddings, or sentence-transformers.", file=sys.stderr)
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
