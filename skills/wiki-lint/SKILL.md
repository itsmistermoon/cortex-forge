---
name: wiki-lint
license: MIT
compatibility: Requires bash with jq, git, and python3 (structural check script)
description: Vault health check — detects dead links, orphan pages, missing provenance, and unprocessed sources.
disable-model-invocation: true
argument-hint: "[vault-name]"
---

Start your response with the flavor line `Linting vault...`, translated to the language of the user's current message (Spanish: `Revisando el vault...`), with nothing before it. Use that same language for every prompt, question, menu, and confirmation this skill produces — persisted vault content (if any) still follows the vault's locale, not the conversation language.

Health check the active vault in three layers: structural (script), semantic (agents), and drift (metadata comparison).

## Available scripts

Paths are relative to this skill's directory.

- **`scripts/lint.sh`** — Layer 1 structural check; single writer of `meta/vault-report.json` (step 2)
- **`scripts/validate-schema.sh`** — Validates `vault-report.json` schema drift, called by `lint.sh` as a sibling

## Steps

1. **Resolve vault** — per `~/.almagest/references/VAULT-RESOLUTION.md` (synced by `/wiki-setup` — if missing, run `/wiki-setup` first). If the first argument matches a registered vault name (e.g., `/wiki-lint personal`), use that vault.

   **Confirmation gate:** if the vault was resolved from an explicit argument (not from CWD), confirm with the user before proceeding: "About to prune `{vault-name}` at `{path}`. Continue?" — do not proceed until confirmed.

2. **Layer 1 — Structural check**: Run `bash scripts/lint.sh {vault}`. If the script is missing, the skill installation is incomplete — run `/wiki-setup`, sub-task `skills`, to reinstall.

3. **Layer 2 — Semantic analysis**: Run the semantic checks below (L2a–L2e) — read the actual pages, never reason about relationships from memory alone.

4. **Layer 3 — Drift detection**: For each `wiki/sources/` page, check whether its `.raw/` file was modified after the page was last synthesized.

   1. For each file in `{vault}/wiki/sources/`, read its `raw:` and `updated:` frontmatter fields. Skip pages with no `raw:` field.
   2. Run `stat -f "%Sm" -t "%Y-%m-%d" {vault}/{raw}` (macOS) or `date -r {vault}/{raw} "+%Y-%m-%d"` to get the `.raw/` file's modification date. If the file does not exist, skip — already covered by Layer 1's `raw_without_source_page` check.
   3. If `.raw/` mtime > `updated:` → MEDIUM finding: "`.raw/{slug}.md` was modified after `wiki/sources/{slug}.md` was last synthesized — source page may be stale."
   4. If no drift found, note: "Layer 3: no drift detected."

5. **Report** all findings (Layer 1 + Layer 2 + Layer 3) grouped by severity. For each: path(s), problem, proposed action.

   - **Verify `meta/vault-report.json`** — confirm it was refreshed (its `generated` date matches today) and report its path to the user. See `references/VAULT-REPORT-SCHEMA.md` for its schema.

6. **Consolidate findings** — if your environment supports subagent spawning, delegate to a subagent using the lightest capable model available. This task requires only structured formatting of pre-classified findings — prioritize speed. If subagent spawning is not supported, execute inline.

   Prompt: "You are synthesizing the results of a vault health check. Here is the Layer 1 structural report: {layer1_json}. Here are the Layer 2 semantic findings: {layer2_findings}. Produce a single grouped report with this structure:
   - HIGH findings (list each: path, problem, proposed action)
   - MEDIUM findings (same)
   - LOW findings (same)
   - Summary line: '{N} HIGH / {N} MEDIUM / {N} LOW findings'
   For each finding, output exactly three fields: path, problem (one sentence), proposed action (one imperative sentence). No additional explanation, context, or justification."

   The main agent presents this consolidated report verbatim — it does not re-process or summarize the output.

7. **Ask** whether to proceed with corrections per the auto-correct / requires-confirmation rules below.

---

## Layer 2 — Semantic checks

**Hard cap**: evaluate at most 20 candidate pairs in L2a and at most 20 uncovered sources in L2c. If there are more, pick the 20 with the strongest surface-level signal and note the total count skipped. Do not write scripts, external files, or spawn more than 3 subagents total — inline evaluation is always acceptable and preferred for small vaults.

### L2a. Unlinked relationships between entities and concepts

Read `wiki/index.md` to get the full list of entities and concepts. Then:

1. Identify candidate pairs where EITHER is true (read the files directly — no scripts):
   - One page's `title`, `aliases`, or `tags` contains a term in the other page's title or aliases
   - One page's body text mentions the other entity/concept by name without a markdown link (`[title](/wiki/...)`)
2. Evaluate each candidate pair inline, reading both pages once, and render two judgments from that read: relationship — RELATED or COINCIDENCE, with one sentence of justification, noting the exact markdown link to add to each page if RELATED; and contradiction — CONTRADICTION or CONSISTENT, comparing their claims on the shared subject (incompatible facts vs. mere differences in emphasis, scope, or vintage), noting the exact conflicting excerpt from each page if CONTRADICTION. Do not spawn subagents for this step.
3. Report RELATED findings as MEDIUM (the markdown link to add). Report CONTRADICTION findings as a separate MEDIUM (both excerpts side by side, no proposed action — resolving a factual conflict needs human judgment, not a suggested fix). Discard COINCIDENCE and CONSISTENT.

### L2b. Body text mentions without markdown links

For each page in `wiki/concepts/`, `wiki/entities/`, and `wiki/projects/`:

1. Extract entity and concept titles + aliases from the index.
2. Scan the page body for plain-text mentions of those names (case-insensitive) not already part of a markdown link.
3. Report as LOW: "Page X mentions 'Y' without a link — consider `[Y](/wiki/entities/Y.md)`."

Do not flag mentions inside code blocks or frontmatter.

### L2c. Sources without a covering concept

For each page in `wiki/sources/`:

1. Check if any page in `wiki/concepts/` or `wiki/entities/` cites this source in its `# Citations` section.
2. For uncovered sources: read the source page and classify inline — NEEDS_PAGE, COVERED_BY {page}, or BORDERLINE with one sentence. Do not spawn subagents for this step.
3. Report NEEDS_PAGE as MEDIUM. Report BORDERLINE for user decision. Discard COVERED_BY.

### L2d. Potential page merges (debate pattern)

Trigger only when check L2a finds two pages with significant overlap (not just a component relationship, but potentially duplicate coverage of the same topic).

Evaluate inline: read both pages, argue FOR merge (max 3 bullets), argue AGAINST (max 3 bullets), render a verdict: MERGE, KEEP_SEPARATE, or RESTRUCTURE with one paragraph.

Report verdict as MEDIUM. Never auto-apply — always requires user confirmation.

### L2e. Recurring recall misses

Reads `wiki/log.md`, not vault pages — a different data source from L2a–L2d, but still bounded by the same hard cap.

1. Collect `**[YYYY-MM-DD] query-miss** | {query}` entries from the last 30 days (or the most recent 20, whichever is fewer).
2. Group by topic similarity — same or near-identical query text, or queries a reasonable reading would consider the same underlying question asked differently.
3. Report any group with 2+ occurrences as MEDIUM: "`{N}` recall misses on `{topic}` since `{earliest-date}` — propose `/wiki-ingest` for a source, or confirm a wiki page should exist." Single-occurrence misses are normal noise — discard them.

---

## Auto-correctable (propose + apply on confirmation)

- Add missing `confidence:` to any page (source, concept, or entity) — default `medium` pending review, noted in the page's changelog
- Add missing `tags:` to source pages
- Add a markdown link to a body mention identified in check L2b
- Add entry to `wiki/index.md` for unindexed pages
- Add `wiki/log.md` entry: `**[YYYY-MM-DD] lint** | {N} findings`

`meta/vault-report.json` — written automatically by Layer 1 (step 2); not a correction, needs no confirmation.

## Requires confirmation (never auto-apply)

- Add cross-links between entities/concepts (check L2a verdict: RELATED)
- Create missing concept/entity pages (check L2c verdict: NEEDS_PAGE)
- Merge pages (check L2d verdict: MERGE or RESTRUCTURE)
- Resolve a contradiction (check L2a verdict: CONTRADICTION) — present both excerpts, let the user decide which stands, both, or neither
- Act on a recurring query-miss group (check L2e) — propose `/wiki-ingest` or a new page, per the user's call
- Delete orphan pages
- Fix a dead markdown link — search the vault for a page with a matching slug or title; propose retargeting there, or propose removal if none found
- Synthesize an unprocessed `.raw/` file — propose invoking `/wiki-ingest {vault} .raw/{slug}.md` within this session
- Reconstruct missing frontmatter — read the page's body and draft a best-effort frontmatter block (type, tags) for review
- Add a `# Citations` entry to a concept/entity/project — propose candidate citations drawn from the page's existing markdown links and body mentions
- Resolve a duplicate frontmatter key — show both values, ask which to keep (never guess the "right" one)
- Reconcile a frontmatter key that diverges from `templates/{type}.md` — propose removing an extra key or adding a missing one, per page
- Decide on an out-of-template directory (`wiki/pages/`, `wiki/reference/`, etc.) — propose one of: adopt it into the template set (add `templates/{type}.md`), migrate its content into an existing type, or leave as-is; never move/delete files without this decision

---

## Detection criteria — Layer 1 (lint.sh)

| Severity | Check |
|---|---|
| HIGH | Dead markdown links pointing to non-existent pages |
| HIGH | `.raw/` files with no corresponding `wiki/sources/` page |
| HIGH | Pages without YAML frontmatter (excl. `index.md`, `log.md`) |
| MEDIUM | Orphan pages — no incoming markdown links from any other vault page |
| MEDIUM | Concepts/entities without a `# Citations` section or `confidence:` frontmatter |
| MEDIUM | Malformed or non-sequential `# Citations` entries (not `[N] [title](path)`) |
| MEDIUM | Source pages without `confidence:` frontmatter |
| LOW | Source pages without `tags:` (or `tags: []`) |
| HIGH | Duplicate frontmatter key within a single page (invalid/ambiguous YAML) |
| MEDIUM | Frontmatter key in a page but absent from its `templates/{type}.md` (excludes `confidence`/`tags`, covered above) |
| MEDIUM | Frontmatter key missing that its `templates/{type}.md` ships with a non-blank default |
| LOW | Frontmatter key missing that its `templates/{type}.md` ships blank (e.g. `timestamp:`, `section:`) — optional, informational only |
| LOW | Top-level `wiki/` directory with no matching `templates/{type}.md` (e.g. legacy `pages/`, `reference/`) — structural, not auto-fixed |
| LOW | `wiki/index.md` section/listing under a heading that doesn't match the page's `type:` (heuristic A: only flag if the page is absent from its correct section, tolerates intentional cross-references) — console-only, not persisted to `vault-report.json` |
| LOW | Tag used exactly once with no entity/concept page behind it (e.g. typo, one-off label) — suggest merging into a registered tag from `meta/tags.md` or removing |

## Rules

- Always run the script for Layer 1 — never reproduce its logic ad-hoc
- For Layer 2, read the actual pages — never reason about relationships from memory alone
- Source pages use `resource:` (URL) and `raw:` for provenance — `raw:` is the page's context pointer back to its `.raw/` primary. `# Citations` (wiki links) is for concepts, entities, and projects only
- Orphan sources are normal if freshly ingested and not yet linked from concepts/entities
- Debate pattern (L2d) only triggers on genuine ambiguity — not on clear component relationships
- L2a's contradiction check flags factual conflicts, not differences in emphasis, scope, or vintage — when in doubt, classify CONSISTENT
- L2e skips `wiki/log.md` entirely if it has no `query-miss` entries — this is the normal case for a vault where every query has been answered
- Layer 3 drift findings are informational — never auto-re-synthesize; always ask the user
