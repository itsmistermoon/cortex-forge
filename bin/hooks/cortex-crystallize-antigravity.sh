#!/bin/bash
# Stop hook for Antigravity — snapshots session into .hot/MEMORY.md.
# Only fires when fullyIdle==true and terminationReason=="model_stop".
# Antigravity stores transcripts as SQLite+Protobuf .db files — cannot parse
# with jq. Instead: user messages from history.jsonl, tool summaries via strings.

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

mkdir -p "$GIT_ROOT/.hot" 2>/dev/null || { echo '{"decision":""}'; exit 0; }

if ! grep -qF '.hot/' "$GIT_ROOT/.gitignore" 2>/dev/null; then
  echo '.hot/' >> "$GIT_ROOT/.gitignore"
fi

NOW=$(date '+%Y-%m-%d %H:%M %Z')
HOT_FILE="$GIT_ROOT/.hot/MEMORY.md"
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

  DASH_COUNT=$(printf '%s\n' "$CURRENT_STATE" | grep -c '^---$' 2>/dev/null || echo 0)
  if [ "$DASH_COUNT" -gt 2 ]; then
    CURRENT_STATE=$(printf '%s\n' "$CURRENT_STATE" | awk '/^---$/{n++; if(n==3) exit} {print}')
  fi
else
  CURRENT_STATE="## Current state"
  PREV_HISTORY=""
fi

# ── Extract session context from Antigravity's SQLite .db transcript ─────────
# Antigravity uses SQLite+Protobuf — jq cannot parse it.
# Strategy: tool summaries via `strings`, user messages via history.jsonl.

TOOL_SUMMARIES=""
USER_MSGS=""

if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  # Extract tool summaries embedded as JSON fragments in protobuf blobs
  TOOL_SUMMARIES=$(strings "$TRANSCRIPT" 2>/dev/null \
    | grep -oE '"toolSummary":"[^"]*"' \
    | sed 's/"toolSummary":"//;s/"$//' \
    | sort -u \
    | head -30)

  # Derive conversationId from db filename, then fetch user messages
  CONV_ID=$(basename "$TRANSCRIPT" .db)
  HISTORY_FILE="$HOME/.gemini/antigravity-cli/history.jsonl"
  if [ -f "$HISTORY_FILE" ] && [ -n "$CONV_ID" ]; then
    USER_MSGS=$(grep -F "$CONV_ID" "$HISTORY_FILE" \
      | grep -oE '"display":"[^"]*"' \
      | sed 's/"display":"//;s/"$//' \
      | head -20)
  fi
fi

# If no tool summaries found, the session had no real work — skip
[ -z "$TOOL_SUMMARIES" ] && echo '{"decision":""}' && exit 0

# ── Build synthesis prompt ───────────────────────────────────────────────────
FULL_PROMPT="Analyze this Antigravity CLI session and generate a structured summary in English.

== USER REQUESTS ==
$USER_MSGS

== TOOLS USED (summaries) ==
$TOOL_SUMMARIES

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
