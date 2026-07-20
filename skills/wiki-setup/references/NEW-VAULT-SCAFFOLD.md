# New vault scaffold

Reference for `wiki-setup` step 1. Read when the vault-candidate check finds `wiki/` and/or `AGENTS.md` missing from the current directory, or an existing `AGENTS.md` without the Antu session-start block (see the dedicated section below).

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

1. **`wiki/` structure**: `mkdir -p wiki/{concepts,entities,sources,projects} meta`. `meta/` is a sibling of `wiki/`, not nested inside it (ADR 0005, decision 4).
2. **`meta/tags.md`**: copy from `templates/tags.md` (fetched the same way step 3b fetches other templates — see `references/UPSTREAM-SYNC.md`) if missing.
3. **`wiki/index.md`**: create with frontmatter declaring `okf_version: "0.1"` (the only frontmatter `index.md` is permitted, per OKF §11), followed by a minimal header (`# {vault-name}`, one line noting it's the master index) and empty `## Concepts` / `## Entities` / `## Sources` / `## Projects` sections — the first `/wiki-ingest` or `/wiki-imprint` run populates it further.
4. **`AGENTS.md`**: copy from `templates/AGENTS-vault.md` (fetched the same way step 3b fetches other templates — see `references/UPSTREAM-SYNC.md`), replacing `{vault-name}` with the vault name. That template is the single definition of the minimal vault AGENTS.md — session-start block, vault working rules, and a "Vault identity" placeholder. Never substitute this repo's own root `AGENTS.md`: that one is production configuration for developing the suite, not for running it. Do not invent owner, locale, or vocabulary content for "Vault identity" — those are personal to the vault; locale is asked and written separately in step 3/3a.

5. Continue the normal new-vault flow from step 2 (read/write config) onward — step 3b then syncs `templates/*.md` (including `templates/tags.md`) the same way it would for any vault.

## Existing AGENTS.md without the Antu block

Read this section when step 1 finds an existing `AGENTS.md` that doesn't tell agents to read `.hot/HANDOFF.md` at session start — i.e. it lacks the `<!-- antu:session-start -->` marker **and** has no equivalent instruction the user wrote in their own words (if either is present, skip silently — never double-append). Without that instruction, `.hot/HANDOFF.md` is written but never auto-loaded, so handoffs don't work as memory. The file is the user's — never rewrite or reorder it. Offer a single append:

```text
Your AGENTS.md doesn't tell agents to read .hot/HANDOFF.md at session start,
so handoffs won't be picked up automatically. Append the minimal Antu block
(session-start instruction + vault working rules) at the end?

  1. Yes, append it
  2. No, I'll manage AGENTS.md myself
```

On confirmation, append verbatim from `templates/AGENTS-vault.md`: only the `<!-- antu:session-start -->` and `<!-- antu:vault-rules -->` blocks (markers included) — no title line, no "Vault identity" placeholder. On decline, continue setup and note in the final summary that handoff auto-loading stays off until the instruction exists.

If the marker (or an equivalent) is already present, skip silently — nothing to offer.

## Rules

- Never scaffold silently — the confirmation above is mandatory, not a default-yes.
- Never touch an existing `wiki/` or `AGENTS.md`, even partially — if either already exists, skip creating it and only scaffold what's genuinely absent.
- The `AGENTS.md` stub is intentionally minimal — it is not a substitute for a human reading `README.md`'s Quickstart and customizing "Vault identity" themselves.
- Appending the Antu block to an existing `AGENTS.md` is append-only and confirmation-gated — the two marked blocks at the end, nothing edited above them.
