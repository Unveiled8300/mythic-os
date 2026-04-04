---
name: git-tag
description: >
  Create annotated git tags for governance milestones (sprints, releases,
  architecture checkpoints). Tagged commits become GitHub Releases for
  historical reference and rollback targets.
version: 1.0.0
slash_command: /git-tag
trigger_pattern: "Vendor Manager: GIT-TAG|create a release tag|tag this milestone"
---

# Skill: Git Tag

Create milestone tags for governance checkpoints, sprints, and releases.

---

## SOP 1: Capture Tag Name

Ask the user for the tag name. Tag names should follow this format:

**Format:** `v[YYYYMMDD]-[kebab-case-description]`

**Examples:**
- `v2026-03-14-initial-governance`
- `v2026-03-14-sprint-1-complete`
- `v2026-03-14-git-automation-checkpoint`
- `v2026-03-21-major-library-restructure`

**Rules:**
- Always start with `v` (for version)
- Always include date in YYYYMMDD format (prevents tag collisions across months)
- Use kebab-case (hyphens, lowercase) for description
- Keep description concise (< 50 chars total after date)

**How to prompt:**
```
What milestone should this tag mark? (e.g., "sprint-1-complete")
→ Tag will be: v2026-03-14-[your description]
```

If the user provides an invalid format, suggest the corrected format and re-ask.

---

## SOP 2: Validate Tag Format

Verify the tag name before creating:

```bash
# Check if tag already exists
git tag -l "[TAG_NAME]"
```

- If tag exists: ❌ warn user that tag already exists, ask to use a different name
- If tag is valid (doesn't exist, matches format): ✅ proceed

---

## SOP 3: Confirm the Milestone

Ask user to confirm what this tag represents:

```
Tag: v2026-03-14-sprint-1-complete
This tag will mark: [user's description]
Current commit: [git rev-parse HEAD --short]
Branch: [git branch --show-current]

Create tag? (yes/no)
```

If user answers "no": cancel and exit.
If user answers "yes": proceed to SOP 4.

---

## SOP 4: Create Annotated Tag

Create the tag with a message (annotated tags are preferred over lightweight tags):

```bash
git tag -a [TAG_NAME] -m "Milestone: [description]. Governance checkpoint v2026-03-14."
```

Example:
```bash
git tag -a v2026-03-14-sprint-1-complete -m "Milestone: Sprint 1 governance complete. All rules, skills, LIBRARY.md updated."
```

Verify tag was created:
```bash
git tag -l | grep [TAG_NAME]
```

---

## SOP 5: Push Tag to GitHub

Push the tag to the remote:

```bash
git push origin [TAG_NAME]
```

**Handle push failures:**
- If rejected: inform user, ask to retry
- If remote unreachable: inform user and defer to next sync

Verify push:
```bash
git ls-remote origin [TAG_NAME]
```

---

## SOP 6: Report and Link to GitHub Release

Return structured report:

```
✅ TAG CREATED

Tag: [TAG_NAME]
Commit: [commit hash]
Message: Milestone: [description]
Branch: main
Status: pushed to origin

GitHub Release: https://github.com/[YOUR_ORG]/[YOUR_REPO]/releases/tag/[TAG_NAME]
```

**Note to user:** The tag is now visible on GitHub Releases page. You can later edit the release notes if needed.

If any step failed:
```
❌ TAG CREATION FAILED

Step: [SOP step that failed]
Error: [error message]
Action: [user should check tag format, verify git access, etc.]
```

---

## Usage Patterns

### Pattern A: Tag After Major Governance Checkpoint
```
[Complete sprint or major architecture update]

/git-tag
  → Prompted: "What milestone?"
  → User: "sprint-1-complete"
  → Tag created: v2026-03-14-sprint-1-complete
  → GitHub Release created
```

### Pattern B: Tag Before Major Refactor
```
[Before restructuring LIBRARY.md or significant rule changes]

/git-tag v2026-03-14-pre-refactor
  → Creates rollback checkpoint
  → If refactor goes wrong, can revert to this tag
```

### Pattern C: Combine with git-sync
```
Storyteller: ON CREATE — major-new-role
Vendor Manager: GIT-SYNC
  → [new role committed]

/git-tag v2026-03-14-new-role-added
  → [milestone tagged]

Result: GitHub shows both commit and tagged milestone
```

---

## Verification Checklist

- [ ] Tag name follows format: `v[YYYYMMDD]-[description]`
- [ ] Tag does not already exist
- [ ] Tag message is descriptive
- [ ] `git push origin [TAG_NAME]` succeeded
- [ ] GitHub Releases page lists the tag
- [ ] Can retrieve tag info: `git show [TAG_NAME]`
