#!/bin/bash
# Codex SessionStart hook.
#
# Codex renders SessionStart additionalContext directly in the chat UI, so the
# shared cortex-reactivate.sh behavior is too noisy here. AGENTS.md remains the
# authoritative instruction to load .cortex/MEMORY.md before the first response.

set -uo pipefail

cat >/dev/null 2>&1 || true

# Valid no-op structured output for Codex hooks.
printf '{}\n'
