#!/usr/bin/env bash
# Verifies cross-skill consistency invariants in skills/*.
# Exit 0 = all checks pass. Exit 1 = one or more failures.
# Run: bash bin/check-skill-sync.sh [skills-dir]

set -euo pipefail

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
WRITE_SKILLS=("cortex-assimilate" "cortex-imprint")
for name in "${WRITE_SKILLS[@]}"; do
  file="$SKILLS_DIR/$name/SKILL.md"
  [[ -f "$file" ]] || { fail "$name: SKILL.md not found"; continue; }
  if grep -q 'wiki/index.md' "$file"; then
    ok "$name: mentions wiki/index.md update"
  else
    fail "$name: writes wiki/ but does not mention updating wiki/index.md"
  fi
done

# ---------------------------------------------------------------------------
# 4. vault-report.json schema fields consistent between cortex-prune and AGENTS.md
# ---------------------------------------------------------------------------
check "vault-report-schema"
PRUNE_SCHEMA="$SKILLS_DIR/cortex-prune/references/VAULT-REPORT-SCHEMA.md"
CRYSTALLIZE_FILE="$SKILLS_DIR/cortex-crystallize/SKILL.md"

if [[ ! -f "$PRUNE_SCHEMA" ]]; then
  fail "cortex-prune/references/VAULT-REPORT-SCHEMA.md not found"
elif [[ ! -f "$CRYSTALLIZE_FILE" ]]; then
  fail "cortex-crystallize/SKILL.md not found — cannot verify vault-report.json consumer"
else
  # Discover field names structurally from the "## Field definitions" bullet list
  # (`- \`health.foo\` — ...`) instead of enumerating known names, so a newly
  # added field is picked up automatically instead of silently skipped.
  prune_fields=$(grep -oE '`health\.[a-z_]+`' "$PRUNE_SCHEMA" | tr -d '`' | sed 's/^health\.//' | sort -u || true)
  if [[ -z "$prune_fields" ]]; then
    fail "no vault-report.json fields found in $PRUNE_SCHEMA — schema may have moved again"
  else
    # Check each field is referenced in cortex-crystallize's vault-health triage
    # step — the actual consumer since AGENTS.md stopped reading vault-report.json
    # directly (2026-07-06) in favor of the Pending item crystallize already writes.
    all_ok=true
    while IFS= read -r field; do
      if ! grep -q "$field" "$CRYSTALLIZE_FILE"; then
        fail "vault-report field '$field' declared in cortex-prune schema but not referenced in cortex-crystallize/SKILL.md"
        all_ok=false
      fi
    done <<< "$prune_fields"
    if $all_ok; then
      ok "vault-report.json schema fields consistent between cortex-prune and cortex-crystallize"
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
# Catches exactly the 2026-07-03 regression: cortex-prune.sh was relocated but
# cortex-validate-schema.sh (which it calls as a sibling) was left in bin/,
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
# 7. Intentionally-duplicated files stay in sync across skills
# ---------------------------------------------------------------------------
# embeddings.py and cortex-index.py are deliberately co-located in more than
# one skill (each skill must be independently installable and must never
# execute a script found inside the vault — see wiki/concepts/agent-hook-compatibility.md
# and the 2026-07-03 E006 fix). LOCALE-RESOLUTION.md is duplicated for the
# same independent-installability reason (fixed 2026-07-03 — it previously
# lived one level up at skills/, outside every skill dir, so it was never
# actually installed by `npx skills add --skill X`). That duplication only
# stays safe if the copies never silently diverge — this check makes drift
# a CI failure instead of a silent bug.
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
_check_synced "scripts" "embeddings.py" cortex-forge-setup cortex-recall cortex-assimilate
_check_synced "scripts" "cortex-index.py" cortex-forge-setup cortex-assimilate
_check_synced "references" "LOCALE-RESOLUTION.md" cortex-assimilate cortex-crystallize cortex-imprint
_check_synced "references" "VAULT-RESOLUTION.md" cortex-assimilate cortex-crystallize cortex-imprint cortex-prune cortex-recall

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "─────────────────────────────────────"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo "─────────────────────────────────────"

[[ $FAIL -eq 0 ]]
