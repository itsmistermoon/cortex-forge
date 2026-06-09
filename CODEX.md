---
type: codex
created: {{date:YYYY-MM-DD}}
updated: {{date:YYYY-MM-DD}}
---

# CODEX

Agent context for this vault. Read this after `.hot/{project}.md` on session start.
Partially filled is fine — empty sections are ignored.

## Mission

<!-- Why does this vault exist? One sentence.
     Agents use this to decide what's worth persisting and what's noise.
     Example: "Capture and connect knowledge for building AI-native products." -->

## Owner

<!-- Who are you? Role, expertise, preferences.
     Agents use this to calibrate explanations and assumptions.
     Example:
       role: Full-stack engineer, 8 years
       strong: Python, distributed systems, data modeling
       learning: Rust, ML infrastructure
       language: Spanish (Chilean) — avoid Argentine voseo
       tone: Direct. No filler. Short answers preferred. -->

## Domains

<!-- Knowledge areas this vault covers. Agents use this to decide what to ingest.
     List them — add a note if the scope within the domain is narrow.
     Example:
       - AI agents and LLM tooling
       - Developer productivity
       - Distributed systems — specifically event-driven architecture -->

## Vocabulary

<!-- Terms with specific meaning in this vault.
     Prevents agents from using generic definitions when this vault has its own.
     Example:
       - **hot cache**: session memory per project (.hot/), not persistent knowledge
       - **vault**: a knowledge base managed by Cortex Forge, not a password manager -->

## Out of scope

<!-- What should NOT be ingested or synthesized here.
     Explicit exclusions prevent vault pollution.
     Example:
       - Client work under NDA
       - Personal finance
       - News and current events without direct relevance to active projects -->
