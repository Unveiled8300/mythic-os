# Multi-System Claude Code Setup — Walkthrough

## Directory Structure

```
~/systems/                          # System repos (source of truth)
  mythic-os/                        # Full governance: 13 roles, 30+ skills, enforcement hooks
  use-system.sh                     # Switcher script (installed by mythic-install.sh)

~/projects/                         # All project workspaces
  mythic/                           # Projects governed by Mythic OS
    CLAUDE.md                       # Walk-up: tells Claude "you're under Mythic OS"
    my-saas-app/
    my-dashboard/

~/.claude/                          # Claude Code runtime directory (real directory, not a symlink)
  claude.md                         # Your personal global instructions (never touched by switcher)
  settings.json                     # Merged: your prefs + active system's hooks
  settings.user.json                # Your prefs only (preserved backup)
  .active-system                    # Which system is currently active
  skills/ → ~/systems/mythic-os/skills/
  commands/ → ~/systems/mythic-os/commands/
  rules/ → ~/systems/mythic-os/rules/
  hooks/ → ~/systems/mythic-os/hooks/
  agents/ → ~/systems/mythic-os/agents/
  stacks/ → ~/systems/mythic-os/stacks/
  templates/ → ~/systems/mythic-os/templates/
  brain/ → ~/systems/mythic-os/brain/
  adr/ → ~/systems/mythic-os/adr/
  LIBRARY.md → ~/systems/mythic-os/LIBRARY.md
  # Runtime data (sessions, history, plans, etc.) stays here permanently
```

## How It Works

### The switcher

```bash
source ~/systems/use-system.sh mythic       # Activate Mythic OS
source ~/systems/use-system.sh --status     # Show what's active
```

The switcher does three things:
1. **Symlinks config directories** — removes old symlinks in `~/.claude/`, creates new ones pointing to the target system
2. **Merges settings.json** — combines your personal prefs (`settings.user.json`) with the system's hooks and permissions
3. **Writes `.active-system`** — marker file so you (and scripts) can check what's active

It never touches your personal `claude.md` or any runtime data (sessions, history, plans).

### How Claude Code loads config

| What | Where it loads from | Mechanism |
|------|-------------------|-----------|
| Global CLAUDE.md | `~/.claude/CLAUDE.md` (or `claude.md`) | Always loaded |
| Project CLAUDE.md | Every parent dir from CWD upward | Walk-up (all found files merge) |
| Skills | `~/.claude/skills/` + project `.claude/skills/` | Direct lookup |
| Settings/hooks | `~/.claude/settings.json` + project `.claude/settings.json` | Merged by scope |
| Commands | `~/.claude/commands/` + project `.claude/commands/` | Direct lookup |

**Walk-up example:** When you open Claude Code in `~/projects/mythic/my-app/`:
```
~/projects/mythic/my-app/CLAUDE.md   <- project-specific (if exists)
~/projects/mythic/CLAUDE.md          <- "you're under Mythic OS"
~/.claude/claude.md                  <- your personal instructions (always)
```

All found files concatenate into context. Most specific (deepest) loads last.

### Why the paths in mythic files say `~/.claude/`

Mythic's skills, rules, and hooks reference paths like `~/.claude/rules/lead-developer.md`. These are **runtime paths** — they describe where Claude Code finds files when it's running. Because `~/.claude/rules/` is a symlink to `~/systems/mythic-os/rules/`, the path resolves correctly.

This also means the repo works for users who install via `mythic-install.sh --apply --copy` (copies files directly into `~/.claude/`). No path changes needed.

---

## Workflows

### Start a new project

```bash
# 1. Make sure mythic is active
source ~/systems/use-system.sh --status

# 2. Create the project directory
mkdir ~/projects/mythic/my-new-app
cd ~/projects/mythic/my-new-app

# 3. Open Claude Code
claude

# 4. Inside Claude Code:
/boot
/cto "build a task tracker with auth"
```

Claude will load your personal `claude.md` + the `~/projects/mythic/CLAUDE.md` walk-up + all mythic skills/hooks via symlinks.

### Quick edit without full ceremony

Two options depending on how light you want it:

**Option A: Stay on mythic, skip the ceremony.**
Open the project and just talk to Claude directly. The enforcement hooks (secret scanning, destructive command blocking) still fire — that's good. But don't invoke `/boot` or team skills. Just say "fix the bug on line 42."

**Option B: Use the `--copy` install (no hooks at all).**
If you installed with `--copy`, you have the skills but no enforcement hooks unless you manually loaded them.

### Switch systems mid-session

You can't hot-swap within a running Claude Code session — skills and hooks are loaded at session start. To switch:

1. End the current session (type `/exit` or Ctrl+C)
2. Run the switcher: `source ~/systems/use-system.sh [target]`
3. Start a new session: `claude`

### Work on the mythic-os repo itself

```bash
cd ~/systems/mythic-os
claude
```

Since `~/systems/mythic-os/CLAUDE.md` exists, Claude loads the mythic constitution from the project directory (walk-up). The symlinked skills/hooks also point here. Edits you make are directly in the source of truth.

### Add per-project overrides

Any project can layer its own config on top of the active system:

```
~/projects/mythic/my-app/
  CLAUDE.md                    # Project-specific instructions (merged with mythic)
  .claude/
    settings.json              # Project-specific hooks (merged with mythic)
    settings.local.json        # Personal overrides (gitignored)
    skills/                    # Project-specific skills
```

Project-level settings merge with (and can override) the system-level settings.

### Check what system is active

```bash
source ~/systems/use-system.sh --status
```

Or check the marker file:
```bash
cat ~/.claude/.active-system
```

---

## Troubleshooting

**Skills aren't loading:**
Check the symlinks exist: `source ~/systems/use-system.sh --status`. If broken, re-run the switcher.

**Hooks aren't firing:**
Check `~/.claude/settings.json` has the hooks section. The switcher merges your user prefs with the system hooks — if the merge failed, re-run the switcher.

**"File not found" errors in Claude:**
Most mythic paths reference `~/.claude/`. Verify the symlinks resolve: `ls -la ~/.claude/rules/` should show files, not a broken symlink.

**Accidentally edited files in `~/.claude/` directly:**
Since the directories are symlinks, edits in `~/.claude/skills/` actually modify `~/systems/mythic-os/skills/`. That's fine — it's the same files. Commit changes from `~/systems/mythic-os/`.

**Want to reset to a clean state:**
```bash
# Re-run the switcher — it removes and recreates all symlinks
source ~/systems/use-system.sh mythic
```

**Backed-up directories (e.g., `skills.backup.20260405220412`):**
Created by the switcher when it found real directories (not symlinks) that would be replaced. Safe to delete after verifying the symlinks work.

**jq not installed:**
The settings merge requires `jq`. Install it:
- macOS: `brew install jq`
- Debian/Ubuntu: `sudo apt-get install jq`
- Fedora/RHEL: `sudo dnf install jq`
