# Skill Template Examples: From Simple to Advanced

Three real-world skill examples demonstrating the anatomy, complexity tiers, and patterns of effective skills.

---

## Example 1: Simple Single-Purpose Skill

**Skill:** `/commit` — Git commit workflow
**Complexity:** Minimal
**Use Case:** Automation with clear inputs and outputs

```yaml
---
name: Git Commit
description: Stage changes, write a semantically-versioned commit message, and push to the current branch
slash_command: /commit
trigger_pattern: /commit|make a commit|commit these changes|save my work
category: development
version: 1.0.0
---

# Git Commit

## Overview
Streamlines the commit workflow: reads git status, stages relevant files, generates a semantic commit message, and pushes to the current branch. Enforces commit message standards.

## When to Use This Skill
- You've finished a task and want to commit with a descriptive message
- You want consistent, readable commit history without verbosity

## When NOT to Use This Skill
- Rebasing or amending commits (use git directly)
- Merge conflicts (resolve manually first)
- Destructive operations (force push, reset)

## How to Use

### Invocation
```
/commit
```

No parameters required. The skill reads the current git state and guides you through the process.

## Workflow

### Step 1: Check Status
Reads `git status` to see all modified and untracked files.

### Step 2: Propose Files to Stage
Lists files with a recommendation:
- **Auto-stage:** Files changed in existing commits on this branch
- **Ask:** New files or files outside the main task scope
- **Skip:** Generated files, `.env`, `node_modules/`, etc.

### Step 3: Generate Commit Message
Based on the staged files and git diff, proposes a commit message in the format:

```
[type]: [short summary]

[optional details about what changed and why]
```

Semantic types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

### Step 4: Push
Runs `git push origin [current-branch]` and reports success.

## Output
- Clean commit message in the repository history
- Changes pushed to the remote branch
- Confirmation in the terminal

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| "Nothing to commit" | No staged changes or all files were skipped | Review git status; stage files manually if needed |
| "Authentication failed" | SSH key not configured or expired | Check `git config user.email` and SSH key setup |
| "Branch not tracking upstream" | First push on a new branch | Run `git push -u origin [branch-name]` manually |

## Examples

### Example 1: Fixing a Bug
User invokes `/commit` after fixing a database query bug.

Staged files: `src/api/queries.ts`, `test/queries.test.ts`

Generated message:
```
fix: correct SQL join in user-profile query

The JOIN condition was comparing incorrect columns, causing
null results for multi-region users. Fixed to use user_id and region_id.
```

Result: Commit is created and pushed.

### Example 2: Adding a Feature
User invokes `/commit` after implementing a new API endpoint.

Staged files: `src/api/endpoints.ts`, `src/handlers/auth.ts`, `docs/API.md`

Generated message:
```
feat: add /verify-email endpoint for email validation flow

Implements POST /verify-email to validate JWT tokens and confirm
user ownership of email addresses. Returns 200 on success, 401 on invalid token.
```

Result: Commit is created and pushed.
```

---

## Example 2: Intermediate Workflow Skill

**Skill:** `/qa-verify T-01` — QA verification
**Complexity:** Moderate
**Use Case:** Multi-step process with branching logic and decision gates

```yaml
---
name: QA Verify
description: Execute full QA verification against SPEC.md Section 6 criteria with documented evidence
slash_command: /qa-verify
trigger_pattern: /qa-verify|run QA|verify T-|check if T-|QA Tester: VERIFY
category: quality
version: 1.0.0
---

# QA Verify

## Overview
Executes the complete QA verification protocol: identifies the QA toolchain, reads acceptance criteria, tests each criterion, documents evidence, performs a regression scan, checks standards prerequisites, then issues a structured PASS or REJECT.

No task moves to Done without this skill running and returning PASS.

## When to Use This Skill
- A Lead Developer Handoff Note has been written in SPRINT.md
- SPEC.md Section 6 (Definition of Done) has testable criteria
- You need documented evidence that the feature works

## When NOT to Use This Skill
- SPEC.md Section 6 is missing or vague (clarify first)
- The QA Toolchain is not declared in the Tech Selection Record (block and notify Lead Developer)
- Code is incomplete or the task is still in progress

## Prerequisites

| Prerequisite | Status | Where to Find |
|--------------|--------|---------------|
| SPEC.md Section 6 | Required | `[project-root]/SPEC.md` |
| Tech Selection Record with QA Toolchain | Required | `[project-root]/SPRINT.md` |
| Handoff Note from Lead Developer | Required | `[project-root]/SPRINT.md` (under the task) |

## How to Use

### Invocation
```
/qa-verify T-01
```

Or if no specific task:
```
/qa-verify
```

The skill will ask which task to verify.

## Workflow

### Step 1: Load Context
1. Read SPRINT.md to find the Handoff Note
2. Read the Tech Selection Record to identify the QA Toolchain
3. Stop if QA Toolchain is missing — report to Lead Developer

### Step 2: Read SPEC.md Section 6
1. Load SPEC.md Section 6 (Definition of Done checklist)
2. For each criterion, confirm it is testable:
   - Can you execute an action and observe a result?
   - Can you produce clear PASS or FAIL?
   - Is the criterion specific enough?
3. If ambiguous, stop and ask Product Architect for clarification

### Step 3: Execute Each Criterion
For each criterion in Section 6:

1. **Choose test method:**
   - Terminal: Run CLI commands (e.g., `npm test`, `curl`)
   - Visual: Interact with the UI and observe
   - API: HTTP GET/POST to endpoints
   - Browser: Load and interact with the page

2. **Produce evidence:**
   ```
   Criterion: [exact text from SPEC.md Section 6]
   Status: PASS | FAIL
   Evidence:
     Method: [terminal / visual / api / browser]
     [Exact command + output / observed state / response code + body]
   ```

3. **On FAIL:** Note the failure and proceed to all criteria before issuing REJECT

### Step 4: Regression Quick-Scan
1. Identify all tasks in the Done section of SPRINT.md
2. For each Done task, run ONE representative check:
   - Quickest action that would reveal a break
   - E.g., load the feature, check it doesn't error
3. Log any regressions as `T-[current]-REG` in SPRINT.md

### Step 5: Standards Prerequisites Check
Confirm three prerequisites before issuing QA PASS:

**Prerequisite 1: Security Officer Clearance**
- Look in SPRINT.md for a Security Officer sign-off on this task
- If missing, flag BLOCKED

**Prerequisite 2: Storyteller UUID**
- If a new resource was created this task, confirm it appears in `~/.claude/LIBRARY.md` Table 1
- If missing, flag BLOCKED

**Prerequisite 3: Lint Gate**
- Check the Handoff Note for `Lint Result: PASS`
- If missing or FAIL, flag BLOCKED

### Step 6: Issue REJECT or PASS Signal

**If any FAIL, BLOCKED, or standards check fails:**
```
QA REJECT — T-[N] — [YYYY-MM-DD]
Reported To: Project Manager
Failing Criterion: [exact text from SPEC.md Section 6]
Status: FAIL | BLOCKED
Evidence: [what you observed]
Block Reason: [what must be fixed]
```

**If all PASS and prerequisites confirmed:**
```
QA PASS — T-[N] — [YYYY-MM-DD]
Criteria Verified:
  - [x] [Criterion 1] — Evidence: [method + summary]
Regression Scan: CLEAN | [N] issues logged
Security Clearance: confirmed | N/A
Storyteller UUID: [resource_id] | N/A
Lint Gate: PASS | N/A
```

## Output Artifacts
- `[project-root]/SPRINT.md` updated with QA PASS or REJECT
- Any regression tasks logged as `T-[N]-REG`
- Evidence documentation saved to task Handoff Note section

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| QA Toolchain not found | Lead Developer did not declare it in Tech Selection Record | Notify PM, who notifies LD to add it |
| Criterion is ambiguous | SPEC.md Section 6 criterion is vague | Ask Product Architect for clarification |
| Test fails in QA but worked in dev | Environment difference (staged vs. local) | Run test in the exact environment the end user will use |
| Regression found in prior task | Change in current task broke previously-passing feature | Log as `T-[current]-REG` and escalate to PM |

## Examples

### Example 1: Simple API Endpoint Verification
Task: T-05 — Implement POST /users endpoint

Criteria from SPEC.md Section 6:
- [ ] POST /users accepts JSON with name and email
- [ ] Returns 201 + created user object
- [ ] Email validation rejects invalid formats

**Step 3 Execution:**

```
Criterion 1: POST /users accepts JSON with name and email
Status: PASS
Evidence:
  Method: API
  Command: curl -X POST http://localhost:3000/users \
    -H "Content-Type: application/json" \
    -d '{"name":"Alice","email":"alice@example.com"}'
  Response: 201 {"id":"uuid","name":"Alice","email":"alice@example.com"}
```

```
Criterion 2: Returns 201 + created user object
Status: PASS
Evidence: [Same as above — 201 status + full object returned]
```

```
Criterion 3: Email validation rejects invalid formats
Status: PASS
Evidence:
  Method: API
  Command: curl -X POST http://localhost:3000/users \
    -d '{"name":"Bob","email":"invalid-email"}'
  Response: 400 {"error":"Invalid email format"}
```

Result: All pass → QA PASS issued

### Example 2: UI Feature with Regression
Task: T-10 — Add dark mode toggle

Criteria:
- [ ] Toggle button appears in header
- [ ] Clicking toggle switches theme
- [ ] Theme preference persists across refresh

**Step 4 Regression Scan:**
- Check T-05 (Users endpoint): load /users page → works ✓
- Check T-08 (Auth flow): login flow → works ✓
- Check T-09 (Sidebar): sidebar renders → REGRESSION: sidebar is missing icons

Result: T-10 regressions logged as T-10-REG, QA REJECT issued until regressions resolved
```

---

## Example 3: Advanced Agent Skill

**Skill:** `/team-fullstack` — Full development cycle
**Complexity:** High
**Use Case:** Orchestrates multiple agents across the complete software development lifecycle

```yaml
---
name: Full-Stack Development Team
description: Assemble and sequence the complete development team through implementation, QA, and Done
slash_command: /team-fullstack
trigger_pattern: /team-fullstack|run the full team|full development cycle|start building
category: orchestration
version: 1.0.0
---

# Full-Stack Development Team

## Overview
Activates the complete development pod in the correct sequence: Project Manager prepares SPRINT.md, Lead Developer dispatches tasks to specialists, QA Tester verifies each task, and Storyteller logs new resources. Ends with all tasks marked Done.

This skill orchestrates an entire sprint from approved SPEC.md through shipping.

## When to Use This Skill
- SPEC.md is approved and ready for development
- You want to move from "what we're building" to "what we shipped"
- All roles should work together in sequence

## When NOT to Use This Skill
- SPEC.md is not yet approved (use `/product-brief` first)
- You want rapid prototyping without QA (use `/team-mvp`)
- Only discovery is needed (use `/team-discovery`)

## Prerequisites

| Prerequisite | Status |
|--------------|--------|
| SPEC.md created and approved | Required |
| Definition of Done (Section 6) signed off by Founder | Required |
| Active project team assembled | Required |

## Workflow

### Phase 1: Sprint Planning
1. Lead Developer reads SPEC.md
2. Project Manager decomposes into Atomic Tasks
3. Writes SPRINT.md with Tech Selection Record
4. Founder approves task breakdown

### Phase 2: Implementation
For each Atomic Task:
1. Lead Developer classifies task (FE / BE / FS)
2. Dispatches to appropriate specialist(s)
3. Specialist implements and passes lint gate
4. Lead Developer reviews output and writes Handoff Note

### Phase 3: Quality Verification
For each completed task:
1. Security Officer reviews code
2. QA Tester verifies all Section 6 criteria
3. QA issues PASS or REJECT
4. On REJECT: task returns to specialist for fixes + re-verification

### Phase 4: Resource Logging
When a new resource is created:
1. Storyteller generates UUID and logs to LIBRARY.md
2. Confirms UUID with task completion

### Phase 5: Done
When all tasks have QA PASS:
1. All Section 6 criteria verified
2. All security reviews passed
3. All resources logged
4. Feature is ready to deploy

## Output Artifacts
- Updated `[project-root]/SPRINT.md` with completed tasks
- All task Handoff Notes documented
- QA PASS for every completed task
- All new resources logged in `~/.claude/LIBRARY.md`
- Feature ready for `/deploy`

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| QA REJECT on first attempt | Implementation doesn't fully satisfy Section 6 | Return to specialist, fix criterion, re-verify |
| Blocking dependency between tasks | Task A can't start until Task B is done | Reorder in SPRINT.md; document dependency |
| Security Officer finds vulnerability | Code has exploitable pattern or exposed secrets | Fix code, re-review, document in error-records |
| Feature works in staging but fails in QA | Environmental difference | Run QA in the exact staging environment |

## Examples

### Example 1: Feature Development (2 tasks)
SPEC.md describes a new "Save as Template" feature.

**SPRINT.md Tasks:**
- T-01: Backend — Create templates table and POST /templates endpoint
- T-02: Frontend — Add save button and form component

**Phase 1:** Sprint Planning
- LD reads SPEC.md Section 1 (functional reqs) and Section 3 (visual)
- PM decomposes into T-01, T-02 with dependencies
- SPRINT.md written, Founder approves

**Phase 2:** Implementation
- T-01: BE Dev implements endpoint, lint passes
- LD reviews BE code, writes Handoff Note
- T-02: FE Dev implements UI, lint passes
- LD reviews FE code against Section 3, writes Handoff Note

**Phase 3:** QA Verification
- QA Tester verifies T-01 (API returns 201, data saved to DB)
- QA Tester verifies T-02 (button visible, form submits, success message)
- All Section 6 criteria PASS

**Phase 4:** Resource Logging
- No new tables created → Storyteller logs completed template-related resources

**Phase 5:** Done
- Both tasks marked Done in SPRINT.md
- Feature ready for deploy

### Example 2: Feature Development with Complications (3 tasks + regressions)
SPEC.md describes "add OAuth login".

**SPRINT.md Tasks:**
- T-01: Backend — Implement OAuth provider integration
- T-02: Frontend — Add login button and auth callback handler
- T-03: Frontend — Update dashboard to show logged-in user name

**Phase 2:** Implementation
- T-01 & T-02 dispatched in parallel (independent)
- T-03 dispatched after T-02 (depends on auth state)

**Phase 3:** QA Verification
- T-01 QA: Endpoint exchange code for token → PASS
- T-02 QA: Login button clicks, redirects to OAuth provider, callback works → PASS
- T-02 Regression scan: Check existing login form → REGRESSION: existing form now hidden

T-02 returns to FE Dev:
- FE Dev hides OAuth button only when logged in
- Passes lint, writes updated Handoff Note
- QA re-verifies both auth paths → PASS
- T-02-REG logged and resolved

- T-03 QA: Logged-in user sees name in header → PASS

**Phase 5:** Done
- All tasks Done, all criteria PASS, feature ready to deploy
```

---

## Patterns Across Examples

### Pattern 1: Single vs. Multi-Step

- **Simple skill** (`/commit`): One clear workflow, few decision points
- **Intermediate skill** (`/qa-verify`): Multiple steps with gates and branching
- **Advanced skill** (`/team-fullstack`): Orchestrates multiple agents and roles

### Pattern 2: Input/Output Clarity

All skills define:
- **Required inputs:** What must be in place before invoking
- **Workflow steps:** Exact sequence the skill executes
- **Output artifacts:** Concrete deliverables (files, decisions, records)

### Pattern 3: Error Handling

Each skill includes a troubleshooting matrix mapping:
- Symptom → Root cause → Exact fix
- No vague "check the logs" — specifics

### Pattern 4: Examples Close Loop

Each skill's examples trace a task **start-to-finish**, showing:
- How the skill processes inputs
- What decisions were made
- What output was produced

---

## When to Create Each Complexity Tier

| Tier | Use When | Examples |
|------|----------|----------|
| **Simple** | One clear workflow with minimal branching | `/commit`, `/push`, `/build` |
| **Intermediate** | Multi-step process with gates and decisions | `/qa-verify`, `/review`, `/deploy` |
| **Advanced** | Orchestrates multiple agents/roles in sequence | `/team-fullstack`, `/team-deploy`, `/reflect` |

Start with **Simple**. Evolve to **Intermediate** when branching logic appears. Move to **Advanced** only when coordinating multiple agents.
