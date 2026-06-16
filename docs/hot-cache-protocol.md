# Hot Cache Protocol (obsoleto — ver referencia actualizada)

Este archivo está desactualizado. La referencia completa de la arquitectura de workflow,
hooks por agente, scripts, skills y modos degradados está en:

→ **`wiki/reference/workflow-architecture.md`**

Lo que cubre el nuevo doc y esto no:

- Las 3 fases de una sesión (Start / During / End) con su mecanismo por agente
- Tabla de skills completa (cuándo invocar cada una)
- Scripts de hooks por agente (7 scripts en `bin/hooks/`)
- Disparadores adicionales (compact, clear, resume, fullyIdle)
- Modos degradados por plataforma (qué hacer cuando faltan hooks)
- Config files por agente con paths exactos

Los nombres de scripts `load-hot-cache.sh` y `update-hot-cache.sh` fueron reemplazados
por scripts específicos por agente (`cortex-reactivat-*.sh`, `cortex-crystallize-*.sh`).

