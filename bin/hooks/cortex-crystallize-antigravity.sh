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

resolve_locale() {
  local git_root="$1"
  local config="$HOME/.cortex-forge/config.yml"
  local locale=""
  if [ -f "$config" ]; then
    locale=$(awk -v root="$git_root" '
      /^    path:/ { p = $2 }
      /^    locale:/ && p == root { print $2; exit }
    ' "$config" 2>/dev/null)
  fi
  if [ -z "$locale" ] && [ -f "$git_root/.hot/MEMORY.md" ]; then
    locale=$(grep -m1 '— locale:' "$git_root/.hot/MEMORY.md" | sed 's/.*locale: *//' | tr -d ' \r\n' 2>/dev/null)
  fi
  if [ -z "$locale" ] && [ -f "$git_root/CODEX.md" ]; then
    locale=$(grep -m1 '\*\*locale\*\*:' "$git_root/CODEX.md" | awk '{print $2}' 2>/dev/null)
  fi
  echo "${locale:-en}"
}

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

  DASH_COUNT=$(printf '%s\n' "$CURRENT_STATE" | awk '/^---$/{n++} END { print n + 0 }')
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

LOCALE=$(resolve_locale "$GIT_ROOT")
case "$LOCALE" in
  es) LANG_LABEL="Spanish (Chilean)" ;;
  fr) LANG_LABEL="French" ;;
  *)  LANG_LABEL="English" ;;
esac

# ── Build synthesis prompt ───────────────────────────────────────────────────
FULL_PROMPT="Analyze this Antigravity CLI session and generate a structured summary in $LANG_LABEL.
NOTE: End-of-session snapshot — definitive handoff (no return path). The session ends after this.

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
[only if there are implicit decisions or context that would be lost between sessions — omit if not applicable]

#### Attempted and failed
[only if an approach was tried and failed — omit if not applicable]

#### Imprint candidate
[only if the session produced a durable insight, design decision, or analysis worth a permanent wiki page — omit if not applicable. One line: what to imprint and suggested type (concept/entity/reference/page)]"

AGY="agy"
if [ -x "/opt/homebrew/bin/agy" ]; then
  AGY="/opt/homebrew/bin/agy"
fi
SUMMARY=$("$AGY" -p "$FULL_PROMPT" 2>/dev/null)
[ -z "$SUMMARY" ] && echo '{"decision":""}' && exit 0

case "$SUMMARY" in
  *"#### What was done"*) ;;
  *) echo '{"decision":""}'; exit 0 ;;
esac

if ! printf '%s\n' "$SUMMARY" | grep -qE '^- '; then
  echo '{"decision":""}'; exit 0
fi

# Append transcript path to the imprint candidate bullet so SessionStart can locate it
if printf '%s\n' "$SUMMARY" | grep -q "^#### Imprint candidate$" && [ -n "$TRANSCRIPT" ]; then
  SUMMARY=$(printf '%s\n' "$SUMMARY" | awk -v tp="$TRANSCRIPT" '
    /^#### Imprint candidate$/ { print; in_candidate=1; next }
    in_candidate && /^- / { print $0 " — transcript: " tp; in_candidate=0; next }
    in_candidate && /^####/ { in_candidate=0 }
    { print }
  ')
fi

# Archive history entries older than 30 days to CONSOLIDATED.md
CONSOLIDATED="$GIT_ROOT/.hot/CONSOLIDATED.md"
CUTOFF=$(date -v-30d '+%Y-%m-%d' 2>/dev/null || date -d '30 days ago' '+%Y-%m-%d' 2>/dev/null || echo "")

RECENT_HISTORY="$PREV_HISTORY"
if [ -n "$PREV_HISTORY" ] && [ -n "$CUTOFF" ]; then
  RECENT_TMP=$(mktemp -t cortex-recent.XXXXXX)
  ARCHIVE_TMP=$(mktemp -t cortex-archive.XXXXXX)
  trap 'rm -f "$TMP" "$RECENT_TMP" "$ARCHIVE_TMP"' EXIT

  printf '%s\n' "$PREV_HISTORY" | awk -v cutoff="$CUTOFF" -v recent="$RECENT_TMP" -v archive="$ARCHIVE_TMP" '
    /^### [0-9]{4}-[0-9]{2}-[0-9]{2}/ {
      if (buf != "") {
        dest = (entry_date < cutoff) ? archive : recent
        printf "%s", buf > dest
      }
      entry_date = $2
      buf = $0 "\n"
      next
    }
    { buf = buf $0 "\n" }
    END {
      if (buf != "") {
        dest = (entry_date < cutoff) ? archive : recent
        printf "%s", buf > dest
      }
    }
  '

  RECENT_HISTORY=$(cat "$RECENT_TMP" 2>/dev/null || true)
  ARCHIVED=$(cat "$ARCHIVE_TMP" 2>/dev/null || true)

  if [ -n "$ARCHIVED" ]; then
    printf '%s\n' "$ARCHIVED" >> "$CONSOLIDATED"
  fi
fi

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
  if [ -n "$RECENT_HISTORY" ]; then
    echo ""
    printf '%s\n' "$RECENT_HISTORY"
  fi
} > "$TMP"

mv "$TMP" "$HOT_FILE"
echo '{"decision":""}'; exit 0
