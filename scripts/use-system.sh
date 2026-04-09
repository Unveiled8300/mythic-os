#!/usr/bin/env bash
# use-system.sh — Switch active Claude Code system (global or per-project)
#
# Symlinks system config dirs into ~/.claude/ (global) or <project>/.claude/ (per-project)
# while preserving runtime data (sessions, history, plans, etc.) and your personal claude.md.
#
# Usage:
#   source ~/systems/use-system.sh mythic                    # Global install
#   source ~/systems/use-system.sh jetpack --project .       # Per-project install (current dir)
#   source ~/systems/use-system.sh mythic --project ~/path   # Per-project install (specific path)
#   source ~/systems/use-system.sh --clear                   # Remove global system symlinks
#   source ~/systems/use-system.sh --status                  # Show global status
#   source ~/systems/use-system.sh --status --project .      # Show project status

set -euo pipefail

SYSTEMS_DIR="$HOME/systems"
CLAUDE_DIR="$HOME/.claude"

# ── Config items that get symlinked ──────────────────────────────
LINK_DIRS=(skills commands rules hooks agents stacks templates brain adr)
LINK_FILES=(LIBRARY.md)

# ── Gitignore entries for per-project installs ───────────────────
GITIGNORE_ENTRIES=(
  "# Claude Code system symlinks (local to this machine)"
  ".claude/skills"
  ".claude/rules"
  ".claude/hooks"
  ".claude/commands"
  ".claude/agents"
  ".claude/stacks"
  ".claude/templates"
  ".claude/brain"
  ".claude/adr"
  ".claude/CLAUDE.md"
  ".claude/LIBRARY.md"
  ".claude/.active-system"
  ".claude/settings.json"
)

# ── Parse arguments ──────────────────────────────────────────────
PROJECT_DIR=""
ACTION=""
SYSTEM=""

while [ $# -gt 0 ]; do
  case "$1" in
    --status)  ACTION="status";  shift ;;
    --clear)   ACTION="clear";   shift ;;
    --project) PROJECT_DIR="$2"; shift 2 ;;
    -*)        echo "Unknown flag: $1"; return 1 2>/dev/null || exit 1 ;;
    *)         SYSTEM="$1";      shift ;;
  esac
done

# Resolve relative project path
if [ -n "$PROJECT_DIR" ]; then
  PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || {
    echo "Project directory not found: $PROJECT_DIR"
    return 1 2>/dev/null || exit 1
  }
fi

# Determine target directory (global ~/.claude/ or project .claude/)
if [ -n "$PROJECT_DIR" ]; then
  TARGET_CLAUDE="$PROJECT_DIR/.claude"
else
  TARGET_CLAUDE="$CLAUDE_DIR"
fi

# ── Status check ─────────────────────────────────────────────────
if [ "$ACTION" = "status" ]; then
  echo "System config in $TARGET_CLAUDE:"
  for dir in "${LINK_DIRS[@]}"; do
    target="$TARGET_CLAUDE/$dir"
    if [ -L "$target" ]; then
      resolved=$(readlink "$target")
      echo "  $dir/ → $resolved"
    elif [ -d "$target" ]; then
      echo "  $dir/ (local copy, not linked)"
    else
      echo "  $dir/ (not present)"
    fi
  done
  for file in "${LINK_FILES[@]}"; do
    target="$TARGET_CLAUDE/$file"
    if [ -L "$target" ]; then
      resolved=$(readlink "$target")
      echo "  $file → $resolved"
    elif [ -f "$target" ]; then
      echo "  $file (local copy, not linked)"
    else
      echo "  $file (not present)"
    fi
  done
  # System CLAUDE.md (per-project only — global uses user's personal CLAUDE.md)
  if [ -n "$PROJECT_DIR" ]; then
    target="$TARGET_CLAUDE/CLAUDE.md"
    if [ -L "$target" ]; then
      resolved=$(readlink "$target")
      echo "  CLAUDE.md → $resolved (system constitution)"
    elif [ -f "$target" ]; then
      echo "  CLAUDE.md (local copy, not linked)"
    else
      echo "  CLAUDE.md (not present — system constitution not installed)"
    fi
  fi
  if [ -f "$TARGET_CLAUDE/.active-system" ]; then
    echo ""
    echo "Active system: $(cat "$TARGET_CLAUDE/.active-system")"
  else
    echo ""
    echo "Active system: unknown (no .active-system marker)"
  fi
  return 0 2>/dev/null || exit 0
fi

# ── Clear global system ──────────────────────────────────────────
if [ "$ACTION" = "clear" ]; then
  echo "Clearing global system symlinks from ~/.claude/"
  echo ""
  for dir in "${LINK_DIRS[@]}"; do
    target="$CLAUDE_DIR/$dir"
    if [ -L "$target" ]; then
      rm "$target"
      echo "  Removed: $dir/"
    fi
  done
  for file in "${LINK_FILES[@]}"; do
    target="$CLAUDE_DIR/$file"
    if [ -L "$target" ]; then
      rm "$target"
      echo "  Removed: $file"
    fi
  done
  # Restore settings.json to user prefs only
  if [ -f "$CLAUDE_DIR/settings.user.json" ]; then
    cp "$CLAUDE_DIR/settings.user.json" "$CLAUDE_DIR/settings.json"
    echo ""
    echo "  settings.json restored to user prefs only"
  fi
  echo "none" > "$CLAUDE_DIR/.active-system"
  echo ""
  echo "Global system cleared. Projects with per-project installs are unaffected."
  echo "Start a new Claude Code session to pick up the changes."
  return 0 2>/dev/null || exit 0
fi

# ── Validate system name ────────────────────────────────────────
if [ -z "$SYSTEM" ]; then
  echo "Usage: source ~/systems/use-system.sh <system-name> [--project <path>]"
  echo "       source ~/systems/use-system.sh --clear"
  echo "       source ~/systems/use-system.sh --status [--project <path>]"
  echo ""
  echo "Available systems:"
  for d in "$SYSTEMS_DIR"/*/; do
    [ -d "$d" ] && echo "  $(basename "$d")"
  done
  return 1 2>/dev/null || exit 1
fi

# Handle shorthand: "mythic" → "mythic-os", "jetpack" → "jetpack-os", "greenfield" → "lcl-root-cc"
if [ "$SYSTEM" = "mythic" ]; then
  SYSTEM="mythic-os"
elif [ "$SYSTEM" = "jetpack" ]; then
  SYSTEM="jetpack-os"
elif [ "$SYSTEM" = "greenfield" ]; then
  SYSTEM="lcl-root-cc"
fi

SOURCE="$SYSTEMS_DIR/$SYSTEM"
if [ ! -d "$SOURCE" ]; then
  echo "System not found: $SOURCE"
  echo ""
  echo "Available systems:"
  for d in "$SYSTEMS_DIR"/*/; do
    [ -d "$d" ] && echo "  $(basename "$d")"
  done
  return 1 2>/dev/null || exit 1
fi

# ── Ensure target .claude/ exists ────────────────────────────────
mkdir -p "$TARGET_CLAUDE"

# ── Save user preferences if not yet preserved (global only) ─────
if [ -z "$PROJECT_DIR" ] && [ ! -f "$CLAUDE_DIR/settings.user.json" ]; then
  if [ -f "$CLAUDE_DIR/settings.json" ] && [ ! -L "$CLAUDE_DIR/settings.json" ]; then
    cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.user.json"
    echo "  Preserved user settings → settings.user.json"
  fi
fi

# ── Remove old symlinks ─────────────────────────────────────────
for dir in "${LINK_DIRS[@]}"; do
  target="$TARGET_CLAUDE/$dir"
  if [ -L "$target" ]; then
    rm "$target"
  fi
done
for file in "${LINK_FILES[@]}"; do
  target="$TARGET_CLAUDE/$file"
  if [ -L "$target" ]; then
    rm "$target"
  fi
done
# Remove old system CLAUDE.md symlink (per-project only; safe — skips regular files)
if [ -n "$PROJECT_DIR" ] && [ -L "$TARGET_CLAUDE/CLAUDE.md" ]; then
  rm "$TARGET_CLAUDE/CLAUDE.md"
fi

# ── Create new symlinks ─────────────────────────────────────────
if [ -n "$PROJECT_DIR" ]; then
  echo "Installing system into project: $PROJECT_DIR"
else
  echo "Activating system globally"
fi
echo "System: $SYSTEM"
echo ""

for dir in "${LINK_DIRS[@]}"; do
  src="$SOURCE/$dir"
  dst="$TARGET_CLAUDE/$dir"
  if [ -d "$src" ]; then
    # If there's a real directory (not symlink), back it up
    if [ -d "$dst" ] && [ ! -L "$dst" ]; then
      backup="$TARGET_CLAUDE/${dir}.backup.$(date +%Y%m%d%H%M%S)"
      mv "$dst" "$backup"
      echo "  Backed up existing $dir/ → $(basename "$backup")"
    fi
    ln -s "$src" "$dst"
    echo "  $dir/ → $src"
  fi
done

for file in "${LINK_FILES[@]}"; do
  src="$SOURCE/$file"
  dst="$TARGET_CLAUDE/$file"
  if [ -f "$src" ]; then
    if [ -f "$dst" ] && [ ! -L "$dst" ]; then
      backup="$TARGET_CLAUDE/${file}.backup.$(date +%Y%m%d%H%M%S)"
      mv "$dst" "$backup"
      echo "  Backed up existing $file → $(basename "$backup")"
    fi
    ln -s "$src" "$dst"
    echo "  $file → $src"
  fi
done

# ── Symlink system CLAUDE.md into .claude/ (per-project only) ────
# Global installs skip this — ~/.claude/CLAUDE.md is the user's personal file.
# Per-project: .claude/CLAUDE.md = system constitution, project root CLAUDE.md = project specifics.
if [ -n "$PROJECT_DIR" ]; then
  src="$SOURCE/CLAUDE.md"
  dst="$TARGET_CLAUDE/CLAUDE.md"
  if [ -f "$src" ]; then
    if [ -f "$dst" ] && [ ! -L "$dst" ]; then
      backup="$TARGET_CLAUDE/CLAUDE.md.backup.$(date +%Y%m%d%H%M%S)"
      mv "$dst" "$backup"
      echo "  Backed up existing .claude/CLAUDE.md → $(basename "$backup")"
    fi
    ln -s "$src" "$dst"
    echo "  CLAUDE.md → $src  (system constitution)"
  else
    echo "  Warning: $SOURCE/CLAUDE.md not found — system has no constitution file"
  fi
fi

# ── Merge settings.json ─────────────────────────────────────────
USER_SETTINGS="$CLAUDE_DIR/settings.user.json"
SYSTEM_SETTINGS="$SOURCE/settings.json"
MERGED_SETTINGS="$TARGET_CLAUDE/settings.json"

if [ -f "$SYSTEM_SETTINGS" ]; then
  if [ -f "$USER_SETTINGS" ]; then
    jq -s '.[0] * .[1]' "$USER_SETTINGS" "$SYSTEM_SETTINGS" > "$MERGED_SETTINGS"
    echo ""
    echo "  settings.json = user prefs + $SYSTEM hooks (merged)"
  else
    cp "$SYSTEM_SETTINGS" "$MERGED_SETTINGS"
    echo ""
    echo "  settings.json = $SYSTEM settings (no user prefs found)"
  fi
elif [ -f "$USER_SETTINGS" ]; then
  cp "$USER_SETTINGS" "$MERGED_SETTINGS"
  echo ""
  echo "  settings.json = user prefs only ($SYSTEM has no settings.json)"
fi

# ── Write active-system marker ───────────────────────────────────
echo "$SYSTEM" > "$TARGET_CLAUDE/.active-system"

# ── Update .gitignore for per-project installs ───────────────────
if [ -n "$PROJECT_DIR" ]; then
  GITIGNORE="$PROJECT_DIR/.gitignore"
  MARKER="# Claude Code system symlinks (local to this machine)"

  if [ ! -f "$GITIGNORE" ] || ! grep -qF "$MARKER" "$GITIGNORE" 2>/dev/null; then
    echo "" >> "$GITIGNORE"
    for entry in "${GITIGNORE_ENTRIES[@]}"; do
      echo "$entry" >> "$GITIGNORE"
    done
    echo ""
    echo "  .gitignore updated with system symlink entries"
  fi
fi

# ── Summary ──────────────────────────────────────────────────────
echo ""
echo "Active system: $SYSTEM"
echo "  System source: $SOURCE"
if [ -n "$PROJECT_DIR" ]; then
  echo "  Installed to: $TARGET_CLAUDE"
else
  echo "  User claude.md: preserved"
  echo "  Runtime data: untouched"
fi
echo ""
echo "Start a new Claude Code session to pick up the changes."
