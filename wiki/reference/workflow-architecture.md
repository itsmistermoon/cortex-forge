---
title: Workflow Architecture
type: concept
created: 2026-06-13
updated: 2026-07-02
tags: [cortex-forge, architecture, workflow, skills, scripts, agents]
sources:
  - wiki/concepts/agent-hook-compatibility.md
confidence: high
schema_version: "0.3"
aliases: []
---

# Workflow Architecture

Cómo opera cortex-forge a través de agentes: qué instruye `AGENTS.md` en cada fase de una sesión, qué skills usar en medio, y qué scripts siguen corriendo por fuera del ciclo de vida del agente (git hooks).

Cortex Forge no usa hooks de ciclo de vida del agente (`SessionStart`, `PreCompact`, `SessionEnd`, `Stop`, `PreToolUse`) — el soporte era demasiado desigual entre Claude Code, Codex, Antigravity y CommandCode para construir el sistema sobre esa base. Ver [[wiki/concepts/agent-hook-compatibility]] para los hallazgos concretos que motivaron esa decisión (2026-07-02).

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

El agente necesita saber qué pasó antes. `AGENTS.md` (sección "Crystallize protocol — MANDATORY") lo obliga a leer `.cortex/MEMORY.md` completo antes de su primera respuesta, en cualquier agente:

1. Leer `.cortex/MEMORY.md` en full.
2. Si existe, leer `.cortex/PRAXIS.md`.
3. Si existe, leer `wiki/meta/vault-report.json` y surfacear issues.
4. Si `MEMORY.md` tiene `### Pending` items, reconocerlos.
5. Revisar la última entrada de `## History` por un `#### Imprint candidate` y proponer `/cortex-imprint` si está presente.

Este mecanismo es idéntico en Claude Code, Codex, Antigravity y CommandCode — no hay tabla de "qué hook usa cada agente" porque ningún agente usa hooks para esto. La confiabilidad depende de que el agente respete `AGENTS.md`, no de un evento del harness.

---

## Fase 2: During Session — Skills

Skills se invocan manualmente durante la sesión. No tienen hooks — el agente (o el usuario) elige cuándo usarlos.

| Skill | Cuándo invocar | Qué hace | Dónde vive |
|-------|---------------|----------|-----------|
| `/cortex-recall` | Cuando el usuario pregunta sobre algo que el vault pueda cubrir | Busca en `wiki/` y responde con citas + confidence. **Protocolo obligatorio** — no usar grep/find como reemplazo | `skills/cortex-recall/SKILL.md` |
| `/cortex-assimilate` | Cuando llega una URL o archivo nuevo para ingerir | Descarga → SPA detection → guarda en `.raw/` → sintetiza páginas wiki → actualiza índice. **Protocolo obligatorio** | `skills/cortex-assimilate/SKILL.md` |
| `/cortex-crystallize` | Al cerrar un hito, o cuando el usuario pide "guardar contexto", o antes de cerrar la sesión | Snapshot del estado actual de la sesión en `.cortex/MEMORY.md` | `skills/cortex-crystallize/SKILL.md` |
| `/cortex-prune` | Periódicamente, o cuando el vault-report muestra issues | Health check: detecta dead links, raw huérfanos, páginas sin frontmatter, confidence faltante | `skills/cortex-prune/SKILL.md` |
| `/cortex-imprint` | Cuando la sesión produjo análisis o síntesis que vale la pena persistir | Archiva el hallazgo como página permanente en `wiki/` | `skills/cortex-imprint/SKILL.md` |

**TASTE rules** (CommandCode) en `.commandcode/taste/taste.md` recuerdan al agente qué skills usar y cuándo. En otros agentes, el equivalente es `AGENTS.md`.

---

## Fase 3: Session End — Guardar snapshot

Al cerrar la sesión, el agente necesita escribir qué se hizo, qué se descartó, y qué contexto es frágil. No hay hook que capture esto automáticamente en ningún agente — `/cortex-crystallize` se invoca manualmente, siempre, del mismo modo en todo agente.

`AGENTS.md` instruye invocar `/cortex-crystallize` "después de hitos" y antes de cerrar la sesión. El skill detecta el agente invocador (`env` — `CLAUDECODE=1`, `AI_AGENT`, etc., ver `cortex-crystallize/SKILL.md` paso 1a) para completar el campo `agent:` del snapshot, pero la invocación siempre es manual.

---

## Scripts: referencia completa

### Co-located con su skill (viajan con `npx skills add` o el tarball)

Desde 2026-07-03, los scripts que invocan las skills viven **dentro del directorio de la skill que los usa**, no en un `bin/` separado — así `npx skills add itsmistermoon/cortex-forge --skill X` instala un skill completo y funcional, sin depender de que exista `~/.cortex-forge/` (el runtime del tarball).

| Script | Vive en | Quién lo invoca | Cómo se resuelve |
|--------|---------|------------------|-------------------|
| `cortex-prune.sh`, `cortex-validate-schema.sh` | `skills/cortex-prune/` | `/cortex-prune` (directo) | El agente lo resuelve como hermano de `SKILL.md` — misma carpeta de donde leyó las instrucciones |
| `cortex-sanitize.sh` | `skills/cortex-assimilate/` | `/cortex-assimilate` paso 4a | Igual — hermano de `SKILL.md` |
| `cortex-search.py`, `embeddings.py` | `skills/cortex-recall/` | `/cortex-recall` paso 3 | Igual — hermano de `SKILL.md`. **Nunca** ejecuta un script que viva dentro del vault (fix E006, ver [[wiki/concepts/agent-hook-compatibility]]) |
| `cortex-index.py`, `embeddings.py` | `skills/cortex-forge-setup/` **y** `skills/cortex-assimilate/` (copias, deliberadamente duplicadas) | `/cortex-forge-setup` (indexación inicial) y `/cortex-assimilate` paso 7 (reindex tras ingesta), cada uno con su propia copia | Igual — hermano de `SKILL.md`. Las dos copias deben ser idénticas byte a byte; `bin/check-skill-sync.sh` (`duplicated-script-sync`) falla el CI si divergen |
| `setup-vault.sh` | `bin/` (repo fuente, no co-located) | Una vez, al crear un vault nuevo desde cero | No es invocado por ninguna skill instalada — solo tiene sentido dentro del repo `moon-cortexforge` |

**`{vault}/.cortex/db/` contiene solo datos, nunca código.** Antes (hasta 2026-07-03), `cortex-forge-setup` copiaba `cortex-search.py` y `cortex-index.py` al vault, y `cortex-recall`/`cortex-assimilate` ejecutaban esas copias vault-local — un scanner de seguridad (Snyk, vía skills.sh) lo marcó como riesgo CRITICAL (E006: "ejecuta Python arbitrario desde rutas del vault"). Ahora cada skill ejecuta únicamente su propio script co-located; `.cortex/db/` solo guarda `vault.db` y `config.json`. Un vault de terceros (clonado, compartido, descargado) ya no puede plantar código que alguna skill ejecute — solo puede aportar datos.

### El único hook que sigue en pie: post-commit git hook

`~/.cortex-forge/bin/` y `~/.cortex-forge/bin/hooks/` ya no son la fuente de estos scripts — son una **caché de runtime** que `/cortex-forge-setup` (pasos 6b/6c) o `install.sh` (Step 5) pueblan copiando desde los directorios co-located de arriba, solo para los dos casos que lo necesitan: los git hooks. La razón es que un git hook corre fuera de cualquier sesión de agente — no hay quien "resuelva la ruta relativa a la skill" en ese contexto, así que necesita una ruta absoluta fija, sin importar desde dónde se instaló la skill (`~/.claude/skills/`, `.claude/skills/`, `~/.agents/skills/`, etc.).

| Bloque instalado en `<vault>/.git/hooks/post-commit` | Script invocado | Copiado desde | Qué hace | Condición |
|--------|----------------|----------------|----------|-----------|
| `cortex-forge prune` | `~/.cortex-forge/bin/cortex-prune.sh` | `skills/cortex-prune/cortex-prune.sh` | Refresca `wiki/meta/vault-report.json`; log en `.git/cortex-prune.log` | Siempre (backgrounded, fail-open) |
| `cortex-forge reindex` | `~/.cortex-forge/bin/hooks/cortex-reindex-post-commit.sh` | `skills/cortex-forge-setup/cortex-reindex-post-commit.sh` | Re-indexa embeddings cuando el commit tocó archivos `wiki/` | Solo si `.cortex/db/vault.db` existe Y el commit incluyó cambios en `wiki/` |

**Flujo del reindex:** el script detecta cuántos archivos `wiki/` cambiaron en el commit (`git diff-tree`), y solo entonces invoca `~/.cortex-forge/bin/cortex-index.py` (la caché de runtime, copiada ahí por `cortex-forge-setup` — nunca un script que viva dentro del vault) sobre la raíz del vault. Si la DB no existe o no hay archivos wiki modificados, sale silenciosamente (`exit 0`). El bloque usa `|| true` para ser fail-open — nunca bloquea un commit.

**Instalación:** ambos bloques se instalan opcionalmente en `<vault>/.git/hooks/post-commit` durante `/cortex-forge-setup` (pasos 6b/6c) o `install.sh`.

**Nota de rendimiento:** el reindex es full (no incremental) — recorre todos los archivos wiki/ en cada commit que los toque. Aceptable con < 200 páginas; en vaults grandes puede requerir estrategia incremental (indexar solo los paths del diff).

---

- 2026-06-13 [CommandCode]: Page created — comprehensive workflow architecture reference covering 3-phase flow, hooks per agent, skills, scripts, degraded modes, and config files
- 2026-06-27 [Claude Code]: Added `.git/hooks/` section — post-commit hook blocks (prune + reindex), reindex trigger conditions, performance note on full vs incremental strategy
- 2026-06-28 [Claude Code]: Corrected script location throughout — all scripts live in `~/.cortex-forge/bin/hooks/` (global), never in consumer vault `bin/`; added reindex script to hook table; clarified standalone scripts are repo-only
- 2026-07-02 [Claude Code]: Full rewrite — agent lifecycle hooks (SessionStart, PreCompact, SessionEnd, Stop, PreToolUse) were removed from cortex-forge entirely; replaced the 3-phase hook/no-hook table and per-agent hook wiring reference with the manual, `AGENTS.md`-mandated protocol used identically on every agent. Only the post-commit git hooks (prune, reindex) remain — kept and documented unchanged, since they're git-triggered, not agent-triggered. See [[wiki/concepts/agent-hook-compatibility]] for why hooks were dropped.
- 2026-07-03 [Claude Code]: Scripts relocated to be co-located with the skill that uses them (`skills/cortex-prune/cortex-prune.sh`, `skills/cortex-assimilate/cortex-sanitize.sh`, `skills/cortex-forge-setup/{cortex-index.py,cortex-search.py,embeddings.py,cortex-reindex-post-commit.sh}`) — so `npx skills add itsmistermoon/cortex-forge --skill X` installs a fully functional skill without depending on `~/.cortex-forge/` (the tarball runtime). `~/.cortex-forge/bin/` is now only a runtime cache populated at setup time, used exclusively by the two git hooks (which need a fixed absolute path outside any agent session). Fixed two latent path bugs found in the process: the reindex post-commit script pointed at a nonexistent `{vault}/bin/cortex-index.py`, and `cortex-assimilate` step 7 pointed at `.cortex/cortex-index.py` instead of `.cortex/db/cortex-index.py`.
- 2026-07-03 [Claude Code]: Second pass — eliminated the remaining vault-local code execution flagged by a Snyk security audit (E006 CRITICAL for `cortex-recall`, same category unreported for `cortex-assimilate`). `cortex-search.py`+`embeddings.py` moved to `skills/cortex-recall/`; `cortex-index.py`+`embeddings.py` duplicated into `skills/cortex-assimilate/` (kept in sync via a new CI check, `duplicated-script-sync`). `cortex-forge-setup` no longer copies these scripts into `{vault}/.cortex/db/` at all — it runs its own co-located `cortex-index.py` directly, and copies `cortex-index.py`+`embeddings.py` to `~/.cortex-forge/bin/` only for the git hook's use. `{vault}/.cortex/db/` now holds only `vault.db` and `config.json` — no executable code, ever.
