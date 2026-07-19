# Upstream sync

Reference for `wiki-setup` (step 3b, maintenance menu option 2). Pulls updated templates and shared skill references from upstream.

## Scope

| Field | Value |
|---|---|
| Upstream | `upstream:` in `~/.almagest/config.yml` (default `itsmistermoon/almagest-antu`), ref `upstream_ref:` (default `main`) |
| Synced | `templates/*.md` → `{vault}/templates/` (per-vault); `references/*.md` → `~/.almagest/references/` (global — once per machine, not per-vault) |
| Never touched | `wiki/`, `.raw/`, `.hot/`, `AGENTS.md` |

`references/*.md` holds skill-internal documentation shared across multiple Antu skills (e.g. `VAULT-RESOLUTION.md`) — moved out of individual skill folders so each skill has one canonical copy to read instead of a duplicate each skill maintainer must keep in sync by hand. Global rather than per-vault because it's consulted by skill logic, not vault content.

## Procedure

1. One API call: `GET https://api.github.com/repos/{upstream}/git/trees/{upstream_ref}?recursive=1`, filtered to scope (both `templates/` and `references/` prefixes — one call covers both).
2. Fetch each matching file's raw content, diff against local (`templates/*.md` against `{vault}/templates/`, `references/*.md` against `~/.almagest/references/`). Skip identical files silently.
3. Collect differing/missing files into two lists, one per destination — never write per-diff.
4. Confirmation is per destination, not combined — writing to the vault and writing machine-global files are different-consent decisions:
   - **Templates list** (`{vault}/templates/`): empty → report "templates up to date". New vault (scaffolded in step 1) → write without asking, part of the scaffolding already confirmed. Existing vault → ask once: "Update {N} template(s) from {upstream}?"; write only on confirmation.
   - **References list** (`~/.almagest/references/`): empty → report "shared references up to date". Always ask once, new vault or not: "Update {N} shared reference file(s) from {upstream}? These are global and affect every vault on this machine, not just this one." Write only on confirmation; create `~/.almagest/references/` if it doesn't exist yet.
   - After both are resolved, return to whichever step called this procedure (the new-vault wizard continues to its next step, a maintenance-menu run continues to any other selected option).
5. Files present locally but gone upstream: report and ask per-file (or once for all) before deleting, per destination.

## Rate limits

60 unauthenticated GitHub API requests/hour; the tree fetch costs 1. Raw downloads aren't API-metered. `GITHUB_TOKEN` raises the API limit (`Authorization: Bearer {token}`, API calls only).
