#!/bin/bash
# antu-prune.sh — health check for an Antu vault wiki/
# Usage: antu-prune.sh [vault-path]
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
INDEX_MISMATCHES=$(mktemp) || { echo "ERROR: mktemp failed — cannot allocate temp file for index_mismatches" >&2; exit 2; }
INCOMING_LINKS=$(mktemp) || { echo "ERROR: mktemp failed — cannot allocate temp file for incoming_links" >&2; exit 2; }
INCOMING_TARGETS=$(mktemp) || { echo "ERROR: mktemp failed — cannot allocate temp file for incoming_targets" >&2; exit 2; }
SOURCES_PAGES=$(mktemp) || { echo "ERROR: mktemp failed — cannot allocate temp file for sources_pages" >&2; exit 2; }
RAW_REFS=$(mktemp) || { echo "ERROR: mktemp failed — cannot allocate temp file for raw_refs" >&2; exit 2; }
SOURCES_REFS=$(mktemp) || { echo "ERROR: mktemp failed — cannot allocate temp file for sources_refs" >&2; exit 2; }
WIKI_SLUGS=$(mktemp) || { echo "ERROR: mktemp failed — cannot allocate temp file for wiki_slugs" >&2; exit 2; }
RAW_INDEX=$(mktemp) || { echo "ERROR: mktemp failed — cannot allocate temp file for raw_index" >&2; exit 2; }

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
      # strip trailing backslash — happens when the wikilink uses an escaped alias
      # pipe inside a markdown table cell, e.g. [[path\|Display text]]; the backslash
      # is part of the table escaping, not the link target
      link="${link%\\}"
      if [ ! -f "$VAULT/${link}.md" ]; then
        f HIGH "Dead link in ${src#"$VAULT"/}: [[${link}]]"
        printf '%s\t%s\n' "${src#"$VAULT"/}" "$link" >> "$DEAD_LINKS"
      fi
    done

# ── HIGH: Unprocessed .raw/ files ─────────────────────────────────────────────
# Performance: previous implementation was O(n × m) — for each .raw/ file,
# ran 2 recursive greps plus a `find -name` over the whole wiki. On
# moon-multivac (143 .raw/ files, 353 wiki pages) this took >10 min and
# effectively hung the script. Current implementation builds the index of
# every `raw:` and `sources:` reference in the wiki in a single pass each
# (O(m)), then each .raw/ file is a single O(1) lookup (O(n)). Total:
# O(n + m).

if [ -d "$RAW" ]; then
  # Single pass: every `raw: .raw/foo.md` reference anywhere in the wiki.
  grep -rho '^raw: .*\.md$' "$WIKI" --include="*.md" 2>/dev/null \
    | sed 's/^raw:[[:space:]]*//' | sort -u > "$RAW_REFS" || true
  # Single pass: every `- .raw/foo.md` (a sources: list item pointing to raw).
  grep -rhoE '^[[:space:]]*-[[:space:]]+\.raw/.*\.md$' "$WIKI" --include="*.md" 2>/dev/null \
    | sed 's/^[[:space:]]*-[[:space:]]*//' | sort -u > "$SOURCES_REFS" || true
  # Single pass: every wiki page basename (for the filename fallback).
  find "$WIKI" -name "*.md" 2>/dev/null \
    | sed 's|.*/||; s|\.md$||' | sort -u > "$WIKI_SLUGS" || true

  # Merge all three index files into one sorted set. The combined lookup
  # is a single `grep -Fxq` per .raw/ file instead of three. Membership
  # in a sorted file is O(log n) with a binary search (grep's default
  # when the file is sorted).
  cat "$RAW_REFS" "$SOURCES_REFS" "$WIKI_SLUGS" 2>/dev/null | sort -u > "$RAW_INDEX" || true

  find "$RAW" -name "*.md" | while read -r raw; do
    rel="${raw#"$VAULT"/}"
    slug=$(basename "$raw" .md)
    if ! grep -Fxq "$rel" "$RAW_INDEX" 2>/dev/null \
       && ! grep -Fxq "$slug" "$RAW_INDEX" 2>/dev/null; then
      f HIGH "No source page for: $rel"
      echo "$rel" >> "$RAW_NOSRC"
    fi
  done
fi

# ── HIGH: Pages without frontmatter ──────────────────────────────────────────
# index.md, log.md, and everything under wiki/meta/ (operational records, not
# knowledge — see wiki/meta/_index.md) are intentionally frontmatter-less.
find "$WIKI" -name "*.md" \
  | grep -v '_index\|/index\.md\|/log\.md\|/meta/' \
  | while read -r p; do
      head -1 "$p" | grep -q "^---" || f HIGH "No frontmatter: ${p#"$VAULT"/}"
    done

# ── MEDIUM: Orphan pages ──────────────────────────────────────────────────────
# Match by full vault-relative path to avoid basename collisions.
# A page is an orphan if no other wiki page links to it via [[wiki/...]] wikilink
# OR references it in a sources: YAML frontmatter list.
# wiki/meta/ excluded — operational records are indexed via wiki/meta/_index.md,
# not the [[wikilink]] graph (see wiki/meta/_index.md).
#
# Performance: previous implementation was O(n × m) — for each page, ran 1-2
# recursive greps over the whole wiki. On moon-multivac (349 pages) this took
# ~4 min. Current implementation builds the wikilinks set and sources: pages
# set ONCE upfront (O(m)), then each page is a single O(1) lookup (O(n)).
# Total: O(n + m), ~10x faster on small vaults, orders of magnitude on large.

# Build the inverse wikilink index in a single pass over the vault:
# for every `from<TAB>to` pair, accumulate. Then orphan detection is
# O(1) per page (membership lookup, excluding self).
# `from<TAB>to` per line. Trailing `\` is stripped (escaped alias pipe in tables).
# `\|Display text` is the alias form — take only the path part.
while IFS=: read -r src link; do
  link="${link#\[\[wiki/}"
  link="${link%.md}"
  link="${link%\\}"
  case "$link" in
    *"|"*) link="${link%%|*}" ;;  # drop "|Display text" alias
  esac
  printf '%s\t%s\n' "${src#"$VAULT"/}" "$link"
done < <(grep -roE '\[\[wiki/[^]|]+' "$WIKI" --include="*.md" 2>/dev/null) > "$INCOMING_LINKS"

# Precompute the set of pages that have at least one inbound non-self
# wikilink: a flat sorted list of unique target paths. Orphan detection
# becomes a single `grep -Fxq` per page (O(log n) with sorted input,
# O(n) worst case) instead of an awk linear scan per page.
awk -F'\t' '$1 != $2 { print $2 }' "$INCOMING_LINKS" | sort -u > "$INCOMING_TARGETS" || true

# Precompute the set of all references from pages with sources: frontmatter.
# Extracts both basename-only references (e.g. concept-name) and full path
# references (e.g. wiki/sources/slug.md, wiki/sources/slug, etc.).
SOURCES_TARGETS=$(mktemp) || exit 2
trap 'rm -f "$FINDINGS" "$DEAD_LINKS" "$RAW_NOSRC" "$NO_CONF" "$ORPHANS" "$INDEX_MISMATCHES" "$INCOMING_LINKS" "$INCOMING_TARGETS" "$SOURCES_PAGES" "$RAW_REFS" "$SOURCES_REFS" "$WIKI_SLUGS" "$RAW_INDEX" "$SOURCES_TARGETS"' EXIT
while IFS= read -r sf; do
  # Scope extraction to the frontmatter block only (between the two `---`
  # delimiters) — body prose or lists can otherwise contain `- foo` or
  # `wiki/...` text that falsely counts as a sources: reference.
  fm=$(awk '/^---$/{c++; next} c==1' "$sf" 2>/dev/null)
  # basename references (YAML block list: `- concept-name`)
  printf '%s\n' "$fm" | grep -oE '^[[:space:]]+-[[:space:]]+[^ ]+$' \
    | sed 's/^[[:space:]]*-[[:space:]]*//' | sed 's/\.md$//' >> "$SOURCES_TARGETS"
  # flow sequence references (YAML flow: `wiki/sources/slug.md,`)
  printf '%s\n' "$fm" | grep -oE '[[:space:]]+wiki/[^,]+,?' \
    | sed 's/[[:space:]]*//g; s/,//g; s/\.md$//' >> "$SOURCES_TARGETS"
done < <(grep -rl '^sources:' "$WIKI" --include="*.md" 2>/dev/null)
sort -u "$SOURCES_TARGETS" -o "$SOURCES_TARGETS"

find "$WIKI" -name "*.md" \
  | grep -v '_index\|/index\.md\|/log\.md\|/meta/' \
  | while read -r page; do
      rel="${page#"$VAULT"/}"          # e.g. wiki/concepts/memory-system.md
      rel_noext="${rel%.md}"         # e.g. wiki/concepts/memory-system
      rel_target="${rel_noext#wiki/}"  # e.g. concepts/memory-system — matches INCOMING_TARGETS format
      basename_noext="${rel_noext##*/}"  # e.g. memory-system
      if ! grep -Fxq "$rel_target" "$INCOMING_TARGETS" 2>/dev/null; then
        # Check sources: references — both basename and full path format
        if ! grep -Fxq "$basename_noext" "$SOURCES_TARGETS" 2>/dev/null \
           && ! grep -Fxq "$rel_noext" "$SOURCES_TARGETS" 2>/dev/null; then
          f MEDIUM "Orphan: ${rel}"
          echo "$rel" >> "$ORPHANS"
        fi
      fi
    done

# ── MEDIUM: Missing provenance — concepts + entities ──────────────────────────
# Source pages usan `source:` (URL) y `raw:`, no `sources:` wiki
for dir in "$WIKI/concepts" "$WIKI/entities"; do
  [ -d "$dir" ] || continue
  find "$dir" -name "*.md" | grep -v '_index' | while read -r p; do
    rel="${p#"$VAULT"/}"
    grep -q "^sources:" "$p" || f MEDIUM "No sources: $rel"
    grep -q "^confidence:" "$p" || { f MEDIUM "No confidence: $rel"; echo "$rel" >> "$NO_CONF"; }
  done
done

# ── MEDIUM: Sources without confidence ────────────────────────────────────────
[ -d "$WIKI/sources" ] && \
find "$WIKI/sources" -name "*.md" | grep -v '_index' | while read -r p; do
  grep -q "^confidence:" "$p" || { f MEDIUM "No confidence: ${p#"$VAULT"/}"; echo "${p#"$VAULT"/}" >> "$NO_CONF"; }
done

# ── LOW: Sources without tags ─────────────────────────────────────────────────
[ -d "$WIKI/sources" ] && \
find "$WIKI/sources" -name "*.md" | grep -v '_index' | while read -r p; do
  val=$(grep "^tags:" "$p" 2>/dev/null | head -1)
  { [ -z "$val" ] || [ "$val" = "tags: []" ]; } && f LOW "No tags: ${p#"$VAULT"/}"
done

# ── Frontmatter vs templates/{type}.md ────────────────────────────────────────
# Generic diff against the vault's own templates — HIGH for duplicate keys
# (invalid/ambiguous YAML), MEDIUM for keys the page has that its template
# doesn't (or vice versa). Confidence/tags omissions stay in the dedicated
# checks above (they feed vault-report.json); skip them here to avoid double
# reporting the same gap under two messages.
TEMPLATES="$VAULT/templates"
fm_keys() {  # $1: file -> one frontmatter key per line, duplicates preserved
  awk '
    /^---$/ { c++; next }
    c==1 && $0 ~ /^[A-Za-z_][A-Za-zA-Z0-9_]*:/ { k=$0; sub(/:.*/,"",k); print k }
    c==2 { exit }
  ' "$1" 2>/dev/null
}

tmpl_val_nonempty() {  # $1: template file, $2: key -> "1" if template ships a non-blank default, else "0"
  awk -v key="$2" '
    /^---$/ { c++; next }
    c==1 && $0 ~ "^"key":" {
      v=$0; sub("^"key":[ \t]*","",v); gsub(/[ \t]+$/,"",v)
      print (length(v)>0) ? "1" : "0"; found=1; exit
    }
    c==2 { exit }
    END { if (!found) print "0" }
  ' "$1"
}

if [ -d "$TEMPLATES" ]; then
  find "$WIKI" -name "*.md" \
    | grep -v '_index\|/index\.md\|/log\.md\|/meta/' \
    | while read -r p; do
        rel="${p#"$VAULT"/}"
        keys=$(fm_keys "$p")
        [ -z "$keys" ] && continue  # no frontmatter — already flagged above

        dups=$(echo "$keys" | sort | uniq -d)
        if [ -n "$dups" ]; then
          echo "$dups" | while read -r dk; do
            [ -n "$dk" ] && f HIGH "Duplicate frontmatter key '${dk}' in ${rel}"
          done
        fi

        type=$(grep -m1 "^type:" "$p" | sed 's/^type:[[:space:]]*//' | tr -d '[:space:]')
        tmpl="$TEMPLATES/${type}.md"
        if [ -n "$type" ] && [ -f "$tmpl" ]; then
          tmpl_keys=$(fm_keys "$tmpl" | sort -u)
          page_keys=$(echo "$keys" | sort -u)
          extra=$(comm -23 <(echo "$page_keys") <(echo "$tmpl_keys") | grep -vx 'confidence\|tags')
          missing=$(comm -13 <(echo "$page_keys") <(echo "$tmpl_keys") | grep -vx 'confidence\|tags')
          [ -n "$extra" ] && echo "$extra" | while read -r ek; do
            [ -n "$ek" ] && f MEDIUM "Frontmatter key '${ek}' in ${rel} not in templates/${type}.md"
          done
          [ -n "$missing" ] && echo "$missing" | while read -r mk; do
            [ -z "$mk" ] && continue
            if [ "$(tmpl_val_nonempty "$tmpl" "$mk")" = "1" ]; then
              f MEDIUM "Frontmatter missing key '${mk}' (per templates/${type}.md) in ${rel}"
            else
              f LOW "Frontmatter missing key '${mk}' (optional — blank default in templates/${type}.md) in ${rel}"
            fi
          done
        fi
      done
fi

# ── LOW: Directories with no matching templates/{type}.md ────────────────────
# Structural drift is a user decision, not an auto-fix — informational only.
if [ -d "$TEMPLATES" ]; then
  EXPECTED_DIRS=$(find "$TEMPLATES" -maxdepth 1 -name "*.md" -exec basename {} .md \; \
    | awk '{ if ($0 ~ /y$/) { sub(/y$/,"ies"); print } else print $0 "s" }')
  find "$WIKI" -mindepth 1 -maxdepth 1 -type d ! -name ".*" | while read -r d; do
    dname=$(basename "$d")
    [ "$dname" = "meta" ] && continue
    echo "$EXPECTED_DIRS" | grep -qx "$dname" \
      || f LOW "Carpeta fuera de estructura: wiki/${dname}/ (sin templates/*.md correspondiente — decisión del usuario)"
  done
fi

# ── LOW: index.md section vs page type ───────────────────────────────────────
# Console-only (not persisted to vault-report.json) — same pattern as the
# directory-structure check above. A page is mismatch only if it appears in
# a section that doesn't match its frontmatter `type:` AND is absent from
# its correct section (heuristic A: tolerates intentional cross-references,
# flags pages that live only in the wrong place).
if [ -f "$WIKI/index.md" ]; then
  python3 - "$WIKI" "$INDEX_MISMATCHES" <<'PYEOF'
import re, sys
from pathlib import Path

# sys.argv[1] is $WIKI = $VAULT/wiki; rglob starts from there, so
# relative_to(WIKI) yields "concepts/...", "sources/..." — prefix
# with "wiki/" to match the [[wiki/...]] shape in index.md.
wiki = Path(sys.argv[1])
out = Path(sys.argv[2])
text = (wiki / "index.md").read_text()
section_to_type = {
    "conceptos": "concept", "entities": "entity",
    "entidades": "entity", "fuentes": "source", "sources": "source",
    "proyectos": "project", "projects": "project",
}

current = None
listings = {}
for line in text.splitlines():
    m = re.match(r"^##\s+(\w+)", line)
    if m:
        # Any `##` heading (recognized or not) ends the previous section —
        # otherwise unknown headings like `## Meta` would let their
        # following wikilinks be misattributed to the prior section.
        current = section_to_type.get(m.group(1).lower())
        listings.setdefault(current, set())
    elif current:
        m = re.match(r"^\s*-\s*\[\[(wiki/[^|\]]+)", line)
        if m:
            listings[current].add(m.group(1))

findings = []
for p in sorted(wiki.rglob("*.md")):
    if p.name in ("_index.md", "index.md", "log.md") or "meta" in p.parts:
        continue
    try:
        content = p.read_text()
    except (OSError, UnicodeDecodeError):
        continue
    fm = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
    if not fm: continue
    tm = re.search(r"^type:\s*(\w+)", fm.group(1), re.MULTILINE)
    if not tm: continue
    page_type = tm.group(1)
    rel = re.sub(r"\.md$", "", "wiki/" + str(p.relative_to(wiki)))
    for section_type, paths in listings.items():
        if section_type == page_type: continue
        if rel in paths and rel not in listings.get(page_type, set()):
            findings.append(f"Section/type mismatch: {rel} listed under '{section_type}' (type is '{page_type}')")

out.write_text("\n".join(findings) + ("\n" if findings else ""))
PYEOF
  while IFS= read -r line; do
    [ -n "$line" ] && f LOW "$line"
  done < "$INDEX_MISMATCHES"
fi

# ── Schema validation (delegated) ────────────────────────────────────────────
VALIDATE_SCRIPT="$(dirname "$0")/antu-validate-schema.sh"
if [ -x "$VALIDATE_SCRIPT" ]; then
  "$VALIDATE_SCRIPT" "$VAULT" "$FINDINGS"
else
  echo "WARNING: antu-validate-schema.sh not found next to antu-prune.sh ($VALIDATE_SCRIPT) — schema drift checks skipped. Reinstall the antu-prune skill to restore it." >&2
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
# Canonical schema defined in skills/antu-prune/references/VAULT-REPORT-SCHEMA.md
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
echo "Report written: ${WIKI#"$VAULT"/}/meta/vault-report.json"

[ "$HIGH" -gt 0 ] && exit 1 || exit 0
