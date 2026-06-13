---
title: Headless Mode - Command Code
type: source
created: 2026-06-12
updated: 2026-06-12
tags: [commandcode, headless, sessions, transcripts, resume]
source_url: https://commandcode.ai/docs/core-concepts/headless
source_date: 2026-06-12
source_author: CommandCode
sources:
  - .raw/commandcode-headless.md
confidence: high
---

# Headless Mode - Command Code

**URL:** https://commandcode.ai/docs/core-concepts/headless
**Author:** CommandCode

## Summary

Official documentation for CommandCode's headless mode (`-p`/`--print`). Covers multi-turn execution, session persistence, session resuming, permissions, exit codes, and limitations.

## Key findings for cortex-forge

1. **Each headless run persists its transcript to disk** — confirmed. Headless sessions are tagged separately from interactive ones.
2. **Resume by session ID**: `--resume <uuid>` or `--continue` for most recent. The session ID is output via `--verbose` to stderr.
3. **Interactive resume of headless session**: `cmd --resume <uuid>` (without `-p`) loads a headless transcript into interactive mode.
4. **Transcript path on disk**: confirmed via filesystem inspection at `~/.commandcode/projects/{project-slug}/{session-uuid}.jsonl`. The hook input `transcript_path` field provides this directly at runtime.
5. **Retention**: no documented retention period in official docs. Filesystem inspection shows sessions dating back to June 7 (at least 5 days). Retention appears to be indefinite or based on disk pressure.

## Connections
- Related concepts: [[wiki/concepts/agent-hook-compatibility]]
- Projects: [[wiki/pages/cortex-forge]]
- Sources: [[wiki/sources/commandcode-hooks-configuration]], [[wiki/sources/commandcode-hooks-reference]]

---

- 2026-06-12 [CommandCode]: Page created — ingested to resolve CommandCode transcript location for pipeline imprint design
