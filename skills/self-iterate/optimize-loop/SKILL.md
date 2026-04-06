---
name: optimize-loop
description: Core autonomous iteration engine for self-reinforced optimization. Modifies target artifacts, evaluates via task replay, keeps improvements, discards regressions, and logs everything.
---

# Optimize Loop

This is the core engine — the equivalent of autoresearch's `program.md` experimentation loop. Once started, it runs autonomously: modifying the target artifact, evaluating the result, keeping improvements, reverting failures, and logging everything.

## When to Use

- After `define-experiment` has created `config.yaml`, `results.tsv`, and the experiment branch
- The user says "start optimizing" or "begin the loop"

## Prerequisites

- `config.yaml` exists and is valid
- `results.tsv` exists with at least the header row (and ideally a baseline)
- The experiment branch is checked out
- The eval command runs successfully

## Procedure

### Phase 0: Load State

1. **Read `config.yaml`** and extract all configuration values.

2. **Read `results.tsv`** to understand experiment history:
   ```bash
   cat results.tsv
   ```
   - Determine the current iteration number (last row's iteration + 1)
   - Determine the current best pass rate (highest pass_rate among `keep` and `baseline` rows)
   - Review what has been tried before (descriptions column)

3. **Read the target artifact(s)** in full:
   - If `target.artifact_group` is defined: read ALL files in the group.
   - If only `target.artifact` is defined: read that single file.
   ```bash
   # Single mode:
   cat <TARGET_ARTIFACT>
   # Group mode:
   cat <GROUP_FILE_1>
   cat <GROUP_FILE_2>
   # ... for each file in artifact_group
   ```

4. **Read all context files** listed in `config.yaml`:
   ```bash
   cat <CONTEXT_FILE_1>
   cat <CONTEXT_FILE_2>
   ```

4b. **Read prior experiment patterns** (if any exist):
   ```bash
   ls experiments/*/patterns.md 2>/dev/null
   ```
   If pattern files exist, read ALL of them. Extract:
   - Which strategy types were effective for similar artifact types
   - Which strategy types consistently failed
   - Any anti-patterns to avoid
   - Cross-experiment insights
   
   Use this knowledge to bias Phase 1 strategy selection:
   - **Prioritize** strategy types with `outcome: keep` in prior patterns for the same `artifact_type`
   - **Deprioritize** (but don't exclude) strategy types that appear in anti-patterns
   - **Apply** cross-experiment insights as additional context for modification planning
   
   If no pattern files exist, proceed as before (no bias).

5. **Verify branch state:**
   ```bash
   git branch --show-current
   # Must be experiment/<tag>
   ```

### Phase 1: Plan Modification

Based on your understanding of:
- The target artifact's current content
- The evaluation criteria
- What has been tried before (results.tsv)
- What worked and what didn't

Propose a **single, focused modification** to the target artifact(s). The modification should:
- Address a specific criterion that may be failing
- Be small enough to isolate its effect
- Be clearly describable in one line

**Artifact group mode:** When operating on an artifact group, the modification may target any file in the group. State which file(s) will be changed and why. The modification should still be focused — changing all files simultaneously is discouraged. Prefer changing the fewest files necessary to address the failing criterion.

**Pattern-informed strategy selection:** If prior experiment patterns were loaded in Phase 0 step 4b, use them to inform strategy choice. If patterns show a strategy was effective on similar artifact types, try that first. If patterns show a strategy consistently failed, try other approaches first. Patterns are guidance, not deterministic — creative exploration still matters. After exhausting pattern-informed strategies, try novel approaches.

Write a 1-line description of the change before making it.

**Modification strategies** (try in roughly this order):

1. **Fix obvious gaps** — If criteria are failing because something is missing, add it
2. **Clarify ambiguous instructions** — Make vague language specific
3. **Add explicit constraints** — "MUST", "NEVER", "ALWAYS" directives
4. **Add examples** — Concrete examples improve compliance
5. **Restructure for clarity** — Reorder sections for logical flow
6. **Remove noise** — Delete instructions that conflict or confuse
7. **Add error handling** — Anticipate edge cases
8. **Simplify** — Fewer words, same meaning (simplicity wins, per autoresearch)

### Phase 2: Apply & Commit

1. **Edit the target artifact(s)** with the planned modification.

2. **Commit the change** (invoke `git-experiment` skill, Operation 2):
   ```bash
   # Single mode:
   git add <TARGET_ARTIFACT>
   # Group mode — stage only files actually modified this iteration:
   git add <MODIFIED_GROUP_FILE_1> <MODIFIED_GROUP_FILE_2>
   git commit -m "experiment: <1-line description>"
   ```

3. **Record the commit hash:**
   ```bash
   COMMIT=$(git rev-parse --short HEAD)
   ```

### Phase 3: Evaluate

1. **Run the eval harness** (invoke `eval-harness` skill):
   ```bash
   <EVAL_COMMAND> > eval_output.log 2>&1
   ```
   Or use the helper script:
   ```bash
   bash skills/eval-harness/scripts/run_eval.sh "<EVAL_COMMAND>" <NUM_TRIALS> <TIMEOUT> <THRESHOLD> > eval_output.log 2>&1
   EVAL_EXIT=$?
   ```

2. **Extract results:**
   ```bash
   grep "^verdict:" eval_output.log
   grep "^pass_rate:" eval_output.log
   ```

3. **Parse the pass rate** into a comparable number.

   If `evaluation.models` is configured, the eval harness returns per-model pass rates and an overall average. Use the overall average for the Phase 4 grade decision. Log per-model breakdown in the description column of results.tsv for pattern analysis.

### Phase 4: Grade & Decide

Apply these rules strictly:

| Condition | Status | Action |
|---|---|---|
| PASS verdict AND pass_rate > current_best | `keep` | Advance — this is the new best |
| PASS verdict AND pass_rate == current_best | `keep` | Advance — equal is worth keeping if simpler |
| PASS verdict AND pass_rate < current_best | `discard` | Revert — regression |
| FAIL verdict | `discard` | Revert — did not meet threshold |
| CRASH verdict (all trials crashed) | `crash` | Revert — broken change |

**Simplicity criterion** (borrowed from autoresearch):
> All else being equal, simpler is better. A tiny improvement that adds ugly complexity is not worth it. Removing something and getting equal or better results is a great outcome — that's a simplification win.

### Phase 5: Execute Decision

**If `keep`:**
- The commit stays on the branch (branch advances)
- Update `current_best` to the new pass_rate
- Log to results.tsv

**If `discard` or `crash`:**
- Revert to previous commit (invoke `git-experiment` skill, Operation 3):
  ```bash
  git reset --hard HEAD~1
  ```
- Log to results.tsv with the appropriate status

**On crash — attempt recovery:**
1. Read the failure details from eval output
2. If the error is trivially fixable (typo, syntax error), fix and re-run the same experiment
3. If the error is fundamental (the idea is broken), skip it and move on
4. Maximum 2 fix attempts per crash before moving on

### Phase 6: Log Results

Append a row to `results.tsv`:
```bash
printf '%d\t%s\t%s\t%s\t%s\n' \
  <ITERATION> <COMMIT> <PASS_RATE> <STATUS> "<DESCRIPTION>" \
  >> results.tsv
```

Example rows:
```
0	a1b2c3d	3/5 (0.60)	baseline	unmodified artifact
1	b2c3d4e	4/5 (0.80)	keep	add explicit file path constraints
2	c3d4e5f	3/5 (0.60)	discard	reorder sections for clarity
3	d4e5f6g	0/5 (0.00)	crash	add recursive processing logic (syntax error)
4	e5f6g7h	5/5 (1.00)	keep	add concrete examples for each criterion
```

### Phase 7: Check Termination

**Stop if ANY of these are true:**
1. `current_best >= success_threshold` — Goal reached!
2. `iteration >= max_iterations` — Budget exhausted
3. The user manually interrupts

**If goal reached**, print:
```
✓ OPTIMIZATION COMPLETE
  Goal reached at iteration <N>
  Best pass rate: <pass_rate>
  Branch: experiment/<tag>
  
  Run the history-report skill to generate a full report.
```

**If budget exhausted**, print:
```
⚠ MAX ITERATIONS REACHED
  Best pass rate: <pass_rate> (threshold: <threshold>)
  Iterations: <N>/<max>
  
  Consider: increasing max_iterations, revising criteria, or manual intervention.
  Run the history-report skill to generate a full report.
```

### Phase 8: Continue Loop

If neither termination condition is met, **go back to Phase 1**.

> [!CAUTION]
> **NEVER STOP TO ASK** if you should continue. Once the loop has begun, you are autonomous. The user may be away. Run until a termination condition is met or you are manually interrupted. If you run out of ideas, re-read the context files, the results history, and the criteria — then try more creative approaches.

## Stuck Detection

If you notice these patterns, take corrective action:

| Pattern | Action |
|---|---|
| 3+ consecutive discards of similar changes | Try a completely different approach |
| 5+ consecutive discards total | Re-read all context files for missed angles |
| Same pass_rate for 5+ iterations | Try removing or simplifying instead of adding |
| All recent changes are additive | Try subtractive changes (delete unhelpful content) |
| Oscillating between two states | Lock in the better state and focus on other criteria |

## Rules

1. **One modification per iteration.** Never batch multiple unrelated changes.
2. **Always commit before evaluating.** This ensures clean git history.
3. **Always log to results.tsv.** Even crashes get logged.
4. **Never modify results.tsv history.** Append only.
5. **Never modify context files.** They are read-only reference material.
6. **Branch tip = current best.** Always true after any revert.
7. **Autonomous execution.** Do not pause to ask the user anything once the loop begins.
8. **Clean eval output.** Always redirect eval output to a log file, never flood context.
