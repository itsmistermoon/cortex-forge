# Upstream sync

Reference for `antu-setup` (step 3b, maintenance menu option 2). Pulls updated templates from upstream into the current vault.

## Scope

| Field | Value |
|---|---|
| Upstream | `upstream:` in `~/.cortex-forge/config.yml` (default `itsmistermoon/cortex-forge`), ref `upstream_ref:` (default `main`) |
| Synced | `templates/*.md` only |
| Never touched | `wiki/`, `.raw/`, `.cortex/`, `AGENTS.md` |

## Procedure

1. One API call: `GET https://api.github.com/repos/{upstream}/git/trees/{upstream_ref}?recursive=1`, filtered to scope.
2. Fetch each matching file's raw content, diff against local. Skip identical files silently.
3. Collect all differing/missing files into one list — never write per-diff.
4. Empty list → report "templates up to date", stop this procedure (return to whichever step called it — the new-vault wizard continues to its next step, a maintenance-menu run continues to any other selected option). Otherwise show the list and ask once: "Update {N} template(s) from {upstream}?" Write only on confirmation; on decline, write nothing.
5. Files present locally but gone upstream: report and ask per-file (or once for all) before deleting.

## Rate limits

60 unauthenticated GitHub API requests/hour; the tree fetch costs 1. Raw downloads aren't API-metered. `GITHUB_TOKEN` raises the API limit (`Authorization: Bearer {token}`, API calls only).
