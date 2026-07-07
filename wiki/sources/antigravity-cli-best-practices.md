---
type: source
title: "Antigravity CLI — Best Practices"
resource: https://antigravity.google/docs/cli-best-practices
created: 2026-06-08
updated: 2026-06-08
tags: [antigravity, cli, best-practices]
confidence: high
schema_version: "0.3"
raw: .raw/antigravity-cli/cli-best-practices.md
---

# Best practices for Antigravity CLI

Workflow patterns, prompt architectures, and local configuration choices to maximize agent velocity while keeping control.

## 1. Establish verification loops

The single most effective way to ensure reliable modifications is a local verification mechanism (unit tests, build commands, formatting scripts).

Before asking for a code change:
1. Ensure workspace has a test suite ready.
2. If no tests, direct the agent to write a standard test block _first_.
3. After code is proposed, instruct the agent to run the local test command to verify.
4. Watch it execute and iterate on outputs automatically.

```text
> Implement feature X in main.py. Run npm test afterward to verify the build.
```

## 2. Explore, plan, then execute

Partition complex changes into distinct phases:
- **Exploration**: ask the agent to explain how the target codebase resolves a problem or where an interface is defined.
- **Planning**: request an implementation plan — targeted files, dependencies, logic overrides in a plan artifact.
- **Execution**: approve the plan, then direct edits.

```text
> Explore how our router resolves `/docs/:page`. Write down an implementation plan to add `/docs/best-practices`.
```

## 3. Enrich your prompting context

### Target file autocompletion

Type `@` in the prompt box → **Interactive Path Suggestion** overlay. Selecting a path imports the absolute workspace file path into the prompt.

### Attaching visual evidence

Capture a screenshot or video, copy it, press `ctrl+v` in the prompt box. The agent consults the media file to diagnose.

## 4. Configure your workspace environment

### Codebase rule files

Create `GEMINI.md` or `AGENTS.md` at workspace root — directory standards, styling paradigms, test command parameters, deprecation warnings. Auto-parsed on startup.

### Structured permissions

Tune `~/.gemini/antigravity-cli/settings.json` based on project risk:

- **`request-review`** (default): prompts before writes, bash, network.
- **`proceed-in-sandbox`**: safe commands run autonomously, risky ones prompt.
- **`strict`**: prompts for all non-read operations, line-by-line transparency.

```json
{
  "toolPermission": "proceed-in-sandbox",
  "enableTerminalSandbox": true
}
```

## 5. Manage TUI sessions proactively

### Course-correct early (`esc`)

Press `esc` to interrupt a turn and regain a clean prompt if the agent goes off-track.

### Rewind history with `/rewind`

Type `/rewind` (alias `/undo`) to roll back the conversation thread to a previous stable checkout.

### Branch experiments with `/fork`

1. Reach a stable baseline.
2. `/fork` → duplicate parallel session.
3. Test speculative modifications in the branch.
4. If the approach fails, `/resume` to swap back.

## 6. Automate and script

### Non-interactive commands (`-p`)

```bash
agy -p "Review this git diff and draft a conventional commit message" --cwd $(pwd)
```

### Fan out using parallel subagents

Direct the primary agent to spawn concurrent background subagents. The agent manager handles background threads autonomously.

## See also

- [Settings, Rendering & Keybindings](./antigravity-cli-settings.md)
- [Permissions & Sandbox](./antigravity-cli-sandbox.md)
- [Plugins & Skills](./antigravity-cli-plugins.md)
