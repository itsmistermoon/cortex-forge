# Roadmap

## Fase 1 — Multi-agent parity

Objetivo: que el Hot Cache Protocol funcione en todos los agentes soportados.

- [x] Claude Code — configurado vía `cortex-forge-setup`
- [x] Matriz de compatibilidad → `wiki/concepts/agent-hook-compatibility.md`
- [ ] Antigravity CLI — parcial
  - [ ] Correr `/cortex-forge-setup` desde Antigravity — muestra el bloque JSON a agregar
  - [x] Configurar hooks en `~/.gemini/config/hooks.json` (PreInvocation + Stop) — migrado a `cortex-reactivate-antigravity.sh` + `cortex-crystallize-antigravity.sh`; symlink a `~/.gemini/antigravity-cli/hooks.json` por bug agy-cli #49
  - [x] **PROBAR**: `cortex-reactivate-antigravity.sh` inyecta Zone 1 de `.hot/` al inicio — sin payload devuelve `{"injectSteps":[]}` (correcto); con `invocationNum=0` + workspace inyecta Zone 1 correctamente
  - [x] **REESCRIBIR**: `cortex-crystallize-antigravity.sh` — script original usaba `jq` sobre el transcript; Antigravity guarda transcripts como SQLite+Protobuf (`.db`), no JSON. Script reescrito para extraer via `strings $TRANSCRIPT | grep -oE '"toolSummary":"[^"]*"'` y mensajes de usuario desde `history.jsonl`. Fix de portabilidad: `grep -P` → `grep -E` (BSD grep en macOS). Guard `[ -z "$TOOL_SUMMARIES" ] && exit 0` protege sesiones de solo lectura.
  - [ ] **VALIDAR** en sesión orgánica real: `fullyIdle==true` dispara hook → `agy -p` sobre transcript real → síntesis descriptiva escrita en `.hot/MEMORY.md` — script probado con transcript histórico (bb3be9d0) ✅; trigger real pendiente ❌
  - [x] **VERIFICAR**: contradicción en path de `settings.json` — no existe `~/.gemini/config/settings.json`; el archivo real es `~/.gemini/antigravity-cli/settings.json`
  - [x] Ingestar una fuente con `cortex-assimilate`
  - [ ] Consultar conocimiento con `cortex-recall` — falló, usó búsqueda manual
- [ ] Codex — parcial
  - [ ] Correr `/cortex-forge-setup` desde Codex — verificar que detecta config existente y ofrece "Update"
  - [x] Pegar bloque en `~/.codex/hooks.json` (SessionStart + Stop)
  - [x] Verificar que `.hot/` se inyecta en contexto al iniciar sesión — hook nativo confirmado; `hook context:` visible en UI es comportamiento de diseño, no error de parsing
  - [x] Crear `cortex-crystallize-codex.sh` — wrapper de 12 líneas que delega en `cortex-crystallize-claude.sh` con `AGENT_LABEL=Codex`; instalado en `~/.codex/hooks/cortex-crystallize-codex.sh`
  - [ ] **VALIDAR** flujo end-to-end: SessionStart inyecta `.hot/` → trabajo real → Stop dispara wrapper → síntesis escrita — wrapper creado ✅; validación en sesión orgánica pendiente ❌
  - [ ] Ingestar una fuente con `cortex-assimilate`
  - [ ] Consultar conocimiento con `cortex-recall`
- [ ] CommandCode — parcial; Capa 1 confirmada, hooks de cierre pendientes
  - [x] Correr `/cortex-forge-setup` desde CommandCode — re-ejecutado; skills y symlinks actualizados
  - [x] Pegar bloque de Stop hook en el archivo de hooks de CommandCode — copiado a `second-brain/.commandcode/settings.local.json` con wire format anidado
  - [x] Verificar modo degradado sesión 1: agente lee `.hot/` vía `AGENTS.md` (Capa 1 confirmada — lectura en primer turno, contexto de proyecto inmediato)
  - [x] Verificar ciclo completo sesión 2: `.hot/` escrito en sesión 1 es leído correctamente en sesión 2
  - [x] Ejecutar `cortex-crystallize` y confirmar snapshot guardado
  - [x] Ingestar una fuente con `cortex-assimilate`
  - [ ] Consultar conocimiento con `cortex-recall` — falló proactivamente (usó `grep`); funciona bajo instrucción explícita
  - [x] Instalar TASTE rule (`## Cortex Forge Skills`) en `taste.md` per-project (second-brain) y global (`~/.commandcode/taste/`) — paso 7 de setup ejecutado por Claude Code; CommandCode no puede editar `taste/` por system policy

## Fase 2 — Hardening del protocolo

- [x] **Detección de agente en `cortex-crystallize` (paso 1a)** — 3 niveles: (1) env vars (`CLAUDECODE=1`, `AI_AGENT` — Claude Code ✅); (2) árbol de procesos desde `$PPID` buscando binario conocido — CommandCode ✅; (3) `which` como fallback parcial. Antigravity y Codex: hipótesis proceso-árbol, pendientes de validación en sesión real.
- [x] **Multi-vault**: `~/.cortex-forge/config.yml` con `vaults: {name: path}` + `default:`; vault resuelto por CWD primero, luego default; `cortex-forge-setup` registra/deregistra el vault actual (toggle por CWD); legacy `vault:` soportado en `cortex-crystallize`
- [x] Guardrails de compliance para skills — contratos verificables en `AGENTS.md` (criterio de cumplimiento por protocolo) + output format obligatorio en `cortex-recall`, `cortex-assimilate`, `cortex-crystallize` — commit `ee7cbe5`
- [ ] **Link-count scan** (post-v0.3.0) — diferido por colisiones de basename en wikilinks y falta de consumidor real para `knowledge_map` en el esquema recortado de `vault-report.json`. Requiere resolver el matching de rutas completas antes de implementar.
- [ ] Hook guardrail de plataforma — detectar SPA tras WebFetch e inyectar recordatorio del flujo 3a (PostToolUse, pendiente)
  - [x] Grep interception: `bin/hooks/cortex-recall-nudge.sh` implementado 2026-06-12 (PreToolUse, Bash-only, once-per-session, fail-open, Claude Code only) según backlog #2 Item 1 — supersede la línea PostToolUse para este caso
  - [ ] **EXPERIMENTO** (AGENT-LOG): baseline = pregunta de contenido del vault en sesión nueva sin nudge vs con nudge; medir si el agente invoca `cortex-recall` en vez de grep directo. Kill criterion: 5 sesiones sin cambio de comportamiento o fatiga de nudge → desinstalar y registrar
  - [ ] Ports a Codex/Antigravity/CommandCode — bloqueados hasta que el experimento muestre cambio de comportamiento (pendiente por agente)
- [ ] Versionado de schema en `AGENTS.md` y templates (`schema_version:`)
- [~] `cortex-prune` automático vía hook periódico — **parcial** 2026-06-12: post-commit hook (backlog #2 Item 2) refresca `vault-report.json` en cada commit (setup paso 6b); post-commit ≠ periódico — detección de staleness en vaults dormidos sigue abierta. Pendiente: validar en second-brain (vault con commits de contenido reales)
- [ ] Detección de hot cache stale (sin actualizar en N días)
- [x] Campo `agent:` en frontmatter de snapshots `.hot/` — identifica qué agente escribió cada entrada; necesario para resolver conflictos en vaults multi-agente
- [ ] Split `Project state` / `Agent context` en `.hot/` — separar estado del proyecto (pendientes, decisiones) del contexto específico del agente (convenciones aprendidas, workarounds); patrón validado por MEMORY.md + USER.md de Hermes
- [ ] Context fencing en `cortex-imprint` — al escribir páginas wiki, la fuente de verdad es `.raw/`; las páginas wiki existentes son referencia, no fuente; previene contaminación circular donde el agente "recuerda" resúmenes de sus propias memorias
- [ ] Tags de comportamiento en skills (`behavior:` en frontmatter) — clasificar skills por lo que el agente *hace* (`#synthesize`, `#ingest`, `#recall`, `#prune`) además de su nombre; un skill con múltiples comportamientos es señal de que debe dividirse

## Fase 2.5 — Batch 2026-06-12 (prioridad: implementar pronto)

Decisiones derivadas de la ingesta de obsidian-mind + guías de @affaan (`wiki/sources/obsidian-mind.md`, `claude-code-shorthand-guide.md`, `claude-code-longform-guide.md`, `agentic-security-shorthand-guide.md`). Estrategia: **Claude Code primero**; si otro agente retrasa un paso, queda como pendiente por agente y se valida empíricamente solo con Claude.

- [ ] **Sección "Intentado y fallido" en el template del hot cache** — agregar al contrato de `MEMORY-FORMAT.md` (junto a What was done / Fragile context) el registro explícito de enfoques intentados que fallaron, con evidencia. Evita que sesiones futuras repitan callejones sin salida. Origen: contrato de session file del Longform Guide.
- [ ] **Sanitización en `cortex-assimilate`** — paso de escaneo barato (`rg`) antes de guardar a `.raw/`: Unicode invisible (zero-width, bidi), comentarios HTML, base64 embebido, comandos de egress, `ANTHROPIC_BASE_URL`. Hallazgo → reportar al usuario antes de continuar, no abortar silencioso. Razón: assimilate ingiere contenido foráneo que sesiones futuras tratan como verdad → vector de memory poisoning (`wiki/concepts/memory-as-attack-surface`). El template además distribuye hooks/skills: aplicar el mismo escaneo como check de CI sería la segunda mitad (supply chain saliente).
- [ ] **Pipeline imprint: detección al Stop + triage al SessionStart** — diseño cerrado en sesión 2026-06-12:
  - [ ] Crystallize (Stop, in-session, modelo de la sesión): si detecta lección/síntesis no trivial, agrega flag `imprint-candidate: <tema> — transcript: <path>` a la entrada de History. No ejecuta imprint (agente fatigado, usuario ausente).
  - [ ] Script de crystallize barre flags expirados (>30 días, igual que la retención de transcripts de Claude Code) — comparación de fecha en shell; prune NO es responsable de esto.
  - [ ] SessionStart (solo vaults/proyectos enlazados): si hay flags pendientes y el toggle lo permite, lanzar subagente **Haiku** (`model: haiku`) en background que lee la sección relevante del transcript y prepara el imprint; informa al final de la respuesta ("mientras realizaba X, cortex-forge evaluó Y → path"). Sin flags → costo cero.
  - [ ] Toggle por vault en `~/.cortex-forge/config.yml`: `imprint_triage: off | suggest | auto`. Default `suggest` (subagente deja borrador, humano aprueba — mitiga memory poisoning). `auto` escribe directo confiando en git como reversa. Configurable en `cortex-forge-setup` y conmutable después.
  - [ ] Transcript caducado o ilocalizable → degradar a imprint desde el resumen del History, o descartar flag.
  - Nota de diseño: la garantía de consumo viene del **canal inyectado** (hot cache), no de la redacción de skills/AGENTS.md — los flags viajan en la misma inyección que ya es confiable. Lección crítica que deba sobrevivir siempre → destilar a una línea en `Current state`, detalle largo en wiki.
  - Pendientes por agente: localización de transcripts en Codex (`~/.codex/sessions/`), Antigravity (SQLite+Protobuf — sin path JSONL) y CommandCode (desconocido); subagente en background es capacidad de Claude Code, sin equivalente verificado en los demás.

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
