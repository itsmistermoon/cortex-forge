# Family conventions: Antu ↔ Kuyen

Antu and [Kuyen](https://github.com/itsmistermoon/moon-reflex) are sibling vault suites — Antu is the full-feature option (provenance, multi-vault, semantic search, planned MCP integration), Kuyen is the lite option (tabula-rasa rebuild, minimal dependencies, fast). See the README's "Full vs. lite" table for how to choose between them for a given vault.

They are **not** merged: Kuyen does not depend on or reference `antu-*` skills, and Antu does not depend on `kuyen-*` skills. This document exists so that conventions the two suites happen to share stay in sync deliberately, instead of drifting apart or being re-discovered by accident.

## What belongs here

A convention that:
- is not specific to a feature only one suite has (e.g. multi-vault resolution is Antu-only — it doesn't belong here)
- both suites currently follow, or should follow, for a vault built with either to feel consistent (log formats, timestamp formats, file naming patterns a human or agent might expect either way)

## Current shared conventions

- **Log entry format**: `**[YYYY-MM-DD]**` (bold, not a heading) for dated entries in append-only logs. Synced manually 2026-07-09 after Kuyen adopted Antu's format; drift between Kuyen's repo and its globally-installed copy was found and fixed 2026-07-12 (see #22).
- **Log file location**: `wiki/meta/log.md`, not `wiki/log.md`. Kuyen moved to match Antu 2026-07-12.
- **Concept vs. Entity vs. Source classification criteria**: a Concept is synthesized knowledge with no existence outside the wiki (an idea you'd look up in a textbook — proper name, reusable, warrants its own article; skip concrete instances and topics too generic to stand alone). An Entity is a person/org/tool/service that exists independently and can go stale (skip passing mentions with no role of their own). A Source is reserved for external artifacts with a verifiable URL or file — a purely conversational origin never classifies as Source. Formalized identically in both suites 2026-07-12.
- **Contradiction check verdicts**: when comparing pages that share a tag/alias/cross-link, distinguish CONTRADICTION (incompatible facts on the shared subject) from CONSISTENT (mere difference in emphasis, scope, or vintage) — only CONTRADICTION is a finding. Formalized identically in both suites 2026-07-12.
- **`timestamp:` frontmatter field on source pages**: the original publication/content date, distinct from `created:` (when the page was made in the vault) and `updated:` (last edit). Both suites' real vaults used this field before either canonical template declared it; added to both templates 2026-07-12.
- **`source.md` omits `aliases:`**: unlike concept/entity pages, a source page doesn't get aliases — it's referenced by title, not looked up by alternate names. True in both suites' templates already; recorded here so a future cleanup doesn't "restore" it as a missing field.
- **Page changelog line has no author tag**: `- {{date:YYYY-MM-DD}}: description`, not `- {{date}} [{agent}]: description`. Kuyen dropped the agent tag deliberately (commit `14504be`); Antu's template never had one. The focus is the record of what changed, not which agent did it — kept as the shared convention 2026-07-12 even though some already-created pages in both vaults still carry the older `[agent]`-tagged lines from before this was settled.
- **Session-state directory and file names**: `.hot/` holding `HANDOFF.md` (session snapshot) and `HISTORY.md` (rotated/archived entries), resolved from the nearest `.git` root rather than the literal CWD. Antu renamed from `.cortex/`, `MEMORY.md`, `CONSOLIDATED.md`; Kuyen already used `.hot/` but also renamed `MEMORY.md`→`HANDOFF.md` and `CONSOLIDATED.md`→`HISTORY.md` to match, and adopted nearest-`.git` resolution in place of literal CWD. `.hot/` is never tracked in either suite — both add it to `.gitignore`. Antu's `PLAYBOOK.md` (renamed from `PRAXIS.md`) has no Kuyen equivalent, see "Explicitly not shared" below. Unified per ADR 0001 (`docs/adr/0001-unify-session-state-antu-kuyen.md`), implemented 2026-07-16.
- **Cross-suite `suite:` marker**: `antu-handoff` and `kuyen-handoff` each write a one-line `suite: antu` / `suite: kuyen` marker identifying who last wrote `HANDOFF.md`, so either skill can detect foreign content without parsing the other's schema. Neither suite adopts the other's format — Antu keeps frontmatter + fixed sections, Kuyen keeps free text. On finding the other suite's marker (or none at all), each skill archives the prior `HANDOFF.md` whole into `HISTORY.md` and calls this out explicitly in its confirmation, instead of attempting to merge or recover it automatically. Formalized in ADR 0001, implemented 2026-07-16.

## Shared frontmatter schema (concept / entity / source)

Kuyen's page templates were originally created by copying Antu's frontmatter fields (an explicit, one-time data reuse — not a design reference, which stays off-limits per Kuyen's `AGENTS.md`). As a result the two suites' templates converge almost field-for-field today:

| Field | concept | entity | source | Notes |
|---|---|---|---|---|
| `title` | ✓ | ✓ | ✓ | |
| `type` | ✓ | ✓ | ✓ | `concept\|entity\|source`, plus `project` (Antu only) |
| `created` | ✓ | ✓ | ✓ | date the page was made in the vault |
| `updated` | ✓ | ✓ | ✓ | date of last edit |
| `timestamp` | – | – | ✓ | source only — original publication/content date, see above |
| `tags` | ✓ | ✓ | ✓ | |
| `aliases` | ✓ | ✓ | – | source pages are referenced by title, not alternate names |
| `sources` | ✓ | ✓ | – | source pages don't cite other sources this way |
| `resource` | – | – | ✓ | URL or path to the external artifact |
| `source_author` | – | – | ✓ | |
| `raw` | – | – | ✓ | path to the `.raw/` copy |
| `confidence` | ✓ | ✓ | ✓ | `high\|medium\|low` |
| `schema_version` | ✓ | ✓ | ✓ | same field, versioned independently per suite (Antu is at `0.3`, Kuyen at `0.1`) — don't try to keep the number itself in sync, only the field's meaning |

Body structure (an untitled synthesis section, then a trailing `- {{date:YYYY-MM-DD}}: description` changelog) also matches across both suites' concept/entity/source templates. Kuyen's `concept.md` adds an extra `## Related` section Antu's doesn't have — a minor body divergence, not worth forcing into alignment.

When editing a template field in one suite, check the table above before assuming it's suite-specific — most frontmatter fields are shared by convergent origin, not coincidence.

## Explicitly not shared (intentional full/lite divergence)

These were reviewed during the 2026-07-12 audit (#22) and kept suite-specific on purpose — do not "fix" them into alignment:

- **Credential/injection sanitization** (`antu-sanitize.sh`) — Antu only. Kuyen has no equivalent script; the ligereza tradeoff means no automated safety net here.
- **`project` page type** — Antu only. Kuyen vaults are scoped smaller and don't track projects as their own page type.
- **Multi-vault resolution, research mode, semantic/embedding search** — Antu only, out of scope for Kuyen by design.
- **`raw:`/mtime drift check** (antu-prune Layer 3, detects a source re-fetched after being synthesized) — Antu only. Reasonable to skip for Kuyen's smaller, shorter-lived vaults.
- **`antu-triage` and `PLAYBOOK.md`** — Antu only. On-demand `.hot/` hygiene (`PLAYBOOK.md` pruning, foreign-suite pending recovery, Pending/Active decisions re-checks) mirrors the existing `antu-prune` pattern. Kuyen has no `PLAYBOOK.md`, no structured Pending to recover, and no equivalent skill — deliberately asymmetric per ADR 0001, decision 5.

## Open items

- **`tags.md`**: Antu has a `wiki/meta/tags.md` registry with reuse-before-inventing rules. Kuyen has no tag registry at all. Unlike the items above, this wasn't ruled out as a permanent divergence — the user wants to evaluate adding a lighter-weight version (simpler maintenance cycle) to Kuyen. Noted 2026-07-12, not yet designed or built.

## Adding a new convention

When you notice Antu and Kuyen converging (or should converge) on some format, name, or structural choice:
1. Confirm it's genuinely cross-cutting, not a full-feature-only concern (see "What belongs here" above).
2. Add an entry to "Current shared conventions" describing the convention and the date it was formalized.
3. Update both suites to match, if one is currently out of sync.
4. If only one side needs to change, do that edit directly in that repo — this document doesn't require a synchronized PR across both repos, just a synchronized *record* of what the convention is.
