---
name: arena-scorecard
description: >
  Scores and ranks arena contestants after run-matchup has completed execution. Evaluates
  each contestant's output against the scoring criteria, computes weighted aggregates,
  renders a comparative report with rankings, bar charts, and insights.
---

# Arena: Scorecard

You are scoring the arena matchup. Read `config.yaml` and contestant outputs, evaluate each
output against the defined scoring criteria, compute rankings, and render the comparative report.

## Prerequisites

- `config.yaml` exists
- `run-matchup` has completed (contestant workspace dirs contain output + `meta.json`)
- `scoreboard.tsv` exists with header

## Step 1: Load Configuration

Read `config.yaml`. Extract:
- Contestant list
- Task list
- Scoring criteria (name, type, evaluator, weight)
- Workspace root path

## Step 2: Score Each Output

For each contestant, for each task, for each repetition:

### 2a: Navigate to Output

```bash
cd "arena-workspaces/<tag>/contestants/<contestant>/<task>/rep-<N>"
```

Set environment variables:
```bash
export OUTPUT_DIR="$(pwd)"
export CONTESTANT="<name>"
export TASK_NAME="<task>"
```

### 2b: Evaluate Each Criterion

**For `binary` criteria:**
```bash
eval "<evaluator>"
# Exit 0 → score = 1.0
# Non-zero → score = 0.0
```

**For `numeric` criteria:**
```bash
RAW_VALUE=$(eval "<evaluator>" | tail -1)
# Store raw value. Normalization happens in Step 3.
```

**For `rubric` criteria:**
Run the evaluator prompt 3 times via `claude --print` with strict output:
```bash
for i in 1 2 3; do
    # Feed the contestant's output as context, evaluator as instruction
    SCORE=$(claude --print \
        --tools "" \
        --permission-mode bypassPermissions \
        --output-format text \
        "Here is the code/output to evaluate:

$(cat $OUTPUT_DIR/build.log | tail -200)

Files created:
$(find $OUTPUT_DIR -type f -not -path '*/.git/*' -not -name 'meta.json' -not -name 'build.log' | head -50)

$EVALUATOR_PROMPT" | grep -oE '[0-9]+(\.[0-9]+)?' | head -1)
    echo "$SCORE"
done
# Take the median of 3 scores
```

Normalize rubric scores to 0.0-1.0: `normalized = raw_score / scale`

### 2c: Record Raw Scores

Append to `scoreboard.tsv`:
```
<contestant>\t<task>\t<rep>\t<criterion_1_score>\t<criterion_2_score>\t...\t<weighted>
```

## Step 3: Normalize and Aggregate

### Normalize Numeric Criteria

For numeric criteria, normalize across all contestants for the same task:
- If `direction: lower` → `normalized = 1.0 - (value - min) / (max - min)` (best = lowest)
- If `direction: higher` → `normalized = (value - min) / (max - min)` (best = highest)
- If all values equal → `normalized = 1.0` for all

### Aggregate Per Contestant

For each contestant, for each task:
1. Average across repetitions per criterion
2. Compute weighted score: `sum(criterion_score × weight)`

For overall ranking:
1. Average weighted scores across all tasks

## Step 4: Render Report

Generate the comparison report:

```markdown
# Arena Report: <tag>

> Generated: <ISO_TIMESTAMP>
> Contestants: <N> | Tasks: <N> | Criteria: <N> | Total runs: <N>

## Overall Rankings

| Rank | Contestant | Score | <task_1> | <task_2> | ... |
|------|-----------|-------|----------|----------|-----|
| 1    | <name>    | <X.XX>| <X.XX>   | <X.XX>   | ... |
| 2    | <name>    | <X.XX>| <X.XX>   | <X.XX>   | ... |
| ...  | ...       | ...   | ...      | ...      | ... |

## Per-Criterion Breakdown

<criterion_1> (weight: <W>):
  <contestant_1> : <bar_chart> <score>
  <contestant_2> : <bar_chart> <score>
  ...

<criterion_2> (weight: <W>):
  ...
```

### Bar Chart Rendering

Use 20-character ASCII bars (matching `history-report` convention):
```
score 0.85: █████████████████░░░ 0.85
score 0.50: ██████████░░░░░░░░░░ 0.50
score 0.00: ░░░░░░░░░░░░░░░░░░░░ 0.00
```

Formula: `filled = round(score × 20)`, `empty = 20 - filled`

### Insights Section

Analyze the scores and generate insights:

1. **Winner analysis:** What did the top contestant do well? Where did it score highest?
2. **Gap analysis:** Where is the biggest gap between #1 and #2? What explains it?
3. **Task-specific patterns:** Did any contestant win some tasks but lose others?
4. **Criterion sensitivity:** Which criteria drove the ranking most? (highest weight × variance)
5. **Consistency:** Which contestant had the smallest variance across repetitions?

### Per-Execution Detail (collapsed section)

```markdown
## Execution Detail

### <contestant_1> — <task_1>
| Rep | Exit | Time | <criterion_1> | <criterion_2> | ... | Weighted |
|-----|------|------|---------------|---------------|-----|----------|
| 1   | 0    | 45s  | PASS          | 4/5           | ... | 0.82     |
| 2   | 0    | 52s  | PASS          | 3/5           | ... | 0.75     |
| Avg |      | 48s  | 1.00          | 0.70          | ... | 0.79     |
```

### Raw Scoreboard

```markdown
## Raw Scoreboard

\`\`\`tsv
<full scoreboard.tsv contents>
\`\`\`
```

## Step 5: Write Report

Write the report to `arena-workspaces/<tag>/REPORT.md`.

Print summary to console:
```
Arena scored: <tag>
Winner: <name> (score: <X.XX>)
Runner-up: <name> (score: <X.XX>)
Report: arena-workspaces/<tag>/REPORT.md
Scoreboard: scoreboard.tsv
```

## Rules

1. **Score every execution.** Even failed/timed-out runs get scored (they score 0 on most criteria).
2. **Rubric evaluations use 3x median.** Single LLM judgments are too noisy.
3. **Normalize numeric scores across contestants.** Raw values aren't comparable across criteria.
4. **Structured output.** The report must follow the format above for consistency with other skills.
5. **Never modify contestant outputs.** Scoring is read-only observation.
6. **Insights must be evidence-based.** Every insight references specific score differentials.
