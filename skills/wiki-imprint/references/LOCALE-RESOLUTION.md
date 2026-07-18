# Locale resolution

Reference for skills that write persistent content to the vault. Read when a step says "locale resolution — see LOCALE-RESOLUTION.md".

Skills that generate content stored in the vault must write it in the vault's own language, not default to the agent's training language or whatever language the current conversation happens to be in — content written today is read by a different agent, in a different session, possibly in a different language, later. Getting this wrong means a vault silently accumulates mixed-language pages that degrade retrieval and readability over time.

## Fallback chain

Read `locale:` from the vault's entry in `~/.cortex-forge/config.yml`. Use it for all agent-generated content.

If absent, apply in order:
1. `.hot/HANDOFF.md` title line — look for `— locale: {lang}` in the first heading
2. Default: `en`

Use the first value found. Stop at the first match — do not continue down the chain.
