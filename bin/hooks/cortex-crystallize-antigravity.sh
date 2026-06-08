#!/bin/bash
# Stop hook for Antigravity — snapshots session into .hot/{project}.md.
# Only fires when fullyIdle==true and terminationReason=="model_stop".

set -uo pipefail

PAYLOAD=$(cat 2>/dev/null || echo "{}")
FULLY_IDLE=$(printf '%s' "$PAYLOAD" | jq -r '.fullyIdle // false' 2>/dev/null)
TERMINATION=$(printf '%s' "$PAYLOAD" | jq -r '.terminationReason // ""' 2>/dev/null)

if [ "$FULLY_IDLE" != "true" ] || [ "$TERMINATION" != "model_stop" ]; then
  echo '{"decision":""}'; exit 0
fi

WORKSPACE=$(printf '%s' "$PAYLOAD" | jq -r '.workspacePaths[0] // empty' 2>/dev/null)
TRANSCRIPT=$(printf '%s' "$PAYLOAD" | jq -r '.transcriptPath // empty' 2>/dev/null)

find_git_root_dir() {
  local dir="${WORKSPACE:-$PWD}"
  while [ "$dir" != "/" ]; do
    [ -d "$dir/.git" ] && echo "$dir" && return 0
    dir="$(dirname "$dir")"
  done
  echo "${WORKSPACE:-$PWD}"
}

GIT_ROOT=$(find_git_root_dir)
PROJECT=$(basename "$GIT_ROOT")

[ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ] && echo '{"decision":""}' && exit 0

mkdir -p "$GIT_ROOT/.hot" 2>/dev/null || { echo '{"decision":""}'; exit 0; }

if ! grep -qF '.hot/' "$GIT_ROOT/.gitignore" 2>/dev/null; then
  echo '.hot/' >> "$GIT_ROOT/.gitignore"
fi

NOW=$(date '+%Y-%m-%d %H:%M %Z')
HOT_FILE="$GIT_ROOT/.hot/$PROJECT.md"
TMP=$(mktemp -t hot-cache.XXXXXX) || { echo '{"decision":""}'; exit 0; }
trap 'rm -f "$TMP"' EXIT

# ── Extract existing Zone 1 (frontmatter + Current state) ────────────────────
if [ -f "$HOT_FILE" ]; then
  CURRENT_STATE=$(awk '
    /^---$/ { buf = buf "---\n"; next }
    /^## History$/ { gsub(/---\n[[:space:]]*$/, "", buf); printf "%s", buf; exit }
    { buf = buf $0 "\n" }
    END { printf "%s", buf }
  ' "$HOT_FILE")
  PREV_HISTORY=$(awk '/^## History$/{found=1; next} found{print}' "$HOT_FILE")

  # Guard against duplicate Current state blocks
  DASH_COUNT=$(printf '%s\n' "$CURRENT_STATE" | grep -c '^---$' 2>/dev/null || echo 0)
  if [ "$DASH_COUNT" -gt 2 ]; then
    CURRENT_STATE=$(printf '%s\n' "$CURRENT_STATE" | awk '/^---$/{n++; if(n==3) exit} {print}')
  fi
else
  CURRENT_STATE="## Current state"
  PREV_HISTORY=""
fi

# ── Build synthesis prompt ───────────────────────────────────────────────────
# Antigravity tool names differ from Claude Code
TOOL_CALL_COUNT=$(jq -r '
  select(.type=="assistant")
  | .message.content[]?
  | select(.type=="tool_use")
  | .name
' "$TRANSCRIPT" 2>/dev/null | wc -l | tr -d ' ')

[ "$TOOL_CALL_COUNT" -eq 0 ] && echo '{"decision":""}' && exit 0

USER_MSGS=$(jq -r '
  select(.type=="user")
  | .message.content[]?
  | select(.type=="text")
  | .text
' "$TRANSCRIPT" 2>/dev/null | grep -v '^<' | grep -v '^$' | head -40)

TOOL_CALLS=$(jq -r '
  select(.type=="assistant")
  | .message.content[]?
  | select(.type=="tool_use")
  | "- " + .name + ": " + (
      (.input.TargetFile // .input.command // (.input | tostring))
      | .[0:120]
    )
' "$TRANSCRIPT" 2>/dev/null | head -50)

LAST_REPLY=$(jq -r '
  select(.type=="assistant")
  | .message.content[]?
  | select(.type=="text")
  | .text
' "$TRANSCRIPT" 2>/dev/null | tail -3)

FULL_PROMPT="Analyze this Antigravity CLI session and generate a structured summary in English.

== USER REQUESTS ==
$USER_MSGS

== TOOLS USED ==
$TOOL_CALLS

== LAST ASSISTANT MESSAGE ==
$LAST_REPLY

Generate EXACTLY this markdown block (no extra text before or after).
Omit sections with no real content entirely — never use placeholders.

#### What was done
[2-4 bullets: what was done and why — real context, not just file names]

#### Discarded
[only if something was explicitly discarded — omit if not applicable]

#### Fragile context
[only if there are implicit decisions or context that would be lost between sessions — omit if not applicable]"

SUMMARY=$(agy -p "$FULL_PROMPT" 2>/dev/null)
[ -z "$SUMMARY" ] && echo '{"decision":""}' && exit 0

# ── Write hot file ────────────────────────────────────────────────────────────
{
  printf '%s\n' "$CURRENT_STATE"
  echo ""
  echo "---"
  echo ""
  echo "## History"
  echo ""
  echo "### $NOW — Antigravity (Stop)"
  echo ""
  printf '%s\n' "$SUMMARY"
  if [ -n "$PREV_HISTORY" ]; then
    echo ""
    printf '%s\n' "$PREV_HISTORY"
  fi
} > "$TMP"

mv "$TMP" "$HOT_FILE"
echo '{"decision":""}'; exit 0
