# Locale resolution

Disclosed reference for all Cortex Forge skills. Read when a step says "locale resolution — see LOCALE-RESOLUTION.md".

## Fallback chain

Read `locale:` from the vault's entry in `~/.cortex-forge/config.yml`. Use it for all agent-generated content.

If absent, apply in order:
1. `.cortex/MEMORY.md` title line — look for `— locale: {lang}` in the first heading
2. `AGENTS.md` Vault identity section — look for `**locale**:` field
3. Default: `en`

Use the first value found. Stop at the first match — do not continue down the chain.
