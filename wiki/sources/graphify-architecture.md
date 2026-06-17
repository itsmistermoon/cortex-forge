---
type: source
title: "graphify — ARCHITECTURE.md (v8)"
resource: https://github.com/safishamsi/graphify/blob/v8/ARCHITECTURE.md
created: 2026-06-12
updated: 2026-06-12
tags: [graphify, architecture, pipeline]
confidence: high
schema_version: "0.3"
raw: .raw/graphify-architecture.md
---

# graphify — ARCHITECTURE.md

**URL:** https://github.com/safishamsi/graphify/blob/v8/ARCHITECTURE.md
**Original date:** 2026-06-12
**Author:** Safi Shamsi / Graphify Labs

## Summary

Pipeline architecture: detect() → extract() → build_graph() → cluster() → analyze() → report() → export(). Each stage is a single function in its own module communicating through plain Python dicts and NetworkX graphs. 18 modules documented with responsibilities and extraction schema.

## Key ideas

1. Seven-stage pipeline with clear separation per module
2. Confidence labels: EXTRACTED, INFERRED, AMBIGUOUS
3. Extensible: adding a language extractor requires 5 steps (function, dispatch registration, extensions, tree-sitter dep, tests)
4. Security layer: all external input passes through `security.py`

## Connections
- Part of: [[wiki/sources/graphify]] (combined synthesis)
- Related concepts: [[wiki/concepts/treesitter-llm-hybrid-parsing]]
- Projects: [[wiki/pages/cortex-forge]]

---

- 2026-06-13 [CommandCode]: Page created — split from combined graphify source for individual raw coverage
