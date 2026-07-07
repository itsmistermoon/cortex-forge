---
title: Hooks Reference - Command Code
type: source
resource: https://commandcode.ai/docs/hooks/reference
created: 2026-06-12
updated: 2026-06-12
tags: [commandcode, hooks, reference, wire-format, transcript-path]
aliases: []
source_author: CommandCode
confidence: high
schema_version: "0.3"
raw: .raw/commandcode-hooks-reference.md
---

# Hooks Reference - Command Code

**URL:** https://commandcode.ai/docs/hooks/reference
**Original date:** 2026-06-12
**Author:** CommandCode

## Summary

Complete technical reference for the CommandCode hooks system. Covers settings schema, hook input/output wire formats, exit codes, execution semantics, and the permission modes table.

## Key findings for cortex-forge

1. **`transcript_path` is a common field** on every hook event — absolute path to the session's JSONL transcript. Available on stdin for any hook to read.
2. **Transcript format confirmed JSONL** — the hook input explicitly documents `transcript_path` as "Absolute path to this session's transcript JSONL".
3. **Environment variables**: `COMMANDCODE_PROJECT_DIR`, `COMMANDCODE_SESSION_ID`, `COMMANDCODE_HOOK_EVENT`, `COMMANDCODE_CWD` are injected into every hook process — useful for hook scripts to self-identify without parsing stdin.
4. **Plan mode disables hooks entirely** — the crystallize Stop hook does not fire when closing a planning session. Confirmed by official docs.
5. **No additional system fields** beyond what was already documented in `agent-hook-compatibility.md`. The wire format is stable as captured.

## Connections
- Related concepts: [[wiki/concepts/agent-hook-compatibility]]
- Projects: [[wiki/projects/cortex-forge]]
- Sources: [[wiki/sources/commandcode-hooks-configuration]], [[wiki/sources/commandcode-hooks-examples]], [[wiki/sources/commandcode-hooks-best-practices]]

---

- 2026-06-12 [CommandCode]: Page created — ingested from official docs to resolve transcript_path field semantics
