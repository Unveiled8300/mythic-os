---
name: arena
description: >
  Use this skill when the user says "/arena", "head to head", "matchup", "compare systems",
  "A/B test", "benchmark", "which is better", or wants to run a structured comparison between
  two or more approaches, systems, prompts, models, or configurations. Arena is agnostic —
  the user defines what's being compared, what task they perform, and how to score the results.
  Examples: compare Claude Code configs, compare prompt strategies, compare frameworks,
  compare model outputs. This is the entry point (define-matchup); sub-skills handle execution
  and scoring.
---

# /arena — Agnostic Head-to-Head Comparison

You are setting up an Arena matchup. Arena is a general-purpose comparison framework with
three user-defined primitives: **contestants** (what's being compared), **tasks** (what they do),
and **scoring** (how to judge). You handle setup and configuration; `run-matchup` handles
execution; `scorecard` handles scoring and reporting.

## Step 0: Understand the Comparison

Ask the user what they want to compare. Arena supports any comparison that can be structured as:
"N contestants perform the same task(s), then we score the results."

Examples:
- **Systems:** mythic-cc vs jetpack-cc vs vanilla Claude building apps
- **Prompts:** Prompt A vs Prompt B on the same task
- **Models:** Opus vs Sonnet on a workload
- **Approaches:** Three architectural options for a feature
- **Frameworks:** Next.js vs Remix vs SvelteKit for a project type

If the user wants to compare Claude Code systems building apps, offer the pre-built archetypes
from `references/prd-archetypes.md`.

## Step 1: Define Contestants

Gather the contestant list. Each contestant needs:

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Human-readable label (e.g., "mythic-cc", "prompt-v2", "opus") |
| `setup` | No | Shell command to prepare the contestant's workspace (e.g., copy config files) |
| `run` | Yes | Shell command or invocation pattern to execute the contestant on a task |

The `run` command has access to these environment variables at execution time:
- `$WORKSPACE` — the contestant's isolated workspace directory
- `$TASK_PROMPT` — the task prompt text
- `$TASK_NAME` — the task identifier
- `$OUTPUT_DIR` — where the contestant should write output

**For Claude Code system comparisons**, the typical `run` pattern is:
```bash
claude --print \
  --system-prompt "$(cat $WORKSPACE/.claude/CLAUDE.md)" \
  --permission-mode bypassPermissions \
  --output-format text \
  "$TASK_PROMPT"
```

**For prompt comparisons:**
```bash
claude --print \
  --system-prompt "$(cat $WORKSPACE/prompt.md)" \
  --permission-mode bypassPermissions \
  "$TASK_PROMPT"
```

**For model comparisons:**
```bash
claude --print \
  --model claude-sonnet-4-6 \
  --permission-mode bypassPermissions \
  "$TASK_PROMPT"
```

Minimum 2 contestants, maximum 6 (beyond 6, execution time and cost become impractical).

## Step 2: Define Tasks

Gather the task(s) each contestant will perform. Each task needs:

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Short identifier (e.g., "build-todo-app", "debug-auth-bug") |
| `prompt` | Yes | The task prompt — identical for all contestants |
| `context_files` | No | Shared read-only files copied into every workspace (e.g., PRD.md) |
| `repetitions` | No | Times to run each contestant on this task (default: 1, max: 10) |
| `timeout_seconds` | No | Per-execution timeout (default: 300) |

Multiple tasks are supported — each contestant runs all tasks. This allows cross-task comparison
(e.g., "System A is better at B2C but worse at B2B").

If the user wants pre-built tasks, read `references/prd-archetypes.md` and present the options.

## Step 3: Define Scoring Criteria

Gather the scoring rubric. Each criterion needs:

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | What's being measured (e.g., "builds-successfully", "code-quality") |
| `type` | Yes | One of: `binary`, `numeric`, `rubric` |
| `evaluator` | Yes | How to measure it (command, grep pattern, or LLM judge prompt) |
| `weight` | No | Relative importance, 0.0-1.0 (default: equal weight) |

**Criterion types:**

### Binary (pass/fail)
Evaluator is a shell command. Exit 0 = pass, non-zero = fail.
```yaml
- name: "builds-successfully"
  type: binary
  evaluator: "cd $OUTPUT_DIR && npm run build"
```

### Numeric (measured value)
Evaluator produces a number on stdout. Lower or higher can be "better" (specify `direction`).
```yaml
- name: "lines-of-code"
  type: numeric
  evaluator: "find $OUTPUT_DIR/src -name '*.ts' | xargs wc -l | tail -1 | awk '{print $1}'"
  direction: lower   # lower is better
```

### Rubric (LLM-judged)
Evaluator is a prompt fed to `claude --print` with strict instructions. Output must be a single
number on a defined scale. Run 3 times, take median for stability.
```yaml
- name: "code-quality"
  type: rubric
  evaluator: "Rate this code 1-5 on readability, naming, and structure. Answer ONLY the number."
  scale: 5
```

Weights must sum to 1.0. If not specified, distribute equally.

## Step 4: Validate Configuration

Before writing config, validate:

1. **Contestants:** At least 2 defined. Each has a `run` command.
2. **Tasks:** At least 1 defined. Each has a `prompt`.
3. **Scoring:** At least 1 criterion defined. Weights sum to 1.0 (or will be equalized).
4. **Practical check:** Estimate total runs = contestants × tasks × repetitions. Warn if > 50:
   > "This matchup will require [N] total executions. Estimated time: [N × timeout]s. Proceed?"

## Step 5: Write Configuration

Write `config.yaml` to the current directory (or user-specified location):

```yaml
# Arena matchup configuration
# Generated: <ISO_TIMESTAMP>

arena:
  tag: "<user-provided or auto-generated tag>"
  created: "<ISO_TIMESTAMP>"
  status: "active"

contestants:
  - name: "<name>"
    setup: |
      <setup commands>
    run: |
      <run command>
  # ... more contestants

tasks:
  - name: "<name>"
    prompt: "<prompt text>"
    context_files: []
    repetitions: <N>
    timeout_seconds: <N>
  # ... more tasks

scoring:
  criteria:
    - name: "<name>"
      type: "<binary|numeric|rubric>"
      evaluator: "<evaluator>"
      weight: <0.0-1.0>
    # ... more criteria

output:
  workspace_root: "arena-workspaces/<tag>"
  scoreboard: "scoreboard.tsv"
```

## Step 6: Initialize Workspace

1. Create the workspace root directory:
   ```bash
   mkdir -p arena-workspaces/<tag>
   ```

2. Create shared directory for context files:
   ```bash
   mkdir -p arena-workspaces/<tag>/shared
   ```
   Copy any `context_files` into `shared/`.

3. Initialize `scoreboard.tsv`:
   ```bash
   printf 'contestant\ttask\trepetition\t<criterion_1>\t<criterion_2>\t...\tweighted_score\n' > scoreboard.tsv
   ```

4. Print summary:
   ```
   Arena configured: <tag>
   Contestants: <N> (<names>)
   Tasks: <N> (<names>)
   Scoring: <N> criteria (<names>)
   Total executions: <N>
   Workspace: arena-workspaces/<tag>/
   
   Ready. Invoke the run-matchup skill to begin execution.
   ```

## Rules

1. **Arena is agnostic.** Never hardcode domain assumptions about what contestants are.
2. **All contestants get identical tasks.** The task prompt is the controlled variable.
3. **Validate before writing config.** Never proceed with an invalid or incomplete configuration.
4. **Warn on expensive matchups.** If total executions > 50, require explicit confirmation.
5. **Tag must be unique.** No two matchups share the same tag.
6. **Config is the single source of truth.** run-matchup and scorecard read from it.
