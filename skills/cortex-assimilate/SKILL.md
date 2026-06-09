---
name: cortex-assimilate
description: Ingest a URL or file into the vault — saves to .raw/, synthesizes wiki pages, updates index.
argument-hint: "[vault-name] <url-or-file>"
---

# cortex-assimilate

Ingest a new source and synthesize wiki pages from it.

## Steps

1. **Resolve vault** — read `~/.cortex-forge/config.yml`:
   - If the first argument matches a registered vault name (e.g., `/cortex-assimilate second-brain <url>`) → use that vault; treat the remaining argument as the URL or file path.
   - Otherwise: check if CWD is inside any registered vault → use that vault.
   - If not, use the `default` vault.
   - If no default and multiple vaults → ask the user to pick one.
   - If no vaults registered → stop and prompt to run `/cortex-forge-setup`.

2. **Receive input** — URL or `.raw/` file path.

3. **Download or read**:
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

4. **Synthesize** — determine what to create (see criteria below) and create pages at the correct path inside the resolved vault.

5. Update `{vault}/wiki/index.md` with new pages.

6. **Project linking** — check `{vault}/wiki/pages/` for active projects whose `domains:` match the source; propose the update before writing.

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
3. Whether SPA detection ran and what was found

## Rules

- **Never modify `.raw/`** — it's immutable
- Always create a `wiki/sources/` page per processed source
- Use templates as structural guides — don't compare with existing pages to decide what to write
- If a page already exists for the topic, update it instead of creating a duplicate
- Compiled truth is written in full, never accumulated in patches
- Include `[[wikilinks]]` to existing vault pages
- If there's a contradiction with existing content, mark it as `[!contradiction]`
- Include the agent in every page changelog: `- YYYY-MM-DD [Claude Code]: description`
