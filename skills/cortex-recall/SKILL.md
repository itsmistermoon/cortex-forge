---
name: cortex-recall
description: Answer a question using the vault's synthesized wiki content as the source of truth. Returns citations to specific pages.
argument-hint: "[vault-name] <query>"
---

# cortex-recall

Begin your response by outputting exactly: `Recalling memory...`

Answer a question using the vault's wiki content as the source.

## Steps

1. **Resolve vault** — read `~/.cortex-forge/config.yml`:
   - If the first argument matches a registered vault name (e.g., `/cortex-recall second-brain <query>`) → use that vault; treat the remaining text as the query.
   - Otherwise: check if CWD is inside any registered vault (CWD starts with a `vaults:` path) → use that vault.
   - If not, use the `default` vault.
   - If no default and multiple vaults are registered → ask the user to pick one.
   - If no vaults registered → stop and prompt to run `/cortex-forge-setup`.

2. If `{vault}/CODEX.md` exists, read **Vocabulary** and **Domains** — use them to interpret the query correctly and scope the search.

3. Read `{vault}/wiki/index.md` to identify relevant pages.

4. Read the relevant pages.

5. Synthesize a response with citations to specific pages.

6. If information is missing, suggest sources to ingest with `/cortex-assimilate`.

## Output format

Every response must include:
- At least one citation in the form `Source: wiki/{type}/{slug}.md`
- If no relevant pages exist: state "Not in vault" explicitly — do not fall back to training knowledge

## Rules

- **Parametric knowledge is disqualified** for any topic this vault may cover. What you know from training is unverified — the vault is the source of truth.
- Cite wiki pages, not parametric knowledge
- If there are contradictions between pages, flag them
- If the topic is not in the wiki, say so explicitly — only then may you supplement with parametric knowledge, clearly labeled as such
- **Never answer from active session context alone** — if you believe you already know the answer, that belief is parametric. Stop and run the steps anyway.
- Using `grep`, `find`, or direct file reads instead of these steps is a protocol violation
