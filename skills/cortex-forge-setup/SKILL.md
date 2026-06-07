---
name: cortex-forge-setup
description: One-time setup for the Cortex Forge protocol. Configures the vault path and installs global skills into ~/.agents/skills/, with Claude Code symlinks if applicable.
argument-hint: "Vault path (optional, prompted if omitted)"
---

Initial setup for Cortex Forge. Run once after cloning the repo or when the vault location changes.

## Steps

1. **Check for existing config** — read `~/.cortex-forge/config.yml` if it exists and display current values.

2. **Set vault path** — if no config exists or the user wants to update it:
   - Ask: "Where is your vault? (directory containing wiki/, AGENTS.md, and .git)"
   - Validate the path has: `.git/`, `wiki/`, `AGENTS.md`, `skills/`
   - If validation fails, report what's missing and stop

3. **Write config**:
   Create `~/.cortex-forge/config.yml`:
   ```yaml
   vault: {validated-path}
   ```

4. **Install global skills** — copy to the agent's skill directory:
   - `{vault}/skills/cortex-crystallize/` → `~/.agents/skills/cortex-crystallize/`
   - `{vault}/skills/cortex-forge-setup/` → `~/.agents/skills/cortex-forge-setup/`
   - Overwrite if they already exist (update in place)

5. **Claude Code symlinks** — if `~/.claude/` exists (Claude Code is installed):
   - Create `~/.claude/skills/` if it doesn't exist
   - Create symlinks pointing to the installed skills:
     - `~/.claude/skills/cortex-crystallize` → `~/.agents/skills/cortex-crystallize`
     - `~/.claude/skills/cortex-forge-setup` → `~/.agents/skills/cortex-forge-setup`
   - If a symlink already exists and points to the right target, skip silently
   - If a symlink exists but points elsewhere, overwrite it

6. **Confirm result**:
   - Vault configured at: `{path}`
   - Skills installed in `~/.agents/skills/`: `cortex-crystallize`, `cortex-forge-setup`
   - Claude Code symlinks: created / already up to date / skipped (Claude Code not detected)
   - Next step: invoke `/cortex-crystallize` at the end of any project session

## Rules

- Do not modify any vault files during setup — read only for validation
- Create `~/.agents/skills/` if it doesn't exist
- If config already exists, show it and ask before overwriting
- Symlinks, not copies, in `~/.claude/skills/` — so updates to `~/.agents/skills/` propagate automatically
