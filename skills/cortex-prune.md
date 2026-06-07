# cortex-prune

Health check of the vault. Traverse `wiki/`, compile findings by category ordered by severity, report, and ask whether to proceed with corrections.

## Detection criteria

### High severity
- **Dead links** — `[[wikilinks]]` pointing to pages that don't exist on disk
- **Unprocessed sources** — files in `.raw/` with no corresponding page in `wiki/sources/`
- **Pages without frontmatter** — `.md` files in `wiki/` with no YAML block

### Medium severity
- **Orphan pages** — no incoming wikilinks from any other vault page
- **Active projects without linked sources** — `wiki/pages/` with `status: active` and no source in `wiki/sources/` referencing them
- **Concepts without outgoing wikilinks** — concept page that links to nothing (signal of isolated knowledge)
- **Missing provenance** — pages without `sources:` or `confidence:` fields in frontmatter

### Low severity
- **Potentially stale claims** — pages with `updated` > 90 days containing factual statements (prices, APIs, versions)
- **Sources without tags** — `wiki/sources/` with `tags: []` empty
- **Entities without appearances** — `wiki/entities/` not referenced from any source or concept

## Expected output

For each finding: file path, problem description, suggested action.
At the end: count summary by severity + ask whether to auto-correct low severity items.

## Allowed auto-corrections

- Add missing frontmatter (infer type from folder)
- Add entry in `wiki/index.md` for pages that exist on disk but aren't indexed
- Add entry in `wiki/meta/log.md`: `## [YYYY-MM-DD] prune | {N} findings — {summary}`

## Actions requiring confirmation

- Delete orphan pages
- Mark claims as `[!stale]`
- Create missing source pages for unprocessed files
