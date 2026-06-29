#!/bin/bash
# cortex-imprint-auto.sh: autonomous imprint synthesis for imprint_triage: auto
# Invoked from cortex-reactivate.sh when auto mode is active and a candidate exists.
# Reads .cortex/imprint-draft.md + transcript → claude -p (Haiku) → writes wiki page.
# Removes the draft file on success so the nudge doesn't repeat next session.
#
# Args: $1 = DRAFT_PATH, $2 = GIT_ROOT

set -euo pipefail

DRAFT_PATH="${1:-}"
GIT_ROOT="${2:-}"

[ -f "$DRAFT_PATH" ] || exit 0
[ -d "$GIT_ROOT" ]   || exit 0

# ── Read draft ────────────────────────────────────────────────────────────────
CANDIDATE=$(awk -F': ' '/^candidate:/{print substr($0, index($0,$2))}' "$DRAFT_PATH" | head -1)
TRANSCRIPT=$(awk -F': ' '/^transcript:/{print substr($0, index($0,$2))}' "$DRAFT_PATH" | head -1)

[ -n "$CANDIDATE" ] || exit 0
[ -f "$TRANSCRIPT" ] || exit 0

# ── Read transcript excerpts ──────────────────────────────────────────────────
USER_MSGS=$(jq -r 'select(.type=="user") | .message.content[]? | select(.type=="text") | .text' \
  "$TRANSCRIPT" 2>/dev/null | grep -v '^<' | grep -v '^$' | head -30 || true)

TOOL_CALLS=$(jq -r '
  select(.type=="assistant")
  | .message.content[]?
  | select(.type=="tool_use")
  | "- " + .name + ": " + ((.input.file_path // .input.command // (.input | tostring)) | .[0:120])
' "$TRANSCRIPT" 2>/dev/null | head -40 || true)

LAST_REPLY=$(jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text' \
  "$TRANSCRIPT" 2>/dev/null | tail -5 || true)

[ -n "$USER_MSGS" ] || exit 0

# ── Read vault context ────────────────────────────────────────────────────────
AGENTS_EXCERPT=$(head -80 "$GIT_ROOT/AGENTS.md" 2>/dev/null || true)
WIKI_INDEX=$(head -80 "$GIT_ROOT/wiki/index.md" 2>/dev/null || true)

TEMPLATES_CONCEPT=$(cat "$GIT_ROOT/templates/concept.md" 2>/dev/null || true)
TEMPLATES_ENTITY=$(cat "$GIT_ROOT/templates/entity.md" 2>/dev/null || true)
TEMPLATES_SOURCE=$(cat "$GIT_ROOT/templates/source.md" 2>/dev/null || true)
TEMPLATES_REFERENCE=$(cat "$GIT_ROOT/templates/reference.md" 2>/dev/null || true)

TODAY=$(date '+%Y-%m-%d')

# ── Build prompt ──────────────────────────────────────────────────────────────
PROMPT="You are archiving a session synthesis as a permanent wiki page in a personal knowledge vault.

== CANDIDATE ==
$CANDIDATE

== SESSION USER REQUESTS ==
$USER_MSGS

== TOOLS USED ==
$TOOL_CALLS

== LAST ASSISTANT MESSAGE ==
$LAST_REPLY

== VAULT IDENTITY (from AGENTS.md) ==
$AGENTS_EXCERPT

== EXISTING WIKI INDEX ==
$WIKI_INDEX

== TEMPLATES ==
--- concept ---
$TEMPLATES_CONCEPT

--- entity ---
$TEMPLATES_ENTITY

--- source ---
$TEMPLATES_SOURCE

--- reference ---
$TEMPLATES_REFERENCE

== INSTRUCTIONS ==
1. Choose the most appropriate page type (concept / entity / source / reference) based on the candidate description and what the session produced.
2. Choose a title in kebab-case that fits the vault's naming conventions (see index for examples).
3. Write a complete, self-contained wiki page using the matching template. The page must be readable cold with no session context.
4. Fill in all frontmatter fields. Use today's date: $TODAY. Add relevant tags.
5. Do NOT include the session date, conversation references, or phrases like \"as discussed\".
6. Output EXACTLY this structure and nothing else:

PAGE_TYPE: <concept|entity|source|reference>
PAGE_PATH: wiki/<type>s/<kebab-title>.md
PAGE_TITLE: <Title in Title Case>
---PAGE_CONTENT---
<complete page content including frontmatter>
---END---"

# ── Run claude -p ─────────────────────────────────────────────────────────────
OUTPUT=$(claude -p "$PROMPT" --model claude-haiku-4-5-20251001 2>/dev/null) || exit 0

# ── Parse output ──────────────────────────────────────────────────────────────
PAGE_TYPE=$(printf '%s\n' "$OUTPUT" | awk '/^PAGE_TYPE:/{print $2; exit}')
PAGE_PATH=$(printf '%s\n' "$OUTPUT" | awk '/^PAGE_PATH:/{print $2; exit}')
PAGE_TITLE=$(printf '%s\n' "$OUTPUT" | awk '/^PAGE_TITLE:/{sub(/^PAGE_TITLE: /,""); print; exit}')
PAGE_CONTENT=$(printf '%s\n' "$OUTPUT" | awk '/^---PAGE_CONTENT---/{found=1; next} /^---END---/{exit} found{print}')

# Validate
[ -n "$PAGE_TYPE" ]    || exit 0
[ -n "$PAGE_PATH" ]    || exit 0
[ -n "$PAGE_CONTENT" ] || exit 0

# Guard against overwriting existing pages
TARGET="$GIT_ROOT/$PAGE_PATH"
[ -f "$TARGET" ] && exit 0   # don't clobber — fall back to suggest

# ── Write page ────────────────────────────────────────────────────────────────
mkdir -p "$(dirname "$TARGET")"
printf '%s\n' "$PAGE_CONTENT" > "$TARGET"

# ── Update wiki/index.md ──────────────────────────────────────────────────────
INDEX="$GIT_ROOT/wiki/index.md"
if [ -f "$INDEX" ] && ! grep -qF "$PAGE_PATH" "$INDEX"; then
  SECTION_HEADER="## $(echo "$PAGE_TYPE" | sed 's/./\u&/')s"
  # Insert after matching section header, or append at end
  if grep -qF "$SECTION_HEADER" "$INDEX"; then
    TMP_IDX=$(mktemp)
    awk -v hdr="$SECTION_HEADER" -v entry="- [[$PAGE_PATH]] — $PAGE_TITLE" '
      $0 == hdr { print; print entry; next }
      { print }
    ' "$INDEX" > "$TMP_IDX" && mv "$TMP_IDX" "$INDEX"
  else
    printf '\n%s\n- [[%s]] — %s\n' "$SECTION_HEADER" "$PAGE_PATH" "$PAGE_TITLE" >> "$INDEX"
  fi
fi

# ── Update wiki/meta/log.md ───────────────────────────────────────────────────
LOG="$GIT_ROOT/wiki/meta/log.md"
if [ -f "$LOG" ]; then
  LOG_ENTRY="## [$TODAY] auto-imprint | $PAGE_TITLE"
  printf '\n%s\n\n' "$LOG_ENTRY" >> "$LOG"
fi

# ── Remove draft ──────────────────────────────────────────────────────────────
rm -f "$DRAFT_PATH"

exit 0
