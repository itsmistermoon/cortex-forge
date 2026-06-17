---
title: Workflow Architecture
type: reference
created: 2026-06-13
updated: 2026-06-13
tags: [cortex-forge, architecture, workflow, hooks, skills, scripts, agents]
sources:
  - wiki/sources/commandcode-hooks-configuration.md
  - wiki/sources/commandcode-hooks-reference.md
  - wiki/sources/commandcode-headless.md
  - wiki/sources/commandcode-security.md
confidence: high
schema_version: "0.3"
---

# Workflow Architecture

Cómo opera cortex-forge a través de agentes: qué se gatilla en cada fase de una sesión, qué skills usar en medio, y cómo degrada cuando faltan hooks.

---

## Las tres fases de una sesión

Cada sesión de un agente sigue tres fases: **Start**, **During** y **End**. cortex-forge actúa en cada una con un mecanismo distinto — hooks automáticos cuando existen, skills manuales como fallback.

```
Start ─────┬─ Hook SessionStart → inyecta .hot/MEMORY.md
            └─ Sin hook → AGENTS.md instruye leer .hot/MEMORY.md

During ──── Skills invocados por el agente:
              /cortex-assimilate, /cortex-recall, /cortex-prune,
              /cortex-imprint, /cortex-crystallize

End ───────┬─ Hook Stop → extrae transcript, sintetiza, escribe snapshot
            └─ Sin hook → /cortex-crystallize manual (o no hay snapshot)
```

---

## Fase 1: Session Start — Cargar contexto

El agente necesita saber qué pasó antes. Cortex-forge se lo entrega via `.hot/MEMORY.md`.

| Agente | Evento | Script | Mecanismo | Dónde se configura |
|--------|--------|--------|-----------|-------------------|
| Claude Code | `SessionStart` | `cortex-reactivate.sh` | Lee MEMORY.md, lo inyecta como `additionalContext` via stdout JSON | `~/.claude/settings.local.json` (global) |
| Codex | `SessionStart` | `cortex-reactivate.sh` | Mismo script, mismo mecanismo | `~/.codex/hooks.json` (global) |
| Antigravity | `PreInvocation` (invoc. 0) | `cortex-reactivate-antigravity.sh` | Lee MEMORY.md Zone 1, inyecta como `ephemeralMessage` | `~/.gemini/config/hooks.json` (global) |
| CommandCode | **no existe** | — | Sin SessionStart hook. Reemplazo: AGENTS.md + TASTE rule instruyen leer MEMORY.md al inicio | — |

**Fallo conocido (CommandCode):** no hay hook para inyectar contexto automáticamente. La instrucción en `AGENTS.md` de leer `.hot/MEMORY.md` es la única vía. Funciona si el agente respeta AGENTS.md, pero es menos confiable que un hook.

---

## Fase 2: During Session — Skills

Skills se invocan manualmente durante la sesión. No tienen hooks — el agente (o el usuario) elige cuándo usarlos.

| Skill | Cuándo invocar | Qué hace | Dónde vive |
|-------|---------------|----------|-----------|
| `/cortex-recall` | Cuando el usuario pregunta sobre algo que el vault pueda cubrir | Busca en `wiki/` y responde con citas + confidence. **Protocolo obligatorio** — no usar grep/find como reemplazo | `skills/cortex-recall/SKILL.md` |
| `/cortex-assimilate` | Cuando llega una URL o archivo nuevo para ingerir | Descarga → SPA detection → guarda en `.raw/` → sintetiza páginas wiki → actualiza índice. **Protocolo obligatorio** | `skills/cortex-assimilate/SKILL.md` |
| `/cortex-crystallize` | Al cerrar un hito, o cuando el usuario pide "guardar contexto" | Snapshot del estado actual de la sesión en `.hot/MEMORY.md` | `skills/cortex-crystallize/SKILL.md` |
| `/cortex-prune` | Periódicamente, o cuando el vault-report muestra issues | Health check: detecta dead links, raw huerfanos, páginas sin frontmatter, confidence faltante | `skills/cortex-prune/SKILL.md` |
| `/cortex-imprint` | Cuando la sesión produjo análisis o síntesis que vale la pena persistir | Archiva el hallazgo como página permanente en `wiki/` | `skills/cortex-imprint/SKILL.md` |

**TASTE rules** (CommandCode) en `.commandcode/taste/taste.md` recuerdan al agente qué skills usar y cuándo. En otros agentes, el equivalente es `AGENTS.md`.

---

## Fase 3: Session End — Guardar snapshot

Al cerrar la sesión, el agente necesita escribir qué se hizo, qué se descartó, y qué contexto es frágil. El hook Stop captura esto automáticamente si existe.

| Agente | Evento | Script | Qué hace | Dónde se configura |
|--------|--------|--------|----------|-------------------|
| Claude Code | `SessionEnd` (Stop) | `cortex-crystallize-claude.sh` | Parsea transcript JSONL via jq, extrae tool calls + user messages, llama `claude -p` para síntesis IA, escribe en `.hot/MEMORY.md` | `~/.claude/settings.local.json` (global) |
| Claude Code | `PreCompact` | `cortex-crystallize-claude.sh` | Mismo script, mismo prompt pero con mode note "mid-session" — se ejecuta ANTES de compactar la ventana | `~/.claude/settings.local.json` (global) |
| Codex | `Stop` | `cortex-crystallize-codex.sh` | Wrapper de 12 líneas: setea `AGENT_LABEL=Codex`, delega a `cortex-crystallize-claude.sh` | `~/.codex/hooks.json` (global) |
| CommandCode | `Stop` | `cortex-crystallize-commandcode.sh` | Parsea transcript JSONL (schema CommandCode: `role`-based), extrae tool calls, llama `cmd -p` para síntesis IA. Timeout configurado a 120s (la llamada API puede tomar 20-60s) | `{vault}/.commandcode/settings.local.json` (proyecto) |
| Antigravity | `Stop` (fullyIdle) | `cortex-crystallize-antigravity.sh` | Parsea DB SQLite+Protobuf via `strings`, extrae user messages de `history.jsonl`, llama `agy -p` | `~/.gemini/config/hooks.json` (global) |

### Disparadores adicionales en Stop

No todos los Stop son iguales. Según el agente, el evento Stop puede tener sub-tipos:

| Agente | Sub-tipo | Script lo maneja? |
|--------|----------|-------------------|
| Claude Code | `compact` (compresión de contexto normal) | Sí — precompact previene perder contexto |
| Claude Code | `clear` (borrado de historial manual) | Sí — deja snapshot antes de perderlo |
| Claude Code | `resume` (reanudación) | No — no hay pérdida de contexto |
| Codex | `Stop` sin sub-tipo | Sí — wrapper delega |
| CommandCode | `Stop` sin sub-tipo | Sí — script CommandCode nativo |
| Antigravity | `Stop` con `fullyIdle==true` | Sí — solo escribe si hubo trabajo real |
| Antigravity | `Stop` sin `fullyIdle` | No — el script verifica la condición |

**⚠ Plan mode:** CommandCode desactiva hooks completamente en plan mode. El Stop hook NO se ejecuta al cerrar una sesión de planificación.

---

## Scripts: referencia completa

### Hook scripts en `bin/hooks/`

| Script | Para qué agente | Evento | Propósito |
|--------|----------------|--------|-----------|
| `cortex-reactivate.sh` | Claude Code, Codex | SessionStart | Inyecta .hot/MEMORY.md como contexto adicional |
| `cortex-reactivate-antigravity.sh` | Antigravity | PreInvocation (invoc 0) | Inyecta .hot/MEMORY.md Zone 1 como ephemeralMessage |
| `cortex-crystallize-claude.sh` | Claude Code, Codex | SessionEnd, PreCompact, Stop | Parsea transcript, sintetiza via `claude -p`, escribe snapshot |
| `cortex-crystallize-codex.sh` | Codex | Stop | Wrapper: setea Codex labels, delega al script Claude |
| `cortex-crystallize-commandcode.sh` | CommandCode | Stop | Parsea transcript CommandCode, sintetiza via `cmd -p`, escribe snapshot |
| `cortex-crystallize-antigravity.sh` | Antigravity | Stop (fullyIdle) | Parsea DB Antigravity, sintetiza via `agy -p`, escribe snapshot |
| `cortex-recall-nudge.sh` | Claude Code (Bash matcher) | PreToolUse | Nudge a usar `/cortex-recall` cuando grep/rg apunta a wiki/ |

### Scripts standalone en `bin/`

| Script | Propósito | Uso |
|--------|-----------|-----|
| `cortex-prune.sh` | Health check estructural del vault | Manual o via post-commit hook |
| `cortex-sanitize.sh` | Escaneo de seguridad antes de ingerir a .raw/ | Manual, paso intermedio de `/cortex-assimilate` |
| `setup-vault.sh` | Crear estructura de directorios + config Obsidian | Una vez, al crear el vault |

---

## Degradación por plataforma

No todos los agentes tienen el mismo soporte de hooks. Esta tabla muestra qué funciona en cada uno y qué reemplazo usar cuando no.

| Agente | ¿Tiene SessionStart? | ¿Tiene Stop? | ¿Tiene PreCompact? | Degradación |
|--------|---------------------|-------------|-------------------|-------------|
| **Claude Code** | ✅ `SessionStart` | ✅ `SessionEnd` | ✅ `PreCompact` | **Completo.** Todos los hooks existen. Ciclo cerrado automático. |
| **Codex** | ✅ `SessionStart` | ✅ `Stop` | ❌ | **Casi completo.** No hay PreCompact → el snapshot solo ocurre al cerrar sesión. Si la ventana se llena, se pierde contexto medio sin registro. Reemplazo: invocar `/cortex-crystallize` manual antes de que la ventana se llene. |
| **Antigravity** | ⚠ `PreInvocation` (condicional) | ⚠ `Stop` (condicional) | ❌ | **Parcial.** Start requiere `invocationNum==0`, Stop requiere `fullyIdle==true`. Si el agente se cierra abruptamente, no hay snapshot. Reemplazo: `AGENTS.md` + invocación manual de `/cortex-crystallize`. |
| **CommandCode** | ❌ No existe | ✅ `Stop` | ❌ | **Mitad.** El Stop funciona y produce snapshots con IA. Pero sin SessionStart, el contexto hay que cargarlo via `AGENTS.md` + TASTE rules. Es menos confiable — el agente puede ignorar la instrucción. Reemplazo: `AGENTS.md` con instrucción explícita de leer `.hot/MEMORY.md`. Plan mode desactiva incluso el Stop. |
| **Trae, Copilot CLI, Cursor, etc.** | ❌ | ❌ | ❌ | **Solo manual.** Sin hooks disponibles. El protocolo funciona via `AGENTS.md` + skills invocados manualmente. El agente lee las instrucciones, invoca `/cortex-crystallize` cuando corresponde. |

### Regla general

```
¿Tiene hooks?     → Automático (start: inyecta, end: sintetiza)
¿Solo AGENTS.md?  → Semi-automático (start: agente lee instrucción, end: /cortex-crystallize manual)
¿Nada?            → Manual (humano instruye al agente paso a paso)
```

Los tres niveles producen `.hot/MEMORY.md` en el mismo formato. Cualquier agente leyendo el archivo no puede distinguir si fue escrito por un hook o por un skill manual.

---

## Config files por agente

| Agente | Archivo de configuración | Eventos configurados |
|--------|-------------------------|---------------------|
| Claude Code (global) | `~/.claude/settings.local.json` | SessionStart, PreCompact, SessionEnd, PreToolUse (recall nudge) |
| Codex (global) | `~/.codex/hooks.json` | SessionStart, Stop |
| Antigravity (global) | `~/.gemini/config/hooks.json` | PreInvocation, Stop |
| CommandCode (global) | `~/.commandcode/settings.local.json` | Stop (por vault) |
| CommandCode (proyecto) | `{vault}/.commandcode/settings.local.json` | Stop |

---

### Ubicación de scripts

Los hooks invocan scripts que están en `bin/hooks/` del vault. Durante la instalación (`/cortex-forge-setup`), los scripts se copian al directorio global de hooks del agente (`~/.claude/hooks/`, `~/.codex/hooks/`, etc.).

Para CommandCode, los scripts se ejecutan directamente desde `bin/hooks/` del vault (no hay copia global porque CommandCode permite rutas absolutas en `settings.local.json`).

---

- 2026-06-13 [CommandCode]: Page created — comprehensive workflow architecture reference covering 3-phase flow, hooks per agent, skills, scripts, degraded modes, and config files
