---
"cortex-forge": patch
---

Fixed a `cortex-prune` false positive: a wikilink using an escaped alias pipe inside a markdown table cell (`[[path\|Display text]]`) left a trailing backslash on the captured link target, which never matched a real file and was reported as a dead link. The backslash is now stripped before the file-existence check.
