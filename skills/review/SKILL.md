---
name: review
description: Governed code review that writes the review-pass governance marker. Launches the code-reviewer agent against recent changes, evaluates the verdict, and gates commits.
---

# /review — Governed Code Review

Use this skill when the user says "/review", "review this code", "review before commit",
"code review", or when the Lead Developer needs a review before committing.

This wraps the code-reviewer agent with governance marker integration. After review
completes with an Approve verdict, the review-pass marker is written, satisfying the
Tier 1 commit gate in branch-gate.py.

## When to Use

- Before every `feat`, `fix`, `refactor`, `test`, or `perf` commit (Tier 1 gate)
- After `/implement` completes and the Handoff Note is written
- When you want an adversarial second look at recent changes
- After `/feature-forge` selects the winning variant

## Procedure

### Step 1: Determine Review Scope

Identify what to review:

1. If a task ID is provided (e.g., `/review T-01`): read the Handoff Note from SPRINT.md
   to get the list of modified files.
2. If no task ID: use `git diff --name-only` to find recently changed files.
3. If a specific file is provided: review just that file.

### Step 2: Launch Code Review Agent

Launch a `code-reviewer` agent with the diff or file paths:

```
Agent({
  subagent_type: "code-reviewer",
  prompt: "Review the following changes for adherence to project guidelines,
           style, security, performance, and correctness.
           Focus on: [modified files from Step 1]
           Project root: [project root]"
})
```

The agent will return a structured report with:
- Critical Issues (severity: high)
- Suggestions (severity: medium/low)
- What Looks Good
- Verdict: Approve | Request Changes | Needs Discussion

### Step 3: Evaluate Verdict

Read the agent's verdict:

- **Approve** or **Approve with suggestions** → Proceed to Step 4.
- **Request Changes** → Report the issues. Do NOT write the marker.
  The developer must fix the issues and re-run `/review`.
- **Needs Discussion** → Present the discussion points to the Founder.
  Do NOT write the marker until the discussion is resolved.

### Step 4: Write Governance Marker

On Approve verdict only:

```bash
python3 ~/.claude/hooks/enforcement/govpass.py write <project_root> review-pass <task_id>
```

Report to the user:
```
REVIEW PASS — [task_id or "ad-hoc"] — [date]
Verdict: Approve
Issues: [N] critical, [N] suggestions
Marker written: .govpass/review-pass.json
```

### Step 5: On Request Changes

If the verdict is Request Changes, report:
```
REVIEW: REQUEST CHANGES — [task_id or "ad-hoc"] — [date]
Issues requiring fixes:
  - [issue 1]
  - [issue 2]

No review-pass marker written. Fix the issues and re-run /review.
```

## Rules

1. Never write the marker on Request Changes or Needs Discussion.
2. The code-reviewer agent must actually read the code — do not skip the review.
3. If the project has CLAUDE.md, the agent should check adherence to it.
4. If SPEC.md exists, check that changes trace to stated requirements.
5. Review scope should match what will be committed — not the entire codebase.
