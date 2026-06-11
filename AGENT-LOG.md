---
title: "AGENT-LOG — bitácora de sesiones multi-agente"
created: 2026-06-08
updated: 2026-06-08
---

# AGENT-LOG

Bitácora de sesiones de prueba del protocolo Cortex Forge con distintos agentes.
Cada entrada es el selfreport de una sesión: qué ocurrió, qué falló, qué funcionó,
y qué observaciones o sugerencias ofrece el agente.

**No es un tracker de tareas.** No hay `Pending`, ni `Active decisions`, ni `Current state`.
Para eso existe `.hot/MEMORY.md`.

---

## Cómo agregar una entrada

Al cerrar una sesión de prueba relevante, agrega una nueva entrada **al final del archivo**
con este template mínimo:

```
---

## YYYY-MM-DD [HH:MM -TZ] — {Agente} ({modelo si se conoce})

**Qué ocurrió:** resumen breve de la sesión (1-3 líneas).

**Qué falló:** comportamientos incorrectos, errores, incumplimientos de protocolo.

**Qué funcionó:** comportamientos correctos, mejoras respecto a sesiones anteriores.

**Observaciones / sugerencias:** hallazgos inesperados, hipótesis, mejoras propuestas.
```

Reglas:
- Sé específico: cita archivos, scripts y comportamientos concretos.
- No edites entradas anteriores. Si necesitas corregir un dato, agrega una nota al final
  de la entrada equivocada o agrega una nueva entrada con la corrección.
- El agente redacta su propia entrada. Si no puede hacerlo, la redacta Claude Code
  desde el log proporcionado por el usuario, indicándolo explícitamente.

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
  no el archivo completo.
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
