# wiki/meta/ — Directory guide

Vault metadata and operational records. Not knowledge — these files track what happened to the vault, not what the vault knows.

## Files

| File | Purpose | Writer |
|------|---------|--------|
| `log.md` | Append-only operation log — one entry per significant vault operation | Agent (on session close) |
| `vault-report.json` | Structural health snapshot — dead links, orphan pages, missing provenance | `cortex-prune.sh` (automated, co-located with the `cortex-prune` skill) |

## What goes here

- Operational records: what ran, when, what changed
- Diagnostic notes: what broke, how it was fixed
- Automated artifacts: vault-report.json

## What does NOT go here

- Knowledge synthesized from sources → `wiki/concepts/`, `wiki/entities/`, `wiki/sources/`
- Design decisions and ADRs → `wiki/projects/` (via `/cortex-imprint`)
- Active project state → `wiki/projects/`
- Session working memory → `.cortex/MEMORY.md` (not versioned)

## Log entry format

```
## [YYYY-MM-DD] {operation} | {one-line description}

{optional body — only when context is needed to interpret the entry later}

Agent: {agent name}
```

Operations: `ingest` · `imprint` · `prune` · `skill-improvement` · `refactor` · `fix` · `setup`
