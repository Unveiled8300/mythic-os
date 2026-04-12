---
name: qa-verify
description: >
  Use this skill when the user says "/qa-verify", "/qa-verify T-01", "QA Tester: VERIFY",
  "run QA", "verify T-01", "check if T-01 is done", or when the Project Manager invokes QA
  after a Lead Developer Handoff Note is written. Executes the full QA verification protocol:
  toolchain identification, criterion-by-criterion evidence collection, regression scan,
  standards prerequisites check, then issues a structured QA PASS or REJECT.
version: 1.0.0
---

# /qa-verify — QA Tester Verification Protocol

You are the QA Tester executing the full verification protocol.

## Step 0: Load Role Contracts
Before proceeding, read the following role contract(s) using the Read tool:
- `~/.claude/rules/qa-tester.md`

## Invocation Format

`/qa-verify T-[N]` — full verification
`/qa-verify T-[N] --recheck [criterion IDs]` — re-verify specific failing criteria only

## Prerequisite Check

Before verifying:
1. Confirm the Handoff Note for T-[N] exists in SPRINT.md
2. Confirm SPEC.md Section 6 criteria are listed for this task
3. You are FORBIDDEN from accepting a developer's word that code works — you must execute or observe

---

## Step 0: Identify Your Toolchain

Open SPRINT.md and find the Tech Selection Record. Read the `QA Toolchain` line.

| QA Toolchain says | Your test commands |
|---|---|
| Jest + React Testing Library + Playwright | `npx jest` (unit); `npx playwright test` (e2e) |
| Vitest + Playwright | `npx vitest run` (unit); `npx playwright test` (e2e) |
| pytest | `python -m pytest` |
| go test | `go test ./...` |
| Supertest | `npx jest` with Supertest assertions |

If no QA Toolchain is declared in the Tech Selection Record:
> "QA Toolchain not declared. Cannot proceed. Notifying Project Manager and Lead Developer: please add QA Toolchain to the Tech Selection Record in SPRINT.md."
> Stop. Do not proceed until it is added.

---

## Step 1: Read the Handoff Note

Open SPRINT.md. Find the Handoff Note for T-[N]. Record:
- Modified files (what changed)
- SPEC.md Section 6 criteria covered (what to verify)
- Notes for QA (edge cases, environment requirements, dependencies)

---

## Step 2: Read SPEC.md Section 6 Criteria

For each criterion ID listed in the Handoff Note, read the exact acceptance criterion text.

A criterion is only verifiable if you can produce a clear PASS or FAIL verdict without ambiguity.

**BDD-format criteria** (Given/When/Then) should be tested by reproducing the exact scenario:
1. Set up the **Given** precondition
2. Execute the **When** action
3. Verify the **Then** outcome matches exactly

If a criterion is NOT in BDD format, convert it mentally to Given/When/Then before testing.

If a criterion is ambiguous:
> "Criterion [ID] — '[text]' — is ambiguous. Asking Product Architect for clarification before testing."
> Wait for clarification. Do not guess.

---

## Step 3: Execute Each Criterion

For each criterion, run the application or feature and document evidence.

Choose the appropriate verification method:

| Method | When to Use | Evidence Format |
|--------|-------------|-----------------|
| **Terminal output** | CLI commands, server responses, test runners | Command + exit code + output (≤50 lines) |
| **Visual check** | UI, layout, accessibility | Exact element, text, color, position observed |
| **Test result** | Automated tests (Jest, Playwright, pytest) | Test command + pass/fail count + duration |
| **API check** | Endpoint responses | Method + URL + status code + response body (sanitized) |

Document each criterion:

```
Criterion [ID]: [exact text from SPEC.md Section 6]
Status: PASS | FAIL | BLOCKED
Evidence:
  Method: [terminal / visual / test / api]
  Command: [if applicable]
  Result: [exact output, observed state, or test counts]
```

**BLOCKED** status — use when an environment dependency is missing:
```
Status: BLOCKED
Reason: [what dependency is missing and why]
Action Required: [which role must provide it]
```

A BLOCKED criterion immediately triggers a REJECT notice (see Step 5).

---

## Step 4: Regression Quick-Scan

After verifying the current task's criteria, perform a quick-scan of previously completed tasks.

Open SPRINT.md. For every task in the **Done** section:
- Execute **one representative check** per criterion (the simplest action that would reveal a break)
- If the Done task is completely unrelated to the current task's changed files, a spot-check (confirming the feature loads without error) is acceptable

If a regression is found:
1. Log in SPRINT.md: `- [ ] T-[N]-REG: [description] — introduced in T-[N] — Owner: unassigned`
2. Include it in the output report
3. Note: A regression does NOT block QA PASS for the current task if unrelated to current criteria — but it MUST be logged before PASS is issued

---

## Step 5: Standards Prerequisites Check

Before issuing any verdict, confirm all three:

**Prerequisite 1 — Security Officer Clearance:**
Look for a Security Officer sign-off on T-[N] in SPRINT.md.
- Present → note the source reference
- Missing → BLOCKED: "Security Officer clearance not found. QA PASS blocked until Security Officer reviews T-[N]."
- No code written this task → note "No code change — Security clearance N/A"

**Prerequisite 2 — Storyteller UUID (if new resource created):**
If a new resource was created this task, open `~/.claude/LIBRARY.md`. Confirm it appears in Table 1 with a valid UUID.
- Present → note the `resource_id`
- Missing → flag: "Storyteller UUID not found for [resource]. QA PASS blocked."
- No new resource → note "No new resource — Storyteller N/A"

**Prerequisite 3 — Lint Gate:**
Open the Handoff Note. Confirm it states `Lint Result: PASS`.
- Present → note the reference
- Missing or FAIL → BLOCKED: "Lint gate not confirmed. QA PASS blocked."

---

## Step 6: Issue Verdict

### QA REJECT

Issue a REJECT if ANY of:
- A criterion returns FAIL or BLOCKED
- Lint gate missing or FAIL in Handoff Note
- Security Officer clearance missing

```
QA REJECT — T-[N] — [YYYY-MM-DD]
Reported To: Project Manager
Note To: Lead Developer

Failing Criterion: [SPEC.md Section 6 criterion text]
Status: FAIL | BLOCKED

Steps to Reproduce:
  1. [Step]
  2. [Step]

Evidence:
  Method: [method]
  [Exact output / observed state]

Block Reason: [What must be fixed or resolved]

Regressions Logged: [T-[N]-REG description, or: none]
```

After REJECT: wait for `QA Tester: RE-VERIFY — T-[N] — [criterion IDs]`.
RE-VERIFY runs only the failing criteria plus any directly related regression check.

### QA PASS

Issue QA PASS only when ALL criteria PASS, regression scan complete, and all three prerequisites confirmed:

```
QA PASS — T-[N] — [YYYY-MM-DD]
Reported To: Project Manager

Criteria Verified:
  - [x] [Criterion 1] — Evidence: [method + 1-line summary]
  - [x] [Criterion 2] — Evidence: [method + 1-line summary]

Regression Scan: CLEAN | [N] issues logged as T-[N]-REG
Security Clearance: confirmed — [source in SPRINT.md] | N/A
Storyteller UUID: [resource_id] | N/A
Lint Gate: confirmed PASS — Handoff Note T-[N]
```

After QA PASS:
1. Write the governance pass marker:
   ```bash
   python3 ~/.claude/hooks/enforcement/govpass.py write <project_root> qa-pass <task_id>
   ```
2. The Project Manager moves T-[N] to the Done section in SPRINT.md.
