# Roadmap

## Fase 1 — Multi-agent parity

Objetivo: que el Hot Cache Protocol funcione en todos los agentes soportados.

- [x] Claude Code — configurado vía `cortex-forge-setup`
- [x] Matriz de compatibilidad → `wiki/concepts/agent-hook-compatibility.md`
- [x] Antigravity CLI — completo
  - [x] Correr `/cortex-forge-setup` desde Antigravity — muestra el bloque JSON a agregar
  - [x] Configurar hooks en `~/.gemini/config/hooks.json` (PreInvocation + Stop) — migrado a `cortex-reactivate-antigravity.sh` + `cortex-crystallize-antigravity.sh`; symlink a `~/.gemini/antigravity-cli/hooks.json` por bug agy-cli #49
  - [x] **PROBAR**: `cortex-reactivate-antigravity.sh` inyecta Zone 1 de `.hot/` al inicio — sin payload devuelve `{"injectSteps":[]}` (correcto); con `invocationNum=0` + workspace inyecta Zone 1 correctamente
  - [x] **REESCRIBIR**: `cortex-crystallize-antigravity.sh` — script original usaba `jq` sobre el transcript; Antigravity guarda transcripts como SQLite+Protobuf (`.db`), no JSON. Script reescrito para extraer via `strings $TRANSCRIPT | grep -oE '"toolSummary":"[^"]*"'` y mensajes de usuario desde `history.jsonl`. Fix de portabilidad: `grep -P` → `grep -E` (BSD grep en macOS). Guard `[ -z "$TOOL_SUMMARIES" ] && exit 0` protege sesiones de solo lectura.
  - [x] **VALIDAR** en sesión orgánica real: `fullyIdle==true` dispara hook → `agy -p` sobre transcript real → síntesis descriptiva escrita en `.hot/MEMORY.md` — trigger real validado en sesión orgánica (692b01be) ✅
  - [x] **VERIFICAR**: contradicción en path de `settings.json` — no existe `~/.gemini/config/settings.json`; el archivo real es `~/.gemini/antigravity-cli/settings.json`
  - [x] Ingestar una fuente con `cortex-assimilate`
  - [x] Consultar conocimiento con `cortex-recall` — validado con citations y confidence level ✅
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
  - [ ] **EXPERIMENTO** (AGENT-LOG): el nudge solo dispara cuando el agente intenta un Bash search (`grep`/`rg`/`find`) apuntando a `wiki/` o `.raw/` — el bypass declarativo (invocar `cortex-recall` directamente desde el system-reminder) y el bypass paramétrico (responder sin ningún tool call) quedan fuera de su alcance. Criterio de éxito: en una sesión donde el nudge disparó, el agente cambió su siguiente acción a `cortex-recall` en vez de continuar con el grep. Medir sobre 5 sesiones donde el hook haya disparado (no 5 sesiones arbitrarias). Kill criterion: 0/5 cambios de comportamiento → desinstalar y registrar en AGENT-LOG.
  - [ ] Ports a Codex/Antigravity/CommandCode — bloqueados hasta que el experimento muestre cambio de comportamiento (pendiente por agente)
- [x] Versionado de schema en `AGENTS.md` y templates (`schema_version: "0.3"`) — 2026-06-15
- [~] `cortex-prune` automático vía hook periódico — **parcial** 2026-06-12: post-commit hook (backlog #2 Item 2) refresca `vault-report.json` en cada commit (setup paso 6b); post-commit ≠ periódico — detección de staleness en vaults dormidos sigue abierta. Pendiente: validar en second-brain (vault con commits de contenido reales)
- [ ] Detección de hot cache stale (sin actualizar en N días)
- [x] Campo `agent:` en frontmatter de snapshots `.hot/` — identifica qué agente escribió cada entrada; necesario para resolver conflictos en vaults multi-agente
- [ ] Split `Project state` / `Agent context` en `.hot/` — separar estado del proyecto (pendientes, decisiones) del contexto específico del agente (convenciones aprendidas, workarounds); patrón validado por MEMORY.md + USER.md de Hermes
- [ ] Context fencing en `cortex-imprint` — al escribir páginas wiki, la fuente de verdad es `.raw/`; las páginas wiki existentes son referencia, no fuente; previene contaminación circular donde el agente "recuerda" resúmenes de sus propias memorias
- [ ] Tags de comportamiento en skills (`behavior:` en frontmatter) — clasificar skills por lo que el agente *hace* (`#synthesize`, `#ingest`, `#recall`, `#prune`) además de su nombre; un skill con múltiples comportamientos es señal de que debe dividirse

## Fase 2.5 — Batch 2026-06-12 (prioridad: implementar pronto)

Decisiones derivadas de la ingesta de obsidian-mind + guías de @affaan (`wiki/sources/obsidian-mind.md`, `claude-code-shorthand-guide.md`, `claude-code-longform-guide.md`, `agentic-security-shorthand-guide.md`). Estrategia: **Claude Code primero**; si otro agente retrasa un paso, queda como pendiente por agente y se valida empíricamente solo con Claude.

- [x] **Sección "Attempted and failed" en el template del hot cache** — agregada a `MEMORY-FORMAT.md` y `cortex-crystallize/SKILL.md` (junto a What was done / Fragile context). Registro explícito de enfoques intentados que fallaron, con evidencia. (2026-06-12, CommandCode)
- [x] **Sanitización en `cortex-assimilate`** — `bin/cortex-sanitize.sh` creado y paso 4a agregado al skill. Escanea: Unicode invisible, comentarios HTML, base64 embebido, comandos de egress, `ANTHROPIC_BASE_URL`. Hallazgo → reporta al usuario, no bloquea. (2026-06-12, CommandCode)
- [x] **Pipeline imprint: detección al Stop + triage al SessionStart** — implementado 2026-06-15:
  - [x] Crystallize (Stop): Haiku detecta síntesis durable → genera `#### Imprint candidate` con bullet + `— transcript: <path>` en la entrada de History.
  - [x] SessionStart: detecta candidate en la entrada más reciente del History, chequea expiración (>30 días → ignora), escribe `.hot/imprint-draft.md` con candidate + transcript path, inyecta nudge.
  - [x] Toggle `imprint_triage: off | suggest | auto` en `~/.cortex-forge/config.yml` (global o por vault). Backwards compat `true`→`suggest`, `false`→`off`. Default `suggest` en config global.
  - [x] `cortex-imprint/SKILL.md` lee `.hot/imprint-draft.md` si existe (paso 0) y lo elimina tras leerlo.
  - [ ] **Pendiente — modo `auto` completo**: hoy `auto` se comporta igual que `suggest` (nudge más fuerte, pero sin subagente autónomo). Implementación completa: el hook lanza `claude -p` (Haiku) bloqueante que lee el transcript + candidate y escribe la página wiki directamente en el vault. Requiere que el hook conozca vault path, taxonomía de tipos y templates — diseñar como script separado `bin/cortex-imprint-auto.sh` invocado desde el hook solo cuando `imprint_triage: auto`.
  - Nota de diseño: la garantía de consumo viene del **canal inyectado** (hot cache), no de la redacción de skills/AGENTS.md — los flags viajan en la misma inyección que ya es confiable. Lección crítica que deba sobrevivir siempre → destilar a una línea en `Current state`, detalle largo en wiki.
  - Pendientes por agente: localización de transcripts en Codex (`~/.codex/sessions/`) y Antigravity (SQLite+Protobuf — sin path JSONL); **CommandCode resuelto** (2026-06-12): `~/.commandcode/projects/{project-slug}/{session-uuid}.jsonl`, también disponible vía `transcript_path` en stdin de hooks. Subagente en background es capacidad de Claude Code, sin equivalente verificado en los demás. Fuentes: `wiki/sources/commandcode-hooks-reference`, `wiki/sources/commandcode-headless`, inspección de filesystem real.

## Fase 3 — Adoptabilidad

- [x] Agregar licencia al repo público
- [ ] Guía de onboarding: 5 minutos desde cero hasta primera ingesta
- [ ] Páginas de ejemplo en `wiki/concepts/` (demuestran el formato, no son contenido personal)
- [ ] `wiki/prompts/` como tipo de página opcional — permite al usuario archivar invocaciones efectivas del agente con ejemplo de output; el vault hoy almacena conocimiento del mundo pero no conocimiento operacional sobre cómo trabajar con el agente
- [ ] MOCs por área temática — `wiki/concepts/_index.md`, `wiki/entities/_index.md` como índices navegables por área, complementarios al índice global; facilita que el agente entre por el MOC correcto en vez de cargar todo el índice

## Fase 3.5 — cortex-prune modo dual

Decisión de diseño cerrada en sesión 2026-06-14, derivada de la ingesta de SkillOpt (Microsoft) y SkillOpt-Sleep.

### `prune-vault` (modo actual)
Mantenimiento del vault: páginas huérfanas, wikilinks rotos, staleness del hot cache. Comportamiento ya existente en `cortex-prune`.

### `prune-cortex` (modo nuevo)
Optimización del sistema mismo: analiza transcripts donde fallaron skills de cortex-forge y propone edits acotados a los `SKILL.md` correspondientes.

**Por qué:** cortex-forge hoy mejora sus skills manualmente, por observación. SkillOpt demuestra que este proceso es automatizable: un optimizer lee éxitos/fracasos y propone add/delete/replace de reglas, un validation gate acepta solo los edits que mejoran un held-out. `prune-cortex` implementa esta idea dentro del paradigma de cortex-forge, sin dependencias externas.

**Por qué la Fase 3 es el gate:** las páginas de ejemplo planeadas en Fase 3 (`wiki/concepts/` con casos de formato canónico) son exactamente el answer key que SkillOpt necesita como held-out set. Sin esas páginas, `prune-cortex` puede proponer edits pero no puede validarlos objetivamente — el gate queda vacío. Con ellas, cada página de ejemplo es un test vivo: input conocido → output esperado. El gate corre automáticamente cuando un skill cambia.

**Consecuencia de diseño:** las páginas de ejemplo de Fase 3 tienen doble función — onboarding para usuarios nuevos + infraestructura de calidad para `prune-cortex`. Esto obliga a mantenerlas actualizadas: un ejemplo desactualizado produce un gate ruidoso.

**Skills aptos para `prune-cortex`** (outputs verificables):
- `cortex-recall` — la cita existe o no en el vault
- `cortex-assimilate` — los archivos se crean en las rutas correctas

**Skills no aptos** (outputs subjetivos, sin respuesta canónica):
- `cortex-crystallize`, `cortex-imprint`

**Implementación en fases:**
- [ ] Fase 3.5a — `prune-cortex` sin gate: analiza transcripts, propone edits a `SKILL.md`, usuario aprueba. Sin scoring automático.
- [ ] Fase 3.5b — validation gate: enchufar páginas de ejemplo de Fase 3 como held-out set. Acepta edits solo si el score mejora estrictamente.
- [ ] Fase 3.5c (opcional) — integración con SkillOpt-Sleep plugin si la comunidad lo demanda; el diseño de 3.5a/b es compatible con el loop de SkillOpt.

**Referencia:** `wiki/concepts/skillopt-text-space-optimization.md`, `wiki/reference/skillopt-cli.md`

## Fase 3.6 — Retrieval semántico (sqlite-vec)

Diseño completo en `CORTEX_FORGE_PLAN.md`. Esta fase desbloquea Fase 4: sin vector retrieval, `cortex-recall` no puede escalar a vaults de >50 páginas.

**Stack:** `sqlite-vec` + backend de embeddings seleccionado por plataforma. No requiere Ollama ni proceso externo.

**Selección de backend (encapsulada en `.cortex/embeddings.py`):**
- Apple Silicon (`Darwin` + `arm64`): `mlx-embeddings` con `mlx-community/nomic-embed-text-v1.5` — más rápido vía Neural Engine; fallback automático a `sentence-transformers` si mlx no está instalado.
- Linux / Windows / Intel Mac: `sentence-transformers` con `nomic-ai/nomic-embed-text-v1.5`, `normalize_embeddings=True`. Fallback universal, sin prerequisitos.

**Dependencias** (`pyproject.toml`): base `sentence-transformers>=2.7.0` + `sqlite-vec>=0.1.0`; opcional `apple-silicon`: `mlx>=0.5.0` + `mlx-embeddings>=0.0.8`.

### Etapa 1 — Índice vectorial local

- [ ] Crear `.cortex/embeddings.py` — módulo compartido que exporta `load_embedding_model()` y `embed()`; encapsula toda la lógica de detección de plataforma y selección de backend; el resto del sistema importa desde aquí, sin duplicar detección
- [ ] Actualizar `cortex-forge-setup` (skill): detectar OS/arch → instalar dependencias base + opcionales Apple Silicon → descargar pesos (~270 MB) → reportar qué backend quedó activo
- [ ] Crear `scripts/cortex-index.py` — indexador completo (`--full`) e incremental (`--file`); chunker por sección `##` (~300 tokens); usa `embed()` desde `.cortex/embeddings.py`; INSERT en `.cortex/vault.db`
- [ ] Crear `.cortex/cortex-search.py` — retrieval vía `vec_distance_dot`, invocable por bash: `python .cortex/cortex-search.py "query" --top-k 5`
- [ ] Hook post-commit: re-indexar solo archivos `wiki/` modificados en el commit
- [ ] Modificar `cortex-recall/SKILL.md`: invocar `cortex-search.py` como primer paso; el agente recibe top-k paths y trabaja sobre ese conjunto acotado
- [ ] Agregar `.cortex/vault.db` y `.cortex/__pycache__/` a `.gitignore`
- [ ] Validar en second-brain: indexación inicial + query de prueba + indexación incremental tras `cortex-assimilate`; verificar que el backend reportado coincide con la plataforma

### Etapa 2 — MCP server (gate: Etapa 1 validada + vault usado desde >1 cliente)

No implementar antes. Ver diseño completo en `CORTEX_FORGE_PLAN.md` → sección "Etapa 2".

- [ ] Crear `.cortex/server.py` con FastMCP — 5 tools: `vault_ingest`, `vault_query`, `vault_imprint`, `session_snapshot`, `vault_prune`
- [ ] Registrar en `.claude/settings.json` del vault (stdio transport)
- [ ] Verificar degradación limpia: vault sigue siendo funcional sin MCP leyendo `AGENTS.md` directamente

## Fase 4 — Inteligencia acumulada

- [ ] `cortex-recall` con síntesis cross-página y detección de contradicciones
- [ ] Detección de patrones cross-sesión: temas recurrentes en `.hot/` que nunca llegan a `wiki/` — al crystallizar, revisar historial y proponer candidatos; patrón validado por dialectic reasoning de Honcho
- [ ] Carga progresiva en `cortex-recall` — navegar wiki como filesystem según relevancia en lugar de cargar el índice completo al inicio; reduce token bloat sin perder cobertura
- [~] **Archivo de historial.** Capa simple implementada 2026-06-15: entries >30 días en `MEMORY.md` → `.hot/CONSOLIDATED.md` (mismo formato Markdown, append-only, no se inyecta al inicio de sesión). Capa estructurada pendiente: cuando `CONSOLIDATED.md` supere N entradas, parsear a JSON con tags `{ts, agent, trigger, tags: [], files: [], decisions: [], discarded: [], fragile: []}` extraídos por el crystallize al momento de escribir. JSON no se carga al inicio — consultable vía `/cortex-recall` o skill dedicado.
