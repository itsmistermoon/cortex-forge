---
name: cortex-recall
behavior: ["recall"]
description: Answer a question using the vault's synthesized wiki content as the source of truth. Returns citations to specific pages.
argument-hint: "[vault-name] <query>"
---

# cortex-recall

Begin your response by outputting exactly: `Recalling memory...`

Answer a question using the vault's wiki content as the source.

## Steps

1. **Resolve vault** — read `~/.cortex-forge/config.yml`:
   Also read `locale:` from the vault's entry — use it for all agent-generated content. Fallback if absent: `.cortex/MEMORY.md` title line (`— locale: {lang}`) → `AGENTS.md` Vault identity (`**locale**:`) → default `en`.

   - If the first argument matches a registered vault name (e.g., `/cortex-recall second-brain <query>`) → use that vault; treat the remaining text as the query.
   - Otherwise: check if CWD is inside any registered vault (CWD starts with a `vaults:` path) → use that vault.
   - If not, use the `default` vault.
   - If no default and multiple vaults are registered → ask the user to pick one.
   - If no vaults registered → stop and prompt to run `/cortex-forge-setup`.

2. Read **Vocabulary** and **Domains** from `{vault}/AGENTS.md` (`## Vault identity` section) — use them to interpret the query correctly and scope the search.

3. **Identify relevant pages** — prefer semantic search if the index is available:
   - If `.cortex/db/vault.db` AND `.cortex/db/cortex-search.py` both exist: run `python {vault}/.cortex/db/cortex-search.py "{query}" --top-k 8 --json` and use the returned chunks (path + heading + content) as the primary source set.
   - Otherwise (index missing or script not installed): read `{vault}/wiki/index.md` directly and identify the most relevant pages by title and description. This is the explicit fallback — it is NOT a protocol violation.

4. Read the full pages for any result where the chunk alone is insufficient for a complete answer.

5. Synthesize a response with citations to specific pages.

6. If information is missing, suggest sources to ingest with `/cortex-assimilate`.

## Output format

Every response must include:
- At least one citation in the form `Source: wiki/{type}/{slug}.md [confidence: {value}]`
  where `{value}` is read directly from the page's YAML frontmatter `confidence:` field.
- If a cited page has no `confidence:` field, append `[confidence: unset]` and flag it as a finding.
- If the page cannot be parsed due to malformed YAML, append `[confidence: read-error]` and flag it.
- If `confidence: medium` or `low`, append the value and do not flag — these are valid states.
- If no relevant pages exist: state "Not in vault" explicitly — do not fall back to training knowledge

## Rules

- **Parametric knowledge is disqualified** for any topic this vault may cover. What you know from training is unverified — the vault is the source of truth.
- Cite wiki pages, not parametric knowledge
- If there are contradictions between pages, flag them
- If the topic is not in the wiki, say so explicitly — only then may you supplement with parametric knowledge, clearly labeled as such
- **Never answer from active session context alone** — if you believe you already know the answer, that belief is parametric. Stop and run the steps anyway.
- Using `grep`, `find`, `Explore`, or direct file reads to answer the query **instead of invoking this skill** is a protocol violation. The search method varies (semantic vector search when `.cortex/db/vault.db` is available, structured index traversal via `wiki/index.md` otherwise) — the prohibition on bypassing the skill does not. Reading `wiki/index.md` or specific wiki pages as part of steps 3–4 is not a violation — it is part of the skill.
