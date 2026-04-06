---
name: arena-run-matchup
description: >
  Executes all contestants in an arena matchup. Called after arena/SKILL.md has created the
  config.yaml and workspace. Runs each contestant on each task in isolated directories,
  captures output, timing, and exit codes. Does NOT score — that's scorecard's job.
---

# Arena: Run Matchup

You are executing the arena matchup. Read `config.yaml`, run each contestant on each task
in isolated workspaces, and capture all outputs for scoring.

## Prerequisites

- `config.yaml` exists and is valid
- `scoreboard.tsv` exists with header row
- Workspace root directory exists (`arena-workspaces/<tag>/`)

## Step 1: Load Configuration

Read `config.yaml`. Extract:
- Contestant list (name, setup, run)
- Task list (name, prompt, context_files, repetitions, timeout)
- Workspace root path

## Step 2: Execute Matchup

For each task, for each contestant, for each repetition:

### 2a: Create Isolated Workspace

```bash
WORKSPACE="arena-workspaces/<tag>/contestants/<contestant-name>/<task-name>/rep-<N>"
mkdir -p "$WORKSPACE"
cd "$WORKSPACE"
git init --quiet
```

**Why separate directories (not worktrees):** Worktrees share `.git`, which would cross-contaminate
commit history between contestants. Separate directories with independent `git init` ensure true
isolation.

### 2b: Copy Shared Context

```bash
# Copy any shared context files into the workspace
for file in <context_files>; do
    cp "arena-workspaces/<tag>/shared/$file" "$WORKSPACE/"
done
```

### 2c: Run Setup

If the contestant has a `setup` command:
```bash
export WORKSPACE="$WORKSPACE"
export TASK_PROMPT="<task prompt>"
export TASK_NAME="<task name>"
export OUTPUT_DIR="$WORKSPACE"
eval "<setup command>"
```

### 2d: Execute Contestant

```bash
START_TIME=$(date +%s)

export WORKSPACE="$WORKSPACE"
export TASK_PROMPT="<task prompt>"
export TASK_NAME="<task name>"
export OUTPUT_DIR="$WORKSPACE"

timeout <timeout_seconds> bash -c '<run command>' \
    > "$WORKSPACE/build.log" 2>&1
EXIT_CODE=$?

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
```

### 2e: Record Metadata

Write `$WORKSPACE/meta.json`:
```json
{
    "contestant": "<name>",
    "task": "<task name>",
    "repetition": <N>,
    "exit_code": <exit_code>,
    "duration_seconds": <duration>,
    "timeout": <true|false>,
    "timestamp": "<ISO>"
}
```

### 2f: Log Progress

After each execution, print:
```
[<contestant>] <task> rep <N>: exit=<code> time=<duration>s
```

## Step 3: Execution Order

- **Sequential by contestant** — Avoids resource contention (each contestant may use significant
  CPU, memory, or API calls).
- **All tasks for one contestant before moving to the next** — Keeps context coherent.
- **Repetitions within a task are sequential** — Ensures each rep starts from a clean state.

Order: contestant 1 → (task 1 rep 1, task 1 rep 2, ..., task 2 rep 1, ...) → contestant 2 → ...

## Step 4: Completion Summary

After all executions complete:

```
========================================
ARENA EXECUTION COMPLETE
========================================
tag:            <tag>
contestants:    <N>
tasks:          <N>
repetitions:    <N per task>
total_runs:     <total>
----------------------------------------
<contestant-1>: <N> runs, <N> exits=0, avg <X>s
<contestant-2>: <N> runs, <N> exits=0, avg <X>s
...
========================================

All outputs in: arena-workspaces/<tag>/contestants/
Run the scorecard skill to score and rank contestants.
```

## Rules

1. **Never modify contestant outputs.** Capture only; scoring is scorecard's job.
2. **Respect timeouts strictly.** A timed-out execution gets exit code 124, logged as timeout.
3. **Isolated workspaces.** Each contestant-task-rep gets its own directory. No sharing.
4. **Deterministic ordering.** Same config always produces same execution order.
5. **No early termination.** Run all contestants even if some fail. Failures are data.
6. **Clean environment per run.** Each execution starts with only the shared context files.
