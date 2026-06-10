# Vault index

[//]: # "Master index — maintained by the agent. Update after every cortex-assimilate or cortex-imprint operation."

## Projects
- [[wiki/pages/cortex-forge]] — Vault with multi-agent hot cache protocol (Claude Code, Codex, Antigravity, CommandCode)

## Concepts
- [[wiki/concepts/parametric-knowledge]] — What the model knows from training; frozen, unverifiable, disqualified as a source for vault topics
- [[wiki/concepts/contextual-knowledge]] — Facts the agent reads directly from context; the verifiable counterpart to parametric knowledge
- [[wiki/concepts/memory-system]] — System that makes an agent stateful across sessions; Cortex Forge is one implementation
- [[wiki/concepts/handoff-artifact]] — Document written by one session to be read by another; .hot/MEMORY.md is an instance
- [[wiki/concepts/smart-zone]] — Session degradation pattern: agents drift from sharp (smart zone) to sloppy (dumb zone) as context fills
- [[wiki/concepts/commandcode-taste]] — CommandCode continuous personalization system: per-project paths (.commandcode/taste/) and global (~/.commandcode/taste/), implicit learning loop, CLI push/pull
- [[wiki/concepts/agent-hook-compatibility]] — Lifecycle hook matrix per agent (Claude Code, Codex, Antigravity, CommandCode)
- [[wiki/concepts/antigravity-hooks]] — Hook configuration and execution in Google Antigravity / Gemini CLI
- [[wiki/concepts/progressive-disclosure-hooks]] — Just-in-time context loading pattern via hooks and skills; avoids token bloat at session start
- [[wiki/concepts/karpathy-wiki-pattern]] — Wiki design pattern optimized for LLM consumption (deterministic parser + semantic layer)
- [[wiki/concepts/treesitter-llm-hybrid-parsing]] — Separation of concerns: deterministic parser for facts, LLM for interpretations
- [[wiki/concepts/multi-agent-analysis-pipeline]] — Orchestration of N specialized agents with parallel fan-out and per-layer validation
- [[wiki/concepts/primary-source]] — Source of truth in its original form (the thing, not an account of it); expensive but complete and current — `.raw/` is the vault's instance
- [[wiki/concepts/secondary-source]] — Account one step removed, lossy by construction; fails by loss or drift, remedied by context pointers — `wiki/` is the vault's instance

## Entities
- [[wiki/entities/google-antigravity]] — Agent-first development platform oriented toward autonomous workflows
- [[wiki/entities/antigravity-cli]] — Google Antigravity CLI: `agy` binary, two-layer permission model, OS-level sandbox, plugins/skills/hooks
- [[wiki/entities/commandcode]] — AI coding agent with continuous TASTE personalization; Stop/SessionStart hooks, config in `.commandcode/`
- [[wiki/entities/understand-anything]] — Lum1104's multi-platform plugin that builds knowledge graphs over codebases and wikis

## Sources
- [[wiki/sources/antigravity-hooks]] — Hook documentation for Google Antigravity (ingested 2026-06-07)
- [[wiki/sources/codex-hooks]] — Hook documentation for Codex (ingested 2026-06-08)
- [[wiki/sources/commandcode-hooks-configuration]] — Hook configuration in Command Code: scopes, precedence, and order (ingested 2026-06-08)
- [[wiki/sources/commandcode-hooks-reference]] — Technical reference: wire format I/O, exit codes, HookDefinition/HookEntry (ingested 2026-06-08)
- [[wiki/sources/commandcode-hooks-examples]] — 4 ready-to-adapt hook patterns: enforcement, context injection, auditing, quality gate (ingested 2026-06-08)
- [[wiki/sources/commandcode-hooks-best-practices]] — Security, performance, and debugging of hooks in CommandCode (ingested 2026-06-08)
- [[wiki/sources/gemini-cli-hooks-video]] — Official Gemini CLI hooks & skills video — Google Cloud Live (ingested 2026-06-08)
- [[wiki/sources/understand-anything]] — README from github.com/Lum1104/Understand-Anything (ingested 2026-06-08)
- [[wiki/sources/antigravity-cli-permissions]] — Permissions per action (`read_file`, `write_file`, `command`, etc.) and preset modes
- [[wiki/sources/antigravity-cli-sandbox]] — OS-level sandbox: nsjail/sandbox-exec/AppContainer, configuration, and controlled escape
- [[wiki/sources/antigravity-cli-features]] — CLI features: plugins, sandbox, subagents, approvals
- [[wiki/sources/antigravity-cli-settings]] — All `settings.json` keys with types, defaults, and descriptions
- [[wiki/sources/antigravity-cli-plugins]] — Plugin system: bundle structure, `agy plugin *` subcommands, skills and MCP per plugin
- [[wiki/sources/antigravity-cli-statusline]] — Status line: JSON payload, configuration in `settings.json`, reference script
- [[wiki/sources/antigravity-cli-tutorial]] — Onboarding flow: launch, review artifacts, and verify output
- [[wiki/sources/antigravity-cli-title]] — Terminal title: same payload as statusline, ANSI stripping, `/title` toggle
- [[wiki/sources/antigravity-cli-best-practices]] — Best practices: minimal permissions, AGENTS.md, checkpoints, subagents
- [[wiki/sources/antigravity-cli-using]] — Daily usage: settings, slash commands, keybindings, and session control
- [[wiki/sources/antigravity-cli-troubleshooting]] — Troubleshooting: auth, sandbox, permissions, MCP, performance
- [[wiki/sources/antigravity-cli-reference]] — Full reference: slash commands, keybindings, settings.json keys
- [[wiki/sources/antigravity-cli-hands-on-codelab]] — Codelab step 5: installation, CLI flags (`-p` non-interactive mode), config, models
- [[wiki/sources/commandcode-taste-blog]] — Introduction to TASTE: three-layer stack, learning loop, empirical results
- [[wiki/sources/commandcode-taste-docs]] — Official TASTE documentation: taste.md format, scopes, management
- [[wiki/sources/commandcode-taste-manage]] — TASTE profile management: push/pull, Studio, lint, scopes
- [[wiki/sources/commandcode-taste-commands]] — `npx taste` / `cmd taste` command reference
- [[wiki/sources/ai-coding-dictionary]] — 68-entry plain-English vocabulary of AI coding by Matt Pocock (AI Hero)
- [[wiki/sources/ai-coding-dictionary-primary-source]] — Full article: primary source — cost vs completeness, staleness inheritance (ingested 2026-06-10)
- [[wiki/sources/ai-coding-dictionary-secondary-source]] — Full article: secondary source — lossy/drift failure modes, context pointers (ingested 2026-06-10)

## Meta
- [[wiki/meta/log]] — Append-only vault operation log
- [[wiki/meta/_index|Vault meta]]
- `templates/` — 5 page templates (concept, entity, source, project, wiki-page)
- `bin/setup-vault.sh` — setup script
- `skills/` — agent skills (cortex-assimilate, cortex-recall, cortex-prune, cortex-imprint, cortex-crystallize, cortex-forge-setup)
