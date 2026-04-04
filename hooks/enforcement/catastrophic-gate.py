#!/usr/bin/env python3
"""
PreToolUse hook (matcher: Bash) — Catastrophic Action Prevention.

Mechanically blocks destructive commands that are irreversible.
Replaces the instructional SOP 4 in CLAUDE.md with a hard gate.

Exit 0 = allow (silent). Exit 2 = block with stderr message.
"""

import json
import re
import sys


BLOCKED_PATTERNS = [
    # rm -rf on system/project parent directories
    (r"rm\s+(-[a-zA-Z]*f[a-zA-Z]*\s+.*)?(/|~|\$HOME|\.\.)\b",
     "rm -rf on system/parent directory — irreversible destruction"),

    # git reset --hard (without preceding git stash or status in same chain)
    (r"git\s+reset\s+--hard",
     "git reset --hard — irreversible commit loss. Use 'git stash' first."),

    # git push --force to main/master
    (r"git\s+push\s+.*--force.*\b(main|master)\b",
     "git push --force to main/master — overwrites shared history"),
    (r"git\s+push\s+.*\b(main|master)\b.*--force",
     "git push --force to main/master — overwrites shared history"),

    # DROP TABLE / DROP DATABASE without backup context
    (r"DROP\s+(TABLE|DATABASE)\b",
     "DROP TABLE/DATABASE — irreversible data loss"),

    # mkfs on any device
    (r"mkfs\b",
     "mkfs — formats a filesystem, irreversible"),

    # dd writing to a device
    (r"dd\s+.*of=/dev/",
     "dd writing to device — irreversible"),

    # chmod 777 recursively (security risk)
    (r"chmod\s+(-R\s+)?777\s+/",
     "chmod 777 on root paths — severe security risk"),

    # Pipe curl to shell
    (r"curl\s+.*\|\s*(ba)?sh",
     "Piping curl to shell — untrusted code execution"),
]


def main():
    try:
        input_data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, IOError):
        sys.exit(0)

    command = input_data.get("tool_input", {}).get("command", "")
    if not command:
        sys.exit(0)

    for pattern, reason in BLOCKED_PATTERNS:
        if re.search(pattern, command, re.IGNORECASE):
            sys.stderr.write(
                f"\n  BLOCKED: {reason}\n"
                f"  Command: {command[:120]}\n"
                f"  This is a catastrophic action. Run it manually outside Claude Code "
                f"if you're certain.\n"
            )
            sys.exit(2)

    # Silent pass
    sys.exit(0)


if __name__ == "__main__":
    main()
