# Mythic OS

A governance framework for [Claude Code](https://claude.ai/download) that turns it into a structured software development team — with roles, enforcement hooks, and self-improving skills.

## Install

```bash
git clone https://github.com/Unveiled8300/mythic-os.git
cd mythic-os

# Preview what will be installed (no changes made)
bash mythic-install.sh

# Install into ~/.claude
bash mythic-install.sh --apply
```

The installer copies Mythic OS into `~/.claude`, merging with any existing files. Safe to re-run.

## Quick Start

```
1. Open Claude Code
2. Type /boot
3. Type /cto "build a task tracker with auth"
```

Claude will run discovery, write a SPEC, plan a sprint, implement with specialist agents, run security scrubs, and QA every task against acceptance criteria.

## When to Use It

Mythic OS adds structure and enforcement. That overhead pays for itself on some projects and gets in the way on others.

**Strong fit:**
- SaaS products (B2B, multitenant, dashboards) — the full sprint cycle with QA gates and security scrubs catches the bugs that matter
- Full-stack web apps with auth, database schemas, and API contracts — TDD enforcement and spec-first development prevent the "it works on my machine" class of failures
- Projects where you want Claude to build the whole thing end-to-end — discovery through deployment, with structured handoffs between planning, implementation, and QA

**Weaker fit:**
- Small scripts, one-file utilities, or quick fixes — the ceremony outweighs the benefit. Just use Claude Code directly.
- Light B2C apps or landing pages with minimal logic — you don't need 13 roles and a sprint plan for a marketing site
- Tweaking a few lines in an existing codebase — Mythic OS is designed for building, not patching

## Why

Claude Code is powerful but unpredictable. It skips tests, forgets conventions, writes code before understanding requirements, and has no memory of what worked last time. Mythic OS fixes this by giving Claude a team structure with mechanical enforcement — not just instructions it can ignore, but hooks and gates that actually block bad behavior.

## What It Does

**Roles** — 13 specialist contracts (Lead Developer, QA Tester, Security Officer, etc.) each with explicit SOPs, ownership boundaries, and verification checklists.

**Skills** — 30+ slash commands that orchestrate multi-role workflows:

| Command | What happens |
|---------|-------------|
| `/boot` | Load active project + sprint state |
| `/cto [idea]` | Full project lifecycle from idea to shipped code |
| `/team-fullstack` | Coordinated sprint: planning, implementation, QA, done |
| `/team-mvp` | Fast build — reduced ceremony, same quality gates |
| `/implement [T-ID]` | Dispatch a task to the right specialist |
| `/qa-verify [T-ID]` | Evidence-based verification against acceptance criteria |
| `/deploy` | Staging verification, then production |
| `/sweep` | Full-project security + fragility scan with auto-patching |
| `/arena` | Head-to-head comparison of systems, prompts, or models |
| `/feature-forge [T-ID]` | Spawn N parallel implementations, evaluate, pick winner |
| `/self-iterate` | Autonomous optimization loop for any artifact |

**Enforcement** — Not suggestions. Actual gates:

| Gate | How it's enforced |
|------|------------------|
| No hardcoded secrets | `secret-scan.py` PreToolUse hook blocks every Edit/Write |
| No destructive commands | `catastrophic-gate.py` blocks `rm -rf /`, `git push --force main`, etc. |
| No code without README | `readme-gate.py` blocks writes in projects missing README.md |
| Lint must pass | PostToolUse hook checks exit code after every file edit |
| TDD red/green for logic tasks | `tdd-gate.sh` — skills run verify-red/verify-green via Bash |

**Self-improvement** — The `self-iterate` skill lets Mythic OS optimize its own skills:

```
/self-iterate
  -> Pick a target artifact (any skill, rule, or config file)
  -> Define binary pass/fail eval criteria
  -> Run autonomous loop: modify -> eval -> keep or revert
  -> Cross-experiment pattern learning carries insights forward
```

Supports artifact groups (multi-file optimization), agent-based evaluation (test skills via real execution, not just grep), and cross-model evaluation (ensure artifacts work on Opus and Sonnet).

## Project Structure

```
rules/          Role contracts (13 specialists with SOPs)
skills/         Slash commands (orchestrated workflows)
hooks/          Enforcement hooks (PreToolUse/PostToolUse gates)
stacks/         Stack templates (Next.js+Supabase, Astro, FastAPI)
agents/         Reusable agent definitions
commands/       Additional Claude commands
templates/      PRD and project templates
CLAUDE.md       Global constitution — loaded every session
LIBRARY.md      Resource registry
settings.json   Hook configuration
```

## How Enforcement Works

Mythic OS has three enforcement tiers:

1. **Harness-level** (hooks in `settings.json`) — Run automatically on every tool call. The agent cannot skip them. Secret scanning, destructive command blocking, README gates.

2. **Skill-level** (shell scripts called by skills) — The skill invokes a gate script via Bash. The agent sees the output and must respond. TDD verification, pre-flight checks.

3. **Role-level** (behavioral contracts in `rules/`) — The agent follows SOPs defined in role contracts. Spec-first development, QA evidence requirements, Storyteller resource tracking.

## Key Concepts

**Mechanical gates** block actions automatically. If a project has a `SPEC.md` but no `README.md`, you literally cannot write implementation files — the hook returns exit 2 and the edit is rejected.

**Team skills** coordinate multiple roles. `/team-fullstack` sequences: PM plans sprint -> Lead Dev selects stack -> specialists implement -> Security scrubs -> QA verifies -> Storyteller logs. Each handoff has a structured note.

**TDD enforcement** for logic tasks. The Lead Developer classifies each task. When TDD applies, the specialist must run `tdd-gate.sh verify-red` (test fails) before implementing, then `tdd-gate.sh verify-green` (test passes) after. QA independently verifies via git history.

**Arena** runs structured comparisons. Compare Claude Code configs, prompt strategies, models, or frameworks — with binary, numeric, and LLM-judged scoring criteria.

**Self-iterate** is an autonomous optimization loop. Define an experiment, set eval criteria, and let it run. It modifies the target, evaluates, keeps improvements, reverts regressions, and logs everything to `results.tsv`. Cross-experiment pattern files let future experiments learn from past ones.

## Requirements

- [Claude Code](https://claude.ai/download)
- Git
- Python 3 (for enforcement hooks)
- Bash (for TDD gate scripts)
