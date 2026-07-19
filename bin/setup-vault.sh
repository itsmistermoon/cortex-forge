#!/usr/bin/env bash
# setup-vault.sh — Second Brain vault setup
# Run ONCE before opening Obsidian for the first time.
# Usage: bash bin/setup-vault.sh [/path/to/vault]
# Default: directory where this script lives (the vault root)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT="${1:-$(dirname "$SCRIPT_DIR")}"
OBSIDIAN="$VAULT/.obsidian"

echo "Setting up Second Brain vault at: $VAULT"

# ── 1. Create directories ─────────────────────────────────────────────────────
mkdir -p "$OBSIDIAN/snippets"
mkdir -p "$VAULT/.raw"
mkdir -p "$VAULT/wiki/concepts" "$VAULT/wiki/entities" "$VAULT/wiki/sources" "$VAULT/meta"
mkdir -p "$VAULT/wiki/pages"
mkdir -p "$VAULT/templates"
mkdir -p "$VAULT/bin"
mkdir -p "$VAULT/skills/wiki"

# ── 2. Write graph.json (color-coded by type) ────────────────────────────────
cat > "$OBSIDIAN/graph.json" << 'EOF'
{
  "collapse-filter": true,
  "search": "",
  "showTags": false,
  "showAttachments": false,
  "hideUnresolved": false,
  "showOrphans": true,
  "collapse-color-groups": true,
  "colorGroups": [
    {
      "query": "path:wiki/concepts",
      "color": { "a": 1, "rgb": 5227007 },
      "label": "Conceptos"
    },
    {
      "query": "path:wiki/entities",
      "color": { "a": 1, "rgb": 12945088 },
      "label": "Entidades"
    },
    {
      "query": "path:wiki/sources",
      "color": { "a": 1, "rgb": 6986069 },
      "label": "Fuentes"
    },
    {
      "query": "path:meta",
      "color": { "a": 1, "rgb": 5676246 },
      "label": "Meta"
    }
  ],
  "showArrow": true,
  "textFadeMultiplier": -1,
  "nodeSizeMultiplier": 1.8,
  "lineSizeMultiplier": 1.2,
  "centerStrength": 0.5,
  "repelStrength": 30,
  "linkStrength": 1.5,
  "linkDistance": 120,
  "scale": 1.0
}
EOF

# ── 3. Write app.json ────────────────────────────────────────────────────────
cat > "$OBSIDIAN/app.json" << 'EOF'
{
  "userIgnoreFilters": [
    "bin/",
    "skills/",
    ".commandcode/",
    ".git/"
  ]
}
EOF

# ── 4. Write appearance.json ─────────────────────────────────────────────────
cat > "$OBSIDIAN/appearance.json" << 'EOF'
{
  "cssTheme": "Dracula Official",
  "nativeMenus": true,
  "translucency": false,
  "enabledCssSnippets": []
}
EOF

# ── 5. Write community-plugins.json ─────────────────────────────────────────
cat > "$OBSIDIAN/community-plugins.json" << 'EOF'
[
  "templater-obsidian",
  "dataview",
  "obsidian-git",
  "calendar",
  "obsidian-excalidraw-plugin",
  "obsidian-banners"
]
EOF

echo ""
echo "✓ Setup complete."
echo ""
echo "Next steps:"
echo "  1. Open Obsidian → Manage Vaults → Open folder as vault → $VAULT"
echo "  2. Enable community plugins when prompted"
echo "  3. Install missing plugins: Dataview, Templater, Obsidian Git,"
echo "     Calendar, Excalidraw, Banners (Settings → Community Plugins)"
echo "  4. Configure Templater to use templates/ as template folder"
echo "  5. Start a session with Claude Code / CommandCode"
echo ""
echo "Pre-created directories:"
echo "  .raw/          — Source documents (immutable)"
echo "  wiki/concepts/ — Conceptual knowledge"
echo "  wiki/entities/ — People, tools, services"
echo "  wiki/sources/  — External references"
echo "  meta/          — Vault metadata"
echo "  wiki/pages/    — General wiki pages"
echo "  templates/     — Obsidian templates per type"
echo "  bin/           — Utility scripts"
echo "  skills/        — Agent skills"
