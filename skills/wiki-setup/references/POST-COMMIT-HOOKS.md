# Post-commit hooks

Reference for `wiki-setup` (step 5a to install, maintenance menu options 6/7; maintenance menu option 9 to uninstall). Plain git hooks, not agent lifecycle hooks — identical across agents. Both backgrounded or fail-open: never block a commit.

## Shared mechanics

- If `git config core.hooksPath` is set (husky-style), install there instead of `.git/hooks/`, or warn and skip.
- Append a marked block to `{vault}/.git/hooks/post-commit` (create with shebang if missing; never touch content outside the skill's own `>>> ... <<<` block), make executable.
- Uninstall (deregister path): remove only the marked block — diff against the pre-install file must be empty.
- Hooks run outside any agent session, so skill-relative script resolution doesn't apply; both hooks stage their scripts once into `~/.almagest/bin/` at a fixed absolute path.

## Prune hook

Ask: "Refresh vault-report.json automatically after each commit? (optional)"

If yes: copy `../wiki-lint/scripts/lint.sh` (relative to this skill) to `~/.almagest/bin/lint.sh` — skip if identical; if not found, tell the user `wiki-lint` isn't installed and skip. Install:

```bash
# >>> antu prune >>>
if [ -f ~/.almagest/bin/lint.sh ]; then
  (
    bash ~/.almagest/bin/lint.sh >/dev/null 2>&1 || true
    R="meta/vault-report.json"
    if [ -f "$R" ] && command -v jq >/dev/null 2>&1; then
      n=$(jq '[.health[] | length] | add' "$R" 2>/dev/null || echo "?")
      echo "$(date '+%F %T') wiki-lint: report refreshed, findings=$n" >> .git/wiki-lint.log
    fi
  ) &
fi
# <<< antu prune <<<
```

Backgrounded; logs a summary line to `.git/wiki-lint.log` each run.

## Reindex hook

Ask: "Re-index vault embeddings automatically after each commit? (recommended if semantic search is enabled)"

If yes:
1. If `.hot/db/vault.db` doesn't exist, run step 5's dependency-check-then-offer procedure first (don't skip silently) — the case when reached directly via maintenance menu option 7.
2. Copy `scripts/reindex-post-commit.sh`, `scripts/index.py`, `scripts/embeddings.py` to `~/.almagest/bin/` (and `bin/hooks/` for the first) if missing or different.
3. Install:

```bash
# >>> antu reindex >>>
bash ~/.almagest/bin/hooks/reindex-post-commit.sh
# <<< antu reindex <<<
```

The hook self-gates (exits if `vault.db` or `index.py` are missing, or the commit didn't touch `wiki/`), runs backgrounded, logs to `.git/antu-reindex.log`.
