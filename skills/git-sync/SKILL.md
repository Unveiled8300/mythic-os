---
name: git-sync
description: >
  Vendor Manager automated git workflow. Invoked after Storyteller decision or at
  session-end to atomically stage, commit, and push governance changes (LIBRARY.md,
  CLAUDE.md, rules/, skills/, adr/, error-records/) with audit-trail metadata.
  Also validates conventional commit format for project commits per rules/git-workflow.md.
version: 1.1.0
slash_command: /git-sync
trigger_pattern: "Vendor Manager: GIT-SYNC|After Storyteller|push governance|git sync"
---

# Skill: Git Sync

Atomically commit and push governance changes to GitHub after Storyteller decisions.

---

## SOP 1: Pre-Flight Checks

Before staging any files:

1. Verify git is initialized
   ```bash
   [ -d .git ] && echo "✅ Git initialized" || echo "❌ Not a git repo"
   ```

2. Verify you're on main branch
   ```bash
   git branch --show-current
   ```
   If not `main`: stop and ask user to switch: `git checkout main`

3. Check git status for uncommitted governance files
   ```bash
   git status --short
   ```
   - If only governance files are modified (LIBRARY.md, CLAUDE.md, rules/, skills/, etc.): ✅ proceed
   - If untracked files exist in governance paths: ✅ will be staged
   - If unrelated project files are modified: ⚠️ flag to user ("Found modified files outside governance scope. Only governance files will be staged. Continue?")

---

## SOP 2: Stage Governance Files

Add ONLY governance files to the staging area:

```bash
git add LIBRARY.md CLAUDE.md TASTE.md rules/ skills/ adr/ error-records/ .gitignore
```

Confirm staging:
```bash
git status --short
```

**Expected output:** Only governance files listed (no `projects/`, `history.jsonl`, `backups/`, etc.)

If unexpected files appear: run `git reset` and ask user to verify `.gitignore` is correct.

---

## SOP 3: Craft Audit-Trail Commit Message

Generate a commit message that references the Storyteller decision (if provided):

**Format:** `docs(governance): [Storyteller: ACTION] [resource_id] [description]`

**Examples:**
- `docs(governance): [Storyteller: ON CREATE] a1b2c3d4 (git-sync skill v1.0.0)`
- `docs(governance): [Storyteller: ON UPDATE] e5f6g7h8 (marketing-manager rule v1.2.0)`
- `docs(governance): session checkpoint — 3 Storyteller decisions committed`

**How to get the message:**
1. If invoked by Storyteller: Storyteller provides `[resource_id]` and description
2. If manual/batch: user can provide a message, or default to "Session checkpoint — governance sync"

---

## SOP 4: Commit & Push

Commit the staged changes:

```bash
git commit -m "docs(governance): [your message from SOP 3]"
```

Capture the commit hash:
```bash
COMMIT_HASH=$(git rev-parse HEAD | cut -c1-7)
```

Push to origin:
```bash
git push origin main
```

**Handle push failures:**
- If rejected ("updates were rejected"): ask user to run `git pull origin main` and retry
- If remote unreachable: inform user and ask whether to retry or defer sync

---

## SOP 5: Report Status

Return a structured status report:

```
✅ GIT SYNC COMPLETE

Commit: [COMMIT_HASH]
Message: docs(governance): [your message]
Files Changed: [N]
  - LIBRARY.md
  - CLAUDE.md
  - rules/
  - skills/
  - adr/
  - error-records/

Branch: main
Remote Status: pushed to origin

GitHub: https://github.com/[YOUR_ORG]/[YOUR_REPO]/commit/[COMMIT_HASH]
```

If any step failed:
```
❌ GIT SYNC FAILED

Step: [SOP step that failed]
Error: [error message]
Action: [user should retry / check .gitignore / run git pull origin main]
```

---

## Usage Patterns

### Pattern A: Auto-Sync After Storyteller Decision (Recommended)
```
Storyteller: ON CREATE — my-skill (my skill description)
  → Storyteller reports: resource_id a1b2c3d4

Vendor Manager: GIT-SYNC — a1b2c3d4
  → Skill stages, commits, pushes
  → GitHub is updated immediately
```

### Pattern B: Manual Batch Sync at Session End
```
[Work through multiple Storyteller decisions during session]

/git-sync
  → Stages all accumulated governance changes
  → Single commit: "docs(governance): session checkpoint"
  → GitHub is updated with batch of decisions
```

### Pattern C: Check Before Syncing (Dry Run)
```
git status --short
  [Review what will be staged]

/git-sync
  [Proceed with confidence]
```

---

## SOP 6: Conventional Commit Validation (Project Commits)

**When:** `/git-sync` is used for non-governance project commits, or when validating a
commit message before `git commit`.

Governance commits (SOP 3) keep their existing `docs(governance):` format.
This SOP applies only to project code commits.

### Step 1: Parse the Commit Message

Extract the subject line. Validate against the pattern:

```
type(scope): subject
```

Where:
- `type` is one of: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`, `style`, `perf`
- `scope` is optional (parenthesized, e.g., `(T-01)`, `(auth)`, `(api)`)
- `subject` starts lowercase, ≤ 72 characters, no trailing period, imperative mood

### Step 2: Validate

| Check | Rule | On Failure |
|-------|------|-----------|
| Type present | Must start with a valid type | Reject: "Missing or invalid type. Valid types: feat, fix, docs, refactor, test, chore, ci, style, perf" |
| Subject length | ≤ 72 characters | Reject: "Subject line is [N] characters. Maximum is 72." |
| Format match | Matches `type(scope): subject` or `type: subject` | Reject: "Commit message '[first 50 chars]...' does not match conventional format. Expected: type(scope): description" |
| No trailing period | Subject must not end with `.` | Reject: "Remove trailing period from subject line." |

### Step 3: Pass or Reject

- **PASS:** Proceed with commit (SOP 4).
- **REJECT:** Display the specific validation error. Do not commit. Ask user to fix
  the message and retry.

### Governance Bypass

If the commit message starts with `docs(governance):`, skip this SOP entirely —
governance commits follow SOP 3 format which is already conventional-commit-compliant.

---

## Verification Checklist

- [ ] Git initialized (`.git/` folder exists)
- [ ] On branch `main`
- [ ] `.gitignore` excludes non-governance files
- [ ] Staged files are ONLY governance files
- [ ] Commit message includes `[Storyteller: ACTION]` tag (if applicable)
- [ ] `git push` succeeded (no rejection errors)
- [ ] GitHub reflects the new commit within 10 seconds
- [ ] Project commits validated against conventional commit format (SOP 6)
