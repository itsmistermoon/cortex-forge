# ADR 0002: Centralize shared skill-reference documentation

## Status

Accepted — implemented and merged in PR #41 (2026-07-18). Spec recorded in issue #42; this ADR is the permanent in-repo record of the decision and its reasoning.

## Context

Several reference docs were consumed by multiple skills at once (`VAULT-RESOLUTION.md`, `LOCALE-RESOLUTION.md`, `HANDOFF-FORMAT.md`, `PLAYBOOK-FORMAT.md`) and lived as duplicated copies inside each consuming skill's own `references/` folder. Editing shared documentation meant a synchronized multi-file edit across every consumer, and copies silently drifted: a fix that landed in only one copy went unnoticed until much later. There was no way to know a change needed replication elsewhere short of remembering the full list of dependent skills by hand.

A related caution predates this decision: an earlier attempt at a shared location (for a different category of file) was reverted because the suite's per-skill installer doesn't distribute content living outside an individual skill's own folder. Any new shared location must not depend on that installer.

## Decisions

### 1. One canonical copy at `references/` (repo root)

Shared reference docs move to a single canonical copy in a top-level `references/` directory, sitting alongside the other top-level shared assets (like `templates/`). There is exactly one place to edit.

### 2. Runtime reads from `~/.cortex-forge/references/` (global, once per machine)

Every skill reads shared reference material from a global location beside the suite's existing global config (`~/.cortex-forge/config.yml`), not from within its own skill folder. This sidesteps the per-skill-installer limitation that sank the earlier attempt: distribution doesn't depend on that installer at all.

### 3. Distribution reuses the existing infrastructure-sync procedure

`antu-setup`'s upstream-sync step (see `skills/antu-setup/references/UPSTREAM-SYNC.md`) — already trusted for keeping vault templates current — is extended to a second destination: global shared references (once per machine) alongside its existing per-vault destination. No second distribution channel is invented. Writing to the global location always asks first — confirming local vault scaffolding is not consent to write machine-global files that affect every other vault.

### 4. Executable scripts stay duplicated per skill — explicitly excluded

Per an existing security decision that predates this change: code must never execute from a location outside a skill's own installation, since a shared location would become a shared attack surface. That reasoning doesn't apply to inert documentation, which carries no execution risk. Centralizing scripts was considered and rejected.

### 5. Consistency check flips from "copies stay identical" to "no local copies exist"

With nothing left to keep in sync for reference docs, `scripts/check-skill-sync.sh`'s byte-identical check for them is retired, replaced by a guard against a skill re-introducing a local copy of a shared doc (regression back toward duplication fails CI). The same script and enforcement style that already verified duplicated executable scripts stay byte-identical — a different invariant, same tool.

### 6. Distribution manifests are checked against disk

A second check compares every skill-listing manifest (`skills.sh.json` for `npx skills add`, `.claude-plugin/plugin.json` for the Claude Code plugin) against the actual `skills/*/` folders on disk. A skill silently missing from one distribution channel — which has already happened — is caught mechanically rather than by a maintainer noticing.

### 7. Missing-doc fallback: prompt to run `antu-setup`

Skills that depend on a shared reference doc instruct the user to run the suite's setup skill if the doc isn't present yet — the same fallback pattern already used when `~/.cortex-forge/config.yml` itself is missing, not a new failure mode.

### 8. Migration: automatic for new vaults, one manual sync for existing ones

Brand-new vault setup populates `~/.cortex-forge/references/` automatically as part of scaffolding. Vaults registered before this change require one manual `/antu-setup` sync to populate the new global location, and are told so explicitly rather than hitting a confusing missing-file error.

### 9. Dependency preflight in the consistency check

`check-skill-sync.sh` fails immediately with a clear, platform-aware install suggestion if a required external tool (`jq`, `diff`) is missing, rather than surfacing a raw shell error partway through a run.

## Consequences

- Editing a shared reference doc is a single-file change; every skill reads the same content via `~/.cortex-forge/references/`.
- The single-source-of-truth invariant is enforced by CI (`.github/workflows/skill-sync.yml` running `scripts/check-skill-sync.sh`), not manual review.
- The regression guard was manually verified by temporarily reintroducing the exact drift it protects against (a skill missing from a manifest), confirming the check fails, then reverting.
- Pre-existing vaults need one manual sync; until then, affected skills degrade to a "run `/antu-setup` first" prompt rather than failing silently.

## Out of scope

- Centralizing executable scripts — explicitly rejected (decision 4).
- The sibling lite suite's (Kuyen) own reference material — this decision is scoped to Antu and doesn't touch shared cross-suite conventions (`docs/family-conventions.md`).
- Retroactively auditing other, unrelated documentation elsewhere in the repo for similar duplication — only the files already identified as duplicated were in scope.
