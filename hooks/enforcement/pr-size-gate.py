#!/usr/bin/env python3
"""
PreToolUse hook (matcher: Bash) -- PR Size Gate.

Blocks creation of pull requests that exceed 400 lines changed (excluding
lock files and generated files). Enforces git-workflow.md PR size standard.

Detection logic:
  1. Check if the bash command is creating a PR (gh pr create).
  2. Run git diff --stat to count lines changed vs base branch.
  3. Exclude lock files and generated files from the count.
  4. If total exceeds 400: BLOCK.

Exit 0 = allow (silent). Exit 2 = block with stderr message.
"""

import json
import os
import re
import subprocess
import sys


PR_SIZE_LIMIT = 400

# Files excluded from the line count
EXCLUDED_PATTERNS = [
    r"package-lock\.json$",
    r"yarn\.lock$",
    r"pnpm-lock\.yaml$",
    r"requirements\.txt$",
    r"\.generated\.",
    r"\.min\.(js|css)$",
    r"prisma/migrations/",
    r"drizzle/migrations/",
]


def is_pr_create_command(command):
    """Check if this is a gh pr create command."""
    return bool(re.search(r"\bgh\s+pr\s+create\b", command))


def get_diff_stats(cwd=None):
    """Get line additions + deletions vs main branch, excluding exempted files."""
    try:
        # Try main first, fall back to master
        for base in ["main", "master"]:
            result = subprocess.run(
                ["git", "diff", "--numstat", f"{base}...HEAD"],
                capture_output=True, text=True, timeout=10,
                cwd=cwd,
            )
            if result.returncode == 0 and result.stdout.strip():
                return parse_numstat(result.stdout)

        # If no base branch comparison works, try staged + unstaged
        result = subprocess.run(
            ["git", "diff", "--numstat", "HEAD"],
            capture_output=True, text=True, timeout=10,
            cwd=cwd,
        )
        if result.returncode == 0:
            return parse_numstat(result.stdout)

    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        pass

    return 0, 0  # Cannot determine — allow


def parse_numstat(output):
    """Parse git diff --numstat output, excluding exempted files.

    Returns (total_lines, excluded_lines).
    """
    total = 0
    excluded = 0

    for line in output.strip().split("\n"):
        if not line.strip():
            continue

        parts = line.split("\t")
        if len(parts) < 3:
            continue

        additions = parts[0]
        deletions = parts[1]
        filepath = parts[2]

        # Binary files show as "-"
        if additions == "-" or deletions == "-":
            continue

        try:
            line_count = int(additions) + int(deletions)
        except ValueError:
            continue

        is_excluded = any(
            re.search(pat, filepath) for pat in EXCLUDED_PATTERNS
        )

        if is_excluded:
            excluded += line_count
        else:
            total += line_count

    return total, excluded


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

    if not is_pr_create_command(command):
        sys.exit(0)

    counted, excluded = get_diff_stats(cwd)

    if counted > PR_SIZE_LIMIT:
        sys.stderr.write(
            f"\n  PR SIZE GATE: PR exceeds {PR_SIZE_LIMIT}-line limit.\n"
            f"  Lines changed: {counted} (+ {excluded} excluded lock/generated files)\n"
            f"  Split this PR into smaller, focused PRs.\n"
            f"  Excluded from count: lock files, .generated.*, prisma migrations\n"
        )
        sys.exit(2)

    sys.exit(0)


if __name__ == "__main__":
    main()
