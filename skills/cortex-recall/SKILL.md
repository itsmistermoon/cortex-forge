---
name: cortex-recall
description: Answer a question using the vault's synthesized wiki content as the source of truth. Returns citations to specific pages.
---

# cortex-recall

Answer a question using the vault's wiki content as the source.

## Steps

1. **Resolve vault** — read `~/.cortex-forge/config.yml`:
   - Check if CWD is inside any registered vault (CWD starts with a `vaults:` path) → use that vault.
   - If not, use the `default` vault.
   - If no default and multiple vaults are registered → ask the user to pick one.
   - If no vaults registered → stop and prompt to run `/cortex-forge-setup`.

2. Read `{vault}/wiki/index.md` to identify relevant pages.

3. Read the relevant pages.

4. Synthesize a response with citations to specific pages.

5. If information is missing, suggest sources to ingest with `/cortex-assimilate`.

## Rules

- Cite wiki pages, not training knowledge
- If there are contradictions between pages, flag them
- If the topic is not in the wiki, say so explicitly
- Never answer from active session context alone — always go through the vault
