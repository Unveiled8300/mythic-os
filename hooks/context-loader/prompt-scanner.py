#!/usr/bin/env python3
"""
UserPromptSubmit hook: CARL-style keyword injection + AEGIS phase-scoped bundles.

Reads user prompt from stdin JSON, matches keywords against fragments.json,
applies prioritized pruning within a token budget cap, deduplicates per-session,
and FORCE_EMITs security fragment every N prompts.

Returns matched fragments via additionalContext in JSON stdout.
"""

import json
import os
import sys
import tempfile
import re
from datetime import datetime

HOOK_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(HOOK_DIR, "fragments.json")
STATE_DIR = os.path.join(tempfile.gettempdir(), "claude-context-loader")
USAGE_LOG_PATH = os.path.join(os.path.expanduser("~"), ".claude", "brain", "log", "fragment-usage.jsonl")


def get_state_path():
    """Per-session state file keyed by parent PID (the Claude Code process)."""
    ppid = os.getppid()
    return os.path.join(STATE_DIR, f"session-{ppid}.json")


def load_state():
    path = get_state_path()
    if os.path.exists(path):
        try:
            with open(path, "r") as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            pass
    return {"emitted": [], "prompt_count": 0}


def save_state(state):
    os.makedirs(STATE_DIR, exist_ok=True)
    path = get_state_path()
    with open(path, "w") as f:
        json.dump(state, f)


def load_config():
    with open(CONFIG_PATH, "r") as f:
        return json.load(f)


def read_fragment(fragment_path):
    full_path = os.path.join(HOOK_DIR, fragment_path)
    if os.path.exists(full_path):
        with open(full_path, "r") as f:
            return f.read().strip()
    return None


def count_keyword_hits(text_lower, keywords):
    """Count how many keywords from the list appear in the text."""
    hits = 0
    for kw in keywords:
        if kw.lower() in text_lower:
            hits += 1
    return hits


def match_fragments(prompt_text, config):
    """Score all phases and standalones by keyword hit count. Return sorted matches."""
    text_lower = prompt_text.lower()
    matches = []

    for phase in config.get("phases", []):
        hits = count_keyword_hits(text_lower, phase["keywords"])
        if hits > 0:
            matches.append({
                "name": phase["phase"],
                "fragment_path": phase["fragment_path"],
                "priority": phase["priority"],
                "token_estimate": phase["token_estimate"],
                "hits": hits,
            })

    for standalone in config.get("standalone", []):
        hits = count_keyword_hits(text_lower, standalone["keywords"])
        if hits > 0:
            matches.append({
                "name": standalone["name"],
                "fragment_path": standalone["fragment_path"],
                "priority": standalone["priority"],
                "token_estimate": standalone["token_estimate"],
                "hits": hits,
            })

    # Sort: highest hit count first, then lowest priority number (1 = highest priority)
    matches.sort(key=lambda m: (-m["hits"], m["priority"]))
    return matches


def log_fragment_usage(fragment_names):
    """Append fragment usage to a persistent JSONL log for Phase 5 role audit."""
    if not fragment_names:
        return
    try:
        os.makedirs(os.path.dirname(USAGE_LOG_PATH), exist_ok=True)
        entry = {
            "timestamp": datetime.now().isoformat(),
            "fragments": fragment_names,
        }
        with open(USAGE_LOG_PATH, "a") as f:
            f.write(json.dumps(entry) + "\n")
    except (IOError, OSError):
        pass  # Never block on logging failure


def select_within_budget(matches, budget, already_emitted):
    """Pick fragments that fit within the token budget, skipping already-emitted ones."""
    selected = []
    remaining = budget

    for match in matches:
        if match["name"] in already_emitted:
            continue
        if match["token_estimate"] <= remaining:
            selected.append(match)
            remaining -= match["token_estimate"]

    return selected


def main():
    try:
        input_data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, IOError):
        # If we can't read input, output empty response
        print(json.dumps({}))
        return

    prompt_text = input_data.get("user_message", "")
    if not prompt_text:
        print(json.dumps({}))
        return

    try:
        config = load_config()
    except (IOError, json.JSONDecodeError):
        print(json.dumps({}))
        return

    state = load_state()
    state["prompt_count"] = state.get("prompt_count", 0) + 1
    already_emitted = set(state.get("emitted", []))

    budget = config.get("token_budget_cap", 2000)
    force_interval = config.get("force_emit_interval", 5)
    force_fragments = config.get("force_emit_fragments", [])

    # Match keywords against prompt
    matches = match_fragments(prompt_text, config)

    # Select within budget, respecting deduplication
    selected = select_within_budget(matches, budget, already_emitted)

    # FORCE_EMIT: check if it's time to re-emit forced fragments
    force_emit_due = (state["prompt_count"] % force_interval == 0)

    if force_emit_due:
        for force_name in force_fragments:
            # Check if already selected in this round
            already_selected = any(s["name"] == force_name for s in selected)
            if not already_selected:
                # Find the fragment config
                for standalone in config.get("standalone", []):
                    if standalone["name"] == force_name:
                        selected.append({
                            "name": standalone["name"],
                            "fragment_path": standalone["fragment_path"],
                            "priority": standalone["priority"],
                            "token_estimate": standalone["token_estimate"],
                            "hits": 0,
                        })
                        break
                for phase in config.get("phases", []):
                    if phase["phase"] == force_name:
                        selected.append({
                            "name": phase["phase"],
                            "fragment_path": phase["fragment_path"],
                            "priority": phase["priority"],
                            "token_estimate": phase["token_estimate"],
                            "hits": 0,
                        })
                        break

    # Build additionalContext from selected fragments
    additional_context = []
    newly_emitted = []

    for frag in selected:
        content = read_fragment(frag["fragment_path"])
        if content:
            additional_context.append(content)
            newly_emitted.append(frag["name"])

    # Log fragment usage for Phase 5 role audit
    log_fragment_usage(newly_emitted)

    # Update state: mark newly emitted (but force-emitted ones can re-emit)
    for name in newly_emitted:
        if name not in force_fragments and name not in already_emitted:
            state["emitted"].append(name)

    save_state(state)

    if additional_context:
        result = {
            "additionalContext": "\n\n---\n\n".join(additional_context)
        }
    else:
        result = {}

    print(json.dumps(result))


if __name__ == "__main__":
    main()
