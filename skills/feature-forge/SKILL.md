---
name: feature-forge
description: >
  Use this skill when the user says "/feature-forge", "forge T-01", "try multiple approaches",
  "variant build", "compete implementations", or wants to generate multiple variant implementations
  of a feature and select the best one. Spawns N parallel agents in isolated worktrees, each
  building the same feature with a different strategy, evaluates all variants, and integrates the
  winner. Can wrap /implement automatically (forge mode: auto in SPRINT.md) or run on-demand.
---

# /feature-forge — Multi-Variant Feature Generation

You are the Lead Developer running a variant competition. Instead of building one implementation,
you spawn N parallel agents — each using a different strategy — evaluate their outputs, and
integrate the winner. This is the autoresearch ratchet applied to feature code.

## Step 0: Load Role Contracts

Read the following using the Read tool:
- `~/.claude/rules/lead-developer.md`
- If FE task: `~/.claude/rules/frontend-dev.md`
- If BE task: `~/.claude/rules/backend-dev.md`

## Step 1: Scope Check

Read SPRINT.md. Find the task being forged. Check:

1. **Task exists** — If not found, stop: "T-[N] not found in SPRINT.md."
2. **Task size** — Read the size estimate.
3. **Forge mode** — Check SPRINT.md Tech Selection Record for `Forge Mode:` field.

| Condition | Action |
|-----------|--------|
| User explicitly invoked `/feature-forge T-[N]` | Always forge, regardless of size/mode |
| Size S + Forge Mode auto | Skip: "T-[N] is size S (boilerplate). Routing to /implement." |
| Size M + Forge Mode auto | Forge with 3 variants |
| Size M + algorithm/UI-layout/perf-critical + auto | Forge with 5 variants |
| Size L | Block: "T-[N] is size L. Must split before dispatch." |
| Forge Mode explicit | Only forge when explicitly invoked |
| Forge Mode off | Skip: "Forge mode is off. Routing to /implement." |
| No Forge Mode field | Treat as `explicit` (opt-in) |

If skipping, invoke `/implement T-[N]` and exit this skill.

## Step 2: Read Task Context

Gather the implementation context:
- Task description from SPRINT.md (verb + noun + output)
- SPEC.md Section 1 (BE) or Section 3 (FE) — the relevant requirements
- SPEC.md Section 6 — Definition of Done criteria for the parent Story
- Tech Selection Record from SPRINT.md
- Dependencies (confirm all prerequisite tasks are Done)

Classify the task: FE-only, BE-only, or full-stack.

## Step 3: Generate Strategy Prompts

Select N strategies from the rotation pool. Each strategy adds a constraint to the standard
implementation prompt. Never use the same strategy twice in one forge.

| Strategy | Constraint Added to Prompt |
|----------|---------------------------|
| **Minimal** | "Use the fewest lines of code possible. Simplest approach that meets all requirements." |
| **Idiomatic** | "Follow framework best practices and conventional patterns. Prioritize readability and convention over cleverness." |
| **Performance** | "Optimize for runtime performance and minimal bundle size. Measure and minimize." |
| **Accessible-first** | "WCAG 2.1 AA is the primary constraint. Every interaction must be keyboard-navigable with proper ARIA." |
| **Testable** | "Design for maximum test coverage. Every function should be independently testable. Write tests." |

For 3 variants, use: Minimal, Idiomatic, Performance.
For 5 variants, use all five.

Construct each variant's prompt:

```
You are the [Frontend/Backend] Developer implementing T-[N].

STRATEGY CONSTRAINT: [strategy constraint text]

TASK: [task description from SPRINT.md]

REQUIREMENTS:
[Relevant SPEC.md section text]

TECH STACK:
[Tech Selection Record]

DEFINITION OF DONE:
[SPEC.md Section 6 criteria for parent Story]

Instructions:
1. Read the requirements carefully before writing any code
2. Implement the task following the strategy constraint above
3. Run lint: [lint command from tech stack] — must exit 0
4. List all files created or modified
5. Report lint result
```

## Step 4: Spawn Variant Agents

For each variant, spawn an Agent with `isolation: "worktree"`:

```
Agent tool:
  subagent_type: "general-purpose"
  model: "opus"
  isolation: "worktree"
  prompt: <variant prompt from Step 3>
```

**Launch all N agents in a single message** for parallel execution.

Wait for all agents to return. Each returns:
- Modified files in its worktree
- Lint result
- Build output (if applicable)

## Step 5: Evaluate Variants

For each variant's worktree, run the evaluation criteria. Use Bash tool to execute checks
in the worktree directory.

### Evaluation Matrix

| Criterion | Weight | Method | Score |
|-----------|--------|--------|-------|
| **Tests pass** | 0.30 | Run test suite: `npx jest --ci` / `pytest` / stack toolchain | 1.0 if exit 0, 0.0 if fail, 0.5 if no tests exist |
| **SPEC.md trace** | 0.20 | For each Section 6 BDD criterion, check if the variant addresses it | fraction addressed |
| **Lint clean** | 0.15 | `npm run lint` / `ruff check .` | 1.0 if exit 0, 0.0 if errors |
| **Type safety** | 0.10 | `npx tsc --noEmit` (TS) or skip | 1.0 if exit 0 or N/A, 0.0 if errors |
| **Bundle size** | 0.10 | `du -sh dist/` or `du -sh .next/` — compare across variants | normalized: best=1.0, worst=0.0 |
| **Accessibility** | 0.10 | `npx axe-core` / `npx pa11y` or grep for aria-label usage | 1.0 if tool passes or aria present, 0.0 otherwise |
| **Lines of code** | 0.05 | `wc -l` on new/modified source files | normalized: fewest=1.0, most=0.0 |

For each criterion, record the raw score. Compute weighted total.

**If test tooling is not set up** (no jest config, no pytest, etc.): weight redistributes to
SPEC.md trace (0.30 → 0.40) and lint (0.15 → 0.25).

### Score Each Variant

Print the evaluation table:

```
========================================
FEATURE FORGE — T-[N]
========================================
task:           T-[N] — [description]
variants:       [N]
----------------------------------------
| Variant | Strategy     | Tests | Trace | Lint | Types | Size | A11y | LOC | Total |
|---------|-------------|-------|-------|------|-------|------|------|-----|-------|
| 1       | minimal     | 1.00  | 1.00  | 1.00 | 1.00  | 1.00 | 0.50 | 1.00| 0.95  |
| 2       | idiomatic   | 1.00  | 1.00  | 1.00 | 1.00  | 0.60 | 1.00 | 0.70| 0.90  |
| 3       | performance | 0.50  | 0.67  | 1.00 | 1.00  | 1.00 | 0.00 | 0.80| 0.68  |
========================================
```

## Step 6: Select Winner

1. **Highest weighted score wins.**
2. **Tie-breaker: fewer lines of code** (simplicity criterion from autoresearch).
3. **All variants < 0.7:** Select the best, but flag as `DONE_WITH_CONCERNS`:
   > "All forge variants scored below 0.7. Best: Variant [X] ([strategy]) at [score].
   >  Proceeding with DONE_WITH_CONCERNS status."

Announce the winner:
```
WINNER: Variant [X] ([strategy]) — Score: [X.XX]
Runner-up: Variant [Y] ([strategy]) — Score: [X.XX]
```

## Step 7: Integrate Winner

1. **Extract the winning variant's changes** from its worktree into the main working branch.
   The Agent tool with `isolation: "worktree"` returns the worktree path and branch.
   Cherry-pick or merge the changes:
   ```bash
   git merge <worktree-branch> --no-ff -m "forge: T-[N] — [strategy] variant (score: [X.XX])"
   ```
   Or if the worktree is on a detached branch, copy files directly.

2. **Verify integration:** Run lint and tests on the integrated result to ensure no merge conflicts
   broke anything.

3. **Non-winning worktrees** are automatically cleaned up by the Agent tool.

## Step 8: Archive Results

Write `.forge/T-[N].md` in the project root:

```markdown
# Feature Forge — T-[N] — [date]

Task: [description]
Variants: [N]
Winner: Variant [X] ([strategy]) — Score: [X.XX]

## Variant Comparison

| Variant | Strategy | Tests | Trace | Lint | Types | Size | A11y | LOC | Total |
|---------|----------|-------|-------|------|-------|------|------|-----|-------|
| 1       | [name]   | ...   | ...   | ...  | ...   | ...  | ...  | ... | ...   |
| ...     | ...      | ...   | ...   | ...  | ...   | ...  | ...  | ... | ...   |

## Why [Strategy] Won
[1-2 sentence explanation based on score differentials]

## Notable Observations
- [Any interesting patterns: e.g., "performance variant had smallest bundle but failed 1 test"]
```

Create the `.forge/` directory if it doesn't exist.

## Step 9: Handoff

The forge output is equivalent to what `/implement` Step 5 produces. Write the Handoff Note
to SPRINT.md following the standard format:

```
#### Handoff Note — T-[N] — [date]
Specialist(s): Feature Forge ([strategy] variant, score [X.XX])
Task Status: DONE | DONE_WITH_CONCERNS
Modified Files:
  - [path] — [created / modified]
Lint Result: PASS (0 errors, [N] warnings)
BDD Criteria Covered:
  - [criteria from SPEC.md Section 6]
Forge Metadata:
  - Variants tested: [N]
  - Strategies: [list]
  - Winner: [strategy] (score [X.XX])
  - Archive: .forge/T-[N].md
Notes for QA: [edge cases, env requirements]
```

Notify: "T-[N] Handoff Note written (via Feature Forge). Ready for QA verification."

## Rules

1. **One forge per task.** Don't re-forge a completed forge. If QA rejects, fix in `/implement`.
2. **All variants get identical requirements.** Only the strategy constraint differs.
3. **Never batch strategies.** Each agent gets exactly one strategy prompt.
4. **Parallel execution.** All variant agents launch in one message. No sequential dispatch.
5. **Simplicity wins ties.** Fewer lines of code = better, all else being equal.
6. **Archive everything.** The `.forge/` log is institutional memory for `/reflect`.
7. **Forge mode respects project config.** Check SPRINT.md before auto-forging.
8. **Skip gracefully.** If forge is not applicable, route to `/implement` without friction.
