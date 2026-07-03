#!/bin/bash
# cortex-prune.sh — health check for a cortex-forge vault wiki/
# Usage: cortex-prune.sh [vault-path]
# Exit: 0 = no HIGH findings, 1 = HIGH findings exist

set -uo pipefail

VAULT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
WIKI="$VAULT/wiki"
RAW="$VAULT/.raw"

if [ ! -d "$WIKI" ]; then
  echo "ERROR: No wiki/ found in $VAULT" >&2
  exit 2
fi

FINDINGS=$(mktemp) || { echo "ERROR: mktemp failed — cannot allocate temp file for findings" >&2; exit 2; }
DEAD_LINKS=$(mktemp) || { echo "ERROR: mktemp failed — cannot allocate temp file for dead links" >&2; exit 2; }
RAW_NOSRC=$(mktemp) || { echo "ERROR: mktemp failed — cannot allocate temp file for raw_without_source" >&2; exit 2; }
NO_CONF=$(mktemp) || { echo "ERROR: mktemp failed — cannot allocate temp file for missing_confidence" >&2; exit 2; }
ORPHANS=$(mktemp) || { echo "ERROR: mktemp failed — cannot allocate temp file for orphans" >&2; exit 2; }
trap 'rm -f "$FINDINGS" "$DEAD_LINKS" "$RAW_NOSRC" "$NO_CONF" "$ORPHANS"' EXIT

f() { echo "[$1] $2" >> "$FINDINGS"; }

# JSON helpers — hand-rolled, no jq (design constraint: .md + .sh only)
json_str_array() {  # $1: file with one string per line → JSON array of strings
  [ -s "$1" ] || { printf '[]'; return; }
  sort -u "$1" | awk 'BEGIN{printf "["} {
    s=$0; gsub(/\\/,"\\\\",s); gsub(/"/,"\\\"",s)
    printf "%s\"%s\"", (NR>1?", ":""), s
  } END{printf "]"}'
}

json_dead_links_array() {  # $1: file with from<TAB>target per line → JSON array of objects
  [ -s "$1" ] || { printf '[]'; return; }
  sort -u "$1" | awk -F'\t' 'BEGIN{printf "["} {
    a=$1; b=$2
    gsub(/\\/,"\\\\",a); gsub(/"/,"\\\"",a)
    gsub(/\\/,"\\\\",b); gsub(/"/,"\\\"",b)
    printf "%s{\"from\": \"%s\", \"broken_target\": \"[[%s]]\"}", (NR>1?", ":""), a, b
  } END{printf "]"}'
}

# ── HIGH: Dead wikilinks ──────────────────────────────────────────────────────
grep -ro '\[\[wiki/[^]|]*' "$WIKI" --include="*.md" 2>/dev/null \
  | sed 's/\[\[//' | sort -u \
  | while IFS=: read -r src link; do
      # strip trailing .md if present — wikilinks may or may not include extension
      link="${link%.md}"
      if [ ! -f "$VAULT/${link}.md" ]; then
        f HIGH "Dead link in ${src#$VAULT/}: [[${link}]]"
        printf '%s\t%s\n' "${src#$VAULT/}" "$link" >> "$DEAD_LINKS"
      fi
    done

# ── HIGH: Unprocessed .raw/ files ─────────────────────────────────────────────
if [ -d "$RAW" ]; then
  find "$RAW" -name "*.md" | while read -r raw; do
    rel="${raw#$VAULT/}"
    slug=$(basename "$raw" .md)
    # Check across all wiki directories: raw: (single-source), sources: (multi-source list), then filename match
    if ! grep -rl "^raw: ${rel}$" "$WIKI" 2>/dev/null | grep -q .; then
      if ! grep -rl "^  - ${rel}$" "$WIKI" 2>/dev/null | grep -q .; then
        if ! find "$WIKI" -name "*${slug}*.md" 2>/dev/null | grep -q .; then
          f HIGH "No source page for: $rel"
          echo "$rel" >> "$RAW_NOSRC"
        fi
      fi
    fi
  done
fi

# ── HIGH: Pages without frontmatter ──────────────────────────────────────────
# index.md y log.md son intencionalmente sin frontmatter
find "$WIKI" -name "*.md" \
  | grep -v '_index\|/index\.md\|/log\.md' \
  | while read -r p; do
      head -1 "$p" | grep -q "^---" || f HIGH "No frontmatter: ${p#$VAULT/}"
    done

# ── MEDIUM: Orphan pages ──────────────────────────────────────────────────────
# Match by full vault-relative path to avoid basename collisions.
# A page is an orphan if no other wiki page links to it via [[wiki/...]] wikilink
# OR references it in a sources: YAML frontmatter list.
find "$WIKI" -name "*.md" \
  | grep -v '_index\|/index\.md\|/log\.md' \
  | while read -r page; do
      rel="${page#$VAULT/}"          # e.g. wiki/concepts/memory-system.md
      rel_noext="${rel%.md}"         # e.g. wiki/concepts/memory-system
      basename_noext="${rel_noext##*/}"  # e.g. memory-system
      # Count pages that contain a wikilink to this exact path (with or without .md)
      hits=$(grep -rl "\[\[${rel_noext}" "$WIKI" 2>/dev/null \
             | grep -v "^${page}$" | wc -l | tr -d ' ')
      # Also count pages that reference this page in a sources: frontmatter entry
      if [ "$hits" -eq 0 ]; then
        hits=$(grep -rl "^\s*-\s*.*${basename_noext}" "$WIKI" 2>/dev/null \
               | xargs grep -l "^sources:" 2>/dev/null \
               | grep -v "^${page}$" | wc -l | tr -d ' ')
      fi
      if [ "$hits" -eq 0 ]; then
        f MEDIUM "Orphan: ${rel}"
        echo "$rel" >> "$ORPHANS"
      fi
    done

# ── MEDIUM: Missing provenance — concepts + entities ──────────────────────────
# Source pages usan `source:` (URL) y `raw:`, no `sources:` wiki
for dir in "$WIKI/concepts" "$WIKI/entities"; do
  [ -d "$dir" ] || continue
  find "$dir" -name "*.md" | grep -v '_index' | while read -r p; do
    rel="${p#$VAULT/}"
    grep -q "^sources:" "$p" || f MEDIUM "No sources: $rel"
    grep -q "^confidence:" "$p" || { f MEDIUM "No confidence: $rel"; echo "$rel" >> "$NO_CONF"; }
  done
done

# ── MEDIUM: Sources without confidence ────────────────────────────────────────
[ -d "$WIKI/sources" ] && \
find "$WIKI/sources" -name "*.md" | grep -v '_index' | while read -r p; do
  grep -q "^confidence:" "$p" || { f MEDIUM "No confidence: ${p#$VAULT/}"; echo "${p#$VAULT/}" >> "$NO_CONF"; }
done

# ── LOW: Sources without tags ─────────────────────────────────────────────────
[ -d "$WIKI/sources" ] && \
find "$WIKI/sources" -name "*.md" | grep -v '_index' | while read -r p; do
  val=$(grep "^tags:" "$p" 2>/dev/null | head -1)
  { [ -z "$val" ] || [ "$val" = "tags: []" ]; } && f LOW "No tags: ${p#$VAULT/}"
done

# ── Schema validation (delegated) ────────────────────────────────────────────
VALIDATE_SCRIPT="$(dirname "$0")/cortex-validate-schema.sh"
if [ -x "$VALIDATE_SCRIPT" ]; then
  "$VALIDATE_SCRIPT" "$VAULT" "$FINDINGS"
else
  echo "WARNING: cortex-validate-schema.sh not found next to cortex-prune.sh ($VALIDATE_SCRIPT) — schema drift checks skipped. Reinstall the cortex-prune skill to restore it." >&2
fi

# ── Output ────────────────────────────────────────────────────────────────────
if [ ! -f "$FINDINGS" ]; then
  echo "ERROR: findings file disappeared mid-run ($FINDINGS) — cannot report results" >&2
  exit 2
fi
HIGH=$(grep -c '^\[HIGH\]'   "$FINDINGS" 2>/dev/null || true)
MED=$(grep  -c '^\[MEDIUM\]' "$FINDINGS" 2>/dev/null || true)
LOW=$(grep  -c '^\[LOW\]'    "$FINDINGS" 2>/dev/null || true)
case "$HIGH$MED$LOW" in
  *[!0-9]*|"") echo "ERROR: could not compute finding counts (HIGH='$HIGH' MEDIUM='$MED' LOW='$LOW') — treating as failure, not silent success" >&2; exit 2 ;;
esac

for sev in HIGH MEDIUM LOW; do
  lines=$(grep "^\[${sev}\]" "$FINDINGS" 2>/dev/null || true)
  [ -n "$lines" ] && echo "" && echo "── ${sev} ────────────────" && echo "$lines"
done

echo ""
echo "── Summary ──────────────────────────────────────────────────────────────"
echo "HIGH: $HIGH  MEDIUM: $MED  LOW: $LOW"

# ── vault-report.json ─────────────────────────────────────────────────────────
# Canonical schema defined in skills/cortex-prune/SKILL.md step 4a.
# Written atomically (temp file in the same dir + rename) so a kill/crash
# mid-write never leaves a truncated/corrupt vault-report.json behind.
mkdir -p "$WIKI/meta"
REPORT_TMP=$(mktemp "$WIKI/meta/.vault-report.json.XXXXXX") || { echo "ERROR: mktemp failed — cannot write vault-report.json" >&2; exit 2; }
{
  printf '{\n'
  printf '  "generated": "%s",\n' "$(date +%Y-%m-%d)"
  printf '  "health": {\n'
  printf '    "dead_links": %s,\n' "$(json_dead_links_array "$DEAD_LINKS")"
  printf '    "raw_without_source_page": %s,\n' "$(json_str_array "$RAW_NOSRC")"
  printf '    "missing_confidence": %s,\n' "$(json_str_array "$NO_CONF")"
  printf '    "orphan_pages": %s\n' "$(json_str_array "$ORPHANS")"
  printf '  }\n'
  printf '}\n'
} > "$REPORT_TMP" && mv "$REPORT_TMP" "$WIKI/meta/vault-report.json" || { echo "ERROR: failed to write vault-report.json" >&2; rm -f "$REPORT_TMP"; exit 2; }
echo "Report written: ${WIKI#$VAULT/}/meta/vault-report.json"

[ "$HIGH" -gt 0 ] && exit 1 || exit 0
