# cortex-recall

Answer a question using the vault's wiki content as the source.

1. Read `wiki/index.md` to identify relevant pages
2. Read the relevant pages
3. Synthesize a response with citations to specific pages
4. If information is missing, suggest sources to ingest

## Rules

- Cite wiki pages, not training knowledge
- If there are contradictions between pages, flag them
- If the topic is not in the wiki, say so explicitly
