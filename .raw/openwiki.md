# OpenWiki — Raw ingestion
Source: https://github.com/langchain-ai/openwiki
Fetched: 2026-07-01
Stars: 43 | Language: TypeScript | License: MIT | Created: 2026-06-22

---

## README

OpenWiki is a CLI that writes and maintains documentation for your codebase, built specifically for agents.

### Install
```sh
npm install -g openwiki
```

### Quick Start
```sh
openwiki --init
```
Then add the GitHub action to auto-update docs once a day (openwiki-update.yml).

### Usage
- `openwiki` — interactive CLI
- `openwiki "..."` — start with initial request
- `openwiki -p "..."` — one-shot non-interactive
- `openwiki --init` — initialize
- `openwiki --update` — update existing docs
- `openwiki --help`

Creates initial documentation in `openwiki/` when no wiki exists. If `openwiki/` already exists, refreshes from repository changes. Automatically appends prompting to AGENTS.md and/or CLAUDE.md to instruct the coding agent to reference the wiki. Creates AGENTS.md/CLAUDE.md if they don't exist.

Config saved to `~/.openwiki/.env`. Providers: OpenRouter (default), Fireworks, Baseten, OpenAI, Anthropic. Optional LangSmith tracing to project "openwiki".

---

## Architecture Overview (openwiki/architecture/overview.md)

Layered architecture:
1. `src/cli.tsx` — Ink-based interactive terminal app, orchestrates runs, auto-exit for init/update
2. `src/commands.ts` — argv parsing, help text, supported options
3. `src/credentials.tsx` — interactive onboarding: provider selection, API keys, model, LangSmith
4. `src/env.ts` — reads/writes `~/.openwiki/.env`, credential diagnostics
5. `src/agent/index.ts` — documentation agent runtime, provider resolution, Git context, update metadata
6. `src/agent/prompt.ts` — system + user prompt assembly
7. `src/agent/utils.ts` — Git evidence, content snapshot (SHA-256), `.last-update.json`
8. `src/constants.ts` — provider configs, model options, env keys, validation
9. `src/agent/types.ts` — shared types: OpenWikiCommand, RunContext, UpdateMetadata

### Provider resolution
1. If `OPENWIKI_PROVIDER` set and valid → use it
2. If `OPENROUTER_API_KEY` present → default to openrouter
3. Otherwise → DEFAULT_PROVIDER (openrouter)

### Model creation by provider
- anthropic → `ChatAnthropic`
- openrouter → `ChatOpenRouter` with `route: "fallback"` + fallback model list
- baseten / fireworks / openai → `ChatOpenAI` with custom baseURL

### DeepAgents backend
`LocalShellBackend` rooted at repository, `virtualMode: true`, `maxOutputBytes: 100_000`, 120s timeout. SQLite checkpointer at `~/.openwiki/openwiki.sqlite`, keyed by hash of repo path.

### Content snapshot and metadata
SHA-256 of entire `openwiki/` directory (excluding `.last-update.json`). Metadata written ONLY if snapshot changed — prevents scheduled loop churn when docs are already current.

---

## Agent Workflow (openwiki/agent/workflow.md)

Main flow for non-chat runs:
1. Load `~/.openwiki/.env`
2. Resolve provider and ensure API key exists
3. Resolve model ID from CLI / env / provider default
4. Create RunContext from Git state + prior update metadata
5. Snapshot current `openwiki/` content hash (pre-run)
6. Build system + user prompts
7. Create provider-specific model client
8. Create DeepAgents `LocalShellBackend`
9. Stream messages and tool events to CLI
10. For init/update: compare post-run vs pre-run snapshot; write `.last-update.json` only if changed

### Prompting strategy (src/agent/prompt.ts)
Agent is instructed to:
- inspect codebase and write docs under `openwiki/`
- use filesystem discovery tools and git history (not invention)
- keep wiki focused and navigable
- avoid thin/slim pages — merge stubs into broader pages
- document for both humans and future agents
- scope to repository root only
- avoid reading secrets or `.env` files
- use git history for init and update runs
- ensure top-level AGENTS.md and/or CLAUDE.md reference the OpenWiki quickstart

User prompt varies by command:
- `init` — current Git summary, asks for fresh docs
- `update` — last update metadata + Git change summary since last run
- `chat` — forwards user message

### Git evidence (src/agent/utils.ts)
- `git status --short`
- `git rev-parse HEAD`
- `git log --max-count=20 --name-status --oneline` (init or update without prior metadata)
- `git log <lastHead>..HEAD --name-status --oneline` (update with recorded gitHead)
- `git log --since <updatedAt> --name-status --oneline` (update with only timestamp)
- `git diff --name-status HEAD`

### Update metadata (.last-update.json)
Written on successful init/update where content changed:
- `updatedAt`
- `command`
- `gitHead`
- `model`

Used to scope future update runs to changes since last successful run.

### Model fallback (OpenRouter only)
Selected model tried first → HTTP 5xx falls back through `OPENROUTER_FALLBACK_MODEL_IDS` → retries with modified thread ID to avoid checkpointer collisions.

---

## GitHub Actions Workflow (examples/openwiki-update.yml)

```yaml
name: OpenWiki Update
on:
  workflow_dispatch:
  schedule:
    - cron: "0 8 * * *"  # 08:00 UTC = midnight PST daily

permissions:
  contents: write

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { persist-credentials: true }
      - uses: actions/setup-node@v4
        with: { node-version: "22" }
      - run: npm install --global openwiki
      - run: openwiki --update --print
        env:
          OPENROUTER_API_KEY: ${{ secrets.OPENROUTER_API_KEY }}
          OPENWIKI_MODEL_ID: z-ai/glm-5.2
          LANGSMITH_API_KEY: ${{ secrets.LANGSMITH_API_KEY }}
          LANGCHAIN_PROJECT: openwiki
          LANGCHAIN_TRACING_V2: "true"
      - uses: peter-evans/create-pull-request@v7
        with:
          add-paths: openwiki
          branch: openwiki/update
          commit-message: "docs: update OpenWiki"
          title: "docs: update OpenWiki"
```
