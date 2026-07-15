# METHODOLOGY.md — Flujo de desarrollo agéntico

Metodología de trabajo compartida entre todos los proyectos de `/proyectos`.
Todo agente que trabaje en un repo bajo `/proyectos` debe seguir este flujo.

**Instalación de skills:** `npx skills add mattpocock/skills`

---

## 0. Tabla de decisión — qué skill usar en cada momento

Consultar esta tabla ante cualquier duda sobre qué invocar a continuación.

| Situación | Skill a usar |
|---|---|
| Hay que decidir algo que **no** es sobre un codebase (plan, idea, decisión personal) | `/grill-me` (§2.1) |
| Hay que decidir algo sobre un codebase y el alcance entra en una sesión | `/grill-with-docs` (§2.1) |
| El trabajo es demasiado grande para una sesión (riesgo de perder contexto entre sesiones) | `/wayfinder` (§2.2) |
| La pregunta clave es "¿cómo se ve?" o "¿cómo se comporta?" antes de comprometerse a una spec | `/prototype` (§2.3) |
| Hace falta investigar algo externo sin interrumpir la sesión activa | `/research` (§3.4) |
| Ya hay contexto compartido (grill cerrado o mapa de Wayfinder resuelto) y falta la spec | `/to-spec` (§2.4) |
| Hay una spec y hay que trocearla en trabajo ejecutable | `/to-tickets` (§2.5) |
| Toca ejecutar un ticket puntual | `/implement` (§2.6) |
| Se terminó de implementar y hay que verificar el resultado | `/code-review` (§2.7) |
| Bug complejo, causa no obvia, varias hipótesis posibles | `/diagnose` (§3.1) |
| Llegó un issue de alguien más (no fue grillado por el propio flujo) y no está claro si se puede trabajar todavía | `/triage` (§3.2) |
| Hay que alinear el codebase con las decisiones ya tomadas (CONTEXT.md, ADRs) o resolver deuda de arquitectura | `/improve-codebase-architecture` (§3.3) |
| Se está instalando esta metodología en un repo, nuevo o existente | `/setup-matt-pocock-skills` (§4) |
| No se sabe si existe una skill para algo puntual | `/find-skills` (§3.5) |
| Hay tickets en el "frontier" (bloqueadores resueltos, requiere tracker real — ver §2.5) y conviene ejecución autónoma continua | Ralph loop (§2.8) |

---

## 1. Por qué este flujo

Reemplaza "plan mode" directo por etapas explícitas con artefacto propio
verificable: separa decisiones de arquitectura de hechos explorados en el
código, permite partir trabajo grande entre sesiones/agentes sin perder
contexto, saca el refactor de la implementación, y deja el review contra un
criterio objetivo (spec + estándares) en vez de la impresión del agente.

---

## 2. El flujo principal

Grilling (→ Wayfinder si es grande) → Spec → Tickets → Implement → Code Review.
Detalle de cada etapa abajo; para saber qué invocar en cada momento, usar la
tabla de §0.

### 2.1 Grilling

`/grill-me` para decisiones no-codebase; `/grill-with-docs` para decisiones
sobre un codebase (además genera `CONTEXT.md`/ADRs vía `/domain-modeling`).
Ambas corren una sesión de `/grilling` — el protocolo de la sesión (una
pregunta a la vez, Fact/Decision, gate de confirmación) vive en esa skill.

### 2.2 Wayfinder (planes grandes)

Para trabajo demasiado grande para una sesión de grilling: `/wayfinder`
mapea el trabajo como tickets en el issue tracker y los resuelve uno a la
vez. Al cerrar el mapa, esa información se convierte en spec vía
`/to-spec`. Recomendado especialmente para trabajo de frontend (ver §2.3).

### 2.3 Prototyping (soporte de grilling/wayfinder)

`/prototype` — artefacto barato para responder *"¿cómo se ve?"* o *"¿cómo
se comporta?"* antes de comprometerse a una spec. Invocable por el propio
modelo. Esencial para casi cualquier cosa que toque frontend.

### 2.4 Spec

El grilling cerrado (o el mapa de Wayfinder resuelto, ver §2.2) se convierte
en spec vía `/to-spec`, sin nueva interview — solo sintetiza lo ya
conversado. Sigue con §2.5.

### 2.5 Tickets

La spec se descompone en tickets vía `/to-tickets`. Cuando el tracker
soporta bloqueos nativos ("tracker real" — ver §4), los tickets sin
bloqueadores pendientes quedan en el "frontier" — el punto donde conviene
pasar a Ralph loop (ver §2.8).

### 2.6 Implement

Por ticket, en su propia sesión, vía `/implement` — que a su vez usa
`/tdd` (red→green, el refactor se resuelve en code review) y termina
invocando `/code-review`.

### 2.7 Code Review

`/code-review` revisa el diff desde un punto fijo (commit, branch, tag o
merge-base) en dos ejes en paralelo — Standards y Spec — y los reporta por
separado, sin fusionar hallazgos.

### 2.8 Ralph loop (autónomo / AFK)

Un solo prompt que se repite hasta agotar el trabajo disponible. Usar cuando
hay tickets en el "frontier" (ver §2.5) y no hace falta supervisión por
ticket: en cada vuelta toma el próximo ticket del frontier, lo implementa
(`/implement`), corre tests + types, commitea, y repite hasta que no queden
tickets disponibles.

Progresión recomendada: HITL (pair programming con el agente) primero, AFK
(autónomo) después de validar que el flujo funciona sin supervisión
constante.

---

## 3. Fuera del flujo principal

Skills que no forman parte de la secuencia lineal Grilling → Implement, pero
son parte del mismo stack y se invocan según la situación (ver tabla en §0).

### 3.1 Diagnose (bugs complejos)

Experimental — supervisar de cerca, el agente tiende a saltar a etapas
avanzadas demasiado rápido.

**Usar en vez de `/implement` directo cuando** el bug no tiene una causa
evidente tras una exploración rápida.

### 3.2 Triage (backlog de issues externos)

Para issues o PRs creados por otros (no producto de este flujo de
grilling). Los mueve por sus roles de categoría/estado hasta que están
listos para agente o humano.

**Usar cuando** entra un issue externo — antes de asignarlo a
implementación, hay que triarlo.

### 3.3 Improve codebase architecture

Usa el vocabulario compartido de `/codebase-design` y `CONTEXT.md`/ADRs
para proponer refactors.

**Usar cuando** hay deuda de arquitectura acumulada o el codebase se
desalineó del lenguaje documentado.

### 3.4 Research

Investiga en background sin interrumpir la sesión activa. Invocable desde
un ticket tipo Research de Wayfinder.

### 3.5 Find skills

Descubre qué skills instalables existen para una necesidad puntual. Si
encuentra una, instalarla e invocarla; si no, avisar al usuario y hacer el
trabajo a mano en vez de improvisar en silencio.

**Usar cuando** no está claro si ya existe una skill para lo que se
necesita hacer.

---

## 4. Cómo adoptar esto en un proyecto (nuevo o existente)

1. Si el repo ya tiene `AGENTS.md`/`CLAUDE.md` con un flujo de trabajo
   documentado, leerlo primero — no asumir que el repo está vacío. Decidir
   explícitamente si esta metodología lo reemplaza, se fusiona con él, o
   coexiste, y dejar esa decisión escrita en el propio archivo.
2. Instalar los skills (ver comando arriba) dentro del repo.
3. Correr `/setup-matt-pocock-skills` — explora el repo y pregunta antes de
   escribir nada (no asume que está vacío ni pisa un tracker ya
   configurado). Configura per-repo: issue tracker (GitHub, GitLab, local
   markdown, o custom), triage labels, domain docs.
4. Verificar que `.claude/skills/` tenga (al menos) `grill-me`,
   `grill-with-docs`, `wayfinder`, `to-spec`, `to-tickets`, `implement`,
   `code-review`, `tdd`, `research`, `prototype`, `diagnose`, `triage`,
   `improve-codebase-architecture`, `find-skills`.
5. Agregar al `AGENTS.md`/`CLAUDE.md` del proyecto:

   ```
   ## Metodología de trabajo
   Sigue /Users/itsmistermoon/proyectos/METHODOLOGY.md. Si ese path no
   existe en este entorno (otra máquina, sandbox), avisar al usuario y
   usar el flujo nativo del repo en su lugar.
   ```

   Si el repo ya tiene coding standards o convenciones propias, referenciarlas
   ahí mismo para que `/implement` y `/code-review` las respeten.
6. Si el repo no tiene tracker real conectado (definido por el paso 3), usar
   la variante de archivo local (`tickets.md`) para `/to-tickets`.
