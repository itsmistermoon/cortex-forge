#!/usr/bin/env bash
# Post-commit hook: re-index vault embeddings when wiki/ files change.
# Install: ln -sf ~/.cortex-forge/bin/hooks/antu-reindex-post-commit.sh \
#          <vault>/.git/hooks/post-commit
set -euo pipefail

VAULT_ROOT="$(git rev-parse --show-toplevel)"
DB="$VAULT_ROOT/.cortex/db/vault.db"
# Runs the stable runtime copy at ~/.cortex-forge/bin/ — never a script from
# inside the vault. The vault is a data source (vault.db), never a code source.
INDEXER="${HOME}/.cortex-forge/bin/antu-index.py"
LOG="$VAULT_ROOT/.git/antu-reindex.log"

# Only run if semantic search is enabled for this vault
[[ -f "$DB" && -f "$INDEXER" ]] || exit 0

# Only run if the commit touched wiki/ files
CHANGED=$(git diff-tree --no-commit-id -r --name-only HEAD | grep -c '^wiki/' || true)
[[ "$CHANGED" -gt 0 ]] || exit 0

# macOS ships no `timeout` by default (GNU coreutils only); use it if present
# (Linux, or `brew install coreutils` → gtimeout on macOS), else run unwrapped —
# the real timeout protection lives in embeddings.py's Ollama call.
TIMEOUT_BIN=""
command -v timeout >/dev/null 2>&1 && TIMEOUT_BIN="timeout 300"
[ -z "$TIMEOUT_BIN" ] && command -v gtimeout >/dev/null 2>&1 && TIMEOUT_BIN="gtimeout 300"

(
  $TIMEOUT_BIN python3 -B "$INDEXER" "$VAULT_ROOT" \
    && echo "$(date '+%F %T') antu-reindex: ok, wiki_files=$CHANGED" >> "$LOG" \
    || {
      code=$?
      if [ -n "$TIMEOUT_BIN" ] && [ "$code" -eq 124 ]; then
        echo "$(date '+%F %T') antu-reindex: TIMED OUT after 300s, wiki_files=$CHANGED" >> "$LOG"
      else
        echo "$(date '+%F %T') antu-reindex: error (exit $code), wiki_files=$CHANGED" >> "$LOG"
      fi
    }
) &
