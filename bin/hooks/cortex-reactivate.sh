#!/bin/bash
# SessionStart hook: injects .hot/{project}.md as additional context.
# Detects the active project from CWD and reads from the active repo.

set -euo pipefail

find_git_root_dir() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.git" ]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  echo "$PWD"
}

GIT_ROOT=$(find_git_root_dir)
PROJECT=$(basename "$GIT_ROOT")
HOT="$GIT_ROOT/.hot/$PROJECT.md"

[ ! -s "$HOT" ] && exit 0

CONTENT=$(jq -Rs . < "$HOT")

cat <<EOF
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":$CONTENT}}
EOF
