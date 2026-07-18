#!/bin/bash
# sanitize.sh — Scan content for injection, exfiltration, and credential vectors.
# Usage: bash sanitize.sh <file> (co-located with the wiki-ingest skill)
# Outputs JSON with findings array. Exit 0 always (fail-open).
# Designed to be called by wiki-ingest before saving to .raw/.
#
# SECURITY INVARIANT: credential-pattern matches are redacted IN THE FILE ITSELF
# before this script returns — not merely reported. This is a mechanism, not an
# instruction: wiki-ingest (or a user insisting the real value is needed)
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

# ── Informational checks — same shape each time: count matches, append a finding ──
_finding() {  # $1: rg pattern, $2: type, $3: label
  local pattern="$1" type="$2" label="$3" n
  n=$(rg -c -- "$pattern" "$FILE" 2>/dev/null || echo 0)
  [ -n "$n" ] && [ "$n" -gt 0 ] 2>/dev/null || return 0
  FINDINGS=$(printf '%s' "$FINDINGS" | jq -c --arg n "$n" --arg type "$type" --arg label "$label" '. + [{"type":$type,"label":$label,"count":($n|tonumber)}]')
}

_finding $'[\u200b\u200c\u200d\u2060\u2061\u2062\u2063\u2064\u2066\u2067\u2068\u2069\u202a\u202b\u202c\u202d\u202e\ufffe\uffff]' "invisible_unicode" "Zero-width / bidi characters"
_finding '<!--{1,}.*?--{1,}>' "html_comment" "HTML comments — possible hidden instructions"
_finding '[A-Za-z0-9+/]{80,}={0,2}' "base64" "Long base64 strings — possible embedded payload"
_finding '(curl|wget|fetch|http.?get)\s+https?://' "egress_command" "Egress commands — curl/wget to external hosts"
_finding 'ANTHROPIC_BASE_URL' "anthropic_base_url" "ANTHROPIC_BASE_URL — possible injection target"

# ── Credentials — detected AND redacted in place, never just reported ────────
# Patterns mirror hot-handoff/SKILL.md's own redaction rule (sk-*, Bearer *,
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
