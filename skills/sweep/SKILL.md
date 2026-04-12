---
name: sweep
description: >
  Use this skill when the user says "/sweep", "scan the project", "check for vulnerabilities",
  "security scan", "run a full sweep", "audit the codebase", or wants proactive full-project
  vulnerability scanning, fragility detection, or auto-remediation. Modes: /sweep (full scan),
  /sweep --security (security only), /sweep --fix (scan + auto-patch), /sweep --scope <path>
  (scoped scan). NOT for per-task QA (use /qa-verify) or per-edit secret detection (pre-commit
  hooks handle that).
---

# /sweep — Proactive Scan + Patch + Test

You are the Security Officer performing a full-project sweep. This skill fills the gap between
per-edit hooks (secret-scan, lint-check) and per-task reviews (Security Officer scrub, /qa-verify).
It scans the *entire codebase* retroactively, detects patterns the per-edit hooks cannot catch,
and optionally auto-patches fixable issues.

## Step 0: Load Role Contract

Read `~/.claude/rules/security.md` using the Read tool.

## Step 1: Parse Mode

Determine the scan mode from the invocation:

| Invocation | Mode | What Runs |
|-----------|------|-----------|
| `/sweep` | full | All 5 scans: secrets + dependencies + OWASP + fragility + lint/tests |
| `/sweep --security` | security | Security only: secrets + dependencies + OWASP |
| `/sweep --fix` | fix | Full scan + auto-patch cycle |
| `/sweep --scope <path>` | scoped | Full scan restricted to `<path>` |

## Step 2: Detect Project Stack

```bash
# Detect stack for tool selection
test -f package.json && echo "STACK:node"
test -f pyproject.toml && echo "STACK:python"
test -f go.mod && echo "STACK:go"
test -f Cargo.toml && echo "STACK:rust"
test -f requirements.txt && echo "STACK:python"
```

Record the stack type. If multiple detected, scan for all.

## Step 3: Run Scan Battery

Execute applicable scans. Each scan can run independently — launch in parallel where possible.

### Scan 1: Secrets (all modes)

Scan the full codebase for hardcoded secrets. This extends the per-edit patterns from
`~/.claude/hooks/enforcement/secret-scan.py` to a retroactive full-project scan.

Patterns to detect (from `secret-scan.py` lines 15-29):
- `sk_live_`, `sk_test_`, `pk_live_`, `pk_test_` (Stripe)
- `AKIA[0-9A-Z]{16}` (AWS)
- `ghp_`, `gho_` (GitHub tokens)
- `xoxb-`, `xoxp-` (Slack tokens)
- `BEGIN.*PRIVATE KEY` (private keys)
- `sk-.*T3BlbkFJ` (OpenAI)
- `AIzaSy` (Google API)
- `sq0atp-` (Square)
- Long JWT tokens

Also check:
1. `.env` listed in `.gitignore` — if not, CRITICAL finding
2. `.env.example` exists — if not, WARN finding
3. Git history for leaked secrets: `git log -p --all -S "sk_live_" --diff-filter=A -- '*.ts' '*.js' '*.py'`

Use `scripts/scan-secrets.sh` for the grep battery. Report each match as a finding.

### Scan 2: Dependencies (all modes)

Check for known vulnerabilities in project dependencies.

| Stack | Command |
|-------|---------|
| Node.js | `npm audit --json 2>/dev/null` |
| Python | `pip-audit --format json 2>/dev/null` or `safety check --json 2>/dev/null` |
| Go | `govulncheck ./... 2>/dev/null` |

Use `scripts/scan-dependencies.sh`. Parse JSON output:
- critical/high severity → FAIL-level finding
- medium → WARN-level finding
- low → INFO-level finding

If the audit tool is not installed, note as SKIP (not FAIL).

### Scan 3: OWASP Patterns (all modes)

Grep-based detection of common vulnerability patterns. Read `references/owasp-patterns.md` for
the full pattern library, then run `scripts/scan-patterns.sh`.

Key patterns:
- **A03 Injection:** String concatenation in SQL queries, `dangerouslySetInnerHTML`, `innerHTML =`, `document.write`, `eval(`
- **A05 Security Misconfiguration:** `DEBUG = true` or `DEBUG=True` in non-.env files, `CORS: '*'`
- **A07 Authentication Failures:** `password =` hardcoded in source (not .env)
- **A08 Software Integrity:** `<script src="http://` (non-HTTPS CDN)
- **A09 Logging Failures:** `console.log` with sensitive variable names (password, token, secret, key, auth)

### Scan 4: Fragility (full and fix modes only)

Detect patterns that indicate fragile error handling. Run `scripts/scan-fragility.sh`.

Patterns:
- `fetch(` or `axios.` without surrounding `try`/`catch` within 5 lines
- `async` function bodies without `.catch()` or `try`/`catch`
- API route handlers without input validation (no Zod/Joi/validator import in the same file)
- Missing CSRF protection on POST/PUT/DELETE routes

### Scan 5: Lint + Tests (full and fix modes only)

Run the project's full lint and test suite:

| Stack | Lint | Tests |
|-------|------|-------|
| Node.js | `npx eslint . --max-warnings=0 2>&1` or `npm run lint 2>&1` | `npx jest --ci 2>&1` or `npx vitest run 2>&1` |
| Python | `ruff check . 2>&1` or `flake8 . 2>&1` | `python -m pytest --tb=short 2>&1` |

Record: exit code, error count, warning count, test pass/fail counts.

## Step 4: Compile Findings

Assign each finding a sequential ID and structured record:

```
SEC-001 | CRITICAL | secrets    | src/lib/stripe.ts:14
  Stripe live key hardcoded in source
  Fix: Move to .env and reference via process.env.STRIPE_KEY
  Auto-fixable: no

SEC-002 | HIGH     | A03-inject | src/api/users.ts:42
  String concatenation in SQL query
  Fix: Use parameterized query with $1 placeholders
  Auto-fixable: yes

SEC-003 | MEDIUM   | fragility  | src/lib/api.ts:28
  fetch() call without try/catch
  Fix: Wrap in try/catch with error handling
  Auto-fixable: yes

SEC-004 | LOW      | deps       | package.json
  lodash 4.17.20 has moderate prototype pollution (npm audit)
  Fix: npm audit fix
  Auto-fixable: yes
```

Severity mapping:
- **CRITICAL**: Hardcoded production secrets, .env not in .gitignore, SQL injection
- **HIGH**: Dependency vulns (critical/high), XSS vectors, missing auth on routes
- **MEDIUM**: Missing error handling, fragility patterns, dependency vulns (medium)
- **LOW**: Dependency vulns (low), minor patterns, style issues
- **INFO**: Suggestions, non-blocking observations

## Step 5: Auto-Patch Cycle (--fix mode only)

Skip this step unless mode is `fix`.

For each finding where `Auto-fixable: yes`, in order from CRITICAL to LOW:

1. **Generate patch** — Write the specific code change
2. **Apply patch** — Edit the file
3. **Re-scan** — Run only the specific scan that found this issue against the patched file
4. **Verdict:**
   - Re-scan passes → mark finding as `RESOLVED`, commit: `sweep-fix: SEC-[NNN] [1-line description]`
   - Re-scan fails → revert the change, mark as `MANUAL_FIX_REQUIRED`
5. **One commit per fix** — never batch multiple fixes into one commit

After all auto-fixes:
- Print summary: `[N] fixed, [M] require manual intervention`
- Re-run full scan to check for regressions

## Step 6: Produce Report

Print the structured report:

```
========================================
SWEEP REPORT
========================================
project:    [project-root]
mode:       [full | security | fix | scoped]
date:       [ISO timestamp]
verdict:    PASS | WARN | FAIL
========================================

FINDINGS SUMMARY
----------------------------------------
CRITICAL:   [N] findings
HIGH:       [N] findings
MEDIUM:     [N] findings
LOW:        [N] findings
INFO:       [N] findings
TOTAL:      [N] findings

SCAN COVERAGE
----------------------------------------
secrets:        EXECUTED — [N] files scanned, [N] findings
dependencies:   EXECUTED — [N] packages checked, [N] findings
owasp_patterns: EXECUTED — [N] patterns checked, [N] findings
fragility:      EXECUTED | SKIPPED — [N] files scanned, [N] findings
lint_tests:     EXECUTED | SKIPPED — lint: [PASS/FAIL], tests: [X/Y passed]

FINDINGS DETAIL
----------------------------------------
[Each SEC-NNN finding with full detail]

========================================
verdict:    [PASS | WARN | FAIL]
findings:   [N] total ([N] critical, [N] high, [N] medium, [N] low)
========================================
```

## Step 7: Verdict Rules

```
FAIL  — Any CRITICAL or HIGH finding is OPEN
WARN  — All CRITICAL/HIGH resolved but MEDIUM findings OPEN
PASS  — No CRITICAL/HIGH/MEDIUM findings OPEN (LOW/INFO are informational)
```

## Rules

1. **Never modify files unless in --fix mode.** Default sweep is read-only.
2. **One commit per auto-fix.** Never batch. This allows easy revert of individual fixes.
3. **Always re-scan after patching.** A fix that introduces a new issue is worse than no fix.
4. **Structured output is sacred.** The `verdict:` and `findings:` lines must be grep-parseable.
5. **SKIP is not FAIL.** If a scan tool is not installed, report SKIP — don't penalize.
6. **Respect .gitignore.** Don't scan `node_modules/`, `dist/`, `.next/`, `__pycache__/`, etc.
7. **Scope flag narrows, never widens.** `--scope src/` means ONLY scan `src/`, not "also scan src/".

## Step 8: Write Governance Marker

After producing the report, if the verdict is PASS or WARN (not FAIL):

```bash
python3 ~/.claude/hooks/enforcement/govpass.py write <project_root> sweep-pass
```

This marker is required for Tier 2 (story completion) commits. It is NOT required on every commit — only when the commit message references a story ID (S-NN) or signals story completion.

Do NOT write the marker if verdict is FAIL (critical/high findings remain).
