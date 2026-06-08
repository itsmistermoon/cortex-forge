# Vault index

[//]: # "Master index — maintained by the agent. Update after every cortex-assimilate or cortex-imprint operation."

## Projects
- [[wiki/pages/cortex-forge]] — Vault con protocolo de hot cache multi-agente (Claude Code, Codex, Antigravity, CommandCode)

## Concepts
- [[wiki/concepts/commandcode-taste]] — Sistema de personalización continua de CommandCode: paths per-project (.commandcode/taste/) y global (~/.commandcode/taste/), bucle de aprendizaje implícito, CLI push/pull
- [[wiki/concepts/agent-hook-compatibility]] — Matriz de lifecycle hooks por agente (Claude Code, Codex, Antigravity, CommandCode)
- [[wiki/concepts/antigravity-hooks]] — Configuración y ejecución de hooks en Google Antigravity / Gemini CLI
- [[wiki/concepts/progressive-disclosure-hooks]] — Patrón de carga just-in-time de contexto vía hooks y skills; evita token bloat al inicio de sesión
- [[wiki/concepts/karpathy-wiki-pattern]] — Patrón de diseño de wikis optimizados para consumo por LLM (parser determinista + capa semántica)
- [[wiki/concepts/treesitter-llm-hybrid-parsing]] — División de responsabilidades: parser determinista para hechos, LLM para interpretaciones
- [[wiki/concepts/multi-agent-analysis-pipeline]] — Orquestación de N agentes especializados con fan-out paralelo y validación por capa

## Entities
- [[wiki/entities/google-antigravity]] — Plataforma de desarrollo agent-first orientada a flujos de trabajo autónomos
- [[wiki/entities/antigravity-cli]] — CLI de Google Antigravity: binary `agy`, modelo de permisos de dos capas, sandbox OS-level, plugins/skills/hooks
- [[wiki/entities/commandcode]] — Agente de código AI con personalización continua TASTE; hooks Stop/SessionStart, config en `.commandcode/`
- [[wiki/entities/understand-anything]] — Plugin multi-plataforma de Lum1104 que construye grafos de conocimiento sobre codebases y wikis

## Sources
- [[wiki/sources/antigravity-hooks]] — Documentación de hooks en Google Antigravity (ingestado 2026-06-07)
- [[wiki/sources/codex-hooks]] — Documentación de hooks en Codex (ingestado 2026-06-08)
- [[wiki/sources/commandcode-hooks-configuration]] — Configuración de hooks en Command Code: scopes, precedencia y orden (ingestado 2026-06-08)
- [[wiki/sources/commandcode-hooks-reference]] — Referencia técnica: wire format I/O, exit codes, HookDefinition/HookEntry (ingestado 2026-06-08)
- [[wiki/sources/commandcode-hooks-examples]] — 4 patrones de hooks listos para adaptar: enforcement, context injection, auditoría, quality gate (ingestado 2026-06-08)
- [[wiki/sources/commandcode-hooks-best-practices]] — Seguridad, performance y debugging de hooks en CommandCode (ingestado 2026-06-08)
- [[wiki/sources/gemini-cli-hooks-video]] — Video oficial de Gemini CLI hooks & skills — Google Cloud Live (ingestado 2026-06-08)
- [[wiki/sources/understand-anything]] — README de github.com/Lum1104/Understand-Anything (ingestado 2026-06-08)
- [[wiki/sources/antigravity-cli-permissions]] — Permisos por acción (`read_file`, `write_file`, `command`, etc.) y preset modes
- [[wiki/sources/antigravity-cli-sandbox]] — Sandbox OS-level: nsjail/sandbox-exec/AppContainer, configuración y escape controlado
- [[wiki/sources/antigravity-cli-settings]] — Todas las claves de `settings.json` con tipos, defaults y descripción
- [[wiki/sources/antigravity-cli-plugins]] — Sistema de plugins: estructura de bundle, subcommands `agy plugin *`, skills y MCP por plugin
- [[wiki/sources/antigravity-cli-statusline]] — Status line: payload JSON, configuración en `settings.json`, script de referencia
- [[wiki/sources/antigravity-cli-title]] — Terminal title: mismo payload que statusline, strip de ANSI, toggle `/title`
- [[wiki/sources/antigravity-cli-best-practices]] — Buenas prácticas: permisos mínimos, AGENTS.md, checkpoints, subagents
- [[wiki/sources/antigravity-cli-troubleshooting]] — Troubleshooting: auth, sandbox, permisos, MCP, rendimiento
- [[wiki/sources/antigravity-cli-reference]] — Referencia completa: slash commands, keybindings, claves settings.json
- [[wiki/sources/commandcode-taste-blog]] — Introducción a TASTE: three-layer stack, bucle de aprendizaje, resultados empíricos
- [[wiki/sources/commandcode-taste-docs]] — Documentación oficial TASTE: formato taste.md, scopes, gestión
- [[wiki/sources/commandcode-taste-manage]] — Gestión de perfiles TASTE: push/pull, Studio, lint, ámbitos
- [[wiki/sources/commandcode-taste-commands]] — Referencia de comandos `npx taste` / `cmd taste`

## Meta
- [[wiki/meta/log]] — Append-only vault operation log
- [[wiki/meta/_index|Vault meta]]
- `templates/` — 5 page templates (concept, entity, source, project, wiki-page)
- `bin/setup-vault.sh` — setup script
- `skills/` — agent skills (cortex-assimilate, cortex-recall, cortex-prune, cortex-imprint, cortex-crystallize, cortex-forge-setup)
