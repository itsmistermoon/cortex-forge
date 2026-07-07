---
type: source
title: "Pi Packages"
resource: https://pi.dev/docs/latest/packages
created: 2026-06-16
updated: 2026-06-16
tags: [pi, packages, npm, git, distribution, security]
aliases: []
confidence: high
schema_version: "0.3"
raw: .raw/pi-packages.md
---

# Pi Packages

**URL:** https://pi.dev/docs/latest/packages
**Original date:** 2026-06-16
**Author:** Mario Zechner / pi-mono

## Summary

Distribution format for sharing pi extensions, skills, prompt templates, and themes through npm or git. Covers install/remove/update CLI, package sources (npm / git / local paths), the `pi` manifest in `package.json`, conventional auto-discovery directories, peer vs bundled dependencies, package filtering, enable/disable via `pi config`, and scope/deduplication rules. Includes an explicit security warning: packages run with full system access — review source before installing.

## Key ideas

1. **Install commands manage packages, not the CLI** — `pi install`, `pi remove`, `pi list`, `pi update`, `pi update --extensions`, `pi update --self [--force]`, `pi update <source>`. By default writes to user settings (`~/.pi/agent/settings.json`); `-l` writes to project (`.pi/settings.json`). One-off: `pi -e npm:@foo/bar` installs to a temp dir for the current run.
2. **Three source kinds** — `npm:@scope/pkg@1.2.3` (pinned, skipped by updates), `git:github.com/user/repo@v1` (HTTPS/SSH/`git@` shorthand; cloned to `~/.pi/agent/git/<host>/<path>`; reconciliation resets/cleans and re-runs `npm install`), and local paths (`/abs` or `./rel`; not copied; file = one extension, dir = package rules).
3. **Manifest in `package.json`** — declare `pi.extensions`, `pi.skills`, `pi.prompts`, `pi.themes` as arrays of relative paths with glob/`!exclusion` support. Add `pi-package` keyword for the [gallery](https://pi.dev/packages) and `pi.video` / `pi.image` for preview.
4. **Convention directories auto-discover when no manifest** — `extensions/` (`.ts`/`.js`), `skills/` (recursive `SKILL.md` + top-level `.md`), `prompts/` (`.md`), `themes/` (`.json`).
5. **Dependency discipline** — core packages (`@earendil-works/pi-ai`, `@earendil-works/pi-agent-core`, `@earendil-works/pi-coding-agent`, `@earendil-works/pi-tui`, `typebox`) go in `peerDependencies: "*"` (do not bundle). Other pi packages must be `bundledDependencies` with `node_modules/` paths in the manifest, because pi loads packages with separate module roots.
6. **Filtering layers on top of the manifest** — `packages: [{ source, extensions: [...], skills: [...], prompts: [...], themes: [...] }]` with `!pattern` exclude, `+path` force-include, `-path` force-exclude. Empty `[]` disables that type entirely.
7. **Scope and dedup** — same package in both global and project settings: project wins. Identity by npm name / git URL without ref / local absolute path. `pi config` toggles enable/disable for each resource type from installed packages.
8. **Security banner** — "Pi packages run with full system access. Extensions execute arbitrary code, and skills can instruct the model to perform any action including running executables. Review source code before installing third-party packages."

## Connections
- Related concepts: [[wiki/concepts/pi-extension-lifecycle]]
- Projects: [[wiki/entities/pi-cli]]
- Sources: [[wiki/sources/pi-extensions]], [[wiki/sources/pi-usage]], [[wiki/sources/pi-custom-provider]]

---

- 2026-06-16 [CommandCode]: Page created
