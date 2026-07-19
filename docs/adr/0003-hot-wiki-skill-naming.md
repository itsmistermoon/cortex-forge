# ADR 0003: Rename skills from suite-prefixed to `hot-`/`wiki-` naming

## Status

Accepted — resolved via `/grill-with-docs`, 2026-07-18. Not yet implemented.

## Context

Antu's skills carry the suite's own brand as their prefix (`antu-ingest`, `antu-handoff`, ...), and Kuyen mirrors the pattern (`kuyen-handoff`, ...). The project wants to keep Antu and Kuyen as the *product* names, but the brand prefix on each individual skill is ambiguous for adoption — it tells a newcomer which suite a skill belongs to, but nothing about what the skill actually does, and in particular nothing about which of the two distinct memory domains a skill operates on: the ephemeral per-session `.hot/` directory (ADR 0001) versus the persistent `wiki/` vault. A generic prefix like `vault-` was considered and rejected — it collapses that same distinction instead of surfacing it. See `docs/family-conventions.md` for the broader cross-suite convention this ADR is scoped under, same as ADR 0001.

## Decisions

### 1. Prefix words and the generative rule: `hot-` / `wiki-`

Two prefixes, chosen to match the directory names ADR 0001 already fixed (`.hot/`, `wiki/`) rather than inventing new vocabulary:

- **`hot-`** — the skill's primary responsibility is `.hot/` (session state: `HANDOFF.md`, `HISTORY.md`, `PLAYBOOK.md`).
- **`wiki-`** — the skill's primary responsibility is `wiki/` (persistent, cross-session knowledge).

This is recorded as a general rule, not just a fixed table — any suite (Antu, Kuyen, or a future one) applies it to its own skill inventory without re-deriving the criterion each time.

### 2. Antu's mapping

| Old | New |
|---|---|
| `antu-handoff` | `hot-handoff` |
| `antu-triage` | `hot-triage` |
| `antu-ingest` | `wiki-ingest` |
| `antu-recall` | `wiki-recall` |
| `antu-imprint` | `wiki-imprint` |
| `antu-prune` | `wiki-prune` |
| `antu-setup` | `wiki-setup` |

### 3. Cross-suite scope: applies to Kuyen too

Same principle applies to Kuyen, recorded in `docs/family-conventions.md` as a shared convention. Kuyen implements it separately, in its own repo (`moon-kuyen`), over its own skill inventory — which is not identical to Antu's (no `triage`, no `imprint`, per the existing "Explicitly not shared" section of `family-conventions.md`). This ADR does not enumerate Kuyen's resulting names; the rule in decision 1 is sufficient for that repo's own implementation to derive them.

### 4. Internal script filenames also drop the `antu-` prefix

Scripts living inside a skill's own folder (`antu-index.py`, `antu-search.py`, `antu-sanitize.sh`, `antu-prune.sh`, `antu-validate-schema.sh`, `antu-reindex-post-commit.sh`) lose the brand prefix too, since the enclosing folder no longer carries it either (e.g. `skills/wiki-prune/scripts/antu-prune.sh` would otherwise read inconsistently). `bin/antu-embed.sh`, which lives at the repo root rather than inside a skill folder, keeps its prefix — there's no enclosing skill-folder name to make it redundant.

### 5. Hard cut, no alias

Skill names change with no backward-compatible alias skill left behind for the old names. Claude Code has no native "skill alias" mechanism; a shim would mean maintaining dead skill folders whose only content is "moved to X." Reinstalling (`npx skills add`) picks up the new names automatically. The project is pre-1.0 (`0.x`), where breaking changes are expected.

### 6. `plugin.json` gains `hot-triage`, bundled with this rename

`.claude-plugin/plugin.json`'s `skills` array never included `antu-triage` — an oversight from when that skill was added, since `skills.sh.json` does list it. Fixed in the same change rather than filed separately, since the rename already touches every line of that array.

### 7. Skill-list ordering: regrouped by domain

`skills.sh.json` and `plugin.json` list `hot-*` skills first, then `wiki-*` skills, replacing the previous usage-flow ordering (ingest, handoff, setup, imprint, prune, recall, triage). Now that the name itself communicates the category, the listing reinforces it.

### 8. Versioning: `patch`

Matches existing precedent in this repo's pending changesets — `rename-praxis-playbook.md` and `family-conventions-hot-unification.md` (pure renames, no behavior change) are both `patch`; `minor` is reserved for genuinely new functionality (e.g. `antu-triage-skill.md`, which added a 7th skill).

### 9. `CHANGELOG.md`: new, separate `[Unreleased]` bullet

The existing `[Unreleased]` bullet documenting the Cortex Forge → Antu rename (`cortex-assimilate` → `antu-ingest`, etc.) has not shipped yet. Rather than editing it to jump straight to the final name (`cortex-assimilate` → `wiki-ingest`), this rename gets its own bullet. Two distinct decisions (this ADR and the original Antu rename) stay visible as two distinct historical steps, even though neither has been released under a version number yet.

### 10. `hot_cache_stale_days` → `playbook_stale_days`, migrated rather than cut

Picks up a follow-up flagged in ADR 0001's Consequences and left unresolved there. Unlike skill names, this key lives in `~/.cortex-forge/config.yml` — a file that persists on the user's machine and is never refreshed by reinstalling skills. A hard cut would silently drop a user's explicit customization (falls back to the default of 15 with no warning). Instead, `wiki-setup` migrates: if `playbook_stale_days` is absent but `hot_cache_stale_days` is present, read the old value, write it under the new key, and surface a one-line notice that the migration happened.

### 11. ADR numbering: `0003`, not `0002`

`0002` is reserved for issue #42 ("Centralize shared skill-reference documentation instead of per-skill duplication"), which is open but has no ADR written yet. This decision is filed as `0003` to avoid a numbering collision once #42 gets its own record.

## Consequences

- All 7 Antu skill folders, their `SKILL.md` `name:` frontmatter, and every cross-reference across `README.md`, `ROADMAP.md`, `AGENTS.md`, `CONTEXT.md`, `docs/family-conventions.md`, `skills.sh.json`, and `.claude-plugin/plugin.json` need updating in the same pass — a partial rename would leave the repo self-inconsistent.
- `moon-kuyen` needs an equivalent, separate rename applied in its own repo, on its own timeline.
- Global installs (`~/.agents/skills/`, `~/.claude/skills/` symlinks) need migration, same mechanism as ADR 0001.
- No compatibility shim exists: invoking `/antu-handoff` (or any other old name) simply stops resolving once this ships and a user hasn't reinstalled.
- Historical `CHANGELOG.md` entries and already-consumed `.changeset/*.md` files are left untouched — they're an accurate record of what was true when written, not a place to retcon the current name.

## Implementation plan

1. Apply decisions 1–2, 4, 6–8, 10 to `moon-antu`: rename the 7 skill folders and their `SKILL.md` `name:` fields, update every cross-reference, drop the `antu-` prefix from in-skill scripts, fix and reorder `plugin.json` and `skills.sh.json`, add `wiki-setup`'s `hot_cache_stale_days` → `playbook_stale_days` migration step, add the new `[Unreleased]` `CHANGELOG.md` bullet (decision 9), and file a `patch` changeset (decision 8).
2. Update `docs/family-conventions.md` to record the `hot-`/`wiki-` principle (decisions 1, 3) as a shared convention.
3. Apply the equivalent rename in `moon-kuyen` (decision 3), a separate repo and separate PR, over its own skill inventory.
4. Migrate both global installs (`~/.agents/skills/`, `~/.claude/skills/` symlinks).
5. **Final audit**, once everything above lands: run `/writing-great-skills` against every touched/new `SKILL.md`.

## Open questions

None — all decisions in scope for this session are resolved. Implementation is a separate step.
