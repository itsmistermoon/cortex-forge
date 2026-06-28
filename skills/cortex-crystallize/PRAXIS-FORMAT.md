# PRAXIS — formato de referencia

PRAXIS.md vive en `.cortex/PRAXIS.md` y tiene dos zonas con ciclos de vida distintos.

## Cuándo escribir

El agente decide cuándo algo merece ir a PRAXIS. No es un log automático — es una decisión deliberada.

- **`## Permanent`** → convenciones estructurales, invariantes de arquitectura, workarounds técnicos confirmados. Sin TTL. Escribe aquí si el próximo agente, en 6 meses, necesita saber esto para no romper nada.
- **`## Working context`** → contexto activo con fecha. Se poda automáticamente en `/cortex-crystallize` cuando supera 30 días.

## Formato

```markdown
---
schema_version: "0.1"
updated: YYYY-MM-DD
---

# PRAXIS — {vault-name}

## Permanent

- **{convención}** — {descripción concisa de por qué existe y qué rompe si se viola}
- **{workaround}** — {comportamiento inesperado, causa, fix aplicado, fecha confirmado: YYYY-MM-DD}

## Working context

### YYYY-MM-DD
- {entrada de contexto activo — se elimina cuando supera 30 días}
```

## Reglas

- `## Permanent`: no tiene TTL, pero sí puede eliminarse si la convención dejó de aplicar. Quien borra, explica.
- `## Working context`: cada bloque bajo `### YYYY-MM-DD` se elimina en `/cortex-crystallize` cuando `today - date > 30 days`. El agente no pregunta — poda automáticamente.
- Ninguna sección es un log de sesión — para eso existe `MEMORY.md`. PRAXIS captura el aprendizaje que trasciende la sesión.
