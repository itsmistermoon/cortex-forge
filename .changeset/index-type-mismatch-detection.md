---
"cortex-forge": patch
---

`cortex-prune` Layer 1 detects a new LOW finding: pages whose frontmatter `type:` silently mismatches the section of `wiki/index.md` they're listed under (heuristic A: only flag if the page is absent from its correct section, tolerates intentional cross-references). Console-only — not persisted to `vault-report.json`, same pattern as the directory-structure check. Closes a gap documented in `ROADMAP.md` that previously required humans to catch by reading the index.
