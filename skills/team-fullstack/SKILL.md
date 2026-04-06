---
name: team-fullstack
description: >
  Use this skill when the user says "/team-fullstack", "run the full team", "full development
  cycle", "start building", "complete sprint cycle", or wants to go from approved SPEC.md all
  the way through implementation, QA, and done in one coordinated sequence. Assembles the
  Full-Stack Development Pod and sequences all roles. Requires an approved SPEC.md.
version: 1.0.0
---

# /team-fullstack — Full-Stack Development Pod

You are coordinating the Full-Stack Development Pod. This team runs Phase 2 + Phase 3 of the lifecycle:
**Approved SPEC.md → task done (Security ✓ + QA ✓ + Storyteller ✓)**.

## Step 0: Load Role Contracts
Before proceeding, read the following role contract(s) using the Read tool:
- `~/.claude/rules/project-manager.md`
- `~/.claude/rules/lead-developer.md`
- `~/.claude/rules/qa-tester.md`

Other specialist contracts (`frontend-dev.md`, `backend-dev.md`) are loaded by `/implement` when tasks are dispatched.

## Pod Composition

| Role | Responsibility in This Pod |
|------|---------------------------|
| Project Manager | Sprint planning → Atomic Task breakdown → SPRINT.md |
| Lead Developer | Tech Selection → task dispatch → review gate → Handoff Note |
| Frontend Developer | UI implementation → accessibility → lint gate |
| Backend Developer | Schema → endpoints → idempotency → lint gate |
| Security Officer | Code scrub on every task with code changes |
| QA Tester | Criterion-by-criterion verification → QA PASS or REJECT |
| Marketing Manager | Marketing Header Standard (public pages) + Brand Voice Audit |
| Storyteller | UUID registration for every new resource |

## Prerequisites

Before this pod runs:
- [ ] `[project-root]/SPEC.md` exists with `Status: approved`
- [ ] Founder has signed off on Section 6 (Definition of Done)
- [ ] If public-facing pages exist: `MARKETING.md` exists (run `/metadata` first if not)

---

## Stage 1: Sprint Planning

Run the Project Manager Sprint Planning ceremony:

1. Read SPEC.md — all 7 sections
2. Decompose Section 1 Functional Requirements into Atomic Tasks:
   - Each task completable in a single session
   - Each task produces exactly one verifiable output
   - Size estimates: S (< 30% context), M (30–60%), L (> 60% — must split before scheduling)
3. Order by dependency: schema → backend → frontend → tests
4. Write SPRINT.md with full task list
5. Present to Founder: "Here are [N] Atomic Tasks. Any adjustments before I hand off to development?"

Wait for Founder approval before proceeding to Stage 2.

---

## Stage 2: Tech Selection (Once Per Project)

Run the Lead Developer Tech Selection:

1. Read SPEC.md Section 4 — identify declared stack or apply defaults:
   | Project Type | Default FE | Default BE |
   |---|---|---|
   | Full-stack web app | TypeScript + React (Next.js 14+) | TypeScript + Node.js + PostgreSQL |
   | Static site | TypeScript + Astro | n/a |
   | Dashboard | TypeScript + React + shadcn/ui | TypeScript + Node.js + PostgreSQL |
   | Rapid prototype | TypeScript + Next.js | TypeScript + Next.js API + Supabase |

2. Declare QA Toolchain:
   | Stack | QA Toolchain |
   |---|---|
   | React/Next.js | Jest + React Testing Library (unit); Playwright (e2e) |
   | Python/FastAPI | pytest |
   | Other | Ask Founder |

3. Confirm with Founder: "Tech stack: [FE + BE + DB]. QA Toolchain: [tools]. Confirmed?"

4. Write Tech Selection Record to SPRINT.md:
   ```
   ### Tech Selection Record — [date]
   FE: [stack + version]
   BE: [runtime + stack + version]
   DB: [engine + version]
   Schema Source of Truth: [path]
   QA Toolchain: [tools]
   Confirmed by: Founder (yes)
   ```

---

## Stage 3: Per-Task Execution Loop

For each Atomic Task in SPRINT.md (in dependency order):

### 3-pre: README.md Gate (First Task Only)

Before dispatching the first Atomic Task, verify:

```bash
test -f [project-root]/README.md && echo "EXISTS" || echo "MISSING"
```

- **EXISTS** — proceed to 3a.
- **MISSING** — STOP. Before any task dispatch, the Lead Developer must create `README.md` per Lead Developer SOP 5 (`rules/lead-developer.md`). This is an infrastructure prerequisite, not a SPRINT.md task. Resume the task loop only after README.md is committed.

This gate runs once per sprint. After the first task passes it, subsequent tasks skip this check.

### 3a: Check Context Budget
Run `/usage`. If ≥ 70%: "Context at [X]%. Running `/compact` before starting T-[N]."

### 3b: Marketing Header Gate (FE tasks with public pages only)
Confirm MARKETING.md exists. If not: run `/metadata` first. Stop dispatch until complete.

### 3c: Classify and Dispatch

**Feature Forge gate:** If Tech Selection Record contains `Forge Mode: auto` and task is size M,
route to `/feature-forge T-[N]` instead of direct dispatch. Feature Forge handles the full
classify → dispatch → evaluate → select → handoff cycle internally. Skip to Stage 3e after
Feature Forge returns.

If Feature Forge is not active, classify the task:
- FE only → invoke Frontend Developer
- BE only → invoke Backend Developer
- Full-stack → Backend first, then Frontend
- Independent parallel → both simultaneously

**TDD Gate:** After classification, apply TDD classification per Lead Developer SOP 2 Step 1b.
When TDD is required, the specialist executes this enforced sequence:

1. **Write the test file** for the task's expected behavior.
2. **Verify red** — run the gate script via Bash tool:
   ```bash
   bash ~/.claude/hooks/enforcement/tdd-gate.sh verify-red "<test_command>"
   ```
   This MUST exit 0 (meaning the test failed as expected). If it exits 1 (test passed prematurely), stop — the test is not testing new behavior.

3. **Implement** the minimum code to satisfy the test.
4. **Verify green** — run the gate script via Bash tool:
   ```bash
   bash ~/.claude/hooks/enforcement/tdd-gate.sh verify-green "<test_command>"
   ```
   This MUST exit 0 (meaning the test now passes). If it exits 1, the implementation is incomplete.

5. **Record in Handoff Note:** test file path, red gate output, green gate output.

If TDD is not required (pure UI/config/docs per Step 1b): skip this gate. When in doubt, require TDD — false positives waste less time than untested logic bugs caught only in QA.

**Frontend Developer** (FE tasks):
- Read SPEC.md Section 3 first — trace every component to a Section 3 statement
- Apply WCAG 2.1 AA accessibility
- TypeScript strict: no `any`; explicit prop interfaces
- Run `npm run lint` → exit 0, 0 errors
- Return file list + lint result

**Backend Developer** (BE tasks):
- Declare Schema Source of Truth first
- Update schema before writing queries
- FK constraints + FK indexes; multi-table writes in transactions
- Input validation (Zod/Joi); consistent error shape; no raw DB errors to client
- UUID PKs via `gen_random_uuid()` or equivalent
- Run lint gate → exit 0, 0 errors
- Return file list + schema change flag + lint result

### 3d: Lead Developer Review
Verify specialist output against SPEC.md:
- FE traces to Section 3 ✓
- BE traces to Section 1 + schema ✓
- Lint PASS confirmed ✓

If output doesn't trace: return to specialist with specific criterion.

Write Handoff Note to SPRINT.md:
```
#### Handoff Note — T-[N] — [date]
Specialist(s): [FE / BE / both]
Modified Files:
  - [path] — [created / modified]
Lint Result: PASS (0 errors, [N] warnings)
SPEC.md Section 6 Criteria Covered:
  - [ ] [criterion]
Notes for QA: [edge cases, env requirements]
```

### 3e: Security Scrub
Trigger: `Security Officer: REVIEW — T-[N]`

Security Officer checks:
- No hardcoded secrets (API keys, passwords, tokens)
- `.env` in `.gitignore`
- No raw DB errors in API responses
- No un-sanitized external input reaching processing
- Supply chain check for any new packages

Returns: "No issues found" or blocking finding.

### 3f: Brand Voice Audit (FE tasks with UI text only)
Trigger: `Marketing Manager: VOICE-AUDIT — T-[N]`

Checks all UI-facing text against B2B or B2C voice standard. Returns PASS or FLAG.

### 3g: QA Verification
Trigger: `QA Tester: VERIFY — T-[N] against SPEC.md Section 6 criteria [IDs]`

QA Tester:
- Reads toolchain from SPRINT.md Tech Selection Record
- Executes each criterion (no verbal confirmation accepted — evidence required)
- Runs regression quick-scan on Done tasks
- Confirms Security scrub + Storyteller UUID + Lint gate

Returns: QA PASS or REJECT with structured repro steps.

### 3h: Storyteller Registration (if new resource created)
Trigger: `Storyteller: ON CREATE — [resource name]`

Storyteller generates UUID via `uuidgen | tr '[:upper:]' '[:lower:]'`, registers in LIBRARY.md.

### 3i: Close the Task
All three gates confirmed:
- [ ] Security: confirmed or N/A
- [ ] QA PASS: received
- [ ] Storyteller UUID: logged or N/A

Move task to Done in SPRINT.md with date.

---

## Stage 4: Sprint Summary

After all tasks are Done (or end of session):

Write Sprint Summary to SPRINT.md:
```
## Sprint Summary — [date]

### Completed
- T-[N]: [description] → [output link]

### Pending
- T-[N]: [description] → [next step or blocker]

### New Resources (UUIDs)
- [name] ([resource_id])

### Context Usage
- Peak: [X]% | Action taken: [compact at Y% / none]

### Blockers
- [description] → Assigned to: [role]
```

Closing statement:
- **Green:** "Sprint on track. Next session: [T-N]."
- **Yellow:** "Blocked on [item]. Founder decision needed before [T-N]."
- **Red:** "DoD failure on [task]. Recovery: [action]."
