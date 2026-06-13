# CommandCode Headless Mode — Official Docs

**URL:** https://commandcode.ai/docs/core-concepts/headless
**Fetched:** 2026-06-12

## Basic Usage

`-p` (or `--print`) flag runs headless mode. Multi-turn tool execution supported, up to 10 turns by default.

## Sessions & Resuming

Each headless run persists its transcript to disk. Headless sessions are tagged separately and stay hidden from interactive /resume menu and interactive --continue.

- `--continue` / `-c`: resumes most recent headless session in current directory. If no session exists, starts fresh.
- `--resume <id>`: resume specific session by id. No bare picker in headless mode.
- `--verbose`: prints session id to stderr for chaining --resume.
- Interactive resume of headless session: `cmd --resume <id>` (without -p).

## Permissions

By default headless mode blocks file writes, edits, and shell commands. Use --yolo to allow all tools.

## Exit Codes

0=success, 1=general error, 3=not authenticated, 4=permission denied, 5=rate limited, 6=network failure, 7=API server error, 130=SIGINT/SIGTERM.

## Related Flags

--max-turns (default 10), --yolo, --auto-accept, --skip-onboarding, -t/--trust, --plan, --permission-mode.

## Limitations

No interactive prompts, no resume picker in print mode, stdin timeout after 30s.
