---
"cortex-forge": patch
---

`cortex-assimilate` now accepts pasted text (no fetchable URL) as a source — for sites that block scraping (e.g. Twitter/X) or sit behind a paywall — and falls back to it automatically when a fetch fails instead of dead-ending. Its backward-enrichment step also gained the same 20-candidate hard cap `cortex-prune` already enforces, so a very common tag no longer risks an unbounded scan. Fixed a latent bug in `embeddings.py`'s `mlx-embeddings` backend, which referenced a non-existent `mlx-community/nomic-embed-text-v1.5` model — silently masked as "MLX unavailable" — now pointing at the real `mlx-community/nomicai-modernbert-embed-base-bf16` port (same 768 dims, same task prefixes).
