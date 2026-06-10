# Obsidian visualization

cortex-forge's `wiki/` is a native Obsidian vault. No configuration required.

## Setup

1. Open Obsidian → Open Folder as Vault → select the `wiki/` directory.
2. Enable Graph View (left sidebar icon).

## What renders

- **Nodes** — every page in `wiki/` (concepts, entities, sources, pages, reference).
- **Edges** — every `[[wikilink]]` between pages.
- **Clusters** — Obsidian renders densely-linked groups visually, emerging naturally from the `[[wikilinks]]` that already exist.
- **Orphans** — isolated nodes with no connections are visually obvious — the same set that `cortex-prune` detects programmatically in its Layer 1 structural check.

## Relationship with cortex-prune

`cortex-prune` detects orphans and dead links programmatically. Obsidian shows the same information visually. They're complementary:

| | cortex-prune | Obsidian |
|---|---|---|
| Orphan detection | Programmatic (Layer 1) | Visual |
| Dead links | Programmatic (Layer 1, written to vault-report.json) | Not shown |
| Cluster detection | Not implemented (link-count scan deferred — see `ROADMAP.md`) | Native graph layout |
| Contradiction detection | Semantic (subagent) | Not shown |

## Status

Supported but not required. The vault is fully functional without Obsidian. The `[[wikilink]]` format is intentional — it serves double duty as Obsidian-compatible syntax and as an inter-page citation format that `cortex-recall` and `cortex-prune` can parse.

**Important:** Open `wiki/` only (not the vault root) to avoid Obsidian indexing `.raw/`, `.hot/`, and `skills/` as graph nodes.
