#!/bin/bash
# Stop hook for CommandCode: snapshots session context to .hot/MEMORY.md
# Usa cmd -p para sintetizar resúmenes IA desde el transcript JSONL,
# replicando lo que cortex-crystallize-claude.sh hace con claude -p.
# Exit 0 en todos los casos — nunca bloquear el cierre de sesión.

set -uo pipefail

# ── Parse stdin (CommandCode hook payload) ──────────────────────────────────
PAYLOAD=$(cat 2>/dev/null || echo "{}")
TRANSCRIPT_PATH=$(printf '%s' "$PAYLOAD" | jq -r '.transcript_path // empty' 2>/dev/null)
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

# ── Resolve locale ───────────────────────────────────────────────────────────
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

# ── Debug: capturar payload del hook para inspección ────────────────────────
printf '%s' "$PAYLOAD" > "$GIT_ROOT/.hot/stop-hook-payload.json" 2>/dev/null

# ── Resolve transcript path ─────────────────────────────────────────────────
# transcript_path viene en el payload del hook; fallback por si acaso
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  # Derivar project slug desde CWD: /Users/x/proyectos/foo → users-x-proyectos-foo
  PROJECT_SLUG=$(printf '%s' "$CWD" | sed 's|^/||; s|/|-|g; s|-$||' | tr '[:upper:]' '[:lower:]')
  PROJECT_DIR="$HOME/.commandcode/projects/$PROJECT_SLUG"
  if [ -d "$PROJECT_DIR" ]; then
    TRANSCRIPT_PATH=$(find "$PROJECT_DIR" -type f -name '*.jsonl' ! -name '*.checkpoints*' ! -name 'hooks-audit*' 2>/dev/null | sort -r | head -1)
  fi
fi

# Si el path del proyecto no existe o no se pudo derivar, buscar el más reciente global
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  TRANSCRIPT_PATH=$(find "$HOME/.commandcode/projects" -type f -name '*.jsonl' ! -name '*.checkpoints*' ! -name 'hooks-audit*' 2>/dev/null | sort -r | head -1)
fi

[ -z "$TRANSCRIPT_PATH" ] && exit 0
[ ! -f "$TRANSCRIPT_PATH" ] && exit 0

mkdir -p "$GIT_ROOT/.hot" 2>/dev/null || exit 0

if ! grep -qF '.hot/' "$GIT_ROOT/.gitignore" 2>/dev/null; then
  echo '.hot/' >> "$GIT_ROOT/.gitignore"
fi

# ── Leer MEMORY.md existente ────────────────────────────────────────────────
NOW=$(date '+%Y-%m-%d-%H%M')
HOT_FILE="$GIT_ROOT/.hot/MEMORY.md"
TMP=$(mktemp -t hot-cache.XXXXXX) || exit 0
trap 'rm -f "$TMP"' EXIT

if [ -f "$HOT_FILE" ]; then
  # Zone 1: frontmatter + Current state (todo antes de ## History)
  CURRENT_STATE=$(awk '
    /^---$/ { buf = buf "---\n"; next }
    /^## History$/ { gsub(/---\n[[:space:]]*$/, "", buf); printf "%s", buf; exit }
    { buf = buf $0 "\n" }
    END { printf "%s", buf }
  ' "$HOT_FILE")
  # Zone 2: historial previo (todo después de ## History)
  PREV_HISTORY=$(awk '/^## History$/{found=1; next} found{print}' "$HOT_FILE")

  # Guard: eliminar frontmatter duplicado
  DASH_COUNT=$(printf '%s\n' "$CURRENT_STATE" | awk '/^---$/{n++} END { print n + 0 }')
  if [ "$DASH_COUNT" -gt 2 ]; then
    CURRENT_STATE=$(printf '%s\n' "$CURRENT_STATE" | awk '/^---$/{n++; if(n==3) exit} {print}')
  fi
else
  CURRENT_STATE="## Current state"
  PREV_HISTORY=""
fi

# ── Extraer contexto del transcript ─────────────────────────────────────────
# CommandCode JSONL schema: { role: "user"|"assistant"|"tool", content: [...], timestamp: "..." }
# Tipos de content: "text", "reasoning", "tool-call", "tool-result"
TOOL_CALL_COUNT=$(tail -n 5000 "$TRANSCRIPT_PATH" | jq -s -r '.[] | .content[]? | select(.type=="tool-call") | .toolName' 2>/dev/null | awk 'END { print NR + 0 }')
[ "$TOOL_CALL_COUNT" -eq 0 ] && exit 0

USER_MSGS=$(tail -n 5000 "$TRANSCRIPT_PATH" | jq -s -r '.[] | select(.role=="user") | .content[]? | select(.type=="text") | .text' 2>/dev/null \
  | grep -v "^<" | grep -v "^$" | head -40)

TOOL_CALLS=$(tail -n 5000 "$TRANSCRIPT_PATH" | jq -s -r '
  .[]
  | select(.role=="assistant")
  | .content[]?
  | select(.type=="tool-call")
  | "- " + .toolName + ": " + ((.input.command // .input.file_path // .input.url // .input.pattern // (.input | tostring)) | .[0:120])
' 2>/dev/null | head -50)

LAST_REPLY=$(tail -n 5000 "$TRANSCRIPT_PATH" | jq -s -r '.[] | select(.role=="assistant") | .content[]? | select(.type=="text") | .text' 2>/dev/null | tail -3)

# ── Síntesis IA vía headless ────────────────────────────────────────────────
LOCALE=$(resolve_locale "$GIT_ROOT")
case "$LOCALE" in
  es) LANG_LABEL="Spanish (Chilean)" ;;
  fr) LANG_LABEL="French" ;;
  *)  LANG_LABEL="English" ;;
esac
# The prompt instructions are always in English regardless of locale — English maximizes
# instruction-following quality across models. Only the requested output language changes.

FULL_PROMPT="Analyze this CommandCode session and generate a structured summary in $LANG_LABEL.
NOTE: End-of-session snapshot — definitive handoff (no return path). The session ends after this.

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

#### Imprint candidate
[only if the session produced a durable insight, design decision, or analysis worth a permanent wiki page — omit if not applicable. One line: what to imprint and suggested type (concept/entity/reference/page)]"

# Encontrar binario cmd o commandcode
CMD_BIN=""
for c in "cmd" "commandcode"; do
  CMD_BIN=$(command -v "$c" 2>/dev/null) && break
done
[ -z "$CMD_BIN" ] && exit 0

# ── Self-backgrounding fix (2026-06-16) ─────────────────────────────────────
# El hook Stop tiene timeout de 30s en CommandCode. La llamada síncrona a
# `cmd -p` puede tardar más cuando el proceso padre está en shutdown
# (cold start del modelo, red congestionada). Refactor: el padre escribe un
# snapshot PLACEHOLDER inmediato y bifurca la síntesis IA en background via
# nohup, retornando exit 0 en <100ms. El hijo reemplaza el placeholder con
# el resumen sintetizado al terminar (puede tardar 30-60s, no bloquea cierre).

SENTINEL="__PENDING_SYNTHESIS_${NOW// /_}__"
HELPER="$GIT_ROOT/.hot/.synthesize-${NOW// /_/}.sh"

# Snapshot placeholder escrito de forma síncrona
{
  printf '%s\n' "$CURRENT_STATE"
  echo ""
  echo "---"
  echo ""
  echo "## History"
  echo ""
  echo "### $NOW — CommandCode (Stop)"
  echo ""
  echo "$SENTINEL"
  if [ -n "$PREV_HISTORY" ]; then
    echo ""
    printf '%s\n' "$PREV_HISTORY"
  fi
} > "$TMP"

mv "$TMP" "$HOT_FILE"

# Serializar contexto al helper (escapa comillas para evitar injection)
HOT_FILE_ESC=$(printf '%s' "$HOT_FILE" | sed "s/'/'\\''/g")
SENTINEL_ESC=$(printf '%s' "$SENTINEL" | sed "s/'/'\\''/g")
FULL_PROMPT_ESC=$(printf '%s' "$FULL_PROMPT" | sed "s/'/'\\''/g")

# Escribir helper script
cat > "$HELPER" <<HEREDOC
#!/bin/bash
# Auto-generado por cortex-crystallize-commandcode.sh
HOT_FILE='$HOT_FILE_ESC'
SENTINEL='$SENTINEL_ESC'
FULL_PROMPT='$FULL_PROMPT_ESC'
SUMMARY=\$("$CMD_BIN" -m "mimo-v2.5" -p "\$FULL_PROMPT" 2>/dev/null)
case "\$SUMMARY" in
  *"#### What was done"*) ;;
  *) rm -f "$HELPER"; exit 0 ;;
esac
if ! printf '%s\n' "\$SUMMARY" | grep -qE '^- '; then
  rm -f "$HELPER"; exit 0
fi
if [ -f "\$HOT_FILE" ] && grep -qF "\$SENTINEL" "\$HOT_FILE"; then
  TMP2=\$(mktemp -t hot-cache-bg.XXXXXX) || exit 0
  awk -v sentinel="\$SENTINEL" -v summary="\$SUMMARY" '
    { if (index(\$0, sentinel)) { printf "%s\n", summary; next } print }
  ' "\$HOT_FILE" > "\$TMP2" && mv "\$TMP2" "\$HOT_FILE"
fi
rm -f "$HELPER"
HEREDOC

chmod +x "$HELPER"

# Lanzar helper en background con nohup — sobrevive al exit del padre
nohup "$HELPER" </dev/null >/dev/null 2>&1 &
disown 2>/dev/null || true

exit 0