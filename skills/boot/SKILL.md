---
name: boot
description: >
  This skill MUST be used at the start of every session. Use it when the user types "/boot",
  "boot session", "start session", "initialize", "let's get started", "what are we working on",
  or opens a new Claude Code session with no immediate task. Also trigger if the user asks
  "what's the current state" or "what was I working on". Prevents cold-start context rot by
  loading the active project, sprint state, and available roles before any work begins.
version: 1.1.0
---

# /boot — Session Initialization

You are executing the Session Boot sequence. Follow every step in order. Do not skip.

## Step 0: Load Context (Skill-Scoped)

Before running any steps, read the following files using the Read tool:
- `~/.claude/LIBRARY.md` — hot storage only (Tables 1, 5a, 7, 8, 10). Do NOT read `LIBRARY-HISTORY.md` (cold storage) — it is only needed by `/reflect` and `/team-audit`.

No role contracts are needed for /boot — it is a routing skill, not a role invocation.

## Step 0.5: Governance Compliance Audit

Run this before any other step. This surfaces unregistered resources before new work begins.

**1. Skill count check:**

Run: `ls ~/.claude/skills/ 2>/dev/null | grep -v '^\.' | sort`

Count the directories listed. Then count the rows in the LIBRARY.md already loaded in Step 0, Table 1, where `type` = `skill` and `status` = `active`.

If skill directories > registered skills:
```
⚠️ GOVERNANCE GAP DETECTED
Skills on disk:      [N]
Registered in LIBRARY.md: [M]
Unregistered: [list directory names not found as skill names in Table 1]

Resolve before new work: Storyteller: ON CREATE — [name] (type: skill)
```

If counts match:
```
✅ Governance: [N] skills registered
```

**2. Command file check:**

Run: `find ~/.claude/commands -name "*.md" 2>/dev/null | wc -l`

Count the rows in Table 5a of LIBRARY.md. If command files > Table 5a rows:
```
⚠️ GOVERNANCE GAP: [N] command files on disk, [M] in Table 5a
Unregistered commands may not trigger correctly.
Resolve: Storyteller: ON UPDATE — Table 5a (add missing slash commands)
```

**3. Retroactive compliance warning:**

If any governance gap is found AND the gap involves files that were committed more than 24 hours ago:
```
⚠️ Retroactive compliance detected — resources exist without LIBRARY.md registration.
Recommended: run /team-audit before starting new work to resolve all gaps cleanly.
```

## Step 0.9: Role Audit Data Check

Check if enough fragment usage data has been collected for a role audit:

Run: `wc -l ~/.claude/brain/log/fragment-usage.jsonl 2>/dev/null | awk '{print $1}'`

- If the file doesn't exist or has < 20 entries: skip silently.
- If ≥ 20 entries and no role audit has been run yet (no files in `~/.claude/brain/log/decisions/` matching `*role-audit*`):
  ```
  📊 ROLE AUDIT DATA READY
  Fragment usage log: [N] entries collected across sessions.
  Run /role-audit to evaluate which roles and fragments are earning their token cost.
  ```
- If a role audit was already run: skip silently (don't nag).

## Step 1: Identify Active Project

From the LIBRARY.md already loaded in Step 0:
- Table 1: count active resources (gives confidence the system is intact)
- Table 7: Project Registry — identify all rows with `status: active`

If Table 7 is empty: report "No active projects registered. Start a new project with `System: KICKOFF — [description]`." and stop.

If Table 7 has one active project: use it automatically.

If Table 7 has multiple active projects: list them and ask:
"Multiple active projects found. Which should be the focus of this session?"
Wait for Founder selection before proceeding.

## Step 2: Load the Active Project

For the selected project, read:
1. `[spec_path]` (SPEC.md) — skim Sections 1 and 6 (Functional Requirements + Definition of Done)
2. `[sprint_path]` (SPRINT.md) — read the full Atomic Tasks and Done sections

## Step 3: Synthesize the State

Compose the Session Status Report:

```
═══════════════════════════════════════════
SESSION BOOT — [project name]
[YYYY-MM-DD HH:MM]
═══════════════════════════════════════════

ACTIVE PROJECT: [name]
SPEC VERSION:   [version] | Status: [draft/approved]
TECH STACK:     [from SPRINT.md Tech Selection Record]

SPRINT PROGRESS:
  Done:    [N] tasks — [T-01, T-02, ...]
  Pending: [N] tasks — [T-03, T-04, ...]
  Blocked: [N] tasks — [T-XX: reason]

LAST COMPLETED: [T-N description] — [date]
NEXT UP:        [T-N description]

REGISTERED RESOURCES: [N] active in LIBRARY.md

═══════════════════════════════════════════
WHAT WOULD YOU LIKE TO DO?
  1. Continue → [next task description]
  2. Review pending tasks
  3. Start a new project (System: KICKOFF)
  4. Run a health check (Storyteller: ON AUDIT)
═══════════════════════════════════════════
```

## Step 4: Wait and Route

Wait for Founder's selection. Route accordingly:
- "1" or "continue" → Invoke `Lead Developer: IMPLEMENT — [next task ID]`
- "2" → Display the full SPRINT.md Atomic Tasks section
- "3" → Invoke `System: KICKOFF — [description from Founder]`
- "4" → Invoke `Storyteller: ON AUDIT`
- Any other task description → classify it and dispatch to the appropriate role

## Rules

- Never proceed to implementation before the Session Status Report is displayed
- Never assume which project is active — always read Table 7
- If SPRINT.md does not exist for the active project, alert the Founder:
  "No SPRINT.md found for [project]. Run `Project Manager: SPRINT PLAN — [feature]` to create one."
- If SPEC.md is missing: "SPEC.md not found at [path]. Run `Product Architect: NEW PROJECT — [name]`."
