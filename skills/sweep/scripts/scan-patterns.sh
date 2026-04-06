#!/bin/bash
# OWASP pattern scanner for /sweep
# Grep-based detection of common vulnerability patterns
#
# Usage: ./scan-patterns.sh [scope_path]
# Exit 0 = no findings, Exit 1 = findings detected

set -uo pipefail

SCOPE="${1:-.}"
FINDINGS=0
FINDING_NUM="${FINDING_START:-1}"

# Directories to skip
EXCLUDE="--exclude-dir=node_modules --exclude-dir=.next --exclude-dir=dist \
--exclude-dir=build --exclude-dir=.git --exclude-dir=__pycache__ \
--exclude-dir=.venv --exclude-dir=venv --exclude-dir=target \
--exclude-dir=.cache --exclude-dir=coverage"

# Source file extensions
SRC_INCLUDE="--include=*.ts --include=*.tsx --include=*.js --include=*.jsx \
--include=*.py --include=*.go --include=*.rs --include=*.java --include=*.rb --include=*.php"

# Config file extensions
CFG_INCLUDE="--include=*.yaml --include=*.yml --include=*.json --include=*.toml \
--include=*.cfg --include=*.ini"

echo "=== Scan: OWASP Patterns ==="
echo "Scope: $SCOPE"
echo ""

# Helper: scan a pattern and report findings
scan_pattern() {
    local id="$1"
    local severity="$2"
    local category="$3"
    local desc="$4"
    local fix="$5"
    local fixable="$6"
    local pattern="$7"
    local includes="$8"

    matches=$(grep -rnE $includes $EXCLUDE "$pattern" "$SCOPE" 2>/dev/null \
        | grep -v '\.md:' \
        | grep -v 'scan-patterns\.sh:' \
        | grep -v 'owasp-patterns\.md:' \
        | grep -v 'node_modules/' \
        || true)

    if [ -n "$matches" ]; then
        match_count=$(echo "$matches" | wc -l | tr -d ' ')
        while IFS= read -r line; do
            file=$(echo "$line" | cut -d: -f1)
            lineno=$(echo "$line" | cut -d: -f2)
            printf "SEC-%03d | %s | %s | %s:%s\n" "$FINDING_NUM" "$severity" "$category" "$file" "$lineno"
            echo "  $desc"
            echo "  Fix: $fix"
            echo "  Auto-fixable: $fixable"
            echo ""
            ((FINDING_NUM++))
            ((FINDINGS++))
        done <<< "$matches"
    fi
}

# --- A03: Injection ---

# SQL injection via string concatenation
scan_pattern "A03" "HIGH" "A03-injection" \
    "Potential SQL injection: string interpolation in query" \
    "Use parameterized queries with placeholders" \
    "no" \
    '(query|execute|exec)\s*\(\s*[`"'"'"'].*\$\{' \
    "$SRC_INCLUDE"

# XSS via dangerouslySetInnerHTML
scan_pattern "A03" "HIGH" "A03-xss" \
    "dangerouslySetInnerHTML used (potential XSS)" \
    "Sanitize input with DOMPurify or equivalent before injection" \
    "no" \
    'dangerouslySetInnerHTML' \
    "$SRC_INCLUDE"

# XSS via innerHTML assignment
scan_pattern "A03" "HIGH" "A03-xss" \
    "innerHTML assignment (potential XSS)" \
    "Use textContent or sanitize with DOMPurify" \
    "no" \
    '\.innerHTML\s*=' \
    "$SRC_INCLUDE"

# document.write
scan_pattern "A03" "MEDIUM" "A03-xss" \
    "document.write() used (potential XSS, blocks rendering)" \
    "Use DOM manipulation methods instead" \
    "no" \
    'document\.write\s*\(' \
    "$SRC_INCLUDE"

# eval() usage
scan_pattern "A03" "HIGH" "A03-injection" \
    "eval() used (code injection risk)" \
    "Replace with safer alternatives (JSON.parse, Function constructor, etc.)" \
    "no" \
    '[^a-zA-Z]eval\s*\(' \
    "$SRC_INCLUDE"

# --- A05: Security Misconfiguration ---

# Debug mode in non-.env files
scan_pattern "A05" "MEDIUM" "A05-misconfig" \
    "DEBUG mode enabled in source/config (should be in .env)" \
    "Move debug flag to .env, default to false in production" \
    "no" \
    'DEBUG\s*[=:]\s*(true|True|1|"true")' \
    "$SRC_INCLUDE $CFG_INCLUDE"

# CORS wildcard
scan_pattern "A05" "MEDIUM" "A05-misconfig" \
    "CORS configured with wildcard origin '*'" \
    "Restrict CORS to specific allowed origins" \
    "no" \
    "cors.*['\"]\\*['\"]|origin.*['\"]\\*['\"]|Access-Control-Allow-Origin.*\\*" \
    "$SRC_INCLUDE"

# --- A07: Identification and Authentication Failures ---

# Hardcoded passwords in source
scan_pattern "A07" "HIGH" "A07-auth" \
    "Hardcoded password in source code" \
    "Move to .env and reference via environment variable" \
    "no" \
    'password\s*[=:]\s*['"'"'"][^'"'"'"]{4,}['"'"'"]' \
    "$SRC_INCLUDE"

# --- A08: Software and Data Integrity Failures ---

# Non-HTTPS CDN scripts
scan_pattern "A08" "MEDIUM" "A08-integrity" \
    "Script loaded over HTTP (not HTTPS)" \
    "Change to HTTPS or use a local copy" \
    "yes" \
    '<script[^>]+src\s*=\s*['"'"'"]http://' \
    "--include=*.html --include=*.htm --include=*.tsx --include=*.jsx"

# --- A09: Security Logging and Monitoring Failures ---

# Sensitive data in console.log
scan_pattern "A09" "MEDIUM" "A09-logging" \
    "Potentially sensitive data in console.log/print" \
    "Remove sensitive data from log statements or use a structured logger" \
    "yes" \
    'console\.log.*\b(password|token|secret|apiKey|api_key|auth|credential)\b|print\(.*\b(password|token|secret|api_key)\b' \
    "$SRC_INCLUDE"

echo "--- OWASP patterns scan complete: $FINDINGS findings ---"

if [ "$FINDINGS" -gt 0 ]; then
    exit 1
else
    exit 0
fi
