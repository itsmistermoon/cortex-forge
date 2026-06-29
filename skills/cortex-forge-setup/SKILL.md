---
name: cortex-forge-setup
behavior: ["configure"]
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
   If `~/.cortex-forge/config.yml` already has an entry for this vault, also read its `locale:` — use it for all agent-generated content. Fallback if absent: `.cortex/MEMORY.md` title line (`— locale: {lang}`) → `AGENTS.md` Vault identity (`**locale**:`) → default `en`.

   - Required: `.git/`, `wiki/`, `AGENTS.md`
   - If validation fails, report what's missing and stop.
   - Derive vault name from `basename` of CWD (e.g., `/Users/jp/second-brain` → `second-brain`).

2. **Read existing config** — read `~/.cortex-forge/config.yml` if it exists.
   - Check if the current vault path is already registered.
   - **If not registered** → vault is new. Proceed through steps 3–9 in full, asking each optional step interactively.
   - **If already registered** → vault exists. Skip steps 3–9. Instead show a menu (step 2b) and execute only what the user selects.

2b. **Maintenance menu (existing vault only)** — present a numbered list of available operations. The user can select one or more numbers (comma-separated), or "all":

   ```
   Vault "{name}" is already registered. What would you like to do?

     1. Update skills       — reinstall/update all cortex-forge skills in ~/.agents/skills/
     2. Update hooks        — reinstall session hooks in ~/.claude/settings.json (SessionStart / PreCompact / SessionEnd)
     3. Sync from upstream  — pull updated templates and bin scripts from the upstream repo
     4. Initialize semantic search — build .cortex/vault.db for the first time (asks for backend choice)
     5. Add post-commit prune    — install the vault-report refresh hook
     6. Add post-commit reindex  — install the embedding reindex hook (requires semantic search)
     7. Install TASTE rule  — add cortex-recall auto-invoke rule for CommandCode
     8. Remove this vault   — deregister from config.yml
     9. Set as default      — make this vault the default
   ```

   For each selected operation, run the corresponding step in sequence:
   - 1 → steps 4–5
   - 2 → step 6 (session hooks only; skip 6a, 6b, 6c — those have their own entries)
   - 3 → step 3b
   - 4 → Initialize: copy `bin/cortex-search.py` and `bin/embeddings.py` from the forge to `{vault}/.cortex/db/` (create dir if needed). Check embedding dependencies before indexing (see dependency check below). Then run `python3 {forge}/bin/cortex-index.py {vault}`, report chunks indexed. Skip the copy if files already exist and are identical. Skip indexing if `.cortex/db/vault.db` already exists (ask user if they want to re-index instead).
   - 5 → step 6b
   - 6 → step 6c (gate still applies: if vault.db doesn't exist, offer option 4 first)
   - 7 → step 7
   - 8 → remove vault from `vaults:`, update default if needed, save config, stop
   - 9 → step 9

   After all selected operations complete, show confirmation (step 10) for only the operations that ran.

3. **Write config** — add the vault entry in `~/.cortex-forge/config.yml` (new vault only).

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

   For each file in scope:
   1. Fetch raw content: `https://raw.githubusercontent.com/{upstream}/main/{path}`
   2. Compare with local file (if it exists).
   3. If different (or missing locally): overwrite. If identical: skip silently.

   **Never touch** (hard exclusions — skip even if present in upstream tree):
   - `wiki/` — personal knowledge
   - `.raw/` — primary sources
   - `.cortex/` — session cache and semantic search (gitignored; not synced)
   - `AGENTS.md` — mixed protocol + personal content; compare structure only (see below)

   **Structure-only divergence check** — always run for `AGENTS.md` even though it's excluded from auto-sync. Fetch from upstream, then:

   Extract headings from both upstream and local (`##` and `###` lines). Report:
   - Headings present upstream but missing locally → "sections added upstream — consider adding them"
   - Headings present locally but absent upstream → "local-only sections — safe to keep"
   - Never report body content differences, only structural (heading) changes.
   - Do not overwrite under any circumstance.

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

   **Step 6-install — Verify runtime hooks:**
   - Confirm `~/.cortex-forge/bin/hooks/` exists and contains hook scripts. If missing or empty, tell the user to re-run the curl installer (`install.sh`) — the hooks are part of the forge runtime, not the vault.
   - This is the single runtime location for all agents. Symlinks for each agent point here.

   **Claude Code** (`~/.claude/` exists):
   - Create `~/.claude/hooks/` if it doesn't exist.
   - For each hook script, create a symlink `~/.claude/hooks/{script}` → `~/.cortex-forge/bin/hooks/{script}`. If a symlink already exists pointing to the right target, skip silently. If it points elsewhere or is a plain file, overwrite with the symlink.
   - Read `~/.claude/settings.json` (or create it if missing).
   - Add the following hooks if not already present (use `matcher: ""` to match all):
     ```json
     "SessionStart": [{ "matcher": "", "hooks": [{ "type": "command", "command": "~/.claude/hooks/cortex-reactivate.sh" }] }]
     "PreCompact":   [{ "matcher": "", "hooks": [{ "type": "command", "command": "~/.claude/hooks/cortex-crystallize-claude.sh" }] }]
     "SessionEnd":   [{ "matcher": "", "hooks": [{ "type": "command", "command": "~/.claude/hooks/cortex-crystallize-claude.sh", "timeout": 60 }] }]
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
   - Create symlinks `~/.codex/hooks/{script}` → `~/.cortex-forge/bin/hooks/{script}` for each Codex hook script (`cortex-reactivate-codex.sh`, `cortex-crystallize-codex.sh`).
   - Display instructions for `~/.codex/hooks.json`:
     ```
     Codex (~/.codex/hooks.json):
       SessionStart → ~/.codex/hooks/cortex-reactivate-codex.sh
       Stop         → ~/.codex/hooks/cortex-crystallize-codex.sh  # no-op JSON guard
     ```
   - ⚠️ **No automatic Codex crystallize.** Codex displays SessionStart injected context in the conversation and its Stop event is turn-scoped rather than a reliable session-close signal. Codex must load hot cache from `AGENTS.md` instructions and crystallize manually via `/cortex-crystallize`.
   - ⚠️ **Semantic search requires network access in Codex.** Codex CLI runs with an OS-level sandbox that blocks loopback connections by default (`allow_local_binding = false`), which prevents `cortex-search.py` from reaching Ollama on `localhost:11434`. Without this, `cortex-recall` silently falls back to keyword search via `wiki/index.md`. Display and ask the user to add to `~/.codex/config.toml`:
     ```toml
     # Required for cortex-recall semantic search (allows Ollama on localhost:11434)
     [sandbox_workspace_write]
     network_access = true

     [features.network_proxy]
     enabled = true
     allow_local_binding = true
     ```
     Source: confirmed via live testing + OpenAI Codex docs (sandboxing, config-reference) — 2026-06-28.

   **CommandCode** (`~/.commandcode/` exists):
   - Create `~/.commandcode/hooks/` if it doesn't exist.
   - Create symlink `~/.commandcode/hooks/cortex-crystallize-commandcode.sh` → `~/.cortex-forge/bin/hooks/cortex-crystallize-commandcode.sh`.
   - Display instructions for `~/.commandcode/settings.json` (user scope — applies to all projects):
     ```json
     "hooks": {
       "Stop": [{ "command": "bash ~/.commandcode/hooks/cortex-crystallize-commandcode.sh", "timeout": 120 }"]
     }
     ```
   - Note: user scope (`~/.commandcode/settings.json`) is preferred over project scope so the hook works across all vaults. The script resolves the active vault at runtime from CWD. Timeout 120s — the script calls `cmd -p` which requires an API call.

6u. **Update runtime hooks** (sub-task `update` only) — re-run the curl installer to pull the latest forge runtime (hooks included), then re-verify symlinks:
   - Tell the user to run: `curl -fsSL https://raw.githubusercontent.com/itsmistermoon/cortex-forge/main/install.sh | bash`
   - After the installer completes, verify symlinks in `~/.claude/hooks/`, `~/.gemini/config/hooks/`, etc. still point to `~/.cortex-forge/bin/hooks/`. If any are broken, recreate them.
   - Report: symlinks verified (list), any recreated (list).

6a. **Recall enforcement nudge (Claude Code only, v1)** — ask: "Install the cortex-recall nudge hook? It reminds the agent to use /cortex-recall when it greps vault content directly. (experimental)"
   If yes, ask scope (never the versioned `settings.json` of a template repo):
   - **Global (recommended)** — the script self-gates (inert outside registered vaults, once per session), so user scope covers every vault without per-vault config. The script is already in `~/.cortex-forge/bin/hooks/` (copied in step 6-install); create symlink `~/.claude/hooks/cortex-recall-nudge.sh` → `~/.cortex-forge/bin/hooks/cortex-recall-nudge.sh`, then add to `~/.claude/settings.local.json`:
     ```json
     "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/cortex-recall-nudge.sh" }] }"]
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

6c. **Post-commit re-index (opt-in, separate question)** — ask: "Re-index vault embeddings automatically after each commit? (recommended if semantic search is enabled)"
   If yes:
   - Check if `.cortex/db/vault.db` exists:
     - **Exists** → proceed normally.
     - **Does not exist** → do NOT skip silently. Instead ask: "Semantic search index not found. Initialize it now? This runs `bin/cortex-index.py` once to build `.cortex/db/vault.db`. Skip if you want to set it up later."
       - If user confirms: run dependency check (step 6d) first. If dependencies are satisfied, copy `bin/cortex-search.py` and `bin/embeddings.py` from the forge to `{vault}/.cortex/db/` (create dir if needed). Then run `python3 {forge}/bin/cortex-index.py {vault}` and wait for it to complete before installing the hook. Report how many chunks were indexed.
       - If user skips: skip the hook installation and note in the summary that semantic search was not initialized (user can re-run `/cortex-forge-setup` later to add it).
   - Check `git config core.hooksPath` first — if set (husky-style), install into that directory instead of `.git/hooks/`, or warn and skip.
   - Copy `bin/hooks/cortex-reindex-post-commit.sh` from the forge to `~/.cortex-forge/bin/hooks/` if not already there.
   - Append the marked block to `{vault}/.git/hooks/post-commit` (create with shebang if missing; never clobber existing content — only add/remove the `>>> cortex-forge reindex >>>` … `<<< cortex-forge reindex <<<` block) and make it executable:
     ```bash
     # >>> cortex-forge reindex >>>
     bash ~/.cortex-forge/bin/hooks/cortex-reindex-post-commit.sh
     # <<< cortex-forge reindex <<<
     ```
   - The hook self-gates: exits immediately if `.cortex/db/vault.db` or `bin/cortex-index.py` don't exist, and only runs when the commit touched `wiki/` files. Runs in the background (`&`) — never delays the commit. Appends a timestamped line to `.git/cortex-reindex.log` (ok or error with exit code).
   - Uninstall (deregister path): remove only the marked block — a diff against the pre-install file must be empty.

6d. **Embedding dependency check** — run this before any indexing attempt (option 4 and 6c). This check is also triggered if `cortex-index.py` fails with an import error.

   Detect platform: `uname -m` → `arm64` = Apple Silicon, anything else = generic.

   Run:
   ```bash
   python3 -c "import mlx_lm" 2>/dev/null && echo mlx || python3 -c "import sentence_transformers" 2>/dev/null && echo st || echo none
   ```

   - **`mlx` or `st` available** → proceed silently (report which backend is active in the summary).
   - **`none`** → do NOT fail silently. Present this message:

     ```
     Semantic search requires an embedding library to generate vectors locally.
     No compatible library was found on this machine.

     Why this matters: without embeddings, cortex-recall falls back to keyword search
     across the full index. With embeddings, it retrieves the most relevant pages
     semantically — useful as the vault grows beyond ~50 pages.

     Long-term implications of installing:
     • ~270 MB of model weights downloaded once, stored in ~/.cache/
     • On Apple Silicon: mlx-embeddings runs via Neural Engine (fast, low power)
     • On other platforms: sentence-transformers runs on CPU (slower but portable)
     • No network calls at query time — fully local after the first download

     Install now?
       [1] Yes — install for this platform ({mlx-embeddings | sentence-transformers})
       [2] No — skip semantic search for now (can re-run /cortex-forge-setup later)
     ```

   - If user chooses **[1]**:
     - Apple Silicon → `pip install mlx-embeddings` (primary); if it fails, fall back to `pip install sentence-transformers` and note the fallback.
     - Other → `pip install sentence-transformers`.
     - After install, re-run the detection snippet to confirm. If still failing, report the error and skip indexing — do not proceed blindly.
   - If user chooses **[2]**: skip indexing, note in the final summary that semantic search is not active.

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

8. **Update AGENTS.md vault identity** — check if `AGENTS.md` contains a `## Vault identity` section.
   - If missing: ask "Add vault identity section to AGENTS.md? (recommended — sets locale, vocabulary, and out-of-scope rules)"
     If yes: append a `## Vault identity` section with the template from `CODEX-FORMAT.md` (locale, vocabulary, domains, out-of-scope).
   - If present: skip silently.

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
   - AGENTS.md vault identity: added / already present / skipped
   - Sync (if run): upstream used, files updated (list), files skipped (count), deletions pending user confirmation, AGENTS.md divergence noted if any
   - Next step: fill out vault identity in `AGENTS.md` if just added; invoke `/cortex-crystallize` at the end of any project session

## Hook behavior

The hooks provide automatic (no-invoke) session memory where the agent lifecycle supports it:
- **Claude SessionStart** (`cortex-reactivate.sh`) — reads `.cortex/MEMORY.md` and injects it as context
- **Claude PreCompact / SessionEnd** (`cortex-crystallize-claude.sh`) — appends a snapshot to `.cortex/MEMORY.md`
- **Codex SessionStart / Stop** (`cortex-reactivate-codex.sh`, `cortex-crystallize-codex.sh`) — no-op JSON guards; Codex loads and saves memory manually via `AGENTS.md` + `/cortex-crystallize`

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
