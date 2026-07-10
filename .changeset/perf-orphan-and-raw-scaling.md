---
"cortex-forge": patch
---

`cortex-prune` ahora termina en tiempo razonable (~17s en vez de >10 min) sobre vaults de cientos de páginas. Los checks de "orphan pages" y "unprocessed .raw/ files" eran O(n × m) — para cada página/archivo corría 1-3 greps recursivos sobre el wiki entero. moon-multivac (143 .raw/ files, 353 wiki pages) exponía el problema: el script nunca terminaba. Ambos checks ahora extraen todos sus índices en un solo pass (O(m)) y luego consultan O(1) por elemento (O(n) total), escalando a vaults grandes sin cambios adicionales.

También corrige un bug pre-existente en el check de index.md section/type: el parser solo reseteaba `current` ante headings reconocidos en `section_to_type`, así que un heading no reconocido entre dos secciones válidas (e.g. `## Meta` entre `## Fuentes` y `## Conceptos`) dejaba los wikilinks siguientes atribuidos a la sección anterior, generando falsos positivos.
