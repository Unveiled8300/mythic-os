---
name: git-experiment
description: Create and manage experiment branches for self-reinforced optimization loops. Handles branching, committing, reverting, and branch hygiene.
---

# Git Experiment Branch Management

This skill manages the git lifecycle for optimization experiments. Every experiment runs on a dedicated branch so the main branch is never polluted with failed attempts.

## Prerequisites

- The target repository must be a git repo with at least one commit.
- The working tree must be clean before starting (no uncommitted changes).

## Branch Naming Convention

Experiment branches follow this pattern:

```
experiment/<tag>
```

Where `<tag>` is a user-provided or auto-generated identifier. Examples:
- `experiment/mar27-skill-optimize`
- `experiment/v2-claude-md`
- `experiment/workflow-deploy-fix`

## Operations

### 1. Create Experiment Branch

**When to use:** At the start of a new optimization experiment.

**Steps:**

1. Verify the working tree is clean:
   ```bash
   git status --porcelain
   ```
   - If output is non-empty, STOP and report that there are uncommitted changes.

2. Check that the branch does not already exist:
   ```bash
   git branch --list "experiment/<tag>"
   ```
   - If it exists, STOP and report the conflict. Suggest a different tag.

3. Create and switch to the experiment branch from the current HEAD:
   ```bash
   git checkout -b "experiment/<tag>"
   ```

4. Confirm the branch was created:
   ```bash
   git branch --show-current
   ```

### 2. Commit an Experiment Iteration

**When to use:** After modifying the target artifact, before running evaluation.

**Steps:**

1. Stage ONLY the target artifact file (never stage `results.tsv` or other generated files):
   ```bash
   git add <TARGET_ARTIFACT_PATH>
   ```

2. Commit with a descriptive message following this format:
   ```bash
   git commit -m "experiment: <1-line description of what changed>"
   ```
   Example: `git commit -m "experiment: increase context window instructions to 4096 tokens"`

3. Record the short commit hash for the results log:
   ```bash
   git rev-parse --short HEAD
   ```

### 3. Revert a Failed Experiment

**When to use:** When an experiment's evaluation results in `discard` or `crash`.

**Steps:**

1. Reset to the previous commit (the last known-good state):
   ```bash
   git reset --hard HEAD~1
   ```

2. Verify the revert was successful:
   ```bash
   git log --oneline -1
   ```

> [!CAUTION]
> `git reset --hard` is destructive. The discarded commit is still recoverable via `git reflog` for 90 days, but is no longer on the branch.

### 4. Revert to a Specific Commit

**When to use:** When stuck after many consecutive failures and you want to jump back to an earlier known-good state.

**Steps:**

1. Find the target commit hash from `results.tsv` (look for `keep` status entries).

2. Reset to that commit:
   ```bash
   git reset --hard <commit_hash>
   ```

3. Verify:
   ```bash
   git log --oneline -3
   ```

### 5. View Experiment History

**When to use:** To understand what's been tried on this branch.

```bash
git log --oneline --no-decorate experiment/<tag>
```

### 6. Finalize Experiment

**When to use:** After the optimization loop completes (threshold reached or max iterations hit).

**Steps:**

1. Ensure the branch tip is the best result (it should be, by construction).

2. Create an archive of the experiment artifacts:
   ```bash
   mkdir -p experiments/<tag>
   cp results.tsv experiments/<tag>/
   cp <TARGET_ARTIFACT_PATH> experiments/<tag>/final_artifact_snapshot
   ```

3. Optionally merge back to main:
   ```bash
   git checkout main
   git merge experiment/<tag> --no-ff -m "merge: experiment/<tag> — <summary of improvement>"
   ```

> [!NOTE]
> The merge step is optional and should only be done if the user explicitly requests it. The experiment branch is preserved either way.

## Rules

1. **Never commit `results.tsv`** to the experiment branch. It stays untracked so git history only contains artifact changes.
2. **One artifact per commit.** Each commit should represent exactly one experimental modification.
3. **Branch tip = current best.** After any discard, the branch tip is always reset to the last `keep` commit.
4. **Never force-push experiment branches.** Use `git reset --hard` locally only.
5. **Tag conventions are lowercase with hyphens.** No spaces, underscores, or special characters.
