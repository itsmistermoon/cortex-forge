#!/bin/bash
# SessionEnd + PreCompact hook: snapshots de sesión en .hot/{project}.md
# SessionEnd  → síntesis con claude -p (bullets descriptivos)
# PreCompact  → mecánico (lista de archivos modificados)

set -uo pipefail

PAYLOAD=$(cat 2>/dev/null || echo "{}")
TRANSCRIPT_PATH=$(printf '%s' "$PAYLOAD" | jq -r '.transcript_path // empty' 2>/dev/null)
TRIGGER=$(printf '%s' "$PAYLOAD" | jq -r '.hook_event_name // "PreCompact"' 2>/dev/null)
CWD=$(printf '%s' "$PAYLOAD" | jq -r '.cwd // empty' 2>/dev/null)

find_git_root_dir() {
  local dir="${CWD:-$PWD}"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.git" ]; then echo "$dir"; return 0; fi
    dir="$(dirname "$dir")"
  done
  echo "${CWD:-$PWD}"
}

GIT_ROOT=$(find_git_root_dir)
PROJECT=$(basename "$GIT_ROOT")

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  TRANSCRIPT_PATH=$(ls -t "$HOME/.claude/projects/"*/*.jsonl 2>/dev/null | head -1)
fi
[ -z "$TRANSCRIPT_PATH" ] && exit 0
[ ! -f "$TRANSCRIPT_PATH" ] && exit 0

mkdir -p "$GIT_ROOT/.hot" 2>/dev/null || exit 0

if ! grep -qF '.hot/' "$GIT_ROOT/.gitignore" 2>/dev/null; then
  echo '.hot/' >> "$GIT_ROOT/.gitignore"
fi

NOW=$(date '+%Y-%m-%d %H:%M %Z')
HOT_FILE="$GIT_ROOT/.hot/$PROJECT.md"
TMP=$(mktemp -t hot-cache.XXXXXX) || exit 0
trap 'rm -f "$TMP"' EXIT

if [ -f "$HOT_FILE" ]; then
  # Cortar en el --- que precede a ## History, no en el primero que aparece.
  # Esto preserva el frontmatter YAML cuando la skill escribe el archivo.
  CURRENT_STATE=$(awk '
    /^---$/ { buf = buf "---\n"; next }
    /^## History$/ { gsub(/---\n[[:space:]]*$/, "", buf); printf "%s", buf; exit }
    { buf = buf $0 "\n" }
    END { printf "%s", buf }
  ' "$HOT_FILE")
  PREV_HISTORY=$(awk '/^## History$/{found=1; next} found{print}' "$HOT_FILE")

  # Guard: si hay más de 2 líneas "---" en CURRENT_STATE, hay bloques duplicados.
  # Conservar solo el primer bloque (frontmatter + current state).
  DASH_COUNT=$(printf '%s\n' "$CURRENT_STATE" | grep -c '^---$' 2>/dev/null || echo 0)
  if [ "$DASH_COUNT" -gt 2 ]; then
    CURRENT_STATE=$(printf '%s\n' "$CURRENT_STATE" | awk '/^---$/{n++; if(n==3) exit} {print}')
  fi
else
  CURRENT_STATE="## Current state"
  PREV_HISTORY=""
fi

if [ "$TRIGGER" = "SessionEnd" ]; then
  TOOL_CALL_COUNT=$(jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | .name' "$TRANSCRIPT_PATH" 2>/dev/null | wc -l | tr -d ' ')
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

  FULL_PROMPT="Analiza esta sesión de Claude Code y genera un resumen estructurado en español chileno.

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
  [ -z "$SUMMARY" ] && exit 0

else
  FILES_TOUCHED=$(jq -r '
    select(.type == "assistant")
    | .message.content[]?
    | select(.type == "tool_use" and (.name == "Edit" or .name == "Write" or .name == "NotebookEdit"))
    | .input.file_path // empty
  ' "$TRANSCRIPT_PATH" 2>/dev/null | sort -u | grep -v '^$' || true)

  EXTERNAL_ACTIONS=$(jq -r '
    select(.type == "assistant")
    | .message.content[]?
    | select(.type == "tool_use" and .name == "Bash")
    | .input.command
    | select(test("git (commit|push|tag)|gh (issue|pr) (create|edit|close)|sam deploy"; "i"))
    | split("\n")[0]
  ' "$TRANSCRIPT_PATH" 2>/dev/null | tail -n 10)

  [ -z "$FILES_TOUCHED" ] && [ -z "$EXTERNAL_ACTIONS" ] && exit 0

  SUMMARY="#### What was done
$(printf '%s\n' "$FILES_TOUCHED" | sed 's|^|- |')"

  if [ -n "$EXTERNAL_ACTIONS" ]; then
    SUMMARY="$SUMMARY

#### External actions
\`\`\`bash
$EXTERNAL_ACTIONS
\`\`\`"
  fi
fi

{
  printf '%s\n' "$CURRENT_STATE"
  echo ""
  echo "---"
  echo ""
  echo "## History"
  echo ""
  echo "### $NOW — Claude Code ($TRIGGER)"
  echo ""
  printf '%s\n' "$SUMMARY"
  if [ -n "$PREV_HISTORY" ]; then
    echo ""
    printf '%s\n' "$PREV_HISTORY"
  fi
} > "$TMP"

mv "$TMP" "$HOT_FILE"
exit 0
