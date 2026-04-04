#!/usr/bin/env python3
"""
PreToolUse hook (matcher: Edit|Write|MultiEdit) — Secret Detection.

Scans EVERY file write for hardcoded secrets and blocks if found.
Replaces security_reminder_hook.py which only warned once per session.

Exit 0 = allow (silent). Exit 2 = block with stderr message.
"""

import json
import re
import sys

SECRET_PATTERNS = [
    (r"sk_live_[A-Za-z0-9]{20,}", "Stripe live secret key"),
    (r"sk_test_[A-Za-z0-9]{20,}", "Stripe test secret key"),
    (r"pk_live_[A-Za-z0-9]{20,}", "Stripe live publishable key"),
    (r"pk_test_[A-Za-z0-9]{20,}", "Stripe test publishable key"),
    (r"AKIA[0-9A-Z]{16}", "AWS access key ID"),
    (r"ghp_[A-Za-z0-9]{36}", "GitHub personal access token"),
    (r"gho_[A-Za-z0-9]{36}", "GitHub OAuth token"),
    (r"xoxb-[A-Za-z0-9\-]+", "Slack bot token"),
    (r"xoxp-[A-Za-z0-9\-]+", "Slack user token"),
    (r"-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----", "Private key"),
    (r"sk-[A-Za-z0-9]{20,}T3BlbkFJ[A-Za-z0-9]+", "OpenAI API key"),
    (r"AIzaSy[A-Za-z0-9_-]{33}", "Google API key"),
    (r"sq0atp-[A-Za-z0-9_-]{22}", "Square access token"),
    (r"eyJ[A-Za-z0-9_-]{50,}\.[A-Za-z0-9_-]{50,}\.", "JWT token (long)"),
]

# Files that legitimately reference secret patterns (e.g., this hook itself, docs)
SAFE_PATH_PATTERNS = [
    r"secret.scan\.py$",
    r"catastrophic.gate\.py$",
    r"pre-commit$",
    r"\.md$",
]

FORBIDDEN_FILE_PATTERNS = [
    (r"\.env$", ".env file — manage secrets manually, never via Claude Code"),
    (r"\.env\.[a-z]+$", ".env.* file — manage secrets manually"),
    (r"\.pem$", "PEM certificate file"),
    (r"\.key$", "Private key file"),
    (r"\.p12$", "PKCS#12 keystore file"),
    (r"\.pfx$", "PFX certificate file"),
]


def extract_content(tool_input):
    """Extract the text being written from various tool input formats."""
    contents = []

    # Write tool
    if "content" in tool_input:
        contents.append(tool_input["content"])

    # Edit tool
    if "new_string" in tool_input:
        contents.append(tool_input["new_string"])

    # MultiEdit tool
    if "edits" in tool_input:
        for edit in tool_input.get("edits", []):
            if "new_string" in edit:
                contents.append(edit["new_string"])

    return "\n".join(contents)


def main():
    try:
        input_data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, IOError):
        sys.exit(0)

    tool_input = input_data.get("tool_input", {})
    file_path = tool_input.get("file_path", "")

    # Check if writing to a forbidden file type
    for pattern, reason in FORBIDDEN_FILE_PATTERNS:
        if re.search(pattern, file_path):
            sys.stderr.write(
                f"\n  BLOCKED: Refusing to write {reason}\n"
                f"  File: {file_path}\n"
                f"  Manage secrets manually outside Claude Code.\n"
            )
            sys.exit(2)

    # Skip scanning files that legitimately contain secret patterns
    for safe_pattern in SAFE_PATH_PATTERNS:
        if re.search(safe_pattern, file_path):
            sys.exit(0)

    content = extract_content(tool_input)
    if not content:
        sys.exit(0)

    # Scan for secret patterns
    for pattern, description in SECRET_PATTERNS:
        match = re.search(pattern, content)
        if match:
            matched_text = match.group(0)
            # Show first/last 4 chars only
            if len(matched_text) > 12:
                redacted = matched_text[:4] + "..." + matched_text[-4:]
            else:
                redacted = matched_text[:4] + "..."

            sys.stderr.write(
                f"\n  BLOCKED: Hardcoded secret detected — {description}\n"
                f"  Pattern: {redacted}\n"
                f"  File: {file_path}\n"
                f"  Use environment variables instead.\n"
            )
            sys.exit(2)

    # Silent pass
    sys.exit(0)


if __name__ == "__main__":
    main()
