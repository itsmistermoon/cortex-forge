---
title: CommandCode
type: entity
created: 2026-06-08
updated: 2026-06-08
tags: [commandcode, agente, cli, coding-agent]
sources:
  - wiki/sources/commandcode-taste-blog.md
  - wiki/sources/commandcode-taste-docs.md
  - wiki/sources/commandcode-hooks-configuration.md
  - wiki/sources/commandcode-hooks-reference.md
confidence: high
---

# CommandCode

Agente de código AI con CLI que integra personalización continua mediante TASTE. Comparte el espacio de agentes coding-first con Claude Code, Codex y Antigravity CLI.

## Identity

- **CLI**: `cmd` (alias `npx commandcode`)
- **Config project**: `.commandcode/settings.local.json`
- **Config global**: `~/.commandcode/`
- **Studio**: `commandcode.ai` — sincronización de perfiles TASTE y skills remotas
- **Auth**: cuenta commandcode.ai

## Capacidades clave

- **TASTE** — sistema de personalización continua: aprende preferencias de estilo implícitamente (aceptar/rechazar/editar) y las persiste en `taste.md`. Modelo subyacente: `taste-1`. Ver [[wiki/concepts/commandcode-taste]].
- **Skills** — markdown files en `.commandcode/skills/` o `~/.commandcode/skills/`
- **Rules** — directivas manuales del usuario (capa sobre TASTE y skills)
- **Hooks** — Stop, SessionStart. Wire format: `{ hooks: [{ matcher, hooks: [{ type, command }] }] }`. Ver [[wiki/sources/commandcode-hooks-configuration]].
- **Plan mode** — omite hooks cuando está activo (`stop_hook_active` como anti-bucle)

## Three-layer stack

| Capa | Fuente | Actualización |
|---|---|---|
| TASTE | Auto-aprendido | Cada sesión, automático |
| Skills | Escrito por el usuario | Manual |
| Rules | Escrito por el usuario | Manual |

## Relevancia para cortex-forge

- La skill `cortex-forge-setup` instala una TASTE rule para invocar `/cortex-recall` automáticamente.
- El hook Stop de CommandCode tiene restricciones de scope: debe ir en `{vault}/.commandcode/settings.local.json`, no en `cortex-forge/.commandcode/`. Ver [[wiki/concepts/agent-hook-compatibility]].

---

- 2026-06-08 [Claude Code]: Entidad creada desde fuentes CommandCode TASTE + hooks
