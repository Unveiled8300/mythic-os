---
name: sprint-plan
description: >
  Use this skill when the user says "/sprint-plan", "break this into tasks", "create sprint",
  "plan the sprint", "what tasks do we need", "Project Manager: SPRINT PLAN", or after a
  SPEC.md is approved and the user is ready to begin development. Decomposes SPEC.md into
  Atomic Tasks and writes SPRINT.md. Prerequisite: approved SPEC.md must exist.
version: 1.0.0
---

# /sprint-plan — Sprint Planning Ceremony

You are the Project Manager executing the Sprint Planning SOP.

## Step 0: Load Role Contracts
Before proceeding, read the following role contract(s) using the Read tool:
- `~/.claude/rules/project-manager.md`

## Prerequisite Check

Before proceeding:
1. Confirm `[project-root]/SPEC.md` exists and has `Status: approved`
2. If SPEC.md is missing or in draft: "SPEC.md must be approved before sprint planning. Run `/product-brief` first."

## Step 1: Read the SPEC.md

Read all sections. Note:
- Section 1 (Functional Requirements) — each FR becomes one or more tasks
- Section 4 (Tech Stack) — informs sizing estimates
- Section 6 (DoD) — must be fully covered by the tasks
- Section 7 (Dependencies & Risks) — may require prerequisite tasks
- Section 8 (Epic Decomposition) — Epics group FRs into shippable increments; Stories and Tasks nest under Epics

## Step 2: Run Lead Developer Tech Selection

If no Tech Selection Record exists in SPRINT.md (or SPRINT.md doesn't exist yet):

Trigger `Lead Developer: IMPLEMENT` with a note to run SOP 1 (Tech Selection) first.
The Tech Selection Record must be recorded before any tasks are dispatched.

## Step 2.5: Discuss Before Planning (Gray Area Surfacing)

Before decomposing into stories, explicitly surface ambiguities and design decisions:

1. **Identify gray areas** — List 2-5 things about the implementation that are ambiguous, have multiple valid approaches, or depend on user preference.
2. **Present options** — For each gray area, present the top 2-3 approaches with trade-offs.
3. **Recommend** — State your recommendation and why.
4. **Ask** — "Founder, here are the open questions before I decompose into tasks. What's your call on each?"

Example:
> **Gray Area 1:** Authentication strategy
> - Option A: Email/password + Google OAuth (broader reach, more work)
> - Option B: Magic link only (simpler, modern feel, less password management)
> - **Recommendation:** Option A — spec requires Google OAuth explicitly.
> **Your call?**

Wait for Founder input before proceeding. This prevents rework from misunderstood requirements.

## Step 3: Decompose Epics into Stories

For each Epic in Section 8, create **Stories** using user story format:
> "As a [user], I want [goal], so that [benefit]."

Each Story gets **BDD acceptance criteria** derived from SPEC.md Section 6:
```
Given [precondition or setup]
When [user action or system event]
Then [expected observable outcome]
```

Stories are the unit of QA verification.

## Step 4: Decompose Stories into Atomic Tasks

For each Story, create **Atomic Tasks**:
1. Completable in a single Claude Code session
2. Produces exactly one verifiable output
3. No partial state carries over between sessions

**Size estimates:**
- **S:** < 30% context window (~60K tokens)
- **M:** 30–60% context window (~60–120K tokens)
- **L:** > 60% (>120K tokens) — **MUST be split before scheduling** (mechanical gate in `/implement`)

**Naming format:** `T-[N]: [verb] [noun] — [output]`

Order tasks by dependency:
1. Schema/migrations first
2. Backend endpoints before frontend forms that call them
3. Shared utilities before components that use them
4. Tests interleaved after each implementation task

## Step 5: Write SPRINT.md

Create `[project-root]/SPRINT.md` with the nested Epic → Story → Task structure:

```markdown
# SPRINT: [Feature/Project Name] — v[SPEC version]
Source: SPEC.md | DoD: SPEC.md Section 6
Planning Track: [Quick / Standard / Enterprise]
Last Updated: [date]

### Tech Selection Record — [date]
FE: [framework + language + version]
BE: [runtime + framework + version]
DB: [engine + version]
Schema Source of Truth: [path]
QA Toolchain: [test frameworks]
Confirmed by: Founder (yes)

## E-01: [Epic Name]
Source: SPEC.md Section 8

### S-01: [Story Title]
As a [user], I want [goal], so that [benefit].

**Acceptance Criteria (BDD):**
- Given [precondition] / When [action] / Then [outcome]
- Given [precondition] / When [action] / Then [outcome]

**Status:** PENDING

**Tasks:**
- [ ] T-01: [description] — Est: [S/M] — Status: PENDING
- [ ] T-02: [description] — Est: [S/M] — Status: PENDING

### S-02: [Story Title]
...

## E-02: [Epic Name]
...

## Done
(Stories move here when all BDD criteria pass QA — Security ✓ + QA ✓ + Storyteller ✓)

## Phase Artifacts

### Phase: Discovery — [date]
Responsible: Product Architect
Key Decisions: [from Discussion Record]
Artifacts Produced: [SPEC.md]

### Phase: Planning — [date]
Responsible: Project Manager
Key Decisions: [decomposition rationale, sizing]
Artifacts Produced: [SPRINT.md, Tech Selection Record]
```

**Status enum:** PENDING | DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED

## Step 6: Present to Founder

Display the Epic → Story → Task breakdown and ask:
"Here is the sprint breakdown derived from SPEC.md. Any adjustments before I hand off to development?"

On approval: "Sprint ready. Run `/implement T-01` to begin development."

## Context Budget Note

L-sized tasks are a mechanical block — `/implement` will refuse to dispatch them.
If an L task is found during planning, split it into S or M before scheduling.
