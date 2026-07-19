# ADR 0004: Almagest — umbrella brand, repo identities, and the final naming pass

## Status

Accepted — resolved via `/grill-with-docs`, 2026-07-18. Not yet implemented.

## Context

Three naming layers had drifted out of sync: the GitHub repo still carries the pre-Antu name (`cortex-forge`), the global config directory still carries it too (`~/.cortex-forge/`), and the sibling suite Kuyen had a dead repo link (`moon-reflex` doesn't exist on GitHub; Kuyen is local-only). Meanwhile ADR 0003 introduced a latent collision it didn't confront: both suites install *flat* into `~/.agents/skills/` (verified: skills.sh has no cross-source namespacing and no conflict handling — identical names silently overwrite), so Kuyen literally applying the `hot-`/`wiki-` rule would collide with Antu's installed skills. This ADR resolves all of it in one pass under a new umbrella name: **Almagest**, the house that contains the Antu (full) and Kuyen (lite) suites.

Note: the GitHub username `almagest` is taken, ruling out a bare-name GitHub Organization; repo names under `itsmistermoon` are all free.

## Decisions

### 1. Almagest is the family name; its canonical home is a small public umbrella repo

**Almagest** is the umbrella ("casa madre") for the two suites. Its canonical definition lives in a new public repo, `itsmistermoon/almagest`, containing only: a README (what Almagest is, the full-vs-lite chooser table, links to both suites) and `docs/family-conventions.md` (moved out of the Antu repo, where it lived "borrowed"). Suite repos link to the umbrella; prose in either suite mentions Almagest once as family context, never as a prefix on every mention (consistent with ADR 0003's lesson: the brand doesn't ride along on every name).

### 2. Repo identities: `almagest-antu`, `almagest-kuyen`, `almagest`

- `itsmistermoon/cortex-forge` is **renamed** to `itsmistermoon/almagest-antu` (GitHub redirects old URLs).
- Kuyen is **published for the first time** as `itsmistermoon/almagest-kuyen` (it currently has no remote at all — the `moon-reflex` link in family-conventions.md is dead).
- The umbrella repo `itsmistermoon/almagest` is created per decision 1.
- All three are public.
- `package.json` `name` stays `antu` (changesets unaffected); `plugin.json` `displayName` becomes "Almagest Antu"; install/upstream URLs update to `itsmistermoon/almagest-antu`.

### 3. Local layout mirrors the family

```
~/proyectos/moon-almagest/          ← checkout of the umbrella repo
├── almagest-antu/                  ← the Antu repo itself (moved from moon-antu/), gitignored by the umbrella
├── almagest-kuyen/                 ← the Kuyen repo itself (moved from moon-kuyen/), gitignored
├── docs/family-conventions.md
└── README.md
```

The suite directories are the official local repos physically nested inside the umbrella checkout — plain gitignored directories, not clones, not submodules (submodules are ceremony for a single maintainer working in all three at once). This restructure is the **final** step of implementation: moving the repos breaks active git worktrees (absolute paths; repaired with `git worktree repair`) and stales the `path:` entries in the global config's vault registry, both fixed in the same pass.

### 4. Global config: `~/.cortex-forge/` → `~/.almagest/`, shared by both suites

The directory is renamed; its internal structure is unchanged (restructure when a real need appears, not speculatively). It becomes a **shared** Almagest asset with a deliberately asymmetric contract:

- Antu keeps its full multi-vault registry machinery (unchanged).
- Kuyen may read exactly one thing: the default vault's path (`default:` + that vault's `path:`), to resolve its single write-target vault. This scopes — not contradicts — ADR 0001 decision 9 and family-conventions' "multi-vault is Antu-only": Kuyen consumes one key; it gains no registry machinery, no vault-name arguments, no resolution logic.
- `upstream:` default becomes `itsmistermoon/almagest-antu`.

### 5. Antu verb convergence: `wiki-recall` → `wiki-query`, `wiki-prune` → `wiki-lint`

Comparison of the two suites showed `kuyen-query`/`kuyen-lint` are exact functional mirrors of `wiki-recall`/`wiki-prune` (same core contract; Antu is a superset). The suites converge on **`query`/`lint`** — the terms from Karpathy's LLM-wiki gist this whole family descends from, and the literal, industry-standard words — consistent with the jargon-reduction principle this repo already applied twice (ADR 0001 decisions 2 and 10: the literal name beats the memory metaphor). Supersedes those two rows of ADR 0003's mapping table; everything else from ADR 0003 stands.

Mechanical consequences: `wiki-lint`'s `prune.sh` → `lint.sh`; the `log.md` miss tag `recall-miss` → `query-miss`; flavor lines updated (`Querying vault...`, `Linting vault...`). Antu's final inventory: `hot-handoff`, `hot-triage`, `wiki-ingest`, `wiki-query`, `wiki-imprint`, `wiki-lint`, `wiki-setup`.

### 6. Cross-suite flat-install collision: Kuyen prefixes `kyn-`

skills.sh installs flat with silent overwrite on name collision (researched against vercel-labs/skills: no cross-source namespacing; the `skills/<category>/<name>/` catalog layout is repo-internal organization, not an installed namespace). Since both suites must coexist on any agent — not just Claude Code, whose plugin namespaces don't help the others — Kuyen's installed skill names carry an abbreviated brand prefix: **`kyn-hot-handoff`, `kyn-wiki-ingest`, `kyn-wiki-query`, `kyn-wiki-lint`**.

This amends ADR 0003 decisions 1 and 3: the `hot-`/`wiki-` domain rule gives the *base* name in both suites; the lite suite prepends `kyn-` to guarantee flat coexistence with the full suite, which owns the clean names. `kyn` was chosen over the full `kuyen` for brevity while keeping the origin recognizable.

### 7. Kuyen distribution: flat-only, no Claude Code plugin

A skill's name is a single source consumed by both channels — the plugin namespace prepends to the same name, so a Kuyen plugin would read `/kuyen:kyn-wiki-query` (double brand). Diverging the plugin name from the flat name isn't cleanly possible: it requires duplicate skill directories, skills.sh scans all of `skills/` (both copies would install flat, recreating the collision), and `plugin.json`'s `skills` array adds to rather than replaces the default directory scan (both variants would appear in the plugin namespace). So Kuyen ships flat-only via `npx skills add itsmistermoon/almagest-kuyen`; the invocation is `/kyn-*` everywhere, including Claude Code. Trivially reversible — a plugin manifest can be added any time. Antu keeps both channels.

### 8. Zero-legacy policy: no migration shims in skills, ever

The project has no external adoption yet; exactly one machine is affected. Therefore:

- The `hot_cache_stale_days` → `playbook_stale_days` migration step that shipped in PR #46 (`wiki-setup` step 3c) is **removed** — the skill reads and writes only the new key.
- The legacy `.hot/vault.db` fallback path in `wiki-query` (ex `wiki-recall`) is removed — only `.hot/db/vault.db` is supported.
- No code anywhere migrates `~/.cortex-forge/` → `~/.almagest/`.

Instead, the maintainer's machine is migrated by hand at cut time, in this order: move `~/.cortex-forge/` → `~/.almagest/`; rename the config key; update `upstream:` if it holds the old default; rewrite installed post-commit hooks to point at `~/.almagest/bin/`; reinstall global skills under the new names (removing the stale `antu-*`, `kuyen-*`, and orphaned `cortex-*` entries); update `query-miss` tags and vault `path:` entries after the local restructure (decision 3). Future breaking changes follow the same policy until real adoption exists.

## Consequences

- ADR 0003 is amended in two places (decisions 5 and 6 above); its hard-cut/no-aliases stance and everything else stand.
- `family-conventions.md` moves to the umbrella repo; `AGENTS.md`/`CONTEXT.md` references in the suite repos point cross-repo. Its Kuyen entry finally gets a live URL.
- README/AGENTS.md/CONTEXT.md/manifests in `almagest-antu` need the Almagest context section, new repo URLs, and the `query`/`lint` names; `skills.sh.json` and `plugin.json` update accordingly.
- Kuyen's repo needs its own rename pass (`kuyen-*` → `kyn-*` names), `.gitignore` review, README with family link, and first push.
- The `gh repo rename` on `cortex-forge` is executed only after explicit user confirmation at that step (agreed in session).
- Optional follow-up, not blocking: file a feature request on vercel-labs/skills for cross-source namespacing; if it ever lands, decision 6's prefix could be revisited.
- Stale remote branches on `almagest-antu` are cleaned up at the end; the pending changesets release PR (#38) merges last, cutting one version with everything.

## Implementation plan

1. `almagest-antu` (this repo): ADR 0004, verb renames (decision 5), zero-legacy strips (decision 8), Almagest branding/URLs (decisions 1–2), patch changeset, new PR.
2. Create umbrella repo `almagest` (README + family-conventions.md moved from here).
3. Rename `cortex-forge` → `almagest-antu` on GitHub (with confirmation), update local remotes.
4. Kuyen: `kyn-*` rename pass, README/family link, publish as `almagest-kuyen`.
5. Machine migration per decision 8 + global skill reinstall.
6. Local restructure per decision 3 (final step), including `git worktree repair` and config `path:` updates.
7. Branch cleanup; merge release PR #38.

## Open questions

None — all decisions in scope are resolved. Kuyen's flat-only distribution (decision 7) was set on the assistant's recommendation with the user's question answered but not separately re-confirmed; reversal is a one-file addition if wanted.
