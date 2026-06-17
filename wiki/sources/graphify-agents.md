---
type: source
title: "graphify — AGENTS.md (v8)"
resource: https://github.com/safishamsi/graphify/blob/v8/AGENTS.md
created: 2026-06-12
updated: 2026-06-12
tags: [graphify, agents, knowledge-graph]
confidence: high
schema_version: "0.3"
raw: .raw/graphify-agents.md
---

# graphify — AGENTS.md

**URL:** https://github.com/safishamsi/graphify/blob/v8/AGENTS.md
**Original date:** 2026-06-12
**Author:** Safi Shamsi / Graphify Labs

## Summary

AGENTS.md of graphify: instructs the agent to read `graphify-out/GRAPH_REPORT.md` before answering architecture questions, navigate `graphify-out/wiki/index.md` instead of raw files, and run `graphify update .` after code modifications.

## Key ideas

1. Graph-aware agent workflow: read report → navigate wiki → update on change
2. All three steps are AST-only (free, no API cost)

## Connections
- Part of: [[wiki/sources/graphify]] (combined synthesis)
- Related concepts: [[wiki/concepts/karpathy-wiki-pattern]]

---

- 2026-06-13 [CommandCode]: Page created — split from combined graphify source for individual raw coverage
