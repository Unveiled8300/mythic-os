# Claude OS

A governance system for Claude Code — roles, skills, and workflows that make Claude a reliable software development partner.

## What This Is

Claude OS is a structured set of role contracts, skills (slash commands), and project management conventions that run inside Claude Code. It gives Claude a consistent, auditable way to plan, build, QA, and ship software.

## What's Inside

| Directory | Contents |
|-----------|----------|
| `rules/` | Role contracts (Product Architect, Lead Developer, QA Tester, etc.) |
| `skills/` | Slash commands (`/boot`, `/implement`, `/qa-verify`, `/deploy`, etc.) |
| `stacks/` | Stack templates (Next.js + Supabase, Astro, Python FastAPI) |
| `templates/` | PRD template, per-project CLAUDE.md template |
| `commands/` | Additional Claude commands |
| `hooks/` | Claude Code hooks (context injection, security reminders) |
| `adr/` | Architecture Decision Records |
| `CLAUDE.md` | The global constitution — loaded at every session |
| `LIBRARY.md` | Resource registry — tracks all active skills, rules, and tools |

## Install

```bash
# Preview what will be installed (no changes made)
bash install.sh

# Install into ~/.claude
bash install.sh --apply
```

The installer copies Claude OS into `~/.claude`, merging with any files already there.

## Getting Started

After installing:

1. Open Claude Code
2. Type `/boot` to initialize a session
3. Type `/cto [your idea]` to start a new project

## Key Slash Commands

| Command | What it does |
|---------|-------------|
| `/boot` | Start every session — loads active project and sprint state |
| `/cto [idea]` | New project entry point — orchestrates the full build lifecycle |
| `/implement [T-ID]` | Dispatch a sprint task to specialist agents |
| `/qa-verify [T-ID]` | Run QA verification against SPEC.md acceptance criteria |
| `/deploy` | Full deployment lifecycle: ENV → CI/CD → staging → production |
| `/reflect` | Post-sprint retrospective — surfaces error patterns and governance gaps |
| `/self-iterate` | Self-reinforced optimization — improve a skill or artifact automatically |

## Self-Iterate

The `self-iterate` skill enables Claude OS to improve itself. Point it at any skill, rule, or prompt file and it will run an optimization loop — testing changes against an eval, keeping improvements, reverting regressions.

```
/self-iterate
→ Asks: what to optimize, how to eval, how many iterations
→ Creates experiment branch
→ Runs loop until threshold or max iterations
→ Reports what worked and what didn't
```

## Related Files

- `LIBRARY.md` — full resource registry with UUIDs
- `LIBRARY-HISTORY.md` — append-only audit trail (version history, tags, dependencies)

## Requirements

- [Claude Code](https://claude.ai/download)
- Git (for version control of your governance files)
- Python 3 (for the context-loader hook)
