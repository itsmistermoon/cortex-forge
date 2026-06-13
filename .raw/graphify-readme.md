# graphify — README (v8)

**URL:** https://github.com/safishamsi/graphify
**Fetched:** 2026-06-12

Type `/graphify .` in your AI coding assistant and it maps your entire project into a knowledge graph. Works in Claude Code, Codex, OpenCode, Kilo Code, Cursor, Gemini CLI, GitHub Copilot CLI, VS Code Copilot Chat, Aider, Amp, OpenClaw, Factory Droid, Trae, Hermes, Kimi Code, Kiro, Pi, Devin CLI, and Google Antigravity.

Output: graph.html, GRAPH_REPORT.md, graph.json.

66.3k stars, YC S26, 733 commits on v8 branch. MIT license.

Key multi-agent features per platform:
- Claude Code: CLAUDE.md + PreToolUse hooks
- Codex: AGENTS.md + PreToolUse hooks in .codex/hooks.json
- CodeBuddy: CODEBUDDY.md + PreToolUse hooks
- Cursor: .cursor/rules/graphify.mdc with alwaysApply: true
- Gemini CLI: GEMINI.md + BeforeTool hook
- Kilo Code: native skill + /graphify command + AGENTS.md + .kilo plugin
- OpenCode: AGENTS.md + tool.execute.before plugin
- Others: AGENTS.md or skill file

Notable: CommandCode is NOT in the supported list.
