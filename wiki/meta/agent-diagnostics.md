---
title: "Agent Diagnostics Log"
created: 2026-06-08
updated: 2026-06-26
schema_version: "0.3"
---

# Agent Diagnostics Log

Bitácora de sesiones de prueba del protocolo Cortex Forge con distintos agentes.
Cada entrada es el selfreport de una sesión: qué ocurrió, qué falló, qué funcionó,
y qué observaciones o sugerencias ofrece el agente.

**No es un tracker de tareas.** No hay `Pending`, ni `Active decisions`, ni `Current state`.
Para eso existe `.hot/MEMORY.md`.

## Criterio de uso (Excepciones)

Escribe una entrada en esta bitácora solo al final de sesiones donde:
- Se encuentre o diagnostique un comportamiento sistémico nuevo en un agente o plataforma.
- Se descarte una hipótesis de diseño importante con evidencia técnica.
- Ocurra un fallo complejo o encadenado que requiera un análisis de causa raíz detallado.
- Se configure o valide compatibilidad de hooks por primera vez en una plataforma.

No es necesario registrar sesiones de desarrollo incremental normal o mantenimiento de rutina.

---

## Entradas

---

## 2026-06-07 — CommandCode (MiniMax-M3)

**Qué ocurrió:** primera prueba de agente-agnosticismo. Se abrió una sesión nueva en
CommandCode sobre el vault cortex-forge para observar si el agente leía `.hot/cortex-forge.md`
por iniciativa propia al inicio, como instruye `AGENTS.md`.

**Qué falló:**
- El agente no leyó `.hot/cortex-forge.md` al inicio de la sesión.
- La lectura solo ocurrió cuando el usuario lo pidió explícitamente.
- `AGENTS.md` se cargó como texto al system prompt pero la instrucción "Read it on
  session start" no se tradujo en acción.

**Qué funcionó:** una vez pedida, la lectura fue correcta y el agente usó el contexto.

**Observaciones / sugerencias:**
- 5 causas identificadas: instrucción declarativa (no ejecutable), sin hook SessionStart
  en CommandCode, compite con otras directrices del system prompt, falta señal de
  continuidad, framing "read on session start" no activa heurísticas de preflight.
- 3 soluciones propuestas: Capa 1 (reforzar prompt en `AGENTS.md`), Capa 2 (modificar
  wrapper), Capa 3 (skill de preflight). Capa 3 descartada posteriormente — mismo
  mecanismo declarativo que el problema original.
- Recomendación: implementar Capa 1 de inmediato como experimento controlado.

---

## 2026-06-07 — Claude Code (claude-sonnet-4-6)

**Qué ocurrió:** análisis del reporte de CommandCode + implementación de Capa 1 en `AGENTS.md`.

**Qué falló:**
- Se identificó un segundo fallo no documentado por CommandCode: `cortex-recall` tampoco
  fue invocado proactivamente durante una consulta al vault — el agente usó `find`/`grep`
  en su lugar.
- El patrón es el mismo que el del hot cache: instrucciones declarativas no disparan
  acciones.

**Qué funcionó:** la Capa 1 fue implementada — secciones `Hot Cache protocol` e
`Ingest protocol` en `AGENTS.md` reescritas con `MANDATORY`, verbos imperativos,
4 pasos numerados y framing de "protocol violation".

**Observaciones / sugerencias:**
- La Capa 3 (skill de preflight auto-invocada) tiene el mismo flaw que el problema
  que intenta resolver: si el modelo no ejecuta "Read it on session start", tampoco
  auto-invocará una skill. Descartada.
- El problema de `cortex-recall` es sistémico, no puntual: afecta a skills y hot cache
  por igual.

---

## 2026-06-08 — Antigravity / Gemini CLI

**Nota:** sesión terminada por cuota antes del cierre formal. Entrada reconstruida por
Claude Code desde log proporcionado por el usuario.

**Qué ocurrió:** experimento de control de Capa 1. Se abrió sesión nueva en Antigravity
sin dar contexto previo. Objetivo: verificar si el agente leía `.hot/cortex-forge.md`
de forma autónoma gracias al MANDATORY de `AGENTS.md`.

**Qué falló:**
- El agente aclaró que la lectura no ocurrió "automáticamente al iniciar la sesión" —
  ocurrió reactivamente al recibir el primer mensaje. Técnicamente cumple la instrucción
  pero no es el comportamiento ideal.
- El agente afirmó inicialmente no tener hooks nativos (incorrecto: Antigravity hereda
  hooks de Gemini CLI con `PreInvocation` y `Stop`).

**Qué funcionó:**
- Capa 1: éxito parcial. El agente leyó `.hot/cortex-forge.md` antes de generar su
  primera respuesta, sin instrucción explícita.
- `cortex-assimilate` y `cortex-recall` funcionaron en la misma sesión sin instrucción
  adicional.

**Observaciones / sugerencias:**
- La distinción "reactiva vs automática" es relevante: todos los LLMs son reactivos;
  el primer mensaje del usuario es el despertador. La Capa 1 es efectiva dentro de
  esa arquitectura.
- Bug conocido en agy-cli (issue #49): el CLI escribe hooks en
  `~/.gemini/antigravity-cli/hooks.json` pero los lee desde `~/.gemini/config/hooks.json`.
  Solución: edición manual + symlink.

---

## 2026-06-08 — Codex / o3

**Nota:** sección extraída y reorganizada por Claude Code desde log de sesión mezclado.

**Qué ocurrió:** experimento de Capa 2 nativa. Se configuraron hooks `SessionStart` y
`Stop` en Codex (`~/.codex/hooks.json`) apuntando a scripts de cortex-forge.

**Qué falló:**
- `hook context:` visible en el chat del usuario — Codex muestra el `additionalContext`
  del hook como texto visible en la conversación. Es comportamiento de UI por diseño,
  no un error de parsing. `suppressOutput` existe en el schema pero está marcado
  "Reserved for future use".
- `SessionStart` se disparó dos veces (probable `startup` + `resume`). Esperable por
  diseño — el evento tiene un campo `source` filtrable.
- Scripts estaban alojados en `~/.claude/hooks/` (ruta de Claude Code), no en
  `~/.codex/hooks/`. Bug de `cortex-forge-setup`.

**Qué funcionó:**
- Capa 2: éxito funcional. El hook `SessionStart` se ejecutó, leyó `.hot/cortex-forge.md`
  y cargó el contexto antes de que el modelo generara su primera respuesta.
- Wire format de Codex es compatible con los scripts existentes sin modificaciones
  (mismo formato JSON plano que Claude Code).

**Observaciones / sugerencias:**
- Próximo refactor debe limitar el payload de `SessionStart` a las zonas mínimas del
  `.hot/` (`### Pending` y `### Active decisions`), no el archivo completo.
- Scripts deben vivir en `~/.codex/hooks/`, no en `~/.claude/`. Corregido en sesión
  posterior.
- El doble disparo es esperable y filtrable; documentar en `agent-hook-compatibility.md`.

---

## 2026-06-08 — CommandCode / MiniMax-M3 (segunda sesión — ingesta + cortex-recall)

**Qué ocurrió:** ingesta de docs oficiales de hooks de CommandCode. Prueba práctica
de `cortex-recall` en la misma sesión.

**Qué falló:**
- `cortex-recall` no fue invocado proactivamente ante una consulta sobre el vault —
  el agente usó `grep` hasta que el usuario corrigió. Mismo patrón que los tres agentes
  anteriores. Cuatro agentes, mismo fallo.

**Qué funcionó:**
- Cuando se invocó `cortex-recall` explícitamente, los resultados fueron mejores que
  `grep`: 2 páginas wiki sintetizadas con citas vs 12 archivos con ruido.
- Diferencia práctica: la skill filtra conocimiento sintetizado en `wiki/`, no memoria
  cruda.

**Observaciones / sugerencias:**
- El fallo de `cortex-recall` está confirmado en Claude Code, Codex, Antigravity y
  CommandCode. No es un fallo puntual — es sistémico.
- Wire format de CommandCode es anidado (`hooks: [{ matcher, hooks: [{ type, command }] }]`),
  distinto del formato plano de Claude Code/Codex. Scripts actuales no son drop-in
  para CommandCode.
- Diferencia operacional `explore` vs `cortex-recall`: `explore` cruza múltiples fuentes;
  `cortex-recall` retorna respuesta enfocada desde `wiki/`. Criterio: si existe wiki
  page sintetizada → `cortex-recall`; si requiere cruzar conocimiento disperso → `explore`.

---

## 2026-06-08 — CommandCode / MiniMax-M3 (creación settings.local.json)

**Qué ocurrió:** creación de `.commandcode/settings.local.json` con hook `Stop` para
registrar snapshot al cierre de sesión. Consulta sobre qué eventos disparan `Stop`.

**Qué falló:** nada en esta sesión específica (el archivo fue creado correctamente).

**Qué funcionó:** wire format anidado de CommandCode aplicado correctamente, verificado
contra dos fuentes independientes del vault.

**Observaciones / sugerencias:**
- Scope del archivo: project-scoped en `cortex-forge/.commandcode/` — problema de scope
  ya conocido (el vault activo del usuario es `second-brain`, no `cortex-forge`).
- `Stop` se dispara con: cierre natural, `/slash exit`, timeout de inactividad.
  No se dispara en: plan mode, `Ctrl-C` abrupto, sesiones de solo lectura.
- El script `update-hot-cache.sh` probablemente degradará silenciosamente con stdin
  de CommandCode porque espera campos del wire format de Claude Code que no existen
  en `Stop` de CommandCode. Verificación pendiente.

---

## 2026-06-08 — CommandCode / MiniMax-M3 (diagnóstico: Stop hook no se disparó)

**Qué ocurrió:** se constató que el hook `Stop` no se ejecutó al cerrar sesión con
`/exit`. Evidencia: `.hot/cortex-forge.md` no se actualizó.

**Qué falló:** tres errores en cascada, cada uno suficiente para silenciar el hook:
1. **Scope equivocado:** `cortex-forge/.commandcode/settings.local.json` — el hook no
   está donde se necesita (debería estar en `second-brain/.commandcode/`).
2. **Ruta de transcripts incorrecta:** el script busca en `~/.claude/projects/`; 
   CommandCode guarda transcripts en otra ruta. Sin transcript → `exit 0` silencioso.
3. **Nombre de agente hardcodeado:** el script escribe `### ... — Claude Code` en el
   snapshot, contaminando el historial si el hook hubiera llegado a ejecutarse.

**Qué funcionó:** el diagnóstico fue preciso y accionable.

**Observaciones / sugerencias:**
- Lección transferible: configurar un hook ≠ hook funcional. Tres capas a verificar:
  (1) ¿el archivo está en el scope correcto?, (2) ¿el script maneja el payload del
  agente correcto?, (3) ¿el evento que dispara el hook es el que la doc dice?
- Las tres pueden fallar silenciosamente — `exit 0` oculta todo.

---

## 2026-06-08 13:22 — Antigravity (validación hooks PreInvocation + Stop)

**Nota:** sesión terminada por cuota. Entrada reconstruida por Claude Code desde log
proporcionado por el usuario.

**Qué ocurrió:** prueba de los hooks de Antigravity con payload mock.
`cortex-reactivate-antigravity.sh` (Zone 1) y `cortex-crystallize-antigravity.sh`
(Zone 2).

**Qué falló:**
- La síntesis generada por `agy -p` fue genérica ("web search for 'example'") — el
  modelo no tenía contexto real de sesión porque el payload era simulado.
- El flujo completo en sesión real orgánica no fue validado.

**Qué funcionó:**
- Zone 1 (`PreInvocation invocationNum==0`): inyección en contexto correcta con payload
  real. Fix del awk confirmado funcional.
- Zone 2 (`Stop fullyIdle==true`): nueva entrada escrita en `.hot/cortex-forge.md`.
  Guard anti-duplicación de frontmatter funcionó.

**Observaciones / sugerencias:**
- La validación pendiente clave es el flujo orgánico: sesión productiva real →
  `fullyIdle==true` automático → `agy -p` sobre transcripción real → síntesis
  descriptiva.

---

## 2026-06-08 — Claude Code (claude-sonnet-4-6) — diagnóstico hooks Codex

**Qué ocurrió:** diagnóstico del `hook context:` visible en Codex. Corrección de rutas
de scripts (movidos a `~/.codex/hooks/`). Documentación de propuestas para la siguiente
iteración.

**Qué falló:**
- Scripts en `~/.claude/hooks/` en lugar de `~/.codex/hooks/` — acoplamiento incorrecto
  entre configuraciones de agentes distintos.
- El payload inyecta el `.hot/` completo, aumentando ruido y costo de contexto.

**Qué funcionó:** rutas corregidas. `additionalContext` llega correctamente al modelo —
el ruido visual es de UI, no de parsing.

**Observaciones / sugerencias:**
- Siguiente refactor: inyectar solo `### Pending` y `### Active decisions` del `.hot/`,
  not el archivo completo.
- Separar validación de arranque y cierre en pruebas futuras.
- Documentar que `hook context:` visible es comportamiento esperado en Codex (no bug).

---

## 2026-06-08 16:40 — Codex (vault protocol review)

**Qué ocurrió:** sesión de revisión del protocolo. El agente fue evaluado por dos
fallos: no invocar `cortex-recall` proactivamente, y no seguir el flujo de
`cortex-assimilate` al recibir una URL con respuesta SPA.

**Qué falló:**
- `cortex-recall` no fue invocado proactivamente ante consultas sobre el vault — el
  agente respondió desde contexto activo.
- `cortex-assimilate` no fue cargado correctamente al recibir una URL. El fetch
  retornó contenido SPA y el agente no siguió el flujo de detección (paso 3a) ni
  declaró la situación — procedió sin contenido legible.
- Raíz común: el protocolo está escrito como regla, no como guardrail ejecutable.
  No hay verificación técnica que bloquee una respuesta si los pasos no se siguieron.
- Las instrucciones no definen qué significa "usar la skill" en términos verificables,
  qué evidencia devolver, ni qué hacer si la skill no está disponible.

**Qué funcionó:** autodiagnóstico preciso y articulado al ser consultado directamente.

**Observaciones / sugerencias:**
1. Agregar criterio de cumplimiento verificable en `AGENTS.md` — cita obligatoria a
   `wiki/` en respuestas sobre vault; declaración explícita si skill no disponible.
2. Hook de salida o pre-respuesta que verifique que la consulta pasó por el canal
   correcto.
3. En `cortex-assimilate`: STOP explícito antes del paso 4 si no hay contenido
   legible — nunca guardar shell HTML a `.raw/`.
4. Separar mejor "contenido del vault" de "contexto de sesión" en `AGENTS.md`.

**Aplicado:** contratos verificables y hardening implementados en `AGENTS.md` y
skills `cortex-recall`, `cortex-assimilate`, `cortex-crystallize` — commit `ee7cbe5`.

---

## 2026-06-09 — Claude Code (claude-sonnet-4-6) — v0.2.0 + sincronización second-brain

**Qué ocurrió:** sesión de cierre post-v0.2.0. Dos bloques de trabajo: (1) aplicar
mejoras derivadas del análisis del handoff skill de Matt Pocock al protocolo; (2)
replicar todos los cambios de v0.2.0 al vault personal `second-brain`.

**Qué falló:**
- El PreCompact anterior (00:20 -04) registró solo rutas de archivo en lugar de bullets
  descriptivos — la rama mecánica del script seguía activa. Fix aplicado en esta sesión.
- Los dos PreCompact previos a la sesión guardaron listas de rutas sin narrativa, lo que
  hace esas entradas inútiles como handoff. Entradas conservadas tal cual (append-only).

**Qué funcionó:**
- Fix de `cortex-crystallize.sh`: rama PreCompact mecánica eliminada; ambos triggers
  usan `claude -p` con `MODE_NOTE` contextual. Código unificado, sin duplicación.
- 4 mejoras del análisis handoff aplicadas: tabla PreCompact/SessionEnd en MEMORY-FORMAT,
  `### Suggested skills` en Zone 1, argumento `next: <focus>` en SKILL.md,
  primary/secondary source en AGENTS.md.
- `wiki/concepts/handoff-artifact.md`: decisiones de diseño documentadas — `.hot/` vs
  `/tmp`, nombre fijo MEMORY.md, dos zonas, PreCompact vs SessionEnd.
- `second-brain` sincronizado a v0.2.0 sin fricción: AGENTS.md (6 capas, MEMORY.md fijo,
  Reference taxonomy, parametric knowledge, compliance criteria), CODEX.md creado,
  template reference copiado, `.hot/second-brain.md` renombrado a `.hot/MEMORY.md`.
- Release v0.2.0 publicado en GitHub.

**Observaciones / sugerencias:**
- La sincronización manual de second-brain es el proceso doloroso esperado al tener dos
  repos. El costo fue bajo esta vez (AGENTS.md + CODEX.md + un template), pero crecerá
  con cada iteración del protocolo.
- Considerar en el futuro: `/cortex-forge-setup` podría detectar si hay vaults registrados
  con AGENTS.md desactualizado y proponer un diff aplicable. No urgente — el proceso
  manual fue rápido y controlado.

---

## 2026-06-10 — CommandCode (MiniMax-M3)

**Qué ocurrió:** implementación final del backlog de mejoras derivado del análisis comparativo. Se aplicaron los ítems con unanimidad de los revisores y se diferó el escaneo de enlaces (Item 4) a `ROADMAP.md`.

**Qué falló:**
- Mención innecesaria a "Graphify" en la documentación de Obsidian (era análisis interno, no un reemplazo declarativo del proyecto). Corregido.
- El `CHANGELOG.md` generado inicialmente duplicaba información que ya existe en las releases de GitHub. Ajustado para ser un resumen conciso con enlaces a las releases oficiales.

**Qué funcionó:**
- **Item 1:** Citas de confianza en `cortex-recall` (maneja `unset`, `read-error` y valida `medium`/`low`).
- **Item 2:** Esquema mínimo viable de `vault-report.json` (solo `generated` y `health` con 3 campos), actualizado en `cortex-prune`, `AGENTS.md` y `.gitignore`.
- **Item 3:** Documentación de visualización con Obsidian (`docs/obsidian-visualization.md` y sección en `README.md`). Se omitió `bin/standalone/` por rechazo unánime.
- **Item 5:** Tabla de compatibilidad de plataformas en `README.md` (con corrección de Cursor a "Not tested" y mención de sub-comandos).
- **Item 6:** `CHANGELOG.md` ajustado para apuntar a las releases de GitHub, y convención de commits agregada a `README.md` y referenciada en `AGENTS.md`.
- **Item 4:** Diferido a `ROADMAP.md` como pendiente para post-v0.3.0 debido a colisiones de basename y falta de consumidor real.

**Observaciones / sugerencias:**
- Mantener el `CHANGELOG.md` local como un resumen de alto nivel con enlaces a las releases de GitHub evita la duplicación y el desfasaje entre el repo y el tracker de releases.
- La omisión de referencias a herramientas de análisis interno en la documentación pública mantiene el foco en el valor propio del proyecto.

---

## 2026-06-10 17:45 -04 — CommandCode (Stop hook fix)

**Qué ocurrió:** se resolvió el pending de CommandCode en el vault: el hook Stop apuntaba a `cortex-crystallize.sh` (diseñado para Claude Code, incompatible con el wire format de CommandCode — esperaba `transcript_path`, `hook_event_name`, `cwd` y usaba `claude -p`). Se creó `bin/hooks/cortex-crystallize-commandcode.sh` que no depende de transcript, no usa síntesis IA, y escribe el snapshot directamente. Se instaló en `second-brain/.commandcode/settings.local.json` (scope correcto). Se corrigió también `cortex-forge/.commandcode/settings.local.json` para que apunte al script CommandCode-native.

**Qué funcionó:**
- `cortex-crystallize-commandcode.sh` creado como script mínimo y robusto: parsea stdin con jq, encuentra git root, preserva Zone 1 + Zone 2 de MEMORY.md, escribe entrada en History con etiqueta `CommandCode (Stop)`.
- Hook instalado donde corresponde: `second-brain/.commandcode/settings.local.json` (el vault activo del usuario).
- Hook de cortex-forge corregido también para que use el script CommandCode-native.

**Observaciones / sugerencias:**
- El script no hace síntesis IA (como sí hace la versión de Claude Code). El snapshot es mínimo — solo marca que la sesión se cerró. La síntesis real la hará el agente CommandCode al leer MEMORY.md en la próxima sesión y reconstruir contexto desde el historial.
- El pending de Antigravity (`cortex-crystallize-antigravity.sh` en sesión orgánica real) queda como el único bloqueante previo a instalar hooks nuevos del backlog #2.

---

## 2026-06-11 — Claude Code (claude-sonnet-4-6) — fix cortex-crystallize-antigravity.sh

**Qué ocurrió:** diagnóstico y corrección del script Stop hook de Antigravity, que generaba síntesis basura.

**Qué falló:**
- `cortex-crystallize-antigravity.sh` usaba `jq` para parsear el transcript, pero Antigravity almacena transcripts as SQLite+Protobuf (`.db`), no JSON. `jq` fallaba silenciosamente y retornaba 0 tool calls.
- Durante la sesión de test, Antigravity creó un dummy transcript en formato JSON-Claude-Code. El script lo parseó con éxito, llamó `agy -p` sobre ese dummy, y escribió una síntesis genérica/incorrecta en `.hot/MEMORY.md` (entrada "No files were created..." del 20:31). Cuando el hook real se disparó al cerrar la sesión real, el `.db` no fue parseado y la entrada basura quedó intacta.
- La entrada del 20:31 fue eliminada de MEMORY.md (era artefacto del test, no contexto real de sesión).

**Qué funcionó:**
- Nuevo approach para parsear transcripts de Antigravity: (1) `strings $TRANSCRIPT | grep -oE '"toolSummary":"[^"]*"'` extrae summaries de herramientas desde los blobs protobuf; (2) `grep -F $CONV_ID ~/.gemini/antigravity-cli/history.jsonl | grep -oE '"display":"[^"]*"'` extrae mensajes del usuario, donde `CONV_ID` se deriva del basename del `.db`.
- El script probado con el db real de la sesión bb3be9d0 generó síntesis correcta y descriptiva.
- Fix de portabilidad: `grep -P` → `grep -E` (BSD grep en macOS no tiene PCRE).

**Observaciones / sugerencias:**
- El guard `[ -z "$TOOL_SUMMARIES" ] && exit 0` protege contra sesiones de solo lectura sin herramientas.
- Queda pendiente la validación en sesión orgánica real (el script se probó con transcript de sesión anterior, no con trigger real del hook Stop).
- Si Antigravity cambia el schema del SQLite o el campo `toolSummary` en el wire format, la extracción falla silenciosamente — documentar como fragile point.

---

## 2026-06-11 — Claude Code (claude-sonnet-4-6) — rename -claude suffix + agent detection en skill

**Qué ocurrió:** rename de `cortex-crystallize.sh` a `cortex-crystallize-claude.sh` para alinear la convención de nombres con los demás scripts. Adicionalmente, se implementó detección de agente invocador en la skill `cortex-crystallize`.

**Qué funcionó:**
- Rename aplicado en todas las referencias activas: `bin/hooks/`, `~/.claude/hooks/`, `~/.claude/settings.json`, `skills/cortex-forge-setup/SKILL.md`, `wiki/concepts/agent-hook-compatibility.md`. Las referencias históricas en AGENT-LOG y MEMORY.md se dejaron intactas (append-only).
- Detección de agente: inspeccionando el entorno real de Claude Code se confirmaron las señales disponibles — `CLAUDECODE=1`, `AI_AGENT=claude-code_{version}_agent`, `CLAUDE_CODE_ENTRYPOINT`, `CLAUDE_CODE_SESSION_ID`. Estas variables son suficientes para identificar Claude Code sin depender del auto-reporte del modelo.
- Paso `1a` agregado a `cortex-crystallize/SKILL.md`: el agente corre `env` y matchea las señales en orden de prioridad para identificarse antes de escribir el snapshot.
- Tabla de señales agregada a `agent-hook-compatibility.md` con estado de validación por CLI.

**Observaciones / sugerencias:**
- Las señales de CommandCode, Antigravity y Codex son hipótesis (marcadas `⚠ unconfirmed`). Necesitan validarse en sesión real con cada CLI: correr `env | grep -iE "commandcode|agy|codex|ai_agent|claude"` al inicio de sesión y reportar el resultado.
- `AI_AGENT` parece ser la variable más prometedora como estándar cross-CLI — si los demás agentes la adoptan con su propio prefijo, sería el único campo a verificar.
- **Recomendación:** cambiar la lógica de detección en la skill de "match env vars" a "match env vars OR walk process tree OR check common binary paths", en ese orden. El árbol de procesos es el mecanismo más robusto porque no depende del CLI implementando nada.

---

## 2026-06-11 21:03 -04 — CommandCode (deepseek/deepseek-v4-flash) — validación señales de entorno y detección de agente

**Qué ocurrió:** validación en sesión real de las señales de entorno de CommandCode. Se ejecutó `env | grep -iE "commandcode|agy|codex|ai_agent|claude"` al inicio de sesión, más un dump completo de variables (35 total), inspección del árbol de procesos, y análisis del binario.

**Qué falló:**
- `COMMANDCODE=1` **no existe.** La tabla de señales en `agent-hook-compatibility.md` estaba incorrecta para CommandCode. Ninguna de las 35 variables de entorno identifica al CLI.
- `AI_AGENT` tampoco existe en CommandCode. No es un estándar cross-CLI — es específico de Claude Code.
- Tampoco hay `COMMANDCODE_SESSION_ID`, ni ninguna variable tipo `_AGENT`, `_PLATFORM` o similar.
- El paso `1a` de `cortex-crystallize/SKILL.md` (correr `env` y matchear señales) es insuficiente para CommandCode — `env` en CommandCode solo tiene el entorno de shell, sin inyección del CLI.

**Qué funcionó:**
- Se identificaron **2 métodos detectables** alternativos a las variables de entorno:
  1. **Árbol de procesos:** el proceso padre de la sesión es `node /opt/homebrew/bin/cmd` (el symlink de CommandCode). Caminando el árbol hacia arriba desde `$PPID` se llega a `node /opt/homebrew/bin/cmd` → Ghostty. Confiable porque el path del binario identifica unívocamente al CLI.
  2. **Ruta del binario:** `commandcode` está en `$PATH` como `/opt/homebrew/bin/commandcode`, y `which commandcode` funciona. No es suficiente por sí solo (el agente no sabe si el shell nativo lo ejecutó), pero como test complementario es rápido.
- Config de CommandCode en `~/.commandcode/config.json`: `"provider": "command-code"`, `"model": "deepseek/deepseek-v4-flash"`.
- `commandcode --version` → `0.35.0`. El binario es `node /opt/homebrew/bin/commandcode -> ../lib/node_modules/command-code/dist/index.mjs`.

**Observaciones / sugerencias:**
- CommandCode **no inyecta** señales de entorno auto-identificadoras. La detección vía `env` es un falso positivo en la tabla actual.
- Método propuesto para detección en `cortex-crystallize`: (1) probar `env` match (funciona para Claude Code); (2) si no hay match, caminar árbol de procesos desde `$PPID` buscando binario conocido (`commandcode`, `claude`, `codex`, `agy`); (3) último recurso: `which commandcode | agy | codex`.
- Ventaja del árbol de procesos: funciona aunque el CLI no exporte vars. Aplica a cualquier agente que no inyecte señales (CommandCode, probablemente Antigravity y Codex también).
- Hipótesis a validar en Antigravity y Codex: ¿también carecen de vars de entorno? Si el patrón se repite, el árbol de procesos es el método universal.
- **Recomendación:** cambiar la lógica de detección en la skill de "match env vars" a "match env vars OR walk process tree OR check common binary paths", en ese orden. El árbol de procesos es el mecanismo más robusto porque no depende del CLI implementando nada.

---

## 2026-06-10 21:57 -04 — Codex / Claude Code (hook test)

**Qué ocurrió:** se creó `bin/hooks/cortex-crystallize-codex.sh` como wrapper explícito para los hooks de Codex y se generalizó `bin/hooks/cortex-crystallize-claude.sh` para aceptar un `AGENT_LABEL` y múltiples rutas de fallback de transcripts. Se probaron ambos scripts con un repo temporal, un transcript JSONL mínimo y un stub local de `claude`.

**Qué falló:**
- El guard de conteo de `tool_use` y la normalización de `DASH_COUNT` eran frágiles en shells POSIX: `wc -l` y `grep -c || echo 0` podían producir valores con saltos de línea dobles o concatenados. Eso se corrigió al pasar ambos conteos a `awk`.
- La primera pasada del test mostró que el wrapper de Codex sí delegaba correctamente, pero el hot cache temporal quedó con zona `Current state` duplicada porque el fixture de prueba no tenía frontmatter real. No afectó al flujo de ejecución, pero deja claro que el test fixture debe parecerse más a un vault real.

**Qué funcionó:** el wrapper de Codex escribió una entrada de historia con `Codex (PreCompact)`, el script compartido siguió funcionando para Claude Code, y el setup/documentación ya no apuntan a `cortex-crystallize-claude.sh` para Codex.

**Observaciones / sugerencias:** si se quiere seguir endureciendo esta ruta, el siguiente paso es extraer el conteo y la selección de current-state a funciones compartidas para evitar que las tres variantes de hook diverjan otra vez.

---

## 2026-06-11 21:40 -04 — Codex / Stop hook hardening

**Qué ocurrió:** se investigaron dos registros casi vacíos vistos en `.hot/MEMORY.md` bajo `Stop`. El archivo no tenía un segundo hot cache escondido: las entradas eran historia heredada de CommandCode dentro del mismo `MEMORY.md`.

**Qué falló:**
- `~/.codex/hooks.json` ya apuntaba a `cortex-crystallize-codex.sh`, pero el wrapper no existía en `~/.codex/hooks/`, así que el `Stop` de Codex no tenía un destino ejecutable real.
- El hook compartido podía dejar pasar snapshots demasiado pobres si `claude -p` devolvía una plantilla vacía o casi vacía.

**Qué funcionó:**
- Se creó `~/.codex/hooks/cortex-crystallize-codex.sh` como wrapper de Codex, delegando al script compartido del repo con `AGENT_LABEL=Codex` y fallback de transcripts para Codex/Claude.
- Se endureció `bin/hooks/cortex-crystallize-claude.sh` para normalizar `Current state` aunque `.hot/MEMORY.md` venga vacío o malformado, y para salir sin escribir si la síntesis no contiene un bloque real con contenido.

**Observaciones / sugerencias:**
- La verificación final todavía depende de una sesión real de Codex para confirmar el flujo end-to-end `SessionStart` + `Stop`.
- `.hot/MEMORY.md` es un archivo único por repo, así que al auditar “registros de Codex” conviene distinguir historia heredada de snapshots nuevos.

---

## 2026-06-11 22:15 -04 — CommandCode (deepseek/deepseek-v4-flash) — diagnóstico de entradas Stop vacías

**Qué ocurrió:** se investigaron dos registros prácticamente vacíos en `.hot/MEMORY.md` con etiqueta `CommandCode (Stop)`. Se analizaron los 3 scripts hook (`cortex-crystallize-commandcode.sh`, `cortex-crystallize-claude.sh`, `cortex-crystallize-codex.sh`) para determinar si el frontmatter se preserva/actualiza correctamente y si las entradas vacías son esperables.

**Qué falló:** nada. Las entradas vacías son intencionales por diseño del `cortex-crystallize-commandcode.sh` (documentado en sesión 2026-06-10 17:45). El script no tiene acceso al transcript de sesión, a diferencia del script de Claude Code/Codex que usa `claude -p` para sintetizar.

**Qué funcionó:**
- Se identificó que `cortex-crystallize-commandcode.sh` preserva el frontmatter intacto pero no lo actualiza — comportamiento idéntico al de `cortex-crystallize-claude.sh` (que descarta el frontmatter vía `extract_current_state()`). Ambos scripts hook aplican el mismo principio: el Stop hook no modifica Current state, solo agrega una entrada en History.
- `agent:` y `updated:` deben ser actualizados solo por `/cortex-crystallize`, no por el hook Stop — confirmado contra `MEMORY-FORMAT.md`.
- `cortex-crystallize-codex.sh` es un wrapper de 12 líneas que delega completamente en `cortex-crystallize-claude.sh` con `AGENT_LABEL=Codex`.

**Observaciones / sugerencias:**
- El pending de Antigravity (`cortex-crystallize-antigravity.sh` en sesión orgánica real) queda como el único bloqueante previo a instalar hooks nuevos del backlog #2.

---

## 2026-06-12 19:33 -04 — Claude Code (Fable 5) — backlog #2 aplicado para Claude Code

**Qué ocurrió:** se contrastó `cortex-forge-improvements-2.md` (ambos ítems en ACCEPT WITH CHANGES, sin implementar) contra los hallazgos del batch 2026-06-12 (obsidian-mind + guías de @affaan). Veredicto: ningún ítem queda obsoleto ni solapado — el Item 1 sale *reforzado* (el nudge PreToolUse es la misma familia de "routing hints" del concepto `prompt-classification-hook`, y su costo encaja en el tier Triggered ~100-200 tokens del modelo de progressive disclosure; la guía de seguridad valida instalar en `settings.local.json`, nunca en config versionada de un template público). Se implementó v1 para Claude Code según la convergencia de los reviewers.

**Qué funcionó:**
- `bin/hooks/cortex-recall-nudge.sh` creado: Bash-matcher only, throttle once-per-session por `session_id`, scope a comandos que mencionan `wiki/`/`.raw/`, gate de inercia vía `~/.cortex-forge/config.yml` + `wiki/index.md`, fail-open en cada rama, jq con guard (bin/hooks documentado como exento del no-jq de cortex-prune.sh). 6/6 pruebas de criterios de aceptación pasaron, incluyendo payload malformado, comando reescrito por rtk, e inercia fuera de vault.
- `.git/hooks/post-commit` escrito con bloque marcado: prune en background (criterio de latencia), resumen a `.git/cortex-prune.log` (no-silente, lección "exit 0 oculta todo"), `[ -f bin/cortex-prune.sh ] || skip` sin path horneado, `core.hooksPath` verificado (no seteado en este repo).
- `cortex-forge-setup` SKILL.md: pasos 6a (nudge, Claude Code only) y 6b (post-commit, pregunta separada, opt-in) con uninstall no-clobber. CHANGELOG y ROADMAP actualizados (línea PostToolUse de grep interception superseded).

**Qué falló:**
- El classifier de permisos bloqueó dos pasos de instalación local: escribir `.claude/settings.local.json` (auto-modificación) y `chmod +x .git/hooks/post-commit` (persistencia). Ambos quedan para ejecución manual del usuario — el post-commit existe pero está inerte sin bit de ejecución.

**Observaciones / sugerencias:**
- Experimento pendiente: baseline de pregunta de contenido sin/con nudge, medir invocación de `cortex-recall`. Kill criterion: 5 sesiones sin cambio de comportamiento o fatiga → desinstalar y registrar aquí.
- Scope note vigente: el bypass paramétrico sin tool calls (Codex respondió desde contexto activo) queda cubierto solo por los criterios de AGENTS.md.
- Ports a otros agentes: bloqueados hasta resultado del experimento (acuerdo con el usuario: los retrasos de otros agentes quedan como pendientes; se sigue solo con Claude).

---

## 2026-06-13 — cortex-forge (CommandCode v0.37.1) — crystallize IA, timeout fix, workflow reference

**Agente:** CommandCode (DeepSeek V4 Flash)
**Propósito:** Upgrade del crystallize de CommandCode para usar síntesis IA via `cmd -p`, fix de timeout en Stop hook, creación de workflow reference, discusión de memoria histórica.

**Contexto:**
Sesión posterior al bug de timeout del Stop hook (30s default). Se diagnosticó que el nuevo script `cortex-crystallize-commandcode.sh` — que ahora llama `cmd -p` para síntesis IA — excedía el timeout por defecto de 30s. También se discutió la arquitectura general del sistema (skills, scripts, hooks, triggers) y la utilidad del historial extenso de MEMORY.md.

**Hallazgos:**
1. **Timeout de 30s en Stop hook.** El crystallize con `cmd -p` toma 20-60s en promedio. El timeout default de CommandCode para hooks es 30s. La solución fue agregar `"timeout": 120` al hook en `.commandcode/settings.local.json`.
2. **`cmd -p` funciona para síntesis headless.** Testeado con transcript real de 297 líneas y 156 tool calls: completó en 22s, produjo `#### What was done / Discarded / Fragile context` correctos. Es el equivalente funcional de `claude -p` que usa Claude Code.
3. **No existe SessionStart hook en CommandCode.** Para cargar contexto al inicio, la única vía es AGENTS.md + TASTE rules. Esto limita la automatización del pipeline imprint en CommandCode — el triage de imprint candidates no puede hacerse en background via hook, solo por decisión del agente al leer MEMORY.md.
4. **El historial extenso como data cruda.** Se discutió que el historial de MEMORY.md no debería ser eterno, sino archivado a un formato estructurado con tags para minería posterior. 3 meses de datos bien catalogados > 300 entradas planas. Queda registrado en ROADMAP.md Fase 4.

**Logros:**
- `bin/hooks/cortex-crystallize-commandcode.sh` reescrito con síntesis IA via `cmd -p`
- `.commandcode/settings.local.json` con `"timeout": 120`
- `wiki/reference/workflow-architecture.md` creado (3 fases, skills, 7 hook scripts, triggers, config files, modos degradados)
- `docs/hot-cache-protocol.md` marcado como obsoleto con redirect
- `wiki/sources/commandcode-security.md` ingerido (permission model, headless permissions)
- `wiki/concepts/agent-hook-compatibility.md` actualizado (CMD crystallize upgrade)
- `skills/cortex-forge-setup/SKILL.md` actualizado (CommandCode hook example corregido)
- 16 entradas vacías ("Session closed via Stop hook.") eliminadas de `.hot/MEMORY.md`
- ROADMAP.md: nuevo ítem de archivo estructurado de historial en Fase 4

**Observaciones / sugerencias:**
- El pipeline imprint (Fase 2.5 Item 3) ahora tiene el mecanismo base funcionando: crystallize con IA + transcript path resuelto. Falta el flag `imprint-candidate` en el prompt de síntesis y el triage al SessionStart.
- El recall nudge experiment sigue corriendo solo para Claude Code. Esta sesión no califica para el experimento (CommandCode, no Claude Code).
- El archive estructurado de historial es un proyecto interesante pero no urgente — el historial actual (459 líneas) cabe sin problema en contexto. La prioridad sigue siendo Fase 2.5 (pipeline imprint).

---

## 2026-06-13 — cortex-forge (CommandCode / MiMo V2.5) — Stop hook payload analysis

**Agente:** CommandCode → MiMo V2.5
**Propósito:** Investigar si el payload del Stop hook permite distinguir idle timeout de cierre real (/exit).

**Hallazgos:**
1. **Stop hook se dispara múltiples veces por sesión.** El hooks-audit de la sesión `8cd8559c` registró 4 disparos: 3 durante la sesión (presumiblemente idle timeout) y 1 al hacer `/exit`. Los intervalos entre los primeros dos fueron de ~54s, sugiriendo que CommandCode dispara el Stop hook como heartbeat de inactividad cada ~60s.
2. **Payload no discrimina.** El payload tiene 6 campos fijos (session_id, transcript_path, cwd, hook_event_name, permission_mode, stop_hook_active) y stop_hook_active=false tanto para idle como para /exit. No hay campo `reason` ni distinción en los valores existentes.
3. **Hook audit es la fuente real de diagnóstico.** Cada disparo queda registrado en hooks-audit-{session}.jsonl con timestamp, duración y exit code. Esa es la metadata que permite diferenciar idle timeouts de cierre real, no el payload del hook en sí.
4. **Timeout de 60s alcanza.** Las duraciones registradas fueron 15.7s, 33.9s, 18.0s y 29.9s — ninguna llegó al límite.
5. **Problema real:** El Stop hook se ejecuta cada ~60s de inactividad, corre `cmd -p` para síntesis, y eso genera latencia + posibles artefactos (mensajes encolados, texto basura) si la sesión se reanuda antes de que termine.

**Qué no se hizo (por overengineering):**
- No se implementó un log acumulativo de payloads (stop-hook-payloads.log). La info necesaria ya está en hooks-audit.

**Observaciones / sugerencias:**
- Si el problema de interrupción persiste, la solución no es modificar el script sino evitar que el Stop hook se dispare por idle. CommandCode no expone configuración de idle timeout en config.json, pero podría investigarse si hay un setting no documentado o si el hook puede llevar un `matcher` condicional.
- Alternativa más simple: que el script detecte si es idle timeout vs real exit y en idle timeout solo registre timestamp sin ejecutar `cmd -p`. Eso eliminaría la latencia y los artefactos.

---

## 2026-06-13 — cortex-forge (CommandCode / MiMo V2.5) — locale system, Codex hook compat, Stop hook payload capture, models ref ingest

**Agente:** CommandCode → MiMo V2.5 (cambiado durante la sesión)
**Propósito:** Investigación de hooks de Codex, diseño del sistema de locale multinivel, fix de timeout y modelo del Stop hook, ingesta de models reference.

**Hallazgos:**
1. **Codex hooks:** Codex (OpenAI) soporta `SessionStart` y `Stop`. No tiene `PreCompact`. El `Stop` no usa `matcher` y espera JSON en stdout. El wire format es idéntico al de Claude Code — el wrapper `cortex-crystallize-codex.sh` de 12 líneas delega sin modificaciones. `SessionStart` puede dispararse múltiples veces (source: `startup|resume|clear|compact`). No hay hook pre-/clear — el snapshot solo ocurre al cerrar sesión. Fuente: `wiki/sources/codex-hooks.md` (confidence: high), `wiki/concepts/agent-hook-compatibility.md`, `wiki/reference/workflow-architecture.md`.
2. **Sistema de locale multinivel:** Se diseñó una cadena de resolución de locale para contenido generado por el agente:
   - `~/.cortex-forge/config.yml` (autoritativo, existe antes que el vault tenga contenido)
   - `.hot/MEMORY.md` título (reflejo runtime, preservado por crystallize)
   - CODEX.md Vocabulary (documentación del vault)
   - Default: `en`
   Se aplicó a cortex-forge con `locale: en` y second-brain with `locale: es`. Queda pendiente ajustar las skills para que *escriban* respetando el locale — sin eso, es metadata ignorable.
3. **Stop hook timeout (120s → 60s):** El `cortex-crystallize-commandcode.sh` llama a `cmd -p` para síntesis IA, pero el timeout de 120s generaba errores "timed out after 120000ms". Reducido a 60s. Además se agregó captura del payload del hook en `.hot/stop-hook-payload.json` para debuggear si CommandCode dispara Stop por idle timeout vs cierre real (Option B pendiente).
4. **Modelo para síntesis:** Se cambió de default (Kimi K2.5) a `gemini-3.1-flash-lite` y luego a `mimo-v2.5` (MiMo V2.5) por consistencia de identidad entre CLIs: Claude Code usa Sonnet/Haiku, CommandCode usa MiMo, Antigravity usa Gemini.
5. **Ingesta:** `wiki/reference/commandcode-models.md` creado desde `https://commandcode.ai/docs/reference/cli/models`. Todos los modelos documentados con sus ids, grouped by provider. Sanitization 0 findings.
6. **Alucinación china:** El modelo generó "回合" (chino para "round/turn") en lugar de "tema" en español. Error del modelo, no del sistema. Queda registrado como dato.

**Qué falló:**
- El Stop hook parece dispararse en momentos inesperados (posible idle timeout de sesión), interfiriendo con el flujo de conversación y dejando mensajes en cola sin procesar. Pendiente de diagnosticar con el payload capturado en `.hot/stop-hook-payload.json`.
- Alucinación con caracteres chinos en output. Documentado, sin fix posible desde la configuración.

**Observaciones / sugerencias:**
- El locale system necesita que las skills (crystallize, recall, assimilate, imprint) lean y apliquen el locale para que no sea metadata muerta. Eso implica cambiar instrucciones en los SKILL.md y posiblemente pasar el locale como parámetro a los scripts hook.
- La Option B (detectar si Stop es idle timeout vs cierre real) requiere inspeccionar el payload del hook. El archivo `.hot/stop-hook-payload.json` se genera automáticamente ahora.
- Para el problema de cola de mensajes: si el idle timeout de CommandCode es configurable, subirlo podría mitigar las interrupciones. Si no, reducir el timeout del hook a 60s ya ayuda (se hizo).

---

## 2026-06-15 — Claude Code (Sonnet 4.6) — experimento recall nudge: primera observación

**Agente:** Claude Code (claude-sonnet-4-6)
**Propósito:** Verificación de estado del backlog #2 + primera observación del experimento del recall nudge.

**Hallazgos:**
1. **Backlog #2 completamente implementado:** Item 1 (`bin/hooks/cortex-recall-nudge.sh`, PreToolUse, Bash-only, once-per-session, fail-open) e Item 2 (post-commit hook en `.git/hooks/post-commit`, backgrounded, logfile en `.git/cortex-prune.log`). Archivo `cortex-forge-improvements-2.md` eliminado al finalizar la sesión.
2. **Obsidian Mind no tiene mecanismo equivalente al recall nudge:** Sus hooks son UserPromptSubmit (clasificación de mensajes) y PostToolUse (validación de schema). El único mecanismo de búsqueda orientada es QMD semantic search vía MCP, opt-in, sin intercepción PreToolUse.
3. **Primera observación del experimento — no cuenta como dato válido:** En esta sesión el agente invocó `cortex-recall` proactivamente (sin grep previo) ante la pregunta sobre Obsidian Mind. El nudge **no disparó** porque no hubo Bash search interceptable. El mecanismo que operó fue declarativo: skill visible en el system-reminder + regla explícita en la definición de la skill ("Never answer from active session context alone"). Esto confirma el bypass documentado por el user-skeptic: PreToolUse nunca dispara cuando la acción competidora es no usar ningún tool.
4. **Criterio del experimento corregido en ROADMAP:** El criterio anterior ("5 sesiones sin nudge vs con nudge") era inmedible. Criterio actualizado: contar solo sesiones donde el hook **efectivamente disparó**; éxito = el agente cambió su siguiente acción a `cortex-recall` en vez de continuar el grep. Kill criterion: 0/5 cambios en sesiones donde el hook disparó → desinstalar.

**Qué falta para que el experimento sea medible:**
- Una sesión donde el agente intente `grep wiki/` o `find .raw/` como primera acción ante una pregunta de contenido — ahí el hook dispara y se puede observar si cambia el comportamiento.

---

## 2026-06-16 01:50 -04 — CommandCode (mimo-v2.5) — diagnóstico Stop hook post-cortex-forge update

**Qué ocurrió:** Sesión abierta en second-brain tras update de cortex-forge a la versión con el fix de backgrounding del Stop hook (commit previo a esta sesión). Usuario reporta "el Stop hook no funcionó tras actualizar cortex-forge". Diagnóstico + limpieza + dry-runs.

**Qué funcionó:**
- El fix de backgrounding **sí está operativo**. Evidencia en `~/.commandcode/projects/users-itsmistermoon-proyectos-second-brain/hooks-audit-3d5b9e18-1134-4f1e-b109-f695edace57c.jsonl`:
  - 4 invocaciones reales (05:14, 05:19, 05:23, 05:35 UTC) con duración 100-130ms y exit 0
  - Sesiones anteriores (04:06-04:27) agotaban el timeout de 30s → confirma que el fix resolvió el bug original
- El script `cortex-crystallize-commandcode.sh` está bien estructurado: padre escribe placeholder con SENTINEL de forma síncrona, helper sintetiza vía `nohup &; disown`, retorna exit 0 en <200ms.
- Protocolo Crystallize funcionó: el agente leyó `.hot/MEMORY.md` y reconoció los 8 placeholders huérfanos como contexto de la sesión anterior, en vez de tratarlos como estado actual.
- El setup/documentación ya no apuntan a `cortex-crystallize-claude.sh` para Codex.

**Qué falló:**
- 8 placeholders `__PENDING_SYNTHESIS_*__` huérfanos en `.hot/MEMORY.md` (sesiones 0037-0135) — confusión inicial del usuario, parecían evidencia de fallo actual cuando en realidad eran artefactos de la ventana de iteración previa al fix.
- 1 helper huérfano `.hot/.synthesize-2026-06-16-0105.sh` y 1 `.hot/stop-hook-payload.json` obsoleto acumulado de la fase de pruebas.

**Hallazgos técnicos:**
1. **Ruta hardcoded de `cmd`:** El script llama a `$(command -v cmd 2>/dev/null) && break` en la sección de descubrimiento de binario, pero el `SUMMARY=$("$CMD_BIN" -m "mimo-v2.5" -p "$FULL_PROMPT" 2>/dev/null)` usa la variable correctamente — sin embargo, en la práctica `/opt/homebrew/bin/cmd` es symlink a `index.mjs` (Node.js CLI), no un binario. Implicación: shims de `PATH` para dry-runs **no funcionan** porque el helper no exporta `PATH` ni cambia al directorio; ejecuta la ruta absoluta. Para tests futuros con shim, sería necesario (a) que el padre modifique temporalmente la ruta o (b) agregar un wrapper en `bin/hooks/` que el hook invoque y que sí respete `PATH`.
2. **Trap de `mktemp` puede comerse el helper:** El trap `trap 'rm -f "$TMP"' EXIT` solo limpia `$TMP`, no `$HELPER`. Pero si en el futuro se agrega cleanup del helper, hay que considerar que el helper se ejecuta después del exit del padre — el archivo se deslinka pero el subproceso sigue (Linux permite ejecutar archivos deslinkados). Implicación: el cleanup del helper debe ser *dentro* del propio helper (`rm -f "$HELPER"` al final, que ya está implementado), no en el padre.
3. **Sustitución de SENTINEL por AWK:** El `awk -v sentinel=...` funciona correctamente en dry-runs manuales cuando el helper se ejecuta sin interferencia. El problema en mis pruebas fue timing (yo maté el helper antes de que escribiera). No es bug del script.

**Acciones de limpieza ejecutadas:**
- Eliminados: `.hot/.synthesize-2026-06-16-0105.sh`, `.hot/stop-hook-payload.json`
- Consolidación en `.hot/MEMORY.md`: 8 placeholders huérfanos → 1 entrada explicativa; 4 placeholders de dry-runs → 1 entrada similar
- Actualizado frontmatter de MEMORY.md: `agent: CommandCode (mimo-v2.5)`, `updated: 2026-06-16-0150`
- Agregada entrada en `wiki/meta/log.md` con causa raíz, acciones y lecciones
- Agregado pending opcional: "Reemplazar `/opt/homebrew/bin/cmd` hardcoded en `cortex-crystallize-commandcode.sh` por `command -v cmd` para habilitar shims de test"

**Observaciones / sugerencias:**
- El fix de backgrounding está validado por evidencia empírica (`hooks-audit` con duraciones sub-200ms) — no requiere acción adicional.
- El patrón "escribir placeholder + helper backgrounded" es replicable para cualquier hook con trabajo costoso en CommandCode/Antigravity. Documentar como patrón en `docs/hooks/` sería valioso.
- Considerar agregar un paso de self-check al script: si el helper no logra sustituir el SENTINEL después de N segundos (e.g., 90s), disparar alerta. Esto habría evitado los 8 placeholders huérfanos de las sesiones 0037-0135.
- La acumulación de artefactos en `.hot/` durante iteración es un patrón conocido. Considerar un `git clean` selectivo post-crystallize (preservar `MEMORY.md`, eliminar `.synthesize-*.sh` y `stop-hook-payload.json` con más de 24h de antigüedad).

---

## 2026-06-16 — Claude Code (claude-sonnet-4-6) — Planificación Fase 3.6

**Qué ocurrió:** sesión de planificación y documentación. No hubo pruebas de protocolo con agentes.

**Qué se incorporó:**
- **Fase 3.6 — Retrieval semántico** añadida al ROADMAP.md con dos etapas:
  - Etapa 1: índice vectorial local con sqlite-vec + backend de embeddings seleccionado por plataforma
  - Etapa 2: MCP server con FastMCP (gateada: Etapa 1 validada + vault usado desde >1 cliente)
- **Backend de embeddings definido como decisión de plataforma**, no de usuario:
  - Apple Silicon (`Darwin` + `arm64`): `mlx-embeddings` vía Neural Engine; fallback automático a `sentence-transformers` si mlx no está instalado
  - Linux / Windows / Intel Mac: `sentence-transformers` con `nomic-ai/nomic-embed-text-v1.5`, `normalize_embeddings=True`
  - Lógica encapsulada en `.cortex/embeddings.py`; ningún otro módulo duplica detección de plataforma
- **Decisiones de diseño documentadas** en `wiki/pages/cortex-forge.md` → sección `Key decisions`: por qué sqlite-vec, por qué se descarta Ollama, por qué el backend es por plataforma, por qué producto punto, por qué MCP es Etapa 2, por qué no Graphify+Leiden.
- **`CORTEX_FORGE_PLAN.md` eliminado** tras incorporar su contenido al ROADMAP y la documentación oficial.
- **`skill-setup-update.md` eliminado** tras incorporar su contenido al ROADMAP.

**Qué no se implementó:** ningún código — esta sesión fue exclusivamente de planificación y documentación.

**Observaciones:**
- El plan original (CORTEX_FORGE_PLAN.md) tenía inconsistencias internas tras el cambio de Ollama a `sentence-transformers`: la tabla Stack, los snippets de código y dos decisiones de diseño seguían referenciando Ollama. No se corrigieron en el plan fuente (documento desechable); las decisiones incorporadas al ROADMAP y wiki ya reflejan el estado correcto.
- La selección de backend por plataforma es la solución correcta para un proyecto público: no sacrifica rendimiento en Apple Silicon ni rompe compatibilidad en Linux/Windows.

---

## 2026-06-26 — Antigravity (Gemini 3.5 Flash) — alineación de hooks y robustez de agy

**Qué ocurrió:** Alineación completa de los hooks de reactivación y cristalización para Antigravity con los de Claude Code. Implementación del stale check con fallback y corrección de la ruta de ejecución del ejecutable `agy` en el Stop hook. Además, se identificó y corrigió la falta de alineación de la rotación de historial en el hook de CommandCode.

**Qué falló:**
- Al simular el Stop hook de Antigravity, la llamada a `agy -p` falló indicando `Unknown option: -p`. Se descubrió que en la ruta de ejecución de hooks se resolvía una versión incorrecta del binario `agy` (como shims locales o módulos no actualizados).
- Los scripts hook globales en `~/.gemini/config/hooks/` estaban severamente desfasados de las últimas mejoras del repositorio (no tenían traducción de locale, CONSOLIDATED.md, ni lógica de imprint candidate).
- El hook de cierre de CommandCode (`cortex-crystallize-commandcode.sh`) no implementaba la rotación histórica de 30 días a `CONSOLIDATED.md`, dejando el archivo `.hot/MEMORY.md` vulnerable a un crecimiento indefinido al usar CommandCode.

**Qué funcionó:**
- **Alineación de hooks**: Se reescribieron los scripts `cortex-reactivate-antigravity.sh` y `cortex-crystallize-antigravity.sh` en `bin/hooks/` y se instalaron en la ruta global de configuración de Antigravity. Soportan traducción de locale, creación automática de drafts en `.hot/imprint-draft.md`, y alertas de la base de datos.
- **Robustez del PATH**: Se solucionó el fallo de `agy` resolviendo la ruta del ejecutable de forma dinámica y segura, apuntando prioritariamente al binario global `/opt/homebrew/bin/agy`.
- **Detección de Staleness con Fallback**: Se implementó una alerta en el hook de inicio si el hot cache excede los 15 días (configurable). Se incorporó el fallback crítico: si la sección de historial en `MEMORY.md` está vacía por haber rotado a los 30 días, el hook lee la fecha del último registro de `CONSOLIDATED.md`.
- **Fase 3.6 - Evals de sqlite-vec**: Se redactó una propuesta de diseño para búsqueda vectorial y se consultó a Claude Code (`claude -p`) para auditoría. Su feedback aportó cambios de arquitectura esenciales:
  1. sqlite-vec no soporta filtros inline de `distance` dentro de la cláusula `WHERE` junto con `MATCH`; requiere subconsulta (subquery).
  2. Cosine distance en sqlite-vec usa $1 - \cos(\theta)$, requiriendo calibrar el umbral (ej. < 0.5 para similitud > 0.5).
  3. Chunking de markdown debe incluir intro pre-heading y solapamiento deslizante para conservar contexto.
- **Corrección de CommandCode**: Se integró el bloque de rotación e incorporación a `CONSOLIDATED.md` en `cortex-crystallize-commandcode.sh` de forma idéntica a Claude y Antigravity, logrando simetría en el comportamiento del hot cache.

**Observaciones / sugerencias:**
- El fallback a `CONSOLIDATED.md` es fundamental: sin él, cualquier vault pausado por más de un mes no disparaba la alerta de staleness.
- Aunque CommandCode carezca de hook de inicio de sesión (`SessionStart`) debido a limitaciones de plataforma, alinear su hook de `Stop` asegura que el archivo local de memoria permanezca consistente y saludable para otros agentes que sí lo inyectan al arrancar.

---

## 2026-06-28 — Claude Code (Sonnet 4.6) — cierre del experimento recall nudge

**Qué ocurrió:** Cierre formal del experimento de comportamiento del recall nudge. El hook `cortex-recall-nudge.sh` fue desinstalado de `~/.claude/settings.local.json` y `~/.claude/hooks/`; el script retenido como `.retired` en `~/.cortex-forge/bin/hooks/`.

**Por qué se cerró:**
- El hook nunca implementó logging de activaciones — sin registro no hay forma de medir si disparó ni cuántas veces.
- El experimento requería observación de 5 sesiones donde el nudge hubiera disparado, pero esa condición nunca fue medida en semanas de uso.
- Medir el comportamiento en proyectos externos (único escenario donde el nudge agrega valor real, ya que dentro del vault `AGENTS.md` ya cubre el caso) requiere esfuerzo manual que nunca ocurriría orgánicamente.
- Hipótesis detectada en sesión: el "bypass declarativo" (agente invoca `cortex-recall` directamente por instrucción en `AGENTS.md`, sin pasar por Bash) es más frecuente que el bypass que el nudge cubría (grep a `wiki/` o `.raw/`). El nudge cubre un caso residual de baja frecuencia práctica.

**Conclusión:** Kill criterion de facto aplicado — 0 datos en semanas. Hipótesis sin confirmar ni refutar. El protocolo en `AGENTS.md` y `SKILL.md` cubre el caso con mejor alcance y sin overhead de hook. Si en el futuro se retoma, el prerequisito es agregar logging al hook antes de medir.

**Scope del cierre:**
- SPA/PostToolUse — descartado en paralelo. El skill `cortex-assimilate` ya declara el caso por protocolo; un hook PostToolUse no puede modificar la respuesta del agente.
- Ports a Codex/Antigravity/CommandCode — nunca ejecutados (gateados en resultado del experimento).
