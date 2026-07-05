---
title: "TASTE: Skills, Rules and Continuous Learning — CommandCode Blog"
type: source
resource: 
created: 2026-06-08
updated: 2026-06-08
tags: [commandcode, taste, learning, personalization]
source_url: https://commandcode.ai/blog/taste-skills-rules
source_date: 2026
source_author: CommandCode
sources: []
confidence: medium
schema_version: "0.3"
raw: 
---

# TASTE: Skills, Rules and Continuous Learning — CommandCode Blog

**URL:** https://commandcode.ai/blog/taste-skills-rules
**Original date:** 2026
**Author:** CommandCode

## Summary

Introductory article that positions TASTE within CommandCode's three-layer stack (TASTE > Skills > Rules). Explains the continuous learning loop (generate → observe → extract → learn → apply), per-project storage in `taste.md` files, and the underlying `taste-1` model. Presents empirical results showing reduced edit cycles after one month of use.

## Key ideas

1. TASTE is self-managed: it creates and maintains its own files each session without user intervention.
2. Primary scope is per-project; files live in `.commandcode/taste/` and can be automatically split by domain (API, frontend, backend).
3. Each learned rule includes a confidence score (0.0–1.0) based on observed consistency, not manually configured.

## Connections
- Related concepts: [[wiki/concepts/commandcode-taste]]
- Projects: [[wiki/projects/cortex-forge]]

---

- 2026-06-08 [Claude Code]: Page created
- 2026-06-08 [Claude Code]: Translated to English
