#!/bin/bash
# Stop hook for Antigravity — snapshots session into .cortex/MEMORY.md.
# Runs after every model turn.

set -uo pipefail

# Derive context directly from Antigravity's history
HISTORY_FILE="$HOME/.gemini/antigravity-cli/history.jsonl"
LATEST_ENTRY=$(tail -n 1 "$HISTORY_FILE" 2>/dev/null || echo "{}")
WORKSPACE=$(printf '%s' "$LATEST_ENTRY" | jq -r '.workspace // empty' 2>/dev/null)
CONV_ID=$(printf '%s' "$LATEST_ENTRY" | jq -r '.conversationId // empty' 2>/dev/null)

[ -z "$WORKSPACE" ] && WORKSPACE="$PWD"

find_git_root_dir() {
  local dir="${WORKSPACE}"
  while [ "$dir" != "/" ]; do
    [ -d "$dir/.git" ] && echo "$dir" && return 0
    dir="$(dirname "$dir")"
  done
  echo "${WORKSPACE}"
}

GIT_ROOT=$(find_git_root_dir)

mkdir -p "$GIT_ROOT/.hot" 2>/dev/null || exit 0
if ! grep -qF '.cortex/' "$GIT_ROOT/.gitignore" 2>/dev/null; then
  echo '.cortex/' >> "$GIT_ROOT/.gitignore"
fi

NOW=$(date '+%Y-%m-%d %H:%M %Z')
HOT_FILE="$GIT_ROOT/.cortex/MEMORY.md"
SENTINEL="__PENDING_SYNTHESIS_${NOW// /_}__"

# Helper check
AGY="agy"
if [ -x "/opt/homebrew/bin/agy" ]; then
  AGY="/opt/homebrew/bin/agy"
fi

# Extract existing Zone 1 (frontmatter + Current state)
TMP=$(mktemp -t hot-cache.XXXXXX) || exit 0

if [ -f "$HOT_FILE" ]; then
  CURRENT_STATE=$(awk '
    /^---$/ { buf = buf "---\n"; next }
    /^## History$/ { gsub(/---\n[[:space:]]*$/, "", buf); printf "%s", buf; exit }
    { buf = buf $0 "\n" }
    END { printf "%s", buf }
  ' "$HOT_FILE")
  PREV_HISTORY=$(awk '/^## History$/{found=1; next} found{print}' "$HOT_FILE")

  DASH_COUNT=$(printf '%s\n' "$CURRENT_STATE" | awk '/^---$/{n++} END { print n + 0 }')
  if [ "$DASH_COUNT" -gt 2 ]; then
    CURRENT_STATE=$(printf '%s\n' "$CURRENT_STATE" | awk '/^---$/{n++; if(n==3) exit} {print}')
  fi
else
  CURRENT_STATE="## Current state"
  PREV_HISTORY=""
fi

# Extract session context
TOOL_SUMMARIES=""
USER_MSGS=""
TRANSCRIPT_FILE="$HOME/.gemini/antigravity-cli/brain/$CONV_ID/.system_generated/logs/transcript.jsonl"

if [ -f "$TRANSCRIPT_FILE" ]; then
  TOOL_SUMMARIES=$(grep -oE '"toolSummary":"[^"]*"' "$TRANSCRIPT_FILE" \
    | sed 's/"toolSummary":"//;s/"$//' \
    | sort -u \
    | head -30)
fi

if [ -f "$HISTORY_FILE" ] && [ -n "$CONV_ID" ]; then
  USER_MSGS=$(grep -F "$CONV_ID" "$HISTORY_FILE" \
    | grep -oE '"display":"[^"]*"' \
    | sed 's/"display":"//;s/"$//' \
    | head -20)
fi

# Only proceed if we have tool summaries (meaning actual work was done)
[ -z "$TOOL_SUMMARIES" ] && exit 0

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

# Write the placeholder state
{
  printf '%s\n' "$CURRENT_STATE"
  echo ""
  echo "---"
  echo ""
  echo "## History"
  echo ""
  echo "### $NOW — Antigravity (Stop)"
  echo ""
  echo "$SENTINEL"
  if [ -n "$PREV_HISTORY" ]; then
    echo ""
    printf '%s\n' "$PREV_HISTORY"
  fi
} > "$TMP"

mv "$TMP" "$HOT_FILE"

# Prepare background helper script
HELPER="$GIT_ROOT/.cortex/.synthesize-$(date +%Y-%m-%d-%H%M).sh"

HOT_FILE_ESC=$(printf '%s' "$HOT_FILE" | sed "s/'/'\\\\''/g")
SENTINEL_ESC=$(printf '%s' "$SENTINEL" | sed "s/'/'\\\\''/g")
FULL_PROMPT_ESC=$(printf '%s' "$FULL_PROMPT" | sed "s/'/'\\\\''/g")
AGY_ESC=$(printf '%s' "$AGY" | sed "s/'/'\\\\''/g")
TRANSCRIPT_ESC=$(printf '%s' "$TRANSCRIPT_FILE" | sed "s/'/'\\\\''/g")

cat > "$HELPER" <<HEREDOC
#!/bin/bash
HOT_FILE='$HOT_FILE_ESC'
SENTINEL='$SENTINEL_ESC'
FULL_PROMPT='$FULL_PROMPT_ESC'
AGY='$AGY_ESC'
TRANSCRIPT='$TRANSCRIPT_ESC'

SUMMARY=\$( "\$AGY" --model "gemini-3.5-flash" -p "\$FULL_PROMPT" 2>/dev/null )
case "\$SUMMARY" in
  *"#### What was done"*) ;;
  *) rm -f "\$0"; exit 0 ;;
esac

if [ -f "\$HOT_FILE" ] && grep -qF "\$SENTINEL" "\$HOT_FILE"; then
  TMP2=\$(mktemp -t hot-cache-bg.XXXXXX) || exit 0
  awk -v sentinel="\$SENTINEL" -v summary="\$SUMMARY" '
    { if (index(\$0, sentinel)) { printf "%s\n", summary; next } print }
  ' "\$HOT_FILE" > "\$TMP2" && mv "\$TMP2" "\$HOT_FILE"
fi
rm -f "\$0"
HEREDOC

chmod +x "$HELPER"

# Launch helper in background
nohup "$HELPER" </dev/null >/dev/null 2>&1 &
disown 2>/dev/null || true
exit 0
