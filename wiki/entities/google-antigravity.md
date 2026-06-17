---
title: Google Antigravity
type: entity
created: 2026-06-07
updated: 2026-06-07
tags: [agent-platform, dev-tools, ecosystem]
aliases: [Antigravity, Antigravity CLI]
sources:
  - wiki/sources/antigravity-hooks.md
confidence: high
---

# Google Antigravity

Google Antigravity is Google's agent-first development platform and the standard environment for building software with autonomous AI agents. It shifts traditional software engineering towards autonomous, multi-agent workflows. It provides:
- **Antigravity 2.0 Desktop:** A graphical dashboard for parallel agent orchestration.
- **Antigravity CLI:** A terminal-based, developer-optimized tool for running agents, configuring custom skills, and using plugins.
- **Antigravity SDK:** A programmatic Python toolkit to build, run, and steer customized agent configurations.

## Relationships
- **Antigravity CLI** (`agy`) is the terminal component of this ecosystem — documented in detail at [[wiki/entities/antigravity-cli]].
- Uses [[antigravity-hooks]] to enable custom lifecycle scripting (like `SessionStart` actions).
- Serves as the active environment for executing developer assistants (such as the Antigravity agent).

---

- 2026-06-07 [Antigravity]: Page created
