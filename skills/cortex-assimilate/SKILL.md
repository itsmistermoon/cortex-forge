---
name: cortex-assimilate
behavior: [#ingest, #synthesize]
description: Ingest a URL or file into the vault — saves to .raw/, synthesizes wiki pages, updates index. Use --research "<query>" to auto-discover and ingest sources from the web.
argument-hint: "[vault-name] <url-or-file> | --research \"<query>\" [--rounds N]"
---

# cortex-assimilate

Begin your response by outputting exactly: `Assimilating source...`

Ingest a new source and synthesize wiki pages from it.

## --research mode

If the argument starts with `--research`, enter research mode instead of the normal URL/file flow:

```
/cortex-assimilate --research "embeddings for second brains" [--rounds 3]
```

**Steps:**

1. **Detect Firecrawl** — run `firecrawl --status 2>/dev/null`. If available and authenticated, use it for all search and scrape steps below. If not available, fall back to `WebSearch` + `WebFetch` natively — the skill works without Firecrawl, it just gets richer content with it. Never block on Firecrawl absence.

2. **Round 1 — broad search**
   - With Firecrawl: `firecrawl search "<query>"` — returns full page content, top 5–8 URLs.
   - Without: `WebSearch "<query>"` — collect top 5–8 result URLs, then `WebFetch` each.
   Show the user: "Found N sources (via firecrawl|websearch). Searching deeper..."

3. **Round 2 — focused search** — identify 2–3 sub-topics or terms that appeared in round 1 results but weren't in the original query. Search for each. Add new URLs not already collected. Cap total at 12.

4. **Optional round 3** — only if `--rounds 3` was specified, or if round 2 revealed a significant knowledge gap.

5. **Scrape each URL**
   - With Firecrawl: `firecrawl scrape <url> -o .firecrawl/<slug>.md`
   - Without: `WebFetch <url>` — content goes directly to synthesis without saving locally.
   Skip URLs that fail or return empty content.

6. **Cross-reference for contradictions** — before synthesizing, read all scraped files and identify claims that directly conflict across sources. For each conflict, prepare a `[!contradiction]` callout:
   ```
   > [!contradiction]
   > **Claim:** <the conflicting claim>
   > **Source A** ([title](url)): <what it says>
   > **Source B** ([title](url)): <what it says>
   > **Notes:** <any contextual explanation if evident>
   ```

7. **Synthesize** — treat all scraped files as the input source and run the normal synthesis pipeline (steps 5–7 below). Each scraped URL gets its own `wiki/sources/` entry. Contradiction callouts are embedded in the relevant concept or synthesis page.

8. **Report** — list all sources ingested, pages created/updated, and any contradictions found.

**Budget defaults:** 2 rounds, max 12 URLs. User can override with `--rounds N`.

---

## Steps

1. **Resolve vault** — read `~/.cortex-forge/config.yml`:
   Also read `locale:` from the vault's entry — use it for all agent-generated content. Fallback if absent: `.cortex/MEMORY.md` title line (`— locale: {lang}`) → `AGENTS.md` Vault identity (`**locale**:`) → default `en`.

   - If the first argument matches a registered vault name (e.g., `/cortex-assimilate second-brain <url>`) → use that vault; treat the remaining argument as the URL or file path.
   - Otherwise: check if CWD is inside any registered vault → use that vault.
   - If not, use the `default` vault.
   - If no default and multiple vaults → ask the user to pick one.
   - If no vaults registered → stop and prompt to run `/cortex-forge-setup`.

2. If `{vault}/CODEX.md` exists, read **Domains**, **Out of scope**, **Mission**, and **Vocabulary**:
   - If the source falls under **Out of scope**, stop and tell the user — do not ingest.
   - If the source domain is not in **Domains**, flag it before proceeding.
   - Use **Vocabulary** when naming pages and writing content.

3. **Receive input** — URL or `.raw/` file path.

4. **Download or read**:
   - URL → fetch content. Before saving, run **SPA detection** (step 3a). Then save to `{vault}/.raw/{slug}.md` (never overwrite if exists).
   - `.raw/` file → read directly.

   **3a. SPA detection and static asset fallback**

   After fetching a URL, check if the response is a rendered SPA shell with no real content:
   - Signals: `<app-root>`, `<div id="root">`, `<div id="__next">`, HTML under ~30 KB with no meaningful body text, or `<title>` identical to the site name across different routes.

   If SPA detected:
   1. Fetch the main JS bundle URL (typically `main-*.js` or `_app-*.js`, found in `<script src="...">` tags).
   2. Search the bundle for path template literals — e.g., `` `/assets/docs/${path}/${file}.md` ``, `"/content/"`, `"/static/md/"` — to discover where static markdown is served.
   3. Reconstruct the asset URL from the slug and try fetching it directly.
   4. If found: use the static asset content as the source. Note the actual asset URL in the `.raw/` file and wiki page.
   5. If not found after 2–3 attempts: stop and tell the user that the page is a client-rendered SPA and content couldn't be extracted automatically. Suggest pasting the content directly or providing a static URL.

   **⚠ Do NOT proceed to step 4 until step 3/3a is resolved and you have readable content.**
   Saving an HTML shell with no body text to `.raw/` is a protocol violation.
   If in doubt whether content is readable: paste the first 200 characters and ask yourself "would a reader understand anything from this?" — if no, run SPA detection.

   **4a. Sanitization check** — before saving to `.raw/`, scan the content for injection and exfiltration vectors:

   Run `bash {vault}/bin/cortex-sanitize.sh <temp-file>` and inspect the JSON output.

   If `findings` is non-empty:
   - List each finding to the user (type, label, count)
   - Ask: "This content has [N] findings (see above). Proceed with ingestion?" Default is **yes** — findings don't block, they inform.
   - If the user declines, stop and do not save to `.raw/`.
   - If the user accepts, save to `.raw/` as normal and note the findings in the source page's changelog.

   If `rg` is not available or the script errors: skip the check silently (fail-open).

5. **Synthesize** — determine what to create (see criteria below) and create pages at the correct path inside the resolved vault.

6. Update `{vault}/wiki/index.md` with new pages.

7. **Re-index embeddings** — if `{vault}/.cortex/vault.db` exists, run:
   ```
   python {vault}/.cortex/cortex-index.py {vault}
   ```
   Report the result inline: "Indexed N new chunk(s)." If `.cortex/vault.db` does not exist, skip silently — the vault may not have semantic search enabled.

8. **Project linking** — check `{vault}/wiki/pages/` for active projects whose `domains:` match the source; propose the update before writing.

## When to invoke

Invoke automatically when the user provides new content in any of these forms:
- "new ingest {url or file}"
- "process {url or file}"
- "add / include {source}"
- URL provided directly (no additional context)
- File name visible in `.raw/` that has no wiki page yet

## Types, paths, and templates

| Type | Path | Template |
|------|------|----------|
| **Source** | `wiki/sources/` | `templates/source.md` |
| **Concept** | `wiki/concepts/` | `templates/concept.md` |
| **Entity** | `wiki/entities/` | `templates/entity.md` |
| **Project** | `wiki/pages/` | `templates/project.md` |
| **Reference** | `wiki/reference/` | `templates/reference.md` |

## Reference criteria

**Create** if:
- The content is primarily a table, wire format, code block, or checklist
- The user will scan it to find a specific value, not read it to understand an idea
- Examples: hook wire formats per agent, detection signals, syntax cheat sheets, configuration schemas

**Skip** if:
- The topic needs prose explanation to be useful → create a Concept instead
- It's a one-off lookup that won't be consulted again

## Concept criteria

**Create** if:
- Has a proper name (principle, pattern, framework, technique, idea with identity)
- Can be applied or referenced in future sessions
- Warrants its own article to be understood (not just a passing example)

**Skip** if:
- It's a concrete instance or example, not the concept itself
- A wiki page already exists for that concept — update instead of duplicating
- Too generic to add value as a separate page

## Entity criteria

**Create** if:
- Person, organization, tool, or service with its own identity in the vault
- Appears in more than one context, or has an active role in the user's projects

**Skip** if:
- Mentioned in passing with no role of its own
- A wiki page already exists for that entity — update instead of duplicating

## Project criteria

Only create if it's an active project (with a repo, status, and its own decisions).
Do not create project pages for third-party projects mentioned only as context.

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
1. `.raw/` file path saved
2. Wiki pages created or updated (with paths)
3. If and only if the page was detected as a SPA and required alternative extraction: report what was detected and how content was obtained. If the page delivered content normally, omit any mention of SPA detection.

## Rules

- **Never modify `.raw/`** — it's immutable
- Always create a `wiki/sources/` page per processed source
- Use templates as structural guides — don't compare with existing pages to decide what to write
- If a page already exists for the topic, update it instead of creating a duplicate
- When updating an existing page, rewrite the full body integrating new knowledge with the prior content. Do not append sections at the end without reviewing the existing text. The result must read as a coherent article written at once, not as an original page plus addenda. Violation signal: two blocks in the same page covering the same subtopic from different perspectives without resolving them.
- Include `[[wikilinks]]` to existing vault pages
- If there's a contradiction with existing content, mark it as `[!contradiction]`
- Include the agent in every page changelog: `- YYYY-MM-DD [Claude Code]: description`

## Changelog

- 2026-06-24 [Claude Code]: Reformulated "compiled truth" rule into a verifiable rewrite contract with a concrete violation signal (no-op audit)
