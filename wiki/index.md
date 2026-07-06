# Vault index

[//]: # "Master index — maintained by the agent. Update after every cortex-assimilate or cortex-imprint operation."

## Projects
- [[wiki/projects/cortex-forge]] — Vault with multi-agent hot cache protocol (Claude Code, Codex, Antigravity, CommandCode)

## Concepts
- [[wiki/concepts/crystallize-vs-imprint]] — Design boundary between cortex-crystallize (hot cache, ephemeral, automatic) and cortex-imprint (wiki, permanent, manual)
- [[wiki/concepts/skill-dependency-graph]] — What each skill produces and consumes; contracts, failure modes, and the data flow between all 6 skills
- [[wiki/concepts/skill-design-principles]] — Compiled checklist of what separates a working skill from one that appears to work; whiteness test, 9 principles, commit checklist
- [[wiki/concepts/fail-loud-design]] — Error clearly and immediately instead of degrading silently; origin in the 2026-07-03 script audit, manifestations across CLI scripts, CI, and session-state writes
- [[wiki/concepts/skill-self-improvement-loop]] — Observer skill pattern: run inner skill → evaluate with computer use → generate diff → improve SKILL.md; inner vs outer loop distinction
- [[wiki/concepts/no-op-audit-adversarial-debate]] — Methodology for identifying and rehabilitating no-op skill instructions via adversarial subagent debate (defender / attacker / judge)
- [[wiki/concepts/parametric-knowledge]] — What the model knows from training; frozen, unverifiable, disqualified as a source for vault topics
- [[wiki/concepts/contextual-knowledge]] — Facts the agent reads directly from context; the verifiable counterpart to parametric knowledge
- [[wiki/concepts/memory-system]] — System that makes an agent stateful across sessions; Cortex Forge is one implementation
- [[wiki/concepts/handoff-artifact]] — Document written by one session to be read by another; .hot/MEMORY.md is an instance
- [[wiki/concepts/smart-zone]] — Session degradation pattern: agents drift from sharp (smart zone) to sloppy (dumb zone) as context fills
- [[wiki/concepts/commandcode-taste]] — CommandCode continuous personalization system: per-project paths (.commandcode/taste/) and global (~/.commandcode/taste/), implicit learning loop, CLI push/pull
- [[wiki/concepts/agent-hook-compatibility]] — Decision record: why cortex-forge removed agent lifecycle hooks entirely (per-agent findings that drove the call, absorbs former crystallize-automation-architecture page)
- [[wiki/concepts/antigravity-hooks]] — Hook configuration and execution in Google Antigravity / Gemini CLI
- [[wiki/concepts/progressive-disclosure-hooks]] — Just-in-time context loading pattern via hooks and skills; avoids token bloat at session start
- [[wiki/concepts/karpathy-wiki-pattern]] — Wiki design pattern optimized for LLM consumption (deterministic parser + semantic layer)
- [[wiki/concepts/treesitter-llm-hybrid-parsing]] — Separation of concerns: deterministic parser for facts, LLM for interpretations
- [[wiki/concepts/multi-agent-analysis-pipeline]] — Orchestration of N specialized agents with parallel fan-out and per-layer validation
- [[wiki/concepts/primary-source]] — Source of truth in its original form (the thing, not an account of it); expensive but complete and current — `.raw/` is the vault's instance
- [[wiki/concepts/prompt-classification-hook]] — UserPromptSubmit hook that classifies each message and injects routing hints for mid-session capture
- [[wiki/concepts/continuous-learning-loop]] — Stop-hook evaluation of sessions to extract non-trivial patterns as reusable skills; counterpart to crystallize (lessons, not state)
- [[wiki/concepts/iterative-retrieval]] — Orchestrator treats subagent summaries as drafts: evaluate, follow up, loop (bounded); pass objective, not just query
- [[wiki/concepts/memory-as-attack-surface]] — Persistent memory lets injection payloads plant fragments and assemble later; auto-loaded files are rarely re-audited
- [[wiki/concepts/secondary-source]] — Account one step removed, lossy by construction; fails by loss or drift, remedied by context pointers — `wiki/` is the vault's instance
- [[wiki/concepts/pi-extension-lifecycle]] — Pi's TypeScript-first extension framework: async factory pattern, event taxonomy, ExtensionContext, provider registration, context-overflow recovery
- [[wiki/concepts/knowledge-graph-code-intelligence]] — Structural approach: codebase parsed into persistent property graph; agents query graph instead of reading files; 99%+ token reduction vs file-by-file
- [[wiki/concepts/headless-agent-mode]] — Modo no-interactivo (`-p` / `--print`): flags por agente, permisos de escritura, persistencia de sesión; `--yolo` requerido en CommandCode para hooks de síntesis
- [[wiki/concepts/tool-context-budget]] — Tool schemas consumen ~30K tokens antes del primer mensaje; cada MCP server suma 3–15K adicionales; ventana efectiva ≠ ventana nominal
- [[wiki/concepts/agent-permission-model]] — Superficie de permisos cross-agent: CommandCode bloquea escrituras en headless por defecto (`--yolo` requerido); Antigravity usa per-action-type; MCP expande superficie independientemente
- [[wiki/concepts/super-context]] — Harness-level pattern for deterministic context injection on session start; eliminates agent cold starts; Cortex Forge equivalent is the SessionStart hook + .hot/MEMORY.md
- [[wiki/concepts/cortex-forge-vs-alternatives]] — Comprehensive comparison of cortex-forge vs 16+ alternative systems (OpenHuman, GBrain, Hermes, Obsidian Mind, OpenBrain, Mem0, etc.)
- [[wiki/concepts/vault-design-karpathy-vs-hq]] — Two design reference models (epistemic vs executive); gaps analysis with Hermes cross-reference; cortex-forge chose Karpathy
- [[wiki/concepts/vault-mcp-server-pattern]] — Architecture pattern for exposing a vault as an MCP server; skills vs MCP trade-off; gate for Phase 2 transition
- [[wiki/concepts/workflow-architecture]] — Session flow (start/during/end), skills, and scripts — manual `AGENTS.md`-driven protocol, no agent lifecycle hooks
- [[wiki/concepts/commandcode-models]] — Model ids for `cmd -m` / `cmd --model`, grouped by provider
- [[wiki/concepts/pi-cli-flags]] — Every `pi` CLI flag by category: modes, model/session/tool/resource/other options, env vars (PI_CODING_AGENT_DIR, PI_OFFLINE, etc.)
- [[wiki/concepts/pi-slash-commands]] — All built-in Pi slash commands with one-line descriptions
- [[wiki/concepts/pi-session-file-format]] — Pi JSONL session entry types, message content blocks, AgentMessage union, tree structure
- [[wiki/concepts/pi-terminal-compat]] — Pi terminal compatibility matrix and config snippets for Ghostty/WezTerm/Alacritty/VS Code/Windows Terminal
- [[wiki/concepts/pi-models-json]] — `~/.pi/agent/models.json` full schema: provider/model fields, value resolution, compat flags
- [[wiki/concepts/pi-provider-api-types]] — Pi supported streaming APIs: anthropic-messages, openai-completions, mistral-conversations, etc., with compat flag matrix
- [[wiki/concepts/pi-event-types]] — Pi extension event taxonomy (startup/session/agent/tool/user_bash/input) and ExtensionContext properties
- [[wiki/concepts/pi-extension-api]] — All `pi.*` ExtensionAPI methods (registerTool, registerCommand, registerProvider, etc.)
- [[wiki/concepts/codebase-memory-mcp-tools]] — All 14 MCP tools, node labels, edge types, Cypher read subset, CLI mode, env vars, troubleshooting
- [[wiki/concepts/embedding-backend-selection]] — Runtime backend priority (Ollama → mlx-embeddings → sentence-transformers) encapsulated in `embeddings.py`'s `_try_ollama()`/`_try_mlx()`

## Entities
- [[wiki/entities/compound-engineering]] — Every Inc's compound engineering plugin: 27 skills, compound loop (brainstorm→plan→work→simplify→review→compound), skill-local prompt assets architecture; 22k stars
- [[wiki/entities/openwiki]] — CLI by LangChain AI: LLM-generated codebase wiki + automated git-diff-scoped updates via GitHub Actions; injects reference into AGENTS.md/CLAUDE.md
- [[wiki/entities/openbrain-nate-jones]] — Personal semantic memory system: Postgres + pgvector + MCP server; any agent connects with URL + key
- [[wiki/entities/google-antigravity]] — Agent-first development platform oriented toward autonomous workflows
- [[wiki/entities/antigravity-cli]] — Google Antigravity CLI: `agy` binary, two-layer permission model, OS-level sandbox, plugins/skills/hooks
- [[wiki/entities/commandcode]] — AI coding agent with continuous TASTE personalization; Stop/SessionStart hooks, config in `.commandcode/`
- [[wiki/entities/understand-anything]] — Lum1104's multi-platform plugin that builds knowledge graphs over codebases and wikis
- [[wiki/entities/pi-cli]] — Terminal AI coding agent from `earendil-works/pi-mono`: TypeScript extensions, JSONL tree sessions, multi-provider (Anthropic, OpenAI, Google, Ollama, vLLM, custom)
- [[wiki/entities/codebase-memory-mcp]] — High-performance MCP server: codebase → SQLite knowledge graph; 158 languages, 14 tools, zero dependencies, single static binary; 3,902 stars
- [[wiki/entities/codex]] — Codex CLI (OpenAI): terminal coding agent; Cortex Forge hooks installed as no-op JSON guards, crystallize manual
- [[wiki/entities/graphify]] — Skill multi-agente que convierte cualquier folder en knowledge graph (`graph.html`); 66.3k stars, YC S26; no soporta CommandCode (brecha que cortex-forge cubre)
- [[wiki/entities/openhuman]] — Open-source agentic desktop assistant (33k stars); Memory Tree + Obsidian vault + 118 integrations + SuperContext; closest full-harness comparable to Cortex Forge

## Sources
- [[wiki/sources/antigravity-hooks]] — Hook documentation for Google Antigravity (ingested 2026-06-07)
- [[wiki/sources/antigravity-hooks-reference]] — Antigravity 2.0 official hooks reference: full event table, PreInvocation injectSteps, PostInvocation terminationBehavior, wire format (2026-06-26)
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
- [[wiki/sources/obsidian-mind]] — README from github.com/breferrari/obsidian-mind: comparable memory vault with classification/validation hooks (ingested 2026-06-12)
- [[wiki/sources/claude-code-shorthand-guide]] — @affaan's power-user Claude Code setup: tool-context budget, codemap skill, enforcement hooks (ingested 2026-06-12)
- [[wiki/sources/claude-code-longform-guide]] — @affaan's advanced techniques: memory persistence hook chain, continuous learning, iterative retrieval, evals (ingested 2026-06-12)
- [[wiki/sources/agentic-security-shorthand-guide]] — @affaan's agent security guide: memory poisoning, lethal trifecta, skills as supply chain, least agency (ingested 2026-06-12)
- [[wiki/sources/yt-claude-code-memory-compared]] — 6 levels of Claude Code memory: native tools, hooks, vectors, conversation recall, wiki knowledge bases, cross-platform brain (ingested 2026-06-12)
- [[wiki/sources/graphify]] — Knowledge graph skill for AI coding assistants; 66.3k stars, YC S26, 20+ platforms, multi-agent install patterns (combined synthesis, ingested 2026-06-12)
- [[wiki/sources/graphify-readme]] — graphify README v8: multi-agent install paths, hook mechanisms per platform (ingested 2026-06-12)
- [[wiki/sources/graphify-agents]] — graphify AGENTS.md: graph-aware agent workflow, read report → navigate wiki → update on change (ingested 2026-06-12)
- [[wiki/sources/graphify-architecture]] — graphify ARCHITECTURE.md: 7-stage pipeline, 18 modules, extraction schema, confidence labels (ingested 2026-06-12)
- [[wiki/sources/graphify-how-it-works]] — graphify how-it-works: 3-pass architecture, Leiden algorithm, 71.5x token reduction (ingested 2026-06-12)
- [[wiki/sources/commandcode-headless]] — Headless mode: session persistence, resume, exit codes, permissions (ingested 2026-06-12)
- [[wiki/sources/commandcode-security]] — Security model: permission modes, headless permissions, data handling, MCP security (ingested 2026-06-13)
- [[wiki/sources/openbrain]] — OpenBrain by Nate B. Jones: Postgres+pgvector+MCP personal semantic memory; schema, capture pipeline, privacy model (ingested 2026-06-15)
- [[wiki/sources/pi-usage]] — Pi CLI usage: TUI areas, slash commands, message queue, sessions, project trust, full CLI surface (ingested 2026-06-16)
- [[wiki/sources/pi-extensions]] — Pi extension system: TypeScript lifecycle, event taxonomy, ExtensionContext, ExtensionAPI, custom tools/UI (ingested 2026-06-16)
- [[wiki/sources/pi-packages]] — Pi packages: npm/git distribution, `pi` manifest, conventions, peer vs bundled deps, filtering (ingested 2026-06-16)
- [[wiki/sources/pi-models]] — Pi `models.json`: custom provider schema, value resolution, `compat` flags, `thinkingLevelMap`, per-model overrides (ingested 2026-06-16)
- [[wiki/sources/pi-custom-provider]] — Pi custom providers: `pi.registerProvider()`, OAuth/SSO, `streamSimple` event protocol, context-overflow recovery (ingested 2026-06-16)
- [[wiki/sources/pi-session-format]] — Pi session JSONL tree format: versions, AgentMessage union, entry types, SessionManager API (ingested 2026-06-16)
- [[wiki/sources/pi-terminal-setup]] — Pi terminal compatibility matrix and per-emulator config (Kitty protocol, Ghostty, WezTerm, Alacritty, VS Code, Windows Terminal) (ingested 2026-06-16)
- [[wiki/sources/codebase-memory-mcp]] — codebase-memory-mcp GitHub README: knowledge graph indexer, 14 MCP tools, Hybrid LSP, team-shared artifact (ingested 2026-06-16)
- [[wiki/sources/openhuman]] — OpenHuman README: Memory Tree, SuperContext, TokenJuice, 118+ integrations, agentmemory backend interop (ingested 2026-06-26)
- [[wiki/sources/openhuman-super-context]]
- [[wiki/sources/writing-great-skills]] — Matt Pocock's writing-great-skills SKILL.md + GLOSSARY.md: vocabulary and failure modes for predictable skills (ingested 2026-07-01)
- [[wiki/sources/anthropic-skill-creator]] — Anthropic's official skill-creator: creation loop, eval harness, description optimization (ingested 2026-07-01)
- [[wiki/sources/compound-engineering-plugin]] — Compound Engineering README + June 2026 architectural update: agents→skill-local prompt assets, unified plan doc (ingested 2026-07-01)
- [[wiki/sources/skill-optimization-loop]] — Zach Lloyd's outer-loop skill optimization: observer skill + computer use grader + SKILL.md diffs (ingested 2026-07-01)
- [[wiki/sources/agentskills-best-practices]] — agentskills.io's skill-creation best practices: grounding in real expertise, context budgeting, calibrating specificity, named instruction patterns (ingested 2026-07-03)
- [[wiki/sources/agentskills-using-scripts]] — agentskills.io's guide to bundling and designing scripts in skills: `scripts/` convention, self-contained inline dependencies, agentic CLI design (ingested 2026-07-03)
- [[wiki/sources/openwiki]] — OpenWiki README + architecture + agent workflow + GitHub Actions pattern (ingested 2026-07-01) — OpenHuman SuperContext feature article (featured): harness-level deterministic context injection, read-only scout, tag-delimited bundle (ingested 2026-06-26)

## Meta
- [[wiki/meta/log]] — Append-only vault operation log
- [[wiki/meta/_index|Vault meta]]
- `templates/` — 5 page templates (concept, entity, source, project, reference)
- `bin/setup-vault.sh` — setup script
- `skills/` — agent skills (cortex-assimilate, cortex-recall, cortex-prune, cortex-imprint, cortex-crystallize, cortex-forge-setup)

