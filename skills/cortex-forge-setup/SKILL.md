---
name: cortex-forge-setup
behavior: ["configure"]
description: Register or deregister the current vault in Cortex Forge and install global skills. Run from inside a vault directory.
argument-hint: "Optional sub-task: skills | sync | vaults"
---

Setup for Cortex Forge. Run from inside a vault directory (one containing `wiki/`, `AGENTS.md`, and `.git/`). Registers the vault in the global config and installs global skills. Cortex Forge does not rely on agent lifecycle hooks (SessionStart/PreCompact/SessionEnd/PreToolUse) — support for those is too uneven across agents (Claude Code, Codex, Antigravity, CommandCode). All memory operations (loading `.cortex/MEMORY.md`, crystallizing, recalling) are invoked manually via skills (`/cortex-crystallize`, `/cortex-recall`) so behavior is identical everywhere.

## Sub-tasks

When an argument is provided, always run step 1 (vault detection) first, then jump directly to the relevant step(s) — skip everything else:

| Argument | Runs |
|---|---|
| `skills` | Steps 4–5 — install skills + create symlinks |
| `sync` | Step 3b — sync infrastructure files from upstream repo |
| `taste` | Step 7 — install TASTE rule |
| `vaults` | Steps 2–3 — register/update vault in config |

Always end with the relevant subset of step 9 (confirmation).

## Steps

1. **Detect vault from CWD** — validate that the current directory is a valid vault:
   If `~/.cortex-forge/config.yml` already has an entry for this vault, also read its `locale:` — see `LOCALE-RESOLUTION.md` (co-located with the skills) for the fallback chain.

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
     2. Sync from upstream  — pull updated templates and bin scripts from the upstream repo
     3. Initialize semantic search — build .cortex/vault.db for the first time (asks for backend choice)
     4. Add post-commit prune    — install the vault-report refresh git hook
     5. Add post-commit reindex  — install the embedding reindex git hook (requires semantic search)
     6. Install TASTE rule  — add cortex-recall auto-invoke rule for CommandCode
     7. Remove this vault   — deregister from config.yml
     8. Set as default      — make this vault the default
   ```

   For each selected operation, run the corresponding step in sequence:
   - 1 → steps 4–5
   - 2 → step 3b
   - 3 → Initialize: copy `cortex-search.py`, `embeddings.py`, and `cortex-index.py` (co-located with this skill) to `{vault}/.cortex/db/` (create dir if needed). Check embedding dependencies before indexing (see dependency check below). Then run `python3 {vault}/.cortex/db/cortex-index.py {vault}`, report chunks indexed. Skip the copy if files already exist and are identical. Skip indexing if `.cortex/db/vault.db` already exists (ask user if they want to re-index instead).
   - 4 → step 6b
   - 5 → step 6c (gate still applies: if vault.db doesn't exist, offer option 3 first)
   - 6 → step 7
   - 7 → remove vault from `vaults:`, update default if needed, save config, stop
   - 8 → step 9

   After all selected operations complete, show confirmation (step 10) for only the operations that ran.

3. **Write config** — add the vault entry in `~/.cortex-forge/config.yml` (new vault only):

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

4. **Install global skills** — create `~/.agents/skills/{skill}/` dirs and symlink each `SKILL.md` to `~/.cortex-forge/skills/`:
   - `~/.agents/skills/cortex-crystallize/SKILL.md` → `~/.cortex-forge/skills/cortex-crystallize/SKILL.md`
   - `~/.agents/skills/cortex-forge-setup/SKILL.md` → `~/.cortex-forge/skills/cortex-forge-setup/SKILL.md`
   - `~/.agents/skills/cortex-recall/SKILL.md` → `~/.cortex-forge/skills/cortex-recall/SKILL.md`
   - `~/.agents/skills/cortex-assimilate/SKILL.md` → `~/.cortex-forge/skills/cortex-assimilate/SKILL.md`
   - `~/.agents/skills/cortex-imprint/SKILL.md` → `~/.cortex-forge/skills/cortex-imprint/SKILL.md`
   - `~/.agents/skills/cortex-prune/SKILL.md` → `~/.cortex-forge/skills/cortex-prune/SKILL.md`
   - If a symlink already exists and points to the right target, skip silently. If it points elsewhere or is a plain file, overwrite with `ln -sf`.
   - Create `~/.agents/skills/` and each subdirectory if they don't exist.
   - Single source of truth: `~/.cortex-forge/skills/` (the runtime populated by the tarball installer). Updating forge = re-running the curl installer; all skill symlinks update automatically.

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

6b. **Post-commit prune (opt-in, separate question)** — ask: "Refresh vault-report.json automatically after each commit? (optional)"
   If yes:
   - **Resolve `cortex-prune.sh`:** git hooks run outside any agent session, so they need a fixed absolute path — not the "co-located with this skill" resolution the agent uses when invoking `/cortex-prune` directly. Locate the `cortex-prune` skill's own directory (typically a sibling of this skill's directory — e.g. `../cortex-prune/cortex-prune.sh` relative to where this SKILL.md was read from) and copy its `cortex-prune.sh` to `~/.cortex-forge/bin/cortex-prune.sh` (create dir if needed; skip copy if already identical). If `cortex-prune.sh` cannot be found anywhere, tell the user the `cortex-prune` skill isn't installed and skip this option.
   - Check `git config core.hooksPath` first — if set (husky-style), install into that directory instead of `.git/hooks/`, or warn and skip.
   - Append the marked block to `{vault}/.git/hooks/post-commit` (create with shebang if missing; never clobber existing content — only add/remove the `>>> cortex-forge prune >>>` … `<<< cortex-forge prune <<<` block) and make it executable:
     ```bash
     # >>> cortex-forge prune >>>
     if [ -f ~/.cortex-forge/bin/cortex-prune.sh ]; then
       (
         bash ~/.cortex-forge/bin/cortex-prune.sh >/dev/null 2>&1 || true
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
     - **Does not exist** → do NOT skip silently. Instead ask: "Semantic search index not found. Initialize it now? This runs `cortex-index.py` once to build `.cortex/db/vault.db`. Skip if you want to set it up later."
       - If user confirms: run dependency check (step 6d) first. If dependencies are satisfied, copy `cortex-search.py`, `embeddings.py`, and `cortex-index.py` (co-located with this skill) to `{vault}/.cortex/db/` (create dir if needed). Then run `python3 {vault}/.cortex/db/cortex-index.py {vault}` and wait for it to complete before installing the hook. Report how many chunks were indexed.
       - If user skips: skip the hook installation and note in the summary that semantic search was not initialized (user can re-run `/cortex-forge-setup` later to add it).
   - Check `git config core.hooksPath` first — if set (husky-style), install into that directory instead of `.git/hooks/`, or warn and skip.
   - Copy `cortex-reindex-post-commit.sh` (co-located with this skill) to `~/.cortex-forge/bin/hooks/` if not already there — same reasoning as 6b: the git hook needs a fixed absolute path outside any agent session.
   - Append the marked block to `{vault}/.git/hooks/post-commit` (create with shebang if missing; never clobber existing content — only add/remove the `>>> cortex-forge reindex >>>` … `<<< cortex-forge reindex <<<` block) and make it executable:
     ```bash
     # >>> cortex-forge reindex >>>
     bash ~/.cortex-forge/bin/hooks/cortex-reindex-post-commit.sh
     # <<< cortex-forge reindex <<<
     ```
   - The hook self-gates: exits immediately if `.cortex/db/vault.db` or `.cortex/db/cortex-index.py` don't exist, and only runs when the commit touched `wiki/` files. Runs in the background (`&`) — never delays the commit. Appends a timestamped line to `.git/cortex-reindex.log` (ok or error with exit code).
   - Uninstall (deregister path): remove only the marked block — a diff against the pre-install file must be empty.

6d. **Embedding dependency check** — run this before any indexing attempt (option 3 and 6c). Also triggered if `cortex-index.py` fails with an import error. See `EMBEDDING-SETUP.md` (co-located with this skill) for the full detection and installation procedure.

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
   - If present: skip silently.
   - If missing: append the following stub to `AGENTS.md` and inform the user: "Added `## Vault identity` stub to `AGENTS.md` — fill it out before running `/cortex-assimilate`."
     ```markdown
     ## Vault identity

     **locale**: en
     **mission**: <!-- What this vault is for -->
     **domains**: <!-- Comma-separated list of topics in scope -->
     **out of scope**: <!-- Topics to reject at ingestion time -->
     **vocabulary**: <!-- Key terms and preferred names used in this vault -->
     ```

9. **Set default vault** — if more than one vault is registered:
   - Ask: "Which vault should be the default? ({list of registered names})"
   - Update `default:` in the config with the chosen name.
   - If only one vault is registered, set it as default automatically without asking.

10. **Confirm result**:
   - Registered vaults: list all entries in `vaults:` with their paths, marking the default
   - Skills installed: `cortex-crystallize`, `cortex-forge-setup`, `cortex-recall`, `cortex-assimilate`, `cortex-imprint`, `cortex-prune`
   - Claude Code symlinks: created / up to date / skipped
   - TASTE rule: installed per-project / global / skipped — show exact path
   - AGENTS.md vault identity: added / already present / skipped
   - Sync (if run): upstream used, files updated (list), files skipped (count), deletions pending user confirmation, AGENTS.md divergence noted if any
   - Next step: fill out vault identity in `AGENTS.md` if just added; invoke `/cortex-crystallize` at the end of any project session

## Memory model (manual, no agent lifecycle hooks)

Cortex Forge does not use SessionStart/PreCompact/SessionEnd/PreToolUse hooks on any agent — support for those events is too uneven across Claude Code, Codex, Antigravity, and CommandCode to build the suite on top of them. Instead, every agent behaves the same way:

- **Load memory**: the agent reads `.cortex/MEMORY.md` itself (per `AGENTS.md` instructions) at the start of a session, or the user invokes `/cortex-recall`.
- **Save memory**: the user (or the agent, per `AGENTS.md` instructions near the end of a session) invokes `/cortex-crystallize` manually to append a snapshot to `.cortex/MEMORY.md`.

This is deliberately identical across agents — no per-agent hook wiring, no symlink maintenance, no `settings.json`/`hooks.json` merges.

## Rules

- Always run from inside the vault directory — never ask for a path manually
- Do not modify any vault files during setup — read only for validation
- Preserve all existing vault entries when writing config
- Symlinks in `~/.claude/skills/`, not copies — updates propagate automatically
- Post-commit git hooks (prune, reindex — steps 6b/6c) are the only hooks this skill installs; they are plain git hooks, not agent lifecycle hooks, so they behave identically regardless of which agent is in use
- Always ask for default when there are multiple vaults — never assume
