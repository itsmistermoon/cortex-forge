#!/usr/bin/env bash
# Cortex Forge installer
# Usage: curl -fsSL https://raw.githubusercontent.com/itsmistermoon/cortex-forge/main/install.sh | bash
# Or:    bash install.sh [--vault /path/to/vault] [--no-skills] [--quiet]
#
# Cortex Forge does not use agent lifecycle hooks (SessionStart/PreCompact/
# SessionEnd/PreToolUse) — support for those is too uneven across agents.
# All memory operations are manual, via skills (/cortex-crystallize,
# /cortex-recall), per AGENTS.md instructions. The only hooks this installer
# offers are plain git post-commit hooks (Step 5 below), which behave
# identically regardless of which agent is in use.
set -euo pipefail

# ── Constants ─────────────────────────────────────────────────────────────────
REPO="itsmistermoon/cortex-forge"
REPO_URL="https://github.com/${REPO}.git"
FORGE_DIR="${HOME}/.cortex-forge"
CONFIG="${FORGE_DIR}/config.yml"
SKILLS_DIR="${HOME}/.agents/skills"
SKILL_NAMES=(cortex-crystallize cortex-forge-setup cortex-recall cortex-assimilate cortex-imprint cortex-prune)

# ── Colors ────────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  BOLD='\033[1m'; DIM='\033[2m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
  CYAN='\033[0;36m'; RED='\033[0;31m'; RESET='\033[0m'
else
  BOLD=''; DIM=''; GREEN=''; YELLOW=''; CYAN=''; RED=''; RESET=''
fi

log()  { printf "${CYAN}▸${RESET} %s\n" "$*"; }
ok()   { printf "${GREEN}✓${RESET} %s\n" "$*"; }
warn() { printf "${YELLOW}⚠${RESET} %s\n" "$*"; }
err()  { printf "${RED}✗${RESET} %s\n" "$*" >&2; }
bold() { printf "${BOLD}%s${RESET}\n" "$*"; }
dim()  { printf "${DIM}%s${RESET}\n" "$*"; }

# ── Flags ─────────────────────────────────────────────────────────────────────
VAULT_PATH=""
INSTALL_SKILLS=true
QUIET=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault)    VAULT_PATH="$2"; shift 2 ;;
    --no-skills) INSTALL_SKILLS=false; shift ;;
    --quiet)    QUIET=true; shift ;;
    *) err "Unknown option: $1"; exit 1 ;;
  esac
done

# ── Detect if running interactively (not piped) ───────────────────────────────
INTERACTIVE=false
[ -t 0 ] && INTERACTIVE=true

ask() {
  # ask <prompt> <default>
  # Returns 0 (yes) or 1 (no). In non-interactive mode uses the default.
  local prompt="$1" default="${2:-y}"
  if $INTERACTIVE; then
    local yn_hint; [ "$default" = "y" ] && yn_hint="[Y/n]" || yn_hint="[y/N]"
    printf "%s %s " "$prompt" "$yn_hint"
    read -r answer
    case "$answer" in
      [Yy]*|"") [ "$default" = "y" ] && return 0 || return 1 ;;
      *)         [ "$default" = "y" ] && return 1 || return 0 ;;
    esac
  else
    [ "$default" = "y" ] && return 0 || return 1
  fi
}

ask_input() {
  # ask_input <prompt> <default>
  # Prints the chosen value to stdout.
  local prompt="$1" default="$2"
  if $INTERACTIVE; then
    printf "%s [%s]: " "$prompt" "$default"
    read -r answer
    echo "${answer:-$default}"
  else
    echo "$default"
  fi
}

# ── Header ────────────────────────────────────────────────────────────────────
$QUIET || {
  printf "\n"
  bold "  Cortex Forge — Installer"
  dim   "  https://github.com/${REPO}"
  printf "\n"
}

# ── Step 1: Install forge runtime ────────────────────────────────────────────
log "Installing forge to ${FORGE_DIR}"

_install_from_tarball() {
  local tarball_url
  tarball_url=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep '"browser_download_url"' \
    | grep 'cortex-forge\.tar\.gz' \
    | head -1 \
    | sed 's/.*"browser_download_url": "\(.*\)"/\1/')
  [ -z "$tarball_url" ] && return 1
  local tmp; tmp=$(mktemp -d)
  curl -fsSL "$tarball_url" | tar -xz -C "$tmp"
  rm -rf "$FORGE_DIR"
  mv "$tmp/cortex-forge" "$FORGE_DIR"
  rm -rf "$tmp"
}

_update_from_tarball() {
  local tarball_url
  tarball_url=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep '"browser_download_url"' \
    | grep 'cortex-forge\.tar\.gz' \
    | head -1 \
    | sed 's/.*"browser_download_url": "\(.*\)"/\1/')
  [ -z "$tarball_url" ] && return 1
  local tmp; tmp=$(mktemp -d)
  curl -fsSL "$tarball_url" | tar -xz -C "$tmp"
  # Preserve user config, replace everything else
  [ -f "${FORGE_DIR}/config.yml" ] && cp "${FORGE_DIR}/config.yml" "$tmp/cortex-forge/"
  rm -rf "$FORGE_DIR"
  mv "$tmp/cortex-forge" "$FORGE_DIR"
  rm -rf "$tmp"
}

if [ -d "${FORGE_DIR}/.git" ]; then
  # Dev/contributor install — update via git
  git -C "$FORGE_DIR" pull --ff-only --quiet
  ok "Forge updated (git)"
elif [ -d "$FORGE_DIR" ] && [ -f "${FORGE_DIR}/AGENTS.md" ]; then
  # Tarball install — update via tarball, preserving config.yml
  if _update_from_tarball; then
    ok "Forge updated"
  else
    warn "No release found — forge already present, skipping update"
  fi
else
  rm -rf "$FORGE_DIR"
  if _install_from_tarball; then
    ok "Forge installed"
  else
    # Fallback for dev environments with no published release yet
    warn "No release found — falling back to git clone"
    git clone --depth=1 --quiet "$REPO_URL" "$FORGE_DIR"
    ok "Forge cloned (git)"
  fi
fi

# ── Step 2: Resolve vault ─────────────────────────────────────────────────────
if [ -z "$VAULT_PATH" ]; then
  if [ -f "$FORGE_DIR/wiki/index.md" ] && [ -f "$FORGE_DIR/AGENTS.md" ]; then
    # The forge itself is a vault — common for contributors
    VAULT_PATH="$FORGE_DIR"
  elif [ -f "$(pwd)/wiki/index.md" ] && [ -f "$(pwd)/AGENTS.md" ]; then
    VAULT_PATH="$(pwd)"
  else
    if $INTERACTIVE; then
      printf "\n"
      warn "No vault found in CWD. Enter the path to your vault, or press Enter to skip."
      VAULT_PATH=$(ask_input "Vault path" "")
    else
      warn "No vault specified. Skipping vault registration (re-run with --vault /path/to/vault)."
    fi
  fi
fi

VAULT_VALID=false
if [ -n "$VAULT_PATH" ]; then
  VAULT_PATH=$(cd "$VAULT_PATH" 2>/dev/null && pwd || echo "")
  if [ -d "${VAULT_PATH}/wiki" ] && [ -f "${VAULT_PATH}/AGENTS.md" ] && [ -d "${VAULT_PATH}/.git" ]; then
    VAULT_VALID=true
    VAULT_NAME=$(basename "$VAULT_PATH")
    ok "Vault: ${VAULT_NAME} (${VAULT_PATH})"
  else
    warn "Path '${VAULT_PATH}' is not a valid vault (missing wiki/, AGENTS.md, or .git/). Skipping registration."
    VAULT_PATH=""
  fi
fi

# ── Step 3: Register vault in config.yml ─────────────────────────────────────
if $VAULT_VALID; then
  mkdir -p "$FORGE_DIR"
  if [ ! -f "$CONFIG" ]; then
    cat > "$CONFIG" <<YAML
vaults:
  ${VAULT_NAME}:
    path: ${VAULT_PATH}
    locale: en
default: ${VAULT_NAME}
imprint_triage: suggest
hot_cache_stale_days: 15
YAML
    ok "Config created: ${CONFIG}"
  elif ! grep -qF "$VAULT_PATH" "$CONFIG"; then
    # Append vault entry without clobbering existing entries
    python3 - <<PYEOF
import re, sys
cfg = open("${CONFIG}").read()
entry = "  ${VAULT_NAME}:\n    path: ${VAULT_PATH}\n    locale: en\n"
if "vaults:" not in cfg:
    cfg = "vaults:\n" + entry + cfg
else:
    cfg = re.sub(r"(vaults:\n)", r"\1" + entry, cfg, count=1)
open("${CONFIG}", "w").write(cfg)
PYEOF
    ok "Vault registered in config"
  else
    ok "Vault already registered"
  fi
fi

# ── Step 4: Install skills ────────────────────────────────────────────────────
if $INSTALL_SKILLS; then
  mkdir -p "$SKILLS_DIR"
  for skill in "${SKILL_NAMES[@]}"; do
    src="${FORGE_DIR}/skills/${skill}"
    [ -d "$src" ] || continue
    cp -r "$src" "${SKILLS_DIR}/${skill}"
  done
  ok "Skills installed to ${SKILLS_DIR}"

  # Claude Code symlinks
  if [ -d "${HOME}/.claude" ]; then
    mkdir -p "${HOME}/.claude/skills"
    for skill in "${SKILL_NAMES[@]}"; do
      ln -sf "${SKILLS_DIR}/${skill}" "${HOME}/.claude/skills/${skill}"
    done
    ok "Claude Code skill symlinks created"
  fi

  # Antigravity symlinks
  if [ -d "${HOME}/.gemini/config" ]; then
    mkdir -p "${HOME}/.gemini/config/skills"
    for skill in "${SKILL_NAMES[@]}"; do
      ln -sf "${SKILLS_DIR}/${skill}" "${HOME}/.gemini/config/skills/${skill}"
    done
    ok "Antigravity skill symlinks created"
  fi
fi

# ── Step 5: Post-commit git hooks (opt-in) ───────────────────────────────────
# Git hooks run outside any agent session, so they need a fixed absolute path —
# stage the co-located skill scripts into ~/.cortex-forge/bin/ once, here, rather
# than referencing them inside ~/.agents/skills/ (path varies by install method).
if $VAULT_VALID && $INTERACTIVE; then
  mkdir -p "${FORGE_DIR}/bin/hooks"
  [ -f "${FORGE_DIR}/skills/cortex-prune/cortex-prune.sh" ] && \
    cp "${FORGE_DIR}/skills/cortex-prune/cortex-prune.sh" "${FORGE_DIR}/bin/cortex-prune.sh"
  [ -f "${FORGE_DIR}/skills/cortex-forge-setup/cortex-reindex-post-commit.sh" ] && \
    cp "${FORGE_DIR}/skills/cortex-forge-setup/cortex-reindex-post-commit.sh" "${FORGE_DIR}/bin/hooks/cortex-reindex-post-commit.sh"

  printf "\n"
  if ask "Install post-commit prune hook (refreshes vault-report.json)?" "y"; then
    PC="${VAULT_PATH}/.git/hooks/post-commit"
    [ -f "$PC" ] || printf '#!/bin/bash\n' > "$PC"
    chmod +x "$PC"
    BLOCK='# >>> cortex-forge prune >>>\nif [ -f ~/.cortex-forge/bin/cortex-prune.sh ]; then\n  (bash ~/.cortex-forge/bin/cortex-prune.sh >/dev/null 2>&1 || true) &\nfi\n# <<< cortex-forge prune <<<'
    if ! grep -q "cortex-forge prune" "$PC"; then
      printf "\n%b\n" "$BLOCK" >> "$PC"
      ok "Post-commit prune hook installed"
    else
      ok "Post-commit prune hook already present"
    fi
  fi

  if ask "Install post-commit reindex hook (updates semantic search)?" "y"; then
    PC="${VAULT_PATH}/.git/hooks/post-commit"
    [ -f "$PC" ] || printf '#!/bin/bash\n' > "$PC"
    chmod +x "$PC"
    BLOCK='# >>> cortex-forge reindex >>>\nbash ~/.cortex-forge/bin/hooks/cortex-reindex-post-commit.sh\n# <<< cortex-forge reindex <<<'
    if ! grep -q "cortex-forge reindex" "$PC"; then
      printf "\n%b\n" "$BLOCK" >> "$PC"
      ok "Post-commit reindex hook installed"
    else
      ok "Post-commit reindex hook already present"
    fi
  fi
fi

# ── Done ──────────────────────────────────────────────────────────────────────
printf "\n"
bold "  Installation complete"
printf "\n"

if $VAULT_VALID; then
  dim "  Vault registered : ${VAULT_NAME}"
fi
dim   "  Forge location   : ${FORGE_DIR}"
dim   "  Config           : ${CONFIG}"
$INSTALL_SKILLS && dim "  Skills           : ${SKILLS_DIR}"
printf "\n"
dim   "  Next steps:"
dim   "  1. Open a new session inside your vault (any agent)"
dim   "  2. AGENTS.md instructs the agent to read .cortex/MEMORY.md before its first response"
dim   "  3. Run /cortex-forge-setup if you need to adjust anything"
printf "\n"
