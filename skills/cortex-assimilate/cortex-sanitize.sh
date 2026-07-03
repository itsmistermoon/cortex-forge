#!/bin/bash
# cortex-sanitize.sh — Scan content for injection and exfiltration vectors.
# Usage: bash cortex-sanitize.sh <file> (co-located with the cortex-assimilate skill)
# Outputs JSON with findings array. Exit 0 always (fail-open).
# Designed to be called by cortex-assimilate before saving to .raw/.

set -uo pipefail

FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo '{"file":"","findings":[],"error":"file not found"}'
  exit 0
fi

command -v rg >/dev/null 2>&1 || {
  echo '{"file":"'"$FILE"'","findings":[],"note":"rg not available — scan skipped"}'
  exit 0
}

FINDINGS="[]"

# ── Zero-width / bidi Unicode ────────────────────────────────────────────────
ZW=$(rg -c $'[\u200b\u200c\u200d\u2060\u2061\u2062\u2063\u2064\u2066\u2067\u2068\u2069\u202a\u202b\u202c\u202d\u202e\ufffe\uffff]' "$FILE" 2>/dev/null)
if [ -n "$ZW" ] && [ "$ZW" -gt 0 ] 2>/dev/null; then
  FINDINGS=$(printf '%s' "$FINDINGS" | jq -c --arg n "$ZW" '. + [{"type":"invisible_unicode","label":"Zero-width / bidi characters","count":($n|tonumber)}]')
fi

# ── HTML comments (<!-- -->) ─────────────────────────────────────────────────
HC=$(rg -c '<!--{1,}.*?--{1,}>' "$FILE" 2>/dev/null || echo 0)
if [ -n "$HC" ] && [ "$HC" -gt 0 ] 2>/dev/null; then
  FINDINGS=$(printf '%s' "$FINDINGS" | jq -c --arg n "$HC" '. + [{"type":"html_comment","label":"HTML comments — possible hidden instructions","count":($n|tonumber)}]')
fi

# ── Long base64 strings (>=80 chars, potential payload) ──────────────────────
B64=$(rg -c '[A-Za-z0-9+/]{80,}={0,2}' "$FILE" 2>/dev/null || echo 0)
if [ -n "$B64" ] && [ "$B64" -gt 0 ] 2>/dev/null; then
  FINDINGS=$(printf '%s' "$FINDINGS" | jq -c --arg n "$B64" '. + [{"type":"base64","label":"Long base64 strings — possible embedded payload","count":($n|tonumber)}]')
fi

# ── Egress commands (curl|wget to external hosts) ────────────────────────────
EGRESS=$(rg -cn '(curl|wget|fetch|http.?get)\s+https?://' "$FILE" 2>/dev/null || echo 0)
if [ -n "$EGRESS" ] && [ "$EGRESS" -gt 0 ] 2>/dev/null; then
  FINDINGS=$(printf '%s' "$FINDINGS" | jq -c --arg n "$EGRESS" '. + [{"type":"egress_command","label":"Egress commands — curl/wget to external hosts","count":($n|tonumber)}]')
fi

# ── ANTHROPIC_BASE_URL (injection target) ────────────────────────────────────
ABU=$(rg -c 'ANTHROPIC_BASE_URL' "$FILE" 2>/dev/null || echo 0)
if [ -n "$ABU" ] && [ "$ABU" -gt 0 ] 2>/dev/null; then
  FINDINGS=$(printf '%s' "$FINDINGS" | jq -c --arg n "$ABU" '. + [{"type":"anthropic_base_url","label":"ANTHROPIC_BASE_URL — possible injection target","count":($n|tonumber)}]')
fi

# ── Output ────────────────────────────────────────────────────────────────────
jq -cn --arg file "$FILE" --argjson findings "$FINDINGS" '{
  file: $file,
  findings: $findings,
  total: ($findings | length)
}'
exit 0
