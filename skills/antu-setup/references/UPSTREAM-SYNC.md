# Upstream sync

Reference for `antu-setup` (step 3b, maintenance menu option 2). Pulls updated templates and shared skill references from upstream.

## Scope

| Field | Value |
|---|---|
| Upstream | `upstream:` in `~/.cortex-forge/config.yml` (default `itsmistermoon/cortex-forge`), ref `upstream_ref:` (default `main`) |
| Synced | `templates/*.md` → `{vault}/templates/` (per-vault); `references/*.md` → `~/.cortex-forge/references/` (global — once per machine, not per-vault) |
| Never touched | `wiki/`, `.raw/`, `.hot/`, `AGENTS.md` |

`references/*.md` holds skill-internal documentation shared across multiple Antu skills (e.g. `VAULT-RESOLUTION.md`) — moved out of individual skill folders so each skill has one canonical copy to read instead of a duplicate each skill maintainer must keep in sync by hand. Global rather than per-vault because it's consulted by skill logic, not vault content.

## Procedure

1. One API call: `GET https://api.github.com/repos/{upstream}/git/trees/{upstream_ref}?recursive=1`, filtered to scope (both `templates/` and `references/` prefixes — one call covers both).
2. Fetch each matching file's raw content, diff against local (`templates/*.md` against `{vault}/templates/`, `references/*.md` against `~/.cortex-forge/references/`). Skip identical files silently.
3. Collect all differing/missing files into one list, grouped by destination — never write per-diff.
4. Empty list → report "templates and shared references up to date", stop this procedure (return to whichever step called it — the new-vault wizard continues to its next step, a maintenance-menu run continues to any other selected option). Otherwise show the list and ask once: "Update {N} file(s) from {upstream}?" Write only on confirmation; on decline, write nothing. Create `~/.cortex-forge/references/` if it doesn't exist yet.
5. Files present locally but gone upstream: report and ask per-file (or once for all) before deleting.

## Rate limits

60 unauthenticated GitHub API requests/hour; the tree fetch costs 1. Raw downloads aren't API-metered. `GITHUB_TOKEN` raises the API limit (`Authorization: Bearer {token}`, API calls only).
