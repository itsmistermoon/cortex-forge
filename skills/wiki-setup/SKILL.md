---
name: wiki-setup
license: MIT
compatibility: Requires git and npx (Node.js); python3 only for optional semantic search
description: Register or deregister the current vault in Antu and verify global skills are installed. Run from inside a vault directory.
disable-model-invocation: true
argument-hint: "Optional sub-task: embeddings | skills | sync | vaults"
---

Start your response with the flavor line `Setting up vault...`, translated to the language of the user's current message (Spanish: `Configurando vault...`), with nothing before it. Use that same language for every prompt, question, menu, and confirmation this skill produces — persisted vault content (if any) still follows the vault's locale, not the conversation language.

Setup for Antu. Run from inside a vault directory (one containing `.git/`, and either an existing `wiki/` + `AGENTS.md`, or willing to scaffold them — see step 1). Registers the vault in the global config. This skill does not install skill files itself — [skills.sh](https://www.skills.sh/) (`npx skills add`) is the sole installer, for every agent it supports, not a hardcoded pair.

## Available scripts

Paths are relative to this skill's directory.

- **`scripts/index.py`** — Builds/refreshes `.hot/db/vault.db` when semantic search is enabled (step 5); also copied to `~/.almagest/bin/` for the post-commit reindex hook (step 5a)
- **`scripts/embeddings.py`** — Shared embedding backend, imported by `index.py`; not invoked directly
- **`scripts/reindex-post-commit.sh`** — Copied to `~/.almagest/bin/hooks/` and wired into `{vault}/.git/hooks/post-commit` (step 5a)
- **`scripts/tags-audit.py`** — Runs a tags audit on a vault (maintenance menu option 10); optionally writes a dated snapshot under `wiki/meta/`

## Sub-tasks

When an argument is provided, always run step 1 (vault candidate check) first, then jump directly to the relevant step(s) — skip everything else:

| Argument | Runs |
|---|---|
| `vaults` | Step 2 |
| `sync` | Step 3b |
| `skills` | Step 4 |
| `embeddings` | Step 5 |

Always end with the relevant subset of ## Output format.

## Steps

1. **Validate vault candidate** — confirm the current directory qualifies to be registered as a vault:
   - Required: `.git/`.
   - If `.git/` is missing, report it and stop.
   - If `wiki/` and/or `AGENTS.md` are missing, don't stop — see `references/NEW-VAULT-SCAFFOLD.md` to disambiguate a new vault from a broken one, and scaffold on confirmation.
   - Derive vault name from `basename` of CWD (e.g., `/Users/jp/second-brain` → `second-brain`).

2. **Read existing config** — from `~/.almagest/config.yml`, if it exists.
   - Check if the current vault path is already registered.
   - **If not registered** → vault is new. Proceed through steps 3–6 in full, then ## Output format.
   - **If already registered** → vault exists. Skip steps 3–6. Instead, show the menu in `references/MAINTENANCE-MODE.md` and execute only what the user selects.

3. **Set vault locale** — detect the language of the current conversation and propose it as the default, asking for confirmation:

   ```
   Detected you're writing in {detected-language}. Set this vault's locale to "{code}"?

   This determines the language wiki-ingest, hot-handoff, and
   wiki-imprint use when writing new content to the vault (wiki pages,
   session snapshots, permanent knowledge pages).

     1. {code} (detected — matches this conversation)
     2. en
     3. Other (type an ISO 639-1 code)
   ```

   Use the chosen code (ISO 639-1, e.g. `en`, `es`, `pt`) in step 3a and the final confirmation (## Output format) below.

3a. **Write config** — add the vault entry in `~/.almagest/config.yml`:

   ```yaml
   vaults:
     {name}:
       path: {absolute-path}
       locale: {code}
     # ... other registered vaults preserved as-is
   default: {name}   # set as default only if this is the first vault, or if it was already default
   ```
   - Create `~/.almagest/` if it doesn't exist.
   - Preserve all existing vault entries — never overwrite other vaults — and all other top-level keys (`upstream:`, `upstream_ref:`, `imprint_triage:`, `playbook_stale_days:`, etc.) unchanged. Read the full file, merge in the new vault entry, and write back the whole document — never reconstruct it from only the fields this step cares about.
   - If this is the first vault registered, set it as `default`. If a `default` already exists, leave it unchanged.

3b. **Sync infrastructure from upstream** — pull infrastructure files from the upstream repo: vault templates into the current vault, and shared skill references into `~/.almagest/references/` (global, once per machine). See `references/UPSTREAM-SYNC.md` for resolution, sync scope, exclusions, and rate limits.

   - **Vault templates** — if this is a new vault (scaffolded in step 1), proceed without asking (templates are part of the scaffolding the user already confirmed); if existing, ask before updating, per UPSTREAM-SYNC.md step 4.
   - **Global shared references** (`~/.almagest/references/`) — always ask before writing, new vault or not. Confirming local vault scaffolding is not consent to write machine-global files that affect every other vault. See UPSTREAM-SYNC.md step 4.

3c. **Offer stale-cache warning threshold (opt-in, global setting)** — this is a single global value in `~/.almagest/config.yml` (top-level, like `imprint_triage`), not per-vault. Read the config first:
    - **If `playbook_stale_days:` is already set** → inform the user of the current value and ask if they want to change it, rather than asking as if for the first time.
    - **If not set** → ask: "Warn if this vault's memory hasn't been touched in N days? (default: 15, 0 to disable)"
    - Write the chosen value as `playbook_stale_days: N` at the top level of `config.yml` (not nested under `vaults:`).
    - This is read by the `AGENTS.md` Handoff protocol (step 2) to compare against `HANDOFF.md`'s `updated:` frontmatter.

4. **Verify global skills are installed** — check each of the 7 skills (`hot-handoff`, `wiki-setup`, `wiki-query`, `wiki-ingest`, `wiki-imprint`, `wiki-lint`, `hot-triage`) individually for presence under `~/.agents/skills/` — do not assume presence just because this skill is running.
   - **All present** → report which 7 skills are present and move on.
   - **Some missing** — do not attempt to install them yourself. Tell the user:
     > Missing skills: {list}. Install them with:
     > ```
     > npx skills add itsmistermoon/almagest-antu --all -g -y
     > ```

5. **Offer semantic search** — check dependencies *before* asking, so the offer itself is tailored to what's actually available. Run the detection procedure in `references/EMBEDDING-SETUP.md`, then ask using the tailored wording it returns (ready-to-go confirm, one-step-away confirm, or the full backend menu) — never ask a generic "enable semantic search?" without having checked first. If the user accepts, install anything needed and run `scripts/index.py` with `{vault}` as its argument; report chunks indexed. If declined or skipped, note in the final summary that semantic search is not active and can be enabled later via `/wiki-setup` (maintenance menu, option 5). Re-run this same detection procedure any time it's needed again — from 5a's reindex-hook fallback, or if `index.py` later fails with an import error after this check already passed (dependency became unavailable mid-session).

5a. **Post-commit hooks (opt-in, separate questions)** — see `references/POST-COMMIT-HOOKS.md` for the exact install mechanics of both:
   - **Prune** — refresh `vault-report.json` after each commit.
   - **Reindex** — re-index vault embeddings after each commit (requires semantic search).

6. **Set default vault** — if more than one vault is registered:
   - Ask: "Which vault should be the default? ({list of registered names})"
   - Update `default:` in the config with the chosen name.
   - If only one vault is registered, set it as default automatically without asking.

## Output format

Confirm:
- Scaffold (if run): what was created (`wiki/` structure, `AGENTS.md` stub, `wiki/meta/tags.md`) — remind the user to fill in `AGENTS.md`'s "Vault identity" section themselves
- Registered vaults: list all entries in `vaults:` with their paths and locales, marking the default
- Skills: all 7 present / missing {list} (with the `npx skills add` command to fix it)
- Semantic search: active (backend: Ollama/mlx-embeddings/sentence-transformers, N chunks indexed) / not active (declined or skipped — how to enable later)
- Stale-cache threshold (if set/changed): `playbook_stale_days` value, or "default (15)" if left unset
- Sync (if run): upstream used, files updated (list), files skipped (count), deletions pending user confirmation
- Next step: invoke `/hot-handoff` at the end of any project session

For a maintenance-menu run, confirm only the items for operations that actually ran.

## Rules

- Always run from inside the vault directory — never ask for a path manually
- Never write to an *existing* `wiki/`, `.raw/`, or `AGENTS.md` — those are vault content, not this skill's to touch once they exist. The one exception is step 1's new-vault scaffold (`references/NEW-VAULT-SCAFFOLD.md`), which creates them from nothing, only on explicit confirmation, and never overwrites either if already present. Everything else this skill writes (global config, `templates/`, `.hot/db/`, git hooks) is infrastructure
- Never hand-roll skill installation or agent-specific symlinks — `npx skills add` is the sole installer, for every agent it supports
- Post-commit git hooks (prune, reindex — step 5a) are the only hooks this skill installs
