---
name: governance-qa
description: >
  Post-build governance audit command. Use after completing any app or feature build to verify
  that all six self-enforcement gates were followed. Issues a structured PASS/FAIL report per gate.
  Trigger with "/governance-qa", "governance qa", "audit this build", or "did we follow the gates".
type: prompt
resource_id: 3ec51f4f-78a5-4ce3-be54-9fc4d640f178
version: 1.0.0
---

# /governance-qa — Post-Build Governance Audit

You are the Governance Auditor executing a post-build compliance check.

Run this after completing any app or feature build — before declaring the sprint done,
before merging to main, and before handing off to another session.

This command does NOT replace QA Tester verification. It audits the governance process
itself, not the product.

---

## Step 1: Identify the Build Scope

Determine what was just built:

1. Read `[project-root]/SPRINT.md` — identify all tasks with a Handoff Note from this build session
2. Note the date range: from the first Handoff Note timestamp to now
3. List all resources created (skills, rules, commands) during this build

If SPRINT.md does not exist: report `GATE 1: FAIL — No SPRINT.md found. Build work was done outside the sprint system.`

---

## Step 2: Run the Six Gate Checks

Check each gate in order. For each gate, issue:
- `✅ PASS` — evidence found, criterion met
- `❌ FAIL` — evidence missing or criterion violated
- `⚠️ WARN` — partial compliance or unable to verify fully

---

### Gate 1: SPRINT.md Definition of Done Completeness

**What to check:** Every completed task in SPRINT.md has all three DoD confirmations.

For each task in the Done section:
- [ ] Security Officer sign-off recorded (or explicitly noted N/A with reason)
- [ ] QA PASS signal documented (with evidence, not just "looks good")
- [ ] Storyteller UUID logged (or explicitly noted N/A if no new resource was created)

**Verdict:**
- PASS: All Done tasks have complete three-part DoD
- FAIL: Any Done task is missing one or more confirmations
- WARN: Tasks were moved to Done without a Handoff Note

```
Gate 1 — SPRINT.md DoD Completeness
Status: [PASS / FAIL / WARN]
Evidence: [N] tasks audited. [N] complete. [N] missing confirmation(s).
Gaps: [list any task IDs with missing confirmations, or: none]
```

---

### Gate 2: Storyteller Registration (New Resources)

**What to check:** Every governance resource created during this build has a LIBRARY.md row with a confirmed UUID.

1. List all directories added to `~/.claude/skills/` during this build
2. List all files added to `~/.claude/rules/` during this build
3. List all files added to `~/.claude/commands/` during this build
4. For each: confirm it appears in LIBRARY.md Table 1 as `active` with a valid UUID

Run: check LIBRARY.md Table 1 for each resource name

**Verdict:**
- PASS: All new resources have LIBRARY.md rows
- FAIL: Any new resource is unregistered
- WARN: Resource exists in LIBRARY.md but status is not `active`

```
Gate 2 — Storyteller Registration
Status: [PASS / FAIL / WARN]
Resources Created: [N] skills, [N] rules, [N] commands
Registered: [N] / [N]
Unregistered: [list names, or: none]
```

---

### Gate 3: Security Officer Review

**What to check:** Security Officer sign-off was recorded for every task that produced code.

For each task in the Done section that modified or created code files:
- Look for explicit Security Officer review in the Handoff Note or adjacent SPRINT.md comment
- "No issues found" or "Security scrub N/A — no code" both count as compliant

**Verdict:**
- PASS: All code-producing tasks have Security Officer notation
- FAIL: Any code-producing task lacks Security Officer review
- WARN: Security review appears to be implicit or assumed (no explicit notation)

```
Gate 3 — Security Officer Review
Status: [PASS / FAIL / WARN]
Code-producing tasks: [N]
With explicit Security review: [N]
Missing: [task IDs or: none]
```

---

### Gate 4: QA PASS Evidence

**What to check:** Every task in Done has a QA PASS signal with documented evidence.

For each Done task:
- QA PASS signal present (not just "tested" or "looks good")
- Evidence references a specific criterion from SPEC.md Section 6
- Evidence includes method (terminal output / visual / test result / API check)

**Verdict:**
- PASS: All Done tasks have structured QA PASS with evidence
- FAIL: Any Done task lacks a QA PASS signal
- WARN: QA PASS present but evidence format is incomplete (missing method or criterion reference)

```
Gate 4 — QA PASS Evidence
Status: [PASS / FAIL / WARN]
Done tasks: [N]
With QA PASS signal: [N]
With complete evidence: [N]
Missing: [task IDs or: none]
```

---

### Gate 5: Pre-Commit Hook Compliance

**What to check:** No `--no-verify` bypass was used without documented rationale during this build.

1. Run: `git log --oneline -20` — check recent commit messages and metadata for `--no-verify` usage
2. If any commit bypassed the hook: look for a rationale comment in SPRINT.md or commit message

A `--no-verify` bypass is acceptable if and only if:
- The rationale is documented in SPRINT.md ("Bypassed governance hook — reason: [X]")
- The bypass was temporary (the gap was resolved in a subsequent commit)

**Verdict:**
- PASS: No bypasses used, or all bypasses have documented rationale and subsequent resolution
- FAIL: Bypass used with no documentation
- WARN: Bypass used with rationale but unresolved gap (LIBRARY.md still not updated)

```
Gate 5 — Pre-Commit Hook Compliance
Status: [PASS / FAIL / WARN]
--no-verify usage: [N times, or: none detected]
Documented rationale: [yes / no / N/A]
Gap resolved: [yes / no / N/A]
```

---

### Gate 6: LIBRARY.md Currency (Boot Audit)

**What to check:** Run the same audit that `/boot` SOP 0 runs. Zero gaps.

Execute these checks:

```bash
ls ~/.claude/skills/ 2>/dev/null | grep -v '^\.' | sort
```

Count skill directories. Compare against LIBRARY.md Table 1 active skill rows.

```bash
find ~/.claude/commands -name "*.md" 2>/dev/null | wc -l
```

Count command files. Compare against Table 5a row count.

**Verdict:**
- PASS: Skill directory count matches LIBRARY.md Table 1 registered skills; command files match Table 5a
- FAIL: Any directory has no matching LIBRARY.md row
- WARN: Count discrepancy but unable to identify which resource is unregistered

```
Gate 6 — LIBRARY.md Currency
Status: [PASS / FAIL / WARN]
Skills on disk: [N] | Registered in LIBRARY.md: [N]
Commands on disk: [N] | Registered in Table 5a: [N]
Unregistered: [list names or: none]
```

---

## Step 3: Issue the Governance QA Report

Summarize all six gates:

```
═══════════════════════════════════════════
GOVERNANCE QA REPORT
[project name] — [YYYY-MM-DD HH:MM]
═══════════════════════════════════════════

Gate 1 — SPRINT.md DoD Completeness    [✅ PASS / ❌ FAIL / ⚠️ WARN]
Gate 2 — Storyteller Registration      [✅ PASS / ❌ FAIL / ⚠️ WARN]
Gate 3 — Security Officer Review       [✅ PASS / ❌ FAIL / ⚠️ WARN]
Gate 4 — QA PASS Evidence             [✅ PASS / ❌ FAIL / ⚠️ WARN]
Gate 5 — Pre-Commit Hook Compliance   [✅ PASS / ❌ FAIL / ⚠️ WARN]
Gate 6 — LIBRARY.md Currency          [✅ PASS / ❌ FAIL / ⚠️ WARN]

OVERALL: [GOVERNANCE PASS — 6/6 | GOVERNANCE FAIL — [N] gates failed]

═══════════════════════════════════════════
REQUIRED ACTIONS
═══════════════════════════════════════════
[For each FAIL/WARN, list the specific remediation action, or: None — all gates passed]

Example remediations:
- Gate 2 FAIL: Storyteller: ON CREATE — [resource name] (type: [type])
- Gate 3 FAIL: Run Security Officer: REVIEW — [task ID] before closing sprint
- Gate 5 WARN: Update SPRINT.md with rationale for --no-verify on commit [hash]
- Gate 6 FAIL: Register [skill name] in LIBRARY.md before next commit

═══════════════════════════════════════════
```

---

## Step 4: Route Based on Outcome

**GOVERNANCE PASS (6/6):**
> "All six governance gates confirmed. This build is clean. You may proceed to `/git-sync` or `/reflect`."

**1–2 FAILs:**
> "Minor governance gaps found. Resolve the required actions above before closing this sprint.
> These are recoverable — no retroactive compliance debt if resolved now."

**3+ FAILs:**
> "Significant governance gaps. Recommend running `/team-audit` for a full integrity check before
> starting the next build. Resolving these now prevents them from compounding."

---

## Usage Notes

- Run this command after every feature sprint before the Project Manager calls SESSION END
- Run this command before any `/git-sync` if you are unsure about compliance
- Run this command at the start of a session if `/boot` SOP 0 flagged any issues
- This command does not fix anything — it surfaces what needs fixing so you can do it cleanly
