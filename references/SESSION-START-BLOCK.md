# Session-start block

Shared reference for `hot-handoff`, `hot-triage`, and `wiki-setup`. The canonical text of the AGENTS.md instruction that makes agents auto-load `.hot/HANDOFF.md` at session start. Without it, handoffs are written but never read back — this block is what turns `.hot/` into memory instead of a log.

Keep the copy embedded in `templates/AGENTS-vault.md` in sync with this file — the template can't reference this file because it ships verbatim to end-user vaults.

## The block

Append verbatim (marker comments included — they're how the skills detect the block is already present):

```markdown
<!-- antu:session-start -->
## Session start

Before your first response, in any session that starts in this repo, you MUST read `.hot/HANDOFF.md` in full — and `.hot/PLAYBOOK.md` too, if it exists. Treat them with the same weight as your own persistent instructions. If `.hot/` doesn't exist yet, continue normally.
<!-- /antu:session-start -->
```

## Rules

- **Detection**: the block counts as present if `AGENTS.md` contains the `<!-- antu:session-start -->` marker, or an equivalent instruction to read `.hot/HANDOFF.md` at session start written by the user in their own words — don't append a duplicate next to a hand-written equivalent.
- **Append-only**: add the block at the end of an existing `AGENTS.md`. Never rewrite, reorder, or edit the rest of the file — it's the user's.
- **No AGENTS.md at all**: create one containing only a `# AGENTS.md` title line and this block.
- **Always ask first**: appending to (or creating) `AGENTS.md` requires explicit confirmation, every time, from every skill that uses this reference.
