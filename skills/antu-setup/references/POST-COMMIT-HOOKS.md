# Post-commit hooks

Reference for `antu-setup` (step 5a to install, maintenance menu options 6/7; maintenance menu option 9 to uninstall). Plain git hooks, not agent lifecycle hooks — identical across agents. Both backgrounded or fail-open: never block a commit.

## Shared mechanics

- If `git config core.hooksPath` is set (husky-style), install there instead of `.git/hooks/`, or warn and skip.
- Append a marked block to `{vault}/.git/hooks/post-commit` (create with shebang if missing; never touch content outside the skill's own `>>> ... <<<` block), make executable.
- Uninstall (deregister path): remove only the marked block — diff against the pre-install file must be empty.
- Hooks run outside any agent session, so skill-relative script resolution doesn't apply; both hooks stage their scripts once into `~/.cortex-forge/bin/` at a fixed absolute path.

## Prune hook

Ask: "Refresh vault-report.json automatically after each commit? (optional)"

If yes: copy `../antu-prune/scripts/antu-prune.sh` (relative to this skill) to `~/.cortex-forge/bin/antu-prune.sh` — skip if identical; if not found, tell the user `antu-prune` isn't installed and skip. Install:

```bash
# >>> antu prune >>>
if [ -f ~/.cortex-forge/bin/antu-prune.sh ]; then
  (
    bash ~/.cortex-forge/bin/antu-prune.sh >/dev/null 2>&1 || true
    R="wiki/meta/vault-report.json"
    if [ -f "$R" ] && command -v jq >/dev/null 2>&1; then
      n=$(jq '[.health[] | length] | add' "$R" 2>/dev/null || echo "?")
      echo "$(date '+%F %T') antu-prune: report refreshed, findings=$n" >> .git/antu-prune.log
    fi
  ) &
fi
# <<< antu prune <<<
```

Backgrounded; logs a summary line to `.git/antu-prune.log` each run.

## Reindex hook

Ask: "Re-index vault embeddings automatically after each commit? (recommended if semantic search is enabled)"

If yes:
1. If `.cortex/db/vault.db` doesn't exist, run step 5's dependency-check-then-offer procedure first (don't skip silently) — the case when reached directly via maintenance menu option 7.
2. Copy `scripts/antu-reindex-post-commit.sh`, `scripts/antu-index.py`, `scripts/embeddings.py` to `~/.cortex-forge/bin/` (and `bin/hooks/` for the first) if missing or different.
3. Install:

```bash
# >>> antu reindex >>>
bash ~/.cortex-forge/bin/hooks/antu-reindex-post-commit.sh
# <<< antu reindex <<<
```

The hook self-gates (exits if `vault.db` or `antu-index.py` are missing, or the commit didn't touch `wiki/`), runs backgrounded, logs to `.git/antu-reindex.log`.
