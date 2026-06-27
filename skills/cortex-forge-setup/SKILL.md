---
name: cortex-forge-setup
description: Register or deregister the current vault in Cortex Forge, install global skills, and configure lifecycle hooks. Run from inside a vault directory.
argument-hint: "Optional sub-task: hooks | skills | sync | vaults"
---

Setup for Cortex Forge. Run from inside a vault directory (one containing `wiki/`, `AGENTS.md`, and `.git/`). Registers the vault in the global config, installs global skills, and optionally configures lifecycle hooks.

## Sub-tasks

When an argument is provided, always run step 1 (vault detection) first, then jump directly to the relevant step(s) — skip everything else:

| Argument | Runs |
|---|---|
| `hooks` | Step 6 — reinstall hook scripts + update settings.json |
| `skills` | Steps 4–5 — install skills + create symlinks |
| `sync` | Step 3b — sync infrastructure files from upstream repo |
| `taste` | Step 7 — install TASTE rule |
| `update` | Step 6u — re-copy hooks from vault to `~/.cortex-forge/bin/hooks/` (no settings.json changes) |
| `vaults` | Steps 2–3 — register/update vault in config |

Always end with the relevant subset of step 9 (confirmation).

## Steps

1. **Detect vault from CWD** — validate that the current directory is a valid vault:
   If `~/.cortex-forge/config.yml` already has an entry for this vault, also read its `locale:` — use it for all agent-generated content. Fallback if absent: `.hot/MEMORY.md` title line (`— locale: {lang}`) → `CODEX.md` Vocabulary (`**locale**:`) → default `en`.

   - Required: `.git/`, `wiki/`, `AGENTS.md`
   - If validation fails, report what's missing and stop.
   - Derive vault name from `basename` of CWD (e.g., `/Users/jp/second-brain` → `second-brain`).

2. **Read existing config** — read `~/.cortex-forge/config.yml` if it exists.
   - Check if the current vault path is already registered.
   - **If already registered**: ask "This vault (`{name}`) is already registered. Remove it?"
     - If yes: remove it from `vaults:`. If it was the default, set default to the next available vault or remove the key. Save config and stop — skip steps 3–6.
     - If no: proceed to step 3 (re-run updates skills and hooks).
   - **If not registered**: proceed to step 3.

3. **Write config** — add or update the vault entry in `~/.cortex-forge/config.yml`.
   - If the vault was **already registered** (detected in step 2), after confirming "no" to removal, ask: "Sync infrastructure files from upstream? (templates, bin scripts)" — if yes, run step 3b before continuing.

3b. **Sync infrastructure from upstream** — pull infrastructure files from the upstream repo and apply them to the current vault.

   **Resolve upstream:**
   - Read `upstream:` from `~/.cortex-forge/config.yml`. Default if absent: `itsmistermoon/cortex-forge`.
   - Format: `{owner}/{repo}` (no protocol, no `.git`).
   - Branch/ref: `main` unless `upstream_ref:` is set in config.

   **Fetch file tree** — one API call:
   ```
   GET https://api.github.com/repos/{upstream}/git/trees/main?recursive=1
   ```
   Extract all `blob` entries whose `path` matches the sync scope (see below). This avoids per-file HEAD requests.

   **Sync scope** — files to download and overwrite locally if content differs:
   - `templates/*.md`
   - `bin/*.sh`
   - `bin/hooks/*`

   For each file in scope:
   1. Fetch raw content: `https://raw.githubusercontent.com/{upstream}/main/{path}`
   2. Compare with local file (if it exists).
   3. If different (or missing locally): overwrite. If identical: skip silently.

   **Never touch** (hard exclusions — skip even if present in upstream tree):
   - `wiki/` — personal knowledge
   - `.raw/` — primary sources
   - `.hot/` — session cache
   - `CODEX.md` — vault identity; compare structure only (see below)
   - `AGENTS.md` — mixed protocol + personal content; compare structure only (see below)

   **Structure-only divergence checks** — always run for these files even though they're excluded from auto-sync. Fetch each from upstream, then:

   Extract headings from both upstream and local (`##` and `###` lines). Report:
   - Headings present upstream but missing locally → "sections added upstream — consider adding them"
   - Headings present locally but absent upstream → "local-only sections — safe to keep"
   - Never report body content differences, only structural (heading) changes.
   - Do not overwrite either file under any circumstance.

   Apply this check to:
   - `AGENTS.md` — protocol sections may be added or renamed as the protocol evolves
   - `CODEX.md` — template structure may gain new sections (e.g. a new `## Vocabulary` entry or a new top-level section)

   **Deletions** — files that exist locally in sync scope but are absent from the upstream tree:
   - Report them as "present locally, removed upstream" and ask the user whether to delete each one (or list them all and ask once with yes/no).

   **Rate limits** — the GitHub API allows 60 unauthenticated requests/hour. The tree fetch is 1 call; each file download is 1 raw HTTP request (not API). Raw downloads are not rate-limited by the API quota, but are subject to bandwidth limits. If a `GITHUB_TOKEN` env var is set, include it as `Authorization: Bearer {token}` on API calls only.

   **Config fields summary:**
   ```yaml
   upstream: itsmistermoon/cortex-forge   # default; override to point at a fork
   upstream_ref: main                      # optional; branch or tag to sync from
   ```


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
   - `{vault}/skills/cortex-prune/` → `~/.agents/skills/cortex-prune/`
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
     - `~/.claude/skills/cortex-prune` → `~/.agents/skills/cortex-prune`
   - If a symlink already exists and points to the right target, skip silently.
   - If a symlink exists but points elsewhere, overwrite it.

5a. **Antigravity symlinks** — if `~/.gemini/config/` exists:
    - Create `~/.gemini/config/skills/` if it doesn't exist.
    - Create symlinks pointing to the installed skills:
      - `~/.gemini/config/skills/cortex-crystallize` → `~/.agents/skills/cortex-crystallize`
      - `~/.gemini/config/skills/cortex-forge-setup` → `~/.agents/skills/cortex-forge-setup`
      - `~/.gemini/config/skills/cortex-recall` → `~/.agents/skills/cortex-recall`
      - `~/.gemini/config/skills/cortex-assimilate` → `~/.agents/skills/cortex-assimilate`
      - `~/.gemini/config/skills/cortex-imprint` → `~/.agents/skills/cortex-imprint`
      - `~/.gemini/config/skills/cortex-prune` → `~/.agents/skills/cortex-prune`
    - If a symlink already exists and points to the right target, skip silently.
    - If a symlink exists but points elsewhere, overwrite it.

6. **Configure lifecycle hooks** — ask: "Set up automatic session memory hooks? (recommended)"
   If yes, first install the runtime hook files (step 6-install), then configure each agent detected (steps below).

   **Step 6-install — Install runtime hooks:**
   - Create `~/.cortex-forge/bin/hooks/` if it doesn't exist.
   - Copy all scripts from `{vault}/bin/hooks/` to `~/.cortex-forge/bin/hooks/` (overwrite if already present).
   - This is the single runtime location for all agents. The vault repo is the source of truth; `~/.cortex-forge/bin/hooks/` is the installed copy.

   **Claude Code** (`~/.claude/` exists):
   - Create `~/.claude/hooks/` if it doesn't exist.
   - For each hook script, create a symlink `~/.claude/hooks/{script}` → `~/.cortex-forge/bin/hooks/{script}`. If a symlink already exists pointing to the right target, skip silently. If it points elsewhere or is a plain file, overwrite with the symlink.
   - Read `~/.claude/settings.json` (or create it if missing).
   - Add the following hooks if not already present:
     ```json
     "SessionStart": [{ "type": "command", "command": "~/.claude/hooks/cortex-reactivate.sh" }]
     "PreCompact":   [{ "type": "command", "command": "~/.claude/hooks/cortex-crystallize-claude.sh" }]
     "SessionEnd":   [{ "type": "command", "command": "~/.claude/hooks/cortex-crystallize-claude.sh", "timeout": 60 }]
     ```
   - Merge carefully — do not overwrite existing hooks, only append to the arrays.

   **Antigravity** (`~/.gemini/config/` exists):
   - Create `~/.gemini/config/hooks/` if it doesn't exist.
   - Create symlink `~/.gemini/config/hooks/cortex-reactivate-antigravity.sh` → `~/.cortex-forge/bin/hooks/cortex-reactivate-antigravity.sh`.
   - Display instructions for `~/.gemini/config/hooks.json`:
     ```
     Antigravity (~/.gemini/config/hooks.json):
       PreInvocation (invocationNum == 0) → bash ~/.gemini/config/hooks/cortex-reactivate-antigravity.sh
     ```
   - ⚠️ **No Stop hook for Antigravity.** The CLI kills the process abruptly on `/exit` (no `SessionEnd` event), and any attempt to launch `agy -p` from a Stop hook causes a deadlock — Antigravity blocks secondary instances while the primary session is alive. Crystallize must be run **manually** via `/cortex-crystallize` in Antigravity. See `wiki/concepts/agent-hook-compatibility.md`.

   **Codex** (`~/.codex/` exists):
   - Create `~/.codex/hooks/` if it doesn't exist.
   - Create symlinks `~/.codex/hooks/{script}` → `~/.cortex-forge/bin/hooks/{script}` for each Codex hook script (`cortex-reactivate.sh`, `cortex-crystallize-codex.sh`).
   - Display instructions for `~/.codex/hooks.json`:
     ```
     Codex (~/.codex/hooks.json):
       SessionStart → ~/.codex/hooks/cortex-reactivate.sh
       Stop         → ~/.codex/hooks/cortex-crystallize-codex.sh
     ```

   **CommandCode** (`~/.commandcode/` exists):
   - Create `~/.commandcode/hooks/` if it doesn't exist.
   - Create symlink `~/.commandcode/hooks/cortex-crystallize-commandcode.sh` → `~/.cortex-forge/bin/hooks/cortex-crystallize-commandcode.sh`.
   - Display instructions for `~/.commandcode/settings.json` (user scope — applies to all projects):
     ```json
     "hooks": {
       "Stop": [{ "command": "bash ~/.commandcode/hooks/cortex-crystallize-commandcode.sh", "timeout": 120 }]
     }
     ```
   - Note: user scope (`~/.commandcode/settings.json`) is preferred over project scope so the hook works across all vaults. The script resolves the active vault at runtime from CWD. Timeout 120s — the script calls `cmd -p` which requires an API call.

6u. **Update runtime hooks** (sub-task `update` only) — re-copy hook scripts from the vault to the runtime location without touching `settings.json` or agent configs:
   - Verify `~/.cortex-forge/bin/hooks/` exists (if not, run step 6 instead — this is a first install).
   - Copy all scripts from `{vault}/bin/hooks/` to `~/.cortex-forge/bin/hooks/` (overwrite).
   - Report: files updated (list), files unchanged (count).
   - Symlinks in `~/.claude/hooks/` and `~/.gemini/config/hooks/` do not need updating — they already point to `~/.cortex-forge/bin/hooks/`.

6a. **Recall enforcement nudge (Claude Code only, v1)** — ask: "Install the cortex-recall nudge hook? It reminds the agent to use /cortex-recall when it greps vault content directly. (experimental)"
   If yes, ask scope (never the versioned `settings.json` of a template repo):
   - **Global (recommended)** — the script self-gates (inert outside registered vaults, once per session), so user scope covers every vault without per-vault config. The script is already in `~/.cortex-forge/bin/hooks/` (copied in step 6-install); create symlink `~/.claude/hooks/cortex-recall-nudge.sh` → `~/.cortex-forge/bin/hooks/cortex-recall-nudge.sh`, then add to `~/.claude/settings.local.json`:
     ```json
     "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/cortex-recall-nudge.sh" }] }]
     ```
   - **Vault-local** — add to the vault's `.claude/settings.local.json` with `"bash \"$CLAUDE_PROJECT_DIR\"/bin/hooks/cortex-recall-nudge.sh"` instead.
   - Scope criterion (applies to any future hook): global only if the script self-discards deterministically, cheaply, and silently from environment signals (config, files, CWD); if relevance can't be detected from the environment, install per project.
   - Merge into existing hooks arrays, never overwrite.
   - The hook is Bash-matcher only, fires once per session, and is inert outside registered vaults. Do **not** offer this for other agents — ports are gated on the AGENT-LOG behavior experiment showing the nudge changes recall invocation (see `cortex-forge-improvements-2.md` Item 1).

6b. **Post-commit prune (opt-in, separate question)** — ask: "Refresh vault-report.json automatically after each commit? (optional)"
   If yes:
   - Check `git config core.hooksPath` first — if set (husky-style), install into that directory instead of `.git/hooks/`, or warn and skip.
   - Append the marked block to `{vault}/.git/hooks/post-commit` (create with shebang if missing; never clobber existing content — only add/remove the `>>> cortex-forge prune >>>` … `<<< cortex-forge prune <<<` block) and make it executable:
     ```bash
     # >>> cortex-forge prune >>>
     if [ -f bin/cortex-prune.sh ]; then
       (
         bash bin/cortex-prune.sh >/dev/null 2>&1 || true
         R="wiki/meta/vault-report.json"
         if [ -f "$R" ] && command -v jq >/dev/null 2>&1; then
           n=$(jq '[.health[] | length] | add' "$R" 2>/dev/null || echo "?")
           echo "$(date '+%F %T') cortex-prune: report refreshed, findings=$n" >> .git/cortex-prune.log
         fi
       ) &
     fi
     # <<< cortex-forge prune <<<
     ```
   - Backgrounded: never delays the commit. Not silent: summary line in `.git/cortex-prune.log`.
   - Uninstall (deregister path): remove only the marked block — a diff against the pre-install file must be empty.

7. **Install TASTE rule for `cortex-recall`** — ask: "Install a TASTE rule so CommandCode invokes `/cortex-recall` automatically? (recommended)"
   If yes:
   - Ask: "Where should the rule live?"
     - **Per-project** (`.commandcode/taste/` inside this vault) — applies only when working in this vault directory.
     - **Global** (`~/.commandcode/taste/`) — applies in every project on this machine.
   - Read the content from `TASTE-FORMAT.md` (co-located with this skill) and use the matching variant (per-project or global).
   - Create or append to the target file:
     - Per-project → `.commandcode/taste/taste.md`
     - Global → `~/.commandcode/taste/taste.md`
   - Create the `taste/` directory if it doesn't exist.
   - If the file already contains a `## Cortex Forge Skills` section, skip — do not duplicate.

8. **Create CODEX.md** — ask: "Create CODEX.md to configure vault context? (recommended)"
   If yes:
   - Copy `CODEX-FORMAT.md` (co-located with this skill) to `{vault}/CODEX.md`.
   - Tell the user: "Edit CODEX.md to describe your vault's mission, domains, vocabulary, and out-of-scope rules."
   - If `CODEX.md` already exists, skip — do not overwrite.

9. **Set default vault** — if more than one vault is registered:
   - Ask: "Which vault should be the default? ({list of registered names})"
   - Update `default:` in the config with the chosen name.
   - If only one vault is registered, set it as default automatically without asking.

10. **Confirm result**:
   - Registered vaults: list all entries in `vaults:` with their paths, marking the default
   - Skills installed: `cortex-crystallize`, `cortex-forge-setup`, `cortex-recall`, `cortex-assimilate`, `cortex-imprint`, `cortex-prune`
   - Claude Code symlinks: created / up to date / skipped
   - Hooks: configured / skipped / manual instructions shown
   - TASTE rule: installed per-project / global / skipped — show exact path
   - CODEX.md: created / already existed / skipped
   - Sync (if run): upstream used, files updated (list), files skipped (count), deletions pending user confirmation, AGENTS.md divergence noted if any
   - Next step: edit `CODEX.md` if just created; invoke `/cortex-crystallize` at the end of any project session

## Hook behavior

The hooks provide automatic (no-invoke) session memory:
- **SessionStart** (`cortex-reactivate.sh`) — reads `.hot/MEMORY.md` and injects it as context
- **PreCompact / Stop** (`cortex-crystallize-claude.sh`) — appends a snapshot to `.hot/MEMORY.md`

The hook writes a minimal snapshot (files touched, external actions). For a full snapshot with Current state updated, invoke `/cortex-crystallize` manually — hooks and manual invocation are compatible and complementary.

## Codex placement

Codex should use a stable global hook directory such as `~/.codex/hooks/`, not a vault-local path. The hook scripts themselves must resolve the active vault at runtime so the same Codex setup works across multiple vaults and from non-vault projects.

## Rules

- Always run from inside the vault directory — never ask for a path manually
- Do not modify any vault files during setup — read only for validation
- Preserve all existing vault entries when writing config
- Symlinks in `~/.claude/skills/`, not copies — updates propagate automatically
- Hook scripts are copied to `~/.cortex-forge/bin/hooks/` (single runtime location); agent-specific dirs (`~/.claude/hooks/`, `~/.gemini/config/hooks/`) contain symlinks to that location — never plain file copies
- To update hooks after a vault change: run `/cortex-forge-setup update` — never copy directly to `~/.claude/hooks/`
- When merging into `settings.json`, preserve all existing hooks
- Always ask for default when there are multiple vaults — never assume
