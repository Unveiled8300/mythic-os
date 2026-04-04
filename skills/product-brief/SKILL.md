---
name: product-brief
description: >
  Use this skill when the user says "/product-brief", "start a new project", "I have an idea",
  "let's build [something]", "new feature", "Product Architect: NEW PROJECT", or
  "Product Architect: NEW FEATURE". Activates the full discovery workflow: Marketing Manager
  brief first (for public-facing projects), then Founder Interview across 5 domains, then
  SPEC.md creation. Do NOT use for scope changes on existing projects (use /implement or discuss directly).
version: 1.0.0
---

# /product-brief — New Project or Feature Discovery

You are executing the Product Architect + Marketing Manager discovery sequence.
Follow every step in order.

## Step 0: Load Role Contracts
Before proceeding, read the following role contract(s) using the Read tool:
- `~/.claude/rules/product-architect.md`
- If the project has public-facing pages (determined in Step 1), also read `~/.claude/rules/marketing-manager.md`

## Step 1: Determine Project Type and Planning Track

Ask (or infer from context):
- Does this project have public-facing pages (web app, marketing site, SaaS)?
- Or is it internal tooling, a CLI, or a backend service?

**Planning Track** (auto-detect, Founder can override):
| Signal | Track |
|--------|-------|
| CLI, script, personal tool, single-file | **Quick** |
| Single feature, ≤5 FRs | **Standard** |
| New product, >10 FRs, B2B SaaS, compliance | **Enterprise** |

Record the track — it determines which steps are required vs. skipped below.

**If public-facing → proceed to Step 2.**
**If internal/CLI/backend only → skip to Step 3.**

## Step 2: Marketing Manager Brief (Public-Facing Projects)

Trigger: `Marketing Manager: BRIEF — [project name]`

Execute the following in sequence:

**2a. Business Model Declaration**

Ask the Founder (use `AskUserQuestion`):
- "Is the primary buyer an individual making a personal decision (B2C), or a professional making a business decision (B2B)?"

Record:
```
Business Model: [B2B | B2C]
Primary Buyer: [description]
Decision Trigger: [emotional / ROI / authority / convenience]
```

**2b. User Persona**

Ask the Founder:
- "Who is the user? (role, life context, technical level)"
- "What problem brings them to this product today?" → Pain Point
- "What does success look like for them after using it?" → Desired Gain
- "What is their biggest hesitation before committing?" → Key Objection

Write the Persona Record:
```
## User Persona: [Name or Archetype]
Role: [title / life context]
Technical Level: [novice / intermediate / expert]
Pain Point: [specific friction]
Desired Gain: [concrete outcome sought]
Key Objection: [most likely reason they don't commit]
Decision Trigger: [what causes them to act now]
```

Deliver to Product Architect: "Persona ready. Proceed with Founder Interview. Key Objection must appear in at least one Section 6 criterion."

## Step 3: Founder Interview (Product Architect)

Use `AskUserQuestion` to surface all five domains:

| Domain | Question |
|--------|---------|
| Scope | What's explicitly IN scope? What's OUT? |
| Users | Who is the end user? What's their technical level? |
| Tech constraints | Required languages, frameworks, or existing systems? |
| Non-functional | Performance targets? HIPAA or CA privacy needed? |
| Done condition | How will you know this feature is complete? |

Do not proceed until all five domains are resolved.

**Success Matrix:** Write ≥ 3 testable acceptance criteria using BDD format:
```
Given [precondition or setup]
When [user action or system event]
Then [expected observable outcome]
```
Each criterion must produce a clear PASS or FAIL without ambiguity.

## Step 3b: Discuss Step (Gray Area Surfacing)

**Skip if:** Quick planning track.

After the interview, present the Founder with a focused discussion:
1. **Ambiguities discovered** — areas with multiple valid interpretations
2. **2–3 architectural approaches** — with trade-offs
3. **Your recommendation** — and why

One conversation. Founder confirms or redirects.

Document decisions in a brief Discussion Record:
```
### Discussion Record — [date]
Ambiguities Resolved:
  - [ambiguity] → Founder chose: [decision]
Approach Selected: [approach name] — [rationale]
Rejected: [approach] — because: [reason]
```

## Step 4: Write SPEC.md

Create `[project-root]/SPEC.md` with all 8 required sections:

```
# SPEC: [Project Name]
Version: 1.0.0 | Created: [date] | Status: draft

## 1. Functional Requirements
- FR-01: [verb + noun + outcome]
- FR-02: ...
(minimum 3)

## 2. Non-Functional Requirements
- Performance: [page load target]
- Security: [password hashing, auth method]
- Compliance: [HIPAA: yes/no | CA Privacy: yes/no]

## 3. Visual Description (for Frontend Developer)
[Layout, components, responsive breakpoints, style notes]
[Informed by User Persona Pain Point and Desired Gain]

## 4. Tech Stack
- Language(s): [e.g., TypeScript]
- Framework(s): [e.g., Next.js 14]
- Existing systems: [integrations]
- New dependencies: [list]

## 5. Out of Scope
- [Explicit list of what will NOT be built]

## 6. Definition of Done
- [ ] [Acceptance criterion 1 — testable]
- [ ] [Criterion addressing Key Objection]
- [ ] [Criterion 3+]

## 7. Dependencies & Risks
- Depends on: [systems, APIs, roles]
- Risks: [known unknowns]

## 8. Epic Decomposition
- E-01: [Epic Name] — FR-01, FR-02
  Summary: [shippable increment description]
- E-02: [Epic Name] — FR-03, FR-04
  Summary: [shippable increment description]
(Each FR must belong to exactly one Epic; sequence by dependency)
```

## Step 5: Get Founder Approval

Present the SPEC.md draft. Ask:
"Please review and approve this SPEC.md. Type 'approved' to proceed, or tell me what to change."

On approval: change `Status: draft` → `Status: approved`

Then trigger:
`Storyteller: ON CREATE — SPEC.md for [project name]`

## Step 6: Register the Project

After Storyteller confirms, add a row to LIBRARY.md Table 7 (Project Registry):
```
| [uuid] | [project-name] | active | [spec_path] | [sprint_path] | [tech stack summary] | [today's date] | [notes] |
```

Report: "SPEC.md approved and registered. Run `/sprint-plan` to break this into Atomic Tasks."
