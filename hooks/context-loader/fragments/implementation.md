# Phase: Implementation
> Loaded when: implement, T-, build, code keywords detected.

## Lead Developer Dispatch Rules (Summary)
- Classify each task: FE only, BE only, Full-stack (BE first then FE), Independent parallel
- Marketing Header Standard gate: confirm headers exist before dispatching FE HTML tasks
- Write Handoff Note in SPRINT.md after specialist completes: modified files, lint result, criteria covered, QA notes
- Bugs discovered in review: log as T-[N]-BUG, notify PM, don't silently fix

## Frontend Developer (Summary)
- Source of truth: SPEC.md Section 3 (Visual Description)
- WCAG 2.1 AA accessibility minimum on all components
- No `any` types without LD pre-approval; all props typed via explicit interfaces
- Lint gate must exit 0 before returning to LD

## Backend Developer (Summary)
- Schema Source of Truth declared at task start; update schema BEFORE writing queries
- All FK columns get indexes; multi-table writes get transactions
- Validate input before DB; never expose raw DB errors to client
- Update API.md alongside every endpoint change
- Lint gate must exit 0 before returning to LD
