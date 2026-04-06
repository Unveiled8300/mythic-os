#!/bin/bash
# Fragility scanner for /sweep
# Detects patterns indicating weak error handling, uncaught exceptions, missing validation
#
# Usage: ./scan-fragility.sh [scope_path]
# Exit 0 = no findings, Exit 1 = findings detected

set -uo pipefail

SCOPE="${1:-.}"
FINDINGS=0
FINDING_NUM="${FINDING_START:-1}"

EXCLUDE="--exclude-dir=node_modules --exclude-dir=.next --exclude-dir=dist \
--exclude-dir=build --exclude-dir=.git --exclude-dir=__pycache__ \
--exclude-dir=.venv --exclude-dir=venv --exclude-dir=target \
--exclude-dir=.cache --exclude-dir=coverage --exclude-dir=.forge"

SRC_INCLUDE="--include=*.ts --include=*.tsx --include=*.js --include=*.jsx \
--include=*.py --include=*.go --include=*.rs"

echo "=== Scan: Fragility ==="
echo "Scope: $SCOPE"
echo ""

# --- Unhandled fetch/axios calls ---
# Look for fetch() or axios calls not inside try/catch blocks
# Heuristic: if file contains fetch/axios but no try/catch, flag it
echo "Checking: Unhandled async HTTP calls..."

for file in $(grep -rlE '(fetch\s*\(|axios\.(get|post|put|delete|patch)\s*\()' $SRC_INCLUDE $EXCLUDE "$SCOPE" 2>/dev/null | grep -v '\.md$' | grep -v 'scan-fragility' || true); do
    # Check if the file has any try/catch
    has_try=$(grep -c 'try\s*{' "$file" 2>/dev/null || echo "0")
    has_catch=$(grep -c '\.catch\s*(' "$file" 2>/dev/null || echo "0")

    if [ "$has_try" -eq 0 ] && [ "$has_catch" -eq 0 ]; then
        fetch_lines=$(grep -nE '(fetch\s*\(|axios\.(get|post|put|delete|patch)\s*\()' "$file" 2>/dev/null | head -3 || true)
        if [ -n "$fetch_lines" ]; then
            first_line=$(echo "$fetch_lines" | head -1 | cut -d: -f1)
            printf "SEC-%03d | MEDIUM | fragility | %s:%s\n" "$FINDING_NUM" "$file" "$first_line"
            echo "  HTTP call (fetch/axios) without any try/catch or .catch() in file"
            echo "  Fix: Wrap async HTTP calls in try/catch with error handling"
            echo "  Auto-fixable: yes"
            echo ""
            ((FINDING_NUM++))
            ((FINDINGS++))
        fi
    fi
done

# --- API routes without input validation ---
# Look for route handlers that don't import/use any validation library
echo "Checking: API routes without input validation..."

# Node.js: look for route files without zod/joi/yup/validator imports
for file in $(grep -rlE '(app\.(get|post|put|delete|patch)\s*\(|router\.(get|post|put|delete|patch)\s*\(|export\s+(async\s+)?function\s+(GET|POST|PUT|DELETE|PATCH))' $SRC_INCLUDE $EXCLUDE "$SCOPE" 2>/dev/null | grep -v '\.md$' | grep -v 'scan-fragility' || true); do
    has_validation=$(grep -cE "(from\s+['\"]zod|require\(['\"]zod|from\s+['\"]joi|require\(['\"]joi|from\s+['\"]yup|from\s+['\"]class-validator|\.parse\(|\.validate\(|\.safeParse\()" "$file" 2>/dev/null || echo "0")

    if [ "$has_validation" -eq 0 ]; then
        route_line=$(grep -nE '(app\.(get|post|put|delete|patch)\s*\(|router\.(get|post|put|delete|patch)\s*\(|export\s+(async\s+)?function\s+(GET|POST|PUT|DELETE|PATCH))' "$file" 2>/dev/null | head -1 | cut -d: -f1 || true)
        if [ -n "$route_line" ]; then
            printf "SEC-%03d | MEDIUM | fragility | %s:%s\n" "$FINDING_NUM" "$file" "$route_line"
            echo "  API route handler without input validation (no Zod/Joi/Yup import)"
            echo "  Fix: Add input validation with Zod or equivalent before processing"
            echo "  Auto-fixable: no"
            echo ""
            ((FINDING_NUM++))
            ((FINDINGS++))
        fi
    fi
done

# Python: look for route files without pydantic/marshmallow/cerberus
for file in $(grep -rlE '(@app\.(get|post|put|delete|patch)|@router\.(get|post|put|delete|patch)|def\s+(get|post|put|delete|patch)\s*\()' --include=*.py $EXCLUDE "$SCOPE" 2>/dev/null | grep -v 'scan-fragility' || true); do
    has_validation=$(grep -cE "(from\s+pydantic|import\s+pydantic|from\s+marshmallow|from\s+cerberus|BaseModel)" "$file" 2>/dev/null || echo "0")

    if [ "$has_validation" -eq 0 ]; then
        route_line=$(grep -nE '(@app\.(get|post|put|delete|patch)|@router\.(get|post|put|delete|patch))' "$file" 2>/dev/null | head -1 | cut -d: -f1 || true)
        if [ -n "$route_line" ]; then
            printf "SEC-%03d | MEDIUM | fragility | %s:%s\n" "$FINDING_NUM" "$file" "$route_line"
            echo "  Python API route without input validation (no Pydantic/Marshmallow)"
            echo "  Fix: Add Pydantic models for request body validation"
            echo "  Auto-fixable: no"
            echo ""
            ((FINDING_NUM++))
            ((FINDINGS++))
        fi
    fi
done

# --- Missing error boundaries (React) ---
echo "Checking: Missing React error boundaries..."

# Check if any React component tree exists without an error boundary
has_react=$(grep -rl 'from.*react' --include=*.tsx --include=*.jsx $EXCLUDE "$SCOPE" 2>/dev/null | head -1 || true)
if [ -n "$has_react" ]; then
    has_error_boundary=$(grep -rl 'ErrorBoundary\|componentDidCatch\|error-boundary' $SRC_INCLUDE $EXCLUDE "$SCOPE" 2>/dev/null | head -1 || true)
    if [ -z "$has_error_boundary" ]; then
        printf "SEC-%03d | LOW | fragility | (project-wide)\n" "$FINDING_NUM"
        echo "  React project has no ErrorBoundary component"
        echo "  Fix: Add an ErrorBoundary wrapper to catch render errors gracefully"
        echo "  Auto-fixable: no"
        echo ""
        ((FINDING_NUM++))
        ((FINDINGS++))
    fi
fi

echo "--- Fragility scan complete: $FINDINGS findings ---"

if [ "$FINDINGS" -gt 0 ]; then
    exit 1
else
    exit 0
fi
