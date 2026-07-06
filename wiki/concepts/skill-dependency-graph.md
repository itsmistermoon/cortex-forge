---
title: skill dependency graph
type: concept
created: 2026-06-30
updated: 2026-07-06
tags: [cortex-forge/skills, skills, architecture, dependency, data-flow]
aliases: [skill contracts, skill data flow, cortex-forge dependencies]
sources:
  - conversation 2026-06-30
confidence: high
schema_version: "0.3"
---

# skill dependency graph

Maps what each Cortex Forge skill produces and what it consumes — the contracts that must hold for the suite to work correctly.

## Dependency map

```
cortex-forge-setup
       │
       └── prerequisite for ALL skills (vault registration, opt-in post-commit git hooks)
       
cortex-assimilate
       │
       ├── produces → .raw/{slug}.md          consumed by: cortex-imprint, cortex-prune
       ├── produces → wiki/{type}/{slug}.md   consumed by: cortex-recall, cortex-prune
       └── produces → wiki/index.md (updated) consumed by: cortex-recall

cortex-recall
       │
       ├── consumes ← wiki/ pages             produced by: cortex-assimilate, cortex-imprint
       └── on gap   → suggests /cortex-assimilate (step 6)

cortex-crystallize
       │
       └── produces → .cortex/MEMORY.md
                         └── #### Imprint candidate → surfaced by AGENTS.md's mandatory read protocol → consumed by: cortex-imprint

cortex-imprint
       │
       ├── consumes ← session synthesis + .raw/ files  produced by: cortex-assimilate
       └── produces → wiki/{type}/{slug}.md            consumed by: cortex-recall, cortex-prune

cortex-prune
       │
       ├── validates ← .raw/ files            produced by: cortex-assimilate
       ├── validates ← wiki/ pages            produced by: cortex-assimilate, cortex-imprint
       └── produces  → wiki/meta/vault-report.json  consumed by: cortex-crystallize (vault health triage → ### Pending)
```

## Contracts per dependency

### forge-setup → all skills
Every skill resolves the vault from `~/.cortex-forge/config.yml`, which setup writes. If the vault is not registered, all skills stop at step 1. Setup also offers opt-in post-commit git hooks (prune refresh, embedding reindex) — separate from, and simpler than, agent lifecycle hooks, which cortex-forge does not use. `cortex-crystallize` is invoked manually, never automatically.

### assimilate → recall
assimilate writes `wiki/` pages that recall searches. recall's semantic index (`.cortex/db/vault.db`) is built from those pages. If assimilate skips updating `wiki/index.md`, recall's fallback path (index traversal) misses the new page. **Contract:** assimilate must update `wiki/index.md` on every successful ingestion.

### assimilate ↔ recall (gap loop)
When recall finds no vault coverage for a topic, step 6 explicitly suggests running `/cortex-assimilate`. This is the vault's growth loop: gaps surface through recall, get filled by assimilate, become queryable again through recall. Neither skill enforces the loop — the user drives it.

### assimilate → prune
prune layer 1 (structural script) checks:
- `.raw/` files with no corresponding `wiki/sources/` page → assimilate that ran but didn't synthesize
- wiki pages with dead `[[wikilinks]]` → assimilate that created references to pages that don't exist yet
- wiki pages with no incoming links → assimilate that didn't update the graph correctly

If assimilate produces incomplete output (network error mid-ingestion, missing synthesis step), prune is the detection mechanism. **There is no automatic repair** — prune flags, the user decides.

### crystallize → imprint (via imprint candidate)
crystallize writes `#### Imprint candidate` entries in `.cortex/MEMORY.md` when a session produces something worth permanent archiving. `AGENTS.md`'s mandatory session-start read protocol instructs the agent to check the latest History entry for this flag and propose running `/cortex-imprint`. imprint then reads the synthesis from the session and writes a permanent `wiki/` page.

The handoff is passive: crystallize does not call imprint, and imprint does not read MEMORY.md directly. `AGENTS.md`'s read protocol is the bridge — every agent reads `.cortex/MEMORY.md` before its first response, identically, with no hook wiring required. If an agent skips that mandatory read (a protocol violation, not an opt-out), the nudge never fires — imprint candidates accumulate silently in MEMORY.md.

### imprint → recall
imprint writes permanent `wiki/` pages into the same directory tree that recall searches. A successful imprint immediately expands recall's coverage without requiring a new assimilate run. **Contract:** imprint must update `wiki/index.md` on every successful write (step 8 of cortex-imprint).

### prune → crystallize → AGENTS.md (via vault-report.json)
prune produces `wiki/meta/vault-report.json` with this schema:

```json
{
  "generated": "YYYY-MM-DD",
  "health": {
    "dead_links": [],
    "raw_without_source_page": [],
    "missing_confidence": [],
    "orphan_pages": []
  }
}
```

`cortex-crystallize`'s vault-health-triage step reads this file and writes a `### Pending` item in `.cortex/MEMORY.md` whenever any field is non-empty; `AGENTS.md`'s mandatory session-start read then surfaces it to the agent as part of the normal Pending read — there is no longer a direct AGENTS.md read of the JSON file (removed 2026-07-06, redundant with the Pending item crystallize already writes). **If the schema changes in cortex-prune without updating `cortex-crystallize`**, the triage step reads wrong field names silently. This is the only cross-skill contract where a format change in one skill corrupts a consumer that is not itself a skill.

## Failure modes by dependency

| Broken dependency | Symptom | Detectable by |
|---|---|---|
| forge-setup not run | All skills stop at vault resolution step 1 | Immediate, loud |
| assimilate skips index update | recall misses new pages via index fallback | cortex-prune (orphan detection) |
| assimilate incomplete (mid-run failure) | `.raw/` file exists, no wiki page | cortex-prune layer 1 |
| Agent skips AGENTS.md's mandatory read protocol | Imprint candidates accumulate, no nudge | Manual inspection of MEMORY.md |
| imprint skips index update | recall misses imprinted pages | cortex-prune (orphan detection) |
| prune schema change, cortex-crystallize not updated | Vault-health triage reads wrong field names silently | No automatic detection |

## Related

- [[wiki/concepts/crystallize-vs-imprint]] — design boundary between the two session-end skills
- [[wiki/concepts/memory-system]] — broader context on stateful agents
- [[wiki/concepts/workflow-architecture]] — session flow: hooks, skills, scripts
