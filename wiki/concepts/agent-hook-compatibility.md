---
title: agent-hook-compatibility
type: concept
created: 2026-06-07
updated: 2026-06-07
tags: [multi-agent, hooks, cortex-forge, compatibility]
aliases: [hook matrix, agent lifecycle]
sources:
  - wiki/sources/commandcode-hooks-configuration.md
  - wiki/sources/commandcode-hooks-reference.md
  - wiki/sources/commandcode-hooks-examples.md
  - wiki/sources/commandcode-hooks-best-practices.md
confidence: high
---

# Agent Hook Compatibility

Cortex Forge's Hot Cache Protocol requiere dos eventos de lifecycle por agente: uno al **inicio de sesión** (inyectar contexto) y uno al **cierre** (guardar snapshot). No todos los agentes exponen ambos.

## Matriz de compatibilidad

| Agente | SessionStart equiv. | Stop equiv. | Estado hot cache |
|--------|---------------------|-------------|-----------------|
| Claude Code | `SessionStart` | `SessionEnd` + `PreCompact` | ✅ completo — automático vía hooks |
| Antigravity CLI | `PreInvocation (invocationNum==0)` | `Stop (fullyIdle==true)` | documentado, sin probar |
| Codex | `SessionStart` | `Stop` | ✅ completo — automático vía hooks; hook context visible en UI |
| CommandCode | **no existe** | `Stop` | parcial — solo cierre automático |

## Modo degradado por agente

### Claude Code
Configurado vía `cortex-forge-setup`. Los hooks `load-hot-cache.sh` y `update-hot-cache.sh` corren automáticamente. No requiere acción del agente.

**Detalles de SessionStart (doc oficial):**
- El evento tiene un campo `source` con valores `startup`, `resume`, `clear`, `compact` — igual que Codex. Filtrar por `startup` si se quiere limitar el hook al inicio real de sesión.
- `asyncRewake`: campo disponible para hooks que corren en background y necesitan despertar al agente al terminar — útil para operaciones lentas que no deben bloquear el inicio.
- `PreCompact` puede bloquearse con exit 2 — el hook `update-hot-cache.sh` de Cortex Forge ya lo usa para guardar snapshot antes de compactar.

### Antigravity CLI
Antigravity hereda la ruta de Gemini CLI. Config global en `~/.gemini/config/hooks.json`; config de proyecto en `.agents/hooks.json`.

**⚠ Bug conocido (agy-cli issue #49)**: si usas comandos del CLI para configurar hooks, escribe en `~/.gemini/antigravity-cli/hooks.json` (incorrecto) en lugar de `~/.gemini/config/hooks.json` (correcto). **Crear el archivo manualmente** o usar symlink:
```bash
ln -s ~/.gemini/config/hooks.json ~/.gemini/antigravity-cli/hooks.json
```

Configurar en `~/.gemini/config/hooks.json`:
```json
{
  "PreInvocation": [{ "condition": "invocationNum == 0", "command": "bash ~/.gemini/config/hooks/load-hot-cache-antigravity.sh" }],
  "Stop":          [{ "condition": "fullyIdle == true",  "command": "bash ~/.gemini/config/hooks/update-hot-cache-antigravity.sh" }]
}
```

Los scripts deben vivir en `~/.gemini/config/hooks/`, no en `~/.claude/hooks/`.

### Codex
Configurar en `~/.codex/hooks.json`:
```json
{
  "SessionStart": [{ "command": "bash {vault}/bin/hooks/load-hot-cache.sh" }],
  "Stop":         [{ "command": "bash {vault}/bin/hooks/update-hot-cache.sh" }]
}
```

**Hallazgos validados en sesión (2026-06-08):**
- Wire format idéntico al de Claude Code — el script `load-hot-cache.sh` es compatible sin modificaciones.
- `SessionStart` puede dispararse más de una vez por sesión: tiene un campo `source` con valores `startup`, `resume`, `clear`. Filtrar por `source` en el matcher si se quiere limitar a inicio real.
- El `hook context:` es visible en el chat por diseño de la UI de Codex. No hay mecanismo para suprimirlo hoy (`suppressOutput` está reservado para uso futuro). El contexto llega correctamente al modelo — el ruido es solo visual.
- **Costo de contexto**: `additionalContext` consume tokens del context window de la sesión como cualquier mensaje. Para un hot cache de pocos KB es negligible con ventanas de 200k+ tokens, pero es un costo real compartido con Claude Code y toda implementación de Capa 2.
- Primera ejecución requiere aprobación manual de los hooks (`Trust: New hook - review required`).

### CommandCode
No tiene hook de SessionStart. El contexto se inyecta por `AGENTS.md`: la regla global de leer `.hot/{proyecto}.md` al iniciar es cumplida por el agente si lee el archivo de instrucciones. El cierre es automático vía hook `Stop`.

Configurar bajo la clave `hooks` en `settings.json`:
- **User scope**: `~/.commandcode/settings.json` (no commiteado; aplica a todos los proyectos del usuario)
- **Project scope**: `.commandcode/settings.json` (commiteado al repo; aplica a quien clone)
- **Precedencia**: project > user

Ejemplo (project scope) para el hot cache:
```json
{
  "hooks": {
    "Stop": [{ "command": "bash {vault}/bin/hooks/update-hot-cache.sh" }]
  }
}
```

**Orden de ejecución y短路** (de la doc oficial de Configuration):
- `PreToolUse` corre **secuencialmente**; si un handler bloquea (exit code != 0), los siguientes `PreToolUse` se saltan.
- `PostToolUse` corre en **paralelo** (la tool ya terminó).
- Múltiples handlers bajo un mismo matcher corren en el orden listado.
- Wire format: array anidado `hooks: [{ matcher, hooks: [{ type: "command", command, timeout? }] }]`, distinto del formato plano de Codex/Claude Code.

**⚠ Plan mode**: CommandCode deshabilita los hooks completamente en plan mode — el hook `Stop` no corre al cerrar una sesión de planificación. Tener esto en cuenta al operar el crystallize protocol.

**Implicación**: en CommandCode el hot cache es de solo salida en la primera sesión. A partir de la segunda sesión, el contexto previo ya está en `.hot/` y `AGENTS.md` instruye al agente a leerlo — el ciclo se cierra vía instrucción, no vía hook.

### Wire format I/O de CommandCode

Los hooks reciben JSON en `stdin` con session context, tool details y environment info. Devuelven JSON en `stdout` con campos opcionales:

| Campo | Evento | Efecto |
|-------|--------|--------|
| `permissionDecision: "deny"` | PreToolUse | Bloquea la tool; el modelo recibe el mensaje |
| `permissionDecision: "allow"` | PreToolUse | Permite explícitamente; útil junto con `additionalContext` |
| `decision: "block"` | PostToolUse | Advisory retry (tool ya ejecutó) |
| `systemMessage` | cualquiera | Mensaje de política inyectado al contexto del modelo |
| `additionalContext` | cualquiera | Contexto no bloqueante para el modelo |
| `continue` | Stop | Controla si la sesión continúa |

Exit codes: `0` → ejecutar JSON output; `2` → bloquear/reintentar según evento; otros → error no bloqueante (tool procede).

### Seguridad y performance (best practices)

- **Nunca `eval`**: parsear stdin con `jq -r`. Los inputs vienen del modelo y son no confiables.
- **Siempre quoting**: `grep -qE` sobre `printf` con quoting, no variables sueltas en shell.
- **Timeout**: PreToolUse < 10s para no lagear la UI. Operaciones lentas → PostToolUse o background.
- **Debugging**: flag `--debug` genera logs con matcher results y payload. Se puede iterar con mock payloads locales sin levantar CommandCode.
- **Plan mode**: hooks están deshabilitados en plan mode — no asumir que corren siempre.
- **`chmod +x`**: todos los scripts deben ser ejecutables.

> Fuentes: `wiki/sources/commandcode-hooks-configuration`, `commandcode-hooks-reference`, `commandcode-hooks-examples`, `commandcode-hooks-best-practices` (2026-06-08). Ver [[wiki/entities/commandcode]] para el perfil completo del agente.

## Patrones de uso comunes (aplicables a todos los agentes)

Patrones extraídos de los ejemplos oficiales de CommandCode; el mecanismo de output varía por agente pero la lógica es portable:

| Patrón | Evento | Mecanismo | Caso típico |
|--------|--------|-----------|-------------|
| **Enforcement de seguridad** | PreToolUse | `permissionDecision: "deny"` + `systemMessage` | Bloquear `rm -rf /`, `curl \| sh` |
| **Context injection condicional** | PreToolUse | `permissionDecision: "allow"` + `additionalContext` | Advertir sobre archivos `.env`, `.pem` sin bloquear |
| **Observabilidad pura** | Pre o PostToolUse | exit `0`, escribe a log local | Auditoría de tool calls con timestamp y session ID |
| **Completion gate** | Stop | exit `2` + `systemMessage` | Bloquear cierre si hay marcadores `DO NOT SHIP`; hasta 3 reintentos |

## Regla de fallback universal

Si un agente no tiene hook de inicio, `AGENTS.md` actúa como fallback: la instrucción explícita de leer `.hot/{proyecto}.md` es interpretada por cualquier agente que procese el archivo de instrucciones antes de operar. Es menos confiable que un hook (depende de que el agente respete AGENTS.md), pero cubre el gap.

---

- 2026-06-07 [claude-sonnet-4-6]: Página creada — matriz inicial basada en documentación oficial de cada agente; CommandCode verificado contra commandcode.ai/docs/hooks/reference
- 2026-06-08 [claude-sonnet-4-6]: Codex actualizado con hallazgos de sesión real — wire format confirmado, comportamiento de SessionStart multi-source, visibilidad de hook context, costo de contexto
- 2026-06-08 [claude-sonnet-4-6]: Antigravity corregido — config global es `~/.gemini/config/hooks.json`; bug de alineación de rutas documentado (agy-cli issue #49)
- 2026-06-08 [CommandCode / MiniMax-M3]: Ampliada con scopes (user/project), precedencia, orden PreToolUse (secuencial, cortocircuito) vs PostToolUse (paralelo), wire format anidado. Fuente: wiki/sources/commandcode-hooks-configuration
- 2026-06-08 [claude-sonnet-4-6]: Agregado I/O schema completo de CommandCode (campos de control, exit codes), sección de seguridad/performance (best practices), y tabla de patrones de uso comunes portable entre agentes. Fuentes: commandcode-hooks-reference, commandcode-hooks-examples, commandcode-hooks-best-practices
- 2026-06-08 [claude-sonnet-4-6]: Claude Code SessionStart — campo `source` documentado (startup|resume|clear|compact), `asyncRewake` agregado, `PreCompact` con exit 2 confirmado. CommandCode — gotcha de plan mode documentado. Fuente: handoff desde second-brain
