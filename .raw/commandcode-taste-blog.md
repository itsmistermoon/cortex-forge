# TASTE: Skills, Rules y Aprendizaje Continuo — Blog CommandCode

**URL:** https://commandcode.ai/blog/taste-skills-rules
**Ingestado:** 2026-06-08

## Qué es TASTE

TASTE es la capa superior de un sistema de tres niveles que guía la generación de código IA. A diferencia de Rules (reglas estáticas) y Skills (flujos de trabajo reutilizables), TASTE se describe como "continuamente aprendido de tu comportamiento" y "auto-gestionado", componiéndose con el tiempo de manera personal.

## Cómo funciona

El sistema opera mediante un bucle continuo:
1. Generar: Código condicionado por el TASTE actual
2. Observar: Aceptar, rechazar o editar el resultado
3. Extraer: Identificar nuevas restricciones
4. Aprender: Actualizar archivos de TASTE
5. Aplicar: Mejorar la siguiente generación

Fórmula conceptual: `output = LLM(prompt | taste(user))`

## Tecnología subyacente

Usa `taste-1`, modelo de IA meta neuro-simbólico que combina capacidades generativas de LLMs con un sistema de restricciones simbólicas. Separa el conocimiento del modelo (neural) del aprendizaje sobre el usuario (simbólico).

## Almacenamiento

Archivos legibles en formato `taste.md` dentro del directorio del proyecto. Ejemplo de contenido:

```
## TypeScript
- Use strict mode. Confidence: 0.80
- Prefer explicit return types on exported functions. Confidence: 0.65
```

## Alcance: Global vs Per-Project

Diseñado como per-project, generando múltiples "paquetes de taste" según crece el proyecto (APIs, componentes frontend, backend). Se divide automáticamente.

## Gestión: Auto-gestionada

- Crea y mantiene sus propios archivos
- Se actualiza automáticamente cada sesión
- No requiere intervención del desarrollador inicial
- El usuario puede inspeccionar, editar o resetear los archivos

## Three-Layer Stack

| Capa   | Fuente              | Presencia              | Actualización           | Resultado  |
|--------|---------------------|------------------------|-------------------------|------------|
| TASTE  | Aprendido auto      | Siempre activo         | Cada sesión, auto       | Personal   |
| Skills | Autor del usuario   | Activado cuando necesario | Manual               | Universal  |
| Rules  | Usuario escribe     | Siempre presente       | Manual                  | Universal  |

"Skills aumentan capacidad. Taste aumenta alineación. Un skill sin taste es código de alguien más generado más rápido. Un skill con taste es tuyo."

## Composición y compartición

```bash
npx taste push --all          # Publicar taste del proyecto
npx taste pull ahmadawais/cli # Adoptar taste de otro
```

## Resultados medidos (un mes de aprendizaje)

- CLI scaffolding: 4.2 → 0.4 ediciones
- Endpoint API: 3.1 → 0.3 ediciones
- Componente React: 3.8 → 0.5 ediciones
- Archivo de prueba: 2.9 → 0.2 ediciones

"10x más rápido escribir código. 2x más rápido revisar código. 5x menos bugs."

## Diferenciadores

- Confianza observada, no configurada: cada regla incluye score de confianza
- Retroalimentación implícita: accepts, rechazos y ediciones entrenan el sistema sin anotación explícita
