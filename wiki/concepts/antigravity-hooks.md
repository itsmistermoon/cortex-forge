---
title: Antigravity Hooks
type: concept
created: 2026-06-07
updated: 2026-06-08
tags: [hooks, lifecycle, configurations, gemini-cli]
aliases: [lifecycle-hooks]
sources:
  - wiki/sources/antigravity-hooks.md
  - wiki/sources/gemini-cli-hooks-video.md
confidence: medium
---

# Antigravity Hooks

Antigravity Hooks definen el patrón de configuración y ejecución para extender el lifecycle del agente en el ecosistema [[google-antigravity]] / Gemini CLI. Permiten insertar pasos de verificación, inicialización y carga de contexto en el loop del agente.

## Archivo de configuración

Antigravity hereda la ruta de Gemini CLI. Los hooks globales se leen desde:

```
~/.gemini/config/hooks.json
```

La diferencia con Gemini CLI (que usa `settings.json`) es que Antigravity usa un `hooks.json` separado — mismo directorio, archivo distinto.

### Bug conocido en agy-cli (issue #49)

Hay un bug de alineación de rutas en el CLI:

- **Ruta de lectura (correcta)**: `~/.gemini/config/hooks.json`
- **Ruta de escritura (errónea)**: `~/.gemini/antigravity-cli/hooks.json`

Si se crean o modifican hooks usando comandos del CLI, el archivo se escribe en la ruta incorrecta y los hooks no se ejecutan.

**Solución mientras no se parchee**: crear y editar `hooks.json` manualmente en la ruta correcta, o crear un symlink:

```bash
ln -s ~/.gemini/config/hooks.json ~/.gemini/antigravity-cli/hooks.json
```

## Scopes

- **Global**: `~/.gemini/config/hooks.json` — disponible en todos los proyectos
- **Workspace**: `.agents/hooks.json` en el root del proyecto

## Ruta de scripts

No hay ruta impuesta por la plataforma. Los scripts pueden vivir en cualquier directorio absoluto. Convención recomendada para Cortex Forge: `~/.gemini/config/hooks/` (alineado con el scope global).

## Mecanismos

### 1. Configuración JSON
Mapeo estático de eventos a scripts o comandos. Eventos soportados incluyen lifecycle de sesión (`SessionStart`, `Stop`) y eventos de herramientas.

### 2. SDK (Python)
Hooks programáticos para observar, modificar o bloquear tool calls y acciones del agente de forma dinámica.

### 3. SessionStart
Evento disparado al inicio de sesión. Caso de uso principal: cargar contexto de sesión anterior (hot cache), verificar estado del entorno, inicializar dependencias.

## Skills folder

La carpeta estandarizada agnóstica de proveedor es `.agents/skills/`. Gemini CLI también lee desde `.gemini/skills/`. Para máxima compatibilidad multi-agente, usar `.agents/skills/`.

## Connections
- Related concepts: [[wiki/concepts/agent-hook-compatibility]], [[wiki/concepts/progressive-disclosure-hooks]]
- Entities: [[wiki/entities/google-antigravity]], [[wiki/entities/antigravity-cli]]

---

- 2026-06-07 [Antigravity]: Page created
- 2026-06-08 [Claude Code]: Actualizado con hallazgos del video oficial de Gemini CLI — scopes y ruta de scripts aclarados; skills folder estandarizado
- 2026-06-08 [Claude Code]: Bug de alineación de rutas documentado (issue #49 de agy-cli) — ruta de lectura vs escritura del CLI difieren; solución: edición manual o symlink
