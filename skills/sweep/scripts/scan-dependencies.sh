#!/bin/bash
# Dependency vulnerability scanner for /sweep
# Wraps npm audit, pip-audit, govulncheck with unified output
#
# Usage: ./scan-dependencies.sh [scope_path]
# Exit 0 = no high/critical findings, Exit 1 = findings detected

set -uo pipefail

SCOPE="${1:-.}"
FINDINGS=0
FINDING_NUM="${FINDING_START:-1}"

echo "=== Scan: Dependencies ==="
echo "Scope: $SCOPE"
echo ""

# --- Node.js ---
if [ -f "$SCOPE/package.json" ]; then
    echo "Stack: Node.js detected"

    if command -v npm &>/dev/null; then
        AUDIT_OUTPUT=$(cd "$SCOPE" && npm audit --json 2>/dev/null || true)

        if [ -n "$AUDIT_OUTPUT" ] && echo "$AUDIT_OUTPUT" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
            # Parse vulnerabilities by severity
            for severity in critical high moderate low; do
                count=$(echo "$AUDIT_OUTPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    vuln = data.get('metadata', {}).get('vulnerabilities', {})
    print(vuln.get('$severity', 0))
except: print(0)
" 2>/dev/null || echo "0")

                if [ "$count" -gt 0 ] && [ "$count" != "0" ]; then
                    case "$severity" in
                        critical) level="CRITICAL" ;;
                        high)     level="HIGH" ;;
                        moderate) level="MEDIUM" ;;
                        low)      level="LOW" ;;
                    esac

                    printf "SEC-%03d | %s | deps | package.json\n" "$FINDING_NUM" "$level"
                    echo "  npm audit: $count $severity vulnerabilities"
                    echo "  Fix: npm audit fix (or npm audit fix --force for breaking changes)"
                    echo "  Auto-fixable: yes"
                    echo ""
                    ((FINDING_NUM++))
                    ((FINDINGS++))
                fi
            done
        else
            echo "  npm audit returned no parseable output (may be clean)"
        fi
    else
        echo "  SKIP: npm not installed"
    fi
    echo ""
fi

# --- Python ---
if [ -f "$SCOPE/pyproject.toml" ] || [ -f "$SCOPE/requirements.txt" ] || [ -f "$SCOPE/setup.py" ]; then
    echo "Stack: Python detected"

    if command -v pip-audit &>/dev/null; then
        AUDIT_OUTPUT=$(cd "$SCOPE" && pip-audit --format json 2>/dev/null || true)

        if [ -n "$AUDIT_OUTPUT" ]; then
            count=$(echo "$AUDIT_OUTPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    vulns = data if isinstance(data, list) else data.get('dependencies', [])
    total = sum(1 for d in vulns if d.get('vulns'))
    print(total)
except: print(0)
" 2>/dev/null || echo "0")

            if [ "$count" -gt 0 ] && [ "$count" != "0" ]; then
                printf "SEC-%03d | HIGH | deps | pyproject.toml\n" "$FINDING_NUM"
                echo "  pip-audit: $count packages with known vulnerabilities"
                echo "  Fix: pip-audit --fix or update vulnerable packages"
                echo "  Auto-fixable: yes"
                echo ""
                ((FINDING_NUM++))
                ((FINDINGS++))
            fi
        fi
    elif command -v safety &>/dev/null; then
        AUDIT_OUTPUT=$(cd "$SCOPE" && safety check --json 2>/dev/null || true)
        if [ -n "$AUDIT_OUTPUT" ]; then
            echo "  safety check output captured (parse for vulnerabilities)"
        fi
    else
        echo "  SKIP: Neither pip-audit nor safety installed"
    fi
    echo ""
fi

# --- Go ---
if [ -f "$SCOPE/go.mod" ]; then
    echo "Stack: Go detected"

    if command -v govulncheck &>/dev/null; then
        VULN_OUTPUT=$(cd "$SCOPE" && govulncheck ./... 2>/dev/null || true)
        if echo "$VULN_OUTPUT" | grep -q "Vulnerability"; then
            vuln_count=$(echo "$VULN_OUTPUT" | grep -c "Vulnerability" || true)
            printf "SEC-%03d | HIGH | deps | go.mod\n" "$FINDING_NUM"
            echo "  govulncheck: $vuln_count vulnerabilities found"
            echo "  Fix: go get -u [affected packages]"
            echo "  Auto-fixable: no"
            echo ""
            ((FINDING_NUM++))
            ((FINDINGS++))
        fi
    else
        echo "  SKIP: govulncheck not installed"
    fi
    echo ""
fi

echo "--- Dependencies scan complete: $FINDINGS findings ---"

if [ "$FINDINGS" -gt 0 ]; then
    exit 1
else
    exit 0
fi
