#!/usr/bin/env python3
"""
PostToolUse hook (matcher: Write|Edit|MultiEdit) -- TDD Audit Trail Logger.

After every file write, appends a line to .tdd-audit.jsonl in the governed
project root. This provides:
  - Forensic evidence of write ordering (QA can verify TDD was followed)
  - Data for tdd-gate.sh verify-audit to use instead of git log
  - Input for /reflect to detect TDD compliance patterns across sessions

Log format (one JSON object per line):
  {"timestamp": "ISO8601", "file": "path", "type": "test|impl|config|doc",
   "action": "create|modify", "tool": "Edit|Write|MultiEdit"}

The audit log auto-rotates at 1000 lines (truncates oldest entries).

Only logs in governed projects (those with SPEC.md).

Exit 0 always. Output JSON with additionalContext only on errors.
"""

import json
import os
import re
import sys
from datetime import datetime, timezone


MAX_AUDIT_LINES = 1000
AUDIT_FILENAME = ".tdd-audit.jsonl"

# Directories that are never project roots
IGNORE_ROOTS = {
    os.path.expanduser("~/.claude"),
}

# --- File classification ---

TEST_FILE_PATTERNS = [
    r"\.test\.[^.]+$",
    r"\.spec\.[^.]+$",
    r"(^|/)test_[^/]+$",
    r"_test\.[^.]+$",
    r"(^|/)__tests__/",
    r"(^|/)tests/",
]

CONFIG_DOC_EXTENSIONS = {
    ".md", ".json", ".yaml", ".yml", ".toml", ".cfg", ".ini", ".conf",
    ".lock", ".gitignore", ".txt", ".csv", ".xml", ".html", ".css",
    ".sh", ".bash",
}

DOC_FILENAMES = {
    "CLAUDE.md", "SPEC.md", "SPRINT.md", "HANDOFF.md", "README.md",
    "LIBRARY.md", "LIBRARY-HISTORY.md", "DEPLOY.md", "API.md",
    "MARKETING.md", "CODEBASE.md",
    ".gitignore", ".env.example",
    "package.json", "package-lock.json", "tsconfig.json",
    "pyproject.toml", "setup.py", "setup.cfg",
    "Cargo.toml", "Cargo.lock", "go.mod", "go.sum",
    "Dockerfile", "docker-compose.yml", "docker-compose.yaml",
    "Makefile", "Procfile", "Gemfile",
    ".tdd-lock", ".tdd-skip", ".tdd-audit.jsonl",
}


def classify_file(file_path):
    """Classify a file as test, impl, config, or doc."""
    basename = os.path.basename(file_path)

    # Check test patterns first
    for pattern in TEST_FILE_PATTERNS:
        if re.search(pattern, file_path):
            return "test"

    # Check doc/config by exact name
    if basename in DOC_FILENAMES:
        return "doc"

    # Check doc/config by extension
    _, ext = os.path.splitext(basename)
    if ext.lower() in CONFIG_DOC_EXTENSIONS:
        return "config"

    # Everything else is impl
    return "impl"


def determine_action(file_path):
    """Determine if this is a create or modify action."""
    if os.path.isfile(file_path):
        return "modify"
    return "create"


def determine_tool(input_data):
    """Determine which tool was used from the input structure."""
    tool_input = input_data.get("tool_input", {})
    if "content" in tool_input:
        return "Write"
    if "edits" in tool_input:
        return "MultiEdit"
    return "Edit"


def find_project_root(file_path):
    """Walk up from file_path looking for a directory containing SPEC.md."""
    directory = os.path.dirname(os.path.abspath(file_path))

    for _ in range(10):
        if not directory or directory == os.path.dirname(directory):
            return None

        if directory in IGNORE_ROOTS:
            return None

        if os.path.isfile(os.path.join(directory, "SPEC.md")):
            return directory

        directory = os.path.dirname(directory)

    return None


def rotate_audit_log(audit_path):
    """Rotate the audit log if it exceeds MAX_AUDIT_LINES.

    Keeps the most recent MAX_AUDIT_LINES * 3/4 lines to avoid rotating
    on every single write once at the limit.
    """
    try:
        with open(audit_path, "r") as f:
            lines = f.readlines()

        if len(lines) <= MAX_AUDIT_LINES:
            return

        # Keep the most recent 75% of max
        keep_count = int(MAX_AUDIT_LINES * 3 / 4)
        with open(audit_path, "w") as f:
            f.writelines(lines[-keep_count:])
    except (IOError, OSError):
        pass


def append_audit_entry(audit_path, entry):
    """Append a single JSON line to the audit log."""
    try:
        with open(audit_path, "a") as f:
            f.write(json.dumps(entry, separators=(",", ":")) + "\n")
    except (IOError, OSError):
        pass


def main():
    try:
        input_data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, IOError):
        print("{}")
        sys.exit(0)

    tool_input = input_data.get("tool_input", {})
    file_path = tool_input.get("file_path", "")

    if not file_path:
        print("{}")
        sys.exit(0)

    # Find governed project root
    project_root = find_project_root(file_path)
    if project_root is None:
        # Not in a governed project -- no audit needed
        print("{}")
        sys.exit(0)

    # Build the audit entry
    file_type = classify_file(file_path)
    action = determine_action(file_path)
    tool = determine_tool(input_data)

    # Use relative path from project root for readability
    abs_file = os.path.abspath(file_path)
    try:
        rel_path = os.path.relpath(abs_file, project_root)
    except ValueError:
        rel_path = abs_file

    entry = {
        "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "file": rel_path,
        "type": file_type,
        "action": action,
        "tool": tool,
    }

    audit_path = os.path.join(project_root, AUDIT_FILENAME)

    # Rotate if needed, then append
    rotate_audit_log(audit_path)
    append_audit_entry(audit_path, entry)

    # PostToolUse always exits 0 -- output empty JSON
    print("{}")
    sys.exit(0)


if __name__ == "__main__":
    main()
