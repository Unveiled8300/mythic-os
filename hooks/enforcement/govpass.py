#!/usr/bin/env python3
"""
Governance Pass Marker Protocol — shared module for skill-marker enforcement.

Skills call write_marker() when they complete successfully. The branch-gate
checks for required markers before allowing git commit. Markers are cleared
after each successful commit by the commit-cleanup hook.

Marker directory: .govpass/ in the project root (next to SPEC.md).
Marker format: JSON files named by gate (review-pass.json, sweep-pass.json, etc.)

Usage from skills:
    from govpass import write_marker, REVIEW, SWEEP, QA, EVAL
    write_marker(project_root, REVIEW, task_id="T-01", verdict="PASS", details={})

Usage from branch-gate:
    from govpass import check_markers, REQUIRED_MARKERS
    missing = check_markers(project_root, task_id="T-01")
    if missing:
        block(f"Missing governance markers: {missing}")
"""

import json
import os
import time
from datetime import datetime, timezone


# Marker names — these are the gates that must pass before commit
REVIEW = "review-pass"
SWEEP = "sweep-pass"
QA = "qa-pass"
EVAL = "eval-pass"

# All required markers for a standard commit
REQUIRED_MARKERS = [REVIEW, SWEEP, QA, EVAL]

# Markers directory name (created in project root)
GOVPASS_DIR = ".govpass"

# Maximum age of a marker in seconds (24 hours — prevents ancient markers
# from satisfying current gates)
MAX_MARKER_AGE = 86400


def get_govpass_dir(project_root):
    """Get the .govpass directory path for a project."""
    return os.path.join(project_root, GOVPASS_DIR)


def write_marker(project_root, marker_name, task_id=None, verdict="PASS",
                 details=None):
    """Write a governance pass marker.

    Called by skills (/review, /sweep, /qa-verify, eval harness) when they
    complete successfully.

    Args:
        project_root: Path to the project root (contains SPEC.md)
        marker_name: One of REVIEW, SWEEP, QA, EVAL
        task_id: The task ID this marker covers (e.g., "T-01")
        verdict: "PASS" or "PASS_WITH_CONCERNS"
        details: Optional dict with additional information
    """
    govpass_dir = get_govpass_dir(project_root)
    os.makedirs(govpass_dir, exist_ok=True)

    marker_path = os.path.join(govpass_dir, f"{marker_name}.json")
    marker_data = {
        "marker": marker_name,
        "task_id": task_id,
        "verdict": verdict,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "epoch": time.time(),
        "details": details or {},
    }

    with open(marker_path, "w", encoding="utf-8") as f:
        json.dump(marker_data, f, indent=2)

    return marker_path


def read_marker(project_root, marker_name):
    """Read a governance pass marker, or return None if missing/invalid."""
    marker_path = os.path.join(get_govpass_dir(project_root),
                               f"{marker_name}.json")

    if not os.path.isfile(marker_path):
        return None

    try:
        with open(marker_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        # Check age — reject stale markers
        epoch = data.get("epoch", 0)
        if time.time() - epoch > MAX_MARKER_AGE:
            return None

        return data
    except (json.JSONDecodeError, IOError, OSError):
        return None


def check_markers(project_root, task_id=None, required=None):
    """Check which required markers are missing or invalid.

    Args:
        project_root: Path to the project root
        task_id: If provided, markers must match this task ID
        required: List of required marker names (default: REQUIRED_MARKERS)

    Returns:
        List of missing marker names (empty list = all present).
    """
    if required is None:
        required = REQUIRED_MARKERS

    missing = []
    for marker_name in required:
        data = read_marker(project_root, marker_name)
        if data is None:
            missing.append(marker_name)
            continue

        # If task_id is specified, marker must match
        if task_id and data.get("task_id") and data["task_id"] != task_id:
            missing.append(marker_name)
            continue

        # Marker must have PASS verdict
        if data.get("verdict") not in ("PASS", "PASS_WITH_CONCERNS"):
            missing.append(marker_name)

    return missing


def clear_markers(project_root):
    """Clear all governance markers (called after successful commit).

    Does not remove the .govpass/ directory — only the marker files.
    """
    govpass_dir = get_govpass_dir(project_root)
    if not os.path.isdir(govpass_dir):
        return

    for filename in os.listdir(govpass_dir):
        if filename.endswith(".json"):
            try:
                os.remove(os.path.join(govpass_dir, filename))
            except OSError:
                pass


def has_bypass(project_root):
    """Check if the project has a .review-skip bypass file."""
    return os.path.isfile(os.path.join(project_root, ".review-skip"))


# --- CLI interface for use from shell scripts ---

if __name__ == "__main__":
    import sys

    if len(sys.argv) < 3:
        print("Usage: govpass.py <command> <project_root> [args...]")
        print("Commands: write <marker> [task_id], check [task_id], clear")
        sys.exit(1)

    command = sys.argv[1]
    project_root = sys.argv[2]

    if command == "write":
        marker_name = sys.argv[3] if len(sys.argv) > 3 else REVIEW
        task_id = sys.argv[4] if len(sys.argv) > 4 else None
        path = write_marker(project_root, marker_name, task_id=task_id)
        print(f"Wrote marker: {path}")

    elif command == "check":
        task_id = sys.argv[3] if len(sys.argv) > 3 else None
        missing = check_markers(project_root, task_id=task_id)
        if missing:
            print(f"Missing markers: {', '.join(missing)}")
            sys.exit(1)
        else:
            print("All markers present.")
            sys.exit(0)

    elif command == "clear":
        clear_markers(project_root)
        print("Markers cleared.")

    else:
        print(f"Unknown command: {command}")
        sys.exit(1)
