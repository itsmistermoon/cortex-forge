---
name: cortex-prune
description: Health check del vault — detecta dead links, páginas huérfanas, provenance faltante y fuentes no procesadas.
argument-hint: "[vault-name]"
---

Begin your response by outputting exactly: `Pruning vault...`

Health check del vault activo en dos capas: estructural (script) y semántica (agentes).

## Steps

1. **Resolve vault** — read `~/.cortex-forge/config.yml`:
   Also read `locale:` from the vault's entry — use it for all agent-generated content. Fallback if absent: `.hot/MEMORY.md` title line (`— locale: {lang}`) → `CODEX.md` Vocabulary (`**locale**:`) → default `en`.

   - If the first argument matches a registered vault name (e.g., `/cortex-prune personal`) → use that vault.
   - Otherwise: check if CWD is inside any registered vault → use that vault.
   - If not, use the `default` vault.
   - If no default and multiple vaults → ask the user to pick one.
   - If no vaults registered → stop and prompt to run `/cortex-forge-setup`.

   **Confirmation gate:** if the vault was resolved from an explicit argument (not from CWD), confirm with the user before proceeding: "About to prune `{vault-name}` at `{path}`. Continue?" — do not proceed until confirmed.

   Confirm vault is a Cortex Forge vault: path contains `wiki/` and `bin/cortex-prune.sh`.

   If `CODEX.md` exists at the vault root, read **Domains** and **Out of scope** — use them to flag pages whose topics fall outside the vault's defined scope.
   Also read `locale:` from `~/.cortex-forge/config.yml` (match vault by path) — use it for all agent-generated content. Fallback if absent: `.hot/MEMORY.md` title line (`— locale: {lang}`) → `CODEX.md` Vocabulary (`**locale**:`) → default `en`.

2. **Capa 1 — Structural check**: Run `bash {vault}/bin/cortex-prune.sh {vault}` and capture output.

3. **Capa 2 — Semantic analysis**: Run the four semantic checks below. For each check, spawn subagents as described — do not attempt to reason about the wiki pages from memory alone.

4. **Report** all findings (Layer 1 + Layer 2) grouped by severity. For each: path(s), problem, proposed action.

4a. **Verify `wiki/meta/vault-report.json`** — the Layer 1 script (step 2) writes or overwrites this file on every run. Confirm it was refreshed (its `generated` date matches today) and report its path to the user. Do not write it yourself — the script is the single writer. The canonical schema:

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

   Field definitions:
   - `health.dead_links` — array of `{"from": "wiki/...", "broken_target": "[[X]]"}` objects, from Layer 1.
   - `health.raw_without_source_page` — array of `.raw/` file paths with no corresponding `wiki/sources/` page, from Layer 1.
   - `health.missing_confidence` — array of page paths where `confidence:` is absent from frontmatter, from Layer 1.

   This file is the session-startup health signal read in `AGENTS.md`. It is gitignored — a local artifact, not versioned content. This schema is canonical: do not add fields that have no consumer in `AGENTS.md` or in this skill.

5. **Consolidate findings** — if your environment supports subagent spawning, delegate to a subagent using the lightest capable model available. This task requires only structured formatting of pre-classified findings — prioritize speed. If subagent spawning is not supported, execute inline.

   Prompt: "You are synthesizing the results of a vault health check. Here is the Layer 1 structural report: {layer1_json}. Here are the Layer 2 semantic findings: {layer2_findings}. Produce a single grouped report with this structure:
   - HIGH findings (list each: path, problem, proposed action)
   - MEDIUM findings (same)
   - LOW findings (same)
   - Summary line: '{N} HIGH / {N} MEDIUM / {N} LOW findings'
   Be concise. Do not add explanation beyond what's needed to act on each finding."

   The main agent presents this consolidated report verbatim — it does not re-process or summarize the output.

6. **Ask** whether to proceed with corrections per the auto-correct / requires-confirmation rules below.

---

## Capa 2 — Semantic checks

### 2a. Unlinked relationships between entities and concepts

Read `wiki/index.md` to get the full list of entities and concepts. Then:

1. For every pair of pages where EITHER of these is true:
   - One page's `title`, `aliases`, or `tags` contains a term that appears in the other page's title or aliases
   - One page's body text mentions the other entity/concept by name without using `[[wikilink]]` syntax
2. If your environment supports subagent spawning, spawn one subagent per candidate pair using the lightest capable model available. This task requires only binary classification — prioritize speed. If subagent spawning is not supported, evaluate each pair inline.

   Prompt per pair: "Read {page_A} and {page_B}. Are these genuinely related (one describes a component, variant, or sub-topic of the other)? Or is the name/tag overlap coincidental? Respond with: RELATED or COINCIDENCE, followed by one sentence of justification. If RELATED, propose the exact wikilink text to add to each page."
3. Collect verdicts. Report RELATED findings as MEDIUM findings. Discard COINCIDENCE.

### 2b. Body text mentions without wikilinks

For each page in `wiki/concepts/`, `wiki/entities/`, and `wiki/pages/`:

1. Extract all entity and concept titles + aliases from the index.
2. Scan the page body for plain-text mentions of those names (case-insensitive) that are NOT already wrapped in `[[...]]`.
3. Report as LOW: "Page X mentions 'Y' without a wikilink — consider `[[wiki/entities/Y]]`."

Do not flag mentions inside code blocks or frontmatter.

### 2c. Sources without a covering concept

For each page in `wiki/sources/`:

1. Check if any page in `wiki/concepts/` or `wiki/entities/` lists this source in its `sources:` frontmatter.
2. If no covering page exists: if your environment supports subagent spawning, spawn one subagent per uncovered source using the lightest capable model available. This task requires only a three-way classification — prioritize speed. If subagent spawning is not supported, evaluate inline.

   Prompt: "Read {source_page}. Does this source introduce a distinct concept, pattern, or entity that warrants its own wiki page? Or is it adequately covered by existing vault pages (list them if so)? Respond: NEEDS_PAGE, COVERED_BY {page}, or BORDERLINE with one sentence."
3. Report NEEDS_PAGE as MEDIUM. Report BORDERLINE for user decision. Discard COVERED_BY.

### 2d. Potential page merges (debate pattern)

Trigger only when check 2a finds two pages with significant overlap (not just a component relationship, but potentially duplicate coverage of the same topic).

If your environment supports subagent spawning, spawn two subagents in parallel using the lightest capable model available. This task requires structured argumentation, not deep reasoning — prioritize speed. If subagent spawning is not supported, argue both sides inline before rendering a verdict.

- **Agent FOR merge**: "Read {page_A} and {page_B}. Argue that these pages should be merged. What content would be lost? What would be gained? Max 5 bullet points."
- **Agent AGAINST merge**: "Read {page_A} and {page_B}. Argue that these pages should remain separate. What distinct value does each provide? Max 5 bullet points."

Then spawn a third subagent (or continue inline):
- **Synthesizer**: "Given these arguments FOR and AGAINST merging {page_A} and {page_B}: {for_args} / {against_args} — render a verdict: MERGE, KEEP_SEPARATE, or RESTRUCTURE. One paragraph."

Report verdict as MEDIUM. Never auto-apply — always requires user confirmation.

---

## Auto-correctable (propose + apply on confirmation)

- Add missing `confidence:` or `tags:` to source pages
- Add `[[wikilink]]` to a body mention identified in check 2b
- Add entry to `wiki/index.md` for unindexed pages
- Add `wiki/meta/log.md` entry: `## [YYYY-MM-DD] prune | {N} findings`

`wiki/meta/vault-report.json` is written automatically by `bin/cortex-prune.sh` on every Layer 1 run — it is not a correction and needs no confirmation.

## Requires confirmation (never auto-apply)

- Add cross-links between entities/concepts (check 2a verdict: RELATED)
- Create missing concept/entity pages (check 2c verdict: NEEDS_PAGE)
- Merge pages (check 2d verdict: MERGE or RESTRUCTURE)
- Delete orphan pages

---

## Detection criteria — Capa 1 (bin/cortex-prune.sh)

| Severity | Check |
|---|---|
| HIGH | Dead `[[wikilinks]]` pointing to non-existent pages |
| HIGH | `.raw/` files with no corresponding `wiki/sources/` page |
| HIGH | Pages without YAML frontmatter (excl. `index.md`, `log.md`) |
| MEDIUM | Orphan pages — no incoming wikilinks from any other vault page |
| MEDIUM | Concepts/entities without `sources:` or `confidence:` frontmatter |
| MEDIUM | Source pages without `confidence:` frontmatter |
| LOW | Source pages without `tags:` (or `tags: []`) |

## Rules

- Always run the script for Layer 1 — never reproduce its logic ad-hoc
- For Layer 2, always spawn subagents — never reason about page relationships from memory alone
- `index.md` and `log.md` without frontmatter is expected, not a finding
- Source pages use `source:` (URL) and `raw:` for provenance — `raw:` is the page's context pointer back to its `.raw/` primary. `sources:` (wiki links) is for concepts and entities only
- Orphan sources are normal if freshly ingested and not yet linked from concepts/entities
- Never delete or merge pages without explicit user confirmation
- Debate pattern (2d) only triggers on genuine ambiguity — not on clear component relationships
