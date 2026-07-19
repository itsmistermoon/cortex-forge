---
"antu": minor
---

`wiki/` is now OKF (Open Knowledge Format) compatible (ADR 0005): pages cross-reference each other with bundle-relative markdown links (`[title](/wiki/entities/x.md)`) instead of `[[wikilinks]]`, cite their backing sources in a `# Citations` section instead of `sources:` frontmatter, and all four page templates gain a `description:` field. `meta/` (tag registry, vault health report) moves out of `wiki/` to become a sibling directory, and the vault-wide log moves from `wiki/meta/log.md` to `wiki/log.md`. `wiki/index.md` now declares `okf_version: "0.1"` in frontmatter.

This is a hard cut with no compatibility shim, consistent with the project's zero-legacy policy: `wiki-ingest`, `wiki-query`, `wiki-imprint`, `wiki-lint`, and `wiki-setup` all produce and expect the new format going forward. Existing vault content written under the old conventions is unaffected until separately migrated — a later, explicitly authorized task, not part of this change.
