#!/usr/bin/env python3
"""
UserPromptSubmit hook -- Context Budget Monitor.

Advisory hook that estimates context window usage by tracking prompt count
and cumulative character volume. Injects a reminder when heuristic thresholds
suggest ~70% context usage, per PM SOP 2.

State is tracked via a tmp file keyed by the parent process ID.

Exit 0 always (advisory only — cannot block prompt submission).
"""

import json
import os
import sys
import time


STATE_DIR = os.path.join(os.environ.get("TMPDIR", "/tmp"), "mythic-os")

# Heuristic thresholds — tuned for ~200K token context window
# Average exchange (prompt + response) ~ 2000 tokens ~ 8000 chars
CHAR_THRESHOLD_70PCT = 560000   # ~70% of 200K tokens * 4 chars/token
CHAR_THRESHOLD_90PCT = 720000   # ~90%
PROMPT_THRESHOLD_70 = 60        # ~60 exchanges at avg 2K tokens each
PROMPT_THRESHOLD_90 = 80
MIN_NUDGE_INTERVAL = 300        # Don't nudge more than once per 5 minutes


def get_state_file():
    """Get the path to the session state file, keyed by parent PID."""
    ppid = os.getppid()
    os.makedirs(STATE_DIR, exist_ok=True)
    return os.path.join(STATE_DIR, f"context-budget-{ppid}.json")


def load_state():
    """Load session state."""
    state_file = get_state_file()
    try:
        with open(state_file, "r") as f:
            return json.load(f)
    except (IOError, json.JSONDecodeError, FileNotFoundError):
        return {"prompt_count": 0, "total_chars": 0, "last_nudge": 0}


def save_state(state):
    """Save session state."""
    state_file = get_state_file()
    try:
        with open(state_file, "w") as f:
            json.dump(state, f)
    except IOError:
        pass


def main():
    try:
        input_data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, IOError):
        sys.exit(0)

    prompt = input_data.get("prompt", "")

    state = load_state()
    state["prompt_count"] = state.get("prompt_count", 0) + 1
    state["total_chars"] = state.get("total_chars", 0) + len(prompt)
    now = time.time()

    # Determine severity
    severity = None
    if (state["total_chars"] >= CHAR_THRESHOLD_90PCT
            or state["prompt_count"] >= PROMPT_THRESHOLD_90):
        severity = "critical"
    elif (state["total_chars"] >= CHAR_THRESHOLD_70PCT
            or state["prompt_count"] >= PROMPT_THRESHOLD_70):
        severity = "warning"

    save_state(state)

    if severity and (now - state.get("last_nudge", 0) > MIN_NUDGE_INTERVAL):
        state["last_nudge"] = now
        save_state(state)

        if severity == "critical":
            msg = (
                f"CONTEXT BUDGET CRITICAL (~90%): {state['prompt_count']} prompts, "
                f"~{state['total_chars'] // 4000}K tokens estimated. "
                f"Run /compact immediately. Do not start a new task. "
                f"Consider: Vendor Manager: HANDOFF"
            )
        else:
            msg = (
                f"CONTEXT BUDGET WARNING (~70%): {state['prompt_count']} prompts, "
                f"~{state['total_chars'] // 4000}K tokens estimated. "
                f"Consider running /compact before starting the next task. "
                f"PM SOP 2: do not start a new task above 70%."
            )

        output = {
            "hookSpecificOutput": {
                "hookEventName": "UserPromptSubmit",
                "additionalContext": msg,
            }
        }
        json.dump(output, sys.stdout)

    sys.exit(0)


if __name__ == "__main__":
    main()
