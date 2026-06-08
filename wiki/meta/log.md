# Vault operation log

Append-only log of significant vault operations. Each entry added by `cortex-assimilate`, `cortex-imprint`, or `cortex-prune`.

## Format

```
## [YYYY-MM-DD] {operation} | {description}
```

Operations: `ingest`, `imprint`, `prune`, `query`

---

<!-- entries below -->

## [2026-06-08] ingest | CommandCode TASTE — 4 fuentes oficiales

Sources: `.raw/commandcode-taste-blog.md`, `.raw/commandcode-taste-docs.md`, `.raw/commandcode-taste-manage.md`, `.raw/commandcode-taste-commands.md`
Pages created: `wiki/sources/commandcode-taste-{blog,docs,manage,commands}.md`, `wiki/concepts/commandcode-taste.md`
Key finding: TASTE tiene dos ámbitos con paths concretos — per-project en `.commandcode/taste/` y global en `~/.commandcode/taste/` (flag `-g`). Resuelve el pendiente de scope para TASTE rule de `cortex-recall`.

## [2026-06-08] ingest | Gemini CLI Hooks & Skills (youtube.com/watch?v=ZXYuiEMm21s)

Source: `.raw/gemini-cli-hooks-video.md` (transcript limpio via yt-dlp)

Created:
- `wiki/sources/gemini-cli-hooks-video.md` (type: source, confidence: medium)
- `wiki/concepts/progressive-disclosure-hooks.md` (type: concept)

Updated:
- `wiki/concepts/antigravity-hooks.md` — contradicción `settings.json` vs `hooks.json` documentada; scopes y ruta de scripts aclarados
- `wiki/index.md` (Concepts, Sources)

Project linking: skipped (no hay proyectos activos en `wiki/pages/`).

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

Source: `.raw/understand-anything.md` (README principal, 350 líneas, descargado desde raw.githubusercontent.com)

Created:
- `wiki/sources/understand-anything.md` (type: source, confidence: high)
- `wiki/entities/understand-anything.md` (type: entity)
- `wiki/concepts/karpathy-wiki-pattern.md` (type: concept)
- `wiki/concepts/treesitter-llm-hybrid-parsing.md` (type: concept)
- `wiki/concepts/multi-agent-analysis-pipeline.md` (type: concept)

Updated:
- `wiki/index.md` (4 secciones: Projects, Concepts, Entities, Sources)

Project linking: skipped — no hay proyectos activos en `wiki/pages/` con `status: active`. Understand Anything es un proyecto third-party (MIT, Lum1104), no del usuario; no se crea `wiki/pages/` page según criterio de la skill.

Concepts skipped (considerados pero descartados por falta de nombre propio transferible o especificidad UI):
- Persona-adaptive UI (UI-específico, sin identidad conceptual reusable)
- Fingerprint-based incremental (sub-concepto de `treesitter-llm-hybrid-parsing`, ya cubierto)
- Diff impact analysis (genérico, sin nombre propio)

Cross-references: [[wiki/concepts/agent-hook-compatibility]] (matriz de hooks solapa con la matriz multi-plataforma de la fuente — ambas plataforma × evento).

Agent: CommandCode (MiniMax-M3)

## [2026-06-08] ingest | CommandCode Hooks Configuration (commandcode.ai/docs/hooks/configuration)

Source: `.raw/commandcode-hooks-configuration.md` (fetched via curl, 2.4KB limpio)

Created:
- `wiki/sources/commandcode-hooks-configuration.md` (type: source, confidence: high)

Updated:
- `wiki/concepts/agent-hook-compatibility.md` — sección CommandCode ampliada con scopes (user vs project), precedencia, orden PreToolUse/PostToolUse, semántica de cortocircuito, y wire format anidado
- `wiki/index.md` (Sources)

No new concepts/entities created. La fuente es configuración operacional de un producto ya cubierto por `wiki/concepts/agent-hook-compatibility` y `wiki/sources/commandcode-hooks-configuration` (referenciada en el concept). El wire format anidado distinto de Codex/Claude Code es nota operacional, no un concepto reusable con nombre propio.

Project linking: skipped — `wiki/pages/` solo contiene `.gitkeep`; no hay proyectos activos del usuario con `status: active`. El knowledge de cortex-forge vive como pages, no como wiki project page.

Hallazgo operativo clave: el wire format oficial de CommandCode (`hooks: [{ matcher, hooks: [{ type, command, timeout? }] }]`) difiere del wire format plano de Claude Code/Codex. Los scripts de hot cache escritos para Claude Code/Codex NO son drop-in para CommandCode; habría que envolver cada handler en un sub-array `hooks` por matcher.

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
- `wiki/concepts/agent-hook-compatibility.md` — I/O schema completo de CommandCode (campos `permissionDecision`, `additionalContext`, `systemMessage`, `decision`, `continue`; semántica de exit codes), sección de seguridad/performance (no eval, jq -r, timeout <10s, plan mode, chmod +x, debugging con --debug), tabla de patrones de uso comunes portable entre agentes (enforcement, context injection, observabilidad, completion gate)
- `wiki/index.md` (Sources: 3 entradas nuevas)

No new concepts/entities. Los patrones de ejemplos (block dangerous commands, warn on sensitive reads, audit, quality gate) son instancias de patrones ya cubiertos por `progressive-disclosure-hooks` y el nuevo §Patrones de uso comunes en `agent-hook-compatibility`.

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
