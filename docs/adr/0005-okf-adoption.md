# ADR 0005: Adopt OKF (Open Knowledge Format) for `wiki/`

## Status

Accepted — resolved via `/wayfinder` (grilling + domain-modeling), 2026-07-19. Implementation plan steps 1–4 (templates, skills, `AGENTS.md`, changeset) landed 2026-07-19. Step 5 — migrating already-installed vault content (decision 8) — remains a separate, future task, not started, requiring explicit user authorization.

## Context

Antu's `wiki/` has grown its own improvised conventions — `[[wikilinks]]`, a `sources:` frontmatter list, `wiki/meta/` holding both registry files and a non-concept tag document — while the broader ecosystem has converged on [OKF (Open Knowledge Format)](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf): a vendor-neutral spec for representing knowledge as a bundle of markdown files with YAML frontmatter, designed to be produced and consumed by any agent or tool without a bespoke SDK. Rather than keep improvising, this ADR adopts OKF wholesale for `wiki/` — replacing Antu's own conventions where they overlap with the spec, and flagging any genuinely valuable divergence as a candidate feature request to OKF itself rather than a permanent fork.

**Scope: `wiki/` only.** `.hot/` (`HANDOFF.md`/`HISTORY.md`/`PLAYBOOK.md`, per ADR 0001) is deliberately out of scope here — its own OKF adoption is a separate, conditional evaluation for later, not a foregone conclusion.

**Kuyen cascade.** Decisions below are written about the format itself, not Antu-only implementation, because Kuyen (`almagest-kuyen`) is expected to adopt them later in a cascade. Kuyen's own adoption is a separate, future effort in its own repo — out of scope here.

**Execution is deferred.** This ADR records format decisions only. Migrating existing skills, templates, and already-written vault content (this repo's own `wiki-*` skills, and any vault that has installed them, e.g. `moon-multivac`) is explicitly **not** part of this ADR's implementation — see Consequences and Implementation plan.

## Decisions

### 1. Cross-linking: markdown links replace `[[wikilinks]]`

OKF §5 specifies relationships between concepts as standard markdown links (`[title](/wiki/entities/x.md)`), preferring bundle-relative absolute paths (leading `/`) for stability when documents move within their subdirectory. Antu's `[[wikilink]]` syntax — used throughout `wiki-ingest`, `wiki-imprint`, `wiki-lint`, and `wiki-query` — is not markdown OKF's link-graph tooling (including the reference visualizer) can read; a generic OKF consumer would see it as inert body text, not a relationship. Antu adopts bundle-relative markdown links as the sole link syntax.

### 2. Citations: `# Citations` replaces `sources:` frontmatter; `resource:` is untouched

`sources:` (a frontmatter list on `concept`/`entity`/`project` pages, citing related pages) is dropped. OKF §8 defines `# Citations` — a numbered list of markdown links at the foot of the body — as the convention for a concept's supporting sources, and no OKF relationship mechanism lives in frontmatter (§5 is entirely body-link based). Keeping `sources:` alongside `# Citations` would create two sources of truth for the same relationship, with the frontmatter copy invisible to any generic OKF consumer (which only reads body links).

OKF's own conformance rules (§9) treat `# Citations` as soft guidance, not a validated grammar — looser than YAML frontmatter. Antu recovers the lost rigor on the producer side rather than the consumer side: skills always emit `# Citations` as `[N] [title](path)`, one per line, sequentially numbered, and `wiki-lint` gains a check that validates this shape (extending its existing dead-link detection) as part of the eventual migration.

`resource:` (singular — the one external URI a concept *is about*, already used correctly in `templates/source.md`) is a different axis from `sources:` (plural — pages that back a concept's claims) and is unaffected by this decision.

### 3. Log file: `wiki/log.md` replaces `wiki/meta/log.md`

OKF §7 allows `log.md` at any level of the hierarchy, but scopes it to *that* directory — `wiki/meta/log.md` would read to an OKF consumer as `meta/`'s own log, not the vault's. Antu moves the vault-wide log to the bundle root (`wiki/log.md`) and standardizes every skill that writes to it (`wiki-ingest`, `wiki-imprint`, `wiki-lint`, `wiki-query`'s `query-miss` entries) on the new path.

### 4. `meta/` moves out of the bundle, becomes a sibling of `wiki/`

`wiki/meta/tags.md` (no `type:` frontmatter — fails OKF conformance §9 rule 1–2 as-is) and `wiki/meta/vault-report.json` (non-markdown, not a concept) both stem from the same root cause: `meta/` holds operational/registry material, not curated knowledge, and doesn't belong inside an OKF bundle. Moving it to a sibling directory (`meta/` next to `wiki/`, not inside it) resolves both problems at once without inventing a `type: registry` fiction or forcing JSON to pretend to be markdown.

### 5. `description:` added to all page templates

OKF recommends `description` (§4.1) — a one-line summary used by `index.md` generators and search/preview surfaces. `templates/concept.md`, `entity.md`, `source.md`, and `project.md` all gain the field.

### 6. `wiki/index.md` declares `okf_version: "0.1"`

Per OKF §11, a bundle root `index.md` MAY declare the spec version it targets — the only `index.md` permitted frontmatter at all. Antu's vault-root `wiki/index.md` declares `okf_version: "0.1"` so any OKF consumer knows what it's reading.

### 7. No change: type taxonomy and `.raw/`

- `type:` values (`concept`/`entity`/`source`/`project`) need no change — OKF explicitly declines to mandate a fixed taxonomy (§1 Non-goals) and tolerates any string (§9: consumers MUST NOT reject unknown `type` values).
- `.raw/` staying outside `wiki/`, referenced from `wiki/sources/*.md` via `resource:`/`raw:`, already matches OKF's own recommended pattern for preserving raw source material: §8 names a `references/`-style subdirectory of first-class OKF concepts as the *citable* representation, with the actual raw external content living outside the bundle. No change needed.

### 8. Migration of existing content: out of scope for this ADR

A full migration of already-installed vaults (existing `wiki/` content written under the old conventions) is wanted eventually, but as separate, later work — explicitly triggered by the user, not automatically undertaken by whichever agent implements this ADR's format decisions. This ADR only changes what `wiki-*` skills produce and expect going forward. The runbook for that later task, written so any agent can execute it once authorized, lives at `skills/wiki-setup/references/OKF-MIGRATION.md`.

## Consequences

- `templates/concept.md`, `entity.md`, `source.md`, `project.md` all need updating (decisions 2, 5).
- Every skill that reads or writes `wiki/` content needs its logic and prose updated for the new link syntax, citation format, log path, and `meta/` location: `wiki-ingest`, `wiki-query`, `wiki-imprint`, `wiki-lint`, `wiki-setup` (including `references/NEW-VAULT-SCAFFOLD.md`'s scaffold commands — `mkdir -p wiki/{concepts,entities,sources,projects}` plus a sibling `meta/`, `wiki/index.md`'s starter content, and the `wiki/log.md` path).
- `AGENTS.md`'s "Wiki taxonomy" table and surrounding prose need a pass to reflect the new `meta/` location and mention OKF conformance.
- No compatibility shim for the old `[[wikilink]]` syntax, `sources:` field, or `wiki/meta/` path — consistent with the project's established zero-legacy policy (ADR 0004, decision 8). This is a hard cut for any vault that reinstalls the suite; existing vault content is unaffected until separately migrated (decision 8).
- A changeset is required per repo convention (`AGENTS.md` Agent rules) when this is implemented; whether it's `patch` or `minor` is a judgment call for that PR, since this changes produced output shape without adding a new skill.
- Kuyen's own OKF adoption is not decided here — expected to follow this ADR's decisions later, in its own repo, on its own timeline.
- `.hot/`'s OKF adoption remains an open, separate, conditional question — not decided by this ADR either way.

## Implementation plan

1. Update `templates/concept.md`, `entity.md`, `source.md`, `project.md`: drop `sources:`, add `description:`.
2. Update `wiki-ingest`, `wiki-query`, `wiki-imprint`, `wiki-lint`, `wiki-setup` (SKILL.md and `references/`) for: markdown-link syntax (decision 1), `# Citations` generation/parsing incl. `wiki-lint`'s format validation (decision 2), `wiki/log.md` path (decision 3), `meta/` as a `wiki/`-sibling (decision 4), `wiki/index.md` scaffold including `okf_version: "0.1"` (decision 6).
3. Update `AGENTS.md`'s wiki taxonomy section and any other cross-references to `wiki/meta/`.
4. File a changeset and open a PR, per this repo's standard workflow (`AGENTS.md` Agent rules).
5. **Not in this implementation pass**: migrating already-installed vaults' existing content (decision 8) — a separate task, started only when explicitly authorized. The runbook is written and ready (`skills/wiki-setup/references/OKF-MIGRATION.md`); its execution against any specific vault is not.

## Open questions

- Whether `.hot/` should also adopt OKF — explicitly out of scope here; a future, conditional evaluation.
- Kuyen's adoption timeline and any format nuance specific to its repo — deferred to Kuyen's own effort.
