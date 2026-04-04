---
name: team-discovery
description: >
  Use this skill when the user says "/team-discovery", "run discovery", "start the discovery
  team", "kick off a new project", "System: KICKOFF", or wants to go from raw idea to approved
  SPEC.md in one coordinated sequence. Assembles the Discovery Pod (Marketing Manager +
  Product Architect) and runs them in the correct sequence. Output: approved SPEC.md ready
  for sprint planning.
version: 1.0.0
---

# /team-discovery — Discovery Pod

You are coordinating the Discovery Pod. This team runs Phase 1 of the lifecycle:
**Founder idea → approved SPEC.md**.

## Step 0: Load Role Contracts
Before proceeding, read the following role contract(s) using the Read tool:
- `~/.claude/rules/product-architect.md`
- `~/.claude/rules/marketing-manager.md`

## Pod Composition

| Role | Responsibility in This Pod |
|------|---------------------------|
| Marketing Manager | Business model declaration + User Persona (runs first) |
| Product Architect | Founder Interview + SPEC.md creation (runs second) |
| **Founder** | Approves SPEC.md Section 6 Definition of Done |

## When to Use This Pod

- Starting a brand new project from scratch
- Starting a new major feature that needs its own SPEC.md
- When `System: KICKOFF — [description]` is triggered

**Not for:** Scope changes on an approved SPEC.md (use Product Architect directly) or when you already have an approved SPEC.md (use `/team-fullstack` or `/sprint-plan`).

---

## Step 1: Project Type Classification

Read the Founder's project description. Classify:

| Project Type | Team Modification |
|---|---|
| Full-stack web app with public pages | Full pod — both roles run |
| SaaS product, marketing site, mobile app | Full pod — both roles run |
| CLI tool, script, data pipeline | Marketing Manager skipped — Product Architect only |
| Personal/dogfood tool (only Founder uses it) | Marketing Manager skipped — Product Architect only |
| Backend-only service, no UI | Marketing Manager skipped — Product Architect only |

State clearly to the Founder:
> "For [description], I'll run: [roles list]. Skipping: [roles] because [reason]. Shall I proceed?"

Wait for confirmation before continuing.

---

## Step 2: Check LIBRARY.md for Existing Resources

Before creating anything new, read `~/.claude/LIBRARY.md` Table 1.

Look for:
- An existing SPEC.md for this project (if one already exists, this is a scope change — use Product Architect directly)
- Any existing integrations, APIs, or tools that this project should use

Report findings: "LIBRARY.md check: [X] potentially reusable resources found: [names]. Will incorporate into SPEC.md Section 4 and Section 7."

---

## Step 3: Marketing Manager BRIEF (If Required)

If the project has public-facing pages:

Run the Marketing Manager BRIEF sequence (SOPs 1 + 2):

**SOP 1: Business Model Declaration**
Ask Founder: "Is the primary buyer an individual making a personal decision — or a professional making a business decision?"
→ Record B2B or B2C mode

**SOP 2: Customer Profiling**
Interview Founder to surface:
- Role and technical level of the user
- Pain Point (specific friction)
- Desired Gain (concrete outcome)
- Key Objection (biggest hesitation)
- Decision Trigger (why act now)

Write the Persona Record to MARKETING.md (or include in SPEC.md).

---

## Step 4: Product Architect Founder Interview

Run the Founder Interview across all 5 domains. Use `AskUserQuestion` — do not accept vague answers:

| Domain | Questions |
|--------|-----------|
| **Scope** | What is explicitly IN scope? What is explicitly OUT of scope? |
| **Users** | Who is the end user? (May already be answered by Marketing Manager) |
| **Tech constraints** | Required languages, frameworks, or existing systems? |
| **Non-functional** | Performance targets? HIPAA? CA Privacy? |
| **Done condition** | What does success look like? How will you know it's complete? |

**Success Matrix:** The interview is complete when you can write ≥ 3 testable acceptance criteria:
> A criterion is valid if a QA Tester can produce a clear PASS or FAIL without ambiguity.
> ✓ Valid: "User submits valid email + password → redirected to /dashboard in < 2 seconds."
> ✗ Invalid: "Login works."

If answers are still vague after one round, ask one focused follow-up per domain. Do not proceed until all 5 domains are resolved.

---

## Step 5: Write SPEC.md

Generate `[project-root]/SPEC.md` with all 7 required sections:

```
# SPEC: [Project Name]
Version: 1.0.0 | Created: [date] | Status: draft

## 1. Functional Requirements
- FR-01: [verb + noun + outcome]
- FR-02: ...
(minimum 3)

## 2. Non-Functional Requirements
- Performance: [target]
- Security: [requirements]
- Compliance: [HIPAA: yes/no | CA Privacy: yes/no]

## 3. Visual Description (for Front End Dev)
[Inform this section with the User Persona's technical level and Key Objection]
- Layout: [page structure]
- Components: [key UI components]
- Responsive: [breakpoints]
- Style notes: [colors, font, spacing]

## 4. Tech Stack
- Language(s): [TypeScript]
- Framework(s): [Next.js 14, Supabase, etc.]
- Existing systems: [from LIBRARY.md check]
- New dependencies: [list]

## 5. Out of Scope
- [explicit list of what will NOT be built this iteration]

## 6. Definition of Done (Success Matrix)
[At least one criterion must address the Key Objection from the User Persona]
- [ ] [Criterion 1 — testable, specific]
- [ ] [Criterion 2]
- [ ] [Criterion 3]
(Founder sign-off required)

## 7. Dependencies & Risks
- Depends on: [other systems, APIs, from LIBRARY.md]
- Risks: [known unknowns]
```

---

## Step 6: Founder Sign-Off

Present Section 6 (Definition of Done) to the Founder:

> "Here is the Definition of Done for [project name]. Please confirm these criteria before I hand off to development:
> [list criteria]
> Reply 'approved' to lock the spec."

Wait for explicit approval. Do not proceed to sprint planning without it.

---

## Step 7: Register and Hand Off

After approval:

1. Update SPEC.md status from `draft` to `approved`
2. Register in LIBRARY.md Table 7 (Project Registry) — generate UUID via `uuidgen | tr '[:upper:]' '[:lower:]'`:
   ```
   | [uuid] | [project name] | active | [spec_path] | [sprint_path — TBD] | [tech stack summary] | [date] | — |
   ```
3. Trigger Storyteller: `Storyteller: ON CREATE — [project name] SPEC.md`
4. Report:

```
Discovery complete — [project name]
SPEC.md: approved (v1.0.0)
Tech Stack: [summary]
Definition of Done: [N] criteria

Next step: Run `/sprint-plan` to decompose into Atomic Tasks.
```
