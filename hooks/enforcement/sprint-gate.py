#!/usr/bin/env python3
"""
PreToolUse hook (matcher: Edit|Write|MultiEdit) -- Sprint Decomposition Gate.

Blocks writes to implementation files inside governed projects when SPRINT.md
is missing or contains no task breakdown. This enforces Project Manager SOP 1:
"implementation without a task breakdown is forbidden."

Detection logic:
  1. Extract file path from tool input.
  2. Skip if the file is exempt (config, docs, governance, test files).
  3. Walk up from the file's directory looking for SPEC.md (governed project).
  4. Check that SPRINT.md exists in project root.
  5. Check that SPRINT.md contains at least one task line (T-\d+:).
  6. If SPRINT.md is missing or has no tasks: BLOCK.

Bypass: Create a .sprint-skip file in the project root.

Exit 0 = allow (silent). Exit 2 = block with stderr message.
"""

import json
import os
import re
import sys


IGNORE_ROOTS = {
    os.path.expanduser("~/.claude"),
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

# Pattern to match task lines in SPRINT.md
TASK_PATTERN = re.compile(r"^\s*-\s*\[[ x]\]\s*T-\d+:", re.MULTILINE)

# Pattern to match epic headers in SPRINT.md (e.g., "## E-01: Auth & Tenant")
EPIC_HEADER_RE = re.compile(r"^##\s+(E-\d+):", re.MULTILINE)

# Known epic-to-directory mappings for common project conventions
# Maps directory names (from route groups or feature dirs) to epic slugs
# This is a heuristic — if no mapping found, falls back to global task check.


def infer_epic_from_path(file_path):
    """Try to infer which epic a file belongs to based on its directory path.

    Returns the epic ID (e.g., 'E-09') if one can be inferred, or None.
    This uses the SPRINT.md epic headers to build a reverse mapping from
    directory names to epic IDs.
    """
    # We don't do path-to-epic inference here — that requires SPRINT.md content.
    # This function just extracts directory segments from the path.
    path_parts = file_path.replace("\\", "/").split("/")
    # Strip route group parens: (app) → app
    return [p.strip("()") for p in path_parts if p and p != "src"]


def epic_has_tasks(content, epic_id):
    """Check if a specific epic in SPRINT.md has at least one task line.

    Looks for the epic header, then checks for task lines between it and the
    next epic header (or end of file).
    """
    # Find the position of this epic's header
    epic_pattern = re.compile(
        rf"^##\s+{re.escape(epic_id)}:", re.MULTILINE
    )
    match = epic_pattern.search(content)
    if not match:
        return None  # Epic not found in SPRINT.md

    start = match.end()

    # Find the next epic header (or end of file)
    next_epic = re.search(r"^##\s+E-\d+:", content[start:], re.MULTILINE)
    if next_epic:
        section = content[start : start + next_epic.start()]
    else:
        section = content[start:]

    # Check for task lines in this epic's section
    return bool(TASK_PATTERN.search(section))


def match_path_to_epic(sprint_content, file_path):
    """Try to match a file path to a specific epic based on SPRINT.md content.

    Strategy: extract epic names from SPRINT.md headers, then check if any
    epic name keywords appear in the file path directory segments.

    Returns (epic_id, has_tasks) or (None, None) if no match found.
    """
    path_segments = infer_epic_from_path(file_path)
    if not path_segments:
        return None, None

    # Build mapping: epic_id -> name words from the header
    epics = {}
    for m in EPIC_HEADER_RE.finditer(sprint_content):
        epic_id = m.group(1)
        # Get the rest of the header line after "E-NN: "
        line_start = m.end()
        line_end = sprint_content.find("\n", line_start)
        if line_end == -1:
            line_end = len(sprint_content)
        name = sprint_content[line_start:line_end].strip().lower()
        # Extract meaningful words (skip short words)
        words = [w for w in re.split(r"[\s&,/]+", name) if len(w) >= 3]
        epics[epic_id] = words

    if not epics:
        return None, None

    # Try to match path segments to epic keywords
    path_lower = [s.lower() for s in path_segments]
    for epic_id, keywords in epics.items():
        for keyword in keywords:
            if keyword in path_lower:
                has_tasks = epic_has_tasks(sprint_content, epic_id)
                return epic_id, has_tasks

    return None, None


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


def sprint_has_tasks(project_root):
    """Check if SPRINT.md exists and contains at least one task line."""
    sprint_path = os.path.join(project_root, "SPRINT.md")

    if not os.path.isfile(sprint_path):
        return False, None

    try:
        with open(sprint_path, "r", encoding="utf-8") as f:
            content = f.read()
        has_any = bool(TASK_PATTERN.search(content))
        return has_any, content
    except (IOError, OSError):
        # Cannot read — allow to avoid false blocks
        return True, None


def check_sprint_for_file(project_root, file_path):
    """Enhanced sprint check: per-epic if possible, global fallback.

    Returns (allowed: bool, message: str or None).
    """
    sprint_path = os.path.join(project_root, "SPRINT.md")

    if not os.path.isfile(sprint_path):
        return False, "SPRINT.md does not exist."

    has_any_tasks, content = sprint_has_tasks(project_root)

    if content is None:
        # Could not read — allow
        return True, None

    if not has_any_tasks:
        return False, "SPRINT.md contains no task breakdown (no T-NN: lines found)."

    # Per-epic check: try to match file to a specific epic
    epic_id, epic_has = match_path_to_epic(content, file_path)

    if epic_id is not None and epic_has is not None:
        if not epic_has:
            return False, (
                f"Epic {epic_id} has no task breakdown in SPRINT.md. "
                f"Decompose {epic_id} into Atomic Tasks before implementing its files."
            )
        # Epic matched and has tasks — allow
        return True, None

    # No epic match found — fall back to global "any tasks exist" check
    # (backwards compatible with the previous behavior)
    return True, None


def main():
    try:
        input_data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, IOError):
        sys.exit(0)

    tool_input = input_data.get("tool_input", {})
    file_path = tool_input.get("file_path", "")

    if not file_path:
        sys.exit(0)

    if is_exempt(file_path):
        sys.exit(0)

    project_root = find_project_root(file_path)
    if project_root is None:
        sys.exit(0)

    if os.path.isfile(os.path.join(project_root, ".sprint-skip")):
        sys.exit(0)

    allowed, msg = check_sprint_for_file(project_root, file_path)

    if not allowed:
        sys.stderr.write(
            f"\n  SPRINT GATE: {msg}\n"
            f"  Decompose the sprint into Atomic Tasks before writing implementation.\n"
            f"  Run: Project Manager: SPRINT PLAN — [feature]\n"
            f"  Current file: {file_path}\n"
            f"  Or create .sprint-skip in {project_root} to bypass.\n"
        )
        sys.exit(2)

    sys.exit(0)


if __name__ == "__main__":
    main()
