---
title: Fail-Loud Design
type: concept
created: 2026-07-06
updated: 2026-07-06
tags: [design-principles, reliability, scripts, cortex-forge/architecture]
aliases: [fail loud, fail loudly, silent degradation]
sources:
  - wiki/projects/cortex-forge.md
  - wiki/sources/agentskills-using-scripts.md
confidence: medium
schema_version: "0.3"
---

# Fail-Loud Design

A system should error clearly and immediately when something goes wrong, rather than continuing in a degraded or partially-broken state without telling anyone. A hang, a silent skip, or a quietly-corrupted file is worse than a fast, visible error — the visible error gets fixed; the silent one accumulates until something downstream breaks in a way that's hard to trace back to its cause.

## Origin in cortex-forge

Formalized during a 2026-07-03 audit that reviewed every script in the suite (`cortex-prune.sh`, `cortex-validate-schema.sh`, `cortex-sanitize.sh`, `embeddings.py`, `cortex-reindex-post-commit.sh`, `install.sh`, `cortex-embed.sh`, `check-skill-sync.sh`) against three failure classes: unbounded waits, silent mid-run corruption, and broken path references. The audit caught its own motivating example the same day it ran: the script co-location migration had moved `cortex-prune.sh` into its skill's directory but left `cortex-validate-schema.sh` behind in the old shared `bin/`, silently disabling schema-drift checks for every install with no error anywhere — exactly the class of bug the audit was designed to catch.

## Manifestations across the suite

- **CLI scripts never block on interactive input.** Agents run in non-interactive shells; a script that waits on a TTY prompt hangs indefinitely instead of failing loud. All input comes via flags, env vars, or stdin — see `wiki/sources/agentskills-using-scripts.md`'s "avoid interactive prompts" guidance, which applies the same principle to script design.
- **Resource allocation failures abort, they don't degrade silently.** `mktemp` failures in `cortex-prune.sh` abort the run loudly instead of writing findings to an empty path; a missing `jq` in `cortex-sanitize.sh` used to produce invalid JSON that `cortex-assimilate` could misread as "no findings" — now checked explicitly, alongside the existing `rg` check.
- **Previously-unbounded waits now time out with a clear message.** `embeddings.py`'s Ollama embed call, `cortex-reindex-post-commit.sh`'s backgrounded reindex, and `install.sh`'s `curl` calls could all hang indefinitely before this audit; each now has an explicit timeout.
- **CI turns "a skill silently references something that doesn't exist" into a build failure.** `bin/check-skill-sync.sh`'s `available-script-exists` and `vault-report-schema` checks exist specifically to catch drift between what a `SKILL.md` claims and what's actually shipped, before it reaches a user's install.
- **Malformed session state is surfaced, not silently patched over.** `cortex-crystallize` reading a `.cortex/MEMORY.md` with malformed YAML frontmatter doesn't just fix it quietly — it reads the body as plain text and explicitly notes the issue in the next `#### Fragile context` entry, so the next agent knows the file was inconsistent rather than assuming it always looked that way.
- **Atomic writes prevent a crash from ever producing a silently-corrupted file.** `vault-report.json` and `~/.cortex-forge/config.yml` write to a temp file in the same directory and `mv` into place — a kill or crash mid-write can't leave a truncated `vault-report.json` or a `config.yml` that lost every registered vault.

## Related

- [[wiki/concepts/skill-design-principles]] — fail-loud is one of the principles that separates a skill that works from one that appears to work.
