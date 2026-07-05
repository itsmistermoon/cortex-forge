# Post-commit hooks

Reference for `cortex-forge-setup` (steps 5b/5c, maintenance menu options 4/5). Plain git hooks, not agent lifecycle hooks — identical across agents. Both backgrounded or fail-open: never block a commit.

## Shared mechanics

- If `git config core.hooksPath` is set (husky-style), install there instead of `.git/hooks/`, or warn and skip.
- Append a marked block to `{vault}/.git/hooks/post-commit` (create with shebang if missing; never touch content outside the skill's own `>>> ... <<<` block), make executable.
- Uninstall (deregister path): remove only the marked block — diff against the pre-install file must be empty.
- Hooks run outside any agent session, so skill-relative script resolution doesn't apply; both hooks stage their scripts once into `~/.cortex-forge/bin/` at a fixed absolute path.

## Prune hook (step 5b)

Ask: "Refresh vault-report.json automatically after each commit? (optional)"

If yes: copy `../cortex-prune/scripts/cortex-prune.sh` (relative to this skill) to `~/.cortex-forge/bin/cortex-prune.sh` — skip if identical; if not found, tell the user `cortex-prune` isn't installed and skip. Install:

```bash
# >>> cortex-forge prune >>>
if [ -f ~/.cortex-forge/bin/cortex-prune.sh ]; then
  (
    bash ~/.cortex-forge/bin/cortex-prune.sh >/dev/null 2>&1 || true
    R="wiki/meta/vault-report.json"
    if [ -f "$R" ] && command -v jq >/dev/null 2>&1; then
      n=$(jq '[.health[] | length] | add' "$R" 2>/dev/null || echo "?")
      echo "$(date '+%F %T') cortex-prune: report refreshed, findings=$n" >> .git/cortex-prune.log
    fi
  ) &
fi
# <<< cortex-forge prune <<<
```

Backgrounded; logs a summary line to `.git/cortex-prune.log` each run.

## Reindex hook (step 5c)

Ask: "Re-index vault embeddings automatically after each commit? (recommended if semantic search is enabled)"

If yes:
1. If `.cortex/db/vault.db` doesn't exist, run step 5's dependency-check-then-offer procedure first (don't skip silently) — the case when reached directly via maintenance menu option 5.
2. Copy `scripts/cortex-reindex-post-commit.sh`, `scripts/cortex-index.py`, `scripts/embeddings.py` (co-located with this skill) to `~/.cortex-forge/bin/` (and `bin/hooks/` for the first) if missing or different.
3. Install:

```bash
# >>> cortex-forge reindex >>>
bash ~/.cortex-forge/bin/hooks/cortex-reindex-post-commit.sh
# <<< cortex-forge reindex <<<
```

The hook self-gates (exits if `vault.db` or `cortex-index.py` are missing, or the commit didn't touch `wiki/`), runs backgrounded, logs to `.git/cortex-reindex.log`.
