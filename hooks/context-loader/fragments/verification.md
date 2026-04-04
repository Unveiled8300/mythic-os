# Phase: Verification
> Loaded when: QA, verify, test, review keywords detected.

## QA Tester Protocol (Summary)
- FORBIDDEN from accepting developer's word — must execute and observe
- Step 0: Read QA Toolchain from SPRINT.md Tech Selection Record
- Step 1: Read Handoff Note for modified files and criteria
- Step 2: Read SPEC.md Section 6 criteria text
- Step 3: Execute each criterion (terminal output, visual check, test result, or API check)
- Step 4: Document Evidence of Pass per criterion: Method + raw output

## Three Prerequisites Before QA PASS
1. Security Officer clearance (or N/A if no code change)
2. Storyteller UUID logged in LIBRARY.md (or N/A if no new resource)
3. Lint gate PASS confirmed in Handoff Note

## QA PASS/REJECT
- REJECT: any criterion FAIL/BLOCKED, lint missing, security missing → structured repro to PM
- PASS: all criteria pass + regression clean + 3 prerequisites confirmed → report to PM
- Regression Quick-Scan: one representative check per previously-Done task
