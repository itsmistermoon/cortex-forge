---
title: Tree-sitter + LLM hybrid parsing
type: concept
created: 2026-06-08
updated: 2026-06-08
tags: [parsing, code-analysis, hybrid, ast, llm, fingerprint]
aliases: [hybrid parsing, deterministic + semantic parsing]
sources:
  - wiki/sources/understand-anything.md
confidence: high
schema_version: "0.3"
---

# Tree-sitter + LLM hybrid parsing

Code analysis pattern that divides work between a **deterministic parser** (tree-sitter) and a **semantic LLM** based on what each does best. Applied by [[wiki/entities/understand-anything]] in its `/understand` pipeline, and by [[wiki/entities/codebase-memory-mcp]] as its Hybrid LSP layer (syntactic AST + type-aware resolution).

## The split

**Tree-sitter (deterministic)** — produces the **objective facts** of the code:

- Concrete syntax tree (CST).
- Imports, exports, function/class definitions.
- Call sites, inheritance, type signatures.
- Pre-resolved `importMap`.
- Structural fingerprints for incremental change detection.

**Same input → same output, always.** Reproducible by construction.

**LLM (semantic)** — produces the **interpretations** the parser cannot:

- Natural language summaries of what each function does.
- Semantic tags (e.g. "auth-handler", "payment-flow").
- Architectural layer assignment (API, Service, Data, UI, Utility).
- Business domain mapping.
- Guided learning tours.
- Programming concept callouts in context.

**Same input → outputs that may vary** between runs (depends on model, temperature, prompt).

## Why the split matters

If you delegate everything to the LLM:
- You lose structural reproducibility (the same functions could map to different nodes between runs).
- You spend tokens re-deriving facts the parser already knows.
- You cannot do reliable incremental analysis (what changed?).

If you delegate everything to the parser:
- You have no summaries.
- You cannot infer intent.
- There is no business domain mapping.

**The split gives you:**
- Structural reproducibility (edges are facts).
- Variable but labelable semantics (summaries are hypotheses).
- Reliable incremental processing via structural fingerprinting (only re-analyzes files whose CST changed).

## Import pre-resolution

Key design detail: tree-sitter **not only** extracts `import x from y` — it **resolves** `x` against the project's complete `importMap` and passes the pre-resolved map to the file analyzers. Result: the LLM does not re-derive dependencies; it consumes an already-materialized import graph.

**Trade-off:** upfront cost of a full project scan. Benefit: token savings on each analyzed file (which scales poorly without this).

## Fingerprinting for incremental

Tree-sitter produces a structural hash of the CST (not of the source text). If code is reformatted without semantic changes (e.g. prettier), the fingerprint **does not change** and the file is not re-analyzed. If an `import` is changed, the fingerprint changes and only the affected file is re-analyzed.

**Lesson:** hash the **semantic shape**, not the raw text. Text is presentation; shape is what matters for analysis.

## Transferable applicability

The pattern is replicable in any system that analyzes code + documentation:

- **Documentation:** markdown parser (remark/markdown-it) extracts structure, LLM extracts intent.
- **Wikis:** wikilink + frontmatter parser (see [[wiki/concepts/karpathy-wiki-pattern]]) extracts edges, LLM extracts implicit claims.
- **Logs/queries:** regex/AST parser extracts facts, LLM extracts causality.

**Rule:** the parser handles **what is verifiable**; the LLM handles **what requires interpretation**. Mixing both responsibilities in a single layer (everything to the LLM, or everything to regex) is the most common cause of analysis pipelines that do not scale.

---

- 2026-06-08 [CommandCode]: Page created — concept extracted from the internal architecture of Understand Anything, with emphasis on the design decisions (pre-resolution, structural fingerprinting) that make it efficient
- 2026-06-08 [Claude Code]: Translated to English
