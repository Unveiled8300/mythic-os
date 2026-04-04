---
name: project-plans
description: >
  Project plan filing skill. Triggers on `/project-plan` or phrases like "save this plan",
  "file this plan", or "save plan locally". Saves the current plan content to `.plans/` in
  the current working directory using a chronological `YYYYMMDD-HHMMSS-[kebab-slug].md`
  naming convention. Works agnostically across any project type with no configuration.
version: 1.0.0
---

# /project-plan — Save Plan to Project Directory

You are executing the Project Plan Filing sequence. Your job is to write a plan file into the
current working directory so it lives with the project, stays chronological, and is readable
without any tooling.

---

## Placement Guide

Plans always go here:

```
[project-root]/
└── .plans/
    ├── 20260328-143022-initial-auth-design.md
    ├── 20260328-160511-refactor-api-routes.md
    └── 20260401-092233-add-dashboard-feature.md
```

**Folder:** `.plans/` at the project root (current working directory).
- Dot-prefixed: kept out of casual `ls` output, not buried in a tool-specific subdirectory.
- **Tracked or ignored:** Your choice. Commit plans for team visibility; add `.plans/` to `.gitignore` for private scratch plans.

**File name format:** `YYYYMMDD-HHMMSS-[kebab-slug].md`
- `YYYYMMDD-HHMMSS` — timestamp guarantees lexicographic sort = chronological sort.
- `[kebab-slug]` — 3–6 words, lowercase, hyphens only (e.g., `add-user-auth`, `migrate-db-schema`, `refactor-payment-flow`).
- Never use spaces, camelCase, or underscores in the slug.

---

## Step 1: Resolve the Plan Title

If the user invoked `/project-plan [title]` — use that title as the slug source.

If no title was provided, ask:
> "What is this plan for? Give me a short title (3–6 words)."

Wait for the answer before continuing.

---

## Step 2: Generate Timestamp and Filename

Run this command to get the current timestamp:

```bash
date +%Y%m%d-%H%M%S
```

Convert the user's title to a kebab slug:
- Lowercase everything
- Replace spaces with hyphens
- Strip punctuation (apostrophes, commas, colons, slashes, etc.)
- Truncate to 6 words maximum

Compose the filename:
```
[timestamp]-[kebab-slug].md
```

Example: title "Add user authentication with OAuth" → `20260328-143022-add-user-authentication-oauth.md`

---

## Step 3: Create the Folder (if needed)

Check whether `.plans/` exists in the current working directory.
If not, create it:

```bash
mkdir -p .plans
```

Do not create it anywhere other than the current working directory.

---

## Step 4: Write the Plan File

Write the plan content to `.plans/[filename]`.

### Required Plan Structure

Every plan file must include these sections. Fill in what is known; leave sections marked
`TBD` if they haven't been determined yet.

```markdown
# Plan: [Human-readable title]
**Date:** [YYYY-MM-DD]
**File:** `.plans/[filename]`
**Status:** draft | approved | superseded

---

## Context
[Why this plan exists. What problem or need prompted it. 2–5 sentences.]

## Approach
[The recommended implementation strategy. What will be built, changed, or configured.
Include key decisions and the reasoning behind them.]

## Steps
1. [Step one]
2. [Step two]
3. ...

## Files Affected
| File | Action |
|------|--------|
| [path] | create / modify / delete |

## Verification
[How to confirm this plan was executed correctly. What to run, check, or observe.]

## Out of Scope
[What this plan explicitly does NOT cover.]
```

If the user already has plan content from a previous planning session, incorporate it
directly into the appropriate sections rather than starting blank.

---

## Step 5: Report

After writing the file, report:

```
Plan saved → .plans/[filename]

To view: cat .plans/[filename]
To list all plans: ls -1 .plans/
```

If `.plans/` was newly created, add:
```
Folder created: .plans/
Consider adding to .gitignore if these plans are private scratch notes.
```

---

## Rules

- Always save to `.plans/` in the **current working directory** — never to `~/.claude/plans/` or any global location.
- Never overwrite an existing plan file. If a slug collision occurs (same title within the same second), append `-2` to the slug.
- The timestamp comes from the `date` command — never hardcode or guess it.
- If the cwd cannot be determined, stop and report: "Cannot determine working directory. Please confirm your project root."
