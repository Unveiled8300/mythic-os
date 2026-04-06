#!/bin/bash
# Full-codebase secret scanner for /sweep
# Extends patterns from hooks/enforcement/secret-scan.py to retroactive scanning
#
# Usage: ./scan-secrets.sh [scope_path]
# Exit 0 = no findings, Exit 1 = findings detected

set -uo pipefail

SCOPE="${1:-.}"
FINDINGS=0
FINDING_NUM="${FINDING_START:-1}"

# File extensions to scan
INCLUDE="--include=*.ts --include=*.tsx --include=*.js --include=*.jsx --include=*.py \
--include=*.yaml --include=*.yml --include=*.json --include=*.toml --include=*.cfg \
--include=*.ini --include=*.env.* --include=*.sh --include=*.go --include=*.rs \
--include=*.java --include=*.rb --include=*.php"

# Directories to skip
EXCLUDE="--exclude-dir=node_modules --exclude-dir=.next --exclude-dir=dist \
--exclude-dir=build --exclude-dir=.git --exclude-dir=__pycache__ \
--exclude-dir=.venv --exclude-dir=venv --exclude-dir=target \
--exclude-dir=.cache --exclude-dir=coverage"

# Secret patterns (from secret-scan.py lines 15-29)
declare -A PATTERNS
PATTERNS["Stripe live secret key"]='sk_live_[A-Za-z0-9]{20,}'
PATTERNS["Stripe test secret key"]='sk_test_[A-Za-z0-9]{20,}'
PATTERNS["Stripe live publishable key"]='pk_live_[A-Za-z0-9]{20,}'
PATTERNS["Stripe test publishable key"]='pk_test_[A-Za-z0-9]{20,}'
PATTERNS["AWS access key ID"]='AKIA[0-9A-Z]{16}'
PATTERNS["GitHub personal access token"]='ghp_[A-Za-z0-9]{36}'
PATTERNS["GitHub OAuth token"]='gho_[A-Za-z0-9]{36}'
PATTERNS["Slack bot token"]='xoxb-[A-Za-z0-9-]+'
PATTERNS["Slack user token"]='xoxp-[A-Za-z0-9-]+'
PATTERNS["Private key"]='-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----'
PATTERNS["OpenAI API key"]='sk-[A-Za-z0-9]{20,}T3BlbkFJ'
PATTERNS["Google API key"]='AIzaSy[A-Za-z0-9_-]{33}'
PATTERNS["Square access token"]='sq0atp-[A-Za-z0-9_-]{22}'

echo "=== Scan: Secrets ==="
echo "Scope: $SCOPE"
echo ""

# Run each pattern
for desc in "${!PATTERNS[@]}"; do
    pattern="${PATTERNS[$desc]}"
    matches=$(grep -rnE $INCLUDE $EXCLUDE "$pattern" "$SCOPE" 2>/dev/null | grep -v '\.md:' | grep -v 'scan-secrets\.sh:' || true)
    if [ -n "$matches" ]; then
        while IFS= read -r line; do
            file=$(echo "$line" | cut -d: -f1)
            lineno=$(echo "$line" | cut -d: -f2)
            printf "SEC-%03d | CRITICAL | secrets | %s:%s\n" "$FINDING_NUM" "$file" "$lineno"
            echo "  $desc detected"
            echo "  Fix: Move to .env and reference via environment variable"
            echo "  Auto-fixable: no"
            echo ""
            ((FINDING_NUM++))
            ((FINDINGS++))
        done <<< "$matches"
    fi
done

# Check .env in .gitignore
if [ -f "$SCOPE/.gitignore" ]; then
    if ! grep -q '\.env' "$SCOPE/.gitignore" 2>/dev/null; then
        printf "SEC-%03d | CRITICAL | secrets | .gitignore\n" "$FINDING_NUM"
        echo "  .env is not listed in .gitignore"
        echo "  Fix: Add .env to .gitignore"
        echo "  Auto-fixable: yes"
        echo ""
        ((FINDING_NUM++))
        ((FINDINGS++))
    fi
elif [ -d "$SCOPE/.git" ]; then
    printf "SEC-%03d | HIGH | secrets | (missing)\n" "$FINDING_NUM"
    echo "  No .gitignore file found in git repository"
    echo "  Fix: Create .gitignore with .env and other exclusions"
    echo "  Auto-fixable: yes"
    echo ""
    ((FINDING_NUM++))
    ((FINDINGS++))
fi

# Check .env.example exists (if .env pattern is used)
if ls "$SCOPE"/.env* 1>/dev/null 2>&1 || grep -rq 'process\.env\.\|os\.environ\|os\.getenv' "$SCOPE" $INCLUDE $EXCLUDE 2>/dev/null; then
    if [ ! -f "$SCOPE/.env.example" ]; then
        printf "SEC-%03d | MEDIUM | secrets | (missing)\n" "$FINDING_NUM"
        echo "  .env.example file not found (env vars are used but no example provided)"
        echo "  Fix: Create .env.example with all required keys (values blank)"
        echo "  Auto-fixable: no"
        echo ""
        ((FINDING_NUM++))
        ((FINDINGS++))
    fi
fi

echo "--- Secrets scan complete: $FINDINGS findings ---"

if [ "$FINDINGS" -gt 0 ]; then
    exit 1
else
    exit 0
fi
