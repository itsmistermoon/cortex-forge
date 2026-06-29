#!/bin/bash
# Codex Stop hook.
#
# Codex Stop is turn-scoped and expects valid JSON on stdout. The previous
# wrapper delegated to the Claude transcript parser and could fail or spam the
# conversation. Keep this hook non-blocking; use /cortex-crystallize for actual
# session snapshots from Codex.

set -uo pipefail

cat >/dev/null 2>&1 || true

# Valid no-op structured output for Codex hooks.
printf '{}\n'
