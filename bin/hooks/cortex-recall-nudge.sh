#!/bin/bash
# cortex-recall-nudge.sh — PreToolUse hook (Bash matcher only, v1: Claude Code only)
# Nudges toward /cortex-recall when a Bash search command targets vault content
# (wiki/ or .raw/). Once per session. Every branch fails open (exit 0).
#
# Scope note: covers the Bash-search bypass only. The no-tool-call parametric
# bypass (agent answers from active context) remains covered solely by the
# AGENTS.md compliance criteria.
# jq note: bin/hooks/ scripts are exempt from the no-jq constraint in
# bin/cortex-prune.sh — guarded by command -v, fail-open.

set -u

command -v jq >/dev/null 2>&1 || exit 0

PAYLOAD=$(cat 2>/dev/null) || exit 0
[ -n "$PAYLOAD" ] || exit 0

SESSION_ID=$(printf '%s' "$PAYLOAD" | jq -r '.session_id // empty' 2>/dev/null) || exit 0
CMD=$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -n "$CMD" ] || exit 0

# Once-per-session throttle
MARKER="/tmp/cortex-recall-nudge-${SESSION_ID:-nosession}"
[ -f "$MARKER" ] && exit 0

# Match: search command that plausibly targets vault content
printf '%s' "$CMD" | grep -qE '(^|[ |;&(])(grep|rg|fd|find|ack|ag)([ ]|$)' || exit 0
printf '%s' "$CMD" | grep -qE '(wiki/|\.raw/)' || exit 0

# Inertness gate: CWD inside a registered vault that has a wiki index
CONFIG="$HOME/.cortex-forge/config.yml"
[ -f "$CONFIG" ] || exit 0
IN_VAULT=""
while IFS= read -r raw_path; do
  path="${raw_path/#\~/$HOME}"
  [ -n "$path" ] || continue
  case "$PWD/" in
    "$path"/*) IN_VAULT="$path" ;;
  esac
done < <(sed -n 's/^[[:space:]]\{1,\}[A-Za-z0-9_-]*:[[:space:]]*//p' "$CONFIG" 2>/dev/null)
[ -n "$IN_VAULT" ] || exit 0
[ -f "$IN_VAULT/wiki/index.md" ] || exit 0

touch "$MARKER" 2>/dev/null || true

MSG="Cortex Forge: this vault has synthesized knowledge. Before grepping wiki/ or .raw/ to answer a content question, invoke /cortex-recall — it returns compiled pages with citations. Grep directly only after recall has oriented you, or to verify/edit specific lines. This rule applies to subagents too — include it in any subagent prompt that searches vault content."

jq -cn --arg msg "$MSG" '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$msg}}' 2>/dev/null || exit 0
exit 0
