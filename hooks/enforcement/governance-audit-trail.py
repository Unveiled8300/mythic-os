#!/usr/bin/env python3
"""
PostToolUse hook (matcher: Write|Edit|MultiEdit) -- Governance Audit Trail.

Advisory hook that checks whether newly created or modified governance
resources have been logged in LIBRARY.md. If not, injects a reminder
to run Storyteller: ON CREATE.

This enforces Storyteller SOP 1 by surfacing the gap — it does not block.

Detection logic:
  1. Check if the modified file is a governance resource (rules/, skills/, adr/).
  2. Check if the file is already tracked in LIBRARY.md.
  3. If not tracked, inject additionalContext reminder.

Exit 0 always (advisory only).
"""

import json
import os
import re
import sys


GOVERNANCE_DIRS = [
    "rules/",
    "skills/",
    "adr/",
    "error-records/",
    "hooks/enforcement/",
    "hooks/brain/",
    "hooks/context-loader/",
]

LIBRARY_PATH = os.path.expanduser("~/.claude/LIBRARY.md")


def is_governance_file(file_path):
    """Check if the file is inside a governance directory."""
    for gov_dir in GOVERNANCE_DIRS:
        if gov_dir in file_path:
            return True
    return False


def is_tracked_in_library(file_path):
    """Check if the file path appears in LIBRARY.md."""
    if not os.path.isfile(LIBRARY_PATH):
        return False

    try:
        with open(LIBRARY_PATH, "r", encoding="utf-8") as f:
            content = f.read()

        # Extract the relative path portion that would appear in LIBRARY.md
        basename = os.path.basename(file_path)
        # Check for the filename or a relative path segment
        return basename in content
    except (IOError, OSError):
        return True  # Cannot check — assume tracked


def main():
    try:
        input_data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, IOError):
        sys.exit(0)

    tool_input = input_data.get("tool_input", {})
    file_path = tool_input.get("file_path", "")

    if not file_path:
        sys.exit(0)

    if not is_governance_file(file_path):
        sys.exit(0)

    if is_tracked_in_library(file_path):
        sys.exit(0)

    # File is governance resource but not tracked in LIBRARY.md
    basename = os.path.basename(file_path)
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PostToolUse",
            "additionalContext": (
                f"STORYTELLER REMINDER: Governance resource '{basename}' was "
                f"modified but is not tracked in LIBRARY.md. "
                f"Run: Storyteller: ON CREATE — {basename} (or ON UPDATE if it "
                f"already exists). This prevents context rot."
            ),
        }
    }
    json.dump(output, sys.stdout)
    sys.exit(0)


if __name__ == "__main__":
    main()
