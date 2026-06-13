#!/bin/bash
# Stop hook for CommandCode: snapshots session context to .hot/MEMORY.md
# CommandCode wire format: nested hooks array, stdin JSON with session/env context.
# Exit 0 on success, no JSON output needed for normal session close.
#
# Installed via settings.local.json (project scope) or settings.json (user scope).
# Deployment: copy this script to the active vault's bin/hooks/ and reference it.

set -uo pipefail

# ── Parse stdin (CommandCode hook payload) ──────────────────────────────────
PAYLOAD=$(cat 2>/dev/null || echo "{}")
CWD=$(printf '%s' "$PAYLOAD" | jq -r '.cwd // empty' 2>/dev/null)

# ── Find git root ───────────────────────────────────────────────────────────
find_git_root_dir() {
  local dir="${CWD:-$PWD}"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.git" ]; then echo "$dir"; return 0; fi
    dir="$(dirname "$dir")"
  done
  echo "${CWD:-$PWD}"
}

GIT_ROOT=$(find_git_root_dir)
mkdir -p "$GIT_ROOT/.hot" 2>/dev/null || exit 0

if ! grep -qF '.hot/' "$GIT_ROOT/.gitignore" 2>/dev/null; then
  echo '.hot/' >> "$GIT_ROOT/.gitignore"
fi

# ── Read existing MEMORY.md ─────────────────────────────────────────────────
NOW=$(date '+%Y-%m-%d %H:%M %Z')
HOT_FILE="$GIT_ROOT/.hot/MEMORY.md"
TMP=$(mktemp -t hot-cache.XXXXXX) || exit 0
trap 'rm -f "$TMP"' EXIT

if [ -f "$HOT_FILE" ]; then
  # Zone 1: everything before ## History (frontmatter + Current state)
  CURRENT_STATE=$(awk '
    /^---$/ { buf = buf "---\n"; next }
    /^## History$/ { gsub(/---\n[[:space:]]*$/, "", buf); printf "%s", buf; exit }
    { buf = buf $0 "\n" }
    END { printf "%s", buf }
  ' "$HOT_FILE")
  # Zone 2: everything after ## History
  PREV_HISTORY=$(awk '/^## History$/{found=1; next} found{print}' "$HOT_FILE")

  # Guard: remove duplicate frontmatter blocks
  DASH_COUNT=$(printf '%s\n' "$CURRENT_STATE" | awk '/^---$/{n++} END { print n + 0 }')
  if [ "$DASH_COUNT" -gt 2 ]; then
    CURRENT_STATE=$(printf '%s\n' "$CURRENT_STATE" | awk '/^---$/{n++; if(n==3) exit} {print}')
  fi

else
  CURRENT_STATE="## Current state"
  PREV_HISTORY=""
fi

# ── Write snapshot ──────────────────────────────────────────────────────────
{
  printf '%s\n' "$CURRENT_STATE"
  echo ""
  echo "---"
  echo ""
  echo "## History"
  echo ""
  echo "### $NOW — CommandCode (Stop)"
  echo ""
  echo "Session closed via Stop hook."
  if [ -n "$PREV_HISTORY" ]; then
    echo ""
    printf '%s\n' "$PREV_HISTORY"
  fi
} > "$TMP"

mv "$TMP" "$HOT_FILE"
exit 0
