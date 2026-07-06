# Vault operation log

Append-only log of significant vault operations. Each entry added by `cortex-assimilate`, `cortex-imprint`, or `cortex-prune`.

## Format

```
## [YYYY-MM-DD] {operation} | {description}
```

Operations: `ingest`, `imprint`, `prune`, `query`

---

<!-- entries below -->

## [2026-07-01] ingest | 4 sources on skill design and optimization

Sources:
- `.raw/writing-great-skills.md` → `wiki/sources/writing-great-skills.md`
- `.raw/anthropic-skill-creator.md` → `wiki/sources/anthropic-skill-creator.md`
- `.raw/compound-engineering-plugin.md` → `wiki/sources/compound-engineering-plugin.md`
- `.raw/skill-optimization-loop.md` → `wiki/sources/skill-optimization-loop.md`

Pages created: `wiki/entities/compound-engineering.md`, `wiki/concepts/skill-self-improvement-loop.md`
Pages updated: `wiki/concepts/skill-design-principles.md` (sources upgraded to primary)

Agent: Claude Code

## [2026-07-01] skill-improvement | Backward enrichment + drift detection implemented

Step 9 added to `cortex-assimilate`: after ingest, scans existing wiki pages for tag overlap, classifies as ENRICHABLE/FALSE_POSITIVE, proposes updates with confirmation required.
Layer 3 added to `cortex-prune`: compares mtime of `.raw/` files against `updated:` in corresponding `wiki/sources/` pages; MEDIUM finding when `.raw/` is newer.

Agent: Claude Code

## [2026-07-01] imprint | Backward enrichment + drift detection patterns designed

Two related staleness patterns identified and documented during OpenWiki ingestion analysis:

**Backward enrichment**: after ingesting a new source, existing wiki pages that share `tags:` and have `updated:` before the ingestion date are candidates for update — concept pages, entity entries, and comparison tables that should now mention the new source. Detection: O(pages) tag scan; evaluation by agent before any write. Planned as a step in `cortex-assimilate`.

**Drift detection**: sources whose `.raw/` file was modified after their `wiki/sources/` page was last synthesized. Planned as Layer 3 in `cortex-prune`. Surfaced by the OpenWiki git-diff-scoped update pattern (`lastHead` in `.last-update.json` → only feed changed commits to the agent).

Both mechanisms use structured page metadata (tags, updated:, raw: frontmatter field) to detect staleness without re-reading all content.

Documented in: `wiki/projects/cortex-forge.md` (Key decisions + Roadmap Phase 4), `README.md` (`/cortex-assimilate` section).

Agent: Claude Code

## [2026-06-10] ingest | Codex hooks docs refresh

Checked `https://developers.openai.com/codex/hooks` against the existing vault source before rewriting anything. The source was already present as `.raw/codex-hooks.md` and `wiki/sources/codex-hooks.md`, so no new raw capture was needed.

Updated:
- `wiki/sources/codex-hooks.md` — refreshed summary with current docs details: hooks are enabled by default, multiple matches all run, `/hooks` is the review path, `Stop` ignores `matcher`, and `transcript_path` is only a convenience field

Updated by request to keep the synthesized source aligned with the current official docs while respecting the "do not ingest if already consumed" constraint.

Agent: Codex

## [2026-06-10] query | Agent hook compatibility refreshed with current Codex docs

Updated `wiki/concepts/agent-hook-compatibility.md` to reflect the current Codex hook behavior documented on `https://developers.openai.com/codex/hooks`:
- hooks are enabled by default
- multiple matching hooks across files all run
- `/hooks` is the review/trust/disable surface for non-managed hooks
- `Stop` ignores `matcher`
- `transcript_path` is convenience input, not a stable contract

Agent: Codex

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

Project linking: skipped (no active projects in `wiki/projects/`).

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

## [2026-06-28] fix | Codex hook behavior hardened

- Retired full hot-cache injection for Codex `SessionStart`; the Codex-specific hook now returns `{}` so `.cortex/MEMORY.md` is not rendered into the conversation as visible hook context.
- Retired automatic Codex `Stop` crystallization; the Codex-specific hook now returns `{}` instead of delegating to the Claude transcript parser.
- Updated setup and compatibility docs to mark Codex hot-cache persistence as manual-only via `/cortex-crystallize`.

Agent: Codex

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

Project linking: skipped — no active projects in `wiki/projects/` with `status: active`. Understand Anything is a third-party project (MIT, Lum1104), not the user's; no `wiki/projects/` page created per skill criteria.

Concepts skipped (considered but discarded due to lack of transferable proper name or UI specificity):
- Persona-adaptive UI (UI-specific, no reusable conceptual identity)
- Fingerprint-based incremental (sub-concept of `treesitter-llm-hybrid-parsing`, already covered)
- Diff impact analysis (generic, no proper name)

Cross-references: [[wiki/concepts/agent-hook-compatibility]] (hooks matrix overlaps with source's multi-platform matrix — both platform × event).

Agent: CommandCode

## [2026-06-13] ingest | CommandCode Models reference

Source: `https://commandcode.ai/docs/reference/cli/models`
Raw: `.raw/commandcode-models-reference.md`
Pages created: `wiki/reference/commandcode-models.md`
Updated: `wiki/index.md`
Key finding: `google/gemini-3.1-flash-lite` es el modelo id para Gemini 3.1 Flash Lite. Matching acepta short form (`gemini-3.1-flash-lite`) sin el prefijo `google/`. Default actual de CommandCode: `moonshotai/Kimi-K2.5`.
SPA: no aplica (HTML plano). Sanitization: 0 findings. (MiniMax-M3)

## [2026-06-08] ingest | CommandCode Hooks Configuration (commandcode.ai/docs/hooks/configuration)

Source: `.raw/commandcode-hooks-configuration.md` (fetched via curl, 2.4KB clean)

Created:
- `wiki/sources/commandcode-hooks-configuration.md` (type: source, confidence: high)

Updated:
- `wiki/concepts/agent-hook-compatibility.md` — CommandCode section expanded with scopes (user vs project), precedence, PreToolUse/PostToolUse order, short-circuit semantics, and nested wire format
- `wiki/index.md` (Sources)

No new concepts/entities created. The source is operational configuration for a product already covered by `wiki/concepts/agent-hook-compatibility` and `wiki/sources/commandcode-hooks-configuration` (referenced in the concept). The nested wire format differing from Codex/Claude Code is an operational note, not a reusable concept with a proper name.

Project linking: skipped — `wiki/projects/` only contains `.gitkeep`; no active user projects with `status: active`. Cortex-forge knowledge lives as pages, not as a wiki project page.

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

Project linking: `wiki/projects/cortex-forge.md` vinculado en todas las sources (dominio: hooks, cortex-forge).

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

## [2026-06-13] fix | CommandCode Stop hook timeout

Stop hook estaba fallando con timeout de 30s default — la síntesis IA via `cmd -p` requiere llamada API que toma 20-60s. Agregado `"timeout": 120` al hook en `.commandcode/settings.local.json`. Testeado con transcript real de 297 líneas y 156 tool calls: completado en 22s, produjo `#### What was done / Discarded / Fragile context` correctos.
Updated: `skills/cortex-forge-setup/SKILL.md` (CommandCode hook example corregido), `wiki/reference/workflow-architecture.md` (nota de timeout)

## [2026-06-13] create | Workflow architecture reference

Pages created: `wiki/reference/workflow-architecture.md`
Updated: `wiki/index.md` (Reference section), `docs/hot-cache-protocol.md` (outdated notice redirecting to new doc)
Cobertura: 3 fases de sesión, tabla de skills por evento, 7 hook scripts catalogados con su propósito y agente target, triggers adicionales (compact/clear/resume/fullyIdle), modos degradados por plataforma, config files por agente. El doc viejo `hot-cache-protocol.md` mencionaba scripts `load-hot-cache.sh`/`update-hot-cache.sh` que ya no existen — actualizado con redirect.

## [2026-06-13] upgrade | CommandCode crystallize — IA synthesis via `cmd -p`

`bin/hooks/cortex-crystallize-commandcode.sh` reescrito para usar `cmd -p` headless mode para síntesis IA, replicando el patrón de `cortex-crystallize-claude.sh`. Extrae user messages, tool calls y última respuesta del transcript JSONL via jq, construye prompt estructurado, y escribe en `.hot/MEMORY.md` con formato `#### What was done / Discarded / Fragile context`. Reemplaza la entrada mínima "Session closed via Stop hook."

Dependencias: `cmd` en PATH (encontrado en `/opt/homebrew/bin/cmd` v0.37.1). Fallback: si `cmd` no está disponible o la síntesis falla, el script sale silenciosamente (exit 0). El transcript se resuelve desde el campo `transcript_path` del hook payload, con fallback de slug derivado de CWD y búsqueda global en `~/.commandcode/projects/`.

Updated: `wiki/concepts/agent-hook-compatibility.md` (matrix + síntesis upgrade section)

## [2026-06-13] ingest | CommandCode Security & Privacy docs

Sources: `.raw/commandcode-security.md`
Pages created: `wiki/sources/commandcode-security.md`
Updated: `wiki/sources/commandcode-headless.md` (cross-reference to security), `wiki/index.md`, `wiki/projects/cortex-forge.md`
Key finding: `cmd -p --yolo` is the headless equivalent of `claude -p` for synthesis in hooks, but requires explicit `--yolo` to enable writes. Crystallize hooks currently do not use this — they just append minimal "Session closed via Stop hook." entries.

## [2026-06-13] fix | `cortex-prune.sh` — multi-source page detection

`raw_without_source_page` estaba generando falsos positivos para raws referenciados via el campo `sources:` (lista YAML multi-source), porque el script solo revisaba `raw:` (single-source) y matches de filename. Ejemplo: `.raw/graphify-agents.md` referenciado en `wiki/sources/graphify.md` via `sources:` era reportado como huérfano.

Fix: agregado un tercer chequeo intermedio — `grep -rl "^  - ${rel}$"` sobre `wiki/sources/` — entre el check de `raw:` y el fallback de filename. Vault-report ahora registra 0 findings.

Agent: CommandCode

## [2026-06-16] ingest | Pi CLI documentation (7 pages)

Sources: `.raw/pi-usage.md`, `.raw/pi-extensions.md`, `.raw/pi-packages.md`, `.raw/pi-models.md`, `.raw/pi-custom-provider.md`, `.raw/pi-session-format.md`, `.raw/pi-terminal-setup.md`
Pages created: 7 in `wiki/sources/pi-*.md`, 1 entity `wiki/entities/pi-cli.md`, 1 concept `wiki/concepts/pi-extension-lifecycle.md`, 8 references in `wiki/reference/pi-*.md` (cli-flags, slash-commands, session-file-format, terminal-compat, models-json, provider-api-types, event-types, extension-api)
Updated: `wiki/index.md`
Key findings:
- Pi is `earendil-works/pi-mono` (NOT `badlogic` — `badlogic/pi-share-hf` is a separate companion project for HF dataset publishing)
- Design philosophy: small core, opt-in everything else (no built-in MCP, sub-agents, permission popups, plan mode, to-dos, or background bash)
- Extension system: TypeScript async factory pattern, lifecycle events (startup/session/agent/tool/user_bash/input), two-state model (CustomEntry vs CustomMessageEntry)
- Sessions: JSONL with id/parentId tree structure (v1→v2→v3), enabling in-place fork/clone
- Multi-provider: declarative `~/.pi/agent/models.json` (static) or programmatic `pi.registerProvider()` (dynamic, async factory)
- OAuth/SSO integrated into `/login` via provider's `oauth` block
- Custom streaming APIs via `streamSimple` event protocol on `createAssistantMessageEventStream`
- 9 supported API types: anthropic-messages, openai-completions, openai-responses, azure-openai-responses, openai-codex-responses, mistral-conversations, google-generative-ai, google-vertex, bedrock-converse-stream
- Sub-agent B (references) wrote 8 files directly; sub-agent A (sources/entity/concept) had no write tool, content was written by main agent from the returned payload.

Agent: CommandCode (MiniMax M3)
## [2026-06-24] imprint | No-Op Audit with Adversarial Subagent Debate

## [2026-06-26] session | Register e7c0e19, fix graphify wikilink, validate post-commit prune hook
- Registered commit `e7c0e19` in `CHANGELOG.md` and pushed.
- Fixed the escaped wikilink in `wiki/entities/graphify.md`.
- Pulled `nomic-embed-text` via Ollama.
- Installed and validated the post-commit prune hook in the personal vault (`moon-multivac`), confirming background execution and logging.

Agent: Antigravity (Gemini 3.5 Flash)

## [2026-06-26] migrate | AGENT-LOG to wiki/meta/agent-diagnostics
- Migrated `AGENT-LOG.md` from the root directory to `wiki/meta/agent-diagnostics.md`.
- Updated `wiki/index.md` to register `wiki/meta/agent-diagnostics` in the master index (file later deleted 2026-07-04 — see `wiki/concepts/agent-hook-compatibility.md`).
- Confirmed that the global hook configuration for Antigravity (Gemini 3.5 Flash) is fully aligned and functional.

Agent: Antigravity (Gemini 3.5 Flash)

## [2026-06-28] auto-imprint | Crystallize Automation Architecture

## [2026-06-29] fix | cortex-forge-setup: formato de hook incorrecto en spec de Claude Code

**Problema:** El paso 6 de `skills/cortex-forge-setup/SKILL.md` especificaba los hooks de Claude Code como objetos de comando crudos:
```json
[{ "type": "command", "command": "~/.claude/hooks/cortex-reactivate.sh" }]
```

El formato correcto requiere un wrapper con `matcher` y `hooks`:
```json
[{ "matcher": "", "hooks": [{ "type": "command", "command": "~/.claude/hooks/cortex-reactivate.sh" }] }]
```

**Impacto:** Cuando se ejecutó `/cortex-forge-setup hooks`, el skill aplicó este formato directamente a `~/.claude/settings.json`, creando un segundo entry malformado (index `[1]`) en los eventos `SessionStart`, `PreCompact` y `SessionEnd` — junto al entry válido (index `[0]`) que ya existía con la estructura correcta. El diagnóstico `/doctor` reportó `hooks.SessionStart.1.hooks: Expected array, but received undefined` para los tres eventos.

**Corrección aplicada:**
- `~/.claude/settings.json` — eliminados los tres entries malformados (`[1]`) de `SessionStart`, `PreCompact` y `SessionEnd`. Los entries válidos al index `[0]` permanecen intactos.
- `skills/cortex-forge-setup/SKILL.md` líneas 174–179 — corregido el formato en la spec para que futuras ejecuciones del skill escriban la estructura correcta con `matcher` + `hooks`.

Agent: Claude Code (Sonnet 4.6)


## [2026-06-30] refactor | consolidación del sistema de types a 4 tipos canónicos

**Decisión:** Resultado de debate adversarial (5 posturas + evaluador). Sistema reducido de 6 a 4 tipos:

| Eliminado | Absorbido por | Motivo |
|---|---|---|
| `reference` | `concept` | Sin campos propios — cheatsheet vs. síntesis es diferencia editorial, no ontológica |
| `series` | `source` | Schema idéntico a otros tipos; colección ordenada = source con body estructurado |

**Tipos canónicos resultantes:** `source · concept · entity · project`

**Cambios aplicados en moon-cortexforge:**
- 11 páginas `wiki/reference/` migradas a `type: concept`
- `cortex-validate-schema.sh` simplificado: eliminados `fields_reference` y `fields_series`
- `templates/reference.md` eliminado
- `AGENTS.md` actualizado con tabla de 4 tipos + guías de decisión (concept vs entity, concept vs source)

**Pendiente:** Aplicar migración equivalente en moon-multivac y demás vaults registrados.

Agent: Claude Code (Sonnet 4.6)

## [2026-07-01] skill-improvement | Auditoría completa del skill suite (adversarial review + SkillOpt)

Revisión de 6 skills (cortex-assimilate, cortex-crystallize, cortex-imprint, cortex-prune, cortex-recall, cortex-forge-setup) con tres subagentes de review adversarial + hallazgos del repo SkillOpt (microsoft). 13 archivos modificados, 2 nuevos (skill-sync.yml, check-skill-sync.sh), 2 wiki pages creadas.

Cambios principales: descripciones enriquecidas con trigger phrases, sección ## Constraints para restricciones críticas, graceful failure en 4 skills, migración CODEX.md → AGENTS.md, JSON inválidos corregidos, formato `vaults:` consolidado, PRAXIS-FORMAT.md traducido al inglés, CI agregado.

Agent: Claude Code (Sonnet 4.6)

## [2026-07-01] skill-improvement | Auditoría capa 2 — writing-great-skills framework

Segunda pasada sobre el skill suite aplicando el framework writing-great-skills (mattpocock). 9 hallazgos resueltos en 2 commits (d3f6b2e, 99dccc5).

Cambios principales: locale resolution extraído a LOCALE-RESOLUTION.md (single source of truth, 5 archivos simplificados), `disable-model-invocation: true` en cortex-imprint, ## When to invoke eliminado de assimilate e imprint, Rules de cortex-recall deduplicadas contra Constraints, step 6d de forge-setup extraído a EMBEDDING-SETUP.md, sediment español eliminado de cortex-prune, completion criterion checkable en assimilate step 5, YAML de config movido al step 3 correcto.

Agent: Claude Code (Sonnet 4.6)

## [2026-07-01] refactor | wiki/meta/_index.md redefinido como guía humana del directorio

_index.md reescrito: tabla de archivos, qué va/no va en meta/, formato canónico del log. AGENTS.md ## On session close expandido con trigger explícito para log.md y distinción log vs /cortex-imprint.

Agent: Claude Code (Sonnet 4.6)

## [2026-07-03] refactor | Hooks eliminados, scripts co-located, auditoría fail-loud, v0.6.0 consolidado

Trabajo de dos días consolidado bajo un solo release v0.6.0: (1) hooks de ciclo de vida del agente eliminados en los 4 agentes soportados, reemplazados por protocolo manual vía AGENTS.md; (2) scripts de skills relocalizados de bin/ a co-located dentro de cada skills/<name>/ para soportar instalación vía `npx skills add` (skills.sh); (3) auditoría fail-loud de todos los scripts — timeouts faltantes, mktemp sin chequear, rutas rotas — que atrapó una regresión del mismo día (cortex-validate-schema.sh no co-located); (4) escrituras atómicas para vault-report.json y config.yml; (5) cortex-forge-setup ahora detecta runtime del tarball incompleto y sugiere npx skills add. Ver wiki/projects/cortex-forge.md Key decisions y wiki/concepts/agent-hook-compatibility.md para el detalle completo.

Agent: Claude Code (Sonnet 5)

## [2026-07-05] refactor | Changelog de las 5 skills con historial movido a wiki/meta/

La sección `## Changelog` de `cortex-assimilate`, `cortex-crystallize`, `cortex-imprint`, `cortex-prune` y `cortex-recall` fue extraída a `wiki/meta/{skill-name}-changelog.md` (uno por skill), dejando el `SKILL.md` solo con instrucciones operativas. Se revisó el árbol git de cada skill para confirmar que ninguna entrada histórica se perdió — el historial en git nunca mostró una eliminación real de `## Changelog`, así que el contenido movido es el acumulado completo. `cortex-forge-setup` no tenía sección de changelog, no requirió cambios. `wiki/meta/_index.md` actualizado con la nueva convención de archivo.

Agent: Claude Code (Sonnet 5)

## [2026-07-06] prune | 9 HIGH / 14 MEDIUM / 17 LOW findings

Layer 1 (`cortex-prune.sh`): 3 dead wikilinks sin candidato de retarget, 6 `wiki/meta/*-changelog.md` marcados sin frontmatter/orphan — falsos positivos: el regex de exclusión del script (`_index|/index\.md|/log\.md`) no contemplaba `*-changelog.md` pese a que `wiki/meta/_index.md` ya documenta esos archivos como operational records fuera del grafo de wikilinks. Corregido en la misma pasada: el regex ahora excluye `wiki/meta/` completo de los checks de frontmatter y orphan (`_index|/index\.md|/log\.md|/meta/`) — re-verificado contra el vault real, HIGH bajó de 9 a 3, MEDIUM de 14 a 8. Layer 2: 5 relaciones sin wikilink cruzado (L2a), veredicto KEEP_SEPARATE para `karpathy-wiki-pattern.md`/`vault-design-karpathy-vs-hq.md` (L2d), 17 menciones sin wikilink (L2b), cobertura de fuentes completa (L2c, sin hallazgos). Layer 3: sin drift.

Auto-aplicado: `wiki/concepts/embedding-backend-selection.md` (orphan real) indexado en `wiki/index.md`; los 17 wikilinks L2b agregados. No aplicado (requiere confirmación): 3 dead links, `aliases:` faltantes en 2 páginas, texto desactualizado de hooks en 3 páginas (`crystallize-vs-imprint.md`, `handoff-artifact.md`, `super-context.md`).

Agent: Claude Code (Sonnet 5)

## [2026-07-06] refactor | AGENTS.md recortado — protocolos eliminados, solo queda la lectura obligatoria

Las 3 secciones "{Crystallize,Assimilate,Recall} protocol — MANDATORY" (123 líneas totales) se redujeron a una sola sección "Session start" de 3 líneas: leer `.cortex/MEMORY.md` (+ `PRAXIS.md` si existe) antes de la primera respuesta, y proponer `/cortex-imprint` si la última entrada de History tiene un flag `#### Imprint candidate`. Decisión explícita del usuario: las skills deben valerse por sí mismas (cada una ya dispara sola vía su propio `description:`), `AGENTS.md` no debe duplicar esa lógica.

Evaluado caso a caso qué del protocolo Crystallize sobrevivía: la alerta de stale-cache y la lectura directa de `wiki/meta/vault-report.json` se eliminaron (redundantes con el ítem de `### Pending` que `cortex-crystallize` ya escribe en cada corrida); la lectura de `PRAXIS.md` y el nudge de Imprint candidate se mantuvieron (sin dueño natural en ninguna skill, se pierden silenciosamente si no quedan en algún lado).

Efecto en cascada: `bin/check-skill-sync.sh`'s `vault-report-schema` check verificaba que los 4 campos del schema de `vault-report.json` aparecieran en `AGENTS.md` — ahora ya no aparecen ahí, así que el check se corrigió para verificar contra `cortex-crystallize/SKILL.md` (el consumidor real desde hoy). `wiki/concepts/skill-dependency-graph.md` y `wiki/concepts/workflow-architecture.md` actualizados para reflejar el nuevo flujo (prune → crystallize → Pending, no prune → AGENTS.md directo).

Verificado: `bash skills/cortex-prune/scripts/cortex-prune.sh .` — 0 HIGH/MEDIUM/LOW. `bin/check-skill-sync.sh`: 31/31.

Agent: Claude Code (Sonnet 5)
