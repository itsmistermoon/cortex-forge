# Obsidian visualization

cortex-forge's `wiki/` is a native Obsidian vault. No configuration required.

## Setup

1. Open Obsidian → Open Folder as Vault → select the `wiki/` directory.
2. Enable Graph View (left sidebar icon).

## What renders

- **Nodes** — every page in `wiki/` (concepts, entities, sources, pages, reference).
- **Edges** — every `[[wikilink]]` between pages.
- **Clusters** — Obsidian renders densely-linked groups visually, emerging naturally from the `[[wikilinks]]` that already exist.
- **Orphans** — isolated nodes with no connections are visually obvious — the same set that `cortex-prune` detects programmatically and writes to `vault-report.json`.

## Relationship with cortex-prune

`cortex-prune` detects orphans and dead links programmatically. Obsidian shows the same information visually. They're complementary:

| | cortex-prune | Obsidian |
|---|---|---|
| Orphan detection | Programmatic, written to vault-report.json | Visual |
| Dead links | Programmatic | Not shown |
| Cluster detection | Link-count approximation (most_referenced) | Native graph layout |
| Contradiction detection | Semantic (subagent) | Not shown |

## Status

Supported but not required. The vault is fully functional without Obsidian. The `[[wikilink]]` format is intentional — it serves double duty as Obsidian-compatible syntax and as an inter-page citation format that `cortex-recall` and `cortex-prune` can parse.

**Important:** Open `wiki/` only (not the vault root) to avoid Obsidian indexing `.raw/`, `.hot/`, and `skills/` as graph nodes.
