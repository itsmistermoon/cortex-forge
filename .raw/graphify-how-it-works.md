# How graphify works

**URL:** https://github.com/safishamsi/graphify/blob/v8/docs/how-it-works.md
**Fetched:** 2026-06-12

## Three passes

Pass 1 — Code structure (free, no API calls): Tree-sitter parses code files locally. 25+ languages. SQL: tables, views, foreign keys deterministically.

Pass 2 — Video and audio (local, no API calls): faster-whisper transcription. Prompt seeded with top god nodes. Cached.

Pass 3 — Docs, papers, images (Claude subagents, costs tokens): parallel Claude subagents over markdown, PDFs, images, transcripts. Merged into single graph.

## Community detection

Leiden algorithm — graph-clustering by edge density. No embeddings needed. Semantic similarity edges from Claude influence shape directly.

## Confidence tagging

EXTRACTED (1.0), INFERRED (0.55–0.95 discrete rubric), AMBIGUOUS (flagged for review).

## Token benchmark

71.5x fewer tokens per query vs reading raw files on 52-file corpus. Scales with corpus size.

## Parallel extraction

ProcessPoolExecutor for AST. Parallel Claude subagents for docs. SHA256 cache skips unchanged files.

## Graph format

NetworkX node-link format. Nodes: id, label, file_type (code|document|paper|image|rationale), source_file. Edges: source, target, relation, confidence, confidence_score, source_file. Hyperedges in G.graph["hyperedges"].
