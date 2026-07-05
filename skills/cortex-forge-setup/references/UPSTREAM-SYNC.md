# Upstream sync

Reference for `cortex-forge-setup` (step 3b, maintenance menu option 2). Pulls infrastructure files from upstream into the current vault.

## Scope

| | |
|---|---|
| Upstream | `upstream:` in `~/.cortex-forge/config.yml` (default `itsmistermoon/cortex-forge`), ref `upstream_ref:` (default `main`) |
| Synced | `templates/*.md` only |
| Never touched | `wiki/`, `.raw/`, `.cortex/`. `AGENTS.md`: never written, but structurally diffed (below) |

## Procedure

1. One API call: `GET https://api.github.com/repos/{upstream}/git/trees/main?recursive=1`, filtered to scope.
2. Fetch each matching file's raw content, diff against local. Skip identical files silently.
3. Collect all differing/missing files into one list — never write per-diff.
4. Empty list → report "templates up to date", stop. Otherwise show the list and ask once: "Update {N} template(s) from {upstream}?" Write only on confirmation; on decline, write nothing.
5. Files present locally but gone upstream: report and ask per-file (or once for all) before deleting.

## AGENTS.md structural check

Always runs. Compare `##`/`###` headings upstream vs local: report headings added upstream (consider adding) and local-only headings (safe to keep). Never diff body content.

## Rate limits

60 unauthenticated GitHub API requests/hour; the tree fetch costs 1. Raw downloads aren't API-metered. `GITHUB_TOKEN` raises the API limit (`Authorization: Bearer {token}`, API calls only).
