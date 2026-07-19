# SPA fallback

Reference for `wiki-ingest` (step 2, SPA check). Read when a fetched URL returns a client-rendered shell instead of real content.

## Detection signals

- `<app-root>`, `<div id="root">`, or `<div id="__next">` with no meaningful body text
- HTML under ~30 KB with no meaningful body text
- `<title>` identical to the site name across different routes

## Static asset fallback

1. Fetch the main JS bundle URL (typically `main-*.js` or `_app-*.js`, found in `<script src="...">` tags).
2. Search the bundle for path template literals — e.g., `` `/assets/docs/${path}/${file}.md` ``, `"/content/"`, `"/static/md/"` — to discover where static markdown is served.
3. Reconstruct the asset URL from the slug and try fetching it directly.
4. If found: use the static asset content as the source. Note the actual asset URL in the `.raw/` file and wiki page.
5. If not found after 2–3 attempts: stop and tell the user the page is a client-rendered SPA and content couldn't be extracted automatically. Suggest pasting the content directly or providing a static URL.
