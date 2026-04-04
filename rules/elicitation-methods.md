# Elicitation Methods: Curated Toolkit

> **TL;DR:** Five structured thinking methods wired to specific decision points in the system.
> Not auto-loaded. Referenced by Product Architect, Project Manager, Lead Developer, and QA
> when they hit high-leverage decisions where wrong assumptions are expensive.

---

## Method 1: Pre-Mortem Analysis

**Wired To:** Project Manager SOP 1 — Sprint Decomposition
**Trigger:** "Assume this sprint failed — what went wrong?"

### When to Use
Before finalizing a sprint breakdown. Surfaces missed dependencies, underestimated tasks,
and integration risks not visible from SPEC.md alone.

### Protocol
1. State: "This sprint is complete and has failed."
2. List 3-5 plausible failure modes (real risks, not hypothetical edge cases):
   - Task dependency missed → blocked mid-sprint
   - Context budget exceeded → forced /compact mid-task
   - External API unavailable → integration tasks blocked
   - Schema migration breaks existing data → rollback needed
   - Ambiguous acceptance criterion → QA REJECT after implementation
3. For each: identify the preventive action and add it to SPRINT.md

### Output Format
```
### Pre-Mortem — [Sprint/Story Name] — [date]
| Failure Mode | Likelihood | Preventive Action | Added To |
|-------------|-----------|-------------------|----------|
| [description] | High/Med/Low | [action] | SPRINT.md T-[N] |
```

---

## Method 2: First Principles Thinking

**Wired To:** Lead Developer SOP 1 — Tech Selection
**Trigger:** "Strip all inherited assumptions — why this stack from ground truth?"

### When to Use
When selecting a tech stack. Prevents cargo-culting previous choices.

### Protocol
1. List the project's actual constraints (from SPEC.md Sections 1, 2, 4):
   - Data model complexity, expected traffic/scale, team expertise,
     deployment target, time constraints
2. For each constraint, derive the minimum technical requirement (a capability, not a tool)
3. Only then match capabilities to specific tools/frameworks
4. If the match differs from the "obvious" choice, document why in the Reasoning Manifest

### Output Format
```
### First Principles — Tech Selection — [date]
| Constraint | Required Capability | Tool Selected | Why |
|-----------|-------------------|--------------|-----|
| [constraint] | [capability] | [tool] | [rationale] |

Inherited assumptions challenged:
- [assumption] → [kept/dropped] because [reason]
```

---

## Method 3: Red Team / Blue Team

**Wired To:** /peer-review + QA Tester SOP 4 — QA PASS
**Trigger:** "Attack your own work, then defend it."

### When to Use
During adversarial review and before issuing QA PASS.

### Protocol

**Red Team (Attack — 5 min):**
1. Identify the 3 most likely failure points
2. For each: describe the attack vector (bad input, race condition, edge case, missing validation)
3. Attempt to trigger each failure

**Blue Team (Defend — 5 min):**
1. For each attack: explain why the implementation handles it correctly, OR
2. Acknowledge the vulnerability and log it as a finding

**Zero-Findings Rule:** If Red Team finds zero issues across all 3 attack vectors,
re-examine using a different method (rotate to next in Quick Reference table).
Two consecutive zero-findings rounds → escalate to Founder.

### Output Format
```
### Red Team / Blue Team — T-[N] — [date]
| Attack Vector | Red Team Finding | Blue Team Response | Status |
|--------------|-----------------|-------------------|--------|
| [vector] | [finding or "clean"] | [defense or "acknowledged"] | DEFENDED / LOGGED |

Zero-Findings Check: [PASS — findings exist / HALT — re-examine required]
```

---

## Method 4: Socratic Questioning

**Wired To:** Product Architect SOP 1 — Discuss Step (Gray Area Surfacing)
**Trigger:** "Why this approach? How do you know?"

### When to Use
During the Discuss Step, when presenting architectural approaches to the Founder.

### Protocol
Apply these 5 question types to each proposed approach:

| Question Type | Example |
|--------------|---------|
| Clarification | "What exactly do you mean by [term]?" |
| Assumption probing | "What are we assuming about [user behavior / data volume / API stability]?" |
| Evidence seeking | "What evidence supports this approach over the alternatives?" |
| Perspective shifting | "If we were the end user, would this decision make sense?" |
| Consequence exploring | "If we choose this, what becomes harder to change later?" |

### Output Format
```
### Socratic Inquiry — [Approach Name] — [date]
Assumptions surfaced:
- [assumption] → Founder confirmed: [yes/no/modified]
Evidence gaps:
- [gap] → Resolution: [how addressed]
```

---

## Method 5: Inversion

**Wired To:** Product Architect SOP 4 — Definition of Done
**Trigger:** "How would we guarantee this feature fails?"

### When to Use
When writing acceptance criteria for SPEC.md Section 6.

### Protocol
1. For each functional requirement, ask: "How would I guarantee this feature fails?"
2. List 3 failure scenarios per requirement
3. Invert each into a testable acceptance criterion:
   - Failure: "User submits empty form and gets a 500 error"
   - Inversion: "Given empty form submission / When user clicks Submit / Then validation
     error is displayed (no server error)"
4. Add the strongest inversions to SPEC.md Section 6

### Output Format
```
### Inversion — [Feature Name] — [date]
| Requirement | Guaranteed Failure | Inverted Criterion |
|------------|-------------------|-------------------|
| FR-[N] | [how it would fail] | Given/When/Then |
```

---

## Quick Reference: Method Selection

| Decision Point | Default Method | Rotate To (if zero findings) |
|---------------|---------------|----------------------------|
| Sprint Decomposition (PM) | Pre-Mortem | Inversion |
| Tech Selection (LD) | First Principles | Socratic Questioning |
| Discuss Step (PA) | Socratic Questioning | First Principles |
| Definition of Done (PA) | Inversion | Pre-Mortem |
| Adversarial Review (QA) | Red Team / Blue Team | Inversion |

---

## Rules

- Methods fire only at the 5 decision points listed above — not on every task.
- Output format is mandatory. A method applied without documented output did not happen.
- Zero-findings rotation applies to Red Team / Blue Team and Pre-Mortem only.
- This file is loaded by Read tool when a skill needs it — never injected into every session.
