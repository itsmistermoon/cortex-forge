---
title: "Primary Source"
type: concept
created: 2026-06-10
updated: 2026-06-10
tags: [epistemology, context-engineering, provenance]
aliases: [source of truth, original source]
sources:
  - wiki/sources/ai-coding-dictionary-primary-source.md
confidence: high
---

# Primary Source

A source of truth in its original form — the code, the conversation transcript, the raw log, the actual API response. Not an account of the thing; the thing.

**Counterpart:** [[secondary-source]]

## Properties

- **Current by definition.** The code *is* what the codebase does. Docs, diagrams, and READMEs are descriptions — accurate when written, on their own schedule ever since. An agent that read a doc inherits the doc's staleness; an agent that read the code is reading the current truth.
- **Expensive to load.** The full file, the full transcript — every token billed as input and competing for attention budget. This cost is why primary sources are not the default.
- **Complete.** Nothing has been pre-filtered by someone else's judgement about what mattered. A summary written last month can't contain the detail that turned out to matter today; the primary source still does.

## When to pay for it

Reach for the primary source when precision matters — the exact signature, the actual error, the line that throws. When an agent confidently asserts something wrong, the diagnostic question is which source class it worked from. Much of managing context is deciding when to pay for the primary source and when a [[secondary-source]] is good enough.

## Relevance to this vault

Cortex Forge encodes this distinction structurally: `.raw/` holds primary sources (immutable, complete) and `wiki/` holds secondary sources (synthesized, cheap to load). The conflict rule in `AGENTS.md` follows directly: when wiki content contradicts its `.raw/` original, the primary source wins and the wiki page must be re-synthesized.

The `confidence:` frontmatter criteria also track source class: `high` is reserved for primary sources (code, papers, official docs), `medium` for secondary accounts.

---

- 2026-06-10 [Claude Code]: Page created from full-article ingestion
