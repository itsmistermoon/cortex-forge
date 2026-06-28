#!/bin/bash
# SessionEnd + PreCompact hook: snapshots de sesión en .cortex/MEMORY.md
# Ambos triggers usan claude -p para generar bullets descriptivos.
# SessionEnd  → handoff definitivo (no return path)
# PreCompact  → compactación mid-session (la sesión continúa)

set -uo pipefail

PAYLOAD=$(cat 2>/dev/null || echo "{}")
TRANSCRIPT_PATH=$(printf '%s' "$PAYLOAD" | jq -r '.transcript_path // empty' 2>/dev/null)
TRIGGER=$(printf '%s' "$PAYLOAD" | jq -r '.hook_event_name // "PreCompact"' 2>/dev/null)
CWD=$(printf '%s' "$PAYLOAD" | jq -r '.cwd // empty' 2>/dev/null)
AGENT_LABEL=${AGENT_LABEL:-Claude Code}
TRANSCRIPT_FALLBACK_DIRS=${TRANSCRIPT_FALLBACK_DIRS:-"$HOME/.claude/projects"}

find_git_root_dir() {
  local dir="${CWD:-$PWD}"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.git" ]; then echo "$dir"; return 0; fi
    dir="$(dirname "$dir")"
  done
  echo "${CWD:-$PWD}"
}

extract_current_state() {
  local file="$1"
  if [ ! -f "$file" ]; then
    printf '%s\n' "## Current state"
    return 0
  fi

  awk '
    BEGIN {
      in_state = 0
      saw_state = 0
      printed_any = 0
    }
    /^## History$/ { exit }
    /^## Current state$/ {
      saw_state = 1
      if (!printed_any) {
        print
        printed_any = 1
      }
      in_state = 1
      next
    }
    /^## / {
      if (!saw_state) {
        print "## Current state"
        printed_any = 1
        saw_state = 1
      }
      in_state = 1
      next
    }
    {
      if (!saw_state) {
        print "## Current state"
        printed_any = 1
        saw_state = 1
      }
      if (length($0) > 0) {
        print
        printed_any = 1
      }
    }
    END {
      if (!printed_any) print "## Current state"
    }
  ' "$file"
}

extract_previous_history() {
  local file="$1"
  [ -f "$file" ] || return 0
  awk '/^## History$/{found=1; next} found{print}' "$file"
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
  if [ -z "$locale" ] && [ -f "$git_root/.cortex/MEMORY.md" ]; then
    locale=$(grep -m1 '— locale:' "$git_root/.cortex/MEMORY.md" | sed 's/.*locale: *//' | tr -d ' \r\n' 2>/dev/null)
  fi
  if [ -z "$locale" ] && [ -f "$git_root/CODEX.md" ]; then
    locale=$(grep -m1 '\*\*locale\*\*:' "$git_root/CODEX.md" | awk '{print $2}' 2>/dev/null)
  fi
  echo "${locale:-en}"
}

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  IFS=':' read -r -a FALLBACK_DIRS <<< "$TRANSCRIPT_FALLBACK_DIRS"
  for dir in "${FALLBACK_DIRS[@]}"; do
    [ -d "$dir" ] || continue
    TRANSCRIPT_PATH=$(find "$dir" -type f -name '*.jsonl' -print 2>/dev/null | sort -r | head -1)
    [ -n "$TRANSCRIPT_PATH" ] && break
  done
fi
[ -z "$TRANSCRIPT_PATH" ] && exit 0
[ ! -f "$TRANSCRIPT_PATH" ] && exit 0

mkdir -p "$GIT_ROOT/.hot" 2>/dev/null || exit 0

if ! grep -qF '.cortex/' "$GIT_ROOT/.gitignore" 2>/dev/null; then
  echo '.cortex/' >> "$GIT_ROOT/.gitignore"
fi

NOW=$(date '+%Y-%m-%d %H:%M %Z')
HOT_FILE="$GIT_ROOT/.cortex/MEMORY.md"
TMP=$(mktemp -t hot-cache.XXXXXX) || exit 0
trap 'rm -f "$TMP"' EXIT

CURRENT_STATE=$(extract_current_state "$HOT_FILE")
PREV_HISTORY=$(extract_previous_history "$HOT_FILE")

TOOL_CALL_COUNT=$(jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | .name' "$TRANSCRIPT_PATH" 2>/dev/null | awk 'END { print NR + 0 }')
[ "$TOOL_CALL_COUNT" -eq 0 ] && exit 0

USER_MSGS=$(jq -r 'select(.type=="user") | .message.content[]? | select(.type=="text") | .text' "$TRANSCRIPT_PATH" 2>/dev/null \
  | grep -v '^<' | grep -v '^$' | head -40)

TOOL_CALLS=$(jq -r '
  select(.type=="assistant")
  | .message.content[]?
  | select(.type=="tool_use")
  | "- " + .name + ": " + ((.input.file_path // .input.command // (.input | tostring)) | .[0:120])
' "$TRANSCRIPT_PATH" 2>/dev/null | head -50)

LAST_REPLY=$(jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text' "$TRANSCRIPT_PATH" 2>/dev/null | tail -3)

LOCALE=$(resolve_locale "$GIT_ROOT")
case "$LOCALE" in
  es) LANG_LABEL="Spanish (Chilean)" ;;
  fr) LANG_LABEL="French" ;;
  *)  LANG_LABEL="English" ;;
esac
# The prompt instructions are always in English regardless of locale — English maximizes
# instruction-following quality across models. Only the requested output language changes.

if [ "$TRIGGER" = "PreCompact" ]; then
  MODE_NOTE="NOTE: Mid-session compaction snapshot (session continues after). Record what has been done so far, not what remains pending."
  [ "$LOCALE" = "es" ] && MODE_NOTE="NOTA: Snapshot de compactación mid-session (la sesión continúa después). Registra lo hecho hasta ahora, no lo que queda pendiente."
else
  MODE_NOTE="NOTE: End-of-session snapshot — definitive handoff (no return path). The session ends after this."
  [ "$LOCALE" = "es" ] && MODE_NOTE="NOTA: Snapshot de fin de sesión — handoff definitivo (no return path). La sesión termina después de esto."
fi

FULL_PROMPT="Analyze this Claude Code session and generate a structured summary in $LANG_LABEL.
$MODE_NOTE

== USER REQUESTS ==
$USER_MSGS

== TOOLS USED ==
$TOOL_CALLS

== LAST ASSISTANT MESSAGE ==
$LAST_REPLY

Generate EXACTLY this markdown block (no additional text before or after).
Omit sections entirely if they have no real content — never write _(none)_ or empty placeholders.

#### What was done
[2-4 bullets with what was done and why — real context, not just file names]

#### Discarded
[only if something was discarded — omit if not applicable]

#### Fragile context
[only if there are implicit decisions or context that would be lost between sessions — omit if not applicable]

#### Attempted and failed
[only if an approach was tried and failed — omit if not applicable]

#### Imprint candidate
[only if the session produced a durable insight, design decision, or analysis worth a permanent wiki page — omit if not applicable. One line: what to imprint and suggested type (concept/entity/reference/page)]"

SUMMARY=$(claude -p "$FULL_PROMPT" --model claude-haiku-4-5-20251001 2>/dev/null)
case "$SUMMARY" in
  *"#### What was done"*) ;;
  *) exit 0 ;;
esac

if ! printf '%s\n' "$SUMMARY" | grep -qE '^- '; then
  exit 0
fi

# Append transcript path to the imprint candidate bullet so SessionStart can locate it
if printf '%s\n' "$SUMMARY" | grep -q "^#### Imprint candidate$" && [ -n "$TRANSCRIPT_PATH" ]; then
  SUMMARY=$(printf '%s\n' "$SUMMARY" | awk -v tp="$TRANSCRIPT_PATH" '
    /^#### Imprint candidate$/ { print; in_candidate=1; next }
    in_candidate && /^- / { print $0 " — transcript: " tp; in_candidate=0; next }
    in_candidate && /^####/ { in_candidate=0 }
    { print }
  ')
fi

# Archive history entries older than 30 days to CONSOLIDATED.md
CONSOLIDATED="$GIT_ROOT/.cortex/CONSOLIDATED.md"
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

{
  printf '%s\n' "$CURRENT_STATE"
  echo ""
  echo "---"
  echo ""
  echo "## History"
  echo ""
  echo "### $NOW — $AGENT_LABEL ($TRIGGER)"
  echo ""
  printf '%s\n' "$SUMMARY"
  if [ -n "$RECENT_HISTORY" ]; then
    echo ""
    printf '%s\n' "$RECENT_HISTORY"
  fi
} > "$TMP"

mv "$TMP" "$HOT_FILE"
exit 0
