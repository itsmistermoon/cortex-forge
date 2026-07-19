# Tags

[//]: # "Rules + registry in a single self-referencing document. No counts here — they go stale the moment a new page is ingested. For a point-in-time audit, run bin/tags-audit.py."

## Rules

1. **Reuse an existing tag if it applies** — check the list below before creating a new one. Be reluctant to invent new tags; prefer what already exists even if it's not a perfect fit.
2. **A tag must apply to several pages, not one or two.** If it's specific to a single page, it isn't a tag — it's body text or a markdown link.
3. **Format: lowercase, no accents, hyphen-separated.**

**Nested tags (optional):** a tag can take the form `topic/subtopic` when the parent is already a real topic with several pages of its own — e.g. `antu/architecture` for pages about that project's specific architecture, within the broader `antu` topic. Don't overuse this: it only makes sense when the parent would already exist on its own, not as an invented container to group a couple of loose tags.

---

## Topic

## Project
