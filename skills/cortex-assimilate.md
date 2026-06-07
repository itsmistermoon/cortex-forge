# cortex-assimilate

Ingest a new source and synthesize wiki pages from it.

## When to invoke

Invoke automatically when the user provides new content in any of these forms:
- "new ingest {url or file}"
- "process {url or file}"
- "add / include {source}"
- URL provided directly (no additional context)
- File name visible in `.raw/` that has no wiki page yet

## Input modes

### URL mode
1. Download content from the URL
2. Save to `.raw/{slug}.md` (never overwrite if already exists)
3. Continue with synthesis flow

### `.raw/` file mode
1. Read the indicated file in `.raw/`
2. Continue with synthesis flow

## Synthesis flow

1. Read the source content
2. Determine what to create (see criteria below)
3. For each piece: use the corresponding template as a structural guide
4. Create pages at the correct path
5. Update `wiki/index.md` with new pages
6. **Project linking** — see section below

## Types, paths, and templates

| Type | Path | Template |
|------|------|----------|
| **Source** | `wiki/sources/` | `templates/source.md` |
| **Concept** | `wiki/concepts/` | `templates/concept.md` |
| **Entity** | `wiki/entities/` | `templates/entity.md` |
| **Project** | `wiki/pages/` | `templates/project.md` |

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

## Project linking

After completing the synthesis, check whether the source is relevant to any active project:

1. Read `domains:` from each `wiki/pages/` file with `status: active`
2. Compare against the source's content and tags
3. If there's a match, **propose** the update to the user — never write without confirmation

The proposal must include:
- Which project matches and why
- Which section of `wiki/pages/{project}.md` would be updated ("Connections" or "Next steps")
- The exact text to be added

If the user confirms, add the link and update `updated:` in the project page.

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

For `source` type pages: `sources` points to the `.raw/` origin file (`[.raw/{slug}.md]`); `confidence` reflects the source medium.

## Rules

- **Never modify `.raw/`** — it's immutable
- Always create a `wiki/sources/` page per processed source
- Use templates as structural guides — don't compare with existing pages to decide what to write
- If a page already exists for the topic, update it instead of creating a duplicate
- Compiled truth is written in full, never accumulated in patches
- Include `[[wikilinks]]` to existing vault pages
- If there's a contradiction with existing content, mark it as `[!contradiction]`
- Include the agent in every page changelog: `- YYYY-MM-DD [Claude Code]: description`
