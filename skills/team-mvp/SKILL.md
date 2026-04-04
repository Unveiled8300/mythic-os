---
name: team-mvp
description: >
  Use this skill when the user says "/team-mvp", "MVP mode", "fast build", "ship fast",
  "skip the ceremony", "just build it", "rapid prototype", or needs to move from idea to
  working code as quickly as possible. Runs a streamlined sequence: 10-minute discovery →
  minimal SPEC.md → immediate implementation. Cuts non-essential roles while preserving
  Security and QA gates. NOT a substitute for full discovery on production software.
version: 1.0.0
---

# /team-mvp — MVP Rapid Build Pod

You are coordinating the MVP Pod. Speed over ceremony — but security and correctness are non-negotiable.

## Step 0: Load Role Contracts
Before proceeding, read the following role contract(s) using the Read tool:
- `~/.claude/rules/lead-developer.md`
- `~/.claude/rules/qa-tester.md`

## What Gets Cut vs. What Stays

| Role | MVP Mode |
|------|----------|
| Marketing Manager | ❌ Skipped (add later with `/marketing-brief`) |
| Product Architect (full interview) | ✂️ Condensed to 10 minutes |
| Project Manager (full sprint) | ✂️ Minimal SPRINT.md — just a task list |
| Lead Developer | ✓ Full tech selection (non-negotiable for correctness) |
| Frontend Developer | ✓ Full implementation |
| Backend Developer | ✓ Full implementation |
| Security Officer | ✓ Full scrub (non-negotiable) |
| QA Tester | ✂️ Focused only on core criterion per task (no regression scan) |
| Storyteller | ✂️ UUID registration only for new reusable resources |
| DevOps | ❌ Skipped (manual deploy or Vercel auto-deploy) |

## When to Use MVP Mode

✓ Proof-of-concept or prototype to validate an idea
✓ Personal/dogfood tools for the Founder only
✓ Quick internal scripts or automation
✓ First iteration of something that will be replaced or rebuilt

**Not for:**
✗ Customer-facing production software handling user data
✗ Any project with HIPAA or CA Privacy requirements
✗ Software where the Founder plans to invite external users in < 30 days

If any "Not for" applies, use `/team-fullstack` instead.

---

## Stage 1: 10-Minute Discovery

Ask all five domains in one batch using `AskUserQuestion`:

> "Let's build this fast. I need 5 quick answers:"
> 1. "What is the core thing this does — one sentence?"
> 2. "Who uses it and what do they want to accomplish?"
> 3. "What's the tech stack? (I'll default to TypeScript + Next.js if unsure)"
> 4. "What are the 2-3 things that MUST work for this to be useful?"
> 5. "What is explicitly NOT in scope?"

Write a minimal SPEC.md:

```
# SPEC: [Project Name]
Version: 1.0.0 | Created: [date] | Status: approved (MVP mode)

## 1. Functional Requirements
- FR-01: [core thing it does]
- FR-02: [second thing if needed]

## 2. Non-Functional Requirements
- Performance: reasonable (no formal targets)
- Security: no hardcoded secrets; passwords hashed if auth exists
- Compliance: HIPAA: no | CA Privacy: no

## 3. Visual Description
[1-3 sentences about what the UI looks like, if applicable]

## 4. Tech Stack
[Declared by Founder or TypeScript + Next.js default]

## 5. Out of Scope
[Founder's answer to question 5]

## 6. Definition of Done
- [ ] [Must-work thing 1 — specific and testable]
- [ ] [Must-work thing 2]
- [ ] [Must-work thing 3]

## 7. Dependencies & Risks
- [Any obvious dependencies]
```

Present to Founder: "Here's the minimal spec. Approved?" Wait for confirmation.

---

## Stage 2: Minimal Sprint Plan

Write SPRINT.md with just the task list — no ceremony:

```
# SPRINT: [Project Name] — MVP
Source: SPEC.md | DoD: SPEC.md Section 6

### Tech Selection Record — [date]
FE: [stack]
BE: [stack]
DB: [engine]
Schema Source of Truth: [path]
QA Toolchain: [Jest + RTL | pytest | other]
Confirmed by: Founder (yes)

### Atomic Tasks
- [ ] T-01: [task] — Est: [S/M/L]
- [ ] T-02: [task] — Est: [S/M/L]

### Done
```

If any task is L (large): split it before proceeding.

---

## Stage 3: Build Loop (Per Task)

For each Atomic Task:

### Implement
Classify and dispatch:
- FE task → Frontend Developer (full SOP: SPEC.md Section 3, WCAG, TypeScript, lint)
- BE task → Backend Developer (full SOP: schema first, FK indexes, transactions, lint)
- Coupled → BE first, then FE

No shortcuts on implementation quality — MVP speed comes from reduced ceremony, not from skipping correctness.

### Security Scrub
`Security Officer: REVIEW — T-[N]` — non-negotiable. Always runs. Always.

Checks: no hardcoded secrets, `.env` in `.gitignore`, no raw DB errors to client.

### QA — Core Criterion Only
`QA Tester: VERIFY — T-[N]`

In MVP mode, QA Tester verifies **only the core must-work criterion** for this task (from SPEC.md Section 6). No regression scan. No full evidence report.

Returns: PASS (core criterion met) or FAIL (core criterion not met with repro steps).

### Close
Move task to Done in SPRINT.md.

---

## Stage 4: MVP Done Report

```
MVP Build Complete — [project name] — [date]
Tasks Completed: [N]
Criteria Verified: [N] of [N]

What was built: [1-3 sentence summary]

Upgrade path when ready:
  → Run /marketing-brief to add User Persona and voice standard
  → Run /metadata to add SEO headers
  → Run /team-fullstack for the next sprint with full ceremony
  → Run /deploy to set up CI/CD and staging
```

---

## Upgrade Warning

If the Founder later wants to ship this to external users:
> "This was built in MVP mode. Before shipping to users, you need: (1) Marketing Brief + SEO headers, (2) Security Officer full review of all files, (3) Full QA with regression scan, (4) DevOps setup with staging verification. Run `/team-fullstack` for the next sprint to apply the full process."
