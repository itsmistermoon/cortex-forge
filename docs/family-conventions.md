# Family conventions: cortex-forge ↔ reflex

cortex-forge and [reflex](https://github.com/itsmistermoon/moon-reflex) are sibling vault suites — cortex-forge is the full-feature option (provenance, multi-vault, semantic search, planned MCP integration), reflex is the lite option (tabula-rasa rebuild, minimal dependencies, fast). See the README's "Full vs. lite" table for how to choose between them for a given vault.

They are **not** merged: reflex does not depend on or reference `cortex-*` skills, and cortex-forge does not depend on `reflex-*` skills. This document exists so that conventions the two suites happen to share stay in sync deliberately, instead of drifting apart or being re-discovered by accident.

## What belongs here

A convention that:
- is not specific to a feature only one suite has (e.g. multi-vault resolution is cortex-forge-only — it doesn't belong here)
- both suites currently follow, or should follow, for a vault built with either to feel consistent (log formats, timestamp formats, file naming patterns a human or agent might expect either way)

## Current shared conventions

- **Log entry format**: `**[YYYY-MM-DD]**` (bold, not a heading) for dated entries in append-only logs (`wiki/log.md` in reflex, changelog sections in cortex-forge wiki pages). Synced manually 2026-07-09 after reflex adopted cortex-forge's format.

## Adding a new convention

When you notice cortex-forge and reflex converging (or should converge) on some format, name, or structural choice:
1. Confirm it's genuinely cross-cutting, not a full-feature-only concern (see "What belongs here" above).
2. Add an entry to "Current shared conventions" describing the convention and the date it was formalized.
3. Update both suites to match, if one is currently out of sync.
4. If only one side needs to change, do that edit directly in that repo — this document doesn't require a synchronized PR across both repos, just a synchronized *record* of what the convention is.
