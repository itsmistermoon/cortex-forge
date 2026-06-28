#!/usr/bin/env bash
# Post-commit hook: re-index vault embeddings when wiki/ files change.
# Install: ln -sf ~/.cortex-forge/bin/hooks/cortex-reindex-post-commit.sh \
#          <vault>/.git/hooks/post-commit
set -euo pipefail

VAULT_ROOT="$(git rev-parse --show-toplevel)"
DB="$VAULT_ROOT/.cortex/db/vault.db"
INDEXER="$VAULT_ROOT/bin/cortex-index.py"

# Only run if semantic search is enabled for this vault
[[ -f "$DB" && -f "$INDEXER" ]] || exit 0

# Only run if the commit touched wiki/ files
CHANGED=$(git diff-tree --no-commit-id -r --name-only HEAD | grep -c '^wiki/' || true)
[[ "$CHANGED" -gt 0 ]] || exit 0

echo "[cortex-forge] Re-indexing $CHANGED changed wiki file(s)..."
python "$INDEXER" "$VAULT_ROOT"
