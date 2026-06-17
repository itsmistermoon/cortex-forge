---
title: "Pi (CLI)"
type: entity
created: 2026-06-16
updated: 2026-06-16
tags: [pi, coding-agent, cli, tui, typescript, extensions, jsonl, providers]
aliases: [pi, pi-coding-agent]
sources:
  - wiki/sources/pi-usage.md
  - wiki/sources/pi-extensions.md
  - wiki/sources/pi-packages.md
  - wiki/sources/pi-models.md
  - wiki/sources/pi-custom-provider.md
  - wiki/sources/pi-session-format.md
  - wiki/sources/pi-terminal-setup.md
confidence: high
schema_version: "0.3"
---

# Pi (CLI)

Pi is a terminal-based AI coding agent (CLI + TUI) from the `earendil-works/pi-mono` monorepo. It ships with a small core and pushes workflow-specific behavior — MCP, sub-agents, permission popups, plan mode, to-dos, background bash — into TypeScript extensions, skills, prompt templates, and npm/git packages. The interface is a four-area TUI (startup header, messages, editor, footer) with a Kitty-keyboard-protocol-driven editor and a message queue (steering vs follow-up).

Sessions are JSONL with a tree structure (`id`/`parentId`), enabling in-place branching, fork, and clone without creating new files. Custom providers and models are registered either declaratively in `~/.pi/agent/models.json` or programmatically from an extension via `pi.registerProvider()` (with full OAuth/SSO and custom `streamSimple` support).

## Identity

- **CLI binary:** `pi`
- **Org / repo:** `earendil-works/pi-mono` (monorepo: `packages/coding-agent`, `packages/ai`, `packages/agent-core`, `packages/tui`)
- **Package name:** `@earendil-works/pi-coding-agent`
- **Config global:** `~/.pi/agent/`
- **Config project:** `.pi/`
- **Sessions:** `~/.pi/agent/sessions/--{cwd-as-path}--/{ts}_{uuid}.jsonl`
- **Auth:** `~/.pi/agent/auth.json` (OAuth credentials) and provider API keys via `models.json` or env
- **Author blog (design rationale):** [mariozechner.at — 2025-11-30](https://mariozechner.at/posts/2025-11-30-pi-coding-agent/)
- **Companion project:** [`badlogic/pi-share-hf`](https://github.com/badlogic/pi-share-hf) — publishes sessions to Hugging Face datasets for open-source model/prompt/tool/eval research. (`badlogic` is not the author of pi itself; that's `earendil-works`.)

## Key capabilities

- **Extensions** — TypeScript modules that subscribe to lifecycle events, register tools, draw custom TUI components, persist state. See [[wiki/concepts/pi-extension-lifecycle]] and [[wiki/sources/pi-extensions]].
- **Packages** — `pi install npm:|git:|path` to bundle and share extensions/skills/prompts/themes. Conventional directories auto-discover; `pi` manifest in `package.json` declares them. See [[wiki/sources/pi-packages]].
- **Multi-provider** — built-in (Anthropic, OpenAI, Google) plus custom (`models.json` for static, async factory + `pi.registerProvider()` for dynamic). Full OAuth/SSO and custom `streamSimple` support. See [[wiki/sources/pi-models]] and [[wiki/sources/pi-custom-provider]].
- **Sessions as JSONL trees** — `id`/`parentId` linking, three versions (v1 linear, v2 tree, v3 with `custom` rename), `SessionManager` programmatic API, in-place fork/clone. See [[wiki/sources/pi-session-format]].
- **Slash commands and modes** — `/model`, `/scoped-models`, `/resume`, `/tree`, `/fork`, `/clone`, `/compact`, `/export`, `/share`, `/reload`, `/hotkeys`, `/changelog`, `/quit`. Modes: interactive (default), `-p` (print), `--mode json`, `--mode rpc`. See [[wiki/sources/pi-usage]].
- **Context files** — `AGENTS.md` / `CLAUDE.md` discovered at startup; `.pi/SYSTEM.md` replaces the system prompt, `APPEND_SYSTEM.md` appends.
- **Project trust** — gates `.pi/settings.json`, project-local extensions, and project package-managed resources; configurable via `defaultProjectTrust` (`ask` / `always` / `never`) and `--approve`/`--no-approve` per-run.
- **Design philosophy** — small core, opt-in everything else. "Intentionally does not include built-in MCP, sub-agents, permission popups, plan mode, to-dos, or background bash."

## Relationship to the AI coding agent space

Pi sits in the same family as the other terminals-first coding CLIs the vault tracks:

- [[wiki/entities/commandcode]] — uses a JSONL transcript per session with the same `id`/`parentId` shape (parity in forking), but with a hooks/events model that runs shell commands; pi's equivalent is the TypeScript extension lifecycle.
- [[wiki/entities/openbrain-nate-jones]] — orthogonal: cross-platform semantic memory rather than a CLI. Pluggable into any MCP-capable agent including pi via an extension.
- [[wiki/entities/understand-anything]] — multi-platform codebase-to-knowledge-graph plugin; supports "Pi Agent" alongside Claude Code, Codex, Cursor, Copilot, etc.
- [[wiki/entities/google-antigravity]] — agent-first dev platform with its own terminal CLI (`agy`); shares the "no MCP by default, plugins for everything" instinct with pi but ships its own GraphQL-style skills system.

## Connections

- [[wiki/sources/pi-usage]] — slash commands, modes, message queue, project trust
- [[wiki/sources/pi-extensions]] — event taxonomy, ExtensionContext, custom UI
- [[wiki/sources/pi-packages]] — npm/git distribution and manifest
- [[wiki/sources/pi-models]] — declarative custom providers via `models.json`
- [[wiki/sources/pi-custom-provider]] — programmatic providers and OAuth
- [[wiki/sources/pi-session-format]] — JSONL tree, entry types, SessionManager
- [[wiki/sources/pi-terminal-setup]] — Kitty protocol, per-emulator keybinding configs
- [[wiki/concepts/pi-extension-lifecycle]] — synthesized model of the extension system

---

- 2026-06-16 [CommandCode]: Page created
