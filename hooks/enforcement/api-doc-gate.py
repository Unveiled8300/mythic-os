#!/usr/bin/env python3
"""
PreToolUse hook (matcher: Edit|Write|MultiEdit) -- API Documentation Gate.

Blocks writes to API route files when API.md does not exist in the project
root. Enforces Backend Developer SOP 7: "document every endpoint before or
alongside implementation."

Detection logic:
  1. Extract file path from tool input.
  2. Check if the file is inside an API directory (*/api/*).
  3. Walk up to find the governed project root (SPEC.md marker).
  4. Check if API.md exists in the project root.
  5. If API.md is missing: BLOCK.

Bypass: Create a .api-doc-skip file in the project root.

Exit 0 = allow (silent). Exit 2 = block with stderr message.
"""

import json
import os
import re
import sys


IGNORE_ROOTS = {
    os.path.expanduser("~/.claude"),
}

# Patterns indicating the file is an API route
API_PATH_PATTERNS = [
    r"/api/",           # Next.js API routes, Express routes
    r"/routes/api/",    # Alternative route structure
]

# Files that are always allowed even inside API directories
EXEMPT_FILENAMES = {
    "API.md", "api.md", "README.md",
    ".gitignore", ".api-doc-skip",
}

EXEMPT_EXTENSIONS = {
    ".md", ".json", ".yaml", ".yml", ".txt", ".css", ".html",
}


def is_api_file(file_path):
    """Return True if the file is inside an API directory."""
    for pattern in API_PATH_PATTERNS:
        if re.search(pattern, file_path):
            return True
    return False


def is_exempt(file_path):
    """Return True if this file is exempt from API doc gating."""
    basename = os.path.basename(file_path)
    if basename in EXEMPT_FILENAMES:
        return True
    _, ext = os.path.splitext(basename)
    if ext.lower() in EXEMPT_EXTENSIONS:
        return True
    return False


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


def main():
    try:
        input_data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, IOError):
        sys.exit(0)

    tool_input = input_data.get("tool_input", {})
    file_path = tool_input.get("file_path", "")

    if not file_path:
        sys.exit(0)

    # Only gate files in API directories
    if not is_api_file(file_path):
        sys.exit(0)

    # Exempt files (API.md itself, markdown, etc.)
    if is_exempt(file_path):
        sys.exit(0)

    # Find governed project root
    project_root = find_project_root(file_path)
    if project_root is None:
        sys.exit(0)

    # Check for bypass
    if os.path.isfile(os.path.join(project_root, ".api-doc-skip")):
        sys.exit(0)

    # Check if API.md exists
    api_md_path = os.path.join(project_root, "API.md")
    docs_api_md = os.path.join(project_root, "docs", "api.md")

    if not os.path.isfile(api_md_path) and not os.path.isfile(docs_api_md):
        sys.stderr.write(
            f"\n  API DOC GATE: API.md not found in project root.\n"
            f"  Create API.md before writing API route files.\n"
            f"  See Backend Developer SOP 7 for the required format.\n"
            f"  Current file: {file_path}\n"
            f"  Expected location: {api_md_path}\n"
            f"  Or create .api-doc-skip in {project_root} to bypass.\n"
        )
        sys.exit(2)

    sys.exit(0)


if __name__ == "__main__":
    main()
