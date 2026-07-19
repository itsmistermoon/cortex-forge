---
"antu": patch
---

`wiki-lint`'s auto-correctable `wiki/log.md` entry tag changes from `prune` to `lint`, matching the skill's own name (a leftover from the ADR 0004 `wiki-prune` → `wiki-lint` rename that missed this one spot).

Adds `skills/wiki-setup/references/OKF-MIGRATION.md`: a step-by-step runbook for migrating an existing vault's `wiki/` content to the OKF format (ADR 0005), written so any agent can execute it once a user explicitly authorizes migrating a specific vault. Not wired into any automatic flow — `wiki-setup`'s Rules now note it as a second, narrow exception to "never write to an existing wiki/".
