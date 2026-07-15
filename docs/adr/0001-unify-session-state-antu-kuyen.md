# ADR 0001: Unify session-state directory between Antu and Kuyen

## Status

Accepted — resolved via `/grill-with-docs`, 2026-07-13. Not yet implemented.

## Context

Antu (`antu-handoff`) and Kuyen (`kuyen-handoff`) each maintain a per-vault session-state directory (`.cortex/` and `.hot/` respectively). Both suites are installed globally by the same user and can be invoked in the same repo, so naming and behavioral divergence between them is a live risk, not just a cosmetic inconsistency. See `docs/family-conventions.md` for the broader cross-suite convention tracking this ADR is scoped under.

## Decisions

### 1. Directory resolution: nearest-`.git`, not literal CWD

Kuyen currently resolves `.hot/MEMORY.md` relative to the literal CWD; Antu walks up to the nearest `.git` root from CWD. Kuyen adopts Antu's resolution — a vault has one state directory at its root, not one per subdirectory a skill happens to be invoked from. Decided as a bug fix, not a lite-vs-robust tradeoff — the added text in `kuyen-handoff/SKILL.md` must stay minimal (this is a one-line resolution rule, not new machinery).

### 2. Shared directory and file names: `.hot/`, `HANDOFF.md`, `HISTORY.md`

Antu renames `.cortex/` → `.hot/` (Kuyen already uses this name, so Kuyen needs no directory-name migration). Both suites rename their session file from `MEMORY.md` to `HANDOFF.md` and their archive from `CONSOLIDATED.md` to `HISTORY.md`, dropping the neuroscience-flavored naming (memory/consolidation) in favor of literal names, consistent with the earlier `antu-assimilate → antu-ingest` / `antu-crystallize → antu-handoff` rename.

`.hot/` (not `.handoff/`) was chosen specifically because the directory holds more than handoff artifacts (Antu's `PRAXIS.md`, Antu's semantic-index `db/`) — naming the directory after one file inside it (`HANDOFF.md`) would read redundantly (`.handoff/HANDOFF.md`) and couple the directory name to a single skill/verb that could itself be renamed again later. `PRAXIS.md`'s own name is out of scope for this decision — flagged as a follow-up question.

### 3. Cross-suite detection: a one-line `suite:` marker

Neither suite adopts the other's `HANDOFF.md` schema (Antu keeps its frontmatter + fixed sections; Kuyen keeps free text). Instead, both write a single-key marker identifying who wrote last — `suite: antu` or `suite: kuyen` — so each skill can detect foreign content without parsing the rest of the format. Cheap for both: Kuyen adds one fixed line with no new logic; Antu already parses frontmatter, so reading one more key is free.

### 4. Archival philosophy: neither suite changes its core logic; both gain a marker-conditioned courtesy notice

Kuyen keeps whole-file dump + fresh rewrite. Antu keeps per-entry >15-day rotation. Neither attempts to recover or merge the other's structure automatically. Both gain a one-line addition to their final confirmation message, conditioned on the `suite:` marker of the file they're about to overwrite/archive:

- Kuyen, on finding `suite: antu` (or no marker): "previous HANDOFF.md looked like it came from Antu — archived in full; any pending items there won't carry forward automatically."
- Antu, on finding `suite: kuyen` (or no marker): archives the whole prior block as one dated entry (mirroring Kuyen's own behavior, instead of the old generic "malformed frontmatter" fragile-context path) and notes: "previous HANDOFF.md was Kuyen's (free text) — archived in full, no pending/decisions recovered automatically; check HISTORY.md manually if needed."

This makes cross-suite data loss visible at the moment it happens instead of discovered later, without adding merge/parse logic to either handoff skill.

### 5. New Antu-only skill for `.hot/` maintenance

Antu gains a 7th skill dedicated to `.hot/` hygiene — recovering pending/fragile-context items buried in `HISTORY.md` after a foreign-suite (Kuyen) write, re-evaluating whether existing Pending/Active decisions are still valid, retrospectively re-evaluating PRAXIS.md candidates across multiple past sessions, and deeper HISTORY.md cleanup. Mirrors the existing `antu-prune` pattern (separate, on-demand hygiene skill vs. folding everything into the skill that runs every session).

Kuyen gets no equivalent — deliberately asymmetric. Kuyen's philosophy doesn't admit this machinery (no `PRAXIS.md`, no structured Pending to recover, no `vault-report.json`); its only surface with this skill is passive (the `suite:`/`HANDOFF.md`/`HISTORY.md` conventions it already follows).

### 6. Responsibility split and name: `antu-triage`

Named `antu-triage` (reuses vocabulary already established in `AGENTS.md`'s issue-triage system, rather than coining a new word).

**Stays in `antu-handoff`** (mechanical, cheap, must run every session close): resolve context, rotate `## History` entries >15 days, write the new snapshot, vault-health triage from `vault-report.json`, and the marker-detection + whole-block-archive from decision 4 (must happen at the exact moment of the handoff, can't wait for an occasional pass).

**Moves to `antu-triage`** (heavier, judgment-based, can lag): PRAXIS.md pruning of stale `### YYYY-MM-DD` entries (was `antu-handoff` step 2); retrospective PRAXIS-candidate re-evaluation across multiple past sessions (distinct from the lightweight per-session judgment call that stays in `antu-handoff`, which needs the session's fresh context); actual recovery of pending/fragile-context items buried in `HISTORY.md` after a cross-suite write (never belonged in `antu-handoff` per decision 4); validity re-checks on existing `### Pending`/`### Active decisions` entries; deeper `HISTORY.md` cleanup (e.g. near-duplicate archived blocks).

### 7. `antu-triage` trigger: on-demand, plus two suggested-nudge conditions

Same as `antu-prune` — never auto-invoked. `antu-handoff` adds a `### Pending` suggestion (same pattern already used for vault-health and imprint candidates) in two cases: (a) it just archived a whole block due to a cross-suite marker mismatch (decision 4) — pending items may be recoverable right then; (b) `PRAXIS.md` pruning is more than ~30 days overdue (a simple threshold, analogous to the existing `hot_cache_stale_days` global config value). Outside those two cases, purely on-demand.

### 8. `.gitignore` policy: unify to "never track"

Kuyen adds `.hot/` (or at minimum `HANDOFF.md`) to its `.gitignore`, matching Antu's existing practice. Not a lite-philosophy tradeoff — tracking session state doesn't reduce dependencies or complexity, it was an oversight rather than a deliberate choice, and `kuyen-handoff`'s existing secret-redaction step (kept as-is) already signals awareness of exposure risk that untracking removes at the root instead of only mitigating.

### 9. Kuyen's `HISTORY.md` header uses the repo folder name, not a registered vault name

Antu's header (`# {vault-name} — consolidated history`) comes from its multi-vault registry (`~/.cortex-forge/config.yml`) — machinery Kuyen deliberately doesn't have. Kuyen builds its own header from the repo folder name it already resolves (via decision 1's nearest-`.git` walk), rather than adopting vault-registration awareness.

### 10. `PRAXIS.md` → `PLAYBOOK.md`

Same jargon-reduction rationale as decision 2 (MEMORY.md → HANDOFF.md, CONSOLIDATED.md → HISTORY.md). `PLAYBOOK.md` covers both halves of what the file holds — "how we do things here" (conventions) and "what broke before and how it was handled" (recurring failure patterns) — better than the more literal-but-narrower `CONVENTIONS.md` would. Antu-only, no Kuyen equivalent (unchanged from earlier).

## Consequences

- `antu-handoff`, `kuyen-handoff`, and the new `antu-triage` all need implementation work — none of this is built yet.
- `docs/family-conventions.md` needs a pass once implemented, to record the unified `.hot/`/`HANDOFF.md`/`HISTORY.md`/`PLAYBOOK.md` convention there too (it currently still describes the pre-unification state).
- `~/.cortex-forge/config.yml`'s `hot_cache_stale_days` key name should be revisited for the same jargon-reduction reason, though it wasn't explicitly raised in this session — noting it so it isn't lost.

## Implementation plan

1. Apply decisions 1–4, 8–9 to `antu-handoff` (`moon-antu`) and `kuyen-handoff` (`moon-kuyen`).
2. Build `antu-triage` (decisions 5–7) in `moon-antu`.
3. Rename `PRAXIS.md` → `PLAYBOOK.md` (decision 10) and migrate any existing content.
4. Update `docs/family-conventions.md` in `moon-antu` to reflect the unified convention.
5. Migrate both global installs (`~/.agents/skills/`, `~/.claude/skills/` symlinks), same as the Antu/Kuyen rename.
6. **Final audit**, once everything above lands: run `/writing-great-skills` against every touched/new `SKILL.md`, then `/improve-codebase-architecture` across both repos.

## Open questions

None — all decisions in scope for this session are resolved. Implementation is a separate step.
