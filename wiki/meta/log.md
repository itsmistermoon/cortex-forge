# Vault operation log

Append-only log of significant vault operations. Each entry added by `cortex-assimilate`, `cortex-imprint`, or `cortex-prune`.

## Format

```
## [YYYY-MM-DD] {operation} | {description}
```

Operations: `ingest`, `imprint`, `prune`, `query`

---

<!-- entries below -->

## [2026-06-08] ingest | Antigravity CLI docs: full re-assimilation

Rebuilt the Antigravity CLI tutorial, plugins, statusline, using, and features pages from the official documentation routes using the SPA fallback flow required by `cortex-assimilate`.

Updated:
- `wiki/sources/antigravity-cli-tutorial.md`
- `wiki/sources/antigravity-cli-using.md`
- `wiki/sources/antigravity-cli-features.md`
- `wiki/sources/antigravity-cli-plugins.md`
- `wiki/sources/antigravity-cli-statusline.md`
- `wiki/index.md`

Project linking: skipped; these sources describe the Antigravity CLI docs surface, not an active user project.

Agent: Claude Code

## [2026-06-08] ingest | Antigravity CLI docs: tutorial, using, features

Sources checked:
- `https://antigravity.google/docs/cli-plugins` already existed as `wiki/sources/antigravity-cli-plugins.md`
- `https://antigravity.google/docs/cli-statusline` already existed as `wiki/sources/antigravity-cli-statusline.md`

Created:
- `wiki/sources/antigravity-cli-tutorial.md`
- `wiki/sources/antigravity-cli-using.md`
- `wiki/sources/antigravity-cli-features.md`

Updated:
- `wiki/index.md` (Sources)

Project linking: skipped; these pages document the Antigravity CLI surface, not an active user project.

Agent: Claude Code

## [2026-06-08] query | Codex hook placement clarified

Updated `wiki/concepts/agent-hook-compatibility.md` and the `cortex-forge-setup` skill to reflect the multi-vault Codex setup:
- Codex hooks live in a stable global folder: `~/.codex/hooks/`
- The hook scripts are vault-aware at runtime and resolve the active vault dynamically
- Codex should not point directly at a single vault path

This preserves multi-vault compatibility and keeps the same Codex configuration usable from non-vault projects.

## [2026-06-08] ingest | CommandCode TASTE — 4 official sources

Sources: `.raw/commandcode-taste-blog.md`, `.raw/commandcode-taste-docs.md`, `.raw/commandcode-taste-manage.md`, `.raw/commandcode-taste-commands.md`
Pages created: `wiki/sources/commandcode-taste-{blog,docs,manage,commands}.md`, `wiki/concepts/commandcode-taste.md`
Key finding: TASTE has two scopes with concrete paths — per-project at `.commandcode/taste/` and global at `~/.commandcode/taste/` (flag `-g`). Resolves the pending scope question for the TASTE rule in `cortex-recall`.

## [2026-06-08] ingest | Gemini CLI Hooks & Skills (youtube.com/watch?v=ZXYuiEMm21s)

Source: `.raw/gemini-cli-hooks-video.md` (clean transcript via yt-dlp)

Created:
- `wiki/sources/gemini-cli-hooks-video.md` (type: source, confidence: medium)
- `wiki/concepts/progressive-disclosure-hooks.md` (type: concept)

Updated:
- `wiki/concepts/antigravity-hooks.md` — `settings.json` vs `hooks.json` contradiction documented; scopes and script path clarified
- `wiki/index.md` (Concepts, Sources)

Project linking: skipped (no active projects in `wiki/pages/`).

Agent: Claude Code

## [2026-06-08] ingest | Codex Hooks (developers.openai.com/codex/hooks)

Source: `.raw/codex-hooks.md`

Created:
- `wiki/sources/codex-hooks.md` (type: source, confidence: high)

Updated:
- `wiki/index.md` (Sources)

Project linking: skipped (no active project pages related to this Codex docs page).

Agent: Claude Code

## [2026-06-07] ingest | Google Antigravity Hooks (antigravity.google/docs/hooks)

Source: `.raw/antigravity-hooks.md`

Created:
- `wiki/sources/antigravity-hooks.md` (type: source, confidence: high)
- `wiki/entities/google-antigravity.md` (type: entity)
- `wiki/concepts/antigravity-hooks.md` (type: concept)

Updated:
- `wiki/index.md` (Concepts, Entities, Sources)

Project linking: skipped (no active project pages related to this SDK).

Agent: Antigravity (Gemini 3.5 Flash)

## [2026-06-08] ingest | Understand Anything (github.com/Lum1104/Understand-Anything)

Source: `.raw/understand-anything.md` (main README, 350 lines, downloaded from raw.githubusercontent.com)

Created:
- `wiki/sources/understand-anything.md` (type: source, confidence: high)
- `wiki/entities/understand-anything.md` (type: entity)
- `wiki/concepts/karpathy-wiki-pattern.md` (type: concept)
- `wiki/concepts/treesitter-llm-hybrid-parsing.md` (type: concept)
- `wiki/concepts/multi-agent-analysis-pipeline.md` (type: concept)

Updated:
- `wiki/index.md` (4 sections: Projects, Concepts, Entities, Sources)

Project linking: skipped — no active projects in `wiki/pages/` with `status: active`. Understand Anything is a third-party project (MIT, Lum1104), not the user's; no `wiki/pages/` page created per skill criteria.

Concepts skipped (considered but discarded due to lack of transferable proper name or UI specificity):
- Persona-adaptive UI (UI-specific, no reusable conceptual identity)
- Fingerprint-based incremental (sub-concept of `treesitter-llm-hybrid-parsing`, already covered)
- Diff impact analysis (generic, no proper name)

Cross-references: [[wiki/concepts/agent-hook-compatibility]] (hooks matrix overlaps with source's multi-platform matrix — both platform × event).

Agent: CommandCode (MiniMax-M3)

## [2026-06-08] ingest | CommandCode Hooks Configuration (commandcode.ai/docs/hooks/configuration)

Source: `.raw/commandcode-hooks-configuration.md` (fetched via curl, 2.4KB clean)

Created:
- `wiki/sources/commandcode-hooks-configuration.md` (type: source, confidence: high)

Updated:
- `wiki/concepts/agent-hook-compatibility.md` — CommandCode section expanded with scopes (user vs project), precedence, PreToolUse/PostToolUse order, short-circuit semantics, and nested wire format
- `wiki/index.md` (Sources)

No new concepts/entities created. The source is operational configuration for a product already covered by `wiki/concepts/agent-hook-compatibility` and `wiki/sources/commandcode-hooks-configuration` (referenced in the concept). The nested wire format differing from Codex/Claude Code is an operational note, not a reusable concept with a proper name.

Project linking: skipped — `wiki/pages/` only contains `.gitkeep`; no active user projects with `status: active`. Cortex-forge knowledge lives as pages, not as a wiki project page.

Key operational finding: CommandCode's official wire format (`hooks: [{ matcher, hooks: [{ type, command, timeout? }] }]`) differs from the flat wire format of Claude Code/Codex. Hot cache scripts written for Claude Code/Codex are NOT drop-in for CommandCode; each handler would need to be wrapped in a `hooks` sub-array per matcher.

Agent: CommandCode (MiniMax-M3)

## [2026-06-08] ingest | CommandCode Hooks Reference, Examples, Best Practices (commandcode.ai/docs/hooks/{reference,examples,best-practices})

Sources:
- `.raw/commandcode-hooks-reference.md`
- `.raw/commandcode-hooks-examples.md`
- `.raw/commandcode-hooks-best-practices.md`

Created:
- `wiki/sources/commandcode-hooks-reference.md` (type: source, confidence: high)
- `wiki/sources/commandcode-hooks-examples.md` (type: source, confidence: high)
- `wiki/sources/commandcode-hooks-best-practices.md` (type: source, confidence: high)

Updated:
- `wiki/concepts/agent-hook-compatibility.md` — full CommandCode I/O schema (fields `permissionDecision`, `additionalContext`, `systemMessage`, `decision`, `continue`; exit code semantics), security/performance section (no eval, jq -r, timeout <10s, plan mode, chmod +x, debugging with --debug), table of common usage patterns portable across agents (enforcement, context injection, observability, completion gate)
- `wiki/index.md` (Sources: 3 new entries)

No new concepts/entities. The example patterns (block dangerous commands, warn on sensitive reads, audit, quality gate) are instances of patterns already covered by `progressive-disclosure-hooks` and the new §Common usage patterns in `agent-hook-compatibility`.

Project linking: `wiki/pages/cortex-forge.md` vinculado en todas las sources (dominio: hooks, cortex-forge).

Agent: Claude Code (claude-sonnet-4-6)

---

## 2026-06-08 — Agent (assimilate 9x Antigravity CLI docs)

**Operation**: bulk assimilation of 9 CLI documentation pages from `https://antigravity.google/docs/cli-*` into vault.

**Sources**:
- `.raw/antigravity-cli/cli-permissions.md` (3.0 KB)
- `.raw/antigravity-cli/cli-sandbox.md` (1.4 KB)
- `.raw/antigravity-cli/cli-settings.md` (2.5 KB)
- `.raw/antigravity-cli/cli-plugins.md` (2.7 KB)
- `.raw/antigravity-cli/cli-statusline.md` (2.5 KB)
- `.raw/antigravity-cli/cli-title.md` (1.3 KB)
- `.raw/antigravity-cli/cli-best-practices.md` (2.7 KB)
- `.raw/antigravity-cli/cli-troubleshooting.md` (2.9 KB)
- `.raw/antigravity-cli/cli-reference.md` (4.3 KB)

**Key technical finding**: the docs site is a **pure Angular SPA** — all `/docs/*` URLs serve the same 22.7 KB shell HTML (identical MD5 across all 9 pages). The `<title>` says only "Google Antigravity" and the body is `<app-root></app-root>`. The real content is fetched as **static markdown** from `/assets/docs/cli/<slug>.md` (revealed by grepping the bundle's template literal `` `/assets/docs/${t.path}/${e}.md` ``). This explains why Claude's WebFetch only returns the title — it has no JS execution and no knowledge of the assets path.

**Created**:
- `wiki/sources/antigravity-cli-permissions.md`
- `wiki/sources/antigravity-cli-sandbox.md`
- `wiki/sources/antigravity-cli-settings.md`
- `wiki/sources/antigravity-cli-plugins.md`
- `wiki/sources/antigravity-cli-statusline.md`
- `wiki/sources/antigravity-cli-title.md`
- `wiki/sources/antigravity-cli-best-practices.md`
- `wiki/sources/antigravity-cli-troubleshooting.md`
- `wiki/sources/antigravity-cli-reference.md`
- `wiki/entities/antigravity-cli.md` — consolidated entry: identity, config root, two-layer security model, customization layers, TUI rendering, statusline/title shared schema, subagent model

**No new concepts**: the pages describe a single product (Antigravity CLI). Knowledge is granular enough to live as 9 sources + 1 entity.

**Reusable asset** for future doc scrapes: pattern to detect static `.md` content behind a SPA shell is to grep the main JS bundle for `/assets/docs/` or similar template literals, then probe with `curl -I` until 200.

## [2026-06-08] translate | Translated existing entries to English

Files translated: `wiki/sources/gemini-cli-hooks-video.md`, `wiki/sources/understand-anything.md`, `wiki/meta/log.md`
Agent: Claude Code

## [2026-06-10] assimilate | 2 sources + 2 concepts from AI Coding Dictionary full articles

Sources: `wiki/sources/ai-coding-dictionary-primary-source.md`, `wiki/sources/ai-coding-dictionary-secondary-source.md`
Concepts: `wiki/concepts/primary-source.md`, `wiki/concepts/secondary-source.md`
Raw: `.raw/ai-coding-dictionary-primary-source.md`, `.raw/ai-coding-dictionary-secondary-source.md`
Agent: Claude Code
