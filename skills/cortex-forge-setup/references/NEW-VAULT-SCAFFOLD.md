# New vault scaffold

Reference for `cortex-forge-setup` step 1. Read only when the vault-candidate check finds `wiki/` and/or `AGENTS.md` missing from the current directory.

## When this applies

Step 1 requires `.git/`. A missing `wiki/`/`AGENTS.md` is ambiguous — it could mean a genuinely new, empty directory, or a vault that's broken/incomplete. Disambiguate before writing anything:

```text
This directory doesn't have {wiki/ and/or AGENTS.md}. Is this a new vault?
I'll create the empty wiki/ structure and a starter AGENTS.md, then continue setup.

  1. Yes, scaffold it
  2. No, this should already have content — stop
```

On "No" — stop and tell the user to resolve the discrepancy themselves (restore from backup, fix the path, etc.). Never scaffold over an ambiguous state without this confirmation.

## What gets created

Only what's missing — never overwrite an existing `wiki/` or `AGENTS.md`.

1. **`wiki/` structure**: `mkdir -p wiki/{concepts,entities,sources,projects,meta}`.
2. **`wiki/meta/tags.md`**: copy from `templates/tags.md` (fetched the same way step 3b fetches other templates — see `references/UPSTREAM-SYNC.md`) if missing.
3. **`wiki/index.md`**: create with a minimal header (`# {vault-name}`, one line noting it's the master index) and empty `## Concepts` / `## Entities` / `## Sources` / `## Projects` sections — the first `/cortex-assimilate` or `/cortex-imprint` run populates it further.
4. **`AGENTS.md`**: write a minimal starter — protocol skeleton only (Crystallize/Assimilate/Recall mandatory-invocation rules, the wiki taxonomy table, the skills list), matching the shape in `templates/concept.md`'s sibling vaults. Leave a clearly marked placeholder section for identity/vocabulary content that only the user can fill in:

   ```markdown
   ## Vault identity

   <!-- Fill in: owner, locale, domain-specific vocabulary if this vault has any (e.g. project-specific terms). Optional — delete this section if not needed. -->
   ```

   Do not invent an owner name, locale, or vocabulary — those are personal to the vault and this skill has no basis to guess them. Locale is asked and written separately in step 3/3a; this stub doesn't duplicate that.

5. Continue the normal new-vault flow from step 2 (read/write config) onward — step 3b then syncs `templates/*.md` (including `templates/tags.md`) the same way it would for any vault.

## Rules

- Never scaffold silently — the confirmation above is mandatory, not a default-yes.
- Never touch an existing `wiki/` or `AGENTS.md`, even partially — if either already exists, skip creating it and only scaffold what's genuinely absent.
- The `AGENTS.md` stub is intentionally minimal — it is not a substitute for a human reading `README.md`'s Quickstart and customizing "Vault identity" themselves.
