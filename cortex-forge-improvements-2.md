# Cortex Forge — Improvement Backlog #2

**Origin:** Fresh-eyes re-review of [safishamsi/graphify](https://github.com/safishamsi/graphify) (v8 branch, read 2026-06-10) against the applied backlog. The original `cortex-forge-improvements.md` analyzed graphify's *features*; none of its three reviewers went back to the source repository. This pass did — README, ARCHITECTURE.md, AGENTS.md, `docs/how-it-works.md`, `wiki.py`, the `always_on/` templates, and the hook implementations in `__main__.py`.

**Supersedes:** `cortex-forge-improvements.md` — all six items resolved (applied in `2dcb1ff`, gaps closed in `a7f2133`, single-writer refactor in `170a602`; Item 4 deferred to `ROADMAP.md`), file deleted at end of lifecycle.

**Author:** Claude Code (Fable 5), 2026-06-10.

---

## Reviewer trail

> **Independence caveat:** this round was run as three parallel Claude subagents with fresh context, role-played to match the original trail's stances. Same underlying model family, and the backlog author convened the round — weaker independence than the original cross-agent round (CommandCode / Codex / Antigravity). Co-signature slots remain open for the external agents.

| Reviewer | Date | Verdict summary |
|---|---|---|
| Claude subagent — critical senior | 2026-06-10 | Item 1: ACCEPT WITH CHANGES (7) · Item 2: ACCEPT WITH CHANGES (4) · promote version-skew to item |
| Claude subagent — protocol-minimal | 2026-06-10 | Item 1: ACCEPT WITH CHANGES (6) · Item 2: ACCEPT WITH CHANGES (4) · version-skew smuggles surface, strike or move to ROADMAP |
| Claude subagent — user-skeptic | 2026-06-10 | Item 1: ACCEPT WITH CHANGES (5) · Item 2: ACCEPT WITH CHANGES (4, lean) · clear pending hook validations first |

### Convergence (unanimous across the three)

1. **Item 1 ships v1 as Bash-matcher only.** The Read|Glob matcher is structurally broken here: unlike graphify (separate CLI, disjoint directories), `cortex-recall` *is* the agent reading `wiki/` pages — suppressing `wiki/` whitelists the bypass; not suppressing it nags during every legitimate recall.
2. **Claude Code only in v1.** The multi-platform install clause is the `bin/standalone/` anti-pattern in hook form — docs outrunning verified behavior ("configurar un hook ≠ hook funcional", AGENT-LOG 2026-06-08). Ports are gated on the experiment showing behavior change.
3. **Exclusions must widen** to at least `.raw/` (AGENTS.md instructs following the `raw:` context pointer — the hook must not contradict the protocol it enforces), plus `bin/`, `skills/`, `templates/`.
4. **The deliverable is the behavior experiment, not the mechanism.** Acceptance criteria as written measure existence (emits JSON, fails open, idempotent); the thesis test — does the nudge change recall invocation — must be a criterion, logged in `AGENT-LOG.md` with a defined baseline scenario and a kill criterion.
5. **Item 2: drop the baked path argument** (`cortex-prune.sh` already resolves via `git rev-parse`), gate on script existence, and **fix the vacuous criterion** — post-commit cannot abort a commit by construction, so "never aborts" verifies nothing.
6. **Item 2 must not be fully silent.** `>/dev/null 2>&1 || true` repeats the project's hardest-won lesson ("exit 0 oculta todo"). Fail-open on gating, yes; fail-silent on reporting, no — emit one summary line or append to a logfile.
7. **Both items require CHANGELOG entries** when applied (new `bin/hooks/` file and setup skill contract change are protocol-significant by CHANGELOG.md's own definition).

**Processing order (user-skeptic, uncontested):** (1) clear the two pending hook validations in `.hot/MEMORY.md` first — installing new hooks while two installed hooks remain unverified compounds the unknown; (2) Item 1 v1 with the behavior experiment as deliverable; (3) Item 2 after, opportunistically on the same setup-skill edit; (4) version-skew check folded into that same edit.

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

### Verdict (Claude subagent — critical senior, 2026-06-10)

**ACCEPT WITH CHANGES.** Correct diagnosis; first non-declarative mechanism for the documented 4/4 recall failure. But the proposal transplants graphify's design without noticing where the analogy breaks: in graphify the artifact and the bypass surface are disjoint directories; here `cortex-recall` *is* the agent Reading `wiki/` pages, so the anti-feedback-loop rule suppresses the exact bypass the Read|Glob matcher exists to catch. "Pure shell, no new dependencies" is also false as written — existing `bin/hooks/` scripts already use jq, in open tension with the no-jq comment in `cortex-prune.sh:25`; and unthrottled `additionalContext` on every matched call is context spam during legitimate protocol-dev grepping. Required: (1) drop Read|Glob, ship Bash-only; (2) Claude Code only until the experiment produces an AGENT-LOG result; (3) once-per-session throttle keyed on `session_id`; (4) extend suppression to `.raw/` minimum; (5) resolve the jq question honestly — document `bin/hooks/` as exempt or hand-roll and accept false positives; (6) install into `.claude/settings.local.json` or user scope, never the versioned settings of a public template repo; (7) add a kill criterion (N sessions without behavior change, or nudge fatigue → uninstall and log).

### Verdict (Claude subagent — protocol-minimal, 2026-06-10)

**ACCEPT WITH CHANGES.** The consumer is real and load-bearing — `ROADMAP.md` already holds a pending guardrail for exactly this, and the item directly tests the central thesis; invariants (single writer, no new artifact) hold. The smuggle is sketch change #2: install paths for CommandCode, Codex, and Gemini CLI that nothing in this repo verifies have a payload-bearing pre-tool event — the `bin/standalone/` anti-pattern in hook form. The exclusion set also contradicts the protocol it enforces: `AGENTS.md:87` instructs following the `raw:` context pointer, so nudging against `.raw/` reads punishes documented legitimate behavior. Required: (1) cut change #2 to Claude Code only — other platforms get nothing, not even manual instructions, until each has a validated AGENT-LOG entry; (2) expand exclusions to `.raw/`, `AGENTS.md`, `skills/`, `bin/`, `templates/` and make the full list an acceptance criterion; (3) name the inertness gate exactly so "inert" is testable; (4) replace "measurably changes recall invocation" with the AGENT-LOG self-report format; (5) reconcile install-target surface with setup step 6 (global vs vault-local) and mark ROADMAP's PostToolUse line as superseded — two documented mechanisms for one purpose is surface duplication; (6) CHANGELOG entry required.

### Verdict (Claude subagent — user-skeptic, 2026-06-10)

**ACCEPT WITH CHANGES.** Not novelty-driven — it is the project's own backlog finally getting a mechanism, and strictly better than the roadmap's post-hoc PostToolUse idea. Three owner-seat objections: the acceptance criteria measure mechanism existence, not behavior change — the owner could end up with installed machinery, green checkmarks, and zero behavior change, the exact documented failure mode; most grepping in cortex-forge itself is legitimate protocol-dev work, so the nudge must scope to searches plausibly targeting vault *content*; and the hook cannot reach the other documented bypass (Codex answered from active context with zero tool calls — PreToolUse never fires when the competing action is no tool at all). Required: (1) promote behavior measurement into the acceptance criteria — defined baseline scenario, rerun on Claude Code plus one other agent, logged in AGENT-LOG; (2) Bash-matcher only in v1; (3) scope to vault-content searches (`wiki/`, `.raw/`, or pathless from vault root); (4) Claude Code only in v1; (5) write the scope note: the no-tool-call parametric bypass remains uncovered — AGENTS.md compliance criteria stay the only defense there.

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

### Verdict (Claude subagent — critical senior, 2026-06-10)

**ACCEPT WITH CHANGES.** Small, well-scoped, single-writer preserved; the report being gitignored means the rewrite can never dirty the tree — verified. But "costs nothing" is unmeasured and wrong asymptotically: the orphan check runs `grep -rl` over the entire wiki per page, O(N²) in page count — felt latency on every commit once second-brain grows. And acceptance criterion 2 is vacuous: post-commit runs after the commit object exists and cannot abort it under any exit code. Required: (1) background the prune from the hook, or benchmark on the largest registered vault and state the O(N²) cost in the item; (2) replace criterion 2 with a latency criterion (backgrounds or completes < ~200ms on the reference vault); (3) resolve the vault via `git rev-parse --show-toplevel` and exit 0 silently if `bin/cortex-prune.sh` is absent; (4) check `git config core.hooksPath` before writing to `.git/hooks/` — husky-style setups would otherwise install a hook git never runs.

### Verdict (Claude subagent — protocol-minimal, 2026-06-10)

**ACCEPT WITH CHANGES.** Real consumer, real staleness problem — the opposite of the rejected link-count case. Single-writer is preserved, not weakened: the hook only *invokes* the script. Zero dependency cost, zero versioned surface. Two defects: the "never aborts" criterion is true by construction and verifies nothing; the baked `"$VAULT"` path argument is unneeded surface — git runs hooks from the working-tree top and `cortex-prune.sh:8` already self-resolves. Required: (1) drop the path argument, invoke bare with `[ -f bin/cortex-prune.sh ] || exit 0`; (2) rewrite criterion 2 into something falsifiable — the marked block exits 0 and writes nothing when the prune exits 1, exits 2, or is absent; (3) add a verifiable non-clobber criterion — install+uninstall on a file with pre-existing content diffs empty against the original; (4) CHANGELOG entry required.

### Verdict (Claude subagent — user-skeptic, 2026-06-10)

**ACCEPT WITH CHANGES (lean accept).** Honestly, not a felt problem — no AGENT-LOG entry, no Recurring issue, no pending mentions stale `vault-report.json`; the justification is designer reasoning, not owner pain. What saves it: `ROADMAP.md` Fase 2 already lists automatic prune via hook, and health findings change exactly when content is committed — it consumes an existing roadmap line at trivial cost. But `>/dev/null 2>&1 || true` violates the project's hardest-won lesson ("exit 0 oculta todo"): fail-open on gating, yes; fail-silent on reporting, no. Required: (1) emit one summary line to commit output (`cortex-prune: report refreshed, HIGH=n`) or append to a logfile, keeping `|| true`; (2) opt-in as a separate question in `cortex-forge-setup`, not bundled with Item 1; (3) validate the acceptance criterion in second-brain, the vault with real content commits; (4) when updating ROADMAP, mark as partial — post-commit ≠ periodic, staleness detection for dormant vaults stays open.

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

---

### Reviewer notes on this section (2026-06-10)

- **Provenance axes** — unanimous: stays as a non-actionable observation; "exemplary" self-application of the no-consumer rule (protocol-minimal verified every claimed-existing mechanism exists).
- **Honest benchmarks** — stays (2 of 3); critical senior would fold it into ROADMAP Fase 3, where onboarding guide and example pages already cover the same ground.
- **Version skew** — the one disagreement. Critical senior: *promote to a real item* (drift between copies is guaranteed by construction; cheaper than either headline item). Protocol-minimal: *flag* — the sketch smuggles an action into a "no action" section and presupposes a `version:` frontmatter field no SKILL.md carries (its only consumer would be the check itself — chicken-and-egg surface); also overstated, since setup symlinks for Claude Code and overwrites copies on re-run; strike the implementation sentence or move to ROADMAP. User-skeptic: fold opportunistically into the next `cortex-forge-setup` edit, not standalone work. **Net: not actionable as written; if pursued, it must be specced as a proper item resolving the version-field consumer question first.**
