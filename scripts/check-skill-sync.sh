#!/usr/bin/env bash
# Verifies cross-skill consistency invariants in skills/*.
# Exit 0 = all checks pass. Exit 1 = one or more failures.
# Run: bash scripts/check-skill-sync.sh [skills-dir]

set -euo pipefail

# ---------------------------------------------------------------------------
# Dependency preflight — fail loud with an install hint, not a raw
# "command not found" mid-check.
# ---------------------------------------------------------------------------
for dep in jq diff; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    echo "check-skill-sync.sh: missing dependency '$dep'." >&2
    case "$dep" in
      jq) echo "  Install: brew install jq   (macOS)  |  apt-get install -y jq   (Debian/Ubuntu)" >&2 ;;
      diff) echo "  Install: part of diffutils — apt-get install -y diffutils   (Debian/Ubuntu; preinstalled on macOS)" >&2 ;;
    esac
    exit 2
  fi
done

SKILLS_DIR="${1:-$(dirname "$0")/../skills}"
SKILLS_DIR="$(cd "$SKILLS_DIR" && pwd)"

PASS=0
FAIL=0

ok()   { echo "  ✓ $*"; ((PASS++)) || true; }
fail() { echo "  ✗ $*" >&2; ((FAIL++)) || true; }

check() {
  local label="$1"; shift
  echo "[$label]"
}

# ---------------------------------------------------------------------------
# 1. No legacy vault: format (must use vaults:)
# ---------------------------------------------------------------------------
check "legacy-vault-key"
for skill_dir in "$SKILLS_DIR"/*/; do
  name=$(basename "$skill_dir")
  file="$skill_dir/SKILL.md"
  [[ -f "$file" ]] || continue
  # Allow "vaults:" but reject bare "vault:" that isn't part of another word
  if grep -qE '^\s+- Config format:.*vault:' "$file" 2>/dev/null || \
     grep -qE '^\s+vault: ' "$file" 2>/dev/null; then
    fail "$name: contains legacy 'vault:' config key"
  else
    ok "$name: uses vaults: format"
  fi
done

# ---------------------------------------------------------------------------
# 2. No CODEX.md references as vault identity file (must be AGENTS.md)
# ---------------------------------------------------------------------------
check "codex-md-reference"
for skill_dir in "$SKILLS_DIR"/*/; do
  name=$(basename "$skill_dir")
  file="$skill_dir/SKILL.md"
  [[ -f "$file" ]] || continue
  # Allow mentions in changelog lines (contain "→" or are prefixed with "-")
  violations=$(grep -n 'CODEX\.md' "$file" | grep -v '→\|changelog\|Changelog\|- 20' || true)
  if [[ -n "$violations" ]]; then
    fail "$name: functional reference to CODEX.md found:"
    echo "$violations" | sed 's/^/    /' >&2
  else
    ok "$name: no functional CODEX.md references"
  fi
done

# ---------------------------------------------------------------------------
# 3. Skills that write wiki/ must mention wiki/index.md update
# ---------------------------------------------------------------------------
check "index-update"
# Discover write-skills structurally instead of a hardcoded list — a skill
# whose SKILL.md describes creating/saving a new wiki page is scanned
# automatically, matching the "no enumerated names" approach used elsewhere
# in this script (see sections 4 and 6).
while IFS= read -r file; do
  name="$(basename "$(dirname "$file")")"
  if grep -q 'wiki/index.md' "$file"; then
    ok "$name: mentions wiki/index.md update"
  else
    fail "$name: writes wiki/ but does not mention updating wiki/index.md"
  fi
done < <(grep -lriE "creat(e|es|ing)? (a |the |new )*page|saved to \`\{?vault\}?/?wiki|writ(e|es|ing) (the |a |new )*page" "$SKILLS_DIR"/*/SKILL.md | sort -u)

# ---------------------------------------------------------------------------
# 4. vault-report.json schema fields consistent between wiki-lint and AGENTS.md
# ---------------------------------------------------------------------------
check "vault-report-schema"
PRUNE_SCHEMA="$SKILLS_DIR/wiki-lint/references/VAULT-REPORT-SCHEMA.md"
HANDOFF_FILE="$SKILLS_DIR/hot-handoff/SKILL.md"

if [[ ! -f "$PRUNE_SCHEMA" ]]; then
  fail "wiki-lint/references/VAULT-REPORT-SCHEMA.md not found"
elif [[ ! -f "$HANDOFF_FILE" ]]; then
  fail "hot-handoff/SKILL.md not found — cannot verify vault-report.json consumer"
else
  # Discover field names structurally from the "## Field definitions" bullet list
  # (`- \`health.foo\` — ...`) instead of enumerating known names, so a newly
  # added field is picked up automatically instead of silently skipped.
  prune_fields=$(grep -oE '`health\.[a-z_]+`' "$PRUNE_SCHEMA" | tr -d '`' | sed 's/^health\.//' | sort -u || true)
  if [[ -z "$prune_fields" ]]; then
    fail "no vault-report.json fields found in $PRUNE_SCHEMA — schema may have moved again"
  else
    # Check each field is referenced in hot-handoff's vault-health triage
    # step — the actual consumer since AGENTS.md stopped reading vault-report.json
    # directly (2026-07-06) in favor of the Pending item crystallize already writes.
    all_ok=true
    while IFS= read -r field; do
      if ! grep -q "$field" "$HANDOFF_FILE"; then
        fail "vault-report field '$field' declared in wiki-lint schema but not referenced in hot-handoff/SKILL.md"
        all_ok=false
      fi
    done <<< "$prune_fields"
    if $all_ok; then
      ok "vault-report.json schema fields consistent between wiki-lint and hot-handoff"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# 5. All skills have non-empty description in frontmatter
# ---------------------------------------------------------------------------
check "description-not-empty"
for skill_dir in "$SKILLS_DIR"/*/; do
  name=$(basename "$skill_dir")
  file="$skill_dir/SKILL.md"
  [[ -f "$file" ]] || continue
  desc=$(awk '/^---/{p++} p==1 && /^description:/{print; exit}' "$file")
  if [[ -z "$desc" ]] || echo "$desc" | grep -q 'description:\s*$'; then
    fail "$name: missing or empty description in frontmatter"
  else
    ok "$name: has description"
  fi
done

# ---------------------------------------------------------------------------
# 6. Every script listed in "## Available scripts" actually exists (same dir)
# ---------------------------------------------------------------------------
# Catches exactly the 2026-07-03 regression: lint.sh was relocated but
# validate-schema.sh (which it calls as a sibling) was left in bin/,
# silently disabling schema-drift checks for every install. Scans the
# "## Available scripts" section structurally rather than grepping for the
# word "co-located" — that phrasing was intentionally removed everywhere in
# favor of a single "Paths are relative to this skill's directory" line per
# skill, which made the old keyword-based detection silently check nothing.
check "available-script-exists"
for skill_dir in "$SKILLS_DIR"/*/; do
  name=$(basename "$skill_dir")
  file="$skill_dir/SKILL.md"
  [[ -f "$file" ]] || continue
  refs=$(awk '/^## Available scripts/{p=1; next} /^## /{p=0} p' "$file" \
    | grep -oE '`scripts/[A-Za-z0-9_-]+\.(sh|py)`' | tr -d '`' | sed 's#^scripts/##' | sort -u || true)
  missing=""
  while IFS= read -r script; do
    [[ -z "$script" ]] && continue
    [[ -f "$skill_dir/scripts/$script" ]] || missing="$missing $script"
  done <<< "$refs"
  if [[ -n "$missing" ]]; then
    fail "$name: script(s) listed in Available scripts but not found: $missing"
  else
    ok "$name: all scripts in Available scripts are present"
  fi
done

# ---------------------------------------------------------------------------
# 7. Intentionally-duplicated scripts stay in sync across skills
# ---------------------------------------------------------------------------
# embeddings.py and index.py are deliberately co-located in more than
# one skill (each skill must be independently installable and must never
# execute a script found inside the vault — see wiki/concepts/agent-hook-compatibility.md
# and the 2026-07-03 E006 fix: a shared bin/ was rejected there because
# executing code from a shared/vault-adjacent location was the actual
# security problem, not just an installability inconvenience). That
# duplication only stays safe if the copies never silently diverge — this
# check makes drift a CI failure instead of a silent bug.
check "duplicated-script-sync"
_check_synced() {  # $1: subdir ("scripts" or "references"), $2: filename, $3..$N: skill names that must match
  local subdir="$1" script="$2"; shift 2
  local first="" first_skill=""
  for name in "$@"; do
    local f="$SKILLS_DIR/$name/$subdir/$script"
    [[ -f "$f" ]] || { fail "$name/$subdir/$script: expected but not found"; continue; }
    if [[ -z "$first" ]]; then
      first="$f"; first_skill="$name"
    elif ! diff -q "$first" "$f" >/dev/null 2>&1; then
      fail "$script differs between $first_skill and $name — sync them or document why they diverge"
      return
    fi
  done
  [[ -n "$first" ]] && ok "$script identical across: $*"
}
_check_synced "scripts" "embeddings.py" wiki-setup wiki-query wiki-ingest
_check_synced "scripts" "index.py" wiki-setup wiki-ingest

# ---------------------------------------------------------------------------
# 8. Shared reference docs live only at references/, never re-duplicated
# ---------------------------------------------------------------------------
# VAULT-RESOLUTION.md, LOCALE-RESOLUTION.md, HANDOFF-FORMAT.md, and
# PLAYBOOK-FORMAT.md used to be duplicated per-skill (same reason as
# duplicated-script-sync above), but that only applied to the installability
# concern, not the E006 security concern — these are inert docs, nothing
# executes them. Moved to a single canonical copy at references/ (repo root),
# synced by wiki-setup into ~/.almagest/references/ (see
# skills/wiki-setup/references/UPSTREAM-SYNC.md). This check guards against
# a skill silently re-introducing a local copy that could drift.
check "no-reintroduced-reference-duplicates"
for shared_doc in VAULT-RESOLUTION.md LOCALE-RESOLUTION.md HANDOFF-FORMAT.md PLAYBOOK-FORMAT.md; do
  found=""
  for skill_dir in "$SKILLS_DIR"/*/; do
    name=$(basename "$skill_dir")
    f="$skill_dir/references/$shared_doc"
    [[ -f "$f" ]] && found="$found $name"
  done
  if [[ -n "$found" ]]; then
    fail "$shared_doc: re-duplicated locally in:$found — should be removed and referenced from ~/.almagest/references/ instead"
  else
    ok "$shared_doc: no local copies re-introduced"
  fi
done

# ---------------------------------------------------------------------------
# 9. Distribution manifests agree on the skill roster
# ---------------------------------------------------------------------------
# skills.sh.json (npx skills add) and .claude-plugin/plugin.json (Claude Code
# plugin marketplace) each list every skill in this suite independently —
# nothing enforced they stay in sync, and hot-triage was missing from
# plugin.json for a while as a result. Compare both against the actual
# skills/*/ directories on disk, the real source of truth.
check "skill-list-manifests-agree"
REPO_ROOT="$(dirname "$SKILLS_DIR")"
_on_disk=$(basename -a "$SKILLS_DIR"/*/ | sort)
_skills_sh=$(jq -r '.groupings[].skills[]' "$REPO_ROOT/skills.sh.json" | sort)
_plugin=$(jq -r '.skills[]' "$REPO_ROOT/.claude-plugin/plugin.json" | sed 's#^\./skills/##' | sort)
if [[ "$_on_disk" == "$_skills_sh" ]]; then
  ok "skills.sh.json matches skills/*/ on disk"
else
  fail "skills.sh.json roster differs from skills/*/ on disk — diff:$(diff <(echo "$_on_disk") <(echo "$_skills_sh") | tr '\n' ' ')"
fi
if [[ "$_on_disk" == "$_plugin" ]]; then
  ok ".claude-plugin/plugin.json matches skills/*/ on disk"
else
  fail ".claude-plugin/plugin.json roster differs from skills/*/ on disk — diff:$(diff <(echo "$_on_disk") <(echo "$_plugin") | tr '\n' ' ')"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "─────────────────────────────────────"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo "─────────────────────────────────────"

[[ $FAIL -eq 0 ]]
