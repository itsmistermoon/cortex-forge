# CommandCode Hooks Reference — Official Docs

**URL:** https://commandcode.ai/docs/hooks/reference
**Fetched:** 2026-06-12

## Settings Schema

Hooks are configured under the `hooks` key in `settings.json`. Two-level nesting: HookDefinition (matcher + list of handlers) and HookEntry (type + command + timeout).

HookDefinition fields: matcher (optional string, e.g. "shell" or "write|edit"), hooks (required array of handlers).
HookEntry fields: type (required, supports "command"), command (required when type: "command"), timeout (optional, default 30s, max 600s).

Example settings.json with PreToolUse scope to shell|write (10s timeout) and PostToolUse without timeout.

## Hook Input (stdin)

Common fields on all events: session_id, transcript_path (absolute path to this session's transcript JSONL), cwd, hook_event_name, permission_mode.

Tool-call fields: tool_use_id, tool_name (shell_command, read_file, write_file, edit_file), tool_display_name (SHELL, READ, WRITE, EDIT), tool_input (shape depends on tool).

tool_input fields per tool:
- shell_command: command (string), args (string[]?), directory (string?), timeout (number?)
- read_file: absolute_path (string), offset (number?), limit (number?)
- write_file: file_path (string), content (string)
- edit_file: file_path (string), old_value (string), new_value (string), replacement_count (number?), replace_all (boolean?)

Event-specific fields:
- PostToolUse: tool_response (string) — tool output
- Stop: stop_hook_active (boolean) — true on retry fire

## Environment Variables

Four env vars injected into every hook process:
- COMMANDCODE_PROJECT_DIR — absolute path to project (same as cwd)
- COMMANDCODE_SESSION_ID — session ID for correlating hooks
- COMMANDCODE_HOOK_EVENT — PreToolUse, PostToolUse, or Stop
- COMMANDCODE_CWD — alias of COMMANDCODE_PROJECT_DIR

## Hook Output (stdout)

Common fields: continue (boolean), stopReason (string), suppressOutput (boolean), systemMessage (string).

PreToolUseOutput adds hookSpecificOutput: hookEventName, permissionDecision ("allow"|"deny"), permissionDecisionReason, additionalContext.

PostToolUseOutput adds top-level decision ("block") / reason and hookSpecificOutput: hookEventName, additionalContext.

StopOutput: only top-level fields — decision ("block"), reason. No hookSpecificOutput.

Stop loop prevention: stop_hook_active on retry fires; hard cap of 3 retries per turn.

## Exit Codes

0: parsed as JSON, behavior determined by output fields.
2: PreToolUse blocks, PostToolUse advisory retry, Stop retries turn.
Other: tool proceeds, non-blocking error logged.

## Execution Semantics

- PreToolUse: sequential, stops on first denial.
- PostToolUse and Stop: parallel.
- Each hook receives isolated stdin.

## Permission Modes

standard, auto-accept, plan (hooks skipped entirely in plan mode).

## Example Script

Full guard-shell.sh example showing stdin parsing, env var usage, denial with permissionDecisionReason, and allow with additionalContext.
