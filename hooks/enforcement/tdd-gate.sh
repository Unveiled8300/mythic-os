#!/usr/bin/env bash
# -------------------------------------------------------------------
# TDD Gate -- skill-level enforcement for red/green TDD cycle.
#
# Called by team skills via Bash tool (not a harness hook).
# Subcommands:
#   check-test-exists <src_file>       -- Verify a test file exists for the source
#   verify-red <test_cmd>              -- Run test suite, MUST fail (exit != 0)
#   verify-green <test_cmd>            -- Run test suite, MUST pass (exit == 0)
#   verify-order <project_root>        -- Check git log: tests committed before/with impl
#   verify-audit <project_root>        -- Check .tdd-audit.jsonl: test entries before impl
#
# Exit 0 = gate passed.  Exit 1 = gate failed (with diagnostic on stderr).
# -------------------------------------------------------------------

set -euo pipefail

usage() {
    echo "Usage: tdd-gate.sh <subcommand> [args...]"
    echo ""
    echo "Subcommands:"
    echo "  check-test-exists <src_file>    Check that a test file exists for the given source file"
    echo "  verify-red <test_cmd...>        Run test command -- MUST fail (exit != 0)"
    echo "  verify-green <test_cmd...>      Run test command -- MUST pass (exit == 0)"
    echo "  verify-order <project_root>     Check git: test files committed before/with impl files"
    echo "  verify-audit <project_root>     Check .tdd-audit.jsonl: test entries precede impl entries"
    exit 1
}

# --- find_project_root_for_lock ---
# Walk up from CWD looking for SPEC.md (governed project root).
# Used by verify-red (create .tdd-lock) and verify-green (delete .tdd-lock).
find_project_root_for_lock() {
    local dir
    dir=$(pwd)
    for _ in $(seq 1 10); do
        if [ "$dir" = "/" ]; then
            break
        fi
        if [ -f "$dir/SPEC.md" ]; then
            echo "$dir"
            return
        fi
        dir=$(dirname "$dir")
    done
    # Fallback: use CWD
    pwd
}

# --- check-test-exists ---
# Given a source file path, look for a matching test file.
# Conventions checked:
#   foo.ts        -> foo.test.ts, foo.spec.ts, __tests__/foo.ts
#   foo.py        -> test_foo.py, foo_test.py, tests/test_foo.py
#   foo.go        -> foo_test.go
cmd_check_test_exists() {
    local src_file="$1"
    local dir
    dir=$(dirname "$src_file")
    local base
    base=$(basename "$src_file")
    local name="${base%.*}"
    local ext="${base##*.}"

    local candidates=()

    case "$ext" in
        ts|tsx|js|jsx)
            candidates=(
                "$dir/${name}.test.${ext}"
                "$dir/${name}.spec.${ext}"
                "$dir/__tests__/${name}.${ext}"
                "$dir/__tests__/${name}.test.${ext}"
            )
            ;;
        py)
            candidates=(
                "$dir/test_${name}.py"
                "$dir/${name}_test.py"
                "$dir/tests/test_${name}.py"
                "$(dirname "$dir")/tests/test_${name}.py"
            )
            ;;
        go)
            candidates=(
                "$dir/${name}_test.go"
            )
            ;;
        *)
            echo "TDD-GATE: Unknown extension .$ext -- skipping test file check" >&2
            exit 0
            ;;
    esac

    for candidate in "${candidates[@]}"; do
        if [ -f "$candidate" ]; then
            echo "TDD-GATE PASS: Test file found: $candidate"
            exit 0
        fi
    done

    echo "TDD-GATE FAIL: No test file found for $src_file" >&2
    echo "  Checked:" >&2
    for candidate in "${candidates[@]}"; do
        echo "    $candidate" >&2
    done
    echo "  Write a failing test first (red), then implement (green)." >&2
    exit 1
}

# --- verify-red ---
# Run the test command. It MUST fail (exit != 0).
# This confirms the test is meaningful -- it fails before implementation.
# On success: writes .tdd-lock to unlock implementation file writes.
cmd_verify_red() {
    local test_cmd="$*"
    echo "TDD-GATE: Running red check -- expecting FAILURE..."
    echo "  Command: $test_cmd"

    set +e
    eval "$test_cmd" > /tmp/tdd-gate-red-output.tmp 2>&1
    local exit_code=$?
    set -e

    if [ "$exit_code" -ne 0 ]; then
        echo "TDD-GATE PASS (red): Test failed as expected (exit code $exit_code)"
        echo "  Output (last 10 lines):"
        tail -n 10 /tmp/tdd-gate-red-output.tmp | sed 's/^/    /'
        rm -f /tmp/tdd-gate-red-output.tmp

        # Write .tdd-lock to unlock implementation writes
        local lock_dir
        lock_dir=$(find_project_root_for_lock)
        if [ -n "$lock_dir" ]; then
            echo "# TDD Lock -- created by tdd-gate.sh verify-red" > "$lock_dir/.tdd-lock"
            echo "timestamp=$(date -u +'%Y-%m-%dT%H:%M:%SZ')" >> "$lock_dir/.tdd-lock"
            echo "test_cmd=$test_cmd" >> "$lock_dir/.tdd-lock"
            echo "  Lock file written: $lock_dir/.tdd-lock"
        fi

        exit 0
    else
        echo "TDD-GATE FAIL (red): Test passed when it should have failed" >&2
        echo "  The test must FAIL before implementation -- this confirms" >&2
        echo "  the test is actually testing new behavior, not passing vacuously." >&2
        echo "  Output (last 10 lines):" >&2
        tail -n 10 /tmp/tdd-gate-red-output.tmp | sed 's/^/    /' >&2
        rm -f /tmp/tdd-gate-red-output.tmp
        exit 1
    fi
}

# --- verify-green ---
# Run the test command. It MUST pass (exit == 0).
# This confirms the implementation satisfies the test.
# On success: deletes .tdd-lock (cycle complete -- re-lock for next feature).
cmd_verify_green() {
    local test_cmd="$*"
    echo "TDD-GATE: Running green check -- expecting PASS..."
    echo "  Command: $test_cmd"

    set +e
    eval "$test_cmd" > /tmp/tdd-gate-green-output.tmp 2>&1
    local exit_code=$?
    set -e

    if [ "$exit_code" -eq 0 ]; then
        echo "TDD-GATE PASS (green): Test passed (exit code 0)"
        echo "  Output (last 10 lines):"
        tail -n 10 /tmp/tdd-gate-green-output.tmp | sed 's/^/    /'
        rm -f /tmp/tdd-gate-green-output.tmp

        # Delete .tdd-lock -- cycle complete, re-lock for next feature
        local lock_dir
        lock_dir=$(find_project_root_for_lock)
        if [ -n "$lock_dir" ] && [ -f "$lock_dir/.tdd-lock" ]; then
            rm -f "$lock_dir/.tdd-lock"
            echo "  Lock file removed: $lock_dir/.tdd-lock (TDD cycle complete)"
        fi

        exit 0
    else
        echo "TDD-GATE FAIL (green): Test still failing after implementation (exit code $exit_code)" >&2
        echo "  The implementation must make the test pass." >&2
        echo "  Output (last 10 lines):" >&2
        tail -n 10 /tmp/tdd-gate-green-output.tmp | sed 's/^/    /' >&2
        rm -f /tmp/tdd-gate-green-output.tmp
        exit 1
    fi
}

# --- verify-order ---
# Check git log to confirm test files were committed before/with implementation.
cmd_verify_order() {
    local project_root="${1:-.}"
    cd "$project_root"

    local test_commit=""
    local impl_commit=""

    # Find most recent commit that added/modified test files
    test_commit=$(git log -n 20 --diff-filter=AM --format="%H" -- \
        "**/*.test.*" "**/*.spec.*" "**/test_*" "**/*_test.*" \
        "**/__tests__/*" "**/tests/test_*" 2>/dev/null | head -1)

    # Find most recent commit that added/modified non-test source files
    impl_commit=$(git log -n 20 --diff-filter=AM --format="%H" -- \
        "*.ts" "*.tsx" "*.js" "*.jsx" "*.py" "*.go" \
        ":!**/*.test.*" ":!**/*.spec.*" ":!**/test_*" ":!**/*_test.*" \
        ":!**/__tests__/*" ":!**/tests/*" 2>/dev/null | head -1)

    if [ -z "$test_commit" ]; then
        echo "TDD-GATE WARN: No test file commits found in recent history" >&2
        echo "  Cannot verify TDD ordering -- flagging as concern." >&2
        exit 1
    fi

    if [ -z "$impl_commit" ]; then
        echo "TDD-GATE PASS (order): Test commits found, no impl commits yet -- correct TDD ordering"
        exit 0
    fi

    if [ "$test_commit" = "$impl_commit" ]; then
        echo "TDD-GATE PASS (order): Test and impl in same commit -- acceptable"
        exit 0
    fi

    if git merge-base --is-ancestor "$test_commit" "$impl_commit" 2>/dev/null; then
        echo "TDD-GATE PASS (order): Test committed before implementation -- correct TDD ordering"
        exit 0
    fi

    echo "TDD-GATE FAIL (order): Implementation committed before tests" >&2
    echo "  Test commit:  $test_commit" >&2
    echo "  Impl commit:  $impl_commit" >&2
    echo "  TDD requires: write test first (red), then implement (green)." >&2
    exit 1
}

# --- verify-audit ---
# Read .tdd-audit.jsonl and check that for every impl file entry,
# a test file entry exists earlier in the log.
cmd_verify_audit() {
    local project_root="${1:-.}"
    local audit_file="$project_root/.tdd-audit.jsonl"

    if [ ! -f "$audit_file" ]; then
        echo "TDD-GATE WARN: No .tdd-audit.jsonl found at $project_root" >&2
        echo "  Cannot verify TDD ordering -- audit trail missing." >&2
        exit 1
    fi

    set +e
    local result
    result=$(python3 -c "
import json, sys, os

audit_path = sys.argv[1]
violations = []
test_files_seen = set()

with open(audit_path, 'r') as f:
    for line_num, line in enumerate(f, 1):
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue

        file_path = entry.get('file', '')
        file_type = entry.get('type', '')
        timestamp = entry.get('timestamp', 'unknown')

        if file_type == 'test':
            test_files_seen.add(file_path)
        elif file_type == 'impl':
            basename = os.path.basename(file_path)
            name, ext = os.path.splitext(basename)
            dirname = os.path.dirname(file_path)

            expected_tests = set()
            if ext in ('.ts', '.tsx', '.js', '.jsx'):
                expected_tests.add(os.path.join(dirname, name + '.test' + ext))
                expected_tests.add(os.path.join(dirname, name + '.spec' + ext))
                expected_tests.add(os.path.join(dirname, '__tests__', name + ext))
                expected_tests.add(os.path.join(dirname, '__tests__', name + '.test' + ext))
            elif ext == '.py':
                expected_tests.add(os.path.join(dirname, 'test_' + name + '.py'))
                expected_tests.add(os.path.join(dirname, name + '_test.py'))
                expected_tests.add(os.path.join(dirname, 'tests', 'test_' + name + '.py'))
            elif ext == '.go':
                expected_tests.add(os.path.join(dirname, name + '_test.go'))

            found = False
            for t in expected_tests:
                if t in test_files_seen:
                    found = True
                    break

            if not found:
                violations.append({
                    'line': line_num,
                    'file': file_path,
                    'timestamp': timestamp,
                })

if violations:
    print('VIOLATIONS')
    for v in violations:
        print('  Line {}: {} at {} -- no preceding test entry'.format(v['line'], v['file'], v['timestamp']))
    sys.exit(1)
else:
    print('CLEAN')
    sys.exit(0)
" "$audit_file" 2>&1)
    local py_exit=$?
    set -e

    if [ "$py_exit" -eq 0 ]; then
        echo "TDD-GATE PASS (audit): All impl entries have preceding test entries"
        echo "  Audit file: $audit_file"
        exit 0
    else
        echo "TDD-GATE FAIL (audit): Implementation files written before tests" >&2
        echo "$result" >&2
        echo "  TDD requires: write test first, then implement." >&2
        exit 1
    fi
}

# --- Main dispatch ---
if [ $# -lt 1 ]; then
    usage
fi

subcommand="$1"
shift

case "$subcommand" in
    check-test-exists)
        [ $# -lt 1 ] && { echo "Error: check-test-exists requires <src_file>" >&2; exit 1; }
        cmd_check_test_exists "$1"
        ;;
    verify-red)
        [ $# -lt 1 ] && { echo "Error: verify-red requires <test_cmd>" >&2; exit 1; }
        cmd_verify_red "$@"
        ;;
    verify-green)
        [ $# -lt 1 ] && { echo "Error: verify-green requires <test_cmd>" >&2; exit 1; }
        cmd_verify_green "$@"
        ;;
    verify-order)
        cmd_verify_order "${1:-.}"
        ;;
    verify-audit)
        cmd_verify_audit "${1:-.}"
        ;;
    *)
        echo "Unknown subcommand: $subcommand" >&2
        usage
        ;;
esac
