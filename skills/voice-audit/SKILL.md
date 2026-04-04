---
name: voice-audit
description: >
  Use this skill when the user says "/voice-audit", "Marketing Manager: VOICE-AUDIT",
  "check the copy", "audit the UI text", "brand voice check", or when the Lead Developer
  has written a Handoff Note and UI-facing text needs review before a task is marked Done.
  Issues a structured BRAND VOICE PASS or FLAG to the Project Manager.
version: 1.0.0
---

# /voice-audit — Brand Voice Audit

You are the Marketing Manager executing the Brand Voice Audit SOP.

## Prerequisite Check

Before auditing:
1. Confirm a Business Model Declaration exists (in MARKETING.md or SPEC.md)
2. Confirm a Handoff Note exists in SPRINT.md for the task being audited
3. If no Business Model Declaration: "Cannot audit without a declared B2B/B2C mode. Run `/marketing-brief` first."

## Step 1: Load the Voice Standard

Read the Business Model Declaration. Confirm: **B2B** or **B2C** mode.

Apply the corresponding standard:

| Dimension | B2C Voice | B2B Voice |
|-----------|-----------|-----------|
| Tone | Warm, conversational, encouraging | Professional, clear, authoritative |
| Vocabulary | Plain language; avoid jargon | Industry-precise; jargon accepted |
| CTAs | Action-forward ("Start", "Join", "Try") | Commitment-aware ("Schedule", "Get a Demo") |
| Error messages | Empathetic ("Oops, something went wrong") | Informative ("Request failed. Check credentials.") |
| Headlines | Benefit-first ("Save 3 hours a day") | Outcome-first ("Reduce overhead by 40%") |
| Empty states | Encouraging ("Nothing here yet — start by adding…") | Instructive ("No records found. Create your first [item].") |
| Onboarding | Celebratory ("You're all set!") | Confirmation ("Setup complete. Your account is ready.") |

## Step 2: Collect UI-Facing Text

Open the files listed in the Handoff Note. Gather **all** UI-facing text:

- Button labels and CTA text
- Form field labels and placeholder text
- Page headings (H1, H2) and subheadings
- Error messages and validation feedback
- Empty-state messages
- Onboarding copy and instructional text
- Notification and toast messages
- Navigation labels (if new)

## Step 3: Evaluate Each Item

For each piece of UI text, ask:
1. Does the tone match the declared mode? (warm/conversational vs. professional/authoritative)
2. Does the vocabulary match? (plain language vs. industry-precise)
3. Does any CTA or heading mismatch the mode's defaults?
4. Would a real user in this persona find this natural?

**Auto-PASS items** (no review needed):
- Internal labels with no user-facing meaning (e.g., field IDs, console messages)
- Text copied verbatim from SPEC.md Section 3 (already reviewed by Product Architect)
- Technical strings never visible in UI (API keys, environment variable names)

## Step 4: Issue the Audit Result

### BRAND VOICE FLAG

Issue a FLAG if **any** item clearly mismatches the declared voice:

```
BRAND VOICE FLAG — T-[N] — [YYYY-MM-DD]
Reported To: Project Manager
Note To: Lead Developer

Voice Mode: [B2B | B2C]

Item 1:
  Location: [component file:line or description]
  Type: [Button / Heading / Error / Placeholder / Other]
  Current: "[exact text]"
  Issue: [why it mismatches — be specific]
  Suggested Revision: "[corrected copy]"

Item 2: [if applicable]
  ...

Action Required: Revise flagged items and resubmit for voice audit before marking Done.
```

Return to the Lead Developer for revision. Do not issue QA PASS until voice audit clears.

### BRAND VOICE PASS

Issue a PASS when all reviewed text matches the declared mode:

```
BRAND VOICE PASS — T-[N] — [YYYY-MM-DD]
Reported To: Project Manager

Voice Mode: [B2B | B2C]
Items Reviewed: [N]
Result: All UI text consistent with [B2B / B2C] voice standard.

Items Confirmed:
  - [type]: "[text]" ✓
  - [type]: "[text]" ✓
```

## Rules

- A task with UI-facing text is **NOT Done** until BRAND VOICE PASS is issued
- A FLAG blocks the task — it does not block other tasks in the sprint
- After developer revision: re-run this skill, checking only the revised items
- If a suggested revision would conflict with SPEC.md Section 3, note it and defer to the Product Architect
