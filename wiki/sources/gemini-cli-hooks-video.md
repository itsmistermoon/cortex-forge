---
title: "Gemini CLI Hooks & Skills — Google Cloud Live"
type: source
resource: 
created: 2026-06-08
updated: 2026-06-08
tags: [gemini-cli, hooks, skills, lifecycle, configuration]
source_url: https://www.youtube.com/watch?v=ZXYuiEMm21s
source_date: 2026-06-08
source_author: Google Cloud Live — Jack Weatherspoon (Gemini CLI team)
sources:
  - .raw/gemini-cli-hooks-video.md
confidence: medium
schema_version: "0.3"
raw: 
---

# Gemini CLI Hooks & Skills — Google Cloud Live

**URL:** https://www.youtube.com/watch?v=ZXYuiEMm21s
**Author:** Jack Weatherspoon, Gemini CLI team — Google Cloud Live
**Format:** video transcript (auto-subtitles, medium quality)

## Summary

Advanced Gemini CLI demo video focused on hooks, skills, and plan mode. The presenter (Jack Weatherspoon, Gemini CLI team) builds an application live to illustrate each feature.

Relevant to Cortex Forge because Antigravity CLI inherits from the Gemini CLI ecosystem — its hooks and skills system shares the same origin and base conventions.

## Key Ideas

1. **Hooks are configured in `settings.json`**: hook configuration goes inside the `hooks:` block of `settings.json`, the central configuration file for Gemini CLI. Not in a separate `hooks.json`.
2. **Scripts can live at any path**: "wherever you want" — there is no platform-imposed script path. Only the path in `settings.json` needs to be correct.
3. **Context injection via stdout**: hooks send context to Gemini CLI through stdout. The content is injected into the current turn before the model responds.
4. **Session start hook for loading context**: explicit use case — load the last 5 git commits, load previous session context, etc. This is the exact equivalent of Cortex Forge's hot cache protocol.
5. **Two scopes**: user-scope (available across all projects, lives in `~/.gemini/`) and workspace-scope (project-specific, lives in local `.gemini/` or `.agents/`).
6. **Skills standardized folder**: `.agents/skills` is the standardized provider-agnostic folder. Gemini CLI also reads from `.gemini/skills`. The multi-agent standard is `.agents/`.
7. **Progressive disclosure**: central pattern for hooks and skills — instead of loading all context upfront, context is loaded only when needed. See [[wiki/concepts/progressive-disclosure-hooks]].

## Connections
- Related concepts: [[wiki/concepts/antigravity-hooks]], [[wiki/concepts/agent-hook-compatibility]], [[wiki/concepts/progressive-disclosure-hooks]]
- Entities: [[wiki/entities/google-antigravity]]

---

- 2026-06-08 [Claude Code]: Page created — video transcript downloaded with yt-dlp; relevance: Antigravity inherits Gemini CLI conventions
- 2026-06-08 [Claude Code]: Translated to English
