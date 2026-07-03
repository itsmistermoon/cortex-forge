---
title: "Secondary Source"
type: concept
created: 2026-06-10
updated: 2026-06-10
tags: [epistemology, context-engineering, provenance, failure-modes]
aliases: [account, derived source]
sources:
  - wiki/sources/ai-coding-dictionary-secondary-source.md
confidence: high
schema_version: "0.3"
---

# Secondary Source

An account of a primary source, one step removed — documentation describing code, a summary describing a transcript, a report describing search results. Cheaper to load into the context window than the source it describes, and lossy by construction: whoever wrote it decided what mattered, and whatever they dropped is invisible to a reader who only has the summary.

**Counterpart:** [[primary-source]]

## Context engineering manufactures them

Compaction turns session history into a summary that seeds the next session. A subagent burns its own context on a noisy search and returns a short report. A [[handoff-artifact]] condenses a session's decisions into a document the next session reads. [[memory-system|Memory systems]] distil what a session learned into notes. Each makes the same trade: fidelity for headroom.

## Two failure modes

- **Lossy** — the compaction summary that lost the schema decision, the report that didn't mention the edge case. The dropped detail is invisible to the reader.
- **Drift** — the primary source changes and the account doesn't follow, so docs describe last quarter's architecture with this quarter's confidence.

An agent acting on a failed secondary source works confidently from wrong information. The fix is sending it back to the [[primary-source]].

## The context pointer

Neither failure makes secondary sources a mistake — the context window is finite, and without summaries and reports nothing large fits. The skill is knowing which details survive the loss, and verifying against the primary when one can't. A well-made secondary source carries a **context pointer** back to its original: the summary that names the transcript it came from, the doc that names the file it describes.

## Relevance to this vault

Every `wiki/` page is a secondary source by design, and the vault enforces the context-pointer pattern structurally: source pages carry a `raw:` frontmatter field pointing back to their `.raw/` primary, and `cortex-prune.sh` (co-located with the `cortex-prune` skill) flags `.raw/` files without a source page. The conflict rule in `AGENTS.md` is the drift remedy: on contradiction, the primary wins. `.hot/MEMORY.md` is a manufactured secondary source of the session itself — which is why its History entries name commits and files rather than paraphrasing them.

---

- 2026-06-10 [Claude Code]: Page created from full-article ingestion
