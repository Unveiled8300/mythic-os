#!/usr/bin/env bash
# use-system.sh — Switch active Claude Code system
#
# Symlinks system config dirs into ~/.claude/ while preserving
# runtime data (sessions, history, plans, etc.) and your personal claude.md.
#
# This file ships with Mythic OS but is system-agnostic — it switches
# between any systems in ~/systems/. The installer copies it to
# ~/systems/use-system.sh during setup.
#
# Usage:
#   source ~/systems/use-system.sh mythic      # Activate Mythic OS
#   source ~/systems/use-system.sh jetpack     # Activate Jetpack OS
#   source ~/systems/use-system.sh lcl-root-cc # Green-field mode
#   source ~/systems/use-system.sh --status    # Show active system

set -euo pipefail

SYSTEMS_DIR="$HOME/systems"
CLAUDE_DIR="$HOME/.claude"

# ── Config items that get symlinked ──────────────────────────────
# These are directories/files that a system provides.
# Everything else in ~/.claude/ is runtime data and stays untouched.
LINK_DIRS=(skills commands rules hooks agents stacks templates brain adr)
LINK_FILES=(LIBRARY.md)

# ── Status check ─────────────────────────────────────────────────
if [ "${1:-}" = "--status" ]; then
  echo "System config in ~/.claude:"
  for dir in "${LINK_DIRS[@]}"; do
    target="$CLAUDE_DIR/$dir"
    if [ -L "$target" ]; then
      resolved=$(readlink "$target")
      echo "  $dir/ → $resolved"
    elif [ -d "$target" ]; then
      echo "  $dir/ (local copy, not linked)"
    else
      echo "  $dir/ (not present)"
    fi
  done
  # Check settings.json source
  if [ -f "$CLAUDE_DIR/.active-system" ]; then
    echo ""
    echo "Active system: $(cat "$CLAUDE_DIR/.active-system")"
  else
    echo ""
    echo "Active system: unknown (no .active-system marker)"
  fi
  exit 0
fi

# ── Validate input ───────────────────────────────────────────────
SYSTEM="${1:-}"
if [ -z "$SYSTEM" ]; then
  echo "Usage: source ~/systems/use-system.sh <system-name>"
  echo ""
  echo "Available systems:"
  for d in "$SYSTEMS_DIR"/*/; do
    [ -d "$d" ] && echo "  $(basename "$d")"
  done
  return 1 2>/dev/null || exit 1
fi

# Handle shorthand: "mythic" → "mythic-os", "jetpack" → "jetpack-os"
if [ "$SYSTEM" = "mythic" ]; then
  SYSTEM="mythic-os"
elif [ "$SYSTEM" = "jetpack" ]; then
  SYSTEM="jetpack-os"
fi

TARGET="$SYSTEMS_DIR/$SYSTEM"
if [ ! -d "$TARGET" ]; then
  echo "System not found: $TARGET"
  echo ""
  echo "Available systems:"
  for d in "$SYSTEMS_DIR"/*/; do
    [ -d "$d" ] && echo "  $(basename "$d")"
  done
  return 1 2>/dev/null || exit 1
fi

# ── Ensure ~/.claude exists ──────────────────────────────────────
mkdir -p "$CLAUDE_DIR"

# ── Save user preferences if not yet preserved ──────────────────
if [ ! -f "$CLAUDE_DIR/settings.user.json" ]; then
  if [ -f "$CLAUDE_DIR/settings.json" ] && [ ! -L "$CLAUDE_DIR/settings.json" ]; then
    cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.user.json"
    echo "  Preserved user settings → settings.user.json"
  fi
fi

# ── Remove old symlinks ─────────────────────────────────────────
for dir in "${LINK_DIRS[@]}"; do
  target="$CLAUDE_DIR/$dir"
  if [ -L "$target" ]; then
    rm "$target"
  fi
done
for file in "${LINK_FILES[@]}"; do
  target="$CLAUDE_DIR/$file"
  if [ -L "$target" ]; then
    rm "$target"
  fi
done

# ── Create new symlinks ─────────────────────────────────────────
echo "Activating system: $SYSTEM"
echo ""

for dir in "${LINK_DIRS[@]}"; do
  src="$TARGET/$dir"
  dst="$CLAUDE_DIR/$dir"
  if [ -d "$src" ]; then
    # If there's a real directory (not symlink) from a previous install, back it up
    if [ -d "$dst" ] && [ ! -L "$dst" ]; then
      backup="$CLAUDE_DIR/${dir}.backup.$(date +%Y%m%d%H%M%S)"
      mv "$dst" "$backup"
      echo "  Backed up existing $dir/ → $(basename "$backup")"
    fi
    ln -s "$src" "$dst"
    echo "  $dir/ → $src"
  fi
done

for file in "${LINK_FILES[@]}"; do
  src="$TARGET/$file"
  dst="$CLAUDE_DIR/$file"
  if [ -f "$src" ]; then
    if [ -f "$dst" ] && [ ! -L "$dst" ]; then
      backup="$CLAUDE_DIR/${file}.backup.$(date +%Y%m%d%H%M%S)"
      mv "$dst" "$backup"
      echo "  Backed up existing $file → $(basename "$backup")"
    fi
    ln -s "$src" "$dst"
    echo "  $file → $src"
  fi
done

# ── Merge settings.json ─────────────────────────────────────────
# Combines user preferences (effortLevel, enabledPlugins) with system
# config (permissions, hooks). System config wins on conflict.
USER_SETTINGS="$CLAUDE_DIR/settings.user.json"
SYSTEM_SETTINGS="$TARGET/settings.json"
MERGED_SETTINGS="$CLAUDE_DIR/settings.json"

if [ -f "$SYSTEM_SETTINGS" ]; then
  if [ -f "$USER_SETTINGS" ]; then
    # Deep merge: user prefs as base, system config overlaid
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
echo "$SYSTEM" > "$CLAUDE_DIR/.active-system"

echo ""
echo "Active system: $SYSTEM"
echo "  System source: $TARGET"
echo "  User claude.md: preserved"
echo "  Runtime data: untouched"
echo ""
echo "Start a new Claude Code session to pick up the changes."
