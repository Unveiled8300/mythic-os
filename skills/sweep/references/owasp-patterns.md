# OWASP Pattern Library

Reference for `scan-patterns.sh`. Each entry maps an OWASP Top 10 category to grep-detectable patterns.

## A01: Broken Access Control

| Pattern | Regex | Severity |
|---------|-------|----------|
| Routes without auth middleware | `app\.(get\|post).*\(.*req.*res` without `auth\|protect\|guard` in same file | MEDIUM |
| Exposed admin routes | `/(admin\|internal\|debug)/` in route definitions | LOW |

## A03: Injection

| Pattern | Regex | Severity |
|---------|-------|----------|
| SQL string interpolation | `(query\|execute)\s*\(\s*[\`"'].*\$\{` | HIGH |
| dangerouslySetInnerHTML | `dangerouslySetInnerHTML` | HIGH |
| innerHTML assignment | `\.innerHTML\s*=` | HIGH |
| document.write | `document\.write\s*\(` | MEDIUM |
| eval() | `[^a-zA-Z]eval\s*\(` | HIGH |
| new Function() from user input | `new\s+Function\s*\(` | MEDIUM |

## A05: Security Misconfiguration

| Pattern | Regex | Severity |
|---------|-------|----------|
| Debug mode in config | `DEBUG\s*[=:]\s*(true\|True\|1)` | MEDIUM |
| CORS wildcard | `cors.*['"]\\*['"]` | MEDIUM |
| Verbose error responses | `stack.*trace\|stackTrace` in response handlers | LOW |
| Default credentials | `(admin\|root\|test).*password.*=` | HIGH |

## A07: Identification and Authentication Failures

| Pattern | Regex | Severity |
|---------|-------|----------|
| Hardcoded passwords | `password\s*[=:]\s*['"][^'"]{4,}['"]` | HIGH |
| Weak hash algorithms | `\b(md5\|sha1)\b` in auth/password context | HIGH |
| Missing rate limiting | `login\|signin\|auth` route without `rate.*limit\|throttle` | MEDIUM |

## A08: Software and Data Integrity Failures

| Pattern | Regex | Severity |
|---------|-------|----------|
| HTTP script sources | `<script.*src.*http://` | MEDIUM |
| Unpinned CDN resources | `<script.*src.*cdn` without `integrity=` | LOW |

## A09: Security Logging and Monitoring Failures

| Pattern | Regex | Severity |
|---------|-------|----------|
| Sensitive data in logs | `console\.log.*\b(password\|token\|secret\|apiKey)\b` | MEDIUM |
| Missing error logging | `catch\s*\(.*\)\s*\{\s*\}` (empty catch block) | LOW |

## A10: Server-Side Request Forgery (SSRF)

| Pattern | Regex | Severity |
|---------|-------|----------|
| User-controlled URLs in fetch | `fetch\(.*req\.(body\|query\|params)` | HIGH |
| Unvalidated redirect | `redirect\(.*req\.(body\|query)` | MEDIUM |
