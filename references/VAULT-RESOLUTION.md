# Vault resolution

Reference for skills that need to identify which vault to operate on. Read when a step says "Resolve vault — see VAULT-RESOLUTION.md".

## Fallback chain

Read `~/.almagest/config.yml`. Config format: `vaults: {name: {path, locale}, ...}` + `default: name`.

Apply in order:
1. If the first argument matches a registered vault name → use that vault.
2. Otherwise: check if CWD is inside any registered vault (CWD starts with a vault path) → use that vault.
3. If not, use the `default` vault.
4. If no default is set and exactly one vault is registered → use that vault.
5. If no default and multiple vaults are registered → ask the user to pick one.
6. If no vaults registered → stop and prompt to run `/wiki-setup`.

## Validate vault structure

After resolving the vault path, confirm it is a valid Antu vault: the path must contain both `wiki/` and `AGENTS.md`. If either is missing, stop and tell the user the resolved path does not look like an Antu vault — do not proceed to read `AGENTS.md` fields or attempt any vault operation.
