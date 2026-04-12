#!/usr/bin/env python3
"""
PostToolUse hook (matcher: Bash) -- Eval Pass Auto-Marker.

Detects when a test suite command runs successfully and automatically writes
the eval-pass governance marker. This is the most automatic gate — no skill
invocation needed. Tests pass = marker written.

Detection logic:
  1. Check if the bash command matches a known test runner pattern.
  2. Check if the command exited successfully (exit code 0).
  3. Find the governed project root.
  4. Write the eval-pass marker via govpass.

Supported test runners:
  - npm test, npm run test
  - npx vitest, npx vitest run
  - npx jest
  - npx playwright test
  - python -m pytest, pytest
  - go test ./...
  - cargo test

Exit 0 always (PostToolUse — advisory only, never blocks).
"""

import json
import os
import re
import sys


IGNORE_ROOTS = {
    os.path.expanduser("~/.claude"),
}

# Patterns that identify test suite commands
TEST_COMMAND_PATTERNS = [
    r"\bnpm\s+test\b",
    r"\bnpm\s+run\s+test\b",
    r"\bnpx\s+vitest\b",
    r"\bnpx\s+jest\b",
    r"\bnpx\s+playwright\s+test\b",
    r"\bpython3?\s+-m\s+pytest\b",
    r"\bpytest\b",
    r"\bgo\s+test\b",
    r"\bcargo\s+test\b",
    r"\bnpx\s+vitest\s+run\b",
]


def is_test_command(command):
    """Check if the command is running a test suite."""
    for pattern in TEST_COMMAND_PATTERNS:
        if re.search(pattern, command):
            return True
    return False


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


def was_successful(input_data):
    """Check if the command completed successfully (exit code 0)."""
    tool_result = input_data.get("tool_result", {})

    # Try multiple keys for exit code (Claude Code format varies)
    exit_code = tool_result.get("exit_code",
                tool_result.get("exitCode",
                tool_result.get("code", None)))

    if exit_code is not None:
        return int(exit_code) == 0

    # If no exit code available, check stdout for common pass indicators
    stdout = tool_result.get("stdout", "")
    if re.search(r"(?i)(all tests passed|tests?\s+passed|0 failures|0 failed)", stdout):
        return True

    # Cannot determine — don't write marker (conservative)
    return False


def main():
    try:
        input_data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, IOError):
        sys.exit(0)

    tool_input = input_data.get("tool_input", {})
    command = tool_input.get("command", "")
    cwd = input_data.get("cwd", os.getcwd())

    if not command:
        sys.exit(0)

    if not is_test_command(command):
        sys.exit(0)

    if not was_successful(input_data):
        sys.exit(0)

    project_root = find_project_root(cwd)
    if project_root is None:
        sys.exit(0)

    # Write the eval-pass marker
    hook_dir = os.path.dirname(os.path.abspath(__file__))
    if hook_dir not in sys.path:
        sys.path.insert(0, hook_dir)

    try:
        from govpass import write_marker, EVAL
        write_marker(project_root, EVAL, verdict="PASS",
                     details={"command": command[:200]})

        output = {
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": (
                    f"EVAL PASS: Test suite passed. "
                    f"eval-pass marker written to {project_root}/.govpass/"
                ),
            }
        }
        json.dump(output, sys.stdout)
    except ImportError:
        pass

    sys.exit(0)


if __name__ == "__main__":
    main()
