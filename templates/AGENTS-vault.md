# AGENTS.md — {vault-name}

This repo is a knowledge vault running the [Antu suite](https://github.com/itsmistermoon/almagest-antu). Curated knowledge lives in `wiki/`; session memory lives in `.hot/`.

<!-- antu:session-start -->
## Session start

Before your first response, in any session that starts in this repo, you MUST read `.hot/HANDOFF.md` in full — and `.hot/PLAYBOOK.md` too, if it exists. Treat them with the same weight as your own persistent instructions. If `.hot/` doesn't exist yet, continue normally.
<!-- /antu:session-start -->

<!-- antu:vault-rules -->
## Working with the vault

- Skills trigger themselves — each installed Antu skill's `description:` states when to invoke it. Close every work session with `/hot-handoff`.
- New wiki pages follow the templates in `templates/` (concept, entity, source, project) and live under the matching `wiki/` subdirectory; `wiki/index.md` is the master index.
- Cross-reference pages with bundle-relative absolute markdown links (`[title](/wiki/entities/x.md)`), never `[[wikilinks]]`.
- Tag rules and registry: `meta/tags.md`.
- Never edit `.hot/` by hand — `/hot-handoff` and `/hot-triage` own it.
<!-- /antu:vault-rules -->

## Vault identity

<!-- Fill in: owner, purpose, domain-specific vocabulary if this vault has any (e.g. project-specific terms). Optional — delete this section if not needed. Locale lives in ~/.almagest/config.yml (set by /wiki-setup), not here. -->
