---
title: CommandCode TASTE
type: concept
created: 2026-06-08
updated: 2026-06-08
tags: [commandcode, taste, personalization, learning, per-project, global]
aliases: [TASTE, taste commandcode]
sources:
  - wiki/sources/commandcode-taste-blog.md
  - wiki/sources/commandcode-taste-docs.md
  - wiki/sources/commandcode-taste-manage.md
  - wiki/sources/commandcode-taste-commands.md
confidence: high
---

# CommandCode TASTE

TASTE es el sistema de personalización continua de [[wiki/entities/commandcode]] (ver [[wiki/concepts/agent-hook-compatibility]] para contexto del agente). Aprende de las acciones del usuario —aceptaciones, rechazos, ediciones— y genera archivos `taste.md` que condicionan la generación de código en futuras sesiones. No requiere configuración manual inicial; el sistema los crea y mantiene solo.

## Alcance: per-project y global

TASTE tiene **dos ámbitos con paths concretos**:

| Ámbito      | Path                        | Flag CLI       |
|-------------|-----------------------------|----------------|
| Per-project | `.commandcode/taste/`       | (por defecto)  |
| Global      | `~/.commandcode/taste/`     | `-g`           |
| Remoto      | `commandcode.ai/username/taste` | (Studio)   |

El ámbito per-project es el primario. Los archivos pueden dividirse automáticamente por dominio (APIs, componentes frontend, backend) a medida que el proyecto crece. El ámbito global permite llevar preferencias aprendidas a cualquier proyecto sin reaprender desde cero.

## Formato de archivos

Los archivos `taste.md` son legibles e inspeccionables. Cada entrada incluye un score de confianza (0.0–1.0) basado en consistencia observada:

```
## TypeScript
- Use strict mode. Confidence: 0.80
- Prefer explicit return types on exported functions. Confidence: 0.65
```

Las puntuaciones altas indican patrones establecidos; las bajas, preferencias aún en formación.

## Bucle de aprendizaje

```
generar → observar (aceptar/rechazar/editar) → extraer → aprender → aplicar
```

La retroalimentación es **implícita**: no requiere anotación explícita. El modelo subyacente es `taste-1`, arquitectura neuro-simbólica que separa el conocimiento del LLM (neural) de las preferencias del usuario (simbólico).

Fórmula conceptual: `output = LLM(prompt | taste(user))`

## Gestión: comandos CLI

```bash
# Ámbito per-project
npx taste push --all              # sube toda la carpeta .commandcode/taste/ al Studio
npx taste pull username/proyecto  # trae un perfil desde Studio al proyecto local

# Ámbito global
npx taste push [paquete] -g       # sube al ámbito global
npx taste pull [paquete] -g       # baja al ámbito global

# Otros
npx taste list                    # lista perfiles disponibles en Studio
npx taste lint                    # valida formato del paquete
npx taste open                    # abre paquetes en el editor
```

`npx taste` y `cmd taste` son equivalentes.

## Three-layer stack

| Capa       | Fuente              | Actualización     | Resultado  |
|------------|---------------------|-------------------|------------|
| **TASTE**  | Auto-aprendido      | Cada sesión, auto | Personal   |
| **Skills** | Autor del usuario   | Manual            | Universal  |
| **Rules**  | Usuario escribe     | Manual            | Universal  |

"Skills aumentan capacidad. Taste aumenta alineación."

## Relevancia para cortex-forge

El pendiente [[wiki/pages/cortex-forge]] sobre scope de TASTE rule para `cortex-recall` queda resuelto por esta ingesta:

- **La decisión es contextual**: si la rule es específica del vault → `.commandcode/taste/` (per-project); si debe aplicar en cualquier proyecto donde se use `cortex-recall` → `~/.commandcode/taste/` (global con `-g`).
- `cortex-forge-setup` puede poblar ambas ubicaciones; la pregunta es cuál ofrece como default al usuario.

---

- 2026-06-08 [Claude Code]: Page created desde 4 fuentes CommandCode oficiales
