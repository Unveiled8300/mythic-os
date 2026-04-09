#!/usr/bin/env python3
"""
PreToolUse hook (matcher: Edit|Write|MultiEdit) -- TDD Test-First Check.

Blocks writes to implementation files unless a corresponding test file exists
and has been modified at least as recently as the implementation file. Uses
filesystem mtime as implicit state -- the test must be written or updated
before or during the same session as the implementation.

Detection logic:
  1. Extract file path from tool input.
  2. Skip if the file is a test file, config, docs, or governance file.
  3. Walk up from the file's directory looking for SPEC.md (governed project).
  4. Find the corresponding test file using naming conventions.
  5. If no test file exists: BLOCK.
  6. If test file exists but is OLDER than impl file (by mtime, 2s tolerance): BLOCK.
  7. If test file exists and is NEWER or same age: ALLOW.

Bypass: Create a .tdd-skip file in the project root for non-TDD tasks.

Exit 0 = allow (silent). Exit 2 = block with stderr message.
"""

import json
import os
import re
import sys


# Directories that are never project roots (governance repo, templates, etc.)
IGNORE_ROOTS = {
    os.path.expanduser("~/.claude"),
}

# Mtime tolerance in seconds for near-simultaneous writes
MTIME_TOLERANCE = 2.0

# --- File classification: what is NEVER blocked ---

# Test file patterns -- always allowed
TEST_FILE_PATTERNS = [
    r"\.test\.[^.]+$",       # foo.test.ts, foo.test.js
    r"\.spec\.[^.]+$",       # foo.spec.ts, foo.spec.js
    r"(^|/)test_[^/]+$",     # test_foo.py
    r"_test\.[^.]+$",        # foo_test.go, foo_test.py
    r"(^|/)__tests__/",      # __tests__/foo.ts
    r"(^|/)tests/",          # tests/test_foo.py
]

# Config/docs/governance files -- always allowed (by extension or exact name)
EXEMPT_EXTENSIONS = {
    ".md", ".json", ".yaml", ".yml", ".toml", ".cfg", ".ini", ".conf",
    ".lock", ".gitignore", ".txt", ".csv", ".svg", ".png",
    ".jpg", ".jpeg", ".gif", ".ico", ".xml", ".html", ".css",
    ".sh", ".bash",
}

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
    ".tdd-lock", ".tdd-skip", ".tdd-audit.jsonl",
}

# Directories whose contents are always exempt (config, CI, etc.)
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
]


def is_test_file(file_path):
    """Return True if the file matches any test file pattern."""
    for pattern in TEST_FILE_PATTERNS:
        if re.search(pattern, file_path):
            return True
    return False


def is_exempt_file(file_path):
    """Return True if the file should never be gated (config, docs, governance)."""
    basename = os.path.basename(file_path)

    # Exact filename match
    if basename in EXEMPT_FILENAMES:
        return True

    # Extension match
    _, ext = os.path.splitext(basename)
    if ext.lower() in EXEMPT_EXTENSIONS:
        return True

    # Directory pattern match
    for pattern in EXEMPT_DIR_PATTERNS:
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


def find_test_file(file_path):
    """Find the corresponding test file for an implementation file.

    Returns the path of the first matching test file found, or None.
    Naming conventions checked:
      foo.ts  -> foo.test.ts, foo.spec.ts, __tests__/foo.ts, __tests__/foo.test.ts
      foo.py  -> test_foo.py, foo_test.py, tests/test_foo.py, ../tests/test_foo.py
      foo.go  -> foo_test.go
    """
    abs_path = os.path.abspath(file_path)
    directory = os.path.dirname(abs_path)
    basename = os.path.basename(abs_path)
    name, ext = os.path.splitext(basename)

    candidates = []

    if ext in (".ts", ".tsx", ".js", ".jsx"):
        candidates = [
            os.path.join(directory, f"{name}.test{ext}"),
            os.path.join(directory, f"{name}.spec{ext}"),
            os.path.join(directory, "__tests__", f"{name}{ext}"),
            os.path.join(directory, "__tests__", f"{name}.test{ext}"),
        ]
    elif ext == ".py":
        candidates = [
            os.path.join(directory, f"test_{name}.py"),
            os.path.join(directory, f"{name}_test.py"),
            os.path.join(directory, "tests", f"test_{name}.py"),
            os.path.join(os.path.dirname(directory), "tests", f"test_{name}.py"),
        ]
    elif ext == ".go":
        candidates = [
            os.path.join(directory, f"{name}_test.go"),
        ]
    else:
        # Unknown extension -- cannot determine test file, allow the write
        return None

    for candidate in candidates:
        if os.path.isfile(candidate):
            return candidate

    return None


def check_mtime(test_path, impl_path):
    """Check if the test file is at least as recent as the impl file.

    Returns True if test mtime >= impl mtime - MTIME_TOLERANCE.
    If the impl file does not exist yet (new file), returns True.
    """
    if not os.path.isfile(impl_path):
        # Impl file does not exist yet -- this is a new file write, allow
        return True

    try:
        test_mtime = os.path.getmtime(test_path)
        impl_mtime = os.path.getmtime(impl_path)
        return test_mtime >= (impl_mtime - MTIME_TOLERANCE)
    except OSError:
        # Cannot stat -- allow to avoid false blocks
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
    if is_exempt_file(file_path):
        sys.exit(0)

    # Fast path: test files are always allowed
    if is_test_file(file_path):
        sys.exit(0)

    # Find governed project root (SPEC.md marker)
    project_root = find_project_root(file_path)
    if project_root is None:
        # Not inside a governed project -- allow
        sys.exit(0)

    # Check for .tdd-skip (bypass for non-TDD tasks)
    skip_path = os.path.join(project_root, ".tdd-skip")
    if os.path.isfile(skip_path):
        sys.exit(0)

    # Find the corresponding test file
    test_path = find_test_file(file_path)

    if test_path is None:
        # No test file found -- BLOCK
        # Generate expected test path for the error message
        abs_path = os.path.abspath(file_path)
        directory = os.path.dirname(abs_path)
        basename = os.path.basename(abs_path)
        name, ext = os.path.splitext(basename)

        if ext in (".ts", ".tsx", ".js", ".jsx"):
            expected = os.path.join(directory, f"{name}.test{ext}")
        elif ext == ".py":
            expected = os.path.join(directory, f"test_{name}.py")
        elif ext == ".go":
            expected = os.path.join(directory, f"{name}_test.go")
        else:
            expected = f"<test file for {basename}>"

        sys.stderr.write(
            f"\n  TDD: No test file found for {file_path}\n"
            f"  Write {expected} first.\n"
            f"  Or create .tdd-skip in {project_root} to bypass for non-TDD tasks.\n"
        )
        sys.exit(2)

    # Test file exists -- check mtime
    if not check_mtime(test_path, file_path):
        sys.stderr.write(
            f"\n  TDD: Test file {test_path} is stale.\n"
            f"  Update your test before modifying implementation.\n"
            f"  Test mtime must be >= implementation mtime (2s tolerance).\n"
        )
        sys.exit(2)

    # Test file exists and is current -- ALLOW
    sys.exit(0)


if __name__ == "__main__":
    main()
