---
type: source
title: "Antigravity CLI — Sandbox"
resource: https://antigravity.google/docs/cli-sandbox
section: Antigravity CLI / Agent Capabilities
created: 2026-06-08
updated: 2026-06-08
tags: [antigravity, cli, sandbox, security]
confidence: high
schema_version: "0.3"
raw: .raw/antigravity-cli/cli-sandbox.md
---

# Sandbox

Native OS-level process isolation to restrict destructive shell operations and unauthorized network calls. Activated via `enableTerminalSandbox: true` in `~/.gemini/antigravity-cli/settings.json`. Zero execution overhead — no VMs, no heavy containers.

## Platform utilities

| OS | Utility | Security characteristic |
|---|---|---|
| Linux | `nsjail` | Kernel namespaces + cgroups; CPU, memory, path visibility confinement |
| macOS | `sandbox-exec` | Native policy profiles; restricts absolute FS access + raw TCP |
| Windows | `AppContainer` | Desktop security ring; FS permissions + registry isolation |

## Activation

```json
{
  "enableTerminalSandbox": true
}
```

- **`enableTerminalSandbox`** (boolean, default `false`): restricts all agent terminal commands to OS containment rings.

## Interactive approval flow

When the agent attempts a terminal tool, the prompt adapts to sandbox state:

- **Sandbox enabled** — TUI offers a temporary escape option:
  ```text
  Do you want to proceed?
  1. Yes
  2. Yes, and run without sandbox restrictions
  3. No
  ```
  Option 2 bypasses the barrier for that single execution only.
- **Sandbox disabled** — TUI offers containment for a risky command:
  ```text
  Do you want to proceed?
  1. Yes
  2. Yes, and run in sandbox
  3. No
  ```

## See also

- [Permissions](./antigravity-cli-permissions.md) — fine-grained allow/deny rules
- [Plugins & Skills](./antigravity-cli-plugins.md) — slash commands
- [Settings](./antigravity-cli-settings.md) — keyboard + buffer customization
