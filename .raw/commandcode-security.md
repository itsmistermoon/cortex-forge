# Security & Privacy — Command Code Official Docs

**URL:** https://commandcode.ai/docs/resources/security
**Fetched:** 2026-06-13

## Your Data

| What | Stored? | Where | Used for training? |
|------|---------|-------|--------------------|
| Source code | Never stored | Your machine only | No |
| Taste profile | Local + optional cloud sync | `.commandcode/taste/` and `commandcode.ai` | No |
| Conversation history | Local only | `~/.commandcode/projects/` | No |
| Authentication tokens | Local only | `~/.commandcode/auth.json` | No |
| AGENTS.md | Local only | Project root | No |

Privacy: Command Code does not train on your code. Taste learning runs locally and stores preferences as structured rules — not code snippets.

## Permission Model

By default, any action that modifies your system requires explicit approval.

### Permission Modes

| Mode | File reads | File writes | Shell commands | When to use |
|------|-----------|-------------|----------------|-------------|
| **Default** | Allowed | Requires approval | Requires approval | Day-to-day work |
| **Plan** | Allowed | Blocked | Blocked | Exploring and designing |
| **Auto-Accept** | Allowed | Allowed | Allowed | Trusted iteration |

Switch modes: `shift+tab` inside session, or start with:
- `cmd --plan`
- `cmd --auto-accept`
- `cmd --permission-mode auto-accept`

### Project Trust

First time `cmd` runs in a project, it asks whether to trust that directory. Skip with `cmd --trust`.

## Headless Mode Permissions

When running in headless mode (`cmd -p`), **all write operations are blocked by default**. This keeps CI/CD pipelines and scripts safe.

To enable writes in headless mode, pass `--yolo`:
```
cmd -p "fix lint errors" --yolo
```

`--dangerously-skip-permissions` is also accepted as an alias.

Warning: Only use `--yolo` in trusted environments like your own CI pipelines.

## Network Access

Connects for:
- API requests to AI provider (Command Code or Anthropic)
- Authentication via OAuth (during `cmd login`)
- Taste sync when you push/pull taste profiles
- MCP servers you explicitly configure

Does NOT make network requests for telemetry or tracking without knowledge.

## Local File Access

Only accesses files within:
1. Current project directory
2. Additional directories added with `--add-dir` or `/add-dir`
3. Command Code config in `~/.commandcode/`

## API Key Storage

Credentials stored at `~/.commandcode/auth.json`. Never sent to third parties.
BYOK (Anthropic) uses environment variables — not persisted by Command Code.

## MCP Server Security

- MCP tools can access external services
- Each MCP server requires explicit setup via `cmd mcp add`
- OAuth tokens stored locally
- Review with `cmd mcp list` or `/mcp`

## Checkpoints as Safety Nets

Checkpoints created before every file modification. Restore with `Esc` twice.
Stored locally and per-session.

## Enterprise

Self-hosted deployment, code never leaves infrastructure, custom security policies.
Contact support@commandcode.ai.
