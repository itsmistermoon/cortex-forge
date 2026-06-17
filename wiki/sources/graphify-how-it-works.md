---
type: source
title: "graphify — docs/how-it-works.md (v8)"
resource: https://github.com/safishamsi/graphify/blob/v8/docs/how-it-works.md
created: 2026-06-12
tags: [graphify, internals, pipeline, algorithm]
confidence: high
raw: .raw/graphify-how-it-works.md
---

# graphify — docs/how-it-works.md

**URL:** https://github.com/safishamsi/graphify/blob/v8/docs/how-it-works.md
**Original date:** 2026-06-12
**Author:** Safi Shamsi / Graphify Labs

## Summary

Technical deep-dive of graphify's three-pass architecture: Pass 1 (AST, free), Pass 2 (video/audio, local), Pass 3 (docs/images, Claude subagents). Uses Leiden algorithm for community detection without embeddings.

## Key ideas

1. Three passes with increasing cost: free (AST) → local (whisper) → API (Claude subagents)
2. Leiden algorithm for community detection — no embeddings needed
3. 71.5x fewer tokens per query vs reading raw files (52-file corpus)
4. SHA256 cache skips unchanged files; ProcessPoolExecutor for parallel AST extraction

## Connections
- Part of: [[wiki/sources/graphify]] (combined synthesis)
- Related concepts: [[wiki/concepts/multi-agent-analysis-pipeline]]

---

- 2026-06-13 [CommandCode]: Page created — split from combined graphify source for individual raw coverage
