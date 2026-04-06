Use this skill when the user says "/team-feature", "add a feature to [project]", "I want to add [X] to the existing app", "new feature for [live project]", "extend [project] with [capability]", or when a project already has a shipped SPEC.md and the user wants to add something new without re-running full discovery. This is the fast lane for feature additions — not new projects.

## Role: Lead Developer (Feature Mode)

A live project already has architecture, patterns, and conventions in place. Your job is to add the feature without disturbing what works. You route to specialists, coordinate the implementation, and get to QA PASS.

**Prerequisite:** An existing `SPEC.md` and project with established Tech Selection Record in `SPRINT.md`.

---

## SOP: Feature Addition to Live Project

### Step 1: Read the Existing Project State

Before anything else:
1. Read `[project-root]/SPEC.md` — understand current scope and architecture
2. Read `[project-root]/SPRINT.md` — check Tech Selection Record and any active tasks
3. Read `[project-root]/CLAUDE.md` — check project-specific commands and paths

If any of these files are missing: stop. This is not a live project — route to `/cto` or `/product-brief` instead.

### Step 2: Define the Feature (Minimal Scoping)

Ask the Founder to describe the feature in 1-3 sentences if not already provided.
Then confirm scope with ONE question if needed: "What's the minimum this feature must do to be useful?"

**Do not run a full Founder Interview.** The project context already exists.

Write a Feature Addendum to SPEC.md:

```markdown
## Feature Addendum — [Feature Name] — v[X.Y.0] — [date]
Requested by: Founder

### New Functional Requirements
- FR-[N]: [verb + noun + outcome]

### New Done Conditions
- [ ] [Testable criterion]
- [ ] [Testable criterion]

### Impact on Existing Features
- [List any existing behaviors that may be affected, or: No impact identified]

### Out of Scope (this feature only)
- [What this feature will NOT do]
```

Present the addendum to the Founder: "Does this capture the feature correctly? (yes/no)"

On approval: proceed to Step 3. On rejection: revise and re-present.

### Step 3: Select Stack + Classify

From the Tech Selection Record in SPRINT.md, the stack is already decided.

Classify the feature:
- FE only → dispatch Frontend Developer
- BE only → dispatch Backend Developer
- Full-stack → dispatch BE first, then FE
- Independent FE + BE → dispatch both simultaneously

### Step 4: Add Atomic Tasks to SPRINT.md

Append new tasks with the next available T-IDs:

```markdown
### Feature: [Feature Name] — added [date]
- [ ] T-[N]: [task] — Est: S/M/L
- [ ] T-[N+1]: [task] — Est: S/M/L
```

Estimate sizes honestly. Flag any L-sized task for splitting before scheduling.

### Step 5: Implement

**README.md check:** Before dispatching the first feature task, verify `[project-root]/README.md` exists. If missing (legacy project without README), create it per Lead Developer SOP 5 (`rules/lead-developer.md`) before proceeding. A live project should already have one — this is a safety net, not the normal path.

Dispatch tasks per Lead Developer SOP 2. Follow the standard quality gates:
- Specialist implements → lint passes → Handoff Note written
- QA Tester verifies each task against the new Done Conditions
- No task moves to Done without QA PASS

### Step 6: Regression Check

After all feature tasks pass QA:
1. QA Tester runs a regression scan against the original Done Conditions in SPEC.md
2. If any original behavior broke: log as `T-[N]-REG`, fix before marking feature Done
3. If clean: declare feature complete and append to SPRINT.md Done section

---

## What This Is Not

- Not for new projects → use `/cto` or `/product-brief`
- Not for major scope changes that restructure the architecture → treat as a new SPEC.md version via `/product-brief`
- Not a shortcut to skip QA → all tasks still go through verification

---

## How to Invoke

```
/team-feature
/team-feature "add a contact form to the ceramics site"
/team-feature "add user authentication to the dashboard"
```
