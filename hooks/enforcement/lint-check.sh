#!/usr/bin/env bash
# PostToolUse hook (matcher: Write|Edit|MultiEdit) — Lint Feedback
#
# Detects project type and surfaces lint errors as additionalContext
# after every file edit. Advisory (never blocks), but ensures Claude
# sees and fixes lint issues immediately.
#
# Exit 0 always. Output JSON with additionalContext on lint errors.

set -uo pipefail

# Read tool input from stdin
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('tool_result', {}).get('file_path', '') or
          data.get('tool_input', {}).get('file_path', ''))
except: pass
" 2>/dev/null)

if [ -z "$FILE_PATH" ]; then
    echo '{}'
    exit 0
fi

# Find project root by walking up to find package.json or pyproject.toml
find_project_root() {
    local dir="$1"
    while [ "$dir" != "/" ]; do
        if [ -f "$dir/package.json" ] || [ -f "$dir/pyproject.toml" ]; then
            echo "$dir"
            return
        fi
        dir=$(dirname "$dir")
    done
    echo ""
}

PROJECT_ROOT=$(find_project_root "$(dirname "$FILE_PATH")")
if [ -z "$PROJECT_ROOT" ]; then
    echo '{}'
    exit 0
fi

ERRORS=""

# JavaScript/TypeScript project
if [ -f "$PROJECT_ROOT/package.json" ]; then
    case "$FILE_PATH" in
        *.js|*.jsx|*.ts|*.tsx)
            # Try eslint on the specific file
            if command -v npx &>/dev/null; then
                LINT_OUTPUT=$(cd "$PROJECT_ROOT" && npx eslint --no-warn-ignored --format compact "$FILE_PATH" 2>&1) || true
                if echo "$LINT_OUTPUT" | grep -qE "Error -|error " 2>/dev/null; then
                    # Extract just the error lines, limit to 10
                    ERRORS=$(echo "$LINT_OUTPUT" | grep -E "Error -|error " | head -10)
                fi
            fi
            ;;
    esac
fi

# Python project
if [ -f "$PROJECT_ROOT/pyproject.toml" ] || [ -f "$PROJECT_ROOT/ruff.toml" ]; then
    case "$FILE_PATH" in
        *.py)
            if command -v ruff &>/dev/null; then
                LINT_OUTPUT=$(ruff check "$FILE_PATH" 2>&1) || true
                if [ -n "$LINT_OUTPUT" ]; then
                    ERRORS=$(echo "$LINT_OUTPUT" | head -10)
                fi
            fi
            ;;
    esac
fi

# Output results
if [ -n "$ERRORS" ]; then
    # Escape for JSON
    ESCAPED=$(echo "$ERRORS" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip()))" 2>/dev/null)
    echo "{\"additionalContext\": \"Lint errors found after editing $FILE_PATH — fix before proceeding:\\n${ESCAPED}\"}"
else
    echo '{}'
fi

exit 0
