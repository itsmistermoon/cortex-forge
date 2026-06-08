# TASTE: Gestión — Documentación CommandCode

**URL:** https://commandcode.ai/docs/taste/manage
**Ingestado:** 2026-06-08

## Comandos principales

1. **Push**: `npx taste push --all` — Envía el taste al Command Code Studio para compartirlo con el equipo
2. **Pull**: `npx taste pull` — Recupera perfiles de taste del Studio hacia proyectos locales
3. **List**: `npx taste list` — Enumera todos los perfiles de taste disponibles en Command Code Studio
4. **Open**: `npx taste open <package>` — Abre un perfil específico en el Studio

## Observaciones

El documento no especifica:
- Distinción entre configuración global vs. per-project
- Procedimientos para crear, editar o eliminar rules individuales
- Paths exactos de almacenamiento de archivos
- Sintaxis detallada de configuración

El enfoque es Git-like: push/pull hacia repositorio centralizado (Studio).

## Referencias adicionales

- `/docs/taste/commands` — Referencia de comandos taste con documentación detallada
- `/docs/taste/overview` — Información conceptual general
