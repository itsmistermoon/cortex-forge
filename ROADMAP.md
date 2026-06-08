# Roadmap

## Fase 1 — Multi-agent parity

Objetivo: que el Hot Cache Protocol funcione en todos los agentes soportados.

- [x] Claude Code — configurado vía `cortex-forge-setup`
- [x] Matriz de compatibilidad → `wiki/concepts/agent-hook-compatibility.md`
- [ ] Antigravity CLI — parcial
  - [ ] Correr `/cortex-forge-setup` desde Antigravity — muestra el bloque JSON a agregar
  - [x] Configurar hooks en `~/.gemini/config/hooks.json` (PreInvocation + Stop) — hecho manualmente; symlink a `~/.gemini/antigravity-cli/hooks.json` por bug agy-cli #49
  - [x] Verificar que `.hot/` se inyecta en contexto al iniciar sesión — Capa 1, primer turno reactivo (Capa 2 instalada pero pendiente verificación en sesión real)
  - [ ] Ejecutar `cortex-crystallize` y confirmar que `.hot/` se actualiza al cerrar
  - [x] Ingestar una fuente con `cortex-assimilate`
  - [ ] Consultar conocimiento con `cortex-recall` — falló, usó búsqueda manual
- [ ] Codex — parcial
  - [ ] Correr `/cortex-forge-setup` desde Codex — muestra el bloque JSON a agregar
  - [x] Pegar bloque en `~/.codex/hooks.json` (SessionStart + Stop)
  - [x] Verificar que `.hot/` se inyecta en contexto al iniciar sesión — hook nativo confirmado
  - [ ] Ejecutar `cortex-crystallize` y confirmar que `.hot/` se actualiza al cerrar
  - [ ] Ingestar una fuente con `cortex-assimilate`
  - [ ] Consultar conocimiento con `cortex-recall`
- [ ] CommandCode — parcial; Capa 1 confirmada, hooks de cierre pendientes
  - [x] Correr `/cortex-forge-setup` desde CommandCode — re-ejecutado; skills y symlinks actualizados
  - [ ] Pegar bloque de Stop hook en el archivo de hooks de CommandCode
  - [x] Verificar modo degradado sesión 1: agente lee `.hot/` vía `AGENTS.md` (Capa 1 confirmada — lectura en primer turno, contexto de proyecto inmediato)
  - [x] Verificar ciclo completo sesión 2: `.hot/` escrito en sesión 1 es leído correctamente en sesión 2
  - [x] Ejecutar `cortex-crystallize` y confirmar snapshot guardado
  - [x] Ingestar una fuente con `cortex-assimilate`
  - [ ] Consultar conocimiento con `cortex-recall` — falló proactivamente (usó `grep`); funciona bajo instrucción explícita
  - [x] Instalar TASTE rule (`## Cortex Forge Skills`) en `taste.md` per-project (second-brain) y global (`~/.commandcode/taste/`) — paso 7 de setup ejecutado por Claude Code; CommandCode no puede editar `taste/` por system policy

## Fase 2 — Hardening del protocolo

- [x] **Multi-vault**: `~/.cortex-forge/config.yml` con `vaults: {name: path}` + `default:`; vault resuelto por CWD primero, luego default; `cortex-forge-setup` registra/deregistra el vault actual (toggle por CWD); legacy `vault:` soportado en `cortex-crystallize`
- [ ] Versionado de schema en `AGENTS.md` y templates (`schema_version:`)
- [ ] `cortex-prune` automático vía hook periódico
- [ ] Detección de hot cache stale (sin actualizar en N días)
- [x] Campo `agent:` en frontmatter de snapshots `.hot/` — identifica qué agente escribió cada entrada; necesario para resolver conflictos en vaults multi-agente
- [ ] Split `Project state` / `Agent context` en `.hot/` — separar estado del proyecto (pendientes, decisiones) del contexto específico del agente (convenciones aprendidas, workarounds); patrón validado por MEMORY.md + USER.md de Hermes
- [ ] Context fencing en `cortex-imprint` — al escribir páginas wiki, la fuente de verdad es `.raw/`; las páginas wiki existentes son referencia, no fuente; previene contaminación circular donde el agente "recuerda" resúmenes de sus propias memorias
- [ ] Tags de comportamiento en skills (`behavior:` en frontmatter) — clasificar skills por lo que el agente *hace* (`#synthesize`, `#ingest`, `#recall`, `#prune`) además de su nombre; un skill con múltiples comportamientos es señal de que debe dividirse

## Fase 3 — Adoptabilidad

- [x] Agregar licencia al repo público
- [ ] Guía de onboarding: 5 minutos desde cero hasta primera ingesta
- [ ] Páginas de ejemplo en `wiki/concepts/` (demuestran el formato, no son contenido personal)
- [ ] `wiki/prompts/` como tipo de página opcional — permite al usuario archivar invocaciones efectivas del agente con ejemplo de output; el vault hoy almacena conocimiento del mundo pero no conocimiento operacional sobre cómo trabajar con el agente
- [ ] MOCs por área temática — `wiki/concepts/_index.md`, `wiki/entities/_index.md` como índices navegables por área, complementarios al índice global; facilita que el agente entre por el MOC correcto en vez de cargar todo el índice

## Fase 4 — Inteligencia acumulada

- [ ] `cortex-recall` con síntesis cross-página y detección de contradicciones
- [ ] Detección de patrones cross-sesión: temas recurrentes en `.hot/` que nunca llegan a `wiki/` — al crystallizar, revisar historial y proponer candidatos; patrón validado por dialectic reasoning de Honcho
- [ ] Carga progresiva en `cortex-recall` — navegar wiki como filesystem según relevancia en lugar de cargar el índice completo al inicio; reduce token bloat sin perder cobertura
