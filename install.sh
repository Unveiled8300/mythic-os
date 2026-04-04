#!/usr/bin/env bash
# install.sh — Claude OS installer
#
# Copies this governance system into ~/.claude, preserving any existing files
# that are NOT part of Claude OS (personal plans, projects, etc.).
#
# Usage:
#   bash install.sh           # dry-run preview
#   bash install.sh --apply   # apply the installation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME/.claude"
DRY_RUN=true

# Parse flags
for arg in "$@"; do
  case $arg in
    --apply) DRY_RUN=false ;;
    --help|-h)
      echo "Usage: bash install.sh [--apply]"
      echo "  (no flags)  Preview what would be installed (dry run)"
      echo "  --apply     Install Claude OS into ~/.claude"
      exit 0
      ;;
  esac
done

echo ""
echo "╔══════════════════════════════════════╗"
echo "║         Claude OS Installer          ║"
echo "╚══════════════════════════════════════╝"
echo ""

if $DRY_RUN; then
  echo "▶ DRY RUN — no files will be written."
  echo "  Run with --apply to install."
  echo ""
fi

# Directories to install (relative paths)
DIRS=(
  "rules"
  "skills"
  "stacks"
  "templates"
  "commands"
  "hooks"
  "adr"
  "agents"
)

# Root files to install
FILES=(
  "CLAUDE.md"
  "LIBRARY.md"
  "LIBRARY-HISTORY.md"
  "settings.json"
)

# ── Preflight checks ──────────────────────────────────────────────
echo "Preflight checks:"

# Check Claude Code is installed
if command -v claude &>/dev/null; then
  echo "  ✓ Claude Code found: $(which claude)"
else
  echo "  ✗ Claude Code not found."
  echo "    Install it from: https://claude.ai/download"
  if ! $DRY_RUN; then exit 1; fi
fi

# Check target dir
if [ -d "$TARGET" ]; then
  echo "  ✓ ~/.claude exists"
else
  echo "  ○ ~/.claude does not exist — will create on install"
fi
echo ""

# ── Show what will be installed ───────────────────────────────────
echo "Files to install into $TARGET:"
echo ""

for file in "${FILES[@]}"; do
  src="$SCRIPT_DIR/$file"
  dst="$TARGET/$file"
  if [ -f "$src" ]; then
    if [ -f "$dst" ]; then
      echo "  OVERWRITE  $file"
    else
      echo "  CREATE     $file"
    fi
  fi
done

for dir in "${DIRS[@]}"; do
  src="$SCRIPT_DIR/$dir"
  dst="$TARGET/$dir"
  if [ -d "$src" ]; then
    file_count=$(find "$src" -type f | wc -l | tr -d ' ')
    if [ -d "$dst" ]; then
      echo "  MERGE      $dir/  ($file_count files)"
    else
      echo "  CREATE     $dir/  ($file_count files)"
    fi
  fi
done

echo ""

# ── Apply installation ────────────────────────────────────────────
if $DRY_RUN; then
  echo "Run 'bash install.sh --apply' to apply."
  echo ""
  exit 0
fi

echo "Installing Claude OS..."
echo ""

mkdir -p "$TARGET"

# Copy root files
for file in "${FILES[@]}"; do
  src="$SCRIPT_DIR/$file"
  dst="$TARGET/$file"
  if [ -f "$src" ]; then
    cp "$src" "$dst"
    echo "  ✓ $file"
  fi
done

# Copy directories (rsync-style merge)
for dir in "${DIRS[@]}"; do
  src="$SCRIPT_DIR/$dir"
  dst="$TARGET/$dir"
  if [ -d "$src" ]; then
    mkdir -p "$dst"
    cp -R "$src/." "$dst/"
    echo "  ✓ $dir/"
  fi
done

echo ""
echo "╔══════════════════════════════════════╗"
echo "║       Installation complete!         ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. Open a new Claude Code session"
echo "  2. Type: /boot"
echo "  3. Claude OS is ready."
echo ""
