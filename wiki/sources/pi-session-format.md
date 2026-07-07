---
type: source
title: "Pi Session File Format"
resource: https://pi.dev/docs/latest/session-format
created: 2026-06-16
updated: 2026-06-16
tags: [pi, sessions, jsonl, tree, message-types, sessionmanager, versioning]
aliases: []
confidence: high
schema_version: "0.3"
raw: .raw/pi-session-format.md
---

# Pi Session File Format

**URL:** https://pi.dev/docs/latest/session-format
**Original date:** 2026-06-16
**Author:** Mario Zechner / pi-mono

## Summary

JSONL session format with a tree structure (id/parentId) that enables in-place branching without new files. Documents the file path convention (`~/.pi/agent/sessions/--{path}--/{ts}_{uuid}.jsonl`), the three session versions (v1 linear, v2 tree, v3 renamed `hookMessage` → `custom`), the `AgentMessage` union (UserMessage, AssistantMessage, ToolResultMessage, BashExecutionMessage, CustomMessage, BranchSummaryMessage, CompactionSummaryMessage), the entry types (session, message, model_change, thinking_level_change, compaction, branch_summary, custom, custom_message, label, session_info), and the `SessionManager` static/instance API for programmatic manipulation.

## Key ideas

1. **Tree structure with id/parentId** — first entry has `parentId: null`; each subsequent entry points to its parent. Branching creates new children from an earlier entry; the "leaf" is the current position. `buildSessionContext()` walks from leaf to root, optionally injecting a CompactionEntry summary and converting BranchSummary/CustomMessage entries into the right shape.
2. **Three versions, all auto-migrated** — v1 (linear), v2 (tree), v3 (renamed `hookMessage` role to `custom` for extension unification). Loading a v1 file rewrites it to v3 in place.
3. **Two extension entry kinds** — `CustomEntry` (`type: "custom"`, `customType`, `data`) does **not** enter the LLM context; `CustomMessageEntry` (`type: "custom_message"`, `content`, `display`, `details?`) does. `display: true` shows it in TUI with distinct styling; `display: false` hides it. `details` is per-extension metadata not sent to the LLM.
4. **SessionHeader is metadata-only** — `{ type: "session", version, id, timestamp, cwd, parentSession? }`. Optional `parentSession` is set on `/fork`/`/clone`/`newSession({parentSession})` and points to the source file path.
5. **Assistant message schema is rich** — `content: (TextContent | ThinkingContent | ToolCall)[]`, `api`, `provider`, `model`, `usage: { input, output, cacheRead, cacheWrite, totalTokens, cost: {...} }`, `stopReason: "stop" | "length" | "toolUse" | "error" | "aborted"`, optional `errorMessage`, `timestamp`. Pi auto-detects context overflow and compacts-then-retries.
6. **CompactionEntry stores the bridge** — `{ type: "compaction", summary, firstKeptEntryId, tokensBefore, details?, fromHook? }`. `firstKeptEntryId` is where context resumes after the summary. `details` can carry file tracking (`{readFiles, modifiedFiles}`) for the default implementation.
7. **BashExecutionMessage is the `!cmd`/`!!cmd` record** — `{ command, output, exitCode, cancelled, truncated, fullOutputPath?, excludeFromContext? }`. `excludeFromContext: true` for `!!` (hidden shell). `truncated: true` means the full output lives on disk.
8. **SessionManager API** — static factories (`create`, `open`, `continueRecent`, `inMemory`, `forkFrom`, `list`, `listAll`); append methods (`appendMessage`, `appendThinkingLevelChange`, `appendModelChange`, `appendCompaction`, `appendCustomEntry`, `appendSessionInfo`, `appendCustomMessageEntry`, `appendLabelChange`); tree navigation (`getLeafId`, `getEntry`, `getBranch`, `getTree`, `getChildren`, `branch`, `branchWithSummary`); context/info (`buildSessionContext`, `getEntries`, `getHeader`, `getSessionName`, `getCwd`, `getSessionDir`, `getSessionId`, `getSessionFile`, `isPersisted`).

## Connections
- Related concepts: [[wiki/concepts/pi-extension-lifecycle]]
- Projects: [[wiki/entities/pi-cli]]
- Sources: [[wiki/sources/pi-usage]], [[wiki/sources/pi-extensions]], [[wiki/sources/pi-terminal-setup]]

---

- 2026-06-16 [CommandCode]: Page created
