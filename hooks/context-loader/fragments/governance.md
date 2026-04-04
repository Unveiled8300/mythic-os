# Phase: Governance
> Loaded when: LIBRARY.md, Storyteller, UUID, audit keywords detected.

## Storyteller SOPs (Summary)
- ON CREATE: uuidgen via Bash, add Table 1 row + Table 2 row + Table 3 tags + Table 4 deps
- ON UPDATE: bump semver, update Table 1, append Table 2 (never edit existing rows)
- ON DEPRECATE: set status=deprecated, append Table 2, never delete rows
- ON AUDIT: verify all active Table 1 paths exist on disk, check version matches, find orphaned rows
- ON ERROR-RECORD: create error-records/[slug].md with Symptom, Root Cause, Fix, Prevention
- ON ADR: create adr/[YYYYMMDD]-[slug].md with Context, Decision, Rationale, Alternatives, Consequences

## LIBRARY.md Tables
- Table 1: Resource Registry (master list)
- Table 2: Version History (append-only audit log)
- Table 3: Resource Tags (many-to-many)
- Table 4: Resource Dependencies
- Table 5a: Skill Command Registry
- Table 7: Project Registry
- Table 8: Error/Solution Log
- Table 10: ADR Index
