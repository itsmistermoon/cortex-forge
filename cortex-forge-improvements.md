# Cortex Forge — Improvement Backlog
> Derived from comparative analysis with [Graphify](https://github.com/safishamsi/graphify) (v8, 61k stars).
> Written after full read of: all five skills, all five templates, AGENTS.md, CODEX.md, MEMORY-FORMAT.md, CODEX-FORMAT.md, TASTE-FORMAT.md.
> Each item is self-contained: exact files to touch, exact text to insert or change, acceptance criteria.
> Process in any order — no item depends on another except Item 4, which depends on Item 2.

---

## Reviewer trail

This document was reviewed by a second agent on 2026-06-10 acting as a **critical senior reviewer**. The role was to evaluate each item from a skeptical, maintenance-cost-aware perspective, push back on weak proposals, and surface hidden coupling between items. The reviewer did **not** rewrite the proposals — verdicts and critique points were appended to each item as a dedicated subsection, leaving the original proposal intact for a third agent to do a final pass.

**Co-signed by:**
- Claude.ai (model claude-sonnet-4-6) — comparative analysis with Graphify, change propposals
- Command Code v0.33.1 (model minimax-m3) — critical review with verdicts, see `### Verdict (Command Code, critical senior reviewer)` at the end of every item
- Codex (model GPT-5) — second-pass protocol-minimal review; cross-checked for duplicate sources of truth, stubbed artifacts, and unnecessary schema expansion
- Antigravity (model Claude Sonnet 4.6 Thinking) — final evaluation from a skeptical end-user perspective; assessed real implementation cost vs. stated value, surfaced risks the previous reviewers softened, and produced actionable per-item verdicts for the applying agent

**Reviewer scope:** read original items 1–6, read `AGENTS.md`, `CODEX.md`, `.hot/MEMORY.md`, and verified the codebase state (v0.2.0 published, `.hot/MEMORY.md` as fixed filename, type `Reference` in wiki taxonomy, six skills registered). The reviewer did not modify any of the proposed file changes — only appended verdicts.

**Reviewer stance:** the original analysis is strong on diagnosis (the "Corrections" table proves the author read the code) but uneven on implementation. The strongest items are those that touch contracts and documentation only (1, 5, 6). The weakest is Item 3, which proposes a documented stub as if it were a feature — that is debt, not infrastructure. The hidden coupling the reviewer surfaced: Item 2's `protocol_version` field and Item 6's `CHANGELOG.md` must agree on a single source of truth, and Item 3's `bin/standalone/` directory becomes a second source of truth for Layer 1 spec that already lives in `cortex-prune/SKILL.md`.

**Codex review summary:** I re-evaluated the backlog with a minimal-protocol lens. My pass focused on whether each change has a concrete consumer, whether it introduces a second source of truth, and whether it adds operational surface area without delivering runtime value. I preserved the original proposals and appended final verdicts for a third agent to arbitrate.

**Antigravity review summary:** I evaluated the backlog after the two prior review passes — my role was to ask the question the previous reviewers did not ask with enough force: *does this item earn its place given the current state of the repo?* The prior reviews are good at catching implementation problems but consistently soft on scope. Three items are clear wins (1, 5, 6). Two need tighter constraints before touching code (2, 4). One should be partially rejected outright (3). I also surfaced cross-cutting issues: `CODEX.md` is entirely unfilled (all sections are comment templates), which undermines Items 2 and 6; and the proposed CHANGELOG has both a wrong version baseline and a wrong year. Per-item verdicts follow.

---

## Item 1 — Confidence citations in `cortex-recall` responses

### What the code actually does today

Every template already carries `confidence: high` by default. `cortex-assimilate` and `cortex-imprint` both populate it with `high | medium | low` based on source type. `cortex-prune` (Layer 1, via `bin/cortex-prune.sh`) already flags source pages missing `confidence:` as MEDIUM severity. The field is in good shape.

**The gap:** `cortex-recall` synthesizes answers and cites pages, but its output contract does not require surfacing the `confidence:` value of cited pages. A caller gets `Source: wiki/concepts/synthesis-active.md` but doesn't know if that page is `confidence: high` (grounded in a primary source) or `confidence: low` (agent inference). For trust calibration this matters.

### Changes required

**File: `skills/cortex-recall/SKILL.md`**

In the `## Output format` section, change:

```markdown
Every response must include:
- At least one citation in the form `Source: wiki/{type}/{slug}.md`
- If no relevant pages exist: state "Not in vault" explicitly — do not fall back to training knowledge
```

To:

```markdown
Every response must include:
- At least one citation in the form `Source: wiki/{type}/{slug}.md [confidence: {value}]`
  where `{value}` is read directly from the page's YAML frontmatter `confidence:` field.
- If a cited page has no `confidence:` field, append `[confidence: unset]` and flag it as a
  finding — this is a missing-provenance issue for `cortex-prune` to resolve.
- If no relevant pages exist: state "Not in vault" explicitly — do not fall back to training knowledge
```

**File: `AGENTS.md`**

In the Recall protocol compliance criterion, change:

```markdown
**Compliance criterion:** every response that draws on vault knowledge must include at least one citation to a `wiki/` page. If `cortex-recall` is unavailable in this session, declare it explicitly before answering — do not answer as if recall occurred.
```

To:

```markdown
**Compliance criterion:** every response that draws on vault knowledge must include at least one citation to a `wiki/` page with its `confidence:` value appended. If `cortex-recall` is unavailable in this session, declare it explicitly before answering — do not answer as if recall occurred.
```

### Why this is the right scope

The templates are already correct. `cortex-prune` already enforces presence of the field. The only missing piece is the recall surface — making the field visible at query time, not just at write time.

### Acceptance criteria
- `cortex-recall` output format spec includes `[confidence: {value}]` appended to every citation.
- `cortex-recall` explicitly handles the `unset` case and routes it as a finding.
- `AGENTS.md` compliance criterion for Recall references confidence surfacing.
- No changes to templates (they're already correct).

### Verdict (Command Code, critical senior reviewer)

**Verdict: ACCEPT — accept as proposed, with one clarification.**

**Why accept:** the change closes a real transparency loop. `confidence:` is already enforced at write time by the templates and by `cortex-prune` Layer 1, but it is invisible at read time when an agent or user consumes a `cortex-recall` response. The field is in good shape; the only missing piece is surfacing it at query time.

**Clarification needed:** the proposal handles `unset` (flag as finding) but does not address `medium` explicitly. `medium` is a valid state (not a bug), and citations with `medium` should display the value without being flagged. Only `unset` counts as missing-provenance. The SKILL.md edit should make this distinction explicit: "If `confidence:` is absent, append `[confidence: unset]` and flag as finding. If `confidence: medium` or `low`, append the value and do not flag — these are valid states."

**Minor nit:** I would put the confidence marker *before* the path, not after, so a reader scanning multiple citations sees confidence first. This is bikeshedding; the proposed order is fine.

**For the third agent:** confirm that `cortex-prune` Layer 1 (which already flags missing `confidence:` as MEDIUM) and the new recall output contract stay in sync. If a page is flagged by prune as missing confidence, a recall that cites it will also surface the same issue via `[confidence: unset]` — the two signals must agree on what counts as a finding.

### Verdict (Codex, protocol-minimal review)

**Verdict: ACCEPT.**

**Why accept:** this is a narrow, coherent change. It exposes an already-existing field at the point of consumption, which improves trust without adding storage, new files, or a parallel contract.

**Constraint:** preserve the distinction between missing and low-confidence content. `unset` is the only error state here; `medium` and `low` remain valid and should be shown as-is.

**For the third agent:** keep this item if the implementation only appends the confidence value and does not widen the citation format beyond that.

### Verdict (Antigravity, final user-skeptic review)

**Verdict: ACCEPT — with one gap to close in the output contract.**

**Why accept:** three reviewers are aligned and the case is sound. The change is two lines of text in two files. It exposes a field that already exists, already has write-time enforcement, and adds zero maintenance surface.

**Gap not addressed by previous reviewers:** when the agent reads a page's frontmatter and the YAML is malformed (syntax error, encoding issue), the current proposal would emit `[confidence: unset]` — the same signal as a valid page with a missing field. These are different conditions. The SKILL.md edit should distinguish them: `[confidence: unset]` for a valid page missing the field; `[confidence: read-error]` for a file the agent could not parse. The `read-error` case is also a prune finding, but a different one from missing-provenance.

**For the applying agent:** implement exactly as proposed. Add the `read-error` case to the output spec alongside `unset`. No other changes.

---

## Item 2 — `vault-report.json` maintained by `cortex-prune`

### Context

`cortex-prune` today produces a verbal report and writes one line to `wiki/meta/log.md`. It has no machine-readable output artifact. This means:
- A new session can't read vault health at startup without running prune first.
- There's no persistent record of when issues were first detected vs. resolved.
- The session startup sequence (MEMORY.md → CODEX.md) has no health signal.

Graphify solves this with `GRAPH_REPORT.md`. The right format for Cortex Forge is `.json` because the primary consumer is an agent reading it at session start — structured is cheaper in tokens and unambiguous.

### Changes required

**File: `skills/cortex-prune/SKILL.md`**

Add a new step between the current Step 4 (report findings) and Step 5 (ask about corrections):

```markdown
4a. **Write `wiki/meta/vault-report.json`** — after completing Layer 1 and Layer 2, write or overwrite this file with the following structure:

​```json
{
  "generated": "YYYY-MM-DD",
  "protocol_version": "cortex-forge@0.1.0",
  "stats": {
    "total_pages": 0,
    "by_type": {
      "concepts": 0,
      "entities": 0,
      "sources": 0,
      "pages": 0,
      "reference": 0
    },
    "by_confidence": {
      "high": 0,
      "medium": 0,
      "low": 0,
      "unset": 0
    }
  },
  "health": {
    "dead_links": [],
    "orphan_pages": [],
    "raw_without_source_page": [],
    "pages_without_frontmatter": [],
    "missing_confidence": [],
    "missing_sources_field": []
  },
  "knowledge_map": {
    "most_referenced": [],
    "sources_without_covering_concept": [],
    "suggested_questions": []
  },
  "last_findings": {
    "high": 0,
    "medium": 0,
    "low": 0
  }
}
​```

Field definitions:
- `health.dead_links` — array of `{"from": "wiki/...", "broken_target": "[[X]]"}` objects from Layer 1.
- `health.orphan_pages` — array of paths with no incoming wikilinks, from Layer 1.
- `health.raw_without_source_page` — `.raw/` files with no `wiki/sources/` page, from Layer 1.
- `health.pages_without_frontmatter` — paths detected by Layer 1 (excluding `index.md`, `log.md`).
- `health.missing_confidence` — paths where `confidence:` is absent from frontmatter, from Layer 1.
- `health.missing_sources_field` — concept/entity paths where `sources: []` (empty), from Layer 1.
- `knowledge_map.most_referenced` — top-10 pages by incoming wikilink count (see link-count scan below).
- `knowledge_map.sources_without_covering_concept` — paths from check 2c with verdict NEEDS_PAGE.
- `knowledge_map.suggested_questions` — 3–5 questions generated by the agent based on vault content.
- `last_findings.high/medium/low` — total finding counts from this run.

**Link-count scan for `most_referenced`:**

For each page in `wiki/` (excluding `wiki/meta/`):
1. Extract the page's filename without `.md` extension (e.g., `synthesis-active` from `wiki/concepts/synthesis-active.md`).
2. Count occurrences of `[[synthesis-active` across all other `wiki/` `.md` files: `grep -rl "\[\[synthesis-active" wiki/ --include="*.md" | grep -v "^wiki/meta/" | wc -l`
   Note: count files that mention it, not total occurrences, to avoid one verbose page inflating the count.
3. Rank descending. Write top-10 as: `{"path": "wiki/concepts/synthesis-active.md", "incoming_links": 7}`.

This scan runs as part of Layer 1 — pure bash in `bin/cortex-prune.sh` — no LLM required.

**`vault-report.json` is committed** — it's vault state, not a local artifact. Do NOT add it to `.gitignore`.
```

Also update the existing Step 4 (report) to reference the file:

```markdown
4. **Report** all findings (Layer 1 + Layer 2) grouped by severity. For each: path(s), problem, proposed action.
   State the delta from the previous run if `vault-report.json` already exists: "Since last prune: N new issues, M resolved."
```

Update the `## Auto-correctable` section to add:

```markdown
- Write `wiki/meta/vault-report.json` (always — no confirmation needed)
```

**File: `AGENTS.md`**

In the Crystallize protocol `## Before your first response` sequence, add step 3 (shifting existing steps down):

```markdown
**Before your first response to the user, in any session that starts in this vault, you MUST:**

1. Read `.hot/MEMORY.md` in full.
2. If `CODEX.md` exists at the vault root, read it.
3. If `wiki/meta/vault-report.json` exists, read it. If `health.dead_links` or `health.raw_without_source_page`
   is non-empty, surface these to the user in your first message as actionable issues — not background noise.
   Do not surface `health.orphan_pages` unprompted (these are lower priority).
4. Treat all three as required context — not optional background.
5. If `MEMORY.md` contains `### Pending` items, acknowledge them in your first message or surface them
   before starting new work.
```

### Acceptance criteria
- `cortex-prune` writes `wiki/meta/vault-report.json` after every run.
- Schema matches the spec above exactly (field names, nesting, types).
- The link-count scan is documented in `cortex-prune` as part of Layer 1.
- `AGENTS.md` session startup reads `vault-report.json` as step 3 and surfaces HIGH findings.
- `vault-report.json` is not in `.gitignore`.

### Verdict (Command Code, critical senior reviewer)

**Verdict: ACCEPT — accept the JSON artifact, but the schema must be trimmed and two fields removed before implementation.**

**Why accept (with reservations):** the motivation is correct — a session-startup signal is genuinely missing, and JSON is the right format for agent consumers. But the proposed schema is bigger than the problem it solves.

**Specific objections:**

1. **Schema is oversized.** Six sub-arrays in `health`, three in `knowledge_map`, plus a `protocol_version` field, plus `last_findings` counters, plus `suggested_questions`. Each field is a maintenance commitment: if the schema changes, downstream consumers break. Trim `health` to the 3–4 fields that `AGENTS.md` will actually surface at session start (likely `dead_links`, `raw_without_source_page`, `missing_confidence`). Drop `last_findings` — that signal already lives in `wiki/meta/log.md`, which is append-only and already has a history.

2. **`suggested_questions` is filler.** "3–5 questions generated by the agent based on vault content" with no generation criterion means an LLM wasting tokens to populate a low-value field. If the goal is to help a user discover what is in the vault, a better field is `vault_topics: []` — derived deterministically from `CODEX.md` `domains:` and the `tags:` frontmatter. No LLM needed at write time.

3. **`protocol_version` is a coordination point with Item 6 (CHANGELOG.md).** If both exist, one must be the source of truth. My recommendation: `CHANGELOG.md` is authoritative for version; the JSON reads it (or is regenerated when CHANGELOG changes). Two sources of truth will drift.

4. **Commit vs gitignore is debatable, not a blocker.** "Vault state, not local artifact" is reasonable, but the file changes on *every* prune. If the team wants diff-reviewable health, commit it. If the team wants a clean history, gitignore it. Do not impose one answer — this is a team-preference decision, and the proposal should say so.

**For the third agent:** confirm that the trimmed schema still answers the original motivation (session-startup health signal). If trimming kills a field that AGENTS.md actually needs, keep it. The principle is: every field must have a consumer. Fields with no consumer are dead weight.

### Verdict (Codex, protocol-minimal review)

**Verdict: REJECT AS WRITTEN; ACCEPT ONLY AFTER TRIMMING.**

**Why reject as written:** the proposed JSON schema is overgrown for the stated use. It bundles speculative fields, a version authority that will drift, and history-like counters that already belong elsewhere. That is not minimal protocol; that is future maintenance cost.

**Minimum acceptable revision:** keep only fields with a live consumer in `AGENTS.md` or `cortex-prune`, remove or defer the rest, and choose one version source of truth. If the artifact cannot be reduced without losing actual utility, do not add it.

**For the third agent:** approve only the trimmed form, not the full schema. If the schema still feels large after trimming, the item should be rejected outright.

### Verdict (Antigravity, final user-skeptic review)

**Verdict: ACCEPT ONLY THE MINIMUM VIABLE SCHEMA — reject everything else in the proposal.**

**Why the full schema fails:** the two previous reviewers correctly flag it as oversized, but neither provides the minimum viable schema. Here it is:

```json
{
  "generated": "YYYY-MM-DD",
  "health": {
    "dead_links": [],
    "raw_without_source_page": [],
    "missing_confidence": []
  }
}
```

These are the only three fields that `AGENTS.md` step 3 (session startup) will actually read and surface to the user. Every other field in the original proposal — `stats`, `knowledge_map`, `suggested_questions`, `last_findings`, `protocol_version` — has no concrete consumer in the session startup flow. Drop them from this item; they can be added later when a real consumer exists.

**On `protocol_version`:** reject it from this schema. `CHANGELOG.md` (Item 6) is the authoritative version record. Do not create a second source of truth.

**On commit vs. gitignore:** gitignore it. This is a single-owner personal repo. Committing a file that changes on every prune run creates noise in git history with no benefit.

**On `CODEX.md`:** this repo's `CODEX.md` is entirely unfilled — all sections are comment templates. The `suggested_questions` and `vault_topics` fields (proposed or suggested as alternatives) depend on `CODEX.md` being populated. Neither field is viable until `CODEX.md` has real content. This is not the applying agent's problem to solve, but it should be noted as a blocker for any `knowledge_map` expansion.

**For the applying agent:** implement only the three-field schema above. Add step 3 to `AGENTS.md` startup sequence reading only `health.dead_links` and `health.raw_without_source_page` (surface these if non-empty). Add `wiki/meta/vault-report.json` to `.gitignore`.

---

## Item 3 — Headless mode documented + Obsidian visualization as official feature

### Context

`cortex-forge-setup` step 6 already configures hooks for multiple agents (Claude Code, Codex, Antigravity/Gemini CLI). But all five *skill* operations — assimilate, recall, imprint, prune, crystallize — only work when an agent is in an interactive session. There is no documented path for running them outside a session.

`bin/cortex-prune.sh` is the closest thing to headless operation: it's a script that runs without an agent. But it's not documented as the seed of a headless layer.

Separately, the vault uses `[[wikilinks]]` throughout `wiki/` — which means any Obsidian installation pointed at `wiki/` renders a live knowledge graph for free. This is the equivalent of what Graphify builds programmatically as `graph.html`. It should be documented as an official, zero-cost visualization layer.

### Changes required

**New file: `bin/standalone/README.md`**

```markdown
# bin/standalone — Headless operations

Scripts in this directory run vault operations without an active agent session.
They implement the structural (non-semantic) half of each skill's contract.

| Script | Skill equivalent | Requires LLM |
|---|---|---|
| `prune.sh` | `cortex-prune` Layer 1 | No — pure bash |

## Usage

​```bash
# Run structural health check and update vault-report.json
bash bin/standalone/prune.sh /path/to/vault
# Or from inside the vault:
bash bin/standalone/prune.sh .
​```

## Design constraint

Standalone scripts implement only what bash can do without an LLM:
- File system checks (orphans, dead links, missing frontmatter)
- grep-based link-count scan
- JSON output to wiki/meta/vault-report.json

Semantic operations (check 2a–2d in cortex-prune) require an agent session.
They are not replicated here — they complement, not replace, the standalone scripts.

## CI usage

​```yaml
# Example GitHub Actions step
- name: Vault health check
  run: bash bin/standalone/prune.sh ${{ github.workspace }}
​```
```

**New file: `bin/standalone/prune.sh`**

```bash
#!/usr/bin/env bash
# Headless cortex-prune Layer 1 — structural health check.
# Usage: bash bin/standalone/prune.sh <vault-path>
# Output: wiki/meta/vault-report.json (created or overwritten)
# No LLM required.

set -euo pipefail

VAULT="${1:-.}"

if [[ ! -d "$VAULT/wiki" ]]; then
  echo "Error: $VAULT does not look like a cortex-forge vault (wiki/ not found)" >&2
  exit 1
fi

echo "Pruning vault at $VAULT..."

# ── Layer 1: structural checks ──────────────────────────────────────────────
# NOTE: This script is a documented stub.
# Full implementation follows the detection criteria in skills/cortex-prune/SKILL.md § Detection criteria — Capa 1
# Implement each check per the severity table in that file.

# Example: orphan detection seed
echo "Orphan detection: TODO — implement per cortex-prune SKILL.md"
echo "Dead link detection: TODO — implement per cortex-prune SKILL.md"
echo "Link-count scan: TODO — implement per cortex-prune SKILL.md"

# ── Output ───────────────────────────────────────────────────────────────────
echo "Done. vault-report.json: TODO — write output to $VAULT/wiki/meta/vault-report.json"
```

Make executable: `chmod +x bin/standalone/prune.sh`

The script is an intentional documented stub — the structural implementation follows the detection criteria already specified in `skills/cortex-prune/SKILL.md`. The value of creating it now is establishing the path and the contract.

**New file: `docs/obsidian-visualization.md`**

```markdown
# Obsidian visualization

cortex-forge's `wiki/` is a native Obsidian vault. No configuration required.

## Setup

1. Open Obsidian → Open Folder as Vault → select the `wiki/` directory.
2. Enable Graph View (left sidebar icon).

## What renders

- **Nodes** — every page in `wiki/` (concepts, entities, sources, pages, reference).
- **Edges** — every `[[wikilink]]` between pages.
- **Clusters** — Obsidian renders densely-linked groups visually. This is the equivalent of Graphify's
  community detection, produced for free from the `[[wikilinks]]` that already exist.
- **Orphans** — isolated nodes with no connections are visually obvious — the same set that
  `cortex-prune` detects programmatically and writes to `vault-report.json`.

## Relationship with cortex-prune

`cortex-prune` detects orphans and dead links programmatically. Obsidian shows the same information
visually. They're complementary:

| | cortex-prune | Obsidian |
|---|---|---|
| Orphan detection | Programmatic, written to vault-report.json | Visual |
| Dead links | Programmatic | Not shown |
| Cluster detection | Link-count approximation (most_referenced) | Native graph layout |
| Contradiction detection | Semantic (subagent) | Not shown |

## Status

Supported but not required. The vault is fully functional without Obsidian.
The `[[wikilink]]` format is intentional — it serves double duty as Obsidian-compatible syntax and
as an inter-page citation format that `cortex-recall` and `cortex-prune` can parse.

Open `wiki/` only (not the vault root) to avoid Obsidian indexing `.raw/`, `.hot/`, and `skills/`.
```

**File: `README.md`**

Add after the `## Architecture` section:

```markdown
## Visualization

Open `wiki/` as an [Obsidian](https://obsidian.md) vault to get a live knowledge graph — nodes are pages, edges are `[[wikilinks]]`, clusters emerge from link density. No configuration needed. See `docs/obsidian-visualization.md`.
```

**File: `AGENTS.md` — `## Vault architecture` table**

Add a row:

```markdown
| **Standalone** | `bin/standalone/` | Headless scripts for CI and automation | No LLM required |
```

### Acceptance criteria
- `bin/standalone/README.md` exists and describes the design constraint (structural only, no LLM).
- `bin/standalone/prune.sh` exists, is executable, and has inline comments referencing `cortex-prune SKILL.md` for the full implementation spec.
- `docs/obsidian-visualization.md` exists and covers: setup, what renders, comparison table with cortex-prune, instruction to open `wiki/` only.
- `README.md` mentions Obsidian with a link to the doc.
- `AGENTS.md` vault architecture table includes `bin/standalone/` row.

### Verdict (Command Code, critical senior reviewer)

**Verdict: SPLIT — accept the Obsidian documentation half, reject the `bin/standalone/` stub half.**

**Obsidian section: ACCEPT.** Pure documentation, near-zero cost, and the comparison table (`cortex-prune` vs Obsidian) is accurate. Documenting "open `wiki/` only, not vault root" is a useful guardrail — it prevents Obsidian from indexing `.raw/`, `.hot/`, and `skills/` as graph nodes.

**`bin/standalone/` section: REJECT.** Three hard objections:

1. **The proposed script is a stub that does nothing useful.** The body has `echo "TODO — implement per cortex-prune SKILL.md"` three times. A stub that gets committed is technical debt that nobody pays. Three months from now, the CI step "passes" because the script exits 0, and a health check that lies about passing is worse than no health check at all.

2. **Establishing a "path and contract" with a non-functional script is a known anti-pattern.** If the goal is to mark a placeholder, use a GitHub issue or a ROADMAP.md entry — both are honest about being not-done. A non-executing shell script in `bin/` claims the slot without earning it.

3. **It creates a second source of truth for Layer 1 spec.** The canonical Layer 1 spec lives in `cortex-prune/SKILL.md`. A second file that "references" the SKILL.md but lives in a different directory will drift the moment the SKILL.md is updated and nobody remembers to mirror the change. AGENTS.md's design constraint — "templates co-located, not duplicated" — is exactly this principle.

**Alternative I recommend:** implement `bin/cortex-prune.sh` completely in one pass (that is Item 4, already in this backlog). If headless mode is needed later, add a `--headless` flag to the same script. One script, two modes. No new directory, no second source of truth.

**For the third agent:** if the team genuinely wants `bin/standalone/` as a separate concern (e.g., for distribution to non-Cortex-Forge users), then the script must be implemented end-to-end before it lands. Half-measures here are not acceptable.

### Verdict (Codex, protocol-minimal review)

**Verdict: REJECT AS WRITTEN — preserve the Obsidian docs idea, but do not add a stubbed standalone script or a second Layer 1 spec.**

**Why reject:** the documentation half is legitimate, but the `bin/standalone/` package creates maintenance debt immediately because the script is explicitly a TODO stub. A script that exits successfully while doing nothing is worse than no script. The proposal also duplicates Layer 1 semantics already owned by `skills/cortex-prune/SKILL.md`, which violates the minimal-protocol principle: one contract, one canonical implementation.

**Keep:** `docs/obsidian-visualization.md` and the README mention, provided they remain documentation-only and do not assert unsupported behavior.

**Drop or rewrite:** `bin/standalone/README.md`, `bin/standalone/prune.sh`, and the new `AGENTS.md` architecture row unless the standalone path is implemented end-to-end and has a clear consumer outside the existing agent workflow.

**For the third agent:** decide whether the value of a headless path justifies a new directory and maintenance surface. If yes, require a complete implementation first. If no, collapse the idea back into the existing `bin/cortex-prune.sh` flow and avoid a parallel contract.

### Verdict (Antigravity, final user-skeptic review)

**Verdict: SPLIT — Obsidian docs ACCEPT; `bin/standalone/` REJECT with no path to revival in this backlog.**

**On the Obsidian docs:** accept. Create `docs/obsidian-visualization.md` and add the README `## Visualization` paragraph. The comparison table is accurate. The "open `wiki/` only, not the vault root" instruction is the single most useful sentence in the entire item — it prevents Obsidian from indexing `.raw/`, `.hot/`, and `skills/` as graph nodes. Do not remove that instruction.

**On `bin/standalone/`:** reject with stronger rationale than the prior reviewers gave. In an agent-managed project the specific danger is not that the CI step lies — it is that **a future agent reading `bin/standalone/prune.sh` will treat the `echo "TODO"` lines as documentation of existing behavior, not as a placeholder**. Agent consumers of this codebase use the file tree as a source of truth. A script that exists and is executable is indistinguishable from a script that works. This is a category error, not just technical debt.

**On the `AGENTS.md` architecture row for `bin/standalone/`:** reject. Adding a row for a directory that contains only a TODO script implies the layer exists and operates. It does not.

**For the applying agent:** create `docs/obsidian-visualization.md` and add the README `## Visualization` paragraph exactly as proposed. Do not create `bin/standalone/`. Do not add a `bin/standalone/` row to the `AGENTS.md` architecture table. If headless mode is ever needed, add a `--headless` flag to `bin/cortex-prune.sh` — one script, one spec, no parallel contract.

---

## Item 4 — Link-count scan added to `bin/cortex-prune.sh`

### Context

`cortex-prune` has two layers: Layer 1 is structural (bash script `bin/cortex-prune.sh`) and Layer 2 is semantic (subagents). The link-count scan — ranking pages by incoming wikilinks — is purely structural: it only needs `grep` and `wc`. It belongs in Layer 1 (the bash script), not in Layer 2 (the agent), and its output goes into `vault-report.json` as `knowledge_map.most_referenced`.

This item specifies the exact implementation, which Item 2 references but doesn't fully define.

**This item depends on Item 2** — `vault-report.json` must exist before this scan has somewhere to write.

### Changes required

**File: `bin/cortex-prune.sh`**

Add the link-count scan as a distinct section after the existing structural checks. The script does not currently exist in the repo (it's called by the skill but not yet created). If it exists with different content, add this section to it without replacing existing logic.

Logic to implement:

```bash
#!/usr/bin/env bash
# Link-count scan — produces knowledge_map.most_referenced for vault-report.json
# Called by cortex-prune SKILL.md Layer 1 step.

VAULT="${1:-.}"
WIKI="$VAULT/wiki"

echo "=== Link-count scan ==="

# Build list of all wiki pages (exclude meta/)
mapfile -t PAGES < <(find "$WIKI" -name "*.md" -not -path "*/meta/*" -not -name "index.md")

declare -A INCOMING_COUNTS

for PAGE in "${PAGES[@]}"; do
  # Extract base name without extension for wikilink matching
  BASENAME=$(basename "$PAGE" .md)

  # Count files (not occurrences) that contain [[basename as a wikilink
  # Matches [[basename]] and [[basename|alias]] forms
  COUNT=$(grep -rl "\[\[${BASENAME}" "$WIKI" --include="*.md" \
          | grep -v "^${PAGE}$" \
          | grep -v "/meta/" \
          | wc -l | tr -d ' ')

  INCOMING_COUNTS["$PAGE"]=$COUNT
done

# Sort and take top 10
echo "Top referenced pages:"
for PAGE in "${!INCOMING_COUNTS[@]}"; do
  echo "${INCOMING_COUNTS[$PAGE]} $PAGE"
done | sort -rn | head -10

# Output as JSON fragment for vault-report.json
# (vault-report.json assembly is handled by cortex-prune skill after this script runs)
echo "=== End link-count scan ==="
```

**File: `skills/cortex-prune/SKILL.md`**

In the `## Detection criteria — Capa 1` table, add a row:

```markdown
| LOW | Link-count scan — produces `knowledge_map.most_referenced` in vault-report.json |
```

Also add a note after the table:

```markdown
**Link-count scan output:** the script emits the top-10 most-referenced pages to stdout. The skill (Step 4a) reads this output and writes it to `vault-report.json → knowledge_map.most_referenced` as `{"path": "...", "incoming_links": N}` objects. The scan matches `[[pagename` to catch both `[[pagename]]` and `[[pagename|alias]]` forms.
```

### Why this scope

- No Python, no external dependencies. Pure bash + grep + sort.
- Matches Cortex Forge's design constraint: `.md` + `.sh` only.
- The Graphify equivalent (Leiden algorithm) requires Python + `leidenalg` — this approximation costs nothing and catches the same signal at 80% fidelity.
- The Obsidian graph view in Item 3 provides the visual equivalent. This provides the programmatic, persistent-to-JSON equivalent.

### Acceptance criteria
- `bin/cortex-prune.sh` contains the link-count scan logic.
- The scan matches `[[pagename` (not just `[[pagename]]`) to handle alias variants.
- The scan excludes `wiki/meta/` from both source and target pages.
- The scan excludes self-references (a page linking to itself).
- `cortex-prune SKILL.md` detection table includes the link-count scan row.
- Output is written to `vault-report.json → knowledge_map.most_referenced` in Item 2's schema format.

### Verdict (Command Code, critical senior reviewer)

**Verdict: ACCEPT — accept the algorithm, with two technical fixes required before implementation.**

**Why accept:** the link-count scan is genuinely useful signal. Top-10 most-referenced pages tells you what the vault considers "core" without any semantic analysis. Pure bash, no dependencies, no LLM — exactly the kind of structural check that belongs in Layer 1.

**Required fixes:**

1. **Basename collisions are not handled.** If `wiki/concepts/synthesis.md` and `wiki/sources/synthesis.md` both exist, the `[[synthesis` regex matches both from any third page. The count for one is inflated by the other. Fix: match by full path-derived slug, e.g., normalize to `[[concepts/synthesis` or strip the `.md` extension and search for the full relative path. Trivial to implement, easy to forget.

2. **stdout-to-JSON handoff is fragile.** The script echoes results to stdout, and the SKILL.md then reads stdout and assembles JSON. That means the skill does parsing (likely `awk`/`sed` regex) of untyped output, or re-runs the grep. Both are fragile. Better: the script writes directly to `wiki/meta/vault-report.json` using `jq` (or hand-rolled JSON if avoiding dependencies). One writer, one truth.

**Caveat I want to keep in the record:** the proposal says the scan approximates Graphify's Leiden algorithm at "80% fidelity." That number is made up — Leiden is a community-detection algorithm, this is a popularity ranking. They answer different questions. Drop the percentage or rephrase as "answers a related but different question."

**For the third agent:** confirm that the scan runs *after* Layer 1 has detected `orphan_pages` (a page with 0 incoming links cannot be in `most_referenced` by definition, so the two outputs are correlated). The script should exclude any page flagged as orphan from the ranking, or document that an orphan can still appear if other pages link to it. Pick one interpretation and make it explicit.

### Verdict (Codex, protocol-minimal review)

**Verdict: ACCEPT THE SIGNAL, REJECT THE CURRENT HANDOFF MECHANISM.**

**Why accept the signal:** a most-referenced ranking is useful and cheap to compute. It helps identify core pages without semantic inference, so the underlying idea earns its place.

**Why reject the implementation shape:** the proposal currently uses stdout as an intermediate contract and then asks `cortex-prune` to re-parse or reassemble that output into JSON. That is avoidable complexity. The script should either write structured output directly or return a format with a single, explicit parser. Also, basename matching needs a stronger namespace boundary to avoid collisions between pages with the same filename in different folders.

**Minimum bar for approval:** one writer, one artifact, no stubbed shell, no ambiguous matching, and no dependence on a human remembering how to parse console text.

**For the third agent:** if you keep this item, tighten the path-matching algorithm and define the JSON emission boundary precisely. If you cannot do that cleanly, drop the item and keep the vault simpler.

### Verdict (Antigravity, final user-skeptic review)

**Verdict: DEFER — do not implement until Item 2's trimmed schema is stable.**

**Why defer:** this item writes to `vault-report.json → knowledge_map.most_referenced`. My verdict on Item 2 removes `knowledge_map` entirely from the minimum viable schema. Implementing a scan that writes to a field no consumer reads is wasted effort. This item becomes viable only if a future session adds `knowledge_map` back with a real consumer.

**Two technical problems that must be resolved before any implementation:**

1. **Basename collision is a design defect, not a theoretical risk.** The wikilink convention in this vault is `[[page-slug]]`, not `[[type/page-slug]]`. Matching `[[synthesis` will collide if both `wiki/concepts/synthesis.md` and `wiki/sources/synthesis.md` exist. The proposed "fix" — match by full path-derived slug — breaks compatibility with every existing wikilink in the vault. There is no clean solution within the current wikilink convention. Accept the limitation explicitly or change the wikilink convention first; do not paper over it.

2. **The "80% fidelity" claim is fabricated.** Leiden algorithm detects community structure; this scan counts popularity. They answer different questions. The applying agent must remove this comparison from any documentation generated by this item.

**On stdout-to-JSON:** both prior reviewers correctly flag this. The script must write JSON directly — no intermediate stdout parsing.

**For the applying agent:** do not implement this item in the current backlog pass. Add it to `ROADMAP.md` as a post-v0.3.0 item, contingent on `knowledge_map` being added to `vault-report.json` with a verified consumer.

---

## Item 5 — Platform compatibility table in `README.md`

### What the code actually does today

`cortex-forge-setup` (step 4) installs to `~/.agents/skills/`. Step 5 creates symlinks in `~/.claude/skills/` pointing to those. Step 6 configures hooks for: Claude Code (auto), Codex (manual instructions), and Antigravity/Gemini CLI (manual instructions). This is already more sophisticated than what the README communicates.

**The gap:** the README has no platform compatibility section. Someone using Codex, Cursor, or Gemini CLI reads `README.md` and doesn't know where to put the skill files, or that there are manual instructions in `cortex-forge-setup` for their agent.

### Changes required

**File: `README.md`**

Add a `## Platform compatibility` section after `## Usage`:

```markdown
## Platform compatibility

`/cortex-forge-setup` installs skills to `~/.agents/skills/` — the cross-platform convention
adopted by most AI coding agents — and creates agent-specific symlinks where detected.

| Agent | Skills path (global) | Hook support | Notes |
|---|---|---|---|
| Claude Code | `~/.agents/skills/` + `~/.claude/skills/` (symlinks) | Auto (SessionStart, PreCompact, SessionEnd) | Full support |
| Codex | `~/.agents/skills/` | Manual — see setup step 6 | Hooks in `~/.codex/hooks.json` |
| Antigravity (Gemini CLI) | `~/.agents/skills/` | Manual — see setup step 6 | Hooks in `~/.gemini/config/hooks.json` |
| CommandCode | `~/.agents/skills/` | Manual (Stop hook) | TASTE rule available via setup step 7 |
| Cursor | `~/.agents/skills/` | Not supported | Skills path is conventionally `~/.agents/skills/` |
| Other agents | `~/.agents/skills/` | Varies | Check agent docs for skill resolution path |

**If your agent does not read `~/.agents/skills/` automatically:**
Copy `skills/cortex-*.md` (or the full skill folder, if your agent requires it) to your agent's
configured skills path. `AGENTS.md` must always be present at the vault root regardless of agent.

Run `/cortex-forge-setup hooks` to reinstall hooks only.
Run `/cortex-forge-setup skills` to reinstall skills only.
```

**No changes to `cortex-forge-setup` itself** — the skill already handles this correctly. The table only documents what already exists.

### Acceptance criteria
- `README.md` contains a platform compatibility table covering at minimum: Claude Code, Codex, Antigravity, CommandCode, Cursor.
- Table shows: global skills path, hook support level, any notes.
- Table accurately reflects what `cortex-forge-setup` already does (symlinks for Claude Code, manual instructions for Codex and Antigravity).
- The sub-commands `hooks` and `skills` are mentioned as shortcuts.

### Verdict (Command Code, critical senior reviewer)

**Verdict: ACCEPT — with one factual verification before landing.**

**Why accept:** documentation-only change, high information value, near-zero cost. The platform compatibility table surfaces information that already exists in `cortex-forge-setup` step 4–6 but is invisible to a README reader. The five rows cover the realistic agent landscape.

**Required verification:** the proposal claims `/cortex-forge-setup hooks` and `/cortex-forge-setup skills` work as sub-commands for reinstalling just hooks or just skills. I have not verified these sub-commands exist in the current `cortex-forge-setup` skill. If they do not, either add them or remove the mentions from the README — documenting commands that do not exist is worse than not documenting them.

**One factual correction:** the Cursor row says "Not supported" for hooks. That is stronger than what I can verify. Cursor's skill resolution is typically `.cursor/rules/` or project-local, not `~/.agents/skills/`. Saying "Not tested" is more honest than "Not supported" — the difference matters for users evaluating whether to adopt.

**For the third agent:** confirm the sub-command existence and the Cursor row's accuracy. If both check out, accept as-is. If either is wrong, the proposal needs a small edit before merging.

### Verdict (Codex, protocol-minimal review)

**Verdict: ACCEPT WITH MINOR VERIFICATION, BUT DO NOT EXPAND THE CONTRACT BEYOND WHAT THE READER NEEDS.**

**Why accept:** this is pure documentation and it answers a real discoverability gap. The platform table is low-risk, high-signal, and does not add runtime surface area.

**Conditions:** only document commands that exist today, and avoid claiming stronger support than has been verified. The table should describe current behavior, not promise broader compatibility than the repo implements.

**For the third agent:** verify the exact setup subcommands before landing the README text. If the commands do not exist, remove them from the documentation rather than normalizing aspirational CLI syntax.

### Verdict (Antigravity, final user-skeptic review)

**Verdict: ACCEPT — with two factual corrections required before landing.**

**Why accept:** highest value-to-effort ratio in the backlog. Pure documentation, zero runtime risk, and it answers a question a new user will hit in the first five minutes.

**Required correction 1 — Cursor row:** the proposal says "Not supported" for Cursor hooks. That is an overclaim in the wrong direction. Cursor uses `.cursor/rules/` (project-local) as its primary instruction surface, not `~/.agents/skills/`. The row should read: Skills path: `.cursor/rules/` (project-local, not `~/.agents/skills/`); Hook support: Not tested; Notes: Copy `AGENTS.md` content to `.cursor/rules/cortex-forge.mdc`. "Not supported" implies a test was run and failed; "Not tested" is honest about the unknown.

**Required correction 2 — subcommands:** `/cortex-forge-setup hooks` and `/cortex-forge-setup skills` must be verified against the actual skill file before the README documents them. If they do not exist as discrete invocations, remove those two lines. Documenting commands that do not exist is the same error as the `bin/standalone/prune.sh` stub — it tells the reader something works when it does not.

**For the applying agent:** verify both corrections, then implement exactly as proposed. No other changes.

---

## Item 6 — `CHANGELOG.md` with semantic commit convention

### Context

The repo has 4 commits and no changelog. As the protocol evolves — new skill steps, changed compliance criteria, new `vault-report.json` schema fields — agents operating in vaults built on older protocol versions need a way to detect the divergence. `CHANGELOG.md` is the canonical solution.

Importantly: the items in this backlog (1–5) will each constitute a protocol change. Without a changelog, there's no record of when `vault-report.json` was added, when `cortex-recall` started surfacing confidence, or when the link-count scan was added to Layer 1.

### Changes required

**New file: `CHANGELOG.md`** at repo root:

```markdown
# Changelog

Protocol-significant changes to cortex-forge are documented here.

**What counts as protocol-significant:**
- Changes to `AGENTS.md` compliance criteria or session startup sequence
- Changes to skill contracts (input, output, steps, compliance criteria)
- Changes to template frontmatter schema
- Changes to `vault-report.json` schema
- New files added to `bin/` or `docs/` that alter vault operation
- Changes to `~/.cortex-forge/config.yml` structure

**What does not count:** rewording, typos, README prose, cosmetic changes.

Format: `[semver] — YYYY-MM-DD`

---

## [Unreleased]

## [0.1.0] — 2025-06-09

### Skills
- `cortex-assimilate` — ingest URL or `.raw/` file → synthesized wiki pages; SPA detection; vault resolution via `~/.cortex-forge/config.yml`
- `cortex-crystallize` — session snapshot to `.hot/MEMORY.md`; cross-vault mode; two-zone format (Current state + History)
- `cortex-imprint` — archive session synthesis as permanent wiki page; propose before creating
- `cortex-recall` — answer questions from vault wiki content with citations; parametric knowledge disqualified
- `cortex-prune` — vault health check; Layer 1 structural (bash) + Layer 2 semantic (subagents); four semantic checks (2a–2d)
- `cortex-forge-setup` — register vault in `~/.cortex-forge/config.yml`; install to `~/.agents/skills/`; Claude Code symlinks; hooks for Claude Code, Codex, Antigravity; TASTE rule for CommandCode; CODEX.md creation

### Protocols (AGENTS.md)
- Crystallize protocol — mandatory session startup: read MEMORY.md + CODEX.md before first response
- Assimilate protocol — mandatory: invoke `cortex-assimilate` on any URL or file input
- Recall protocol — mandatory: invoke `cortex-recall` before answering any vault-covered topic; parametric knowledge disqualified

### Templates
- `concept.md` — `confidence: high` default; `sources: []`; compiled truth + changelog
- `entity.md` — `confidence: high` default; `role:`, `context:`, `sources: []`; compiled truth + changelog
- `source.md` — `confidence: high` default; `source_url:`, `source_date:`, `source_author:`; summary + key ideas + connections
- `project.md` — `confidence: high` default; `status:`, `repo:`, `domains:`; goal + stack + decisions + next steps + knowledge applied + recurring issues
- `reference.md` — `confidence: high` default; table/code/checklist body

### Architecture
- Five-layer vault: Raw (`.raw/`) → Wiki (`wiki/`) → Hot (`.hot/`) → Codex (`CODEX.md`) → Meta (`wiki/meta/`)
- Global skills path: `~/.agents/skills/`; Claude Code symlinks at `~/.claude/skills/`
- `~/.cortex-forge/config.yml` — multi-vault registry with `default:` key
- Hot Cache Protocol: `load-hot-cache.sh` (SessionStart) + `update-hot-cache.sh` (PreCompact/SessionEnd)
- `MEMORY-FORMAT.md`, `CODEX-FORMAT.md`, `TASTE-FORMAT.md` — format references co-located with skills
```

**File: `README.md`**

Add a `## Commit convention` section near the bottom, before any footer:

```markdown
## Commit convention

```
protocol:  changes to AGENTS.md, skill steps, or compliance criteria
schema:    changes to template frontmatter or vault-report.json schema
feat:      new skill, new script, new document
fix:       incorrect instruction in a skill or broken script
docs:      README, prose, non-protocol documentation
```

`protocol:`, `schema:`, and `feat:` commits require a CHANGELOG entry.
`fix:` requires an entry only if it corrects a behavior agents were relying on.
`docs:` never requires an entry.
```

**File: `AGENTS.md`**

Add one line to the `## Vault architecture` section, after the table:

```markdown
See `CHANGELOG.md` for protocol version history. When operating in a vault that may have been created
before a recent protocol change, check the changelog to identify missing fields or behaviors.
```

### Acceptance criteria
- `CHANGELOG.md` exists at repo root.
- `[0.1.0]` entry documents the current state: all six skills, three protocols, five templates, architecture.
- `[Unreleased]` section exists as a placeholder.
- `README.md` documents the five commit prefixes and specifies which require a CHANGELOG entry.
- `AGENTS.md` references `CHANGELOG.md` in the architecture section.

### Verdict (Command Code, critical senior reviewer)

**Verdict: ACCEPT — with three corrections required and one coordination point with Item 2.**

**Why accept:** a protocol-versioned project without a changelog is a project that cannot be safely evolved. Vaults built on v0.1.0 have no way to detect that v0.2.0 added `CODEX.md`, the `Reference` type, the fixed `.hot/MEMORY.md` filename, or the parametric-knowledge disqualification. The motivation is correct and the proposal is well-scoped.

**Required corrections:**

1. **The [0.1.0] entry is the *wrong* baseline.** The repo is on **v0.2.0** (verified via `.hot/MEMORY.md` and `ROADMAP.md`). A changelog that starts at 0.1.0 *behind* the current state is desorienting. Either (a) start the changelog at 0.2.0 with the current state and add a retroactive 0.1.0 entry below, or (b) start at 0.1.0 *and* add a 0.2.0 entry covering the CODEX.md, Reference type, fixed MEMORY.md filename, and parametric-knowledge changes. I recommend (b) — version history should be honest, and a future agent debugging a v0.1.0 vault needs to see what 0.2.0 added.

2. **The five commit prefixes are incomplete.** `protocol:`, `schema:`, `feat:`, `fix:`, `docs:` cover the contract surface but miss `chore:` (dependency updates) and `refactor:` (reorganization without contract change). Either adopt Conventional Commits in full (which has well-defined behavior for these) or add the two missing prefixes explicitly. Half-conventional is worse than fully conventional because the gaps are silent.

3. **The "requires a CHANGELOG entry" rule is not enforceable without a hook.** A changelog that drifts from the code is worse than no changelog — it gives false confidence. If the team wants this to be reliable, add a pre-commit hook (or PR template checkbox) that verifies CHANGELOG.md was updated on `protocol:`, `schema:`, and `feat:` commits. Document the enforcement mechanism in the README section that introduces the convention.

**Coordination with Item 2 (vault-report.json):** the JSON's `protocol_version` field and `CHANGELOG.md` must agree. Pick one as source of truth — my recommendation: `CHANGELOG.md` is authoritative for the version string, and `vault-report.json` reads it (or is regenerated on each `protocol:` commit). Two sources of truth will drift within a month.

**For the third agent:** confirm that the corrected changelog (option b above) and the trimmed vault-report.json from Item 2's verdict can coexist. The schema's `protocol_version` should match the latest entry in CHANGELOG.md at all times. Add this as an explicit invariant in `cortex-prune` Step 4a, or in a test, or in AGENTS.md as a design constraint.

### Verdict (Codex, protocol-minimal review)

**Verdict: ACCEPT THE IDEA, REJECT THE CURRENT SHAPE WITHOUT REVISION.**

**Why accept the idea:** a changelog is the right place to record protocol-significant changes, and the vault already has enough moving parts that version history matters.

**Why reject the current shape:** the proposal is internally inconsistent with the repo state by using `0.1.0` as the baseline instead of matching the current `0.2.0` state. It also defines commit categories and enforcement expectations without a mechanism to enforce them. A convention without enforcement is documentation, not protocol.

**Minimum revision required:** align the initial version to the actual current state, decide whether the commit taxonomy is full Conventional Commits or a smaller custom set, and pair any “must update changelog” rule with an enforcement hook or check.

**For the third agent:** confirm that `CHANGELOG.md` and any version-bearing JSON field stay synchronized through one authoritative source, not two parallel claims.

### Verdict (Antigravity, final user-skeptic review)

**Verdict: ACCEPT — with three mandatory corrections before the file is created.**

**Why accept:** a protocol that evolves without a version record is a protocol that cannot be debugged. This repo already has meaningful version history (v0.1.0 → v0.2.0) and the items in this backlog will constitute v0.3.0-level changes. The CHANGELOG is the right artifact.

**Mandatory correction 1 — wrong year:** the proposal writes `[0.1.0] — 2025-06-09`. The actual date visible in `.hot/MEMORY.md` is June 2026, not 2025. Use `2026-06-08` for v0.1.0 and `2026-06-09` for v0.2.0.

**Mandatory correction 2 — wrong baseline version:** the repo is at v0.2.0. The CHANGELOG must include both a `[0.1.0]` retroactive entry and a `[0.2.0]` entry covering: CODEX.md added, type `Reference` in taxonomy, `.hot/MEMORY.md` fixed filename, parametric knowledge disqualification in Recall, PreCompact fix in crystallize, six-layer architecture. The `[0.2.0]` content is fully documented in `.hot/MEMORY.md` History — the applying agent should use that as the authoritative source.

**Mandatory correction 3 — commit convention:** adopt [Conventional Commits](https://www.conventionalcommits.org/) in full, or define a custom set completely. The proposed five-prefix subset silently omits `chore:` and `refactor:`, which creates invisible gaps. Half-conventional is worse than no convention. For a solo project, a complete custom set of 5–7 prefixes is fine — but define it without holes.

**On enforcement:** a pre-commit hook that checks changelog entries is overkill for a solo project and will be disabled the first time it blocks a typo fix. Document the convention and move on. Discipline is the enforcement mechanism here.

**On the architecture description in the `[0.1.0]` entry:** the proposal describes "Five-layer vault" but the current architecture has six layers (Raw, Wiki, Hot, Codex, Meta, Skills — per `AGENTS.md`). Correct this or the entry becomes a false historical record.

**For the applying agent:** create `CHANGELOG.md` with `[0.2.0]` as the topmost released entry (sourced from `.hot/MEMORY.md` History section), `[0.1.0]` retroactive below it with the corrected year and six-layer architecture description, and `[Unreleased]` as a placeholder above both. Use the corrected commit convention. Add `CHANGELOG.md` reference to `AGENTS.md` architecture section as proposed.

---

## Processing order recommendation

| Priority | Item | Files touched | Effort | Notes |
|---|---|---|---|---|
| 1 | **Item 6** — CHANGELOG | `CHANGELOG.md` (new), `README.md`, `AGENTS.md` | Low | Do first — documents current state before anything changes |
| 2 | **Item 1** — Confidence in recall | `skills/cortex-recall/SKILL.md`, `AGENTS.md` | Low | Additive; no template changes needed |
| 3 | **Item 5** — Platform table | `README.md` | Low | Documentation only; no logic changes |
| 4 | **Item 2** — vault-report.json | `skills/cortex-prune/SKILL.md`, `AGENTS.md` | Medium | Schema design + skill update |
| 5 | **Item 4** — Link-count scan | `bin/cortex-prune.sh`, `skills/cortex-prune/SKILL.md` | Medium | Depends on Item 2 |
| 6 | **Item 3** — Headless + Obsidian | `bin/standalone/` (2 files), `docs/obsidian-visualization.md`, `README.md`, `AGENTS.md` | Medium | Independent; can batch with 4+5 |

**Dependency:** Item 4 writes to `vault-report.json`. Item 2 defines that schema. Process Item 2 before Item 4.

---

## Corrections to previous analysis

The following assumptions in the original draft were wrong and have been corrected here:

| Wrong assumption | Reality (after reading code) |
|---|---|
| `confidence:` missing from concept/entity/reference/project templates | All five templates already have `confidence: high` |
| `confidence:` uses `extracted/synthesized/inferred` | Uses `high/medium/low` — defined by source type, not derivation method |
| cortex-prune has no semantic layer | Has sophisticated 4-check semantic layer with parallel subagents (2a–2d) |
| `cortex-forge-setup` has no platform awareness | Already does Claude Code symlinks + manual instructions for Codex and Antigravity |
| `bin/standalone/` doesn't exist | Correct — it doesn't, but `bin/cortex-prune.sh` is already called by the skill |

---

*Generated from full read of cortex-forge source — June 2026.*
*Skills read: cortex-assimilate, cortex-crystallize, cortex-imprint, cortex-recall, cortex-prune, cortex-forge-setup.*
*Templates read: concept.md, entity.md, source.md, project.md, reference.md.*
*Other: AGENTS.md, CODEX.md, MEMORY-FORMAT.md, CODEX-FORMAT.md, TASTE-FORMAT.md.*
