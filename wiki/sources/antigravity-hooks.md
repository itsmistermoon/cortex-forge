---
title: Google Antigravity Hooks
type: source
resource: 
created: 2026-06-07
updated: 2026-06-07
tags: [antigravity, hooks, session-management, configuration]
source_url: https://antigravity.google/docs/hooks
source_date: 2026-06-07
source_author: Google Antigravity Team
sources:
  - .raw/antigravity-hooks.md
confidence: high
schema_version: "0.3"
raw: 
---

# Google Antigravity Hooks

**URL:** https://antigravity.google/docs/hooks
**Original date:** 2026-06-07
**Author:** Google Antigravity Team

## Summary

This source documents the hooks mechanism in the Google Antigravity platform. Hooks enable executing custom scripts, commands, or logic at predefined execution lifecycle events (such as session startup or file saves) in both the desktop/CLI environment and via programmatic integration using the Antigravity SDK.

## Key Ideas

1. **Lifecycle Integration:** Hooks permit developers to intercept the agent's execution loop to run tests, enforce rules, or set context automatically.
2. **Configuration Interfaces:** Supports JSON configurations (`hooks.json` under `.agents/` or plugins directory) for simple scripting, and a programmatic Python SDK for advanced lifecycle interception and tool steering.
3. **SessionStart Event:** A primary lifecycle event triggered when starting a new session, used to load settings or auto-provision workspace resources.

## Connections
- Related concepts: [[antigravity-hooks]]
- Projects: [[google-antigravity]]

---

- 2026-06-07 [Antigravity]: Page created
