---
name: cortex-imprint
description: Archive a valuable session synthesis as a permanent wiki page in the vault.
---

# cortex-imprint

Archive a valuable session synthesis as a permanent wiki page.

## Steps

1. **Resolve vault** — read `~/.cortex-forge/config.yml`:
   - Check if CWD is inside any registered vault → use that vault.
   - If not, use the `default` vault.
   - If no default and multiple vaults → ask the user to pick one.
   - If no vaults registered → stop and prompt to run `/cortex-forge-setup`.

2. Review the current conversation and identify the main synthesis produced.

3. Propose: page type, suggested title, proposed path inside the resolved vault.

4. Wait for confirmation or adjustment.

5. Create the page using the corresponding template.

6. Add `[[wikilinks]]` to related existing pages.

7. Update `{vault}/wiki/index.md`.

8. Add entry to `{vault}/wiki/meta/log.md`: `## [YYYY-MM-DD] imprint | {title}`

## When to invoke

Only when the user explicitly invokes `/cortex-imprint`. Never invoke automatically — the user decides what's worth persisting.

Typical cases:
- A comparative analysis produced a non-obvious conclusion
- A design decision was grounded and documented
- A conversation revealed a pattern or principle worth consulting later
- A query answered something useful for future sessions

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
