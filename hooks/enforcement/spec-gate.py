#!/usr/bin/env python3
"""
PreToolUse hook (matcher: Edit|Write|MultiEdit) -- SPEC.md Approval Gate.

Blocks writes to implementation files inside governed projects when SPEC.md
exists but has not been approved (Status: approved). This enforces Product
Architect SOP 4 at the harness level: no implementation begins before the
Founder signs off on the Definition of Done.

Detection logic:
  1. Extract file path from tool input.
  2. Skip if the file is exempt (config, docs, governance, test files).
  3. Walk up from the file's directory looking for SPEC.md (governed project).
  4. Read the first 5 lines of SPEC.md, looking for Status: approved.
  5. If SPEC.md exists but status is not approved: BLOCK.
  6. If SPEC.md has Status: approved: ALLOW.

Bypass: Create a .spec-skip file in the project root.

Exit 0 = allow (silent). Exit 2 = block with stderr message.
"""

import json
import os
import re
import sys


# Directories that are never project roots
IGNORE_ROOTS = {
    os.path.expanduser("~/.claude"),
}

# Files that are always allowed — governance scaffolding, config, tests, docs
EXEMPT_FILENAMES = {
    "CLAUDE.md", "SPEC.md", "SPRINT.md", "HANDOFF.md", "README.md",
    "LIBRARY.md", "LIBRARY-HISTORY.md", "DEPLOY.md", "API.md",
    "MARKETING.md", "CODEBASE.md",
    ".gitignore", ".env.example", ".eslintrc", ".prettierrc",
    "package.json", "package-lock.json", "tsconfig.json",
    "pyproject.toml", "setup.py", "setup.cfg",
    "Cargo.toml", "Cargo.lock", "go.mod", "go.sum",
    "Dockerfile", "docker-compose.yml", "docker-compose.yaml",
    "Makefile", "Procfile", "Gemfile",
    "drizzle.config.ts", "next.config.ts", "next.config.js",
    "postcss.config.mjs", "tailwind.config.ts", "tailwind.config.js",
    "vite.config.ts", "vitest.config.ts", "playwright.config.ts",
    "components.json", "config.yaml",
    ".tdd-skip", ".tdd-lock", ".tdd-audit.jsonl",
    ".spec-skip", ".sprint-skip", ".branch-skip", ".api-doc-skip",
}

EXEMPT_EXTENSIONS = {
    ".md", ".json", ".yaml", ".yml", ".toml", ".cfg", ".ini", ".conf",
    ".lock", ".gitignore", ".txt", ".csv", ".svg", ".png",
    ".jpg", ".jpeg", ".gif", ".ico", ".xml", ".html", ".css",
    ".sh", ".bash", ".sql",
}

EXEMPT_DIR_PATTERNS = [
    r"(^|/)\.github/",
    r"(^|/)\.vscode/",
    r"(^|/)\.idea/",
    r"(^|/)node_modules/",
    r"(^|/)\.next/",
    r"(^|/)dist/",
    r"(^|/)build/",
    r"(^|/)migrations/",
    r"(^|/)prisma/",
    r"(^|/)\.phase-",
    r"(^|/)\.forge/",
]

TEST_FILE_PATTERNS = [
    r"\.test\.[^.]+$",
    r"\.spec\.[^.]+$",
    r"(^|/)test_[^/]+$",
    r"_test\.[^.]+$",
    r"(^|/)__tests__/",
    r"(^|/)tests/",
]


def is_exempt(file_path):
    """Return True if this file should never be gated."""
    basename = os.path.basename(file_path)

    if basename in EXEMPT_FILENAMES:
        return True

    _, ext = os.path.splitext(basename)
    if ext.lower() in EXEMPT_EXTENSIONS:
        return True

    for pattern in EXEMPT_DIR_PATTERNS:
        if re.search(pattern, file_path):
            return True

    for pattern in TEST_FILE_PATTERNS:
        if re.search(pattern, file_path):
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


def spec_is_approved(project_root):
    """Read SPEC.md and check if status line contains 'approved'."""
    spec_path = os.path.join(project_root, "SPEC.md")
    try:
        with open(spec_path, "r", encoding="utf-8") as f:
            # Status is typically in the first 5 lines (header block)
            for i, line in enumerate(f):
                if i >= 10:
                    break
                if re.search(r"Status:\s*.*approved", line, re.IGNORECASE):
                    return True
        return False
    except (IOError, OSError):
        # Cannot read SPEC.md — allow to avoid false blocks
        return True


def main():
    try:
        input_data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, IOError):
        sys.exit(0)

    tool_input = input_data.get("tool_input", {})
    file_path = tool_input.get("file_path", "")

    if not file_path:
        sys.exit(0)

    # Fast path: exempt files are never blocked
    if is_exempt(file_path):
        sys.exit(0)

    # Find governed project root
    project_root = find_project_root(file_path)
    if project_root is None:
        sys.exit(0)

    # Check for bypass
    if os.path.isfile(os.path.join(project_root, ".spec-skip")):
        sys.exit(0)

    # Check SPEC.md approval status
    if not spec_is_approved(project_root):
        sys.stderr.write(
            f"\n  SPEC GATE: SPEC.md has not been approved.\n"
            f"  Update SPEC.md status to 'approved' before writing implementation files.\n"
            f"  Current file: {file_path}\n"
            f"  Project root: {project_root}\n"
            f"  Or create .spec-skip in {project_root} to bypass.\n"
        )
        sys.exit(2)

    sys.exit(0)


if __name__ == "__main__":
    main()
