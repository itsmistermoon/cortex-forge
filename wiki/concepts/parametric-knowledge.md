---
title: "Parametric Knowledge"
type: concept
created: 2026-06-08
updated: 2026-06-08
tags: [failure-modes, epistemology, memory]
aliases: [training knowledge, model knowledge]
sources:
  - wiki/sources/ai-coding-dictionary.md
confidence: high
schema_version: "0.3"
---

# Parametric Knowledge

What the model knows from training, stored in its parameters. Frozen at training time — the model cannot see its own parameters or update them.

**Counterpart:** [[contextual-knowledge]]

## Properties

- **Not stored as facts.** Training adjusts parameters until the model predicts text well. A model that predicts text about a topic accurately behaves *as if* it knows the topic — but there is no lookup table.
- **Reliability tracks frequency.** A topic with millions of training examples is reproduced accurately. A topic with only a handful is guessed from similar patterns.
- **Reproducing and guessing are indistinguishable to the model.** A fabricated answer arrives with the same fluency as a correct one. This is the root cause of hallucination.
- **Ages at the knowledge cutoff.** Post-cutoff libraries, APIs, and events don't exist in parametric knowledge — they become fabrication traps.

## Relevance to this vault

Cortex Forge's [[recall-protocol]] explicitly disqualifies parametric knowledge as a source for any topic the vault may cover. The vault is the source of truth; parametric knowledge is the fallback of last resort, and must be labeled as such when used.

The phrase "I believe I already know the answer" is a signal that parametric knowledge is about to be used — which is a protocol violation if the vault has synthesized knowledge on the topic.

## Remedy

When parametric knowledge is insufficient (too rare, too recent, or disqualified by protocol): supply the knowledge as [[contextual-knowledge]] instead — load docs, ingest sources, or read the relevant vault pages.

---

- 2026-06-08 [Claude Code]: Page created from AI Coding Dictionary ingestion
