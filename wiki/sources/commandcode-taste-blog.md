---
title: "TASTE: Skills, Rules y Aprendizaje Continuo — Blog CommandCode"
type: source
created: 2026-06-08
updated: 2026-06-08
tags: [commandcode, taste, learning, personalization]
source_url: https://commandcode.ai/blog/taste-skills-rules
source_date: 2026
source_author: CommandCode
sources: []
confidence: medium
---

# TASTE: Skills, Rules y Aprendizaje Continuo — Blog CommandCode

**URL:** https://commandcode.ai/blog/taste-skills-rules
**Original date:** 2026
**Author:** CommandCode

## Summary

Artículo introductorio que posiciona TASTE dentro del three-layer stack de CommandCode (TASTE > Skills > Rules). Explica el bucle de aprendizaje continuo (generar → observar → extraer → aprender → aplicar), el almacenamiento per-project en archivos `taste.md`, y el modelo subyacente `taste-1`. Presenta resultados empíricos de reducción de ciclos de edición tras un mes de uso.

## Key ideas

1. TASTE es auto-gestionado: crea y mantiene sus propios archivos cada sesión sin intervención del usuario.
2. El alcance primario es per-project; los archivos viven en `.commandcode/taste/` y pueden dividirse automáticamente por dominio (API, frontend, backend).
3. Cada regla aprendida incluye un score de confianza (0.0–1.0) basado en consistencia observada, no configurada manualmente.

## Connections
- Related concepts: [[wiki/concepts/commandcode-taste]]
- Projects: [[wiki/pages/cortex-forge]]

---

- 2026-06-08 [Claude Code]: Page created
