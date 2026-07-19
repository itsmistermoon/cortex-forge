---
name: wiki-recall
license: MIT
description: Answer questions from the vault wiki as the source of truth — never training knowledge — with page citations.
disable-model-invocation: true
argument-hint: "[vault-name] <query>"
---

# wiki-recall

Start your response with the flavor line `Recalling memory...`, translated to the language of the user's current message (Spanish: `Recuperando memoria...`), with nothing before it. Use that same language for every prompt, question, menu, and confirmation this skill produces.

Answer a question using the vault's wiki content as the source.

## Available scripts

Paths are relative to this skill's directory.

- **`scripts/search.py`** — Semantic search over `.hot/db/vault.db` (step 2)
- **`scripts/embeddings.py`** — Shared embedding backend, imported by `search.py`; not invoked directly

## Steps

1. **Resolve vault** — per `~/.cortex-forge/references/VAULT-RESOLUTION.md` (synced by `/wiki-setup` — if missing, run `/wiki-setup` first). If the first argument matches a registered vault name (e.g., `/wiki-recall second-brain <query>`), use that vault; treat the remaining text as the query.

2. **Identify relevant pages** — prefer semantic search if the index is available:
   - If `{vault}/.hot/db/vault.db` (canonical) or `{vault}/.hot/vault.db` (legacy) exists: run `scripts/search.py --vault {vault} "{query}" --top-k 8 --json`, and use the returned chunks (path + heading + content) as the primary source set.
   - Otherwise (index missing): read `{vault}/wiki/index.md` directly and identify the most relevant pages by title and description. This is the explicit fallback — it is NOT a protocol violation.

3. **Answer** — read the full page for any result where the chunk alone is insufficient, then synthesize a response with citations to specific pages. If information is missing, point to `/wiki-ingest` for the missing sources, and append one line to `{vault}/wiki/meta/log.md`: `**[YYYY-MM-DD] recall-miss** | {query}`. Log misses only — a query that gets a real answer leaves no trace here.

4. **Offer to persist, rarely** — only when the answer combines two or more existing pages into an insight not written down anywhere in the vault, or fills a real gap the wiki had no page for, end the response with one line: "This isn't written anywhere in the vault yet — want me to save it? (`/wiki-imprint`)". Skip this for anything answerable by pointing at a single existing page — the offer must stay rare, not a footer on every response. `wiki-imprint` is user-invoked only: acceptance means telling the user to run it (now or later) — it will treat this answer as the source content.

## Output format

Every response must include:
1. At least one citation in the form `Source: wiki/{type}/{slug}.md [confidence: {value}]`, where `{value}` is read directly from the page's YAML frontmatter `confidence:` field.
   - No `confidence:` field → append `[confidence: unset]` and flag it as a finding.
   - Malformed YAML → append `[confidence: read-error]` and flag it.
   - `confidence: medium` or `low` → append the value, do not flag — these are valid states.
2. If no relevant pages exist: state "Not in vault" explicitly — do not fall back to training knowledge.

## Constraints

- **Parametric knowledge is disqualified** for any topic this vault may cover. What you know from training is unverified — the vault is the source of truth. Even if you believe you already know the answer, run the steps anyway.
- **Never bypass this skill** by using `grep`, `find`, `Explore`, or direct file reads to answer a vault-covered query. That is a protocol violation regardless of the search method.

## Rules

- If there are contradictions between pages, flag them
