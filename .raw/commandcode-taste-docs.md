# TASTE — Documentación oficial CommandCode

**URL:** https://commandcode.ai/docs/taste
**Ingestado:** 2026-06-08

## Qué es TASTE

Sistema de IA personalizada impulsado por el modelo `taste-1`, descrito como "meta neuro-simbólico con aprendizaje de refuerzo continuo". El sistema "aprende de ti — cada aceptación, rechazo y edición se convierte en una señal" para construir un perfil personalizado de preferencias de codificación.

## Almacenamiento y alcance

La doc no especifica paths exactos de almacenamiento. Sin embargo indica:
- **Portabilidad**: Las preferencias aprendidas "no están bloqueadas en un proyecto único. Pueden usarse en todos tus proyectos"
- **Sincronización**: Funciona similar a Git, siendo "transferible y composable"

## Gestión

Comando `npx taste` para:
- Empujar perfiles: `npx taste push --all`
- Tirar perfiles: `npx taste pull username/project-name`

## Funcionamiento

- Observa patrones de escritura y revisión de código
- Desarrolla comprensión intuitiva de estándares de calidad
- Promete "10x más rápido en codificación, 2x más rápido en revisiones, 5x menos bugs"

Se integra como parte del flujo de trabajo de Command Code CLI, aprendiendo continuamente de decisiones de desarrollo para optimizar sugerencias futuras.
