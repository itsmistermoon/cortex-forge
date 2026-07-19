# OKF vault migration — existing vault runbook

Migrates a vault's existing `wiki/` content — written under Antu's pre-ADR-0005 conventions — to the OKF-compatible format that `wiki-ingest`, `wiki-query`, `wiki-imprint`, and `wiki-lint` now produce and expect (`docs/adr/0005-okf-adoption.md` in `itsmistermoon/almagest-antu`). Written so any agent can execute it cold, without having been part of the session that authored ADR 0005.

**Do not run this unless the user has explicitly authorized migrating this specific vault right now.** ADR 0005 decision 8 defers vault-content migration as a separate, later, user-authorized task — never trigger it opportunistically off a `wiki-lint` finding, a stale-format warning, or your own initiative. If you arrived here without that explicit go-ahead, stop and ask first.

## What's changing

| Old convention | New (OKF) convention |
|---|---|
| `[[wiki/{type}/{slug}]]` / `[[wiki/{type}/{slug}\|Display}]]` | `[Display or title](/wiki/{type}/{slug}.md)` |
| `sources:` frontmatter list | `# Citations` section at the foot of the body: `[N] [{title}](/wiki/sources/{slug}.md)`, sequential |
| `wiki/meta/log.md` | `wiki/log.md` |
| `wiki/meta/tags.md`, `wiki/meta/vault-report.json`, any other `wiki/meta/*` | `meta/tags.md`, `meta/vault-report.json`, etc. — `meta/` is a sibling of `wiki/`, not nested inside it |
| No `description:` in frontmatter | `description:` (a real one-line summary, not a placeholder) on every page |
| `wiki/index.md` with no frontmatter | `wiki/index.md` with `okf_version: "0.1"` frontmatter |

## Step A — Preconditions & safety

1. Confirm the user's authorization covers *this* vault, by name or path, not a general "sure, go ahead."
2. `cd` into the vault. Run `git status` — the working tree must be clean. If it isn't, stop and ask the user to commit or stash their own work first; this migration touches many files and needs a clean rollback point that isn't tangled with unrelated changes.
3. Confirm the vault's installed skills already reflect ADR 0005 — e.g. `grep -q '# Citations' ~/.agents/skills/wiki-lint/SKILL.md` (adjust the skills path per the agent/install method in use). If not, run `npx skills add itsmistermoon/almagest-antu --all -g -y` first. Migrating content while the installed skills still expect the old format leaves the vault inconsistent with its own tooling.
4. Create a dedicated branch for this migration (e.g. `git checkout -b okf-migration`) so the whole thing is one revertible unit, separate from the vault's `main`.
5. Run `/wiki-lint {vault}` for a baseline report. Expect a large number of findings — pages using the old format aren't recognized as valid by the new checks (see the table below for exactly which findings mean what). This is the expected starting state, not a regression to fix some other way.

## Step B — Structural moves (mechanical, do first)

These are pure file moves with no content risk — do them before touching any page body, and commit them as their own step.

```bash
# 1. Pull the log out to the bundle root
git mv wiki/meta/log.md wiki/log.md

# 2. Drop the stale generated report (gitignored — wiki-lint regenerates it
#    fresh at meta/vault-report.json on its next run; only rm if present)
rm -f wiki/meta/vault-report.json

# 3. Move everything else under wiki/meta/ (tags.md, any tags-audit
#    snapshots, anything else the vault accumulated there) to a meta/
#    sibling of wiki/, not nested inside it
git mv wiki/meta meta

git add -A
git commit -m "chore: relocate meta/ and log.md per ADR 0005 (OKF adoption)"
```

If the vault's `.gitignore` still says `wiki/meta/vault-report.json`, update it to `meta/vault-report.json` in the same commit.

## Step C — Content transformation (needs judgment, batch it)

Process `wiki/sources/` **first** — other pages' `# Citations` entries need each source's `title:`, so having sources already migrated (or at least readable) makes step C.3.b a lookup instead of a guess. Then `wiki/concepts/`, `wiki/entities/`, `wiki/projects/`, in any order.

For each type directory:

1. **Discover the worklist**: pages needing work are the union of
   ```bash
   grep -rl '\[\[wiki/' "wiki/{type}/"    # old wikilinks in the body
   grep -rl '^sources:' "wiki/{type}/"    # old sources: frontmatter
   ```
   plus any page missing `description:` in frontmatter (`wiki-lint` will have already flagged these as MEDIUM/LOW findings in the Step A baseline — cross-reference rather than re-deriving).

2. **Hard cap**: process in batches of 20 pages, committing after each batch. This mirrors the hard caps already used elsewhere in this suite for large-vault scale (`wiki-ingest` step 6, `wiki-lint` L2a/L2c) — don't attempt an entire 300-page vault as one unreviewable diff.

3. For each page in the batch:
   a. **Wikilinks → markdown links.** For every `[[wiki/{type}/{slug}]]` or `[[wiki/{type}/{slug}|Display}]]` in the body: resolve `wiki/{type}/{slug}.md`. If it doesn't exist, don't guess a replacement — flag it for the user (same standard as `wiki-lint`'s "Fix a dead markdown link" confirmation-required rule) and leave it as-is pending their decision. If it exists, read its `title:` and replace with `[{Display text, or the target's title if no alias was given}](/wiki/{type}/{slug}.md)`.
   b. **`sources:` → `# Citations`.** Read the page's `sources:` list. For each `wiki/sources/{slug}.md` entry, read that source's `title:`. Build a `# Citations` section at the foot of the body (immediately before the changelog `---`) with sequential, numbered entries: `[1] [{title}](/wiki/sources/{slug}.md)`, `[2] [...]`, etc. Then delete the `sources:` key from frontmatter entirely — don't leave it empty, remove it (matches `templates/{type}.md`, which no longer has the field).
   c. **`description:`.** If missing, read the page and write a genuine one-line summary of its content — this step can't be mechanized; don't copy a placeholder or leave it blank.
   d. Bump `updated:` to today's date. Add a changelog line: `- {date}: Migrated to OKF format (markdown links, # Citations, description)`.

4. After each batch: run `/wiki-lint {vault}` and confirm this batch's pages have dropped off the "No # Citations" / "missing description" findings. A page can still show as an orphan mid-migration if the *other* pages that used to link to it haven't been migrated yet — that clears naturally as migration proceeds, it isn't a bug in this batch.

5. **`wiki/index.md`**: convert its `[[wikilinks]]` listing entries to markdown links (`- [Title](/wiki/{type}/{slug}.md)`), and add `okf_version: "0.1"` to its frontmatter (create the frontmatter block if `index.md` doesn't have one yet — it's the one place OKF permits it, per §11).

## Step D — Final verification

1. Run `/wiki-lint {vault}`. Expect **0 HIGH findings**. Spot-check remaining MEDIUM/LOW findings — they should read as genuine, pre-existing vault issues (e.g. a page that legitimately never had a source), not migration leftovers. If any migration-era finding remains, go back to Step C for that page.
2. Confirm `meta/vault-report.json` now exists at the vault root (sibling of `wiki/`), not under `wiki/meta/`.
3. Final commit: `feat: migrate wiki/ to OKF format (ADR 0005)`, summarizing pages touched and any pages flagged for manual review (unresolvable wikilinks, ambiguous sources) that still need the user's decision.
4. Report to the user: pages migrated, pages skipped/flagged, and the final `wiki-lint` summary. Don't merge the migration branch yourself — that's the user's call.

## Rollback

Every step above is its own commit on a dedicated branch, so recovery is ordinary git: `git revert` a specific step, or `git reset --hard {pre-migration-commit}` if the whole thing needs to be abandoned (only if the working tree is otherwise clean — check `git status` first, per standard git safety). Never force-push over the vault's existing history without the user's explicit confirmation.
