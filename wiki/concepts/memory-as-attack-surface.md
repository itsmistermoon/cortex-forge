---
title: "Memory as Attack Surface"
type: concept
created: 2026-06-12
updated: 2026-06-12
tags: [security, memory, prompt-injection, supply-chain]
aliases: [memory poisoning, AI recommendation poisoning]
sources:
  - wiki/sources/agentic-security-shorthand-guide.md
confidence: medium
schema_version: "0.3"
---

# Memory as Attack Surface

Persistent agent memory inverts the usual injection economics: a malicious payload doesn't have to succeed in one shot — it can plant fragments in memory files, survive across sessions, and assemble or activate later. Documented at scale by Microsoft's "AI Recommendation Poisoning" report (Feb 2026: attacks across 31 companies, 14 industries).

## Why it works

- **Memory is auto-loaded and rarely re-audited.** Nobody re-reads the `.md` files already in their knowledge base; content reviewed once is trusted forever, even though it may have been written by an agent processing untrusted input.
- **Everything an LLM reads is executable context.** Once text enters the context window there is no data/instruction distinction, so a poisoned memory file has the same authority as a legitimate one.
- **The write path is open.** Any workflow where untrusted content (web pages, PDFs, PR comments) flows through an agent that also writes memory is a potential persistence mechanism.

## Mitigations

- Keep memory narrow and disposable; no secrets in memory files
- Separate project memory from user-global memory
- Reset or rotate memory after runs over untrusted content
- Disable long-lived memory for high-risk workflows
- Scan memory/skill/hook files like supply-chain artifacts (hidden Unicode, HTML comments, base64, egress commands)

## Application in Cortex Forge

Cortex Forge's entire value is persistent memory, so it carries this surface by design — on both write paths:
- `cortex-assimilate` reads foreign web content and writes wiki pages that future sessions trust as ground truth. A poisoned source page is a persistent injection. The `.raw/` immutability rule helps audit, but nothing scans content today.
- `cortex-crystallize` writes `.hot/MEMORY.md`, which hooks auto-inject at session start ([[wiki/concepts/memory-system]]) — exactly the auto-loaded, rarely re-audited channel this concept describes.
- As a distributed template with hooks and skills, cortex-forge is itself a supply-chain artifact for its users (cf. CVE-2025-59536: repo-controlled hooks ran pre-trust).

## Connections
- Related concepts: [[wiki/concepts/memory-system]], [[wiki/concepts/contextual-knowledge]], [[wiki/concepts/continuous-learning-loop]], [[wiki/concepts/agent-hook-compatibility]]

---

- 2026-06-12 [Claude Code]: Page created from Agentic Security guide ingestion
