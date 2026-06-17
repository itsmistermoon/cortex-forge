---
title: Karpathy-pattern LLM wiki
type: concept
created: 2026-06-08
updated: 2026-06-08
tags: [wiki, knowledge-base, llm, second-brain, karpathy]
aliases: [Karpathy wiki, LLM-readable wiki, vault-as-llm-context]
sources:
  - wiki/sources/understand-anything.md
confidence: high
schema_version: "0.3"
---

# Karpathy-pattern LLM wiki

Design pattern for wikis/knowledge bases optimized to be **read and queried by LLMs**, not just by humans. Informally formalized by Andrej Karpathy in [gist #442a6bf555914893e9891c11519de94f](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f). Applied by [[wiki/entities/understand-anything]] in its `/understand-knowledge` pipeline for wiki analysis.

## Canonical structure

- **`index.md`** as entry point — the LLM reads it first to orient itself.
- **Explicit wikilinks** `[[page-name]]` between documents — the deterministic parser extracts them as graph edges.
- **Categories/tags** declared in frontmatter — the parser extracts them as metadata.
- **Folders by type** (concept, entity, source, project) — predictable navigation.

## What distinguishes it from a traditional wiki

A human wiki (MediaWiki, Notion, Obsidian publish) optimizes for **human reading**: navigation sidebar, full-text search, breadcrumbs. A Karpathy wiki optimizes for **LLM consumption**:

- Structured frontmatter (no HTML decoration).
- Unique H1 titles per file (no multiple H1s).
- Compiled truth in prose, not decorative bullets.
- Changelog at the bottom so an agent knows what has changed.
- Wikilinks in plain text, not in separate metadata fields.

## The deterministic parser

A Karpathy wiki is **parseable without an LLM** by a small script. The Understand Anything pipeline does it as follows:

1. **Deterministic parser** reads `index.md` + files in `wiki/`, extracts:
   - Wikilinks `[[...]]` → graph edges.
   - Categories from frontmatter → visual tags in the graph.
   - Folder structure → clusters.

2. **LLM agent** complements with:
   - Entities not explicitly linked.
   - Implicit claims between pages.
   - Semantic summaries per node.

The result: **navigable graph with a reproducible structural base** (wikilinks are objective facts) and **subjective semantic layer** (LLM inferences are labelable hypotheses).

## Direct applicability

The `cortex-forge` vault already implements this pattern (see [[wiki/index]]): index.md as entry point, frontmatter per page, `templates/` for page types, categories `wiki/concepts/`, `wiki/entities/`, `wiki/sources/`, `wiki/pages/`. Still missing:

- Adopting explicit `[[wikilinks]]` (currently there are few).
- Validating that the deterministic parser can extract the graph from the current filesystem.
- Evaluating `/understand-knowledge` to graph the complete vault.

## Why it works

**Fundamental trade-off:** a human wiki rewards presentation (CSS, images, navigation). A Karpathy wiki rewards **machine retrievability**. For a vault whose primary consumer is an agent, the second is strictly superior. The cost: presentation is more austere, wikilinks break in large wikis, and page design is limited by what a parser can extract.

## Transferable lesson

> If the primary consumer of the vault is an agent, optimize the vault for the agent, not for the human. Presentation is a byproduct of structure.

---

- 2026-06-08 [CommandCode]: Page created — concept extracted from the Understand Anything source, with explicit contrast between the Karpathy pattern and traditional human wikis
- 2026-06-08 [Claude Code]: Translated to English
