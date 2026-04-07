# Mythic OS

A governance framework for [Claude Code](https://claude.ai/download) that turns it into a structured software development team — with roles, enforcement hooks, and self-improving skills.

## Install

```bash
git clone https://github.com/Unveiled8300/mythic-os.git
cd mythic-os

# Preview what will be installed (no changes made)
bash mythic-install.sh

# Install with symlinks (recommended)
bash mythic-install.sh --apply
```

The installer sets up:
- `~/systems/mythic-os/` — source of truth (symlinked from wherever you cloned)
- `~/systems/use-system.sh` — system switcher for multi-system setups
- `~/projects/mythic/` — project workspace with walk-up CLAUDE.md
- `~/.claude/` — symlinks pointing to the repo (skills, rules, hooks, etc.)

Your existing `~/.claude/` runtime data (sessions, plans, history) is preserved. Your personal `claude.md` is never touched.

**Alternative: flat copy install** (no symlinks, no `~/systems/` structure):
```bash
bash mythic-install.sh --apply --copy
```

## Quick Start

```
1. cd ~/projects/mythic
2. mkdir my-app && cd my-app
3. Open Claude Code: claude
4. Type /boot
5. Type /cto "build a task tracker with auth"
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

## Architecture

Mythic OS uses a symlink-based architecture. The repo at `~/systems/mythic-os/` is the single source of truth. `~/.claude/` contains symlinks pointing there, so Claude Code sees the skills, rules, and hooks at their expected runtime paths.

The system switcher (`~/systems/use-system.sh`) manages these symlinks and merges your personal settings with the system's hooks. This means you can have multiple systems installed and switch between them — see [docs/walkthrough.md](docs/walkthrough.md) for the full architecture guide.

## Project Structure

```
rules/          Role contracts (13 specialists with SOPs)
skills/         Slash commands (orchestrated workflows)
hooks/          Enforcement hooks (PreToolUse/PostToolUse gates)
stacks/         Stack templates (Next.js+Supabase, Astro, FastAPI)
agents/         Reusable agent definitions
commands/       Additional Claude commands
templates/      PRD, project, and walk-up CLAUDE.md templates
scripts/        Operational scripts (publish, use-system switcher)
docs/           Architecture walkthrough and guides
CLAUDE.md       Global constitution — loaded every session via walk-up
LIBRARY.md      Resource registry
settings.json   Hook configuration
```

## How Enforcement Works

Mythic OS has three enforcement tiers:

1. **Harness-level** (hooks in `settings.json`) — Run automatically on every tool call. The agent cannot skip them. Secret scanning, destructive command blocking, README gates.

2. **Skill-level** (shell scripts called by skills) — The skill invokes a gate script via Bash. The agent sees the output and must respond. TDD verification, pre-flight checks.

3. **Role-level** (behavioral contracts in `rules/`) — The agent follows SOPs defined in role contracts. Spec-first development, QA evidence requirements, Storyteller resource tracking.

## Requirements

- [Claude Code](https://claude.ai/download)
- Git
- Python 3 (for enforcement hooks)
- Bash
- jq (for settings merge — `brew install jq` on macOS)
