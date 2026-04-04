# Skill Anatomy: Building Custom Agents & Automation

A **Skill** is a reusable automation or workflow that can be invoked via a slash command (e.g., `/commit`, `/review-pr`). Skills are user-invocable agents that solve specific, well-defined problems.

---

## The Skill File Structure

Every skill lives in its own directory and contains a `SKILL.md` file as its entry point.

```
~/.claude/skills/[skill-name]/
├── SKILL.md                 ← The skill definition (required)
├── references/              ← Reference materials and documentation
│   ├── examples.md
│   ├── templates.md
│   └── principles.md
└── templates/               ← Reusable templates or boilerplates
    └── [template-files]
```

---

## SKILL.md Frontmatter (Required)

Every SKILL.md must begin with YAML frontmatter defining the skill's metadata:

```yaml
---
name: Skill Display Name
description: One sentence describing what the skill does and when to use it
slash_command: /command-name
trigger_pattern: /command-name|alternative pattern|trigger words
category: category-name
version: 1.0.0
---
```

### Frontmatter Fields

| Field | Required | Format | Example |
|-------|----------|--------|---------|
| `name` | Yes | Title case | `Brand Voice Generator` |
| `description` | Yes | One sentence | `Generates brand voice guidelines from a persona and design philosophy` |
| `slash_command` | Yes | Kebab-case with `/` prefix | `/brand-voice` |
| `trigger_pattern` | Yes | Regex-like patterns separated by `\|` | `/brand-voice\|create brand voice\|generate voice guidelines` |
| `category` | Yes | Lowercase, single word | `content`, `development`, `automation`, `documentation` |
| `version` | Yes | Semantic versioning | `1.0.0` |

---

## SKILL.md Body Structure

After the frontmatter, the SKILL.md file contains the skill's logic and instructions.

### Minimal Skill Template

```markdown
---
name: Skill Name
description: What it does
slash_command: /command
trigger_pattern: /command|alternative trigger
category: category
version: 1.0.0
---

# [Skill Name]

## Overview
[2-3 sentences describing the skill's purpose and when to use it]

## How to Use
[Bullet points or numbered steps for invoking the skill]

## What This Skill Does
[Detailed explanation of the automation or workflow]

### Step 1: [First Step Name]
[Explanation of what happens]

### Step 2: [Second Step Name]
[Explanation of what happens]

## Output
[What the user receives at the end]

## Examples
```

### Full Skill Anatomy

A mature skill includes these additional sections:

```markdown
---
name: Skill Name
description: What it does
slash_command: /command
trigger_pattern: /command|alternative
category: category
version: 1.0.0
---

# [Skill Name]

## Overview
[Purpose and use cases]

## When to Use This Skill
- [Use case 1]
- [Use case 2]
- [Use case 3]

## When NOT to Use This Skill
- [Anti-pattern 1]
- [Anti-pattern 2]

## Prerequisites
[What the user must set up before running the skill]

## How to Use

### Invocation
```
/command-name [required-param] [--optional-flag]
```

### Parameters
| Parameter | Required | Description |
|-----------|----------|-------------|
| param1 | Yes | What this parameter does |
| --flag | No | What this flag does |

## Workflow

### Step 1: [Step Name]
[Detailed explanation]

### Step 2: [Step Name]
[Detailed explanation]

### Step 3: [Step Name]
[Detailed explanation]

## Output Artifacts
| Artifact | Location | Purpose |
|----------|----------|---------|
| [file] | [path] | [what it contains] |

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| [error] | [why it happens] | [how to fix] |

## Related Skills
- `/skill-name` — [brief description]
- `/skill-name` — [brief description]

## Examples

### Example 1: [Scenario]
[Step-by-step walkthrough]

### Example 2: [Scenario]
[Step-by-step walkthrough]
```

---

## Key Principles

### 1. One Clear Purpose
A skill solves one well-defined problem. If you're tempted to add "or also do this other thing," split it into two skills.

**Good:** `/brand-voice` generates voice guidelines from a persona.
**Bad:** `/generate-content` that generates brand voice, marketing copy, and email templates.

### 2. Transparent Workflow
The user should understand what the skill is doing at each step. If a step requires waiting or makes a significant decision, explain it.

**Good:** "Analyzing your brand files... This may take 30 seconds."
**Bad:** "Processing..." (user has no idea what's happening)

### 3. Recoverable Errors
Every error message should tell the user what went wrong and what to do next. Never end with "Error."

**Good:** "Brand file not found at `brands/acme/brand.json`. Check the path and try again."
**Bad:** "File error."

### 4. Idempotent Output
Running the skill twice with the same input should be safe. Ideally, it produces the same output without side effects or duplicates.

**Good:** `/brand-voice` overwrites the previous brand-voice.md.
**Bad:** `/brand-voice` appends to an existing file, creating duplicates.

### 5. Self-Documenting Parameters
Use clear, descriptive names. Avoid abbreviations or jargon the average user won't understand.

**Good:** `--output-format json`
**Bad:** `--fmt j`

---

## Categorization

Choose exactly one category for your skill:

| Category | Purpose | Examples |
|----------|---------|----------|
| `content` | Content generation (copy, marketing, documentation) | `/brand-voice`, `/metadata` |
| `development` | Code-focused tasks (commits, PRs, tests) | `/commit`, `/test` |
| `automation` | Workflow automation (git operations, deploys) | `/deploy`, `/release` |
| `documentation` | Document generation and maintenance | `/sop`, `/readme` |
| `management` | Project and team operations | `/sprint-plan`, `/standup` |

---

## Versioning

Skills use semantic versioning: `MAJOR.MINOR.PATCH`

| Update Type | Increment | When |
|-------------|-----------|------|
| Breaking change (new required parameter, different output shape) | MAJOR | Only when necessary; users must be notified |
| New feature (optional parameter, new flag, extended output) | MINOR | When backward-compatible additions are made |
| Bug fix or documentation improvement | PATCH | For fixes and clarifications that don't change behavior |

Start all skills at `1.0.0`.

---

## File Naming Convention

```
~/.claude/skills/[skill-name]/
```

Use kebab-case (lowercase, hyphens, no spaces). Keep it short — 2–3 words max.

**Good:** `brand-voice-generator`, `skill-creator`, `sop-creator`
**Bad:** `brand_voice_generator`, `BrandVoiceGenerator`, `the-brand-voice-generator`

---

## Testing Your Skill

Before considering a skill complete:

1. **Invoke it:** Test the slash command and at least one alternative trigger pattern.
2. **Verify output:** Confirm the artifacts (files, text, decisions) are produced correctly.
3. **Error handling:** Try an invalid input and confirm the error message is helpful.
4. **Documentation:** Read your SKILL.md as if you've never seen it. Is it clear?

---

## When to Create a New Skill vs. Enhance an Existing One

| Scenario | Decision |
|----------|----------|
| New, independent problem | **New skill** — create a new directory and SKILL.md |
| Variation on an existing skill | **Enhance existing** — add a parameter or flag to the existing skill |
| Entirely separate automation | **New skill** — each skill should have one purpose |
| Related skills that could sequence together | **Leave separate** — allow each skill to be independent; create documentation linking them |

---

## Example: A Complete Skill

See `~/.claude/skills/[skill-name]/SKILL.md` for a full example of a mature, production-ready skill.
