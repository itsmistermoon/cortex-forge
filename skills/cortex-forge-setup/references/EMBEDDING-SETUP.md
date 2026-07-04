# Embedding dependency check

Disclosed reference for `cortex-forge-setup`. Reached from step 6 (new-vault wizard), maintenance menu option 3, and step 6c's fallback.

**Core rule: check before asking.** Never ask a generic "enable semantic search?" — detect what's already available first, then tailor the question to that. A user who already has Ollama running gets a one-line confirm, not a menu. A user with nothing gets the full menu with every option's tradeoffs spelled out. This mirrors `embeddings.py`'s own runtime backend priority: Ollama → mlx-embeddings (Apple Silicon) → sentence-transformers.

## Detection (run in this order, stop at the first success)

1. **Ollama.** Is the server responding?
   ```bash
   curl -s --max-time 2 http://localhost:11434/api/tags >/dev/null 2>&1 && echo running || echo not-running
   ```
   - **`running`** → check if the embedding model is already pulled:
     ```bash
     ollama list 2>/dev/null | grep -q nomic-embed-text && echo pulled || echo not-pulled
     ```
     - **`pulled`** → fully ready. Skip straight to "Ready-to-go" wording below.
     - **`not-pulled`** → one step away. Use "One step away" wording below.
   - **`not-running`** → continue to step 2.

2. **Platform + Python libraries.** Detect platform: `uname -m` → `arm64` = Apple Silicon, anything else = generic. Then:
   ```bash
   python3 -c "import mlx_lm" 2>/dev/null && echo mlx || python3 -c "import sentence_transformers" 2>/dev/null && echo st || echo none
   ```
   - **`mlx` or `st`** → fully ready (a library is already importable). Use "Ready-to-go" wording.
   - **`none`** → nothing is available. Use "Full menu" wording.

## Offer wording, by detection outcome

**Ready-to-go** (Ollama+model pulled, or a Python library already importable):
```
✓ {backend} ready — no setup needed.
Initialize semantic search now? [Y/n]
```

**One step away** (Ollama running, model not pulled):
```
✓ Ollama detected and running.
Semantic search needs the "nomic-embed-text" model (~274 MB, downloaded once).

Download it and initialize semantic search now? [Y/n]
```
If yes: `ollama pull nomic-embed-text`, show progress, then proceed to indexing.

**Full menu** (nothing detected):
```
Semantic search needs one of these to generate embeddings locally. Choose:

  [1] Ollama (recommended) — installs Ollama, downloads nomic-embed-text
      (~274 MB, once). Runs as a local service. No network calls at query time.
  [2] mlx-embeddings — Apple Silicon only. Uses the Neural Engine — fast,
      low power.                                          (omit if not arm64)
  [3] sentence-transformers — works on any platform, runs on CPU (slower),
      ~270 MB of model weights.
  [4] Not now — skip semantic search (falls back to keyword search via
      wiki/index.md; enable later with /cortex-forge-setup)

Choose [1-4]:
```

## Installation, by choice

- **Ollama, not yet installed**: point the user to https://ollama.com/download (installing Ollama itself is a system-level action this skill does not perform automatically — ask the user to confirm it's installed and running before proceeding). Once running, `ollama pull nomic-embed-text`.
- **mlx-embeddings**: `pip install mlx-embeddings`. If it fails, fall back to `pip install sentence-transformers` and note the fallback.
- **sentence-transformers**: `pip install sentence-transformers`.
- After any install, re-run the relevant detection snippet to confirm before proceeding to indexing. If still failing, report the error and skip indexing — do not proceed blindly.
- **"Not now" / declined**: skip indexing, note in the final summary that semantic search is not active and how to enable it later (`/cortex-forge-setup`, maintenance menu option 3).
