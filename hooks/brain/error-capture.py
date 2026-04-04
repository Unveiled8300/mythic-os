#!/usr/bin/env python3
"""
PostToolUse hook (matcher: Bash) — Automatic Error Capture.

When a build/test/lint command fails (non-zero exit), injects an
instruction to write an error record to brain/log/errors/.
This automates the learning capture that previously required manual invocation.

Exit 0 always (advisory, never blocks).
"""

import json
import re
import sys

# Commands that indicate a build/test/lint failure worth capturing
BUILD_TEST_PATTERNS = [
    r"\bnpm\s+(run\s+)?(build|test|lint|typecheck|check)",
    r"\bnpx\s+(vitest|jest|playwright|eslint|tsc|next\s+build)",
    r"\bpnpm\s+(run\s+)?(build|test|lint|typecheck|check)",
    r"\byarn\s+(run\s+)?(build|test|lint|typecheck|check)",
    r"\bpytest\b",
    r"\bpython3?\s+-m\s+(pytest|unittest|mypy|ruff|flake8|black)",
    r"\bruff\s+(check|format)",
    r"\bmypy\b",
    r"\bcargo\s+(build|test|check|clippy)",
    r"\bgo\s+(build|test|vet)",
    r"\bmake\s+(build|test|lint|check)",
]

# Commands to IGNORE (exploratory, not build failures)
IGNORE_PATTERNS = [
    r"^(ls|cat|head|tail|wc|find|grep|rg|echo|pwd|cd|which|type)\b",
    r"^git\s+(status|log|diff|branch|remote|show|blame)",
    r"^gh\s+",
    r"^mkdir\b",
    r"^touch\b",
    r"^rm\b",
    r"^mv\b",
    r"^cp\b",
]


def is_build_test_command(command):
    """Check if this is a build/test/lint command worth capturing on failure."""
    for pattern in IGNORE_PATTERNS:
        if re.search(pattern, command.strip(), re.IGNORECASE):
            return False

    for pattern in BUILD_TEST_PATTERNS:
        if re.search(pattern, command, re.IGNORECASE):
            return True

    return False


def main():
    try:
        input_data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, IOError):
        print("{}")
        sys.exit(0)

    tool_result = input_data.get("tool_result", {})
    tool_input = input_data.get("tool_input", {})

    command = tool_input.get("command", "")
    # Check for non-zero exit (indicated by error in result or stderr content)
    stdout = tool_result.get("stdout", "")
    stderr = tool_result.get("stderr", "")
    exit_code = tool_result.get("exit_code", 0)

    # If the command succeeded or isn't a build/test command, skip silently
    if exit_code == 0 or not command:
        print("{}")
        sys.exit(0)

    if not is_build_test_command(command):
        print("{}")
        sys.exit(0)

    # Truncate error output to avoid flooding context
    error_output = stderr or stdout
    if len(error_output) > 500:
        error_output = error_output[:500] + "... (truncated)"

    # Inject instruction to capture the error
    instruction = (
        f"A build/test/lint command failed. Before fixing, write a brief error record to "
        f"`brain/log/errors/` using this format:\n\n"
        f"```markdown\n"
        f"# Error: [brief description]\n"
        f"- **When:** [today's date] during [current task]\n"
        f"- **Command:** `{command[:100]}`\n"
        f"- **Symptom:** [what the error output shows]\n"
        f"- **Root Cause:** [fill in after fixing]\n"
        f"- **Fix:** [fill in after fixing]\n"
        f"- **Prevention:** [fill in after fixing]\n"
        f"- **Tags:** [relevant tags]\n"
        f"```\n\n"
        f"Create the file, then proceed with the fix. "
        f"Update Root Cause, Fix, and Prevention fields after resolving."
    )

    result = {"additionalContext": instruction}
    print(json.dumps(result))
    sys.exit(0)


if __name__ == "__main__":
    main()
