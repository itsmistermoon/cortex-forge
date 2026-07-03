#!/bin/bash
# cortex-sanitize.sh — Scan content for injection, exfiltration, and credential vectors.
# Usage: bash cortex-sanitize.sh <file> (co-located with the cortex-assimilate skill)
# Outputs JSON with findings array. Exit 0 always (fail-open).
# Designed to be called by cortex-assimilate before saving to .raw/.
#
# SECURITY INVARIANT: credential-pattern matches are redacted IN THE FILE ITSELF
# before this script returns — not merely reported. This is a mechanism, not an
# instruction: cortex-assimilate (or a user insisting the real value is needed)
# has no way to opt out, because by the time the caller sees the findings, the
# secret is already gone from disk. Never add a flag to disable this.

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
command -v jq >/dev/null 2>&1 || {
  echo '{"file":"'"$FILE"'","findings":[],"note":"jq not available — scan skipped"}'
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

# ── Credentials — detected AND redacted in place, never just reported ────────
# Patterns mirror cortex-crystallize/SKILL.md's own redaction rule (sk-*, Bearer *,
# ghp_*, ?token=*) plus AWS access key IDs (AKIA...) and basic-auth-style
# user:pass in URLs/flags — all common in scraped tech content.
REDACTED=0
_redact() {  # $1: ERE pattern (BRE-safe, no PCRE features)
  # `--` before the pattern is load-bearing: without it, patterns starting
  # with `-` (e.g. "--password...", "-u ...") get parsed as rg/sed flags
  # instead of the pattern itself, and silently fail to match anything.
  local pattern="$1" n tmp
  n=$(rg -c -- "$pattern" "$FILE" 2>/dev/null || echo 0)
  [ -n "$n" ] && [ "$n" -gt 0 ] 2>/dev/null || return 0
  tmp=$(mktemp) || return 0
  sed -E -- "s/${pattern}/<REDACTED>/g" "$FILE" > "$tmp" && mv "$tmp" "$FILE"
  REDACTED=$((REDACTED + n))
}
_redact 'sk-[A-Za-z0-9_-]{16,}'
_redact 'Bearer [A-Za-z0-9._-]{10,}'
_redact 'ghp_[A-Za-z0-9]{20,}'
_redact '(\?|&)token=[^&[:space:]"'"'"'<>]+'
_redact 'AKIA[0-9A-Z]{16}'
_redact '--password[= ][^[:space:]]+'
_redact '-u [^:[:space:]]+:[^@[:space:]]+'

if [ "$REDACTED" -gt 0 ]; then
  FINDINGS=$(printf '%s' "$FINDINGS" | jq -c --arg n "$REDACTED" '. + [{"type":"credential","label":"Credentials found and redacted in place (not optional, not user-overridable)","count":($n|tonumber),"redacted":true}]')
fi

# ── Output ────────────────────────────────────────────────────────────────────
jq -cn --arg file "$FILE" --argjson findings "$FINDINGS" --argjson redacted "$([ "$REDACTED" -gt 0 ] && echo true || echo false)" '{
  file: $file,
  findings: $findings,
  total: ($findings | length),
  redacted: $redacted
}'
exit 0
