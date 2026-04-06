---
name: define-experiment
description: Define and configure a self-reinforced optimization experiment. Produces a config.yaml that all other skills consume. Optionally generates eval test scripts from criteria.
---

# Define Experiment

This skill sets up a new optimization experiment by creating a structured configuration. It ensures all prerequisites are met and produces the `config.yaml` that drives the entire optimization loop.

## When to Use

- Starting a new optimization experiment on any target artifact
- The user has identified what they want to improve and has (or wants to create) evaluation criteria

## Inputs

The user provides (interactively or via parameters):

| Input | Required | Description |
|---|---|---|
| Target artifact path | Yes | Relative path to the file being optimized |
| Experiment tag | Yes | Short identifier (e.g., `mar27-skill-v2`) |
| Eval criteria | Yes | List of binary pass/fail conditions |
| Eval command | No | Command to run for evaluation (can be generated) |
| Context files | No | Additional read-only files for the agent to reference |
| Num trials | No | Number of times to run eval per iteration (default: 5) |
| Success threshold | No | Fraction of trials that must pass (default: 0.8) |
| Max iterations | No | Max experiment iterations (default: 30) |
| Iteration timeout | No | Seconds before killing a single eval run (default: 120) |

## Procedure

### Step 1: Validate Prerequisites

1. Confirm the current directory is a git repository:
   ```bash
   git rev-parse --is-inside-work-tree
   ```

2. Confirm the target artifact exists:
   ```bash
   test -f <TARGET_ARTIFACT_PATH> && echo "EXISTS" || echo "MISSING"
   ```

3. Confirm the working tree is clean:
   ```bash
   git status --porcelain
   ```

### Step 2: Gather Configuration

If the user has not provided all inputs, interactively prompt for them:

1. **Target artifact(s):** Ask what file(s) they want to optimize.
   - **Single artifact:** A single file path. Stored as `target.artifact`.
   - **Artifact group:** Multiple related files that must be modified and evaluated as a unit. Stored as `target.artifact_group` (list of paths). Use this when changes to one file require coordinated changes to others (e.g., a skill and its sub-skills, a config and its consumer).
   
   Validate all files exist. If `artifact_group` is specified, `artifact` is ignored.

2. **Experiment tag:** Propose a tag based on today's date and the artifact name.
   - Format: `<month><day>-<artifact-shortname>` (e.g., `mar27-claude-md`)
   - Verify the branch `experiment/<tag>` does not already exist.

3. **Eval criteria:** Ask the user to list the binary pass/fail conditions. Each criterion must be:
   - Clearly stated as a yes/no question or assertion
   - Independently testable
   - Objective (not subjective/aesthetic)

   **Good criteria examples:**
   - "The agent creates files in the correct directory"
   - "The output contains valid JSON"
   - "The workflow completes without errors"
   - "The agent does not use deprecated API calls"

   **Bad criteria examples (too subjective):**
   - "The code is clean" (what defines "clean"?)
   - "The output looks good" (not binary)

4. **Eval command:** If the user provides one, validate it. If not, offer to generate one (see Step 3).

5. **Context files:** Ask what additional files the agent should read for context when making modifications.

6. **Numeric parameters:** Use defaults unless the user specifies otherwise.

### Step 3: Generate or Validate Eval Script

**Option A: User provides an eval command**

1. Run the command once to verify it works:
   ```bash
   <EVAL_COMMAND>
   ```
2. Check the exit code. Must exit 0 on pass, non-zero on fail.
3. If it fails, work with the user to fix it before proceeding.

**Option B: Generate eval script from criteria (Task Replay)**

When the user wants the agent to generate the eval tests, create a test script that:

1. **Sets up a test scenario** — Creates a temporary workspace with the target artifact installed/active
2. **Runs a real task** — Executes a representative task that exercises the artifact
3. **Checks criteria** — Validates each criterion against the actual task output
4. **Reports binary result** — Exits 0 if all criteria pass, non-zero if any fail

The generated eval script should follow this template:

```bash
#!/bin/bash
# Auto-generated eval script for: <TARGET_ARTIFACT>
# Criteria:
#   1. <criterion_1>
#   2. <criterion_2>
#   ...
#
# Usage: ./eval_test.sh
# Exit 0 = PASS, Exit 1 = FAIL

set -euo pipefail

PASS=0
FAIL=0
TOTAL=<num_criteria>

echo "=== Eval: <EXPERIMENT_TAG> ==="
echo "Target: <TARGET_ARTIFACT>"
echo ""

# --- Criterion 1: <criterion_1> ---
echo -n "Criterion 1: <criterion_1> ... "
if <test_command_for_criterion_1>; then
  echo "PASS"
  ((PASS++))
else
  echo "FAIL"
  ((FAIL++))
fi

# ... repeat for each criterion ...

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL/$TOTAL failed"

if [ "$FAIL" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
else
  echo "VERDICT: FAIL"
  exit 1
fi
```

> [!IMPORTANT]
> For task replay evaluations (testing skills, CLAUDE.md, agents, etc.), the eval script must:
> 1. **Invoke the artifact in a real context** — e.g., run an agent with the CLAUDE.md applied, execute a workflow, use a skill
> 2. **Capture the actual output** — stdout, stderr, created files, etc.
> 3. **Check each criterion against real output** — not hypothetical, not LLM-judged
> The test should be as close to real usage as possible. This is what makes the eval objective.

### Step 4: Create Config File

Write `config.yaml` to the project root (or a user-specified location):

```yaml
# Auto-generated by define-experiment skill
# Created: <ISO_TIMESTAMP>

experiment:
  tag: "<tag>"
  created: "<ISO_TIMESTAMP>"
  status: "active"          # active | completed | abandoned

target:
  artifact: "<relative_path>"            # Single file mode
  artifact_group:                         # Multi-file mode (takes precedence if present)
    - "<relative_path_1>"
    - "<relative_path_2>"
  context_files:
    - "<file_1>"
    - "<file_2>"

evaluation:
  command: "<eval_command>"
  mode: "shell"                           # shell (default) | agent
  agent_config:                           # Only used when mode: agent
    task_prompt: "<sample task for the artifact>"
    criteria_checks:                      # Criteria mapped to output assertions
      - criterion: "<criterion text>"
        assertion: "<grep pattern or check to run against agent output>"
    model: "sonnet"                       # Model for eval agent (default: sonnet for cost)
    timeout_seconds: 120                  # Per-agent-invocation timeout
  models:                                 # Optional: cross-model evaluation
    - "claude-opus-4-6"
    - "claude-sonnet-4-6"
  timeout_seconds: <timeout>
  criteria:
    - "<criterion_1>"
    - "<criterion_2>"
  num_trials: <num_trials>
  success_threshold: <threshold>

optimization:
  max_iterations: <max_iterations>
  branch: "experiment/<tag>"

history:
  results_file: "results.tsv"
  report_dir: "experiments/<tag>"
```

### Step 5: Initialize Experiment

1. **Create the experiment branch** (invoke `git-experiment` skill, Operation 1).

2. **Initialize `results.tsv`** with just the header row:
   ```bash
   printf 'iteration\tcommit\tpass_rate\tstatus\tdescription\n' > results.tsv
   ```

3. **Run baseline** — Execute the eval harness against the unmodified artifact:
   ```bash
   <EVAL_COMMAND>
   ```
   Record the result as iteration 0 with status `baseline`:
   ```
   0	<commit_hash>	<pass_rate>	baseline	unmodified artifact
   ```

4. **Confirm setup** — Print a summary:
   ```
   ✓ Experiment configured: <tag>
   ✓ Branch: experiment/<tag>
   ✓ Target: <artifact_path>
   ✓ Eval: <eval_command>
   ✓ Criteria: <N> criteria defined
   ✓ Baseline: <pass_rate> pass rate
   ✓ Threshold: <success_threshold>
   ✓ Max iterations: <max_iterations>
   
   Ready to optimize. Invoke the optimize-loop skill to begin.
   ```

## Output

- `config.yaml` — Experiment configuration file
- `results.tsv` — Initialized with header + baseline row
- Experiment branch created and checked out
- Eval script created (if generated)

## Rules

1. **Never modify the target artifact during setup.** The baseline must be the unmodified version.
2. **Always validate the eval command works** before writing the config.
3. **Criteria must be binary.** If a criterion can't be expressed as pass/fail, help the user reformulate it.
4. **Tag must be unique.** No two experiments share the same tag.
5. **Config.yaml is the single source of truth** for the experiment. All other skills read from it.
