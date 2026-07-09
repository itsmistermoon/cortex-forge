---
"cortex-forge": minor
---

Integra tag-governance en 3 skills del suite, cerrando el pendiente más viejo de MEMORY.md:

- **cortex-assimilate** paso 3: antes de escribir  en una página nueva, chequear `{vault}/wiki/meta/tags.md` (el registro de tags del vault). Si no existe, skip; si existe, validar cada tag propuesto contra las reglas del header y los nombres registrados, o registrarlo como candidato post-run.
- **cortex-prune** Layer 1: nueva fila LOW — tag usado exactamente una vez en el vault sin página entity/concept que lo respalde. Sugerir merge con un tag registrado o remoción.
- **cortex-forge-setup** maintenance menu: nueva opción 10 — corre `bin/tags-audit.py {vault-path}` e imprime el reporte. Único punto de acceso al script, que sigue sin estar wireado en ninguna skill.

Sigue el principle de los 3 cambios: ninguno introduce auto-mutación; todos surfacean findings que requieren decisión humana. La infra previa (`templates/tags.md`, `bin/tags-audit.py`) ya estaba lista desde PR #10/#12.
