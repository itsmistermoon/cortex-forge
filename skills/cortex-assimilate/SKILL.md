---
name: cortex-assimilate
behavior: ["ingest", "synthesize"]
description: Ingest a URL or file into the vault — saves to .raw/, synthesizes wiki pages, updates index. Trigger when the user pastes a URL with no other context, says "ingest this", "process this", "add this to the vault", "research X and build pages", or drops a file into .raw/. Use --research "<query>" to auto-discover and ingest sources from the web.
argument-hint: "[vault-name] <url-or-file> | --research \"<query>\" [--rounds N]"
---

# cortex-assimilate

Start your response with the flavor line `Assimilating source...`, translated to the language of the user's current message (Spanish: `Asimilando fuente...`), with nothing before it. Use that same language for every prompt, question, menu, and confirmation this skill produces — persisted vault content (if any) still follows the vault's locale, not the conversation language.

Ingest a new source and synthesize wiki pages from it.

## Available scripts

Paths are relative to this skill's directory.

- **`scripts/cortex-sanitize.sh`** — Detects and auto-redacts credentials in a temp file before ingestion (step 2)
- **`scripts/cortex-index.py`** — Re-indexes vault embeddings after a new source is ingested (step 7)
- **`scripts/embeddings.py`** — Shared embedding backend, imported by `cortex-index.py`; not invoked directly

## Steps

1. **Resolve vault** — per `references/VAULT-RESOLUTION.md`, then its `locale:` per `references/LOCALE-RESOLUTION.md`. If the first argument matches a registered vault name (e.g., `/cortex-assimilate second-brain <url>`), use that vault and treat the remaining argument as the URL or file path.

2. **Download or read** — input is a URL or a `.raw/` file path:
   - URL → fetch content, run the **SPA check** and the **sanitization check** below, then save to `{vault}/.raw/{slug}.md` (never overwrite if exists).
   - `.raw/` file → read directly.
   - **Network failure:** if the fetch fails or returns empty content, stop and report the error. Do not create a `.raw/` file or proceed to synthesis.
   - **Partial ingestion recovery:** if `.raw/{slug}.md` exists but `wiki/sources/{slug}.md` doesn't, a previous run was interrupted. Ask: "Found an unprocessed `.raw/{slug}.md` from a previous run. Re-synthesize from it?" Yes → skip to step 3; no → stop.

   **SPA check** — if the fetched page is a client-rendered shell with no meaningful body text (e.g. `<div id="root">`, `<app-root>`, near-empty HTML), recover the content via `references/SPA-FALLBACK.md`; if that fails, stop and ask the user for the content or a static URL. ⚠ Never save an HTML shell to `.raw/` — no readable content, no synthesis.

   **Sanitization check** — before saving to `.raw/`, run `bash scripts/cortex-sanitize.sh <temp-file>` (detects injection, exfiltration, and credential vectors) and inspect the JSON output:

   - **If `redacted: true`** — tell the user how many credentials were redacted in `<temp-file>` and proceed with the redacted content. Never reconstruct or reinsert the original secret anywhere — not even on explicit user request.
   - **Any other finding type** is informational, not blocking: list each finding (type, label, count) and ask "This content has [N] findings (see above). Proceed with ingestion?" — default is **yes**. If the user declines, stop without saving; if they accept, save to `.raw/` and note the findings in the source page's changelog.

   If `rg` or `jq` is not available, or the script errors: skip the check (fail-open), but tell the user explicitly that credential redaction did not run for this source — do not proceed silently.

3. **Synthesize** — evaluate the source against the type criteria in `## Page types` below and create pages for every qualifying type. **Done when:** every content type (concept, entity, project) that meets its creation criteria has a page — zero qualifying types skipped. If a topic is borderline, evaluate it rather than skipping.

4. Update `{vault}/wiki/index.md` with new pages.

5. **Project linking** — check `{vault}/wiki/projects/` for active projects whose `domains:` match the source; propose the update before writing.

6. **Backward enrichment** — scan existing wiki pages for candidates that should now reference the new source.

   Skip this step if the new source page has no `tags:` or if fewer than 5 wiki pages exist total.

   1. Read `tags:` from the newly created `wiki/sources/{slug}.md`.
   2. Candidates: pages in `wiki/concepts/`, `wiki/entities/`, or `wiki/projects/` that share at least one tag with the new source and don't already list `wiki/sources/{slug}.md` in `sources:`.
   3. Evaluate each candidate: does the new source add substantive information this page should reference — a notable comparable, an entry for an existing comparison or list, a contradiction or refinement of a claim? Classify as **ENRICHABLE** (specific addition stated) or **FALSE_POSITIVE** (tag overlap is incidental or thematic only).
   4. For each ENRICHABLE candidate, state exactly what to add and where — e.g., "Add OpenWiki to the comparison table in §Key mechanisms."
   5. Report all ENRICHABLE candidates to the user. Do not apply any changes without explicit confirmation per candidate.

7. **Re-index embeddings** — runs last so it captures every page this run touched, including step 5/6 updates to existing pages — if `{vault}/.cortex/db/vault.db` exists, run `python3 -B scripts/cortex-index.py {vault}` and report the result inline: "Indexed N new chunk(s)." If the db does not exist, skip silently — the vault may not have semantic search enabled.

## --research mode

If the first argument starts with `--research`, discover sources on the web instead of processing a single given URL or file — see `references/RESEARCH-MODE.md`.

## Page types

Each type has a template at `templates/{type}.md`.

- **Source** (`wiki/sources/`) — content created by someone external, with a verifiable URL or raw file. Every processed source gets one.
- **Concept** (`wiki/concepts/`) — synthesized knowledge with no existence outside the vault, even when derived from sources; an idea you'd look up in a textbook. Create when it has a proper name (principle, pattern, framework, technique), can be applied or referenced in future sessions, and warrants its own article. Skip concrete instances and topics too generic to stand alone.
- **Entity** (`wiki/entities/`) — a person, organization, tool, or service that exists in the world independently and can go stale (acquired, deprecated); something a journalist could write breaking news about. Create when it appears in more than one context or has an active role in the user's projects. Skip passing mentions with no role of their own.
- **Project** (`wiki/projects/`) — an active project with a repo, status, and its own decisions. Never for third-party projects mentioned only as context.

## Provenance

Always populate in every page created or updated:

```yaml
sources:
  - wiki/sources/{source-slug}.md
confidence: high | medium | low
```

**`confidence` criteria:**
- `high` — primary source: book, paper, official documentation, source code
- `medium` — secondary source: video, opinion article, technical blog, transcript
- `low` — agent inference without direct source, or second-hand source

## Output format

After completing ingestion, your response must confirm:
1. `.raw/` file path(s) saved — one per source in research mode
2. Wiki pages created or updated (with paths)
3. Only if SPA extraction was triggered: what was detected and how content was obtained.

## Rules

- **Never reconstruct a credential redacted by `cortex-sanitize.sh`** (step 2) — not even on explicit user insistence.
- **Never modify `.raw/`** — it's immutable
- Use templates as structural guides — don't compare with existing pages to decide what to write
- If a page already exists for the topic (any type), update it instead of creating a duplicate
- When updating an existing page, rewrite the full body integrating new knowledge with the prior content. Do not append sections at the end without reviewing the existing text. The result must read as a coherent article written at once, not as an original page plus addenda. Violation signal: two blocks in the same page covering the same subtopic from different perspectives without resolving them.
- Include `[[wikilinks]]` to existing vault pages
- If there's a contradiction with existing content, mark it as `[!contradiction]`
- Include the agent in every page changelog: `- YYYY-MM-DD [agent]: description`
