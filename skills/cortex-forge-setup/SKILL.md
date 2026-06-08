---
name: cortex-forge-setup
description: Register or deregister the current vault in Cortex Forge, install global skills, and configure lifecycle hooks. Run from inside a vault directory.
argument-hint: "Optional sub-task: hooks | skills | taste | vaults"
---

Setup for Cortex Forge. Run from inside a vault directory (one containing `wiki/`, `AGENTS.md`, and `.git/`). Registers the vault in the global config, installs global skills, and optionally configures lifecycle hooks.

## Sub-tasks

When an argument is provided, always run step 1 (vault detection) first, then jump directly to the relevant step(s) — skip everything else:

| Argument | Runs |
|---|---|
| `hooks` | Step 6 — reinstall hook scripts + update settings.json |
| `skills` | Steps 4–5 — install skills + create symlinks |
| `taste` | Step 7 — install TASTE rule |
| `vaults` | Steps 2–3 — register/update vault in config |

Always end with the relevant subset of step 9 (confirmation).

## Steps

1. **Detect vault from CWD** — validate that the current directory is a valid vault:
   - Required: `.git/`, `wiki/`, `AGENTS.md`, `skills/`
   - If validation fails, report what's missing and stop.
   - Derive vault name from `basename` of CWD (e.g., `/Users/jp/second-brain` → `second-brain`).

2. **Read existing config** — read `~/.cortex-forge/config.yml` if it exists.
   - Check if the current vault path is already registered.
   - **If already registered**: ask "This vault (`{name}`) is already registered. Remove it?"
     - If yes: remove it from `vaults:`. If it was the default, set default to the next available vault or remove the key. Save config and stop — skip steps 3–6.
     - If no: proceed to step 3 (re-run updates skills and hooks).
   - **If not registered**: proceed to step 3.

3. **Write config** — add or update the vault entry in `~/.cortex-forge/config.yml`:
   ```yaml
   vaults:
     {name}: {absolute-path}
     # ... other registered vaults preserved as-is
   default: {name}   # set as default only if this is the first vault, or if it was already default
   ```
   - Create `~/.cortex-forge/` if it doesn't exist.
   - Preserve all existing vault entries — never overwrite other vaults.
   - If this is the first vault registered, set it as `default`.
   - If a `default` already exists, leave it unchanged.

4. **Install global skills** — copy from this vault to the agent's skill directory:
   - `{vault}/skills/cortex-crystallize/` → `~/.agents/skills/cortex-crystallize/`
   - `{vault}/skills/cortex-forge-setup/` → `~/.agents/skills/cortex-forge-setup/`
   - `{vault}/skills/cortex-recall/` → `~/.agents/skills/cortex-recall/`
   - `{vault}/skills/cortex-assimilate/` → `~/.agents/skills/cortex-assimilate/`
   - `{vault}/skills/cortex-imprint/` → `~/.agents/skills/cortex-imprint/`
   - Overwrite if they already exist (update in place).
   - Create `~/.agents/skills/` if it doesn't exist.

5. **Claude Code symlinks** — if `~/.claude/` exists:
   - Create `~/.claude/skills/` if it doesn't exist.
   - Create symlinks pointing to the installed skills:
     - `~/.claude/skills/cortex-crystallize` → `~/.agents/skills/cortex-crystallize`
     - `~/.claude/skills/cortex-forge-setup` → `~/.agents/skills/cortex-forge-setup`
     - `~/.claude/skills/cortex-recall` → `~/.agents/skills/cortex-recall`
     - `~/.claude/skills/cortex-assimilate` → `~/.agents/skills/cortex-assimilate`
     - `~/.claude/skills/cortex-imprint` → `~/.agents/skills/cortex-imprint`
   - If a symlink already exists and points to the right target, skip silently.
   - If a symlink exists but points elsewhere, overwrite it.

6. **Configure lifecycle hooks** — ask: "Set up automatic session memory hooks? (recommended)"
   If yes:
   - **Claude Code** (`~/.claude/` exists):
     - Copy hook scripts from `{vault}/bin/hooks/` to `~/.claude/hooks/` (create dir if needed).
     - Read `~/.claude/settings.json` (or create it if missing).
     - Add the following hooks if not already present:
       ```json
       "SessionStart": [{ "type": "command", "command": "~/.claude/hooks/load-hot-cache.sh" }]
       "PreCompact":   [{ "type": "command", "command": "~/.claude/hooks/update-hot-cache.sh" }]
       ```
     - Merge carefully — do not overwrite existing hooks, only append to the arrays.
   - **Other agents** — display manual instructions:
     ```
     Codex (~/.codex/hooks.json):
       SessionStart → bash {vault}/bin/hooks/load-hot-cache.sh
       Stop         → bash {vault}/bin/hooks/update-hot-cache.sh

     Antigravity (~/.gemini/config/hooks.json):
       PreInvocation (invocationNum == 0) → bash {vault}/bin/hooks/load-hot-cache.sh
       Stop (fullyIdle == true)           → bash {vault}/bin/hooks/update-hot-cache.sh

     CommandCode ({vault}/.commandcode/settings.json or ~/.commandcode/settings.json):
       Stop → bash {vault}/bin/hooks/update-hot-cache.sh
     ```

7. **Install TASTE rule for `cortex-recall`** — ask: "Install a TASTE rule so CommandCode invokes `/cortex-recall` automatically? (recommended)"
   If yes:
   - Ask: "Where should the rule live?"
     - **Per-project** (`.commandcode/taste/` inside this vault) — applies only when working in this vault directory.
     - **Global** (`~/.commandcode/taste/`) — applies in every project on this machine.
   - Create or append to the target file:
     - Per-project → `.commandcode/taste/taste.md`
     - Global → `~/.commandcode/taste/taste.md`
   - **Per-project content** (includes `cortex-prune`, which is vault-local):
     ```markdown
     ## Cortex Forge Skills
     - When answering questions about project decisions, architecture, or history, invoke /cortex-recall first. Confidence: 0.85
     - When referencing vault knowledge (wiki pages, concepts, entities), use /cortex-recall to retrieve accurate, cited content. Confidence: 0.85
     - When the user provides a URL or file to add to the vault, use /cortex-assimilate. Confidence: 0.85
     - When a valuable insight, decision, or synthesis emerges from a session, archive it with /cortex-imprint. Confidence: 0.85
     - At the end of a working session, snapshot context to the hot cache with /cortex-crystallize. Confidence: 0.85
     - When the vault accumulates stale or redundant pages, use /cortex-prune to clean up. Confidence: 0.85
     ```
   - **Global content** (includes `cortex-prune` scoped to vault directories):
     ```markdown
     ## Cortex Forge Skills
     - When answering questions about project decisions, architecture, or history, invoke /cortex-recall first. Confidence: 0.85
     - When referencing vault knowledge (wiki pages, concepts, entities), use /cortex-recall to retrieve accurate, cited content. Confidence: 0.85
     - When the user provides a URL or file to add to the vault, use /cortex-assimilate. Confidence: 0.85
     - When a valuable insight, decision, or synthesis emerges from a session, archive it with /cortex-imprint. Confidence: 0.85
     - At the end of a working session, snapshot context to the hot cache with /cortex-crystallize. Confidence: 0.85
     - When working inside a Cortex Forge vault and it accumulates stale or redundant pages, use /cortex-prune to clean up. Confidence: 0.85
     ```
     Note: TASTE confidence scores are normally auto-learned by `taste-1` from observed behavior. These are seed values — the system will adjust them over time based on actual usage.
   - Create the `taste/` directory if it doesn't exist.
   - If the file already contains a `## Cortex Recall` section, skip — do not duplicate.

8. **Set default vault** — if more than one vault is registered:
   - Ask: "Which vault should be the default? ({list of registered names})"
   - Update `default:` in the config with the chosen name.
   - If only one vault is registered, set it as default automatically without asking.

9. **Confirm result**:
   - Registered vaults: list all entries in `vaults:` with their paths, marking the default
   - Skills installed: `cortex-crystallize`, `cortex-forge-setup`, `cortex-recall`, `cortex-assimilate`, `cortex-imprint`
   - Claude Code symlinks: created / up to date / skipped
   - Hooks: configured / skipped / manual instructions shown
   - TASTE rule: installed per-project / global / skipped — show exact path
   - Next step: invoke `/cortex-crystallize` at the end of any project session

## Hook behavior

The hooks provide automatic (no-invoke) session memory:
- **SessionStart** (`load-hot-cache.sh`) — reads `.hot/{project}.md` and injects it as context
- **PreCompact / Stop** (`update-hot-cache.sh`) — appends a snapshot to `.hot/{project}.md`

The hook writes a minimal snapshot (files touched, external actions). For a full snapshot with Current state updated, invoke `/cortex-crystallize` manually — hooks and manual invocation are compatible and complementary.

## Rules

- Always run from inside the vault directory — never ask for a path manually
- Do not modify any vault files during setup — read only for validation
- Preserve all existing vault entries when writing config
- Symlinks in `~/.claude/skills/`, not copies — updates propagate automatically
- When merging into `settings.json`, preserve all existing hooks
- Always ask for default when there are multiple vaults — never assume
