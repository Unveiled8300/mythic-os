# PRD: [Project Name]
**Date:** [YYYY-MM-DD]
**Type:** [web app / portfolio site / CLI / automation tool / mobile]
**Priority:** [Phase 1 / Phase 2 / Phase 3]

> Fill out this document and run `/prd-ingest [path]` to generate SPEC.md + SPRINT.md automatically.
> Leave any section blank if you don't know — Claude will ask up to 5 focused questions to fill gaps.
> The more you fill in, the fewer questions you'll be asked.

---

## What It Does
*2-3 sentences describing the product. What does it do? Why does it exist?*

[Write here]

---

## Who Uses It

**Primary user:**
*Who is this person? Their role, life context, or job title.*

[Write here]

**Their technical level:** [novice / intermediate / expert]

**The problem they have today:**
*What frustration, gap, or failure are they experiencing that this product solves?*

[Write here]

**What success looks like for them:**
*What can they do / feel / achieve after using this that they couldn't before?*

[Write here]

**Why they might not use it:**
*What's the most likely hesitation or objection? (price, trust, complexity, habit?)*

[Write here]

---

## Scope

**What's IN (Version 1 only — be ruthless):**
- [ ] [Feature or capability 1]
- [ ] [Feature or capability 2]
- [ ] [Feature or capability 3]

**What's OUT (explicitly excluded from v1):**
- [Not building: X]
- [Not building: Y]

---

## Tech Preferences
*Leave blank to let CTO decide. Fill in only if you have strong preferences or constraints.*

**Stack:** [e.g., "must use Supabase", "prefer no backend", "needs Python"]
**Hosting:** [e.g., "Vercel", "doesn't matter", "must be free tier"]
**Integrations:** [e.g., "connects to QuickBase", "uses Zapier", "pulls from Google Sheets"]

---

## Done When
*Write 3-5 conditions that must be true for this to be "complete."
Each condition must be testable — someone should be able to say PASS or FAIL clearly.*

- [ ] [Testable condition 1 — e.g., "User can submit contact form and receives email confirmation"]
- [ ] [Testable condition 2 — e.g., "Gallery loads 20 images in under 2 seconds on mobile"]
- [ ] [Testable condition 3]
- [ ] [Testable condition 4 — optional]
- [ ] [Testable condition 5 — optional]

---

## Context & Notes
*Anything else Claude should know. Background, inspirations, examples of similar products, constraints, deadlines, business model, monetization, or dependencies.*

[Write here]

---

## After Submitting

Run: `/prd-ingest [path-to-this-file]`

Claude will:
1. Parse this PRD against the 5 interview domains
2. Ask up to 5 questions if gaps exist (skip if complete)
3. Generate a full SPEC.md for your review
4. On approval → generate SPRINT.md with Atomic Tasks
5. On approval → begin implementation

**Your total involvement:** 2 approvals + up to 5 answers.
