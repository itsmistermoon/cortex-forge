#!/usr/bin/env bash
# antu-embed: Bootstrap semantic index for a vault.
# Usage: antu-embed [vault_name|vault_path]
#   No args → uses default vault from ~/.cortex-forge/config.yml
#   vault_name → looks up path in config.yml
#   vault_path → uses path directly
set -euo pipefail

CONFIG="$HOME/.cortex-forge/config.yml"
[ -f "$CONFIG" ] || { echo "ERROR: $CONFIG not found — run /antu-setup first." >&2; exit 1; }

# embeddings.py/antu-index.py are co-located with the antu-setup skill,
# not in bin/ — resolve the skill dir: sibling of this script's repo (dev checkout),
# else scan config for a vault named 'antu' (self-hosting checkout).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR=""
if [[ -f "$(dirname "$SCRIPT_DIR")/skills/antu-setup/embeddings.py" ]]; then
  SKILL_DIR="$(dirname "$SCRIPT_DIR")/skills/antu-setup"
else
  # Fallback: scan config for a vault named 'antu'
  while IFS= read -r line; do
    trimmed="${line#"${line%%[![:space:]]*}"}"
    if [[ "$trimmed" == antu:* ]]; then
      candidate="${trimmed#*:}"
      candidate="${candidate#"${candidate%%[![:space:]]*}"}"
      if [[ -f "$candidate/skills/antu-setup/embeddings.py" ]]; then
        SKILL_DIR="$candidate/skills/antu-setup"
        break
      fi
    fi
  done < "$CONFIG"
fi

if [[ -z "$SKILL_DIR" ]]; then
  echo "ERROR: Cannot locate skills/antu-setup/embeddings.py. Check ~/.cortex-forge/config.yml." >&2
  exit 1
fi

INDEXER="$SKILL_DIR/antu-index.py"

# Resolve target vault path
resolve_vault() {
  local arg="$1"
  # Absolute or relative path
  if [[ -d "$arg" ]]; then
    echo "$(cd "$arg" && pwd)"
    return
  fi
  # Vault name lookup in config
  local in_vault=false
  local current_name=""
  while IFS= read -r line; do
    trimmed="${line#"${line%%[![:space:]]*}"}"
    if [[ "$trimmed" =~ ^([a-zA-Z0-9_-]+):$ ]]; then
      current_name="${BASH_REMATCH[1]}"
    fi
    if [[ "$current_name" == "$arg" && "$trimmed" == path:* ]]; then
      local p="${trimmed#path:}"
      p="${p#"${p%%[![:space:]]*}"}"
      echo "$p"
      return
    fi
  done < "$CONFIG"
  echo "ERROR: Vault '$arg' not found in $CONFIG" >&2
  exit 1
}

resolve_default_vault() {
  local default_name=""
  while IFS= read -r line; do
    trimmed="${line#"${line%%[![:space:]]*}"}"
    if [[ "$trimmed" == default:* ]]; then
      default_name="${trimmed#default:}"
      default_name="${default_name#"${default_name%%[![:space:]]*}"}"
      break
    fi
  done < "$CONFIG"
  if [[ -z "$default_name" ]]; then
    echo "ERROR: No default vault in $CONFIG" >&2
    exit 1
  fi
  resolve_vault "$default_name"
}

if [[ $# -eq 0 ]]; then
  VAULT_PATH="$(resolve_default_vault)"
elif [[ $# -eq 1 ]]; then
  VAULT_PATH="$(resolve_vault "$1")"
else
  echo "Usage: antu-embed [vault_name|vault_path]" >&2
  exit 1
fi

echo "Vault:  $VAULT_PATH"
echo "Scripts: $SKILL_DIR"
echo ""

python3 "$INDEXER" "$VAULT_PATH"
