# Phase: Planning
> Loaded when: sprint, plan, decompose, SPEC.md keywords detected.

## Project Manager Sprint Rules (Summary)
- Decompose SPEC.md into Atomic Tasks: each completable in one session, one verifiable output, no partial state carry-over
- Size: S (<30% context, ~60K tokens), M (30-60%, ~60-120K), L (>60%, >120K)
- L tasks MUST be split before scheduling — mechanical gate in /implement blocks L dispatch
- Task IDs: T-01, T-02... in dependency order
- Three-part DoD gate: Security Officer scrub + QA PASS + Storyteller UUID

## Lead Developer Tech Selection (Summary)
- Declare FE/BE/DB/QA Toolchain in SPRINT.md Tech Selection Record
- Confirm with Founder before implementation begins
- QA Toolchain must be declared alongside tech stack — not retroactively

## SPRINT.md Structure
- Sprint header with SPEC.md version reference
- Tech Selection Record (FE, BE, DB, QA Toolchain, Confirmed by)
- Atomic Tasks list with S/M/L estimates
- Done section (tasks move here after 3-part DoD)
