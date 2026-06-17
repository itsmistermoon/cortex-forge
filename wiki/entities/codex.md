---
title: Codex CLI
type: entity
created: 2026-06-16
updated: 2026-06-16
tags: [codex, openai, agent, hooks, cli]
aliases: [Codex, OpenAI Codex CLI]
sources:
  - wiki/sources/codex-hooks.md
confidence: high
schema_version: "0.3"
---

# Codex CLI

Codex CLI is OpenAI's terminal-first AI coding agent and one of the four agents with full Cortex Forge hook support alongside Claude Code, Antigravity CLI, and CommandCode. It supports a lifecycle hook system with matcher-based routing, structured JSON outputs, and explicit trust review for non-managed hooks.

## Hook system

- **Events:** `SessionStart`, `SessionEnd`, `PreToolUse`, `PostToolUse`, `SubagentStop`, `Stop`, `PromptSubmit`, `Compaction`
- **Config:** `~/.codex/hooks.json` (global) or `.codex/hooks.json` (project-local, requires trust)
- **Wire format:** flat JSON — same structure as Claude Code; compatible with Cortex Forge hook scripts without modification
- **Trust model:** non-managed hooks require explicit `/hooks` review before first execution; managed (policy-trusted) hooks are not user-disableable
- **Stop event:** does not use `matcher`; expects JSON stdout on exit 0, or exit 2 with continuation reason on stderr
- `transcript_path` available in hook input as a convenience field (format not a stable interface)

## Cortex Forge integration

- **Skills:** global install via `cortex-forge-setup` to `~/.codex/` (AGENTS.md instructions)
- **Hooks:** `SessionStart` → `cortex-reactivate.sh`; `Stop` → `cortex-crystallize-codex.sh`
- **Note:** hook scripts must live in a stable global path (`~/.codex/hooks/`) and resolve the active vault at runtime — vault-local paths break multi-vault setups
- **Validation status:** Capa 2 hooks installed, end-to-end validation in organic session pending (see AGENT-LOG)

## Relationships
- Comparable agents: [[wiki/entities/commandcode]], [[wiki/entities/antigravity-cli]], [[wiki/entities/pi-cli]]
- Concepts: [[wiki/concepts/agent-hook-compatibility]]

---

- 2026-06-16 [Claude Code]: Page created from cortex-prune check 2c — codex-hooks.md had no covering entity page
