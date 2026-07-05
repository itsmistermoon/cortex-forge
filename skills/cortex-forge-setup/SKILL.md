---
name: cortex-forge-setup
behavior: ["configure"]
description: Register or deregister the current vault in Cortex Forge and verify global skills are installed. Run from inside a vault directory.
argument-hint: "Optional sub-task: embeddings | skills | sync | vaults"
---

Setup for Cortex Forge. Run from inside a vault directory (one containing `wiki/`, `AGENTS.md`, and `.git/`). Registers the vault in the global config. Cortex Forge does not rely on agent lifecycle hooks (SessionStart/PreCompact/SessionEnd/PreToolUse) — support for those is too uneven across agents. All memory operations (loading `.cortex/MEMORY.md`, crystallizing, recalling) are invoked manually via skills (`/cortex-crystallize`, `/cortex-recall`) so behavior is identical everywhere. This skill does not install skill files itself — [skills.sh](https://www.skills.sh/) (`npx skills add`) is the sole installer, for every agent it supports, not a hardcoded pair.

## Available scripts

- **`scripts/cortex-index.py`** — Builds/refreshes `.cortex/db/vault.db` when semantic search is enabled (step 5); also copied to `~/.cortex-forge/bin/` for the post-commit reindex hook (step 5c)
- **`scripts/embeddings.py`** — Shared embedding backend, imported by `cortex-index.py`; not invoked directly
- **`scripts/cortex-reindex-post-commit.sh`** — Copied to `~/.cortex-forge/bin/hooks/` and wired into `{vault}/.git/hooks/post-commit` (step 5c)

## Sub-tasks

When an argument is provided, always run step 1 (vault detection) first, then jump directly to the relevant step(s) — skip everything else:

| Argument | Runs |
|---|---|
| `embeddings` | Step 5 — dependency check + tailored offer for semantic search |
| `skills` | Step 4 — verify skills are installed, point to `npx skills add` if not |
| `sync` | Step 3b — sync infrastructure files from upstream repo |
| `vaults` | Steps 2–3a — register/update vault in config |

Always end with the relevant subset of step 7 (confirmation).

## Steps

1. **Detect vault from CWD** — validate that the current directory is a valid vault:
   - Required: `.git/`, `wiki/`, `AGENTS.md`
   - If validation fails, report what's missing and stop.
   - Derive vault name from `basename` of CWD (e.g., `/Users/jp/second-brain` → `second-brain`).

2. **Read existing config** — read `~/.cortex-forge/config.yml` if it exists.
   - Check if the current vault path is already registered.
   - **If not registered** → vault is new. Proceed through steps 3–7 in full, asking each optional step interactively.
   - **If already registered** → vault exists. Skip steps 3–7. Instead show a menu (step 2b) and execute only what the user selects.

2b. **Maintenance menu (existing vault only)** — present a numbered list of available operations. The user can select one or more numbers (comma-separated), or "all":

   ```
   Vault "{name}" is already registered. What would you like to do?

     1. Check skills        — verify all 6 are installed; points to `npx skills add` if not (that's the only installer now)
     2. Sync from upstream  — pull updated templates and bin scripts from the upstream repo
     3. Initialize semantic search — build .cortex/vault.db for the first time (checks what's available, then offers accordingly)
     4. Add post-commit prune    — install the vault-report refresh git hook
     5. Add post-commit reindex  — install the embedding reindex git hook (requires semantic search)
     6. Remove this vault   — deregister from config.yml
     7. Set as default      — make this vault the default
     8. Change locale       — update the vault's locale in config.yml
     9. Set stale-cache threshold — configure hot_cache_stale_days (global, applies to all vaults)
   ```

   For each selected operation, run the corresponding step in sequence:
   - 1 → step 4
   - 2 → step 3b
   - 3 → step 5 (same tailored dependency-check-then-offer procedure as the new-vault wizard). Skip indexing if `.cortex/db/vault.db` already exists (ask user if they want to re-index instead).
   - 4 → step 5b
   - 5 → step 5c (gate still applies: if vault.db doesn't exist, offer option 3 first)
   - 6 → remove vault from `vaults:`, update default if needed, save config, stop
   - 7 → step 6
   - 8 → steps 3 and 3a (re-run the locale prompt and config write)
   - 9 → step 3c

   After all selected operations complete, show confirmation (step 7) for only the operations that ran.

3. **Set vault locale (new vault only)** — detect the language of the current conversation and propose it as the default, asking for confirmation:

   ```
   Detected you're writing in {detected-language}. Set this vault's locale to "{code}"?

   This determines the language cortex-assimilate, cortex-crystallize, and
   cortex-imprint use when writing new content to the vault (wiki pages,
   session snapshots, permanent knowledge pages).

     1. {code} (detected — matches this conversation)
     2. en
     3. Other (type an ISO 639-1 code)
   ```

   Use the chosen code (ISO 639-1, e.g. `en`, `es`, `pt`) in steps 3a and 7 below.

3a. **Write config** — add the vault entry in `~/.cortex-forge/config.yml` (new vault only):

   ```yaml
   vaults:
     {name}:
       path: {absolute-path}
       locale: {code}
     # ... other registered vaults preserved as-is
   default: {name}   # set as default only if this is the first vault, or if it was already default
   ```
   - Create `~/.cortex-forge/` if it doesn't exist.
   - Preserve all existing vault entries — never overwrite other vaults.
   - If this is the first vault registered, set it as `default`.
   - If a `default` already exists, leave it unchanged.

3b. **Sync infrastructure from upstream** — pull infrastructure files from the upstream repo and apply them to the current vault. See `references/UPSTREAM-SYNC.md` (co-located with this skill) for resolution, sync scope, exclusions, and rate limits.

3c. **Offer stale-cache warning threshold (opt-in, global setting)** — this is a single global value in `~/.cortex-forge/config.yml` (top-level, like `imprint_triage`), not per-vault. Read the config first:
    - **If `hot_cache_stale_days:` is already set** → inform the user of the current value and ask if they want to change it, rather than asking as if for the first time.
    - **If not set** → ask: "Warn if this vault's memory hasn't been touched in N days? (default: 15, 0 to disable)"
    - Write the chosen value as `hot_cache_stale_days: N` at the top level of `config.yml` (not nested under `vaults:`).
    - This is read by the `AGENTS.md` Crystallize protocol (step 2) to compare against `MEMORY.md`'s `updated:` frontmatter.

4. **Verify global skills are installed** — cortex-forge has no installer of its own; the sole distribution channel is [skills.sh](https://www.skills.sh/) (`npx skills add`), which is agent-agnostic by design (installs to whichever of the 40+ agents it recognizes, not a hardcoded pair). Check whether the 6 skills (`cortex-crystallize`, `cortex-forge-setup`, `cortex-recall`, `cortex-assimilate`, `cortex-imprint`, `cortex-prune`) are present under `~/.agents/skills/`.
   - **All present** → this step is done implicitly (running this skill at all means it was already installed by something). Report which skills are present and move on.
   - **Some missing** — do not attempt to install them yourself. Tell the user:
     > Missing skills: {list}. Install them with:
     > ```
     > npx skills add itsmistermoon/cortex-forge --all -g -y
     > ```
     > To limit which agents get symlinks (the default installs to every agent skills.sh recognizes), pass `-a <agent>` instead of `--all` — see the [Supported Agents table](https://github.com/vercel-labs/skills#supported-agents) for the exact flag per agent.
   - Never hand-roll agent-specific symlink logic here — that duplicates what `npx skills add` already does correctly for every agent it supports, not just whichever ones this skill happened to hardcode.

5. **Offer semantic search (new vault only — for an already-registered vault, use maintenance menu option 3 instead)** — check dependencies *before* asking, so the offer itself is tailored to what's actually available. Run the detection procedure in `references/EMBEDDING-SETUP.md` (co-located with this skill), then ask using the tailored wording it returns (ready-to-go confirm, one-step-away confirm, or the full backend menu) — never ask a generic "enable semantic search?" without having checked first. If the user accepts, install anything needed and run `scripts/cortex-index.py` (co-located with this skill) with `{vault}` as its argument; report chunks indexed. If declined or skipped, note in the final summary that semantic search is not active and can be enabled later via `/cortex-forge-setup` (maintenance menu, option 3).

5b. **Post-commit prune (opt-in, separate question)** — see `references/POST-COMMIT-HOOKS.md` (co-located with this skill) for the exact install mechanics.

5c. **Post-commit re-index (opt-in, separate question)** — see `references/POST-COMMIT-HOOKS.md` (co-located with this skill) for the exact install mechanics.

5d. **Embedding dependency check** — the procedure step 5 (and its fallback inside 5c) both run. Also triggered if `cortex-index.py` fails with an import error after this check already passed (dependency became unavailable mid-session). See `references/EMBEDDING-SETUP.md` (co-located with this skill) for the full detection-and-offer procedure.

6. **Set default vault** — if more than one vault is registered:
   - Ask: "Which vault should be the default? ({list of registered names})"
   - Update `default:` in the config with the chosen name.
   - If only one vault is registered, set it as default automatically without asking.

7. **Confirm result**:
   - Registered vaults: list all entries in `vaults:` with their paths and locales, marking the default
   - Skills: all 6 present / missing {list} (with the `npx skills add` command to fix it)
   - Semantic search: active (backend: Ollama/mlx-embeddings/sentence-transformers, N chunks indexed) / not active (declined or skipped — how to enable later)
   - Stale-cache threshold (if set/changed): `hot_cache_stale_days` value, or "default (15)" if left unset
   - Sync (if run): upstream used, files updated (list), files skipped (count), deletions pending user confirmation, AGENTS.md divergence noted if any
   - Next step: invoke `/cortex-crystallize` at the end of any project session

## Memory model (manual, no agent lifecycle hooks)

Cortex Forge does not use SessionStart/PreCompact/SessionEnd/PreToolUse hooks on any agent — support for those events is too uneven across agents to build the suite on top of them. Instead, every agent behaves the same way:

- **Load memory**: the agent reads `.cortex/MEMORY.md` itself (per `AGENTS.md` instructions) at the start of a session, or the user invokes `/cortex-recall`.
- **Save memory**: the user (or the agent, per `AGENTS.md` instructions near the end of a session) invokes `/cortex-crystallize` manually to append a snapshot to `.cortex/MEMORY.md`.

This is deliberately identical across agents — no per-agent hook wiring, no symlink maintenance, no `settings.json`/`hooks.json` merges.

## Rules

- Always run from inside the vault directory — never ask for a path manually
- Do not modify any vault files during setup — read only for validation
- Preserve all existing vault entries when writing config
- Never hand-roll skill installation or agent-specific symlinks — `npx skills add` is the sole installer, for every agent it supports
- Post-commit git hooks (prune, reindex — steps 5b/5c) are the only hooks this skill installs; they are plain git hooks, not agent lifecycle hooks, so they behave identically regardless of which agent is in use
- Always ask for default when there are multiple vaults — never assume
