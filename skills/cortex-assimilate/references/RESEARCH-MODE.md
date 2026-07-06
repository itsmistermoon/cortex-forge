# Research mode

Reference for `cortex-assimilate`. Read when the first argument starts with `--research`, discovering and ingesting sources on the web instead of processing a single given URL or file.

```text
/cortex-assimilate --research "embeddings for second brains" [--rounds N]
```

**Budget:** 2 rounds, max 12 URLs. Override rounds with `--rounds N`.

## Steps

1. **Search in rounds** — round 1: broad search on the query. Round 2: search the 2–3 sub-topics that surfaced in round 1 but weren't in the query. Round 3 only if `--rounds 3` was given or round 2 revealed a significant knowledge gap. Tell the user what each round found.

2. **Fetch and save each URL** — use a specialized scraping tool if available (e.g., Firecrawl), otherwise fall back to regular search/fetch tools; never block on the absence of a specialized tool. For each URL, run it through step 2 of the normal pipeline (SPA check, sanitization check, save to `{vault}/.raw/{slug}.md`) — a scraped source is not exempt from either check. Skip URLs that fail or return empty content.

3. **Cross-reference** — where scraped sources directly conflict, prepare a `[!contradiction]` callout (**Claim** / **Source A** / **Source B** / **Notes**, with linked titles) to embed in the relevant page.

4. **Synthesize and report** — run steps 3–7 of the normal pipeline for each `.raw/` file saved above; each gets its own `wiki/sources/` entry. Report sources ingested, pages created/updated, and contradictions found.
