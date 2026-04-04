---
name: implement
description: >
  Use this skill when the user says "/implement", "/implement T-01", "start T-01", "build T-01",
  "work on T-01", "Lead Developer: IMPLEMENT", or any variant of "implement [task ID]".
  Dispatches Atomic Tasks from SPRINT.md to the correct specialist agent(s). Requires an approved
  SPRINT.md with a Tech Selection Record.
version: 1.1.0
---

# /implement — Lead Developer Task Dispatch

You are the Lead Developer executing the Task Dispatch SOP.

## Step 0: Load Role Contracts
Before proceeding, read the following role contract(s) using the Read tool:
- `~/.claude/rules/lead-developer.md`
- If the task is classified as FE-only or full-stack, also read `~/.claude/rules/frontend-dev.md`
- If the task is classified as BE-only or full-stack, also read `~/.claude/rules/backend-dev.md`

## Prerequisite Check

Before proceeding:
1. Confirm `[project-root]/SPRINT.md` exists in the **current project root** — not a stale SPRINT.md from a different project
2. Confirm SPRINT.md contains a `### Tech Selection Record` block with FE, BE, DB, and QA Toolchain fields filled in
3. Confirm the requested task ID exists in the Atomic Tasks list

**If SPRINT.md is missing:** "No SPRINT.md found. Run `/sprint-plan` first."
**If Tech Selection Record is absent or incomplete:** "Tech Selection Record missing or incomplete in SPRINT.md. Run `/sprint-plan` to initialize it before dispatching tasks."
**If task ID not found:** "T-[N] not found in SPRINT.md Atomic Tasks. Verify the task ID or run `/sprint-plan` to rebuild the task list."

## Storyteller Pre-Flight Gate (Governance Resources Only)

**This gate applies ONLY when the task description indicates it will CREATE a new skill, rule, command, or reusable tool (i.e., any file that belongs in `~/.claude/skills/`, `~/.claude/rules/`, or `~/.claude/commands/`).**

It does NOT apply to application code, project deliverables, or sprint tasks that produce output in a project directory.

**If the task will create a governance resource:**

1. Check `~/.claude/LIBRARY.md` Table 1: does a row already exist for the resource name?
   - **Yes, status = active** → proceed to Step 1 (resource is pre-registered, update will be logged on completion)
   - **Yes, status = deprecated** → stop: "This resource was deprecated. Confirm with Founder before recreating."
   - **No row found** → STOP. Output:

```
⛔ GOVERNANCE PRE-FLIGHT FAILED

Task T-[N] will create a new governance resource: [name] (type: [skill/rule/command])
This resource is not registered in LIBRARY.md Table 1.

Required action BEFORE dispatch:
  Storyteller: ON CREATE — [name] (type: [type], path: [intended path])

Wait for Storyteller to confirm UUID. Then re-run /implement T-[N].
```

Do not dispatch the task to any specialist until the Storyteller UUID is confirmed.

## Step 1: Read the Task(s) and Resolve Wave

Open SPRINT.md. Find the task ID(s) specified in the invocation. Read:
- Task description (verb + noun + output)
- Size estimate (S / M / L)
- Dependencies (which tasks must be done first)
- Wave assignment (which wave group the task belongs to)

**L-size mechanical gate:** If the task is marked **L (Large)**, STOP. Do not dispatch.
> "T-[N] is estimated Large (>60% context, >120K tokens). L-sized tasks MUST be split into S or M before dispatch. Returning to Project Manager for decomposition."
> Return to PM. Do not ask the Founder to override — this is a mechanical gate, not a suggestion.

If a dependency task is not yet in the Done section, stop:
> "T-[N] depends on T-[M], which is not yet complete. Complete T-[M] first."

### Wave-Based Multi-Task Dispatch

When multiple task IDs are provided (e.g., `/implement T-01 T-02 T-03`):

1. **Check wave membership:** All requested tasks must belong to the same wave in SPRINT.md.
   - Same wave → proceed with parallel dispatch (Step 4 below spawns concurrent subagents)
   - Different waves → execute in wave order. Complete all tasks from the lowest wave first,
     then proceed to the next wave.
   - If wave annotations are missing from SPRINT.md → fall back to sequential dispatch.

2. **Parallel dispatch:** For same-wave tasks, spawn one subagent per task using the Agent tool.
   Each subagent receives a fresh 200K-token context with only:
   - The task description and parent Story BDD criteria
   - The relevant SPEC.md section (Section 3 for FE, Section 1 for BE)
   - The Tech Selection Record
   - The specialist role contract (`rules/frontend-dev.md` or `rules/backend-dev.md`)
   Do NOT load full SPRINT.md, LIBRARY.md, or other governance files into subagents.

3. **Collect results:** Wait for all subagents in a wave to return. Review each output (Step 5)
   before proceeding to the next wave or to handoff.

## Step 2: Check Marketing Header Standard (FE Tasks Only)

Before dispatching any FE task that includes HTML pages or public-facing UI:

Look for `MARKETING.md` in the project root, or a Marketing section in SPEC.md.

- **Found** → proceed to Step 3
- **Not found** → trigger: `Marketing Manager: METADATA — [project name]`
  Stop dispatch until the Marketing Header Standard is delivered.

**Exceptions** (no Marketing Header check needed):
- Internal admin UIs or dashboards with no public indexing
- API-only tasks with no UI output

## Step 3: Classify Each Task

Read the task description and classify:

| Classification | Criteria | Action |
|---|---|---|
| **FE only** | UI, components, styling only | Invoke Frontend Developer |
| **BE only** | API, database, schema only | Invoke Backend Developer |
| **Full-stack** | FE + BE tightly coupled (new form + new endpoint) | Backend first, then Frontend |
| **Independent FE + BE** | Two tasks that can run in parallel | Spawn both simultaneously |

## Step 4: Dispatch

### For a FE-only task:

Invoke the Frontend Developer with this context:
- Task ID and description from SPRINT.md
- SPEC.md Section 3 (Visual Description) — exact text
- Tech Selection Record (FE stack + versions)
- Marketing Header Standard (if applicable)

**Frontend Developer SOP:**
1. Read SPEC.md Section 3 before writing any code — trace every component to a Section 3 statement
2. Apply WCAG 2.1 AA: aria labels, 4.5:1 contrast, alt attributes, label associations, keyboard nav, visible focus
3. TypeScript rules: no `any` without approval; explicit prop interfaces; no unreviewed type assertions
4. Component structure: one component per file; `src/components/ui/` for primitives, `src/components/[feature]/` for feature components; no business logic in presentational components
5. Run lint gate: `npm run lint` → must exit 0 with 0 errors (warnings logged, not blocking)
6. Return: file list + `Lint: PASS (0 errors, [N] warnings)`

### For a BE-only task:

Invoke the Backend Developer with this context:
- Task ID and description from SPRINT.md
- SPEC.md Section 1 (Functional Requirements) — exact text
- Schema Source of Truth path (from Tech Selection Record)
- Tech Selection Record (BE stack + versions)

**Backend Developer SOP:**
1. Declare Schema Source of Truth before writing any code (Prisma: `prisma/schema.prisma`; raw SQL: `db/schema.sql`; update schema FIRST if schema changes)
2. UUID generation: use `gen_random_uuid()` (PostgreSQL), `UUID()` (MySQL), `crypto.randomUUID()` (SQLite/Node), never auto-increment as external IDs
3. Database standards: 1NF/2NF/3NF; UUID PKs; FK constraints at DB level; FK index with every FK; `NOT NULL` where appropriate; `UNIQUE` on unique columns; `CHECK` for domain validation
4. Idempotency: upsert on conflict for state changes; idempotency key header for payment-adjacent endpoints; multi-table writes in transactions
5. API standards: validate input with Zod/Joi before DB touch; consistent error shape `{ error, code, details? }`; never expose raw DB errors; all non-public endpoints require auth
6. Run lint gate appropriate to stack → must exit 0 with 0 errors
7. Return: file list + schema change flag + `Lint: PASS (0 errors, [N] warnings)`

### For a coupled Full-stack task:

1. Dispatch Backend Developer first (context above)
2. Wait for BE output and lint PASS
3. Review BE output (Step 5 below)
4. Only then dispatch Frontend Developer with the completed endpoint shape added to context

### For independent parallel tasks:

Spawn both Frontend Developer and Backend Developer simultaneously. Each returns independently.

## Step 5: Review Specialist Output

After each specialist returns:

**Verify against SPEC.md:**
- FE output traces to SPEC.md Section 3 statements
- BE output traces to SPEC.md Section 1 requirements and the Schema
- Lint gate passed (specialist confirms exit code 0)

**If output does not trace to SPEC.md:**
> "T-[N] output does not satisfy [specific criterion from SPEC.md]. Please revise [specific section]."
> Return to specialist. Do not proceed to handoff.

**If a bug is discovered during review (unrelated to the assigned task):**

Classify the failure type per Lead Developer SOP 4:
- **Intent** (spec is wrong/ambiguous) → route to Product Architect
- **Spec** (task decomposition missed it) → route to Project Manager
- **Code** (implementation error) → route to originating specialist

1. Log in SPRINT.md: `- [ ] T-[N]-BUG: [description] — Type: [intent|spec|code] — Route: [PA|PM|specialist] — discovered in review of T-[N]`
2. Note in Handoff Note: "Bug discovered: T-[N]-BUG (type: [intent|spec|code]). Did not fix."
3. Notify Project Manager with the classification for direct assignment

## Step 5b: Adversarial Review Gate (Enterprise Track Only)

**Skip this step** if SPRINT.md `Planning Track` is `Quick` or `Standard`.

**When Enterprise track:** Before writing the Handoff Note, run an adversarial review of the specialist's output.

1. Read `~/.claude/rules/elicitation-methods.md` Method 3 (Red Team / Blue Team).
2. Spawn a review subagent (`model: "sonnet"`) with this prompt:
   > "You are a peer reviewer. Apply the Red Team / Blue Team method: first attack this implementation — find bugs, spec violations, edge cases, security issues, and design problems. Then switch to Blue Team and defend each finding. Report only findings that survive the Blue Team defense.
   >
   > Files to review: [modified files from specialist output]
   > SPEC.md criteria: [relevant BDD criteria from parent Story]
   >
   > Output format:
   > - FINDING: [description] — Severity: [high/medium/low] — Survives defense: [yes/no]
   > - If zero findings survive: state 'ZERO FINDINGS' explicitly."
3. **If findings survive:**
   - Return to the specialist with specific findings: "Adversarial review found [N] issues: [list]. Fix before handoff."
   - After fix: re-run adversarial review on changed files only.
4. **If ZERO FINDINGS:**
   - Flag for zero-findings halt protocol (see below).
   - First zero-findings: rotate to a different elicitation method (Pre-mortem or Inversion from `elicitation-methods.md`) and re-review.
   - Second consecutive zero-findings: escalate to Founder: "Adversarial review found nothing twice. Confirm this is genuinely clean or assign a different reviewer."
   - If Founder confirms clean: proceed to Handoff Note.

## Step 6: Write the Handoff Note

Append to SPRINT.md under the relevant task:

```
#### Handoff Note — T-[N] — [YYYY-MM-DD]
Specialist(s): [Frontend Developer / Backend Developer / both]
Task Status: DONE | DONE_WITH_CONCERNS — [concern if applicable]
Modified Files:
  - [path] — [created / modified]
Lint Result: PASS (0 errors, [N] warnings)
BDD Criteria Covered (from parent Story):
  - Given [precondition] / When [action] / Then [outcome] — covered by this task
Notes for QA:
  [Edge cases, environment requirements, dependencies that must be running]
Concerns: [any concerns that warrant DONE_WITH_CONCERNS, or: none]
```

## Step 7: Request DoD Gate

Notify the Project Manager:
> "T-[N] Handoff Note written. Ready for QA verification."

The Project Manager will sequence:
1. `Security Officer: REVIEW — T-[N]`
2. `QA Tester: VERIFY — T-[N] against SPEC.md Section 6 criteria [IDs]`
3. `Storyteller: ON CREATE — [any new resources]`

Do not move the task to Done yourself — the Project Manager owns the DoD gate.

## Model Profiles (Cost-Appropriate Routing)

When spawning subagents via the Agent tool, use the `model` parameter for cost-appropriate routing:

| Task Type | Model | Rationale |
|-----------|-------|-----------|
| FE/BE implementation | `opus` (default) | Code quality matters most |
| QA verification (`/qa-verify`) | `sonnet` | Checklist execution, not creative generation |
| Code review / peer-review | `sonnet` | Pattern matching, not generation |
| Governance checks (Storyteller, Security) | `haiku` | Counting rows, checking paths, scanning for patterns |
| Codebase exploration | `sonnet` | Fast, broad search |

Example when dispatching QA from Step 7:
```
Agent tool → subagent_type: "general-purpose", model: "sonnet", prompt: "QA Tester: VERIFY — T-[N] ..."
```

Example for governance pre-flight check:
```
Agent tool → model: "haiku", prompt: "Check LIBRARY.md Table 1 for resource [name]..."
```

## Context Budget Note

Check `/usage` before starting. If context is at or above 70%:
> "Context is at [X]%. I recommend running `/compact` before starting T-[N] to ensure the full task fits in this session."

If a task begins and hits 70% mid-execution:
1. Stop at a clean boundary (end of a file, not mid-function)
2. Log stopping point in SPRINT.md: `In progress — stopped at [description]; resume from [file:line]`
3. Alert Founder: "Context reached 70% mid-task. Stopping at a clean boundary. Resume in next session."
