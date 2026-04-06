# Global Resource Library

> Single source of truth for all reusable assets. Owned by Storyteller (`rules/storyteller.md`).
> Never delete entries — set status: deprecated. Legend/schema details in `rules/storyteller.md`.

Schema: 3.0.0 | Audited: 2026-03-11 | Cold storage: LIBRARY-HISTORY.md (Tables 2,3,4)

## Resources

All entries are `active` unless a `status` field says otherwise.
Paths are relative to `~/.claude/`.

```yaml
# --- Rules ---
- id: a3f7b2c1-9e4d-4f8a-b123-7e6d5c4b3a29
  name: storyteller
  type: rule
  ver: 1.2.0
  path: rules/storyteller.md
  desc: Owns LIBRARY.md and documentation SOPs
  updated: 2026-03-11

- id: 7f0bed18-846b-403b-a594-ec0424aea755
  name: claude-md
  type: rule
  ver: 2.1.0
  path: CLAUDE.md
  desc: Global Constitution; CEO governance file
  updated: 2026-03-16

- id: a1dc5587-2fa7-44d3-8ef8-a1e7b98af1da
  name: security-officer
  type: rule
  ver: 1.1.0
  path: rules/security.md
  desc: Input sanitization, code scrubbing, HIPAA/CA, catastrophic action prevention
  updated: 2026-03-08

- id: 9e0e7efe-b326-4455-9d1a-52a082354105
  name: product-architect
  type: rule
  ver: 1.3.0
  path: rules/product-architect.md
  desc: Owns SPEC.md, Founder Interview, Definition of Done, Kickoff Sequence
  updated: 2026-03-12

- id: 2e8b1129-30c4-4b2f-b31a-1c5e33185ab5
  name: project-manager
  type: rule
  ver: 1.1.0
  path: rules/project-manager.md
  desc: Owns SPRINT.md, task decomposition, context budgeting, DoD enforcement
  updated: 2026-03-12

- id: fa9b1dbc-87ba-44c9-9b1d-584c6676b6f1
  name: lead-developer
  type: rule
  ver: 1.3.0
  path: rules/lead-developer.md
  desc: Coordinates FE/BE specialists, Tech Selection, task dispatch, Handoff Notes
  updated: 2026-03-12

- id: f82669cd-91e9-4456-98a9-973d6fe5fa5b
  name: frontend-dev
  type: rule
  ver: 1.1.0
  path: rules/frontend-dev.md
  desc: React/TS UI per SPEC.md Section 3, WCAG 2.1 AA, lint gate
  updated: 2026-03-12

- id: 000c95de-9853-4ccb-bc65-254c6da00e9d
  name: backend-dev
  type: rule
  ver: 1.1.0
  path: rules/backend-dev.md
  desc: API endpoints, DB layer, FK indexes, idempotency, API.md docs
  updated: 2026-03-11

- id: 9d350282-213f-413b-8f01-839094272d2b
  name: vendor-manager
  type: rule
  ver: 1.0.0
  path: rules/vendor-manager.md
  desc: IDE handoff, co-work packaging, asset normalization, MCP health
  updated: 2026-03-08

- id: cf18db9d-3ee1-49c0-952c-8a60a6a9acc5
  name: qa-tester
  type: rule
  ver: 1.2.0
  path: rules/qa-tester.md
  desc: Verifies SPEC.md Section 6 criteria, regression scans, QA PASS/REJECT
  updated: 2026-03-12

- id: 2534a0e7-ae18-4054-aa13-d0567f958f05
  name: marketing-manager
  type: rule
  ver: 1.0.0
  path: rules/marketing-manager.md
  desc: B2B/B2C mode, User Persona, SEO metadata standard, Brand Voice Audit
  updated: 2026-03-09

- id: 81fa09ff-2bf5-462c-995c-1562ea97be01
  name: devops
  type: rule
  ver: 1.2.0
  path: rules/devops.md
  desc: CI/CD, staging/prod deploy, smoke tests, monitoring, incident response
  updated: 2026-03-12

- id: e8465b9b-7cc4-41e7-a75d-c94301bec7dc
  name: elicitation-methods
  type: rule
  ver: 1.0.0
  path: rules/elicitation-methods.md
  desc: 5 methods (Pre-mortem, First Principles, Red Team, Socratic, Inversion)
  updated: 2026-03-28

- id: e4256396-df73-4be6-b0fc-f6a2728ec04d
  name: git-workflow
  type: rule
  ver: 1.0.0
  path: rules/git-workflow.md
  desc: Feature branching, conventional commits, PR template, branch naming
  updated: 2026-03-28

# --- Skills ---
- id: 00d83a26-26c3-4ce2-a3d2-39e19aaa8ec4
  name: boot
  type: skill
  ver: 1.1.0
  path: skills/boot/SKILL.md
  cmd: /boot
  desc: Session init; loads project context, sprint state, governance audit
  updated: 2026-03-16

- id: 75753908-1b6c-4dec-b9b2-a9c633aba7ce
  name: product-brief
  type: skill
  ver: 1.0.0
  path: skills/product-brief/SKILL.md
  cmd: /product-brief
  desc: Marketing brief + Founder Interview to produce approved SPEC.md
  updated: 2026-03-11

- id: df48d8ef-33eb-4a0d-82e4-a98d4929f587
  name: sprint-plan
  type: skill
  ver: 1.0.0
  path: skills/sprint-plan/SKILL.md
  cmd: /sprint-plan
  desc: Decomposes SPEC.md into Atomic Tasks, writes SPRINT.md
  updated: 2026-03-11

- id: a698ef23-4430-4e9c-9b11-8ff827dffa19
  name: implement
  type: skill
  ver: 1.2.0
  path: skills/implement/SKILL.md
  cmd: /implement
  desc: Dispatches Atomic Tasks to specialist agents via Lead Developer
  updated: 2026-03-16

- id: 07e5e90f-5462-4e91-90d0-665c487e6f70
  name: marketing-brief
  type: skill
  ver: 1.0.0
  path: skills/marketing-brief/SKILL.md
  cmd: /marketing-brief
  desc: B2B/B2C mode declaration + User Persona delivery
  updated: 2026-03-11

- id: d179274e-e7cf-43ea-a9d3-53f826d4ef88
  name: voice-audit
  type: skill
  ver: 1.0.0
  path: skills/voice-audit/SKILL.md
  cmd: /voice-audit
  desc: Audits UI text against B2B/B2C voice standard
  updated: 2026-03-11

- id: 6b4f065f-b830-454a-b6e2-9b1aca292801
  name: metadata
  type: skill
  ver: 1.0.0
  path: skills/metadata/SKILL.md
  cmd: /metadata
  desc: Generates Marketing Header specs for 7 required SEO tags
  updated: 2026-03-11

- id: 1926e375-88f8-472e-8b6e-09beee2304c4
  name: qa-verify
  type: skill
  ver: 1.0.0
  path: skills/qa-verify/SKILL.md
  cmd: /qa-verify
  desc: QA Tester verifies task against SPEC.md Section 6 criteria
  updated: 2026-03-11

- id: 803c3e3e-df01-4d60-a84d-260fc049eb83
  name: handoff
  type: skill
  ver: 1.0.0
  path: skills/handoff/SKILL.md
  cmd: /handoff
  desc: Prepares HANDOFF.md for IDE context transfer
  updated: 2026-03-11

- id: f7db63ac-0cd8-4132-a301-a28773d3b246
  name: deploy
  type: skill
  ver: 1.0.0
  path: skills/deploy/SKILL.md
  cmd: /deploy
  desc: Full deploy sequence: ENV-SETUP > PIPELINE > STAGE > SHIP > MONITOR
  updated: 2026-03-11

- id: 5cd1c551-38d7-40c2-a276-37ab56c19885
  name: team-discovery
  type: skill
  ver: 1.0.0
  path: skills/team-discovery/SKILL.md
  cmd: /team-discovery
  desc: Marketing Manager + Product Architect to produce SPEC.md from idea
  updated: 2026-03-11

- id: afed3c0e-f769-4161-8152-0622aefd707c
  name: team-fullstack
  type: skill
  ver: 1.0.0
  path: skills/team-fullstack/SKILL.md
  cmd: /team-fullstack
  desc: Full dev team from SPEC.md through implementation, QA, Done
  updated: 2026-03-11

- id: b7f265f1-e373-4d02-9e39-26420375fb7d
  name: team-mvp
  type: skill
  ver: 1.0.0
  path: skills/team-mvp/SKILL.md
  cmd: /team-mvp
  desc: Streamlined build; skips non-essential roles, keeps Security+QA
  updated: 2026-03-11

- id: b07bd667-3f5a-49bf-a60e-e6d243495164
  name: team-audit
  type: skill
  ver: 1.0.0
  path: skills/team-audit/SKILL.md
  cmd: /team-audit
  desc: Security + QA + Storyteller integrity check on full system
  updated: 2026-03-11

- id: 566c6a6f-8d03-4165-9ff5-79e55cf8fa78
  name: team-deploy
  type: skill
  ver: 1.0.0
  path: skills/team-deploy/SKILL.md
  cmd: /team-deploy
  desc: DevOps + QA for full deployment lifecycle
  updated: 2026-03-11

- id: 3127e5fe-856e-4e09-a220-9cdfcc5e4762
  name: reflect
  type: skill
  ver: 1.0.0
  path: skills/reflect/SKILL.md
  cmd: /reflect
  desc: Retrospective; scans error-records, reviews ADRs, proposes updates
  updated: 2026-03-11

- id: 79bd3486-e858-421b-9bae-b0da6dc2d539
  name: brand-voice-generator
  type: skill
  ver: 1.0.0
  path: skills/brand-voice-generator/SKILL.md
  desc: Creates brand.json + tone-of-voice.md for PPTX and content gen
  updated: 2026-03-13

- id: f10338f4-5ad9-421d-82b7-fee7817f6f88
  name: mcp-client
  type: skill
  ver: 1.0.0
  path: skills/mcp-client/SKILL.md
  desc: Universal MCP wrapper; progressive disclosure of tool schemas
  updated: 2026-03-13

- id: e223b0f5-96e6-46c9-bc04-f0efec87bdb2
  name: sop-creator
  type: skill
  ver: 1.0.0
  path: skills/sop-creator/SKILL.md
  desc: Generates runbooks, playbooks, and technical docs
  updated: 2026-03-13

- id: e161825c-d66a-4b32-83b6-a23ff3318de8
  name: git-sync
  type: skill
  ver: 1.0.0
  path: skills/git-sync/SKILL.md
  cmd: /git-sync
  desc: Atomic commit+push for governance changes with audit metadata
  updated: 2026-03-14

- id: 14e1beae-ff52-47d1-a12a-9eae2120ea9a
  name: git-tag
  type: skill
  ver: 1.0.0
  path: skills/git-tag/SKILL.md
  cmd: /git-tag
  desc: Annotated git tags for governance checkpoints
  updated: 2026-03-14

- id: aca7b818-a8ec-4ddd-bf5d-1c459e9c0669
  name: git-audit
  type: skill
  ver: 1.0.0
  path: skills/git-audit/SKILL.md
  cmd: /git-audit
  desc: .gitignore compliance, secret detection, branch health
  updated: 2026-03-14

- id: 1e573a80-aec9-4d75-b92f-95d948f25e76
  name: cto
  type: skill
  ver: 1.0.0
  path: skills/CTO/SKILL.md
  cmd: /cto
  desc: Meta-orchestrator; classifies project, selects stack+pod, coordinates lifecycle
  updated: 2026-03-15

- id: 5b2c9963-4aaa-4ae4-a83c-3821f904d982
  name: prd-ingest
  type: skill
  ver: 1.0.0
  path: skills/prd-ingest/SKILL.md
  cmd: /prd-ingest
  desc: PRD to SPEC.md with <=5 gap questions, auto-triggers sprint plan
  updated: 2026-03-15

- id: 27578c31-f631-4fbf-9826-3a8701afc640
  name: team-feature
  type: skill
  ver: 1.0.0
  path: skills/team-feature/SKILL.md
  cmd: /team-feature
  desc: Adds feature to live project; Feature Addendum, not new SPEC.md
  updated: 2026-03-15

- id: e72dfd5b-15ab-4a16-9441-9474eb3f0d6e
  name: remotion
  type: skill
  ver: 1.0.0
  path: skills/remotion/SKILL.md
  desc: React-based video compositions and animations (22 rule files)
  updated: 2026-03-15

- id: 640d6e8c-f1e2-4022-a902-c634c959c04c
  name: pptx-generator
  type: skill
  ver: 1.0.0
  path: skills/pptx-generator/SKILL.md
  desc: PowerPoint files, LinkedIn carousels; requires brand-voice-generator
  updated: 2026-03-15

- id: 58c2e1ea-9728-407a-aad5-dcc428308137
  name: skill-creator
  type: skill
  ver: 1.0.0
  path: skills/skill-creator/SKILL.md
  desc: Patterns and workflow for authoring SKILL.md files
  updated: 2026-03-15

- id: c930d21c-61a1-42e0-a301-910b13485d9b
  name: project-plans
  type: skill
  ver: 1.0.0
  path: skills/project-plans/SKILL.md
  cmd: /project-plan
  desc: Saves plan content to .plans/ with chronological naming
  updated: 2026-03-28

- id: ab1d5949-5510-46da-94dd-da23caabc006
  name: self-iterate
  type: skill
  ver: 1.1.0
  path: skills/self-iterate/SKILL.md
  desc: Self-reinforced optimization entry point; config > branch > eval > loop
  updated: 2026-03-28

- id: 3d4f2ab3-66a2-4240-91b7-3c243d8e5a6d
  name: eval-harness
  type: skill
  ver: 1.0.1
  path: skills/self-iterate/eval-harness/SKILL.md
  desc: Binary test runner for optimization loops; PASS/FAIL/CRASH verdict
  updated: 2026-03-28

- id: 1a10e431-a821-49bc-9628-cdb32e66dcc9
  name: git-experiment
  type: skill
  ver: 1.0.1
  path: skills/self-iterate/git-experiment/SKILL.md
  desc: Branch lifecycle for optimization experiments
  updated: 2026-03-28

- id: f45304d6-24fb-4651-8626-66e0f603e4a3
  name: optimize-loop
  type: skill
  ver: 1.0.1
  path: skills/self-iterate/optimize-loop/SKILL.md
  desc: Iterative modify > commit > eval loop; keeps wins, reverts regressions
  updated: 2026-03-28

- id: 11c708c4-f738-4a48-b99c-675f65b27a86
  name: history-report
  type: skill
  ver: 1.0.1
  path: skills/self-iterate/history-report/SKILL.md
  desc: Post-loop report with stats, patterns, and recommendations
  updated: 2026-03-28

- id: 7127bc20-c9c8-4038-a3cc-4b9d76ba7892
  name: frontend-design
  type: skill
  ver: 1.0.0
  path: skills/frontend-design/SKILL.md
  desc: Production-grade frontend interfaces; avoids generic AI aesthetics
  updated: 2026-03-28

- id: 1df4f300-b9d7-4449-a217-ca8abf5d328e
  name: map-codebase
  type: skill
  ver: 1.0.0
  path: skills/map-codebase/SKILL.md
  cmd: /map-codebase
  desc: Brownfield onboarding; generates CODEBASE.md from existing repo
  updated: 2026-03-28

- id: 9fdf1e99-947c-4392-9297-ca6258f804c0
  name: sweep
  type: skill
  ver: 1.0.0
  path: skills/sweep/SKILL.md
  cmd: /sweep
  desc: Proactive full-project vulnerability scan, fragility detection, auto-patch
  updated: 2026-04-04

- id: 05be11c0-36bf-4cf7-8b5a-5ffaa9fe1ec6
  name: arena
  type: skill
  ver: 1.0.0
  path: skills/arena/SKILL.md
  cmd: /arena
  desc: Agnostic head-to-head matchup framework; user-defined contestants, tasks, scoring
  updated: 2026-04-04

- id: 60972729-a3c2-4d94-af81-4a505214f45c
  name: arena-run-matchup
  type: skill
  ver: 1.0.0
  path: skills/arena/run-matchup/SKILL.md
  desc: Executes all arena contestants in isolated workspaces, collects outputs
  updated: 2026-04-04

- id: 193685f2-7035-4909-a2fe-b863db431d36
  name: arena-scorecard
  type: skill
  ver: 1.0.0
  path: skills/arena/scorecard/SKILL.md
  desc: Scores arena contestants, renders comparison report with rankings
  updated: 2026-04-04

- id: 4baa4b90-85a5-4b10-97c6-d240b91d2426
  name: feature-forge
  type: skill
  ver: 1.0.0
  path: skills/feature-forge/SKILL.md
  cmd: /feature-forge
  desc: Multi-variant feature generation; spawns N parallel implementations, evaluates, selects best
  updated: 2026-04-04

# --- Stack Templates ---
- id: 31742478-cf01-40c8-96bf-7bad925ae734
  name: stack-nextjs-supabase
  type: tool
  ver: 1.0.0
  path: stacks/nextjs-supabase/STACK.md
  desc: Next.js 14 + Supabase + Prisma stack for B2C/SaaS
  updated: 2026-03-15

- id: 1c7b789e-5500-4fe9-a060-404048252fe8
  name: stack-static-portfolio
  type: tool
  ver: 1.0.0
  path: stacks/static-portfolio/STACK.md
  desc: Astro 4 + Tailwind for portfolio/marketing sites
  updated: 2026-03-15

- id: 6be77bbf-ad64-4e65-a739-490622406f5c
  name: stack-python-fastapi
  type: tool
  ver: 1.0.0
  path: stacks/python-fastapi/STACK.md
  desc: Python 3.11 + FastAPI + SQLAlchemy for APIs/pipelines
  updated: 2026-03-15

# --- Templates ---
- id: 41b32e53-833f-4f7f-b341-aac770e170a6
  name: prd-template
  type: prompt
  ver: 1.0.0
  path: templates/PRD_TEMPLATE.md
  desc: Structured PRD covering all 5 Founder Interview domains
  updated: 2026-03-15

- id: 15a32fa4-d0e3-484a-8789-e3014a65c540
  name: project-claude-template
  type: prompt
  ver: 1.0.0
  path: templates/PROJECT_CLAUDE.md
  desc: Per-project CLAUDE.md template with commands, paths, gates
  updated: 2026-03-15

# --- Commands ---
- id: 7a6b020e-6937-4361-b04a-2b0491513ee3
  name: clean-gone
  type: prompt
  ver: 1.0.0
  path: commands/clean_gone.md
  cmd: /clean-gone
  desc: Removes local branches marked [gone] on remote
  updated: 2026-03-28

- id: 0edae3ea-a970-46a9-a67a-ba746979ef21
  name: code-review
  type: prompt
  ver: 1.0.0
  path: commands/code-review.md
  cmd: /code-review
  desc: Reviews a PR for quality, style, correctness
  updated: 2026-03-28

- id: 16c229eb-fb86-48b6-bf2f-3fadc2eff145
  name: commit-push-pr
  type: prompt
  ver: 1.0.0
  path: commands/commit-push-pr.md
  cmd: /commit-push-pr
  desc: Commit + push + open PR in one sequence
  updated: 2026-03-28

- id: 9c0c4d34-c483-4103-9ebb-8138f1d7a6ce
  name: commit
  type: prompt
  ver: 1.0.0
  path: commands/commit.md
  cmd: /commit
  desc: Creates well-formatted git commit from staged changes
  updated: 2026-03-28

- id: edd3cda8-5be1-4115-a529-6e304c05b162
  name: feature-dev
  type: prompt
  ver: 1.0.0
  path: commands/feature-dev.md
  cmd: /feature-dev
  desc: Guided feature development with codebase understanding
  updated: 2026-03-28

- id: 71776547-fa08-4868-aa70-da26eb7ac1c3
  name: review-pr
  type: prompt
  ver: 1.0.0
  path: commands/review-pr.md
  cmd: /review-pr
  desc: Comprehensive PR review using specialized agents
  updated: 2026-03-28

- id: 3ec51f4f-78a5-4ce3-be54-9fc4d640f178
  name: governance-qa
  type: prompt
  ver: 1.0.0
  path: commands/governance-qa.md
  cmd: /governance-qa
  desc: Post-build audit of all six self-enforcement gates
  updated: 2026-03-28

- id: 211d5f93-319e-4b71-8e0c-700fe1afe469
  name: document
  type: prompt
  ver: 1.0.0
  path: commands/zevi-commands/document.md
  cmd: /document
  desc: Updates project documentation
  updated: 2026-03-28

- id: 3cfa21db-7628-481f-b1e7-14e067474b83
  name: review
  type: prompt
  ver: 1.0.0
  path: commands/zevi-commands/review.md
  cmd: /review
  desc: Code review for quality and correctness
  updated: 2026-03-28

- id: 6bb5992e-c69b-4bf0-b737-c9f787d439e9
  name: peer-review
  type: prompt
  ver: 1.0.0
  path: commands/zevi-commands/peer-review.md
  cmd: /peer-review
  desc: Second-opinion team-lead-level code review
  updated: 2026-03-28

- id: 1ba919bb-9a9c-41bb-8e06-7f9c22e16acb
  name: create-issue
  type: prompt
  ver: 1.0.0
  path: commands/zevi-commands/create-issue.md
  cmd: /create-issue
  desc: Captures bugs or feature ideas as structured issues
  updated: 2026-03-28

- id: 7ee9716b-c46c-4ae7-80bd-621c42b93970
  name: interview-prep
  type: prompt
  ver: 1.0.0
  path: commands/zevi-commands/interview-prep.md
  cmd: /interview-prep
  desc: Interview practice coaching
  updated: 2026-03-28

- id: d4c117d0-673b-4779-8cbb-1689882e7390
  name: learning-opportunity
  type: prompt
  ver: 1.0.0
  path: commands/zevi-commands/learning-opportunity.md
  cmd: /learning-opportunity
  desc: Teaching mode; explains code concepts and patterns
  updated: 2026-03-28
```

## Projects

Fields: project_id, name, status, spec_path, sprint_path, tech_stack, last_session, notes

```yaml
# (empty — add via Product Architect: NEW PROJECT)
```

## Errors

Fields: error_id, resource_id, root_cause_category, severity, recurrence_count, status, notes
Full records: `~/.claude/error-records/[slug].md`

```yaml
# (empty — add via Storyteller: ON ERROR-RECORD)
```

## ADRs

Fields: adr_id, title, status, date, decision_summary
Full records: `~/.claude/adr/[YYYYMMDD]-[slug].md`

```yaml
# (empty — add via Storyteller: ON ADR)
```

## Usage

Follow `rules/storyteller.md` SOPs. Append YAML entries (never delete). Log every change in LIBRARY-HISTORY.md Table 2. Generate UUIDs via `uuidgen | tr '[:upper:]' '[:lower:]'`.
