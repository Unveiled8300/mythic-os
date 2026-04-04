---
name: team-audit
description: >
  Use this skill when the user says "/team-audit", "Storyteller: ON AUDIT", "audit the system",
  "health check", "what's out of date", "check the library", "verify the system", or at the
  start of any session where the integrity of the governance system itself should be confirmed.
  Runs a full integrity check across LIBRARY.md, all rule files, and the skill registry.
version: 1.0.0
---

# /team-audit — System Integrity Audit

You are coordinating the Audit Pod. This team verifies the system's own health.

## Pod Composition

| Role | Responsibility |
|------|---------------|
| Storyteller | LIBRARY.md integrity (Table 1 vs. files on disk) |
| Security Officer | Rule files and skills scanned for hardcoded secrets or unsafe patterns |
| Project Manager | SPRINT.md state for any active projects |

## Model Profiles

All three audit phases are mechanical (counting rows, checking paths, scanning for patterns). When dispatching audit phases to subagents, use `model: "haiku"` for maximum cost efficiency:

```
Agent tool → model: "haiku", prompt: "Phase 1: Check all active rows in LIBRARY.md Table 1..."
Agent tool → model: "haiku", prompt: "Phase 2: Scan rules/*.md and skills/**/*.md for secrets..."
Agent tool → model: "haiku", prompt: "Phase 3: Read SPRINT.md and count task states..."
```

Phases 1, 2, and 3 are independent — dispatch them in parallel when possible.

## When to Run

- Monthly (or before major architectural work)
- After any session that created or modified multiple resources
- If the Founder suspects something is out of sync
- When `/boot` reports an unexpected state

---

## Phase 1: Storyteller Audit — LIBRARY.md Integrity

### Step 1: Check Table 1 Files Exist on Disk

For every `active` row in Table 1:
- Confirm the `path` file exists at `~/.claude/[path]`
- If file not found: `AUDIT FLAG: [name] ([resource_id]) — file missing at ~/.claude/[path]`
- If file exists and has an internal version declaration, compare it against Table 1's `version` field
- If mismatch: `AUDIT FLAG: [name] — Table says v[A], file says v[B]`

### Step 2: Check for Orphaned Rows

Open `~/.claude/LIBRARY-HISTORY.md` (cold storage). Check Tables 2, 3, and 4 for any rows where `resource_id` is not found in Table 1:
- `AUDIT FLAG: orphaned Table [N] row — [uuid]`

### Step 3: Verify Skill Command Registry (if Table 5a exists)

For each row in Table 5a (Skill Command Registry):
- Confirm the corresponding `~/.claude/skills/[name]/SKILL.md` exists
- `AUDIT FLAG: skill [name] registered in Table 5a but SKILL.md missing`

### Step 4: Check Table 7 Project Registry

For each active project in Table 7:
- Confirm `spec_path` file exists
- Confirm `sprint_path` file exists (or note "not yet created" if expected)
- `AUDIT FLAG: Project [name] — [spec_path | sprint_path] missing`

---

## Phase 2: Security Officer Scan — Quick Rule File Scan

### Step 1: Check Rule Files for Secrets

Scan all files in `~/.claude/rules/*.md` and `~/.claude/skills/**/*.md`:
- Look for any hardcoded patterns: `sk_`, `pk_`, API key formats, `password=`, bearer tokens
- If found: `SECURITY FLAG: [file] contains what appears to be a hardcoded secret at line [N]`

### Step 2: Confirm .env Safety Reminder

Verify that `.gitignore` patterns are mentioned in relevant rules/skills (not that actual secrets exist in LIBRARY.md):
- If LIBRARY.md Table 1 contains a `project` row, check that `SPEC.md` or `DEPLOY.md` references `.env.example`

---

## Phase 3: Project Manager — Active Sprint State Check

For each active project in LIBRARY.md Table 7:
1. Read `sprint_path` (SPRINT.md)
2. Count tasks by state: pending / in-progress / done / blocked
3. Flag any task marked `in-progress` (should not carry over between sessions — these indicate incomplete work)
4. Report: `[Project Name]: [N] done, [N] pending, [N] blocked, [N] in-progress (⚠️ stale if > 0)`

---

## Audit Report

After all three phases:

```
═══════════════════════════════════════════
SYSTEM AUDIT — [YYYY-MM-DD]
═══════════════════════════════════════════

LIBRARY.md Integrity:
  Active resources checked: [N]
  Files verified on disk: [N/N]
  Version mismatches: [N]
  Orphaned rows: [N]

Security Scan:
  Rule files scanned: [N]
  Skill files scanned: [N]
  Secret patterns found: [N]

Active Projects:
  [Project Name]: [N] done / [N] pending / [N] blocked

AUDIT FLAGS:
  [list each flag, or: None — system is clean]

═══════════════════════════════════════════
AUDIT STATUS: [CLEAN | FLAGS FOUND]
═══════════════════════════════════════════
```

If flags exist: "Would you like me to resolve these now?"

**Resolution actions:**
- Missing files → Storyteller changes `status` to `deprecated` in LIBRARY.md Table 1; logs in LIBRARY-HISTORY.md Table 2
- Version mismatches → Storyteller updates Table 1 in LIBRARY.md to match the file
- Orphaned rows → Storyteller removes them from LIBRARY-HISTORY.md Table 2/3/4
- Security flags → Report the specific file and line; Founder removes the secret

**After resolution:**
Add one row to LIBRARY-HISTORY.md Table 2 for the Storyteller's own `resource_id`:
```
| [new-uuid] | [storyteller-resource-id] | [current version] | audited | Audit complete. [N] flags found. [N] resolved. | [timestamp] | Storyteller |
```

Report: `Storyteller: AUDIT complete — [N] flags, [N] resolved.`
