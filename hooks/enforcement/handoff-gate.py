#!/usr/bin/env python3
"""
PreToolUse hook (matcher: Bash) -- Handoff Note Gate.

Blocks QA Tester invocation when no Handoff Note exists in SPRINT.md for the
referenced task. Enforces Lead Developer SOP 3: the Lead Developer must write
a Handoff Note before QA is notified.

Detection logic:
  1. Check if the bash command matches QA invocation patterns.
  2. Extract the task ID (T-NN) from the command.
  3. Read SPRINT.md and check for a Handoff Note section for that task.
  4. If no Handoff Note found: BLOCK.

This also intercepts the /qa-verify skill invocation pattern.

Exit 0 = allow (silent). Exit 2 = block with stderr message.
"""

import json
import os
import re
import sys


IGNORE_ROOTS = {
    os.path.expanduser("~/.claude"),
}

# Patterns that indicate QA invocation
QA_PATTERNS = [
    r"QA\s*Tester:\s*VERIFY",
    r"QA\s*Tester:\s*RE-VERIFY",
    r"qa-verify",
    r"qa.*verify",
]

# Pattern to extract task ID
TASK_ID_RE = re.compile(r"\b(T-\d+)\b")

# Pattern to find Handoff Note in SPRINT.md
HANDOFF_NOTE_RE = re.compile(
    r"####?\s*Handoff\s+Note\s*.*?(T-\d+)",
    re.IGNORECASE,
)


def find_project_root(cwd):
    """Walk up from cwd looking for SPEC.md."""
    directory = os.path.abspath(cwd)
    for _ in range(10):
        if not directory or directory == os.path.dirname(directory):
            return None
        if directory in IGNORE_ROOTS:
            return None
        if os.path.isfile(os.path.join(directory, "SPEC.md")):
            return directory
        directory = os.path.dirname(directory)
    return None


def is_qa_invocation(command):
    """Check if the command matches a QA invocation pattern."""
    for pattern in QA_PATTERNS:
        if re.search(pattern, command, re.IGNORECASE):
            return True
    return False


def extract_task_ids(command):
    """Extract all task IDs (T-NN) from the command."""
    return TASK_ID_RE.findall(command)


def sprint_has_handoff(project_root, task_id):
    """Check if SPRINT.md contains a Handoff Note for the given task ID."""
    sprint_path = os.path.join(project_root, "SPRINT.md")

    if not os.path.isfile(sprint_path):
        return False

    try:
        with open(sprint_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Look for Handoff Note header mentioning this task
        # Pattern: ### Handoff Note — T-01 or #### Handoff Note — T-01
        pattern = re.compile(
            rf"####?\s*Handoff\s+Note\s*[—\-]+\s*{re.escape(task_id)}",
            re.IGNORECASE,
        )
        return bool(pattern.search(content))
    except (IOError, OSError):
        # Cannot read — allow to avoid false blocks
        return True


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

    if not is_qa_invocation(command):
        sys.exit(0)

    project_root = find_project_root(cwd)
    if project_root is None:
        sys.exit(0)

    # Extract task IDs from the QA invocation
    task_ids = extract_task_ids(command)
    if not task_ids:
        # QA invoked without a specific task ID — advisory only, allow
        sys.exit(0)

    # Check each referenced task for a Handoff Note
    missing = []
    for task_id in task_ids:
        if not sprint_has_handoff(project_root, task_id):
            missing.append(task_id)

    if missing:
        missing_str = ", ".join(missing)
        sys.stderr.write(
            f"\n  HANDOFF GATE: No Handoff Note found for: {missing_str}\n"
            f"  The Lead Developer must write a Handoff Note in SPRINT.md\n"
            f"  before QA Tester verification can begin.\n"
            f"  Required format: #### Handoff Note — {missing[0]} — [date]\n"
            f"  See Lead Developer SOP 3.\n"
        )
        sys.exit(2)

    sys.exit(0)


if __name__ == "__main__":
    main()
