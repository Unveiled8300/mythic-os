#!/usr/bin/env python3
"""
PostToolUse hook (matcher: Bash) -- Session Summary Nudge.

Advisory hook that tracks bash command count per session and periodically
reminds to write a Session Summary (PM SOP 4). Also detects session-end
patterns and injects a stronger reminder.

State is tracked via a tmp file keyed by the parent process ID (same
pattern as prompt-scanner.py).

Exit 0 always (advisory only).
"""

import json
import os
import sys
import time


NUDGE_INTERVAL = 50  # Remind every N bash commands
STATE_DIR = os.path.join(os.environ.get("TMPDIR", "/tmp"), "mythic-os")

SESSION_END_PATTERNS = [
    "handoff",
    "/handoff",
    "session end",
    "SESSION END",
    "signing off",
    "done for today",
    "wrapping up",
]


def get_state_file():
    """Get the path to the session state file, keyed by parent PID."""
    ppid = os.getppid()
    os.makedirs(STATE_DIR, exist_ok=True)
    return os.path.join(STATE_DIR, f"session-nudge-{ppid}.json")


def load_state():
    """Load session state (command count, last nudge time)."""
    state_file = get_state_file()
    try:
        with open(state_file, "r") as f:
            return json.load(f)
    except (IOError, json.JSONDecodeError, FileNotFoundError):
        return {"count": 0, "last_nudge": 0}


def save_state(state):
    """Save session state."""
    state_file = get_state_file()
    try:
        with open(state_file, "w") as f:
            json.dump(state, f)
    except IOError:
        pass


def is_session_end(command):
    """Check if the command matches a session-end pattern."""
    cmd_lower = command.lower()
    return any(pattern in cmd_lower for pattern in SESSION_END_PATTERNS)


def main():
    try:
        input_data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, IOError):
        sys.exit(0)

    tool_input = input_data.get("tool_input", {})
    command = tool_input.get("command", "")

    if not command:
        sys.exit(0)

    state = load_state()
    state["count"] = state.get("count", 0) + 1
    now = time.time()
    should_nudge = False
    urgent = False

    # Periodic nudge every NUDGE_INTERVAL commands
    if state["count"] % NUDGE_INTERVAL == 0:
        # Don't nudge more than once every 10 minutes
        if now - state.get("last_nudge", 0) > 600:
            should_nudge = True

    # Session-end detection
    if is_session_end(command):
        should_nudge = True
        urgent = True

    save_state(state)

    if should_nudge:
        state["last_nudge"] = now
        save_state(state)

        if urgent:
            msg = (
                "SESSION ENDING: Write a Sprint Summary before closing. "
                "Use PM SOP 4 format: Completed, Pending, Blockers, Context Usage. "
                "Run: Project Manager: SESSION END"
            )
        else:
            msg = (
                f"SESSION CHECKPOINT ({state['count']} commands): Consider writing "
                f"a Sprint Summary to SPRINT.md. "
                f"Run: Project Manager: SESSION END"
            )

        output = {
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": msg,
            }
        }
        json.dump(output, sys.stdout)

    sys.exit(0)


if __name__ == "__main__":
    main()
