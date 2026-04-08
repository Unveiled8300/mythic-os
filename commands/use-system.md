---
allowed-tools: Bash(source ~/systems/use-system.sh*)
description: "Switch this project's Claude Code system. Use when user says 'use mythic', 'use jetpack', 'use greenfield', 'switch to mythic', 'switch system', or 'change system'."
---

## Your task

Install a Claude Code system into the current project's `.claude/` directory.

The user said: $ARGUMENTS

Map the user's request to a system name:
- "mythic" → mythic
- "jetpack" → jetpack
- "greenfield" or "green field" or "bare" or "clean" → greenfield

Run the install command:
```bash
source ~/systems/use-system.sh <system-name> --project .
```

After the command completes, tell the user:
1. Which system was installed
2. They need to **start a new Claude Code session** for the changes to take effect (skills, hooks, and rules load at session start)

Do not run any other tools. Do not take any other actions.
