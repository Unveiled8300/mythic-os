# Skill Design Principles: Building Effective Automation

Core principles that distinguish a skill that people use regularly from one that collects dust.

---

## Principle 1: One Clear Purpose

**Rule:** A skill solves one well-defined problem. Nothing more.

A skill should be invocable by someone who knows **what they want to accomplish**, not by someone trying to guess what the skill does.

### ✓ Good

- `/commit` — Stage changes, write a commit message, push
- `/qa-verify` — Test a task against acceptance criteria
- `/brand-voice` — Generate tone-of-voice guidelines from a persona

### ✗ Bad

- `/do-stuff` — Can commit, push, deploy, or test depending on what files are present
- `/automation` — Does various project management tasks (too broad)
- `/gen` — Generates content (could be copy, code, designs, SOPs — unclear)

### Why This Matters

A skill with multiple purposes becomes a guessing game. The user wonders:
- "Will this skill do what I want?"
- "Do I need to use this skill, or a different one?"
- "What if this skill also does something I didn't ask for?"

**Precision is trust.** When a skill does exactly one thing reliably, users invoke it without hesitation.

---

## Principle 2: Transparent Workflow

**Rule:** The user should understand what the skill is doing at each step.

If a step takes time, requires waiting, or makes a significant decision, explain it. Never hide complexity behind vague status messages.

### ✓ Good

```
Step 1: Reading git status (this may take 5 seconds on large repos)
Found 12 modified files.

Step 2: Analyzing changes...
[Shows which files will be staged, which will be asked about, which will be skipped]

Step 3: Generating commit message from diff...
[Shows proposed message]

Step 4: Pushing to branch...
[Shows git push output]
```

### ✗ Bad

```
Processing...
✓ Done
```

### Why This Matters

When a skill runs opaquely, the user **cannot debug failures**. If something goes wrong, they don't know what the skill tried to do. With transparency:
- The user sees exactly what happened
- They understand where a failure occurred
- They can report the issue precisely
- They can manually complete the step if the skill blocked

---

## Principle 3: Recoverable Errors

**Rule:** Every error message tells the user what went wrong AND what to do next.

An error message is **not a failure to explain.** It's an opportunity to help the user recover.

### ✓ Good

```
Error: Config file not found at ~/.myapp/config.json.

To fix this:
  1. Create the directory: mkdir -p ~/.myapp
  2. Copy the example: cp config.example.json ~/.myapp/config.json
  3. Edit the file: nano ~/.myapp/config.json
  4. Try again: /skill-name
```

### ✗ Bad

```
Error: ENOENT: no such file or directory, open '~/.myapp/config.json'
```

### Why This Matters

Users should never feel stuck. A good error message **reduces support load** by enabling users to self-serve recovery. It also demonstrates that the skill is thoughtfully designed, not just a shortcut.

---

## Principle 4: Idempotency and Safety

**Rule:** Running a skill twice with the same input should be safe. Ideally, it produces the same result without side effects.

Idempotency means the user doesn't have to worry about accidentally breaking something by re-running a skill.

### ✓ Good

- `/commit` — re-running it on the same files commits the same change (no duplicates)
- `/qa-verify` — running it twice on the same task produces the same PASS/FAIL result
- `/deploy` — deploying the same version twice results in no changes (idempotent)

### ✗ Bad

- `/add-feature` — running it twice adds the feature twice (oops)
- `/send-email` — running it twice sends two emails (careful!)
- `/archive` — running it twice archives the archive (nested confusion)

### How to Achieve Idempotency

1. **Upsert operations:** Update if exists, insert if not
2. **Idempotency keys:** Store a key (hash of inputs) and return the same result if already processed
3. **State checks:** Verify the desired state is already true before acting
4. **Document the limit:** If non-idempotent, document clearly: "Running this twice will cause X. Don't run twice."

### Why This Matters

Users should feel safe invoking a skill, even if they're unsure if they've already run it. Idempotency = confidence.

---

## Principle 5: Self-Documenting Parameters

**Rule:** Parameter names explain their purpose. No abbreviations or jargon that require a glossary.

When a user invokes a skill with parameters, the parameter names themselves should communicate intent.

### ✓ Good

```
/deploy --env production --skip-smoke-tests
/bulk-update --dry-run --max-results 50
/export --format csv --include-metadata
```

### ✗ Bad

```
/deploy -p -st
/bulk-update -d -m 50
/export -f c -m
```

### Why This Matters

Parameter names are part of the UX. When names are clear, users don't need to read the docs to understand what a parameter does. Users should be able to guess the command structure by inspection.

---

## Principle 6: Appropriate Scope

**Rule:** A skill handles its concern completely. It doesn't hand off to manual work unless necessary.

A skill should eliminate the need for the user to switch contexts. Once invoked, it should produce the complete output without requiring additional steps.

### ✓ Good

- `/commit` handles: staging, message generation, push
- `/qa-verify` handles: reading criteria, running tests, documenting evidence, issuing pass/reject
- `/deploy` handles: env setup, CI/CD, staging, production, monitoring

### ✗ Bad

- `/commit` stages files but leaves the message blank (user must write it)
- `/qa-verify` reads criteria but tells the user "now go test it manually" (incomplete)
- `/deploy` sets up CI/CD but requires the user to run the deploy command manually

### When to Accept Partial Scope

Some steps require human judgment and should not be automated:
- Deciding if a change is safe (Security Officer review)
- Verifying test results (QA evaluation)
- Approving a design (Product decision)

Document these as **gates**, not cop-outs:

```
⚠️ Human Gate: Security Officer Review
Before proceeding to production, a Security Officer must review the code changes.
Waiting for security clearance...
```

### Why This Matters

Context-switching kills productivity. A complete skill handles everything up to the human gates, then waits for human input before proceeding.

---

## Principle 7: Versioning and Stability

**Rule:** Skill behavior is stable. Changes to behavior bump the major version and are communicated clearly.

Users should trust that a skill works the same way every time they use it. Breaking changes are not surprises.

### Versioning Guide

| Change | Version Bump | Example |
|--------|--------------|---------|
| Bug fix, performance improvement | PATCH | 1.0.0 → 1.0.1 |
| New parameter, extended output | MINOR | 1.0.0 → 1.1.0 |
| Parameter removed, output format changed, behavior significantly different | MAJOR | 1.0.0 → 2.0.0 |

### Deprecation Path for Breaking Changes

If you need to make a breaking change:

```yaml
version: 2.0.0
deprecated_parameters:
  - old_param: replaced_by new_param (MAJOR version change)
    removal_date: 2026-06-01
```

Document migration:
```
⚠️ Breaking Change in v2.0.0

Old: /skill-name --old-param value
New: /skill-name --new-param value

The old-param will be removed 2026-06-01. Please update your invocations.
```

### Why This Matters

Users and other systems may depend on a skill's behavior. Breaking it without notice erodes trust. Semantic versioning signals reliability.

---

## Principle 8: Testing and Validation

**Rule:** Every skill is tested before release. Minimal tests: happy path, one error case, one edge case.

A skill without tests is a liability. Testing doesn't require perfection — it requires coverage of the most likely scenarios.

### Minimal Test Suite

For every skill, test:

1. **Happy path:** Standard invocation with typical inputs
   - Example: `/commit` with 3 modified files that should all be staged

2. **Error case:** One realistic error scenario
   - Example: `/commit` with a detached HEAD or merge conflict

3. **Edge case:** One boundary condition
   - Example: `/commit` with a very large diff (> 1000 lines)

### How to Document Tests

```yaml
tests:
  - name: Happy Path — Commit three files
    input: "3 modified files in standard repo"
    expected_output: "Commit created, pushed to branch"

  - name: Error Case — Detached HEAD
    input: "Invoke /commit in detached HEAD state"
    expected_output: "Error message: Cannot commit in detached HEAD. Check git status."

  - name: Edge Case — Large diff (1000+ lines)
    input: "1500 lines changed across 10 files"
    expected_output: "Commit succeeds, message acknowledges large scope"
```

### Why This Matters

Testing catches the "oops, I didn't think about that scenario" moments before users hit them. It also gives you confidence to improve the skill without fear of breaking things.

---

## Principle 9: Category Precision

**Rule:** Every skill belongs to exactly one category. Categories are narrow enough to be useful, broad enough to be scannable.

A skill's category helps users find it and understand its domain without reading the full description.

### Valid Categories

| Category | Scope | Examples |
|----------|-------|----------|
| `content` | Content generation (copy, documentation, specs) | `/brand-voice`, `/metadata`, `/sop-creator` |
| `development` | Code-focused tasks (commits, tests, reviews) | `/commit`, `/qa-verify`, `/lint` |
| `automation` | Workflow automation (git, deploys, CI/CD) | `/deploy`, `/release`, `/sync-branches` |
| `documentation` | Document creation and updates | `/sop-creator`, `/changelog`, `/readme` |
| `management` | Project and team operations | `/sprint-plan`, `/standup`, `/retro` |

### Anti-Pattern

**Multi-category skills:** A skill that could fit in two categories means its purpose is too broad. Reconsider the scope.

```
❌ Bad: /dev-ops (automation + development + management — too broad)
✓ Good: /deploy (automation) + /qa-verify (development)
```

### Why This Matters

Narrow categories help users navigate the skill ecosystem. They also force you to clarify the skill's purpose.

---

## Principle 10: Documentation as Specification

**Rule:** The SKILL.md file IS the specification. If it's not in the docs, it's not part of the skill.

Documentation is not an afterthought. It defines the contract between the skill and its users.

### Non-Negotiable Sections

Every SKILL.md must include:

1. **Overview** — One sentence: what it does
2. **When to Use** — Scenarios where this skill is the right choice
3. **When NOT to Use** — Anti-patterns and out-of-scope tasks
4. **Parameters** — Exact names, required/optional, format
5. **Workflow** — Step-by-step execution
6. **Output** — What the user receives
7. **Troubleshooting** — Issue → Cause → Fix
8. **Examples** — 2+ real scenarios traced start-to-finish

### Why This Matters

A skill without clear documentation is a burden on users. It forces them to read the code or guess. Documentation is the gift you give to future you and other users of this system.

---

## Principle 11: Naming Conventions

**Rule:** Skill names follow kebab-case and are 2–3 words max. Slash commands are lowercase and memorable.

Naming consistency makes a system feel intentional.

### ✓ Good

```
/commit        ← short, memorable
/qa-verify     ← kebab-case, clear purpose
/brand-voice   ← alliterative, easy to remember
```

### ✗ Bad

```
/do_commit              ← underscore (not kebab-case)
/c                      ← too abbreviated
/commit-and-push-code   ← too wordy
/CommitAndPush          ← camelCase (not kebab-case)
```

### Why This Matters

Naming consistency makes the skill ecosystem feel cohesive. Users learn the naming pattern and can intuit new skill names without looking them up.

---

## Principle 12: Graceful Degradation

**Rule:** If a skill cannot complete its primary task, it should degrade gracefully rather than fail hard.

Graceful degradation means offering a useful partial result or a clear fallback.

### ✓ Good

```
/deploy: Staging QA returned REJECT. Rollback options:
  1. Re-deploy previous version to staging
  2. Return to development (do not deploy to production)
  3. Review failure details and try again
```

### ✗ Bad

```
/deploy: Error. Stopping.
[No guidance, user is stuck]
```

### Why This Matters

Skills are tools. Tools should help the user move forward, even when something goes wrong. Graceful degradation maintains productivity during uncertainty.

---

## Quick Checklist: Is Your Skill Ready?

Before releasing a skill, verify:

- [ ] **One clear purpose** — Can you describe it in one sentence?
- [ ] **Transparent workflow** — Would a first-time user understand what's happening at each step?
- [ ] **Recoverable errors** — Does every error message include the next step?
- [ ] **Idempotent** — Is it safe to run twice?
- [ ] **Self-documenting parameters** — Can a user guess what parameters do?
- [ ] **Appropriate scope** — Does it handle everything up to human gates?
- [ ] **Semantic versioning** — Does it follow MAJOR.MINOR.PATCH?
- [ ] **Tested** — Does it work for happy path, error case, and one edge case?
- [ ] **Correct category** — Does it fit exactly one category?
- [ ] **Documented** — Does SKILL.md cover all required sections?
- [ ] **Named well** — Is it kebab-case and 2–3 words?
- [ ] **Graceful degradation** — Does it handle errors without leaving the user stuck?

If any item is unclear or missing, iterate before release.

---

## From First Skill to Tenth Skill

Your first skill will be rough. That's okay. By your third skill, patterns will emerge. By your tenth, you'll have internalized these principles and won't need this checklist.

The goal: **Build skills people reach for instinctively because they work reliably and get out of the way.**
