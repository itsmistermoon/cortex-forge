---
title: "OpenWiki — GitHub README + internal docs"
type: source
resource: https://github.com/langchain-ai/openwiki
created: 2026-07-01
updated: 2026-07-01
timestamp: 2026-06-22
source_author: LangChain AI
tags: [codebase-documentation, agent-tools, github-actions, langchain, deepagents]
confidence: high
schema_version: "0.3"
raw: .raw/openwiki.md
---

# OpenWiki — GitHub README + internal docs

**URL:** https://github.com/langchain-ai/openwiki
**Original date:** 2026-06-22 (repo created), ingested 2026-07-01
**Author:** LangChain AI

## Summary

OpenWiki is a TypeScript CLI that generates and maintains codebase documentation for AI coding agents. It runs an LLM agent (via DeepAgents, a LangChain agent framework) against the repo, produces a structured `openwiki/` wiki directory, and injects a reference into `AGENTS.md` and/or `CLAUDE.md`. The key differentiator is automated maintenance: a GitHub Actions workflow runs `openwiki --update` on a schedule, uses git diffs since the last successful run, and opens a PR only when documentation actually changed (verified via SHA-256 content snapshot).

## Key ideas

1. **Git-diff-scoped updates** — `--update` computes which commits landed since `.last-update.json`'s `gitHead` and feeds only that diff window to the agent, keeping updates incremental and grounded in evidence rather than re-generating from scratch.
2. **Content snapshot guard** — SHA-256 hash of `openwiki/` (excluding `.last-update.json`) is taken before and after the agent run. Metadata is written only if the hash changed — prevents CI loop churn when docs are already current.
3. **AGENTS.md/CLAUDE.md injection** — the agent is prompted to insert or refresh a standardized section in these instruction files, pointing the coding agent to `openwiki/quickstart.md`. This is the bridge between the generated wiki and the coding agent's context.
4. **Multi-provider, open-model-first** — defaults to OpenRouter with GLM 5.2 (a cheap open model). Supports Anthropic, OpenAI, Fireworks, Baseten. Provider resolved from env vars; model overridable via `OPENWIKI_MODEL_ID`.
5. **SQLite checkpointing** — DeepAgents uses `~/.openwiki/openwiki.sqlite` keyed by repo path hash, persisting conversation threads across runs for continuity.

## Architecture

```
src/
  cli.tsx          — Ink UI, run lifecycle, auto-exit for init/update
  commands.ts      — argv parsing, help
  credentials.tsx  — interactive onboarding (provider, key, model, LangSmith)
  env.ts           — ~/.openwiki/.env read/write, credential diagnostics
  constants.ts     — PROVIDER_CONFIGS, model lists, env keys, validation
  agent/
    index.ts       — agent runtime, model creation, Git context, metadata writes
    prompt.ts      — system + user prompt assembly, AGENTS.md injection rules
    utils.ts       — Git evidence, SHA-256 snapshot, .last-update.json
    types.ts       — OpenWikiCommand, RunContext, UpdateMetadata
```

## GitHub Actions pattern

```yaml
on:
  schedule: [{cron: "0 8 * * *"}]   # daily
steps:
  - checkout + install openwiki
  - run: openwiki --update --print
  - uses: peter-evans/create-pull-request@v7
    with: {add-paths: openwiki, branch: openwiki/update}
```

`--print` flag makes it non-interactive (one-shot). PR is opened only if `openwiki/` changed.

## Connections

- Related concepts: [[wiki/concepts/karpathy-wiki-pattern]], [[wiki/concepts/knowledge-graph-code-intelligence]], [[wiki/concepts/super-context]]
- Related entities: [[wiki/entities/graphify]], [[wiki/entities/understand-anything]], [[wiki/entities/codebase-memory-mcp]]
- Projects: [[wiki/projects/cortex-forge]]

---

- 2026-07-01 [Claude Code]: Page created — README + architecture/overview.md + agent/workflow.md + examples/openwiki-update.yml ingested from github.com/langchain-ai/openwiki
