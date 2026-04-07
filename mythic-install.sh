#!/usr/bin/env bash
# mythic-install.sh — Mythic OS installer
#
# Sets up the Mythic OS governance framework using symlinks from ~/.claude/
# to the repo, matching the multi-system architecture described in docs/walkthrough.md.
#
# Usage:
#   bash mythic-install.sh               # dry-run preview
#   bash mythic-install.sh --apply       # full symlink-based install (recommended)
#   bash mythic-install.sh --apply --copy  # legacy flat-copy install

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEMS_DIR="$HOME/systems"
PROJECTS_DIR="$HOME/projects"
CLAUDE_DIR="$HOME/.claude"
DRY_RUN=true
COPY_MODE=false

# Parse flags
for arg in "$@"; do
  case $arg in
    --apply) DRY_RUN=false ;;
    --copy) COPY_MODE=true ;;
    --help|-h)
      echo "Usage: bash mythic-install.sh [--apply] [--copy]"
      echo ""
      echo "  (no flags)    Preview what would be installed (dry run)"
      echo "  --apply       Install Mythic OS with symlinks (recommended)"
      echo "  --apply --copy  Legacy install: copy files flat into ~/.claude"
      echo ""
      echo "The default install creates:"
      echo "  ~/systems/mythic-os/  Source of truth (symlinked or moved here)"
      echo "  ~/projects/mythic/    Project workspace with walk-up CLAUDE.md"
      echo "  ~/.claude/            Symlinks to ~/systems/mythic-os/"
      echo ""
      echo "See docs/walkthrough.md for the full architecture guide."
      exit 0
      ;;
  esac
done

echo ""
echo "========================================"
echo "        Mythic OS Installer"
echo "========================================"
echo ""

if $DRY_RUN; then
  echo ">> DRY RUN — no files will be written."
  echo "   Run with --apply to install."
  if $COPY_MODE; then
    echo "   Mode: flat copy (legacy)"
  else
    echo "   Mode: symlink (recommended)"
  fi
  echo ""
fi

# ── Directories and files that Mythic OS provides ────────────────
DIRS=(rules skills stacks templates commands hooks adr agents)
FILES=(CLAUDE.md LIBRARY.md settings.json)

# ══════════════════════════════════════════════════════════════════
# PREFLIGHT CHECKS
# ══════════════════════════════════════════════════════════════════
echo "Preflight checks:"

# Claude Code
if command -v claude &>/dev/null; then
  echo "  [ok] Claude Code found: $(which claude)"
else
  echo "  [!!] Claude Code not found."
  echo "       Install it from: https://claude.ai/download"
  if ! $DRY_RUN; then exit 1; fi
fi

# jq (required for symlink mode settings merge)
if ! $COPY_MODE; then
  if command -v jq &>/dev/null; then
    echo "  [ok] jq found: $(which jq)"
  else
    echo "  [!!] jq not found (required for settings merge)."
    echo "       Install it:"
    echo "         macOS:        brew install jq"
    echo "         Debian/Ubuntu: sudo apt-get install jq"
    echo "         Fedora/RHEL:  sudo dnf install jq"
    echo "         Other:        https://jqlang.github.io/jq/download/"
    if ! $DRY_RUN; then exit 1; fi
  fi
fi

# Python 3 (enforcement hooks)
if command -v python3 &>/dev/null; then
  echo "  [ok] Python 3 found: $(which python3)"
else
  echo "  [!!] Python 3 not found (enforcement hooks need it)."
  if ! $DRY_RUN; then exit 1; fi
fi

# Existing state detection
if [ -d "$CLAUDE_DIR" ]; then
  if [ -f "$CLAUDE_DIR/.active-system" ]; then
    CURRENT_SYSTEM=$(cat "$CLAUDE_DIR/.active-system")
    echo "  [ok] ~/.claude exists (active system: $CURRENT_SYSTEM)"
  elif [ -L "$CLAUDE_DIR/rules" ]; then
    echo "  [ok] ~/.claude exists (symlinked, no .active-system marker)"
  elif [ -d "$CLAUDE_DIR/rules" ]; then
    echo "  [ok] ~/.claude exists (flat copy install detected)"
  else
    echo "  [ok] ~/.claude exists"
  fi
else
  echo "  [--] ~/.claude does not exist — will create"
fi

echo ""

# ══════════════════════════════════════════════════════════════════
# COPY MODE (legacy flat install)
# ══════════════════════════════════════════════════════════════════
if $COPY_MODE; then
  echo "Install mode: flat copy (legacy)"
  echo ""
  echo "Files to install into $CLAUDE_DIR:"
  echo ""

  for file in "${FILES[@]}"; do
    src="$SCRIPT_DIR/$file"
    dst="$CLAUDE_DIR/$file"
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
    dst="$CLAUDE_DIR/$dir"
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

  if $DRY_RUN; then
    echo "Run 'bash mythic-install.sh --apply --copy' to apply."
    echo ""
    exit 0
  fi

  echo "Installing Mythic OS (copy mode)..."
  echo ""

  mkdir -p "$CLAUDE_DIR"

  # Preserve user settings before overwriting
  if [ ! -f "$CLAUDE_DIR/settings.user.json" ]; then
    if [ -f "$CLAUDE_DIR/settings.json" ] && [ ! -L "$CLAUDE_DIR/settings.json" ]; then
      cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.user.json"
      echo "  Preserved user settings -> settings.user.json"
    fi
  fi

  # Copy root files
  for file in "${FILES[@]}"; do
    src="$SCRIPT_DIR/$file"
    dst="$CLAUDE_DIR/$file"
    if [ -f "$src" ]; then
      cp "$src" "$dst"
      echo "  [ok] $file"
    fi
  done

  # Copy directories (merge — preserves existing files not part of Mythic OS)
  for dir in "${DIRS[@]}"; do
    src="$SCRIPT_DIR/$dir"
    dst="$CLAUDE_DIR/$dir"
    if [ -d "$src" ]; then
      mkdir -p "$dst"
      cp -R "$src/." "$dst/"
      echo "  [ok] $dir/"
    fi
  done

  echo ""
  echo "========================================"
  echo "       Installation complete!"
  echo "========================================"
  echo ""
  echo "Next steps:"
  echo "  1. Open a new Claude Code session"
  echo "  2. Type: /boot"
  echo "  3. Mythic OS is ready."
  echo ""
  exit 0
fi

# ══════════════════════════════════════════════════════════════════
# SYMLINK MODE (recommended — full setup)
# ══════════════════════════════════════════════════════════════════
echo "Install mode: symlink (recommended)"
echo ""

# ── Step 1: Preview ──────────────────────────────────────────────
echo "This will set up:"
echo ""

# ~/systems/mythic-os
REPO_PATH="$SYSTEMS_DIR/mythic-os"
if [ "$(cd "$SCRIPT_DIR" && pwd)" = "$(cd "$REPO_PATH" 2>/dev/null && pwd)" ] 2>/dev/null; then
  echo "  ~/systems/mythic-os/       already here"
elif [ -d "$REPO_PATH" ] || [ -L "$REPO_PATH" ]; then
  existing_target=$(readlink "$REPO_PATH" 2>/dev/null || echo "$REPO_PATH")
  echo "  ~/systems/mythic-os/       EXISTS (points to $existing_target)"
  echo "       !! Repo is at $SCRIPT_DIR but ~/systems/mythic-os/ already exists."
  echo "       !! Resolve this manually before installing."
  if ! $DRY_RUN; then exit 1; fi
else
  echo "  ~/systems/mythic-os/       -> $SCRIPT_DIR (symlink)"
fi

# use-system.sh
if [ -f "$SYSTEMS_DIR/use-system.sh" ]; then
  echo "  ~/systems/use-system.sh    update"
else
  echo "  ~/systems/use-system.sh    create"
fi

# ~/projects/mythic
if [ -f "$PROJECTS_DIR/mythic/CLAUDE.md" ]; then
  echo "  ~/projects/mythic/CLAUDE.md  already exists (skip)"
else
  echo "  ~/projects/mythic/CLAUDE.md  create"
fi

# Symlinks
echo ""
echo "  ~/.claude/ symlinks:"
for dir in "${DIRS[@]}"; do
  src="$SCRIPT_DIR/$dir"
  dst="$CLAUDE_DIR/$dir"
  if [ -d "$src" ]; then
    if [ -L "$dst" ]; then
      echo "    $dir/ -> (update symlink)"
    elif [ -d "$dst" ]; then
      echo "    $dir/ -> (backup existing dir, create symlink)"
    else
      echo "    $dir/ -> (create symlink)"
    fi
  fi
done
echo "    LIBRARY.md -> (symlink)"
echo "    settings.json -> (merge user prefs + mythic hooks)"

echo ""

if $DRY_RUN; then
  echo "Run 'bash mythic-install.sh --apply' to apply."
  echo ""
  exit 0
fi

# ── Step 2: Set up ~/systems/ ────────────────────────────────────
echo "Setting up ~/systems/..."

mkdir -p "$SYSTEMS_DIR"

# Link repo into ~/systems/mythic-os if not already there
SCRIPT_DIR_RESOLVED="$(cd "$SCRIPT_DIR" && pwd)"
if [ -d "$REPO_PATH" ] || [ -L "$REPO_PATH" ]; then
  REPO_PATH_RESOLVED="$(cd "$REPO_PATH" && pwd)"
  if [ "$SCRIPT_DIR_RESOLVED" = "$REPO_PATH_RESOLVED" ]; then
    echo "  [ok] Repo already at ~/systems/mythic-os/"
  else
    echo "  [!!] ~/systems/mythic-os/ exists but points to $REPO_PATH_RESOLVED"
    echo "       This repo is at $SCRIPT_DIR_RESOLVED"
    echo "       Remove or rename the existing one and re-run."
    exit 1
  fi
else
  ln -s "$SCRIPT_DIR_RESOLVED" "$REPO_PATH"
  echo "  [ok] ~/systems/mythic-os/ -> $SCRIPT_DIR_RESOLVED"
fi

# ── Step 3: Install use-system.sh ────────────────────────────────
echo ""
echo "Installing use-system.sh..."

USE_SYSTEM_SRC="$SCRIPT_DIR/scripts/use-system.sh"
USE_SYSTEM_DST="$SYSTEMS_DIR/use-system.sh"

if [ ! -f "$USE_SYSTEM_SRC" ]; then
  echo "  [!!] scripts/use-system.sh not found in repo. Cannot continue."
  exit 1
fi

if [ -f "$USE_SYSTEM_DST" ]; then
  if ! diff -q "$USE_SYSTEM_SRC" "$USE_SYSTEM_DST" &>/dev/null; then
    backup="$SYSTEMS_DIR/use-system.sh.backup.$(date +%Y%m%d%H%M%S)"
    cp "$USE_SYSTEM_DST" "$backup"
    echo "  Backed up existing -> $(basename "$backup")"
  fi
fi

cp "$USE_SYSTEM_SRC" "$USE_SYSTEM_DST"
chmod +x "$USE_SYSTEM_DST"
echo "  [ok] ~/systems/use-system.sh installed"

# ── Step 4: Create ~/projects/mythic/ ────────────────────────────
echo ""
echo "Setting up ~/projects/mythic/..."

mkdir -p "$PROJECTS_DIR/mythic"

WALKUP_SRC="$SCRIPT_DIR/templates/walkup-claude.md"
WALKUP_DST="$PROJECTS_DIR/mythic/CLAUDE.md"

if [ -f "$WALKUP_DST" ]; then
  echo "  [ok] ~/projects/mythic/CLAUDE.md already exists (preserved)"
else
  if [ -f "$WALKUP_SRC" ]; then
    cp "$WALKUP_SRC" "$WALKUP_DST"
    echo "  [ok] ~/projects/mythic/CLAUDE.md created"
  else
    echo "  [!!] templates/walkup-claude.md not found — skipping walk-up file"
  fi
fi

# ── Step 5: Activate the system via use-system.sh ────────────────
echo ""
echo "Activating mythic-os..."
echo ""

# Preserve user settings before the switcher runs
if [ ! -f "$CLAUDE_DIR/settings.user.json" ]; then
  if [ -f "$CLAUDE_DIR/settings.json" ] && [ ! -L "$CLAUDE_DIR/settings.json" ]; then
    mkdir -p "$CLAUDE_DIR"
    cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.user.json"
    echo "  Preserved user settings -> settings.user.json"
  fi
fi

# Delegate to use-system.sh for all symlinking and settings merge
if ! bash "$USE_SYSTEM_DST" mythic; then
  echo ""
  echo "  [!!] System activation failed. Check the output above."
  exit 1
fi

# ── Step 6: Post-install summary ─────────────────────────────────
echo ""
echo "========================================"
echo "       Installation complete!"
echo "========================================"
echo ""
echo "What was set up:"
echo "  ~/systems/mythic-os/         Source of truth (repo)"
echo "  ~/systems/use-system.sh      System switcher"
echo "  ~/projects/mythic/           Project workspace"
echo "  ~/.claude/                   Symlinks to mythic-os"
echo ""
echo "Next steps:"
echo "  1. cd ~/projects/mythic"
echo "  2. mkdir my-new-project && cd my-new-project"
echo "  3. Open Claude Code: claude"
echo "  4. Type: /boot"
echo ""
echo "Switch systems:  source ~/systems/use-system.sh --status"
echo "Full guide:      cat $(cd "$SCRIPT_DIR" && pwd)/docs/walkthrough.md"
echo ""
