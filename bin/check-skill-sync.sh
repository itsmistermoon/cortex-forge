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
PRUNE_SKILL="$SKILLS_DIR/cortex-prune/SKILL.md"
AGENTS_FILE="$SKILLS_DIR/../AGENTS.md"

if [[ ! -f "$PRUNE_SKILL" ]]; then
  fail "cortex-prune/SKILL.md not found"
elif [[ ! -f "$AGENTS_FILE" ]]; then
  fail "AGENTS.md not found — cannot verify vault-report.json consumer"
else
  # Extract field names declared in cortex-prune schema block
  prune_fields=$(grep -oE '"(dead_links|raw_without_source_page|missing_confidence|orphan_pages)"' "$PRUNE_SKILL" | sort -u)
  # Check each field is referenced in AGENTS.md
  all_ok=true
  while IFS= read -r field; do
    clean="${field//\"/}"
    if ! grep -q "$clean" "$AGENTS_FILE"; then
      fail "vault-report field '$clean' declared in cortex-prune but not referenced in AGENTS.md"
      all_ok=false
    fi
  done <<< "$prune_fields"
  if $all_ok; then
    ok "vault-report.json schema fields consistent between cortex-prune and AGENTS.md"
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
# 6. cortex-prune.sh runtime script referenced correctly
# ---------------------------------------------------------------------------
check "prune-script-colocated"
PRUNE_SKILL="$SKILLS_DIR/cortex-prune/SKILL.md"
if [[ -f "$SKILLS_DIR/cortex-prune/cortex-prune.sh" ]] && grep -q 'co-located with this skill' "$PRUNE_SKILL"; then
  ok "cortex-prune: script co-located and SKILL.md references it as such"
else
  fail "cortex-prune: cortex-prune.sh must be co-located in skills/cortex-prune/ and referenced as such"
fi

# ---------------------------------------------------------------------------
# 7. Every co-located script a SKILL.md references actually exists (same dir)
# ---------------------------------------------------------------------------
# Catches exactly the 2026-07-03 regression: cortex-prune.sh was relocated but
# cortex-validate-schema.sh (which it calls as a sibling) was left in bin/,
# silently disabling schema-drift checks for every install.
check "colocated-script-exists"
for skill_dir in "$SKILLS_DIR"/*/; do
  name=$(basename "$skill_dir")
  file="$skill_dir/SKILL.md"
  [[ -f "$file" ]] || continue
  # Only check scripts named on a line that itself claims co-location — avoids
  # false positives from mentioning another skill's or a vault-local runtime
  # copy's script name (e.g. "{vault}/.cortex/db/cortex-index.py") elsewhere.
  # Only match backtick-quoted filenames (how real script refs are always
  # written) — avoids false positives like prose links (e.g. "skills.sh").
  refs=$(grep -i 'co-located' "$file" | grep -oE '`[A-Za-z0-9_-]+\.(sh|py)`' | tr -d '`' | sort -u || true)
  missing=""
  while IFS= read -r script; do
    [[ -z "$script" ]] && continue
    [[ -f "$skill_dir/$script" ]] || missing="$missing $script"
  done <<< "$refs"
  if [[ -n "$missing" ]]; then
    fail "$name: script(s) claimed co-located but not found in $skill_dir:$missing"
  else
    ok "$name: all co-located scripts present"
  fi
done

# ---------------------------------------------------------------------------
# 8. Intentionally-duplicated scripts stay in sync across skills
# ---------------------------------------------------------------------------
# embeddings.py and cortex-index.py are deliberately co-located in more than
# one skill (each skill must be independently installable and must never
# execute a script found inside the vault — see wiki/concepts/agent-hook-compatibility.md
# and the 2026-07-03 E006 fix). That duplication only stays safe if the
# copies never silently diverge — this check makes drift a CI failure
# instead of a silent bug.
check "duplicated-script-sync"
_check_synced() {  # $1: script filename, $2..$N: skill names that must match
  local script="$1"; shift
  local first="" first_skill=""
  for name in "$@"; do
    local f="$SKILLS_DIR/$name/$script"
    [[ -f "$f" ]] || { fail "$name/$script: expected but not found"; continue; }
    if [[ -z "$first" ]]; then
      first="$f"; first_skill="$name"
    elif ! diff -q "$first" "$f" >/dev/null 2>&1; then
      fail "$script differs between $first_skill and $name — sync them or document why they diverge"
      return
    fi
  done
  [[ -n "$first" ]] && ok "$script identical across: $*"
}
_check_synced "embeddings.py" cortex-forge-setup cortex-recall cortex-assimilate
_check_synced "cortex-index.py" cortex-forge-setup cortex-assimilate

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "─────────────────────────────────────"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo "─────────────────────────────────────"

[[ $FAIL -eq 0 ]]
