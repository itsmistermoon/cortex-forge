# AI Coding Dictionary — Matt Pocock / AI Hero

Source: https://www.aihero.dev/ai-coding-dictionary
Author: Matt Pocock
Date: 2026-06-08
68 entries across 7 sections.

---

## The Model (15 terms)

**AI** — A moving label, not a technology. Points at whatever computers can newly, impressively do — right now, large language models.

**Model** — The parameters. Stateless — does next-token prediction and nothing else. Cannot do anything agentic on its own.

**Parameters** — The numbers inside a model — often billions — tuned during training. Everything the model knows lives in them. Also called weights.

**Training** — The process that sets a model's parameters by exposing it to vast amounts of text and adjusting to improve next-token prediction.

**Inference** — Running a trained model to generate output — what happens on every model provider request. Parameters stay fixed.

**Token** — The atomic unit a model reads and writes. Roughly word-sized but not exactly. Context window size, cost, and latency all count tokens.

**Next-token prediction** — What the model actually does. Samples one next token from the context, appends it, and runs again. Its only mode of operation.

**Non-determinism** — The same input can produce different output. A property of how models generate text and how providers serve requests.

**Model provider** — Whatever serves a model for inference. Usually remote (Anthropic, OpenAI, Google), but can also be local (Ollama, llama.cpp).

**Harness** — Everything around the model that turns it into an agent: tools, system prompt, context-window management, permissions, hooks.

**Model provider request** — One round-trip from the harness to the model provider. The harness sends context; the provider returns one response.

**Input tokens** — Tokens the harness sends on each model provider request. Billed at a lower rate than output tokens.

**Output tokens** — Tokens the model generates back. Billed at a higher rate than input tokens, since they cost more compute to produce.

**Prefix cache** — The provider-side store that lets consecutive requests skip re-processing a shared prefix, billing those tokens at a lower rate.

**Cache tokens** — Input tokens the provider has cached from a previous request via its prefix cache, billed at a much lower rate.

---

## Sessions, Context Windows & Turns (8 terms)

**Stateless** — Carries no information forward. The model is stateless across requests; an agent is stateless across sessions by default.

**Context** — The relevant information the agent has access to right now — what the agent knows that's pertinent to the task.

**Context window** — Everything the model sees on each model provider request. Finite, model-specific, the only surface through which the model perceives.

**Stateful** — Carries information forward. Sessions are stateful across turns; agents can be made stateful across sessions via a memory system.

**Agent** — A model harnessed with tools, a system prompt, and a context window, that takes turns with a user. The model in motion.

**System prompt** — The instructions the harness prepends to every model provider request — the agent's standing brief. Usually stable across a session.

**Session** — One bounded run of interaction with an agent. Starts empty, accumulates, ends when cleared, closed, or compacted into a fresh session.

**Turn** — One user message plus everything the agent does in response, up until it yields back to the user. Contains one or more provider requests.

---

## Tools & Environment (10 terms)

**Environment** — The world the agent acts on — anything outside the harness that the agent perceives via tool results and changes via tool calls.

**Filesystem** — A tree of files and directories the agent reads from, writes to, and executes within — the default environment for a coding agent.

**Tool** — A function the harness exposes for the agent to call — Read, Write, Bash, Search. How an agent perceives and acts on the environment.

**Tool call** — The model's output naming a tool and its arguments — just structured text. The harness has to read it and execute.

**Tool result** — What the harness sends back after executing a tool call — file contents, output, or error. The agent's only view of the environment.

**MCP** — A protocol for plugging external tool servers into a harness — how an agent gets tools beyond what the harness ships with.

**Permission request** — What the harness shows the user before executing a tool call that isn't pre-approved. The mechanism for putting a human in the loop.

**Permission mode** — The permission-gating slice of an agent mode — which tool calls trigger a permission request and which run automatically.

**Agent mode** — A preset bundling a permission mode with behavioral instructions injected into the system prompt. Can flip mid-session.

**Sandbox** — An isolated environment the agent runs inside — container, VM, or restricted shell. Limits the blast radius of agent actions.

---

## Failure Modes (9 terms)

**Sycophancy** — Confidently agreeable model output. Caused by training that shaped the model to favor answers humans liked — including agreement.

**Hallucination** — Confidently-wrong model output. Two flavors: factuality (invented facts) and faithfulness (drift from loaded context).

**Parametric knowledge** — What the model knows from training, stored in its parameters. Frozen at training time. Counterpart to contextual knowledge. Detail is lost in the squeeze: billions of facts cram into a fixed number of parameters, and the rare ones blur. Source of fluency on common topics, and of fabrication on uncommon ones. Parametric knowledge is not stored as facts — training adjusts parameters until the model predicts text well. How reliable the knowledge is tracks how often something appeared in training data. Reproducing and guessing are the same process to the model, so it can't tell which one it's doing. A fabricated answer arrives with the same fluency as a correct one. Parametric knowledge also ages — stops changing at the knowledge cutoff. For both gaps (too rare, too recent), the remedy is the same: supply as contextual knowledge instead.

**Knowledge cutoff** — The date past which a model has no parametric knowledge. Post-cutoff libraries and APIs are fabrication traps unless docs are loaded.

**Contextual knowledge** — Facts the agent can read directly from the context right now. Counterpart to parametric knowledge.

**Attention relationship** — The pairing between two tokens — meaningful pairs influence each other more than unrelated ones. A context of N tokens has ~N² of these.

**Attention budget** — Each token has a finite amount of influence to distribute across the rest of the context. Per-token, doesn't grow when context does.

**Attention degradation** — As a session grows, each token's attention budget spreads across more competitors; signal on meaningful relationships shrinks.

**Smart zone / Dumb zone** — Early in a session the agent is sharp and focused. As the session grows it drifts into a dumb zone: sloppier, forgetful, more mistakes.

---

## Handoffs (9 terms)

**Clearing** — Ending the current session and starting a fresh one. The next message begins with an empty session and an empty context window.

**Handoff** — Transferring agent context from one session to another, with no return path. Carry mechanism varies — artifact, compaction, others.

**Primary source** — The thing itself — code, transcripts, raw data. Complete and authoritative, but expensive to load into context.

**Secondary source** — An account of a primary source, one step removed — summaries, docs, compaction summaries. Cheap to load, lossy by construction.

**Handoff artifact** — A document used as the carry mechanism for a handoff — written by one session to be read by another.

**Spec** — A handoff artifact describing a multi-session piece of work — what's being built, not how each session does its share. Made of tickets.

**Ticket** — A handoff artifact scoping one session of work. Stands alone or hangs off a spec. Can block or be blocked by sibling tickets.

**Compaction** — A handoff done in-memory: the previous session's history is summarised and seeds a fresh session. Lossy — detail traded for headroom.

**Autocompact** — Compaction triggered automatically by the harness when the context window approaches full.

---

## Memory and Steering (6 terms)

**Memory system** — A system that attempts to make an agent stateful across sessions by persisting to the environment and reloading at session start.

**AGENTS.md** — A file in the environment that the harness loads into the context window at session start — the project's standing brief to the agent.

**Progressive disclosure** — Loading only the context an agent needs right now, with context pointers to the rest. Borrowed from UI design.

**Context pointer** — A mention in one document that points to another, so the agent can pull it into context only when the task calls for it.

**Skill** — A teachable capability bundled as a unit — kept out of the context window until a context pointer pulls it in for the task at hand.

**Subagent** — An agent spawned by another agent via a tool call. Runs in its own session, reports a single tool result. Cannot spawn further subagents.

---

## Patterns of Work (11 terms)

**Human-in-the-loop** — A working pattern where one or more humans pair with the agent during a session — reviewing, redirecting, or collaborating in real time.

**AFK** — A working pattern where the user kicks off a session and leaves the agent to run unattended (away from keyboard).

**Automated check** — A deterministic verification that runs in the environment — tests, type checks, lints, build, pre-commit hooks. Pass/fail, no judgement.

**Automated review** — An agent reviewing another agent's work, often with a different model or system prompt. Non-deterministic: it forms a judgement.

**Human review** — The user reading the code the agent produced and forming a judgement on it. Reading the diff counts; reading the summary doesn't.

**Vibe coding** — A working pattern where the user accepts the agent's code without human review. The diff is treated as opaque.

**Design concept** — The shared understanding of what's being built, held in common between user and agent but separate from any asset.

**Grilling** — A technique for developing a design concept: the agent interviews the user Socratically, one decision at a time.

**Prototyping** — Having the agent build a quick, rough version when conversation is too low-fidelity and you need a real artifact to talk about.

**DX** — Developer experience: how easy a codebase and its toolchain make it for humans to do good work — docs, feedback speed, errors.

**AX** — Agent experience: how well the environment is set up for an agent to do good work — checks, architecture, and free context.
