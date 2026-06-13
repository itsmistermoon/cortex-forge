# The Shorthand Guide to Everything Claude Code

Author: cogsec (@affaan) — X/Twitter, 2026-01-17
Source: pasted by user (thread on X). Ganador hackathon Anthropic x Forum Ventures (Zenith/PMFProbe).

---

Here's my complete setup after 10 months of daily use: skills, hooks, subagents, MCPs, plugins, and what actually works.

## Skills and Commands

Skills operate like rules, constricted to certain scopes and workflows. They're shorthand to prompts when you need to execute a particular workflow.

After a long session of coding with Opus 4.5, you want to clean out dead code and loose .md files? Run /refactor-clean. Need testing? /tdd, /e2e, /test-coverage. Skills and commands can be chained together in a single prompt.

I can make a skill that updates codemaps at checkpoints - a way for Claude to quickly navigate your codebase without burning context on exploration. (~/.claude/skills/codemap-updater.md)

Commands are skills executed via slash commands. They overlap but are stored differently:
- Skills: ~/.claude/skills - broader workflow definitions
- Commands: ~/.claude/commands - quick executable prompts

```
~/.claude/skills/
  pmx-guidelines.md      # Project-specific patterns
  coding-standards.md    # Language best practices
  tdd-workflow/          # Multi-file skill with README.md
  security-review/       # Checklist-based skill
```

## Hooks

Hooks are trigger-based automations that fire on specific events. Unlike skills, they're constricted to tool calls and lifecycle events.

Hook types: PreToolUse (validation, reminders), PostToolUse (formatting, feedback loops), UserPromptSubmit, Stop, PreCompact, Notification (permission requests).

Example: tmux reminder before long-running commands:

```json
{
  "PreToolUse": [
    {
      "matcher": "tool == \"Bash\" && tool_input.command matches \"(npm|pnpm|yarn|cargo|pytest)\"",
      "hooks": [
        {
          "type": "command",
          "command": "if [ -z \"$TMUX\" ]; then echo '[Hook] Consider tmux for session persistence' >&2; fi"
        }
      ]
    }
  ]
}
```

Pro tip: Use the `hookify` plugin to create hooks conversationally instead of writing JSON manually. Run /hookify and describe what you want.

## Subagents

Subagents are processes your orchestrator (main Claude) can delegate tasks to with limited scopes. They can run in background or foreground, freeing up context for the main agent.

Subagents work nicely with skills - a subagent capable of executing a subset of your skills can be delegated tasks and use those skills autonomously. They can also be sandboxed with specific tool permissions.

```
~/.claude/agents/
  planner.md, architect.md, tdd-guide.md, code-reviewer.md,
  security-reviewer.md, build-error-resolver.md, e2e-runner.md,
  refactor-cleaner.md, doc-updater.md
```

Configure allowed tools, MCPs, and permissions per subagent for proper scoping.

## Rules and Memory

Your `.rules` folder holds `.md` files with best practices Claude should ALWAYS follow. Two approaches:
1. Single CLAUDE.md - Everything in one file (user or project level)
2. Rules folder - Modular `.md` files grouped by concern

```
~/.claude/rules/
  security.md, coding-style.md, testing.md, git-workflow.md,
  agents.md (when to delegate to subagents), performance.md (model selection), patterns.md, hooks.md
```

Example rules: no emojis in codebase; refrain from purple hues in frontend; always test before deployment; modular code over mega-files; never commit console.logs.

## MCPs (Model Context Protocol)

MCPs connect Claude to external services directly. Not a replacement for APIs - a prompt-driven wrapper around them. Example: Supabase MCP lets Claude pull data and run SQL directly. Chrome in Claude: built-in plugin MCP for autonomous browser control.

### CRITICAL: Context Window Management

Be picky with MCPs. Keep all MCPs in user config but disable everything unused (/plugins, /mcp).

**Your 200k context window before compacting might only be 70k with too many tools enabled. Performance degrades significantly.**

Rule of thumb: 20-30 MCPs in config, but keep under 10 enabled / under 80 tools active.

Disabled per project: in `~/.claude.json` under `projects.[path].disabledMcpServers`. "I have 14 MCPs configured but only ~5-6 enabled per project. Keeps context window healthy."

## Plugins

Plugins package tools for easy installation. A plugin can be a skill + MCP combined, or hooks/tools bundled.

```
claude plugin marketplace add https://github.com/mixedbread-ai/mgrep
```

LSP plugins (typescript-lsp, pyright-lsp): real-time type checking, go-to-definition without an IDE open. Same context-window warning as MCPs.

Installed plugins (4-5 enabled at a time): ralph-wiggum (loop automation), frontend-design, commit-commands, security-guidance, pr-review-toolkit, typescript-lsp, hookify, code-simplifier, feature-dev, explanatory-output-style, code-review, context7 (live documentation), pyright-lsp, mgrep.

## Tips and Tricks

Keyboard shortcuts: Ctrl+U delete line; ! bash prefix; @ file search; / slash commands; Shift+Enter multi-line; Tab toggle thinking; Esc Esc interrupt/restore.

Parallel workflows:
- /fork - fork conversations for non-overlapping parallel tasks
- Git worktrees - for overlapping parallel Claudes without conflicts (`git worktree add ../feature-branch feature-branch`)
- tmux for long-running commands: stream and watch logs (`tmux new -s dev`, detach/reattach)

mgrep > grep: significant improvement over ripgrep. Local + web search (`mgrep --web "..."`).

Other commands: /rewind (previous state), /statusline, /checkpoints (file-level undo), /compact (manual compaction).

GitHub Actions CI/CD: Claude can review PRs automatically when configured.

Sandboxing: use sandbox mode for risky operations (opposite: --dangerously-skip-permissions).

## On Editors

Zed (author's preference): Rust-based, agent panel integration tracks file changes in real-time, CMD+Shift+R command palette, Ctrl+G opens the file Claude is working on, enable auto-save so Claude's reads are current. VSCode/Cursor also viable (\ide for LSP sync, or the extension).

## MCP Servers configured (user level)

github, firecrawl, supabase, memory, sequential-thinking, vercel, railway, cloudflare-docs/workers-bindings/workers-builds/observability, clickhouse, AbletonMCP, magic.

## Key Hooks (summary)

- PreToolUse: tmux reminder (npm|pnpm|yarn|cargo|pytest); block unnecessary .md file creation (unless README/CLAUDE); review before git push
- PostToolUse: prettier --write on JS/TS edits; tsc --noEmit after TS edits; console.log warning
- Stop: audit modified files for console.logs before session ends

## Key Takeaways

- Don't overcomplicate - treat configuration like fine-tuning, not architecture
- Context window is precious - disable unused MCPs and plugins
- Parallel execution - fork conversations, use git worktrees
- Automate the repetitive - hooks for formatting, linting, reminders
- Scope your subagents - limited tools = focused execution
