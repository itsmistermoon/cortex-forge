#!/bin/bash
# Codex Stop hook wrapper: delegates to the shared crystallize hook logic.
# Keeps Codex-specific hook paths stable while reusing the Claude-compatible
# snapshot implementation with Codex-specific labels and transcript search.

set -uo pipefail

export AGENT_LABEL="Codex"
export TRANSCRIPT_FALLBACK_DIRS="${TRANSCRIPT_FALLBACK_DIRS:-$HOME/.codex/projects:$HOME/.claude/projects}"

exec "$(dirname "$0")/cortex-crystallize-claude.sh"
