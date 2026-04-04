---
name: reflect
description: >
  Use this skill when the user says "/reflect", "run a retrospective", "what patterns
  have we seen", "what's breaking repeatedly", "self-improvement review", "what should
  we change", "audit our errors", or after any P1/P2 incident is resolved. Also runs
  automatically when Project Manager: SESSION END is called after a sprint with a REJECT
  or incident. Scans error-records for systemic patterns, reviews pending ADRs, surfaces
  sprint health from SPRINT.md, and produces a Retrospective Report with proposed rule
  updates. This is the self-improvement loop — it turns failures into governance.
slash_command: /reflect
trigger_pattern: "/reflect|run retrospective|what patterns|what's breaking|self-improvement|audit our errors|sprint retrospective"
---

# SKILL: /reflect — Sprint Retrospective & Pattern Analysis

You are activating the **self-improvement loop** of this system. Your job is to look
backward across what broke, what was decided, and what was hard — then translate that
into concrete changes that make the system smarter going forward.

This skill has no implementation code to write. It reads, analyzes, and reports.

**Data Sources:**
- `~/.claude/brain/log/errors/` — Auto-captured build/test/lint failures (primary source)
- `~/.claude/brain/log/decisions/` — Tech decisions captured during planning
- `~/.claude/brain/log/fixes/` — What broke and what fixed it
- `~/.claude/brain/patterns/` — Previously promoted patterns (check for recurrence)
- `~/.claude/error-records/` — Legacy error-record files (secondary source)
- `~/.claude/LIBRARY.md` — Table 1 (Resource Registry), Table 8 (Error/Solution Log)
- `~/.claude/adr/` — Full ADR files

---

## Phase 1: Error Pattern Analysis

### Step 1: Scan brain/log/ and error-records/

Scan BOTH directories for error data:
1. `~/.claude/brain/log/errors/` — Auto-captured errors (primary, newer format)
2. `~/.claude/brain/log/fixes/` — Fix records (paired with errors)
3. `~/.claude/error-records/` — Legacy error records (secondary)

If all are empty, note "No error data on file yet." and skip to Phase 2.

For each error/fix file, extract:
- **Slug** (filename)
- **Root Cause** or **Symptom** content
- **Prevention** or **Fix** content
- **Tags** (if present)
- **Stack** (if present — enables cross-project pattern detection)

### Step 2: Categorize root causes

Group error-records by root cause type. Use plain English categories:

| Category | Example Root Causes |
|----------|-------------------|
| Missing governance | "No SOP existed for this action" |
| Contract gap | "Role contract did not specify this case" |
| Context rot | "Session started cold; prior work was unknown" |
| UUID / ID handling | "ID generated manually instead of via uuidgen" |
| Environment config | "Secret was hardcoded; .env not consulted" |
| Dependency ordering | "Role ran before its precondition was met" |
| Testing gap | "No test covered this path" |

### Step 3: Flag patterns

A **systemic pattern** is any root cause category with ≥ 2 error-records.

For each pattern:
- List the error-record slugs that share it
- State the Prevention notes across those records
- Check: has a rule or SOP already been updated to address this?
  - Read the relevant rule file and look for the preventive language
  - If the fix is already in the contract: note "Resolved — prevention encoded in [rule]"
  - If not: flag as "Unresolved pattern — rule update required"

---

## Phase 1.5: Promote Patterns to brain/

For each **systemic pattern** identified above (≥2 error-records sharing a root cause):

1. **Check if pattern already exists** in `~/.claude/brain/patterns/`. If so, increment its occurrence count.

2. **If new pattern**: Write a pattern file to `~/.claude/brain/patterns/[slug].md`:
   ```markdown
   # Pattern: [root cause category]
   - **Occurrences:** [N]
   - **Evidence:** [list of error slugs]
   - **Prevention:** [consolidated prevention advice]
   - **Stack:** [if stack-specific]
   - **First Seen:** [date]
   - **Last Seen:** [date]
   ```

3. **Cross-project promotion**: If a pattern has the same Stack tag and ≥2 occurrences across different projects, promote to `~/.claude/brain/playbooks/[stack]-gotchas.md` (append if file exists).

4. **Rule promotion**: If a pattern has ≥3 occurrences and severity is high, propose adding it to the relevant skill or CLAUDE.md as a prevention rule (presented to Founder in Phase 4).

5. **Update brain/index.md stats**: Update the Errors/Patterns/Playbooks counts and Last /reflect date.

---

## Phase 2: ADR Status Review

### Step 1: Scan brain/log/decisions/ and adr/

Read decision records from BOTH locations:
1. `~/.claude/brain/log/decisions/` — Auto-captured tech decisions (primary)
2. `~/.claude/adr/` — Legacy ADR files (secondary)

If both are empty, note "No decisions on file yet." and skip to Phase 3.

### Step 2: Check for pending decisions

For each ADR, read the `Status:` line.

- `proposed` → flag as "Pending decision — Founder input required"
- `accepted` → no action needed
- `deprecated` or `superseded` → no action needed

### Step 3: Check for superseded ADRs without replacements

If an ADR is marked `superseded` but its `Superseded By:` field is `N/A` or blank:
flag as "Orphaned deprecation — decision was retired without a successor ADR."

---

## Phase 3: Sprint Health Review

### Step 1: Read SPRINT.md (if it exists)

Look for `[project-root]/SPRINT.md`. If no project is active or the file doesn't exist,
skip this phase.

Read the most recent Sprint Summary block. Extract:
- Completed tasks this sprint
- Blocked tasks and their blockers
- Context usage (if logged)
- Any REJECT notices from QA

### Step 2: Identify health signals

| Signal | Implication |
|--------|-------------|
| 2+ tasks blocked by the same role | That role may have a contract gap |
| Context overrun (> 90%) | Atomic Tasks may be sized too large (SOP 1, Project Manager) |
| QA REJECT on same criterion twice | SPEC.md Section 6 criterion may be ambiguous |
| Marketing Voice FLAG on same copy pattern | Brand Voice standard may need clarification |

---

## Phase 4: Produce the Retrospective Report

Write the report directly in the conversation (do not save to a file unless the Founder asks).

```
## Retrospective Report — [YYYY-MM-DD]
Project: [name if identifiable, or: system-level]

---

### Error Patterns

[For each pattern with ≥2 error-records:]
**Pattern: [root cause category]**
- Evidence: [list of error-record slugs]
- Status: [Resolved — prevention in [rule] | Unresolved — rule update required]
- Proposed Fix: [specific change to which SOP/rule/checklist — or: already addressed]

[If no patterns:]
No recurring root causes detected. [N] error-record(s) reviewed, all distinct.

---

### Pending Decisions (ADRs)

[For each ADR with status: proposed:]
- [title] — Founder decision required before this can be implemented

[If none:]
No pending ADRs.

---

### Sprint Health

[From most recent Sprint Summary:]
- Completed: [N] tasks
- Blocked: [N] tasks — [brief cause summary]
- Context: [peak usage and whether compact was triggered]
- QA: [PASS / REJECT count]

[Health signals found (if any):]
- [signal] → [implication and proposed response]

[If no SPRINT.md found:]
No active sprint to review.

---

### Proposed System Improvements

[For each concrete change the system should make:]

1. **[Change title]**
   - What to change: [specific rule, SOP, or checklist item]
   - Why: [one sentence connecting this to a pattern or failure]
   - Priority: [high / medium / low]
   - Trigger if approved: `Storyteller: ON UPDATE — [resource name]`

[If no improvements needed:]
No systemic improvements identified. System is operating within expected parameters.

---

### No Action Required

[Items reviewed that were fine — acknowledges thoroughness]
```

---

## Phase 5: Execute Approved Improvements

After presenting the Retrospective Report, wait for Founder response.

For each improvement the Founder approves:

1. Trigger `Storyteller: ON UPDATE — [resource name]`
2. Open the relevant rule file and make the specific change
3. If the change represents a significant decision: trigger `Storyteller: ON ADR — [decision title]`
4. Confirm: "Improvement applied. [Rule] updated to version [N]."

For each improvement the Founder defers or rejects:
- Note the decision in the conversation.
- If deferred: suggest `/reflect` as a trigger for revisiting.
- Do NOT make the change without Founder approval.

---

## Skill Completion

End with:
```
/reflect complete — [N] patterns reviewed, [N] improvements proposed, [N] approved.
```

If no patterns or improvements were found:
```
/reflect complete — System is healthy. No recurring issues detected.
```
