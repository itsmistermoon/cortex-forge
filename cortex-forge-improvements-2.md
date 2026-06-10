# Cortex Forge — Improvement Backlog #2

**Origin:** Fresh-eyes re-review of [safishamsi/graphify](https://github.com/safishamsi/graphify) (v8 branch, read 2026-06-10) against the applied backlog. The original `cortex-forge-improvements.md` analyzed graphify's *features*; none of its three reviewers went back to the source repository. This pass did — README, ARCHITECTURE.md, AGENTS.md, `docs/how-it-works.md`, `wiki.py`, the `always_on/` templates, and the hook implementations in `__main__.py`.

**Supersedes:** `cortex-forge-improvements.md` — all six items resolved (applied in `2dcb1ff`, gaps closed in `a7f2133`, single-writer refactor in `170a602`; Item 4 deferred to `ROADMAP.md`), file deleted at end of lifecycle.

**Author:** Claude Code (Fable 5), 2026-06-10.

---

## Reviewer trail

| Reviewer | Date | Verdict summary |
|---|---|---|
| *(pending)* | | |

---

## Item 1 — Recall enforcement via PreToolUse hooks

### Context

This is the finding the original backlog missed entirely. `AGENT-LOG.md` documents the project's central thesis: declarative instructions without a verifiable contract fail systemically — four different agents (Claude Code, Codex, Antigravity, CommandCode) failed identically to invoke `cortex-recall` proactively. The "Layer 3 guardrails" idea (a self-invoking preflight skill) was correctly discarded because it is the same declarative mechanism that fails. `ROADMAP.md` left "PostToolUse guardrails" pending.

Graphify solved this exact problem in production — and the mechanism is **PreToolUse, not PostToolUse**. It does not remind the agent at session start (where instructions dilute); it intercepts the *competing action* at the moment it happens:

1. A hook with `matcher: "Bash"` parses the command string; if it is a search command (`grep|rg|find|fd|ack|ag`), it injects `additionalContext`: *"MANDATORY: graph.json exists. You MUST run graphify query before grepping raw files. Only grep after graphify has oriented you, or to modify/debug specific lines."*
2. A second hook with `matcher: "Read|Glob"` intercepts the most common bypass (graphify issue #1114): answering a codebase question by reading source files one by one.

Design details worth transferring verbatim:

- **Artifact-existence gate** — the hook is inert unless `graphify-out/graph.json` exists (`[ -f ... ]`). Cortex analog: gate on `wiki/index.md` existing in the detected vault, or on vault registration in `~/.cortex-forge/config.yml`.
- **Fail-open on every branch** (`|| true`) — a legitimate action always goes through. The guardrail nudges; it never blocks. Distinct from the vault's fail-loud rule, which applies to *reporting*, not to *gating*.
- **Anti-feedback-loop suppression** — reads inside `graphify-out/` never trigger the hook, so reading the graph's own report cannot start a loop. Cortex analog: reads inside `wiki/`, `.hot/`, and `CODEX.md` must not trigger the recall nudge.
- **Subagent propagation clause** — the injected message ends with *"This rule applies to subagents too — include it in every subagent prompt involving code exploration."* `cortex-prune` Layer 2 spawns subagents; the same leak exists here.
- **Escape hatch in the message itself** — "Only grep after graphify has oriented you, or to modify/debug specific lines" prevents the nudge from blocking legitimate post-orientation work.

### Why this fits the central objective

This is the mechanical complement to the verifiable compliance criteria added in v0.1.0–v0.2.0. The compliance criteria make protocol violations *detectable after the fact*; a PreToolUse nudge makes the protocol *salient at the decision point*. It is the first enforcement mechanism considered for this project that is not declarative. Pure shell, no new dependencies — consistent with the `.md + .sh` constraint.

### Changes required (sketch — needs reviewer round)

1. New `bin/hooks/cortex-recall-nudge.sh` — reads the PreToolUse JSON payload from stdin, matches search-style Bash commands and Read/Glob targets outside `wiki/`/`.hot/`, emits `hookSpecificOutput.additionalContext` pointing at `cortex-recall`. Every branch fails open.
2. `cortex-forge-setup` `hooks` sub-task installs/uninstalls it in the project's `.claude/settings.json` (and per-platform equivalents where PreToolUse-style hooks exist: CommandCode, Codex `.codex/hooks.json`, Gemini CLI BeforeTool). Platforms without payload-bearing hooks fall back to the existing AGENTS.md declarative text — same degradation graphify documents for Trae/Cursor.
3. `AGENT-LOG.md` entry once tested against a real session, including whether the nudge measurably changes recall invocation — this is a direct experiment on the central thesis.

### Acceptance criteria

- Hook emits valid `hookSpecificOutput` JSON for a matching command and emits nothing (exit 0) otherwise.
- Reads inside `wiki/`, `.hot/`, or of `CODEX.md` never trigger it.
- Hook is inert when no registered vault applies to the CWD.
- A deliberately malformed payload does not block the tool call (fail-open verified).
- Install and uninstall are idempotent via `cortex-forge-setup`.

### Verdict (pending)

---

## Item 2 — Git post-commit hook running the Layer 1 prune

### Context

`AGENTS.md` startup step 3 reads `wiki/meta/vault-report.json`, but the file only refreshes when someone runs `cortex-prune`. Between prune runs the startup signal goes stale — the `generated` date drifts and the health arrays describe a past state.

Graphify's `graphify hook install` rebuilds the AST-only part of the graph on every git commit precisely because it is free (no LLM). The cortex analog is exact: `bin/cortex-prune.sh` Layer 1 is pure bash, costs nothing, and is already the single writer of `vault-report.json`.

(Graphify's hard-won lesson here — pinning the interpreter path at install time because GUI git clients have a minimal PATH — does not apply: the prune script is pure bash. The idea is even cheaper for us.)

### Changes required (sketch)

1. `cortex-forge-setup` `hooks` sub-task offers to install a vault-local `post-commit` hook that runs `bash bin/cortex-prune.sh "$VAULT" >/dev/null 2>&1 || true` — silent, fail-open, report refreshed as a side effect of every commit.
2. Hook script carries start/end markers (graphify pattern) so install/uninstall never clobbers a user's existing post-commit hook.

### Acceptance criteria

- After any commit in the vault, `vault-report.json` has `generated` = today.
- A failing prune (HIGH findings, exit 1) never aborts or delays the commit.
- Install is idempotent; uninstall removes only the marked block.

### Verdict (pending)

---

## Verification of the original backlog against the source

Re-checked the original report's claims about graphify against the actual repo:

- **Claims hold.** `GRAPH_REPORT.md`, `graph.html`, Leiden community detection, and confidence tags all exist as described.
- **Item 3 rejection validated.** The unanimous "documented stub" rejection of `bin/standalone/` was the right call — graphify's headless mode (`graphify extract` for CI) is real, working code, not an aspirational README. The criterion applied (no docs for code that doesn't exist) matches what the source actually does.
- **Item 4 deferral validated.** In graphify, god nodes have real consumers: they seed the transcription prompt (Pass 2), feed the report, and drive `--exclude-hubs`. Deferring cortex-forge's link-count scan until `knowledge_map` has a consumer was correct by the source's own logic.

---

## Minor observations — recorded, no action proposed

### Provenance is three axes, not one

Graphify separates the *class* of a relationship (`EXTRACTED` / `INFERRED` / `AMBIGUOUS`) from its *strength* (a discrete 0.95–0.55 rubric, INFERRED only; EXTRACTED is always 1.0). Matt Pocock's AI Coding Dictionary contributes a third, orthogonal axis: **primary source** vs **secondary source**. The dictionary's index gives only one-line definitions, but the full articles (ingested 2026-06-10: [[wiki/concepts/primary-source]], [[wiki/concepts/secondary-source]]) go further and supplied vocabulary the vault was already implementing without names:

- Secondary sources fail two ways: **lossy** (the account dropped the detail that mattered) and **drift** (the primary changed and the account didn't follow).
- The remedy for loss is the **context pointer** — a secondary source that names its original so the reader can follow the pointer rather than work from the loss.

Cortex-forge had both remedies built before having the words: the `raw:` frontmatter field on source pages *is* a context pointer (and `bin/cortex-prune.sh` already flags primaries without one), and the `AGENTS.md` conflict rule (".raw/ wins") *is* the drift remedy. The vocabulary was adopted into `AGENTS.md`, `cortex-prune` rules, and the project page on 2026-06-10 — naming alone, no behavior change.

The three axes map cleanly onto cortex-forge:

| Axis | Question | Cortex-forge today |
|---|---|---|
| Distance from origin (Pocock) | Is this the thing itself or an account of it? | Adopted structurally: `.raw/` = primary, `wiki/` = secondary; conflict rule remedies drift; `raw:` context pointer remedies loss |
| Synthesis class (graphify) | Was this stated in the source or deduced during synthesis? | Not captured — a wiki page mixes quoted facts and agent inference under one value |
| Strength | How much should a reader trust it? | `confidence: high/medium/low` frontmatter |

Axis 1 is now fully covered, named and enforced. Today `confidence:` partially conflates axes 2 and 3. **Do not act on this now** — adding an extracted/inferred marker without a consumer repeats the exact anti-pattern Item 3's reviewers rejected. Record it as the vocabulary to use if `confidence:` ever evolves with a real consumer.

### Honest benchmarks and worked examples

Graphify publishes benchmarks that include its own worst case ("~1x reduction on 6 files — the value there is structural clarity, not compression") and ships a `worked/` folder of real corpora with honest `review.md` files ("what the graph got right and wrong"). If cortex-forge ever documents value claims in the README, this is the pattern: include the case where it doesn't help, and ship a reproducible example vault.

### Skill/CLI version skew

Graphify warns when the installed skill file's version differs from the package. Cortex-forge has the same latent risk between the global copies in `~/.claude/skills/` and the vault repo's `skills/`. A cheap check in `cortex-forge-setup` (compare a version line, warn on mismatch) would cover it. Low priority.
