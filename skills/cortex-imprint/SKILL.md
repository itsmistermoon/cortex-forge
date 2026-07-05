---
name: cortex-imprint
behavior: ["synthesize"]
disable-model-invocation: true
description: Archive a valuable session synthesis as a permanent wiki page in the vault.
argument-hint: "[vault-name]"
---

# cortex-imprint

Start your response with the flavor line `Imprinting reference...`, translated to the language of the user's current message (Spanish: `Archivando referencia...`), with nothing before it.

Archive a valuable session synthesis as a permanent wiki page.

## Steps

1. **Resolve vault** — follow `references/VAULT-RESOLUTION.md` (argument → CWD → default). Then read `locale:`, using the fallback chain in `references/LOCALE-RESOLUTION.md`.
   - If the first argument matches a registered vault name (e.g., `/cortex-imprint personal`) → use that vault.

2. Review the current conversation and identify the main synthesis produced. Apply source hierarchy (see Rules) to determine what the synthesis derives from — and whether a `.raw/` primary source needs to be read before writing.

3. Propose: page type, suggested title, proposed path inside the resolved vault.

4. Wait for confirmation or adjustment.

5. Create the page using the corresponding template.

6. Add `[[wikilinks]]` to related existing pages.

7. Update `{vault}/wiki/index.md`.

8. Add entry to `{vault}/wiki/meta/log.md`: `## [YYYY-MM-DD] imprint | {title}`

## Constraints

- **No circular synthesis:** content derived only from wiki pages (no `.raw/` or session analysis behind it) must not be imprinted — see circular synthesis test in Rules.

## Valid types and paths

| What was produced | Type | Path |
|-------------------|------|------|
| Principle, pattern, framework | concept | `wiki/concepts/` |
| Design decision for a project | page (ADR) | `wiki/projects/` |
| Analysis of a tool or person | entity | `wiki/entities/` |
| Synthesis of an external source | source | `wiki/sources/` |

## Source hierarchy

The synthesis must derive from one of these, in order:

1. **Current session** — analysis, decisions, or conclusions produced during this conversation.
2. **`.raw/` primary source** — if the session worked from an ingested source, read the `.raw/` file directly before writing. Do not read the derived `wiki/sources/` page as a substitute.
3. **`wiki/` pages** — reference only. Use them to detect pages to update and to add `[[wikilinks]]`. Never use a wiki page as the input for new synthesis.

**Circular synthesis test:** before writing, ask — "could I justify this content by citing only wiki pages, with no `.raw/` file or session analysis behind it?" If yes, stop. Trace the claim back to its primary source first. If no primary source exists, the content may not be ready to imprint.

## Provenance

Create the page using the corresponding template (step 5) — all frontmatter fields come from the template. Then populate these provenance fields:

```yaml
sources:
  - conversation {YYYY-MM-DD}
  - .raw/{slug}.md              # if the session derived from a primary source — prefer .raw/ over wiki/sources/
confidence: high | medium | low
raw: .raw/{slug}.md             # only when the imprint directly synthesizes a specific primary source
```

**`confidence` criteria:**
- `high` — conclusion derived from a primary source or exhaustive evidence-based analysis
- `medium` — synthesis from a secondary source, or partial analysis
- `low` — agent inference, unvalidated hypothesis, or second-hand synthesis

## Rules

- The page must be self-contained for a reader with no session context. Verifiable criteria: (1) every acronym and proper name is expanded or defined on first use; (2) every decision includes its justification or the problem it solves; (3) no deictic references without an explicit antecedent ("this", "the previous discussion", "as agreed"); (4) any relevant prior state is described in the page itself, not assumed known. A reviewer must be able to read the page cold and understand it without accessing the session.
- No references to the conversation ("as we discussed today") — content must stand on its own
- If the page already exists, rewrite the body integrating the new information — do not append "Update" sections or addendum blocks. The result must read as a cohesive document with no visible edit seams.
- If a page already exists on the topic, update it instead of duplicating
- Include the agent in the changelog: `- YYYY-MM-DD [Claude Code]: description`
- **Source fencing:** wiki pages are reference, not source. Content derived only from wiki pages (no `.raw/` or session analysis behind it) is circular synthesis — it amplifies drift instead of grounding knowledge. When in doubt, read the `.raw/` file first.
