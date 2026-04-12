#!/usr/bin/env python3
"""
PostToolUse hook (matcher: Bash) -- Commit Cleanup.

After a successful git commit, clears the .govpass/ governance markers so
the next task starts with a clean slate. This prevents stale markers from
satisfying future commit gates.

Detection logic:
  1. Check if the bash command was a git commit.
  2. Check if the tool_result indicates success (exit code 0).
  3. Find the governed project root.
  4. Clear all marker files in .govpass/.

Exit 0 always (PostToolUse — advisory only, never blocks).
"""

import json
import os
import re
import sys


IGNORE_ROOTS = {
    os.path.expanduser("~/.claude"),
}


def find_project_root(cwd):
    """Walk up from cwd looking for SPEC.md."""
    directory = os.path.abspath(cwd) if cwd else os.getcwd()
    for _ in range(10):
        if not directory or directory == os.path.dirname(directory):
            return None
        if directory in IGNORE_ROOTS:
            return None
        if os.path.isfile(os.path.join(directory, "SPEC.md")):
            return directory
        directory = os.path.dirname(directory)
    return None


def is_successful_commit(input_data):
    """Check if this was a successful git commit."""
    tool_input = input_data.get("tool_input", {})
    command = tool_input.get("command", "")

    if not re.search(r"\bgit\s+commit\b", command):
        return False

    # PostToolUse provides tool_result with exit code
    tool_result = input_data.get("tool_result", {})
    # Exit code 0 means success
    exit_code = tool_result.get("exit_code", tool_result.get("exitCode", -1))
    # If exit code is available and non-zero, commit failed
    if exit_code != 0 and exit_code != -1:
        return False

    # If stdout contains commit hash pattern, it succeeded
    stdout = tool_result.get("stdout", "")
    if re.search(r"\[[\w/.-]+ [a-f0-9]+\]", stdout):
        return True

    # If we can't determine — assume success if it was a commit command
    # (better to clear markers on false positive than to leave stale ones)
    return True


def clear_govpass(project_root):
    """Clear all governance markers."""
    govpass_dir = os.path.join(project_root, ".govpass")
    if not os.path.isdir(govpass_dir):
        return 0

    cleared = 0
    for filename in os.listdir(govpass_dir):
        if filename.endswith(".json"):
            try:
                os.remove(os.path.join(govpass_dir, filename))
                cleared += 1
            except OSError:
                pass
    return cleared


def main():
    try:
        input_data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, IOError):
        sys.exit(0)

    if not is_successful_commit(input_data):
        sys.exit(0)

    cwd = input_data.get("cwd", os.getcwd())
    project_root = find_project_root(cwd)

    if project_root is None:
        sys.exit(0)

    cleared = clear_govpass(project_root)

    if cleared > 0:
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": (
                    f"Governance markers cleared ({cleared} markers). "
                    f"Next commit will require fresh /review, /sweep, "
                    f"/qa-verify, and eval passes."
                ),
            }
        }
        json.dump(output, sys.stdout)

    sys.exit(0)


if __name__ == "__main__":
    main()
