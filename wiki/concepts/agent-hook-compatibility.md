---
title: agent-hook-compatibility
type: concept
created: 2026-06-07
updated: 2026-06-07
tags: [multi-agent, hooks, cortex-forge, compatibility]
aliases: [hook matrix, agent lifecycle]
sources: []
confidence: high
---

# Agent Hook Compatibility

Cortex Forge's Hot Cache Protocol requiere dos eventos de lifecycle por agente: uno al **inicio de sesión** (inyectar contexto) y uno al **cierre** (guardar snapshot). No todos los agentes exponen ambos.

## Matriz de compatibilidad

| Agente | SessionStart equiv. | Stop equiv. | Estado hot cache |
|--------|---------------------|-------------|-----------------|
| Claude Code | `SessionStart` | `SessionEnd` + `PreCompact` | ✅ completo — automático vía hooks |
| Antigravity CLI | `PreInvocation (invocationNum==0)` | `Stop (fullyIdle==true)` | documentado, sin probar |
| Codex | `SessionStart` | `Stop` | documentado, sin probar |
| CommandCode | **no existe** | `Stop` | parcial — solo cierre automático |

## Modo degradado por agente

### Claude Code
Configurado vía `cortex-forge-setup`. Los hooks `load-hot-cache.sh` y `update-hot-cache.sh` corren automáticamente. No requiere acción del agente.

### Antigravity CLI
Configurar en `~/.agents/hooks.json`:
```json
{
  "PreInvocation": [{ "condition": "invocationNum == 0", "command": "bash {vault}/bin/hooks/load-hot-cache.sh" }],
  "Stop":          [{ "condition": "fullyIdle == true",  "command": "bash {vault}/bin/hooks/update-hot-cache.sh" }]
}
```

### Codex
Configurar en `~/.codex/hooks.json`:
```json
{
  "SessionStart": [{ "command": "bash {vault}/bin/hooks/load-hot-cache.sh" }],
  "Stop":         [{ "command": "bash {vault}/bin/hooks/update-hot-cache.sh" }]
}
```

### CommandCode
No tiene hook de SessionStart. El contexto se inyecta por `AGENTS.md`: la regla global de leer `.hot/{proyecto}.md` al iniciar es cumplida por el agente si lee el archivo de instrucciones. El cierre es automático vía hook `Stop`.

Configurar en el archivo de hooks de CommandCode:
```json
{
  "Stop": [{ "command": "bash {vault}/bin/hooks/update-hot-cache.sh" }]
}
```

**Implicación**: en CommandCode el hot cache es de solo salida en la primera sesión. A partir de la segunda sesión, el contexto previo ya está en `.hot/` y `AGENTS.md` instruye al agente a leerlo — el ciclo se cierra vía instrucción, no vía hook.

## Regla de fallback universal

Si un agente no tiene hook de inicio, `AGENTS.md` actúa como fallback: la instrucción explícita de leer `.hot/{proyecto}.md` es interpretada por cualquier agente que procese el archivo de instrucciones antes de operar. Es menos confiable que un hook (depende de que el agente respete AGENTS.md), pero cubre el gap.

---

- 2026-06-07 [claude-sonnet-4-6]: Página creada — matriz inicial basada en documentación oficial de cada agente; CommandCode verificado contra commandcode.ai/docs/hooks/reference
