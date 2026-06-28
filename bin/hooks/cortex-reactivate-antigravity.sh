#!/bin/bash
# PreInvocation hook for Antigravity — injects .hot/{project}.md on invocationNum==0.
# Detects the active project from workspace path.

set -uo pipefail

PAYLOAD=$(cat 2>/dev/null || echo "{}")
INVOCATION_NUM=$(printf '%s' "$PAYLOAD" | jq -r '.invocationNum // 1' 2>/dev/null)

[ "$INVOCATION_NUM" != "0" ] && echo '{"injectSteps":[]}' && exit 0

WORKSPACE=$(printf '%s' "$PAYLOAD" | jq -r '.workspacePaths[0] // empty' 2>/dev/null)

find_git_root_dir() {
  local dir="${WORKSPACE:-$PWD}"
  while [ "$dir" != "/" ]; do
    [ -d "$dir/.git" ] && echo "$dir" && return 0
    dir="$(dirname "$dir")"
  done
  echo "${WORKSPACE:-$PWD}"
}

GIT_ROOT=$(find_git_root_dir)
HOT="$GIT_ROOT/.cortex/MEMORY.md"

[ ! -s "$HOT" ] && echo '{"injectSteps":[]}' && exit 0

# Resolve imprint_triage: per-vault overrides global; backwards compat true→suggest false→off
CONFIG="$HOME/.cortex-forge/config.yml"
VAULT_PATH=$(awk -v root="$GIT_ROOT" '
  /^    path:/ { p = $2 }
  /^    imprint_triage:/ && p == root { print $2; exit }
' "$CONFIG" 2>/dev/null)
IMPRINT_TRIAGE="${VAULT_PATH:-$(grep -m1 '^imprint_triage:' "$CONFIG" 2>/dev/null | awk '{print $2}')}"
# Backwards compat
case "$IMPRINT_TRIAGE" in
  true)  IMPRINT_TRIAGE="suggest" ;;
  false) IMPRINT_TRIAGE="off"     ;;
  "")    IMPRINT_TRIAGE="suggest" ;;
esac

ENTRY_DATE=$(awk '
  /^## History$/ { in_hist=1; next }
  in_hist && /^### [0-9]{4}-[0-9]{2}-[0-9]{2}/ { print $2; exit }
' "$HOT" 2>/dev/null)

# Fallback to CONSOLIDATED.md if History in MEMORY.md is empty (all entries archived)
if [ -z "$ENTRY_DATE" ] && [ -f "$GIT_ROOT/.cortex/CONSOLIDATED.md" ]; then
  ENTRY_DATE=$(awk '
    /^### [0-9]{4}-[0-9]{2}-[0-9]{2}/ { last_date = $2 }
    END { print last_date }
  ' "$GIT_ROOT/.cortex/CONSOLIDATED.md" 2>/dev/null)
fi

DIFF_DAYS=0
if [ -n "$ENTRY_DATE" ]; then
  ENTRY_TS=$(date -j -f "%Y-%m-%d" "$ENTRY_DATE" "+%s" 2>/dev/null || date -d "$ENTRY_DATE" "+%s" 2>/dev/null || echo 0)
  NOW_TS=$(date "+%s")
  DIFF_DAYS=$(( (NOW_TS - ENTRY_TS) / 86400 ))
fi

# Resolve hot cache stale threshold
STALE_DAYS_LIMIT=$(awk -v root="$GIT_ROOT" '
  /^    path:/ { p = $2 }
  /^    hot_cache_stale_days:/ && p == root { print $2; exit }
' "$CONFIG" 2>/dev/null)
STALE_DAYS_LIMIT="${STALE_DAYS_LIMIT:-$(grep -m1 '^hot_cache_stale_days:' "$CONFIG" 2>/dev/null | awk '{print $2}')}"
STALE_DAYS_LIMIT="${STALE_DAYS_LIMIT:-7}"

STALE_WARNING=""
if [ -n "$ENTRY_DATE" ] && [ "$DIFF_DAYS" -gt "$STALE_DAYS_LIMIT" ]; then
  STALE_WARNING="⚠ WARNING: The hot cache session memory has not been updated in $DIFF_DAYS days (threshold is $STALE_DAYS_LIMIT days). The project state might be stale or out of sync. Please verify current status with the user.

---

"
fi

NUDGE=""
if [ "$IMPRINT_TRIAGE" != "off" ] && [ -n "$ENTRY_DATE" ] && [ "$DIFF_DAYS" -le 30 ]; then
  # Extract candidate line from the most recent history entry
  CANDIDATE=$(awk '
    /^## History$/ { in_hist=1; next }
    in_hist && /^### / { if (++entry_count == 2) exit; next }
    in_hist && entry_count == 1 && /^#### Imprint candidate$/ { found=1; next }
    found && /^- / { print; exit }
    found && /^####/ { exit }
  ' "$HOT" 2>/dev/null)

  if [ -n "$CANDIDATE" ]; then
    # Extract transcript path and clean description
    TRANSCRIPT_PATH=$(printf '%s' "$CANDIDATE" | grep -oE 'transcript: [^ ]+' | awk '{print $2}')
    CANDIDATE_TEXT=$(printf '%s' "$CANDIDATE" | sed 's/ — transcript:.*$//' | sed 's/^- //')

    # Write structured draft file
    DRAFT="$GIT_ROOT/.cortex/imprint-draft.md"
    cat > "$DRAFT" <<DRAFTEOF
---
candidate: $CANDIDATE_TEXT
transcript: $TRANSCRIPT_PATH
detected: $(date '+%Y-%m-%d')
mode: $IMPRINT_TRIAGE
---
DRAFTEOF

    if [ "$IMPRINT_TRIAGE" = "auto" ]; then
      NUDGE="⚠ IMPRINT CANDIDATE (auto mode): $CANDIDATE_TEXT
Draft saved to .cortex/imprint-draft.md. Run /cortex-imprint now — do not wait for user instruction. Confirm with the user only if the page type or title is ambiguous.

---

"
    else
      NUDGE="⚠ IMPRINT CANDIDATE from last session: $CANDIDATE_TEXT
Draft info saved to .cortex/imprint-draft.md. Run /cortex-imprint to archive it as a permanent wiki page before it's lost.

---

"
    fi
  fi
fi

# Skip YAML frontmatter (between first and second ---), read Zone 1 until ## History
HOT_ZONE_1=$(awk '
  /^---$/ { dashes++; next }
  dashes < 2 { next }
  /^## History$/ { exit }
  { print }
' "$HOT")

[ -z "$HOT_ZONE_1" ] && echo '{"injectSteps":[]}' && exit 0

CONTENT=$(printf '%s%s\n%s' "$STALE_WARNING" "$NUDGE" "$HOT_ZONE_1")
ESCAPED=$(printf '%s' "$CONTENT" | jq -Rs .)
printf '{"injectSteps":[{"ephemeralMessage":%s}]}\n' "$ESCAPED"
