---
name: history-report
description: Generate a structured learning report from experiment results. Produces a permanent record of what was tried, what worked, what failed, and recommendations for future optimization.
---

# History Report

This skill generates a comprehensive, human-readable report from an experiment's `results.tsv`. The report serves as **institutional memory** — future optimization runs should read past reports to avoid repeating failed approaches.

## When to Use

- After an optimization loop completes (goal reached or max iterations hit)
- When a user wants to review experiment progress mid-run
- When starting a new experiment on the same target (read past reports first)

## Inputs

- `config.yaml` — Experiment configuration
- `results.tsv` — Full experiment history
- Target artifact (current version)
- Git log of the experiment branch

## Procedure

### Step 1: Gather Data

1. **Read `config.yaml`:**
   ```bash
   cat config.yaml
   ```

2. **Read `results.tsv`:**
   ```bash
   cat results.tsv
   ```

3. **Read the final target artifact:**
   ```bash
   cat <TARGET_ARTIFACT>
   ```

4. **Get git log for the experiment branch:**
   ```bash
   git log --oneline experiment/<tag>
   ```

5. **Check for previous reports** in `experiments/` directory:
   ```bash
   ls experiments/*/report.md 2>/dev/null
   ```

### Step 2: Compute Statistics

From results.tsv, calculate:

| Metric | Calculation |
|---|---|
| Total iterations | Count of rows (excluding header) |
| Keep rate | `count(status=keep) / total iterations` |
| Discard rate | `count(status=discard) / total iterations` |
| Crash rate | `count(status=crash) / total iterations` |
| Best pass rate | Max `pass_rate` among `keep` rows |
| Baseline pass rate | `pass_rate` of `baseline` row |
| Improvement | `best - baseline` |
| Consecutive discards (max) | Longest streak of consecutive `discard` statuses |
| Iterations to best | Iteration number where best pass_rate was first achieved |

### Step 3: Analyze Patterns

Review the results and identify:

1. **What worked** — Changes that resulted in `keep` status. What do they have in common?
2. **What failed** — Changes that resulted in `discard`. Are there patterns?
3. **Crash causes** — What kinds of changes caused crashes?
4. **Diminishing returns** — Did improvements slow down over time?
5. **Stuck periods** — Were there long streaks of discards?

### Step 3.5: Render the ASCII Bar Chart

Before generating the report, render the `{{PASS_RATE_CHART}}` as an ASCII bar chart showing pass rate progression over iterations. Use this format:

```
Pass Rate Over Time:

iter 0 (baseline) : ████████░░░░░░░░░░░░ 0.80
iter 1 (keep)     : ████████████████░░░░ 0.80
iter 2 (discard)  : ████████░░░░░░░░░░░░ 0.60
iter 3 (keep)     : ████████████████████ 1.00
```

Rules:
- Each bar is 20 characters wide: `█` for filled (pass), `░` for empty
- Fill = `round(pass_rate × 20)` characters
- Right-align the pass_rate decimal after the bar
- Show iteration number, status, and bar on each line
- Baseline row comes first, then iterations in order

Use this rendered ASCII string as the `{{PASS_RATE_CHART}}` value in the template.

### Step 4: Generate Report

Create the report at `experiments/<tag>/report.md` using the template in `resources/report_template.md`.

The report must include ALL of the following sections:

1. **Header** — Experiment tag, date, target artifact, branch
2. **Summary** — One-paragraph overview of the experiment outcome
3. **Configuration** — Key settings (criteria, threshold, max iterations)
4. **Results Summary** — Statistics table
5. **Improvement Trajectory** — ASCII bar chart (from Step 3.5) + iteration-by-iteration table
6. **What Worked** — Analysis of successful changes
7. **What Failed** — Analysis of unsuccessful changes
8. **Recommendations** — Actionable suggestions for future optimization
9. **Full Results Log** — Complete results.tsv embedded in the report

### Step 5: Archive Experiment

#### Step 5a: Save Artifacts

1. **Create the experiment archive directory:**
   ```bash
   mkdir -p experiments/<tag>
   ```

2. **Copy artifacts:**
   ```bash
   cp config.yaml experiments/<tag>/config.yaml
   cp results.tsv experiments/<tag>/results.tsv
   cp <TARGET_ARTIFACT> experiments/<tag>/final_artifact.md
   ```

3. **Write the report:**
   ```bash
   # Write the generated report to experiments/<tag>/report.md
   ```

4. **Print summary:**
   ```
   ✓ Report generated: experiments/<tag>/report.md
   ✓ Results archived: experiments/<tag>/results.tsv
   ✓ Config archived:  experiments/<tag>/config.yaml
   ✓ Final artifact:   experiments/<tag>/final_artifact.md
   ```

#### Step 5b: Extract Patterns

Produce a structured pattern file at `experiments/<tag>/patterns.md`. This distills learnings into a format that future optimization loops can consume (see optimize-loop Phase 0 step 4b).

```markdown
# Patterns: <tag>

## Metadata
- artifact_type: <skill | rule | config | workflow | prompt>
- target: <artifact path>
- baseline: <pass_rate>
- final: <pass_rate>
- iterations: <N>

## Effective Strategies
- strategy_type: <add_examples | add_constraints | simplify | restructure | fix_gaps | remove_noise | error_handling>
  outcome: keep
  description: "<1-line from results.tsv>"
  insight: "<why this worked — inferred from the change and the criterion it addressed>"

## Failed Strategies
- strategy_type: <type>
  outcome: discard
  description: "<1-line>"
  insight: "<why this failed — inferred>"

## Anti-Patterns
- pattern: "<description of an approach that consistently failed>"
  frequency: <N times tried>

## Cross-Experiment Insights
- "<any insight that generalizes beyond this specific artifact>"
```

**Extraction rules:**
1. Map each `keep` row's description to a `strategy_type` from the optimize-loop's strategy list (Phase 1).
2. Map each `discard` row similarly.
3. Identify anti-patterns: any strategy type tried 3+ times with only `discard` results.
4. Cross-experiment insights are synthesized from the What Worked and Recommendations sections of the report.

### Step 6: Update Experiment Status

Update `config.yaml` status field:
```yaml
experiment:
  status: "completed"    # or "abandoned" if max_iterations hit without reaching threshold
```

## Output

- `experiments/<tag>/report.md` — Full analysis report
- `experiments/<tag>/results.tsv` — Archived results log
- `experiments/<tag>/config.yaml` — Archived configuration
- `experiments/<tag>/final_artifact.md` — Snapshot of the optimized artifact

## Rules

1. **Never modify results.tsv.** The report reads it but never changes it.
2. **Always include the full results log.** Even if it's long. This is the historical record.
3. **Be specific in analysis.** "What worked" should quote actual descriptions from results.tsv, not generic statements.
4. **Recommendations must be actionable.** "Try a different approach" is too vague. "Add explicit examples of expected JSON output format" is actionable.
5. **Past reports persist forever.** The `experiments/` directory is the institutional memory of the project.

## Future Learning

When starting a new experiment on a target that has been optimized before:

1. Read ALL previous reports: `experiments/*/report.md`
2. Note what approaches worked and failed
3. Start from the current best (the main branch should have the merged result)
4. Don't repeat known-failed approaches unless you have a fundamentally different angle
