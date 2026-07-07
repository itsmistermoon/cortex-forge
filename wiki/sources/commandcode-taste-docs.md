---
title: "TASTE — Official CommandCode Documentation"
type: source
resource: https://commandcode.ai/docs/taste
created: 2026-06-08
updated: 2026-06-08
tags: [commandcode, taste, documentation]
aliases: []
source_author: CommandCode
confidence: high
schema_version: "0.3"
raw: 
---

# TASTE — Official CommandCode Documentation

**URL:** https://commandcode.ai/docs/taste
**Original date:** 2026
**Author:** CommandCode

## Summary

Official TASTE documentation. Describes the `taste-1` model (meta neuro-symbolic with continuous reinforcement learning) and the learning mechanism via implicit signals (acceptances, rejections, edits). Emphasis on portability: preferences are not locked to a single project but are transferable and composable, similar to Git.

## Key ideas

1. TASTE uses the proprietary `taste-1` model with a neuro-symbolic architecture that separates model knowledge (neural) from user preferences (symbolic).
2. Portability is explicit: learned preferences can be used across all of the user's projects.
3. The documentation does not specify storage paths — that information is in `/docs/taste/commands`.

## Connections
- Related concepts: [[wiki/concepts/commandcode-taste]]
- Projects: [[wiki/projects/cortex-forge]]

---

- 2026-06-08 [Claude Code]: Page created
- 2026-06-08 [Claude Code]: Translated to English
