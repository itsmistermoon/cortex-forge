---
title: CommandCode TASTE
type: concept
created: 2026-06-08
updated: 2026-06-08
tags: [commandcode, taste, personalization, learning, per-project, global]
aliases: [TASTE, taste commandcode]
sources:
  - wiki/sources/commandcode-taste-blog.md
  - wiki/sources/commandcode-taste-docs.md
  - wiki/sources/commandcode-taste-manage.md
  - wiki/sources/commandcode-taste-commands.md
confidence: high
---

# CommandCode TASTE

TASTE is the continuous personalization system of [[wiki/entities/commandcode]] (see [[wiki/concepts/agent-hook-compatibility]] for agent context). It learns from user actions — acceptances, rejections, edits — and generates `taste.md` files that condition code generation in future sessions. No manual initial configuration is required; the system creates and maintains them automatically.

## Scope: per-project and global

TASTE has **two scopes with concrete paths**:

| Scope       | Path                        | CLI flag       |
|-------------|-----------------------------|----------------|
| Per-project | `.commandcode/taste/`       | (default)      |
| Global      | `~/.commandcode/taste/`     | `-g`           |
| Remote      | `commandcode.ai/username/taste` | (Studio)   |

The per-project scope is the primary one. Files can be split automatically by domain (APIs, frontend components, backend) as the project grows. The global scope allows carrying learned preferences to any project without relearning from scratch.

## File format

`taste.md` files are human-readable and inspectable. Each entry includes a confidence score (0.0–1.0) based on observed consistency:

```
## TypeScript
- Use strict mode. Confidence: 0.80
- Prefer explicit return types on exported functions. Confidence: 0.65
```

High scores indicate established patterns; low scores indicate preferences still forming.

## Learning loop

```
generate → observe (accept/reject/edit) → extract → learn → apply
```

Feedback is **implicit**: no explicit annotation required. The underlying model is `taste-1`, a neuro-symbolic architecture that separates LLM knowledge (neural) from user preferences (symbolic).

Conceptual formula: `output = LLM(prompt | taste(user))`

## Management: CLI commands

```bash
# Per-project scope
npx taste push --all              # uploads entire .commandcode/taste/ folder to Studio
npx taste pull username/project   # pulls a profile from Studio to the local project

# Global scope
npx taste push [package] -g       # pushes to global scope
npx taste pull [package] -g       # pulls to global scope

# Other
npx taste list                    # lists available profiles in Studio
npx taste lint                    # validates package format
npx taste open                    # opens packages in editor
```

`npx taste` and `cmd taste` are equivalent.

## Three-layer stack

| Layer      | Source              | Update            | Result     |
|------------|---------------------|-------------------|------------|
| **TASTE**  | Auto-learned        | Each session, auto | Personal  |
| **Skills** | User-authored       | Manual            | Universal  |
| **Rules**  | User-written        | Manual            | Universal  |

"Skills increase capability. Taste increases alignment."

## Relevance for cortex-forge

The pending [[wiki/pages/cortex-forge]] item about TASTE rule scope for `cortex-recall` is resolved by this ingestion:

- **The decision is contextual**: if the rule is vault-specific → `.commandcode/taste/` (per-project); if it should apply in any project where `cortex-recall` is used → `~/.commandcode/taste/` (global with `-g`).
- `cortex-forge-setup` can populate both locations; the question is which one to offer as the default to the user.

---

- 2026-06-08 [Claude Code]: Page created from 4 official CommandCode sources
- 2026-06-08 [Claude Code]: Translated to English
