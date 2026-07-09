---
"cortex-forge": minor
---

`cortex-forge-setup` can now scaffold a brand-new vault's `wiki/` structure and a starter `AGENTS.md` (protocol skeleton, no guessed identity content) instead of requiring them to already exist — closes the gap where a first-time user had no documented way to initialize a vault before running setup. Added `templates/tags.md` as a 5th template (rules + empty tag registry), synced via the existing upstream mechanism; a vault's actual `wiki/meta/tags.md` registry is never overwritten.
