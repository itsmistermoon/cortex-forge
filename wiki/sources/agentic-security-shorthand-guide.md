---
type: source
title: "The Shorthand Guide to Everything Agentic Security"
resource: https://x.com/affaan
created: 2026-06-12
updated: 2026-06-12
tags: [security, prompt-injection, memory, hooks, mcp, supply-chain, sandboxing]
confidence: medium
schema_version: "0.3"
raw: .raw/agentic-security-shorthand-guide.md
---

# The Shorthand Guide to Everything Agentic Security

**URL:** X/Twitter thread (pasted by user)
**Original date:** 2026-03-15
**Author:** cogsec (@affaan) — third in the series after [[wiki/sources/claude-code-shorthand-guide]] and [[wiki/sources/claude-code-longform-guide]]

## Summary

Security guide for autonomous agents, anchored in the February 2026 Check Point disclosures against Claude Code (CVE-2025-59536, pre-trust code execution via project files/hooks, CVSS 8.7; CVE-2026-21852, API-key exfiltration via `ANTHROPIC_BASE_URL` override). Core thesis: everything an LLM reads is executable context, so project config, hooks, MCP settings, skills, and *persistent memory* are all attack surface. Prescribes isolation (identity separation, sandboxes, deny-by-default egress), sanitization, approval boundaries ("least agency"), observability, kill switches, and narrow disposable memory. Cites Anthropic, Microsoft, Snyk, Unit 42, and OWASP reports as primary references worth pulling directly.

## Key ideas

1. **Memory poisoning** — a payload doesn't need to win in one shot; it can plant fragments in persistent memory and assemble later (Microsoft "AI Recommendation Poisoning", Feb 2026: 31 companies, 14 industries). Directly applicable to Cortex Forge: `.hot/MEMORY.md` and the wiki are exactly this surface. See [[wiki/concepts/memory-as-attack-surface]].
2. **Lethal trifecta** (Simon Willison) — private data + untrusted content + external communication in one runtime turns prompt injection into exfiltration.
3. **Hooks and project config are execution surface** — CVE-2025-59536 ran repo-controlled hooks before the trust dialog. Cortex Forge *distributes* hook scripts and skills; that makes the template itself a supply-chain artifact for its users.
4. **Skills as supply chain** — Snyk ToxicSkills: 36% of 3,984 public skills contained prompt injection (1,467 malicious payloads). Scan skills/hooks/MCP configs like any dependency; cheap `rg` scans for zero-width/bidi Unicode, HTML comments, base64, egress commands, `ANTHROPIC_BASE_URL`.
5. **Least agency** — the safety boundary is the policy between model and action, not the system prompt. Deny-rules on secret paths (`~/.ssh`, `~/.aws`, `.env*`) and egress commands are the cheapest high-leverage control.
6. **Extraction/action separation** — one restricted agent parses untrusted documents; a privileged agent acts only on the cleaned summary. Relevant to `cortex-assimilate`, which reads foreign web content by design.
7. **Guardrail next to external links** in skills/rules — links that can change without approval are future injection sources; inline content when possible.
8. **Memory hygiene** — no secrets in memory files, separate project from global memory, reset/rotate after untrusted runs, disable long-lived memory for high-risk workflows.
9. Operational: identity separation for agents, `internal: true` Docker networks, process-group kills, heartbeat dead-man switches for unattended loops.
10. **One rule**: never let the convenience layer outrun the isolation layer.

## Connections
- Related concepts: [[wiki/concepts/memory-as-attack-surface]], [[wiki/concepts/memory-system]], [[wiki/concepts/agent-hook-compatibility]], [[wiki/concepts/continuous-learning-loop]], [[wiki/concepts/prompt-classification-hook]]
- Projects: cortex-forge (assimilate ingiere contenido foráneo; el template distribuye hooks/skills — ambos lados del problema de supply chain)

---

- 2026-06-12 [Claude Code]: Page created from pasted X thread (batch 3/3)
