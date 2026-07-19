#!/bin/bash
# validate-schema.sh — validate frontmatter completeness against schema v0.3
# Usage: validate-schema.sh [vault-path] [findings-file]
#   vault-path     defaults to git root or pwd
#   findings-file  if given, findings are APPENDED there (same format as lint.sh)
#                  if omitted, findings are printed to stdout
# Exit: 0 always — severity is communicated via findings content

set -uo pipefail

VAULT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
WIKI="$VAULT/wiki"
FINDINGS_FILE="${2:-}"

if [ ! -d "$WIKI" ]; then
  echo "ERROR: No wiki/ found in $VAULT" >&2
  exit 1
fi

_tmpfile=$(mktemp) || { echo "ERROR: mktemp failed — cannot allocate temp file for schema findings" >&2; exit 1; }
trap 'rm -f "$_tmpfile"' EXIT

f() { echo "[$1] $2" >> "$_tmpfile"; }

# ── Schema definitions ────────────────────────────────────────────────────────
# Canonical types: source | concept | entity | project
# reference and series are retired — migrate to concept and source respectively.
fields_source="title type resource created updated tags confidence schema_version raw"
fields_concept="title type created updated tags aliases sources confidence schema_version"
fields_entity="title type created updated tags aliases sources confidence schema_version"
fields_project="title type created updated tags status repo domains sources confidence schema_version"

# ── Per-file check ────────────────────────────────────────────────────────────
check_fields() {
  local file="$1" rel="${1#$VAULT/}" required="$2"
  local in_frontmatter=0 seen_open=0

  # Extract frontmatter keys into a temp file
  local keys
  keys=$(awk '
    /^---/ { if (count==0) { count=1; next } else { exit } }
    count==1 && /^[a-zA-Z_][a-zA-Z0-9_]*:/ { print $1 }
  ' "$file" | sed 's/://')

  for field in $required; do
    echo "$keys" | grep -qx "$field" || f MEDIUM "Schema drift — missing field '$field': $rel"
  done
}

# ── Walk wiki directories ─────────────────────────────────────────────────────
walk() {
  local dir="$WIKI/$1" required="$2"
  [ -d "$dir" ] || return
  find "$dir" -name "*.md" | grep -v '_index\|/index\.md\|/log\.md' | while read -r p; do
    check_fields "$p" "$required"
  done
}

walk "sources"   "$fields_source"
walk "concepts"  "$fields_concept"
walk "entities"  "$fields_entity"
walk "projects"  "$fields_project"

# ── Output ────────────────────────────────────────────────────────────────────
if [ -n "$FINDINGS_FILE" ]; then
  cat "$_tmpfile" >> "$FINDINGS_FILE"
else
  cat "$_tmpfile"
  count=$(wc -l < "$_tmpfile" | tr -d ' ')
  echo ""
  echo "── Schema validation ────────────────────────────────────────────────────"
  echo "MEDIUM: $count"
fi

exit 0
