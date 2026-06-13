#!/bin/bash
# SessionEnd + PreCompact hook: snapshots de sesión en .hot/MEMORY.md
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

if ! grep -qF '.hot/' "$GIT_ROOT/.gitignore" 2>/dev/null; then
  echo '.hot/' >> "$GIT_ROOT/.gitignore"
fi

NOW=$(date '+%Y-%m-%d %H:%M %Z')
HOT_FILE="$GIT_ROOT/.hot/MEMORY.md"
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

if [ "$TRIGGER" = "PreCompact" ]; then
  MODE_NOTE="NOTA: Snapshot de compactación mid-session (la sesión continúa después). Registra lo hecho hasta ahora, no lo que queda pendiente."
else
  MODE_NOTE="NOTA: Snapshot de fin de sesión — handoff definitivo (no return path). La sesión termina después de esto."
fi

FULL_PROMPT="Analiza esta sesión de Claude Code y genera un resumen estructurado en español chileno.
$MODE_NOTE

== PETICIONES DEL USUARIO ==
$USER_MSGS

== HERRAMIENTAS USADAS ==
$TOOL_CALLS

== ÚLTIMO MENSAJE DEL ASISTENTE ==
$LAST_REPLY

Genera EXACTAMENTE este bloque markdown (sin texto adicional antes ni después).
Omite completamente las secciones que no tengan contenido real — no uses _(none)_ ni placeholders vacíos.

#### What was done
[2-4 bullets con qué se hizo y por qué — contexto real, no solo nombres de archivo]

#### Discarded
[solo si hubo algo descartado — omitir si no aplica]

#### Fragile context
[solo si hay decisiones implícitas o contexto que se perdería entre sesiones — omitir si no aplica]"

SUMMARY=$(claude -p "$FULL_PROMPT" 2>/dev/null)
case "$SUMMARY" in
  *"#### What was done"*) ;;
  *) exit 0 ;;
esac

if ! printf '%s\n' "$SUMMARY" | grep -qE '^- '; then
  exit 0
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
  if [ -n "$PREV_HISTORY" ]; then
    echo ""
    printf '%s\n' "$PREV_HISTORY"
  fi
} > "$TMP"

mv "$TMP" "$HOT_FILE"
exit 0
