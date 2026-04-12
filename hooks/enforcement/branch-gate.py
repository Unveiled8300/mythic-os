#!/usr/bin/env python3
"""
PreToolUse hook (matcher: Bash) -- Branch Discipline, Conventional Commits,
and Governance Skill Markers.

Enforces four rules:
  1. No direct commits to main/master.
  2. No git push to main/master.
  3. All commit messages must follow conventional commit format.
  4. All required governance skill markers must be present before commit.

Governance skill markers (rule 4):
  Before allowing a git commit on a governed project (SPEC.md present),
  checks for .govpass/ directory containing:
    - review-pass.json  (from /review or /code-review)
    - sweep-pass.json   (from /sweep)
    - qa-pass.json      (from /qa-verify)
    - eval-pass.json    (from eval harness / self-iterate)
  Each marker must be non-stale (< 24 hours old) and have verdict PASS.

  Exemptions from marker check:
    - docs/chore/ci/style commit types (no code review needed)
    - Governance commits (docs(governance):)
    - Merge commits
    - Projects with .review-skip bypass file

Exit 0 = allow (silent). Exit 2 = block with stderr message.
"""

import json
import os
import re
import subprocess
import sys


IGNORE_ROOTS = {
    os.path.expanduser("~/.claude"),
}

# Conventional commit format: type(optional-scope): description
CONVENTIONAL_COMMIT_RE = re.compile(
    r"^(feat|fix|docs|refactor|test|chore|ci|style|perf)"
    r"(\([^)]+\))?"   # optional scope in parentheses
    r"(!)?:\s.+"       # optional breaking change marker, colon, space, description
)

# Patterns for extracting commit message from git commit command
# Handles: git commit -m "msg", git commit -m 'msg', git commit -m msg
# Also handles combined flags: git commit -am "msg", git commit -sam "msg"
COMMIT_MSG_RE = re.compile(
    r'git\s+commit\s+'
    r'(?:.*\s)?'         # optional flags before -m
    r'-[a-ln-zA-LN-Z]*m' # -m alone or combined like -am, -sam (m at end)
    r'\s+'
    r'(?:'
    r'"([^"]*)"'       # double-quoted message
    r"|'([^']*)'"      # single-quoted message
    r'|(\S+)'          # unquoted single word
    r')',
    re.DOTALL
)

# Commit messages that are always allowed (governance, experiment, merge)
ALLOWED_PREFIXES = [
    "docs(governance):",
    "Merge ",
    "merge ",
    "experiment:",
    "initial commit",
    "Initial commit",
]

PROTECTED_BRANCHES = {"main", "master"}

# Commit types that are exempt from governance marker checks.
# These are non-code changes that don't warrant /review, /sweep, /qa-verify.
MARKER_EXEMPT_TYPES = {"docs", "chore", "ci", "style"}


def get_current_branch(cwd=None):
    """Get the current git branch name, or None if not in a git repo."""
    try:
        result = subprocess.run(
            ["git", "branch", "--show-current"],
            capture_output=True, text=True, timeout=3,
            cwd=cwd,
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        pass
    return None


def find_project_root_from_cwd(cwd):
    """Walk up from cwd looking for .branch-skip or SPEC.md."""
    directory = os.path.abspath(cwd) if cwd else os.getcwd()
    for _ in range(10):
        if not directory or directory == os.path.dirname(directory):
            return None
        if directory in IGNORE_ROOTS:
            return None
        if os.path.isfile(os.path.join(directory, ".branch-skip")):
            return directory
        if os.path.isfile(os.path.join(directory, "SPEC.md")):
            return directory
        directory = os.path.dirname(directory)
    return None


def extract_commit_message(command):
    """Extract the commit message from a git commit -m command."""
    match = COMMIT_MSG_RE.search(command)
    if match:
        # Return whichever group matched (double-quoted, single-quoted, or bare)
        return match.group(1) or match.group(2) or match.group(3) or ""
    return None


def is_allowed_message(msg):
    """Check if the commit message matches an always-allowed pattern."""
    for prefix in ALLOWED_PREFIXES:
        if msg.startswith(prefix):
            return True
    return False


def is_heredoc_commit(command):
    """Detect if this is a heredoc-style commit (git commit -m \"$(cat <<'EOF'...)\"."""
    return "<<" in command and "EOF" in command


def is_commit_command(command):
    """Check if this is a git commit command."""
    return bool(re.search(r"\bgit\s+commit\b", command))


def is_push_command(command):
    """Check if this is a git push command."""
    return bool(re.search(r"\bgit\s+push\b", command))


def push_targets_protected(command):
    """Check if a git push command targets a protected branch."""
    # Explicit: git push origin main
    for branch in PROTECTED_BRANCHES:
        if re.search(rf"\bgit\s+push\s+\S+\s+{branch}\b", command):
            return True
        # git push --force origin main
        if re.search(rf"\bgit\s+push\s+.*\b{branch}\b", command):
            return True
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

    # Only gate git commit and git push commands
    is_commit = is_commit_command(command)
    is_push = is_push_command(command)

    if not is_commit and not is_push:
        sys.exit(0)

    # Check for bypass file
    project_root = find_project_root_from_cwd(cwd)
    if project_root and os.path.isfile(os.path.join(project_root, ".branch-skip")):
        sys.exit(0)
    # Also check cwd directly
    if os.path.isfile(os.path.join(cwd, ".branch-skip")):
        sys.exit(0)

    current_branch = get_current_branch(cwd)

    # --- Git push to protected branch ---
    if is_push:
        if push_targets_protected(command):
            sys.stderr.write(
                f"\n  BRANCH GATE: Direct push to protected branch detected.\n"
                f"  Create a PR instead of pushing directly to main/master.\n"
                f"  Command: {command}\n"
            )
            sys.exit(2)

        # If on main and pushing without explicit branch, block
        if current_branch in PROTECTED_BRANCHES:
            # Allow if pushing to a different remote branch explicitly
            # e.g., git push origin HEAD:feature-branch
            if "HEAD:" in command or any(
                f":{b}" in command for b in PROTECTED_BRANCHES
            ):
                pass  # Explicit remote branch targeting — check the target
            else:
                sys.stderr.write(
                    f"\n  BRANCH GATE: You are on '{current_branch}' and pushing.\n"
                    f"  Switch to a feature branch before pushing.\n"
                    f"  Branch naming: epic/N-slug, story/eN-slug, fix/T-ID-slug\n"
                )
                sys.exit(2)

    # --- Git commit on protected branch ---
    if is_commit:
        if current_branch in PROTECTED_BRANCHES:
            # Allow governance commits (docs(governance):, Merge, etc.) on main
            if not is_heredoc_commit(command):
                msg = extract_commit_message(command)
                if msg and is_allowed_message(msg):
                    sys.exit(0)

            sys.stderr.write(
                f"\n  BRANCH GATE: Direct commit to '{current_branch}' is prohibited.\n"
                f"  Create a feature branch first:\n"
                f"    git checkout -b epic/N-name\n"
                f"    git checkout -b story/eN-feature-name\n"
                f"    git checkout -b fix/T-ID-description\n"
                f"  Or create .branch-skip to bypass (initial scaffolding only).\n"
                f"  Exception: docs(governance): commits are allowed on main.\n"
            )
            sys.exit(2)

        # --- Conventional commit format ---
        # Skip validation for heredoc-style commits (too complex to parse inline)
        if is_heredoc_commit(command):
            sys.exit(0)

        msg = extract_commit_message(command)
        if msg is None:
            # Cannot extract message (might be --amend, --no-edit, etc.) — allow
            sys.exit(0)

        if is_allowed_message(msg):
            sys.exit(0)

        if not CONVENTIONAL_COMMIT_RE.match(msg):
            sys.stderr.write(
                f"\n  BRANCH GATE: Commit message does not follow conventional format.\n"
                f"  Expected: type(scope): description\n"
                f"  Types: feat, fix, docs, refactor, test, chore, ci, style, perf\n"
                f"  Got: {msg[:80]}\n"
                f"  Example: feat(T-01): add user registration endpoint\n"
            )
            sys.exit(2)

    # --- Governance skill markers (rule 4) ---
    # Only check markers for git commit on governed projects
    if is_commit and project_root:
        # Skip marker check for exempt commit types and allowed messages
        msg = None
        if not is_heredoc_commit(command):
            msg = extract_commit_message(command)

        marker_exempt = False

        # Governance commits, merges, experiments — exempt
        if msg and is_allowed_message(msg):
            marker_exempt = True

        # docs/chore/ci/style commit types — exempt (no code to review)
        if msg and not marker_exempt:
            type_match = re.match(r"^(\w+)", msg)
            if type_match and type_match.group(1) in MARKER_EXEMPT_TYPES:
                marker_exempt = True

        # Heredoc commits — cannot determine type, exempt from markers
        if is_heredoc_commit(command):
            marker_exempt = True

        # .review-skip bypass
        if os.path.isfile(os.path.join(project_root, ".review-skip")):
            marker_exempt = True

        if not marker_exempt:
            # Determine tier: Tier 1 (every commit) vs Tier 2 (story completion)
            # Tier 1: eval-pass + review-pass
            # Tier 2: all 4 markers (eval + review + qa + sweep)
            is_story_completion = False
            if msg:
                # Story completion signals in commit message
                if re.search(r"\bS-\d+\b", msg):
                    is_story_completion = True
                elif re.search(r"(?i)\bstory\s+(done|complete)", msg):
                    is_story_completion = True
                elif re.search(r"(?i)\bQA\s+PASS\b", msg):
                    is_story_completion = True

            # .govpass/story-complete flag (written by PM skill)
            story_flag = os.path.join(project_root, ".govpass", "story-complete")
            if os.path.isfile(story_flag):
                is_story_completion = True

            # Import govpass module (co-located in enforcement/)
            hook_dir = os.path.dirname(os.path.abspath(__file__))
            if hook_dir not in sys.path:
                sys.path.insert(0, hook_dir)
            try:
                from govpass import check_markers, REVIEW, SWEEP, QA, EVAL

                if is_story_completion:
                    # Tier 2: all 4 markers required
                    required = [EVAL, REVIEW, QA, SWEEP]
                    tier_label = "Tier 2 (story completion)"
                else:
                    # Tier 1: only eval + review required
                    required = [EVAL, REVIEW]
                    tier_label = "Tier 1 (standard commit)"

                missing = check_markers(project_root, required=required)
                if missing:
                    friendly = {
                        "review-pass": "/review (code review)",
                        "sweep-pass": "/sweep (security scan)",
                        "qa-pass": "/qa-verify (QA verification)",
                        "eval-pass": "eval harness (test suite)",
                    }
                    missing_names = [friendly.get(m, m) for m in missing]
                    sys.stderr.write(
                        f"\n  GOVERNANCE MARKER GATE [{tier_label}]:\n"
                        f"  Missing required skill passes.\n"
                        f"  Before committing, run these skills:\n"
                    )
                    for name in missing_names:
                        sys.stderr.write(f"    - {name}\n")
                    sys.stderr.write(
                        f"\n  Markers expected in: {project_root}/.govpass/\n"
                        f"  Or create .review-skip in {project_root} to bypass.\n"
                    )
                    if is_story_completion:
                        sys.stderr.write(
                            f"  Story completion detected — all 4 markers required.\n"
                        )
                    else:
                        sys.stderr.write(
                            f"  Standard commit — eval + review required.\n"
                            f"  Exempt commit types: docs, chore, ci, style\n"
                        )
                    sys.exit(2)
            except ImportError:
                # govpass module not available — allow (graceful degradation)
                pass

    sys.exit(0)


if __name__ == "__main__":
    main()
