#!/usr/bin/env python3
"""
PreToolUse hook (matcher: Edit|Write|MultiEdit) — README.md Gate.

Blocks file writes inside governed projects (those with SPEC.md) that are
missing a README.md. This enforces Lead Developer SOP 5 at the harness level.

Detection logic:
  1. Extract the file path from the tool input.
  2. Walk up from the file's directory looking for SPEC.md (project root marker).
  3. If SPEC.md is found, check whether README.md exists in that same directory.
  4. If README.md is missing, block the write.

Scoping: Only fires on governed projects (SPEC.md present). Writing to
mythic-cc itself, personal configs, or non-project directories is unaffected.

Exit 0 = allow (silent). Exit 2 = block with stderr message.
"""

import json
import os
import sys


# Directories that should never be treated as project roots, even if they
# contain a SPEC.md (e.g., the governance repo itself, templates, fixtures).
IGNORE_ROOTS = {
    os.path.expanduser("~/.claude"),
}

# Files that are allowed to be written even when README.md is missing —
# because they ARE the README or are part of initial project scaffolding.
EXEMPT_FILENAMES = {
    "README.md",
    "readme.md",
    "SPEC.md",
    "SPRINT.md",
    "CLAUDE.md",
    ".gitignore",
    ".env.example",
    "package.json",
    "pyproject.toml",
    "go.mod",
    "Cargo.toml",
    "config.yaml",
}


def find_project_root(file_path):
    """Walk up from file_path looking for a directory containing SPEC.md."""
    directory = os.path.dirname(os.path.abspath(file_path))

    # Walk up at most 10 levels to avoid scanning to /
    for _ in range(10):
        if not directory or directory == os.path.dirname(directory):
            return None

        # Skip ignored roots
        if directory in IGNORE_ROOTS:
            return None

        if os.path.isfile(os.path.join(directory, "SPEC.md")):
            return directory

        directory = os.path.dirname(directory)

    return None


def main():
    try:
        input_data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, IOError):
        sys.exit(0)

    tool_input = input_data.get("tool_input", {})
    file_path = tool_input.get("file_path", "")

    if not file_path:
        sys.exit(0)

    # Allow writes to README.md itself and scaffolding files
    basename = os.path.basename(file_path)
    if basename in EXEMPT_FILENAMES:
        sys.exit(0)

    # Find the governed project root
    project_root = find_project_root(file_path)
    if project_root is None:
        # Not inside a governed project — allow
        sys.exit(0)

    # Check if README.md exists
    readme_path = os.path.join(project_root, "README.md")
    if os.path.isfile(readme_path):
        # README exists — allow
        sys.exit(0)

    # Also check lowercase variant
    readme_lower = os.path.join(project_root, "readme.md")
    if os.path.isfile(readme_lower):
        sys.exit(0)

    # README.md is missing in a governed project — block
    sys.stderr.write(
        f"\n  BLOCKED: README.md missing in governed project\n"
        f"  Project root: {project_root}\n"
        f"  Detected via: {project_root}/SPEC.md\n"
        f"  Create README.md (per Lead Developer SOP 5) before writing "
        f"implementation files.\n"
    )
    sys.exit(2)


if __name__ == "__main__":
    main()
