# Maintenance mode

Reference for `wiki-setup` step 2. Read only when step 2 determines the vault is already registered — never loaded for a new-vault run. Covers the menu shown to the user and how steps 3–6 map to it, including the differences from the new-vault flow where any exist (steps 3, 3a, and 5).

Present this menu. The user can select one or more numbers (comma-separated), or "all":

```
Vault "{name}" is already registered. What would you like to do?

  1. Change locale       — update the vault's locale in config.yml
  2. Sync from upstream  — pull updated templates from the upstream repo
  3. Set stale-cache threshold — configure playbook_stale_days (global, applies to all vaults)
  4. Check skills        — verify all 7 are installed; points to `npx skills add` if not (that's the only installer now)
  5. Initialize semantic search — build .hot/db/vault.db for the first time (checks what's available, then offers accordingly)
  6. Add post-commit prune    — install the vault-report refresh git hook
  7. Add post-commit reindex  — install the embedding reindex git hook (requires semantic search)
  8. Set as default      — make this vault the default
  9. Remove this vault   — deregister from config.yml
 10. Run tags audit      — invoke `scripts/tags-audit.py` on this vault and print the report
```

For each selected operation, run the corresponding step in sequence. Most steps behave identically to the new-vault wizard; where they don't, the difference is noted below:

- 1 → steps 3 and 3a, with these differences from the new-vault flow:
  - Step 3: show the vault's current locale first, rather than asking as if for the first time:
    ```
    This vault's locale is currently "{current-code}". Detected you're writing in {detected-language} — change it to "{code}"?

      1. {code} (detected — matches this conversation)
      2. en
      3. Other (type an ISO 639-1 code)
      4. Keep "{current-code}"
    ```
  - Step 3a: update only the `locale:` value on this vault's existing entry — do not touch `path:`, `default:`, or any other vault's entry.
- 2 → step 3b
- 3 → step 3c
- 4 → step 4
- 5 → step 5, same tailored dependency-check-then-offer procedure as the new-vault wizard. Skip indexing if `.hot/db/vault.db` already exists (ask user if they want to re-index instead).
- 6 → step 5a (prune)
- 7 → step 5a (reindex; gate still applies: if vault.db doesn't exist, offer option 5 first)
- 8 → step 6
- 9 → if any post-commit hooks are installed for this vault, offer to uninstall them first (see `references/POST-COMMIT-HOOKS.md`'s uninstall procedure); then remove vault from `vaults:`, update default if needed, save config. If combined with other selections, run option 9 last — the other operations may need the vault's entry to still exist.
- 10 → run `python3 scripts/tags-audit.py {vault-path}` (paths relative to this skill's directory, per `SKILL.md`'s `## Available scripts`). Pass `--write-snapshot` only if the user wants a dated snapshot saved under `meta/`.

After all selected operations complete, follow SKILL.md's ## Output format — regardless of which combination of options ran, including option 9.
