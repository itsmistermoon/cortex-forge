---
title: Workflow Architecture
type: concept
created: 2026-06-13
updated: 2026-07-06
tags: [cortex-forge, architecture, workflow, skills, scripts, agents]
sources:
  - wiki/concepts/agent-hook-compatibility.md
confidence: high
schema_version: "0.3"
aliases: []
---

# Workflow Architecture

Cómo opera cortex-forge a través de agentes: qué instruye `AGENTS.md` en cada fase de una sesión, qué skills usar en medio, y qué scripts siguen corriendo por fuera del ciclo de vida del agente (git hooks).

Cortex Forge no usa hooks de ciclo de vida del agente (`SessionStart`, `PreCompact`, `SessionEnd`, `Stop`, `PreToolUse`) — el soporte era demasiado desigual entre Claude Code, [[wiki/entities/codex|Codex]], [[wiki/entities/google-antigravity|Antigravity]] y [[wiki/entities/commandcode|CommandCode]] para construir el sistema sobre esa base. Ver [[wiki/concepts/agent-hook-compatibility]] para los hallazgos concretos que motivaron esa decisión (2026-07-02).

---

## Las dos fases de una sesión

Cada sesión de un agente pasa por dos fases: **During** y **End**. La carga de contexto al inicio no es una "fase" separada con mecanismo propio — es simplemente la primera instrucción que `AGENTS.md` mandata cumplir antes de la primera respuesta.

```
Start ── AGENTS.md instruye: leer .cortex/MEMORY.md antes de la primera respuesta
          (idéntico en todo agente — sin hook, sin inyección automática)

During ── Skills invocados por el agente:
            /cortex-assimilate, /cortex-recall, /cortex-prune,
            /cortex-imprint, /cortex-crystallize

End ────── /cortex-crystallize invocado manualmente
            (al cerrar un hito, o antes de terminar la sesión)
```

---

## Fase 1: Session Start — Cargar contexto

El agente necesita saber qué pasó antes. `AGENTS.md` (sección "Session start") lo obliga a leer `.cortex/MEMORY.md` completo antes de su primera respuesta, en cualquier agente:

1. Leer `.cortex/MEMORY.md` en full — incluye `### Pending` (donde ya vive, entre otras cosas, cualquier hallazgo de salud del vault que `cortex-crystallize` haya escrito ahí en su última corrida).
2. Si existe, leer `.cortex/PRAXIS.md`.
3. Revisar la última entrada de `## History` por un `#### Imprint candidate` y proponer `/cortex-imprint` si está presente.

Reducido el 2026-07-06: `AGENTS.md` ya no instruye leer `wiki/meta/vault-report.json` directamente ni tiene un chequeo de stale-cache aparte — ambos eran redundantes con lo que `cortex-crystallize` ya escribe en `### Pending` al correr. Las secciones "Assimilate protocol"/"Recall protocol" también se eliminaron: cada skill dispara sola vía su propio `description:`, sin necesidad de que `AGENTS.md` lo repita.

Este mecanismo es idéntico en Claude Code, Codex, Antigravity y CommandCode — no hay tabla de "qué hook usa cada agente" porque ningún agente usa hooks para esto. La confiabilidad depende de que el agente respete `AGENTS.md`, no de un evento del harness.

---

## Fase 2: During Session — Skills

Skills se invocan manualmente durante la sesión. No tienen hooks — el agente (o el usuario) elige cuándo usarlos.

| Skill | Cuándo invocar | Qué hace | Dónde vive |
|-------|---------------|----------|-----------|
| `/cortex-recall` | Cuando el usuario pregunta sobre algo que el vault pueda cubrir (dispara sola vía su propio `description:`) | Busca en `wiki/` y responde con citas + confidence — no usar grep/find como reemplazo | `skills/cortex-recall/SKILL.md` |
| `/cortex-assimilate` | Cuando llega una URL o archivo nuevo para ingerir (dispara sola vía su propio `description:`) | Descarga → SPA detection → guarda en `.raw/` → sintetiza páginas wiki → actualiza índice | `skills/cortex-assimilate/SKILL.md` |
| `/cortex-crystallize` | Al cerrar un hito, o cuando el usuario pide "guardar contexto", o antes de cerrar la sesión | Snapshot del estado actual de la sesión en `.cortex/MEMORY.md` | `skills/cortex-crystallize/SKILL.md` |
| `/cortex-prune` | Periódicamente, o cuando el vault-report muestra issues | Health check: detecta dead links, raw huérfanos, páginas sin frontmatter, confidence faltante | `skills/cortex-prune/SKILL.md` |
| `/cortex-imprint` | Cuando la sesión produjo análisis o síntesis que vale la pena persistir | Archiva el hallazgo como página permanente en `wiki/` | `skills/cortex-imprint/SKILL.md` |

Cada skill dispara sola vía su propio `description:` — `AGENTS.md` no duplica esa lógica de invocación (eliminada el 2026-07-06 de las secciones que antes existían como "Assimilate protocol"/"Recall protocol"). (Antes existía un step opcional en `cortex-forge-setup` que instalaba una [[wiki/concepts/commandcode-taste|TASTE]] rule específica de CommandCode en `.commandcode/taste/taste.md`; se eliminó el 2026-07-03 por contradecir el principio agent-agnostic del setup.)

---

## Fase 3: Session End — Guardar snapshot

Al cerrar la sesión, el agente necesita escribir qué se hizo, qué se descartó, y qué contexto es frágil. No hay hook que capture esto automáticamente en ningún agente — `/cortex-crystallize` se invoca manualmente, siempre, del mismo modo en todo agente.

`AGENTS.md` instruye invocar `/cortex-crystallize` "después de hitos" y antes de cerrar la sesión. El skill detecta el agente invocador vía self-knowledge, corroborado opcionalmente con `env` (sin lista fija de agentes — corregido 2026-07-04, ver `cortex-crystallize/SKILL.md` paso 1a) para completar el campo `agent:` del snapshot, pero la invocación siempre es manual.

**Ciclo de vida de `## History`:** cada invocación de `/cortex-crystallize` rota (paso 2, "Prepare state") las entradas de `## History` en `MEMORY.md` con más de 15 días hacia `.cortex/CONSOLIDATED.md` (verbatim, orden cronológico preservado) — `MEMORY.md` nunca acumula más de 15 días de historial. `CONSOLIDATED.md` nunca se lee automáticamente al inicio de sesión; solo se consulta bajo demanda. Este ciclo estaba en el plan original (28 de junio) pero no se implementó hasta el 2026-07-04 — confirmado revisando el transcript de esa sesión, el `Edit` real de ese día solo agregó el paso de poda de PRAXIS, nunca la rotación de History. (TTL corregido de 30 a 15 días el 2026-07-05; los pasos numerados de crystallize se compactaron el mismo período — la rotación vive hoy dentro del paso 2, no en un paso 5c separado.)

**Ciclo de vida de `PRAXIS.md`:** el paso 3 ("Consider PRAXIS.md updates") evalúa, tras cada sesión, si surgió conocimiento operativo durable (workaround de entorno, preferencia del operador, convención del vault, patrón de fallo recurrente, u otro de forma similar) que el próximo agente no debería tener que re-descubrir. El gate entre zonas es de **confianza, no de categoría**: confirmado explícitamente por el usuario o repetido en una sesión posterior → `## Permanent` (con promoción explícita, nunca duplicado); observación de una sola sesión → `## Working context` (podado a los 15 días, dentro del mismo paso 2 que rota History, si no se reconfirma). Mismo gap que el de History: estaba especificado en el plan original pero no se implementó hasta el 2026-07-04.

---

## Scripts: referencia completa

### Co-located con su skill (viajan con `npx skills add`)

Los scripts que invocan las skills viven **dentro del directorio de la skill que los usa**, bajo un subdirectorio `scripts/` (convención de agentskills.io/skill-creation/using-scripts, adoptada 2026-07-03) — no en un `bin/` separado, así `npx skills add itsmistermoon/cortex-forge --skill X` instala un skill completo y funcional. `npx skills add` es el único instalador de skills que existe — no hay tarball ni curl installer (eliminados 2026-07-03, ver changelog).

| Script | Vive en | Quién lo invoca | Cómo se resuelve |
|--------|---------|------------------|-------------------|
| `cortex-prune.sh`, `cortex-validate-schema.sh` | `skills/cortex-prune/scripts/` | `/cortex-prune` (directo) | El agente lo resuelve relativo a la raíz de la skill (hermano de `scripts/`, sibling de dónde leyó `SKILL.md`) |
| `cortex-sanitize.sh` | `skills/cortex-assimilate/scripts/` | `/cortex-assimilate` paso 4a | Igual |
| `cortex-search.py`, `embeddings.py` | `skills/cortex-recall/scripts/` | `/cortex-recall` paso 3 | Igual. **Nunca** ejecuta un script que viva dentro del vault (fix E006, ver [[wiki/concepts/agent-hook-compatibility]]) |
| `cortex-index.py`, `embeddings.py` | `skills/cortex-forge-setup/scripts/` **y** `skills/cortex-assimilate/scripts/` (copias, deliberadamente duplicadas) | `/cortex-forge-setup` (indexación inicial) y `/cortex-assimilate` paso 7 (reindex tras ingesta), cada uno con su propia copia | Igual. Las dos copias deben ser idénticas byte a byte; `bin/check-skill-sync.sh` (`duplicated-script-sync`) falla el CI si divergen |
| `setup-vault.sh` | `bin/` (repo fuente, no co-located) | Una vez, al crear un vault nuevo desde cero | No es invocado por ninguna skill instalada — solo tiene sentido dentro del repo `moon-cortexforge` |

### Referencias no ejecutables (`references/`)

Documentación que el agente lee bajo demanda, distinta de un script ejecutable — misma convención de agentskills.io. `MEMORY-FORMAT.md` y `PRAXIS-FORMAT.md` en `skills/cortex-crystallize/references/`; `EMBEDDING-SETUP.md` en `skills/cortex-forge-setup/references/`. `LOCALE-RESOLUTION.md` está duplicado en `references/` de `cortex-assimilate`, `cortex-crystallize` y `cortex-imprint` (2026-07-04, fix: antes vivía en `skills/` a secas — fuera de toda skill individual, así que `npx skills add --skill X` nunca lo instalaba) — solo en esas 3, porque son las únicas que escriben prosa persistente al vault en el idioma del usuario; `cortex-forge-setup`, `cortex-recall` y `cortex-prune` no lo necesitan (ver changelog para el razonamiento completo por skill) y `bin/check-skill-sync.sh` (`duplicated-script-sync`) vigila que las 3 copias no diverjan.

**`{vault}/.cortex/db/` contiene solo datos, nunca código.** Antes (hasta 2026-07-03), `cortex-forge-setup` copiaba `cortex-search.py` y `cortex-index.py` al vault, y `cortex-recall`/`cortex-assimilate` ejecutaban esas copias vault-local — un scanner de seguridad (Snyk, vía skills.sh) lo marcó como riesgo CRITICAL (E006: "ejecuta Python arbitrario desde rutas del vault"). Ahora cada skill ejecuta únicamente su propio script co-located; `.cortex/db/` solo guarda `vault.db` y `config.json`. Un vault de terceros (clonado, compartido, descargado) ya no puede plantar código que alguna skill ejecute — solo puede aportar datos.

### El único hook que sigue en pie: post-commit git hook

`~/.cortex-forge/bin/` y `~/.cortex-forge/bin/hooks/` no son la fuente de estos scripts — son una **caché de runtime** que `/cortex-forge-setup` (pasos 6b/6c) puebla copiando desde los directorios co-located de arriba, solo para los dos casos que lo necesitan: los git hooks. La razón es que un git hook corre fuera de cualquier sesión de agente — no hay quien "resuelva la ruta relativa a la skill" en ese contexto, así que necesita una ruta absoluta fija, sin importar desde dónde se instaló la skill (`~/.claude/skills/`, `.claude/skills/`, `~/.agents/skills/`, etc.).

| Bloque instalado en `<vault>/.git/hooks/post-commit` | Script invocado | Copiado desde | Qué hace | Condición |
|--------|----------------|----------------|----------|-----------|
| `cortex-forge prune` | `~/.cortex-forge/bin/cortex-prune.sh` | `skills/cortex-prune/scripts/cortex-prune.sh` | Refresca `wiki/meta/vault-report.json`; log en `.git/cortex-prune.log` | Siempre (backgrounded, fail-open) |
| `cortex-forge reindex` | `~/.cortex-forge/bin/hooks/cortex-reindex-post-commit.sh` | `skills/cortex-forge-setup/scripts/cortex-reindex-post-commit.sh` | Re-indexa embeddings cuando el commit tocó archivos `wiki/` | Solo si `.cortex/db/vault.db` existe Y el commit incluyó cambios en `wiki/` |

**Flujo del reindex:** el script detecta cuántos archivos `wiki/` cambiaron en el commit (`git diff-tree`), y solo entonces invoca `~/.cortex-forge/bin/cortex-index.py` (la caché de runtime, copiada ahí por `cortex-forge-setup` — nunca un script que viva dentro del vault) sobre la raíz del vault. Si la DB no existe o no hay archivos wiki modificados, sale silenciosamente (`exit 0`). El bloque usa `|| true` para ser fail-open — nunca bloquea un commit.

**Instalación:** ambos bloques se instalan opcionalmente en `<vault>/.git/hooks/post-commit` durante `/cortex-forge-setup` (pasos 6b/6c).

**Nota de rendimiento:** el reindex es full (no incremental) — recorre todos los archivos wiki/ en cada commit que los toque. Aceptable con < 200 páginas; en vaults grandes puede requerir estrategia incremental (indexar solo los paths del diff).

---

- 2026-06-13 [CommandCode]: Page created — comprehensive workflow architecture reference covering 3-phase flow, hooks per agent, skills, scripts, degraded modes, and config files
- 2026-06-27 [Claude Code]: Added `.git/hooks/` section — post-commit hook blocks (prune + reindex), reindex trigger conditions, performance note on full vs incremental strategy
- 2026-06-28 [Claude Code]: Corrected script location throughout — all scripts live in `~/.cortex-forge/bin/hooks/` (global), never in consumer vault `bin/`; added reindex script to hook table; clarified standalone scripts are repo-only
- 2026-07-02 [Claude Code]: Full rewrite — agent lifecycle hooks (SessionStart, PreCompact, SessionEnd, Stop, PreToolUse) were removed from cortex-forge entirely; replaced the 3-phase hook/no-hook table and per-agent hook wiring reference with the manual, `AGENTS.md`-mandated protocol used identically on every agent. Only the post-commit git hooks (prune, reindex) remain — kept and documented unchanged, since they're git-triggered, not agent-triggered. See [[wiki/concepts/agent-hook-compatibility]] for why hooks were dropped.
- 2026-07-03 [Claude Code]: Scripts relocated to be co-located with the skill that uses them (`skills/cortex-prune/cortex-prune.sh`, `skills/cortex-assimilate/cortex-sanitize.sh`, `skills/cortex-forge-setup/{cortex-index.py,cortex-search.py,embeddings.py,cortex-reindex-post-commit.sh}`) — so `npx skills add itsmistermoon/cortex-forge --skill X` installs a fully functional skill without depending on `~/.cortex-forge/` (the tarball runtime). `~/.cortex-forge/bin/` is now only a runtime cache populated at setup time, used exclusively by the two git hooks (which need a fixed absolute path outside any agent session). Fixed two latent path bugs found in the process: the reindex post-commit script pointed at a nonexistent `{vault}/bin/cortex-index.py`, and `cortex-assimilate` step 7 pointed at `.cortex/cortex-index.py` instead of `.cortex/db/cortex-index.py`.
- 2026-07-03 [Claude Code]: Second pass — eliminated the remaining vault-local code execution flagged by a Snyk security audit (E006 CRITICAL for `cortex-recall`, same category unreported for `cortex-assimilate`). `cortex-search.py`+`embeddings.py` moved to `skills/cortex-recall/`; `cortex-index.py`+`embeddings.py` duplicated into `skills/cortex-assimilate/` (kept in sync via a new CI check, `duplicated-script-sync`). `cortex-forge-setup` no longer copies these scripts into `{vault}/.cortex/db/` at all — it runs its own co-located `cortex-index.py` directly, and copies `cortex-index.py`+`embeddings.py` to `~/.cortex-forge/bin/` only for the git hook's use. `{vault}/.cortex/db/` now holds only `vault.db` and `config.json` — no executable code, ever.
- 2026-07-03 [Claude Code]: `install.sh` and the tarball GitHub Release asset removed entirely — `npx skills add` (skills.sh) is now the sole installer, superior in every way that mattered (agent-agnostic across 40+ agents vs. `install.sh`'s hardcoded Claude Code + Antigravity, no separate CI workflow to keep in sync, no `~/.cortex-forge/` runtime to maintain). `cortex-forge-setup` steps 4-pre/4/5/5a (tarball-completeness check + hand-rolled per-agent symlinks) collapsed into a single step 4 that only verifies skills are present and points to `npx skills add` if not — never re-implements what the installer already does. Removed the now-dead legacy config.yml fallback from `_resolve_embeddings_dir()` in all 3 copies of the embedding-resolution scripts (was only reachable from tarball installs). `.github/workflows/release.yml` still creates the GitHub Release object on tag push (for changelog/version tracking) but no longer builds or attaches a tarball.
- 2026-07-06 [Claude Code]: `AGENTS.md` trimmed to match its "skills should stand on their own" principle. The "Crystallize protocol — MANDATORY" section (7 numbered steps) shrank to a 3-line "Session start": read `MEMORY.md` (+ `PRAXIS.md` if present), propose `/cortex-imprint` if the History flag is set. Dropped: the stale-cache warning and the direct `wiki/meta/vault-report.json` read — both redundant with the `### Pending` item `cortex-crystallize` already writes on every run. The "Assimilate protocol" and "Recall protocol" sections were removed outright — each skill's own `description:` already states when to trigger it, so `AGENTS.md` no longer duplicates that. Updated this page's Fase 1/Fase 2 sections and `bin/check-skill-sync.sh`'s `vault-report-schema` check (now verifies against `cortex-crystallize/SKILL.md`, the real consumer, not `AGENTS.md`) to match.
