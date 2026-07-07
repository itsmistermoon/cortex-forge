---
title: "agentskills.io — Using scripts in skills"
type: source
resource: https://agentskills.io/skill-creation/using-scripts
created: 2026-07-03
updated: 2026-07-03
source_author: agentskills.io
tags: [skills, agent-design, scripts, agentic-cli-design]
aliases: []
confidence: high
schema_version: "0.3"
raw: .raw/agentskills-using-scripts.md
---

# agentskills.io — Using scripts in skills

**URL:** https://agentskills.io/skill-creation/using-scripts
**Author:** agentskills.io (maintainers of the Agent Skills specification)

## Summary

The specification's guidance on when and how to bundle executable scripts inside a skill: `scripts/` is the standard subdirectory for reusable, tested logic, referenced with paths relative to the skill directory root (the agent runs commands from there, so no absolute paths are needed). One-off commands (via `uvx`, `npx`, `go run`, etc.) suffice for simple invocations of existing tools; move to a bundled script once a command grows complex enough to be unreliable on a first attempt. The bulk of the page is about designing script *interfaces* for agentic (non-interactive, context-window-constrained) callers.

## Key ideas

1. **`scripts/` is the standard location, referenced with relative paths from the skill root.** List available scripts in a `## Available scripts` section so the agent knows what exists before reading the full step-by-step instructions — cortex-forge adopted this exact section and placement convention on 2026-07-03 (see [[wiki/projects/cortex-forge]]).
2. **Self-contained scripts declare their own dependencies inline** — PEP 723 for Python (`# /// script` blocks, run via `uv run`), Deno's `npm:`/`jsr:` specifiers, Bun's auto-install, Ruby's `bundler/inline` — so a script runs with a single command, no separate manifest or install step. Not yet adopted in cortex-forge's own scripts (they rely on the caller's Python/bash environment already having dependencies), but a candidate pattern if any future script needs an isolated dependency set.
3. **Avoid interactive prompts — a hard requirement, not a style preference.** Agents run in non-interactive shells; a script that blocks on a TTY prompt hangs indefinitely rather than failing loud. All input must come via flags, env vars, or stdin. Directly reinforces cortex-forge's own fail-loud principle (documented in `wiki/projects/cortex-forge.md`'s Key decisions): a hang is worse than a fast, clear error.
4. **`--help` output is the primary interface documentation an agent reads** — keep it concise (it enters the context window), with a description, flags, and usage examples.
5. **Error messages should state what went wrong, what was expected, and what to try** — an opaque "Error: invalid input" wastes a turn; "Error: --format must be one of: json, csv, table. Received: 'xml'" lets the agent self-correct on the next attempt.
6. **Structured output (JSON/CSV/TSV) over whitespace-aligned text**, with data on stdout and diagnostics/progress on stderr — makes scripts composable with `jq`/`cut`/`awk` and lets the agent capture clean output while still surfacing warnings.
7. **Further considerations for agentic robustness**: idempotency ("create if not exists" survives agent retries better than "create and fail on duplicate"); reject ambiguous input with a clear error instead of guessing; `--dry-run` for destructive operations; distinct, documented exit codes per failure type; explicit confirmation flags (`--confirm`, `--force`) for destructive defaults; predictable output size — default to a summary or a capped limit with `--offset`/`--output` flags, since many agent harnesses truncate output past 10–30K characters and silently lose the tail.

## Connections
- Related concepts: [[wiki/concepts/skill-design-principles]] — informed the 2026-07-03 update adding a script-organization principle; [[wiki/concepts/fail-loud-design]] — the "avoid interactive prompts" and "meaningful exit codes" guidance is the same principle applied to CLI script design rather than session-state writes
- Related sources: [[wiki/sources/agentskills-best-practices]] — companion page; "bundling reusable scripts" there is the decision trigger, this page is the resulting implementation guidance
- Projects: cortex-forge's own `scripts/` migration (2026-07-03, commit `681841b`) predates reading this page in full but matches its `scripts/` + `## Available scripts` convention; the script-design guidance (structured output, exit codes, `--dry-run`) has not yet been audited against cortex-forge's existing scripts (`cortex-prune.sh`, `cortex-sanitize.sh`, `cortex-index.py`, `cortex-search.py`) — candidate follow-up

---

- 2026-07-03 [Claude Code]: Page created
