# cortex-imprint

Archive a valuable session synthesis as a permanent wiki page.

## When to invoke

Only when the user explicitly invokes `/cortex-imprint`. Never invoke automatically — the user decides what's worth persisting.

Typical cases:
- A comparative analysis produced a non-obvious conclusion
- A design decision was grounded and documented
- A conversation revealed a pattern or principle worth consulting later
- A query answered something useful for future sessions

## Flow

1. Review the current conversation and identify the main synthesis produced
2. Propose: page type, suggested title, proposed path
3. Wait for confirmation or adjustment
4. Create the page using the corresponding template
5. Add `[[wikilinks]]` to related existing pages
6. Update `wiki/index.md`
7. Add entry to `wiki/meta/log.md`: `## [YYYY-MM-DD] imprint | {title}`

## Valid types and paths

| What was produced | Type | Path |
|-------------------|------|------|
| Principle, pattern, framework | concept | `wiki/concepts/` |
| Design decision for a project | page (ADR) | `wiki/pages/` |
| Analysis of a tool or person | entity | `wiki/entities/` |
| Synthesis of an external source | source | `wiki/sources/` |

## Provenance

Always populate in the created page:

```yaml
sources:
  - conversation {YYYY-MM-DD}
  - wiki/sources/{slug}.md      # if the session worked on a concrete source
confidence: high | medium | low
```

**`confidence` criteria:**
- `high` — conclusion derived from a primary source or exhaustive evidence-based analysis
- `medium` — synthesis from a secondary source, or partial analysis
- `low` — agent inference, unvalidated hypothesis, or second-hand synthesis

## Rules

- The page must be durable — write it as if it will be read in 6 months without session context
- No references to the conversation ("as we discussed today") — content must stand on its own
- Compiled truth: write in full, not in patches
- If a page already exists on the topic, update it instead of duplicating
- Include the agent in the changelog: `- YYYY-MM-DD [Claude Code]: description`
