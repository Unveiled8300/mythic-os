---
name: eval-harness
description: Binary test runner that evaluates a target artifact via task replay. Runs the eval command N times, collects pass/fail results, and returns a structured verdict.
---

# Eval Harness

The eval harness is the **ground truth** for the optimization loop. It runs the evaluation command multiple times, collects results, and produces a binary PASS/FAIL verdict. This is the equivalent of `prepare.py`'s `evaluate_bpb` function in autoresearch — the fixed, trusted metric.

## When to Use

- Called by the `optimize-loop` skill after each iteration
- Can be run standalone to test an artifact without modifying it
- Used by `define-experiment` to establish the baseline

## Inputs

Read from `config.yaml`:
- `evaluation.command` — The command to execute
- `evaluation.timeout_seconds` — Per-trial timeout
- `evaluation.num_trials` — How many times to run the eval
- `evaluation.success_threshold` — Required pass rate
- `evaluation.criteria` — Human-readable criteria (for reporting only)

## Procedure

### Step 1: Load Configuration

```bash
# Read eval parameters from config.yaml
# If config.yaml is not found, STOP and report error
```

Parse the following values:
- `EVAL_CMD` = `evaluation.command`
- `TIMEOUT` = `evaluation.timeout_seconds`
- `NUM_TRIALS` = `evaluation.num_trials`
- `THRESHOLD` = `evaluation.success_threshold`

### Step 2: Execute Trials

Run the eval command `NUM_TRIALS` times sequentially. For each trial:

1. **Start timer:**
   ```bash
   TRIAL_START=$(date +%s)
   ```

2. **Run the eval command with timeout:**
   ```bash
   timeout <TIMEOUT> <EVAL_CMD> > trial_<N>_stdout.tmp 2> trial_<N>_stderr.tmp
   EXIT_CODE=$?
   ```

3. **Record result:**
   - Exit code 0 → `PASS`
   - Exit code 124 (timeout) → `TIMEOUT` (counts as FAIL)
   - Any other exit code → `FAIL`

4. **Capture duration:**
   ```bash
   TRIAL_END=$(date +%s)
   DURATION=$((TRIAL_END - TRIAL_START))
   ```

5. **On failure, capture diagnostic info** (last 50 lines of stderr):
   ```bash
   tail -n 50 trial_<N>_stderr.tmp
   ```

6. **Clean up temp files:**
   ```bash
   rm -f trial_<N>_stdout.tmp trial_<N>_stderr.tmp
   ```

### Step 3: Compute Verdict

```
PASSES = count of trials with exit code 0
FAILS = NUM_TRIALS - PASSES
PASS_RATE = PASSES / NUM_TRIALS

if PASS_RATE >= THRESHOLD:
    VERDICT = "PASS"
else:
    VERDICT = "FAIL"

# Special case: if ALL trials crash (exit code > 1 or timeout), VERDICT = "CRASH"
```

### Step 4: Output Structured Results

Print the results in this exact format (parseable by optimize-loop):

```
========================================
EVAL RESULTS
========================================
verdict:    <PASS|FAIL|CRASH>
pass_rate:  <PASSES>/<NUM_TRIALS> (<PASS_RATE as decimal>)
threshold:  <THRESHOLD>
----------------------------------------
trial_1:    <PASS|FAIL|TIMEOUT> (<DURATION>s)
trial_2:    <PASS|FAIL|TIMEOUT> (<DURATION>s)
trial_3:    <PASS|FAIL|TIMEOUT> (<DURATION>s)
...
trial_N:    <PASS|FAIL|TIMEOUT> (<DURATION>s)
----------------------------------------
```

If any trials failed, also print:

```
FAILURE DETAILS:
--- Trial <N> (FAIL) ---
<last 50 lines of stderr>
---
```

### Step 5: Return Values

The eval harness communicates results to the calling skill via:

1. **Exit code:** 0 for PASS verdict, 1 for FAIL verdict, 2 for CRASH verdict
2. **Structured output** (above format printed to stdout)
3. **Key values extractable via grep:**
   ```bash
   grep "^verdict:" eval_output.log
   grep "^pass_rate:" eval_output.log
   ```

## Helper Script

For convenience, use `scripts/run_eval.sh` to automate the trial loop:

```bash
# Usage:
./skills/eval-harness/scripts/run_eval.sh <EVAL_CMD> <NUM_TRIALS> <TIMEOUT>

# Example:
./skills/eval-harness/scripts/run_eval.sh "./test_skill.sh" 10 120
```

The script handles all the trial execution, timing, output capture, and verdict computation.

## Rules

1. **Never modify the target artifact.** The eval harness is read-only. It only runs tests.
2. **Sequential execution only.** Trials run one at a time, never in parallel. This ensures consistent results and avoids resource contention.
3. **Deterministic timeout.** If a trial exceeds `timeout_seconds`, it is killed and counted as FAIL.
4. **No retries.** A failed trial is a failed trial. The optimize loop decides what to do about it.
5. **Clean up temp files.** Never leave trial output files behind.
6. **Structured output is sacred.** The output format must match exactly — the optimize-loop parses it.

## Task Replay Guidelines

When evaluating non-code artifacts (skills, CLAUDE.md, workflows), the eval command should implement **task replay** — actually using the artifact in a realistic scenario:

### For Skills (SKILL.md)
1. Invoke an agent with the skill loaded
2. Give it a sample task that exercises the skill
3. Check if the agent's output meets the criteria
4. Verify via file system checks, command output, or structured assertions

### For Agent Rules (CLAUDE.md)
1. Apply the CLAUDE.md to an agent session
2. Run a set of representative prompts
3. Check if the agent's responses follow the rules
4. Verify via output parsing and pattern matching

### For Workflows
1. Execute the workflow end-to-end
2. Check each step completed successfully
3. Verify the final output/state matches expectations
4. Check timing, error handling, and edge cases

### For Plugins / Systems
1. Install/activate the plugin
2. Run its core functions
3. Check output correctness and integration points
4. Verify no regressions in existing functionality

> [!TIP]
> The best eval tests are **fast, deterministic, and cheap to run**. A 5-second eval test allows 12 iterations per hour. A 60-second eval test allows only 1 per hour. Optimize your eval for speed without sacrificing accuracy.

---

## Fixture Pattern for Live Skill Tests

When a skill's eval requires testing **behavioral output** (not just text presence), use the fixture pattern to invoke the skill via `claude --print` against pinned fixture data.

### When to Use Live Tests vs. Static Grep

| Approach | When to Use | Speed | Signal Quality |
|---|---|---|---|
| Static grep | Checking that instructions exist in a SKILL.md file | <1s | Low — tests text, not behavior |
| Live execution | Checking that a skill produces correct output | 20-60s | High — tests actual output |

Use static grep as a **pre-screen** to eliminate structurally broken skills quickly. Use live execution to verify behavioral correctness. Combine both in a two-phase eval for maximum efficiency.

### The `claude --print` Invocation Pattern

```bash
claude \
  --print \
  --system-prompt "$(cat <SKILL_FILE>)" \
  --tools "" \
  --permission-mode bypassPermissions \
  --output-format text \
  "$USER_PROMPT" > "$WORK_DIR/output.md"
```

**Flag rationale:**
- `--print` — non-interactive mode; exits after one response
- `--system-prompt "$(cat SKILL.md)"` — loads the skill as the agent's behavior; this is "running the artifact"
- `--tools ""` — disables all tools; output-only mode prevents side effects
- `--permission-mode bypassPermissions` — suppresses interactive permission prompts (required for unattended eval runs)
- `--output-format text` — clean stdout; no JSON envelope to strip

### Speed Trade-off Table

| Eval Type | Typical Duration | Trials/Hour |
|---|---|---|
| Static grep (<1s) | <1s | 3600+ |
| Live execution (20-60s) | ~40s avg | ~60-90 |

Use static grep as Phase 1 to eliminate failing trials before paying the live execution cost. A two-phase design gets most of the speed of static grep while preserving the accuracy of live execution.

### Fixture File Conventions

Store pinned fixture data in `eval-harness/fixtures/`:

| File | Purpose |
|---|---|
| `fixtures/results.tsv` | VAL_SHARD — pinned fixture experiment history with known-correct expected values |
| `fixtures/config.yaml` | Fixture experiment configuration (passed inline, not read from disk) |
| `fixtures/target_artifact.md` | Placeholder artifact for archive steps |

**Fixture design principles (from autoresearch):**
- Choose `pass_rate` values so all `round(pass_rate × 20)` results are exact integers — eliminates rounding ambiguity
- Pre-compute expected values and assert them exactly (e.g., fill=8 for 0.40, fill=20 for 1.00)
- Pass fixture data **inline** in the user prompt, not as file paths — "model only sees what we control"

### User Prompt Construction

Pass all fixture data inline in `$USER_PROMPT`:

```bash
USER_PROMPT="Execute the [skill name] procedure now using the following fixture data.

CONFIG YAML:
${FIXTURE_CONFIG}

RESULTS TSV:
${FIXTURE_RESULTS}

TASK: [imperative instruction]
Output ONLY the complete [output file] content — no explanation, no preamble, no code fences."
```

The imperative framing ("Execute... now") and explicit output constraint ("Output ONLY...") reduce variance in the generated output.

### Assertion Library

Use `eval-harness/scripts/assert_report.sh` for structured assertions:

```bash
source eval-harness/scripts/assert_report.sh

assert_has_section "Pass Rate Over Time" "$REPORT_FILE"   # heading present
assert_bar_at_iter 0 8 "$REPORT_FILE"                      # iter 0: 8 filled chars
assert_bar_at_iter 4 20 "$REPORT_FILE"                     # iter 4: 20 filled chars
assert_numeric_present "0.60" "$REPORT_FILE"               # improvement value present

assert_summary  # prints totals, returns exit code
```

The `assert_bar_at_iter` function includes a **boundary guard**: it checks that the character immediately after the fill string is `░`, preventing a 20-fill bar from passing an 8-fill assertion via substring match.
