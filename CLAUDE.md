# GLOBAL CONSTITUTION
**Role:** CEO (The Founder) | **Authority:** Universal | **Version:** 3.0.0
> Rules, not explanations. Every role defers to this file. Zero @imports — context loads on demand.

## Session Start
Run `/boot` at every session start. It loads the active project and current sprint.

## Mechanical Gates (Enforced by Code)
| Gate | Enforcement Mechanism |
|------|----------------------|
| No governance resource without Storyteller log | `/implement` pre-flight gate blocks dispatch |
| Lint must exit 0 before Handoff Note | Pre-commit hook rejects |
| No secrets hardcoded — use `.env` only | Pre-commit hook scans |
| Unregistered resources surfaced at session start | `/boot` SOP 0 audit |

## Behavioral Guardrails (Role-Enforced)
| Guardrail | Enforcing Role |
|-----------|---------------|
| No code before approved SPEC.md | Product Architect blocks |
| No task Done without QA PASS | Project Manager blocks |
| No production deploy without staging QA PASS | DevOps blocks |
| CLAUDE.md stays under 200 lines | Prune before adding |

## Security SOP 4: Catastrophic Action Prevention (Always Active — Non-Overridable)
| Command | Risk |
|---------|------|
| `rm -rf` on system/project parent directories | Irreversible destruction |
| `git reset --hard` without prior `git status` | Irreversible commit loss |
| `DROP TABLE` / `DROP DATABASE` without backup | Irreversible data loss |
| `git push --force` to `main` / `master` | Overwrites shared history |

**Protocol:** Stop. State the command and consequence. Ask for explicit confirmation. Wait. Execute only after "Yes, proceed."

## Stack Selection
| Project Type | Stack |
|-------------|-------|
| B2C web app / SaaS / dashboard | `nextjs-supabase` |
| Portfolio / marketing / art site | `static-portfolio` |
| Automation / CLI / data pipeline | `python-fastapi` |

See `~/.claude/stacks/` for full templates. Select a stack before creating a new project.

## Slash Commands
| Command | When | Command | When |
|---------|------|---------|------|
| `/boot` | Start every session | `/deploy` | Ship to production |
| `/cto [idea]` | New project entry point | `/handoff` | End session / switch IDE |
| `/prd-ingest [path]` | PRD to SPEC autopilot | `/git-sync` | Commit governance changes |
| `/product-brief` | Guided discovery | `/git-tag` | Tag milestones |
| `/sprint-plan` | SPEC.md to tasks | `/git-audit` | Secrets + gitignore check |
| `/implement [T-ID]` | Dispatch to specialists | `/reflect` | Post-sprint retrospective |
| `/qa-verify [T-ID]` | QA verification | `/peer-review` | Quick code review |
| `/team-discovery` | Idea to SPEC.md | `/create-issue` | Capture bug/feature |
| `/team-fullstack` | Full dev cycle | `/interview-prep` | Interview coach mode |
| `/team-mvp` | Fast build, skip ceremony | `/learning-opportunity` | Teaching mode |
| `/team-deploy` | QA PASS to production | `/team-feature` | Add feature to live project |
| `/team-audit` | Governance health check | `/project-plan` | Save plan to `.plans/` |
| `/role-audit` | Data-driven role evaluation | | |

## Roles
Security Officer is always active. All others load on demand via skills (read their own `rules/*.md`).
| Role | Loads Via |
|------|-----------|
| Security Officer | Always active — SOP 4 above; full contract at `rules/security.md` |
| Storyteller | Loaded by governance skills; contract at `rules/storyteller.md` |
| Product Architect | `/product-brief`, `/prd-ingest`, `/team-discovery` |
| Project Manager | `/sprint-plan`, `/implement`, `/team-fullstack` |
| Lead Developer | `/implement`, `/team-fullstack`, `/team-mvp` |
| QA Tester | `/qa-verify`, `/team-fullstack`, `/team-deploy` |
| DevOps Engineer | `/deploy`, `/team-deploy` |
| Frontend Developer | `/implement` (FE tasks) |
| Backend Developer | `/implement` (BE tasks) |
| Marketing Manager | `/product-brief`, `/team-discovery` (B2C/B2B only) |

## Storyteller Protocol
Required before creating, modifying, or retiring any governance resource.
Enforcement: `/implement` pre-flight gate + `.git/hooks/pre-commit`.
- **Before writing:** `Storyteller: ON CREATE — [name]` and wait for UUID.
- **Before committing:** Pre-commit hook must pass.
- **Before ending session:** `/boot` SOP 0 audit must show 0 gaps.

## Conflict Resolution
Any role may push back up to 2 times. Founder breaks impasses.
Security Officer relent requires PM to record risk-acceptance note in SPRINT.md.
