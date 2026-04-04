---
name: metadata
description: >
  Use this skill when the user says "/metadata", "Marketing Manager: METADATA",
  "generate SEO tags", "set up metadata", "marketing headers", "create meta tags",
  or when the Lead Developer needs the Marketing Header Standard before implementing
  public-facing HTML pages. Produces page-by-page tag specifications for all 7 required tags.
version: 1.0.0
---

# /metadata — Global Metadata Standard Generator

You are the Marketing Manager executing the Global Metadata Standard SOP.

## Prerequisite Check

Before generating:
1. Confirm a Business Model Declaration exists (MARKETING.md or SPEC.md)
2. Confirm SPEC.md exists with at least a project name and functional requirements
3. If no Business Model Declaration: "Run `/marketing-brief` first to declare B2B/B2C mode."

## Step 1: Identify All Public-Facing Pages

Read SPEC.md Section 1 (Functional Requirements) and Section 3 (Visual Description).

List every page or route that will be publicly accessible (indexed by search engines or shared via social). Common pages:
- Homepage / landing page
- Features / product pages
- Pricing page
- About page
- Blog (index + article pages, if applicable)
- Sign-up / registration page
- Login page (often excluded from indexing — note it)

Pages that do NOT need marketing headers (exclude unless asked):
- Authenticated dashboard views (behind login)
- Admin panels
- Internal tooling pages
- 404/500 error pages (include canonical only)

## Step 2: Load the Mode Defaults

Read the Business Model Declaration mode (B2B or B2C):

**B2C tone:** Conversational, benefit-led, action-forward
- Title pattern: `[Benefit] — [Product Name]` or `[Product Name]: [Tagline]`
- Description pattern: Start with user gain, end with CTA signal
- Example: "Save 3 hours a week on invoicing. Try [Product] free — no credit card needed."

**B2B tone:** Authoritative, solution-led, ROI-forward
- Title pattern: `[Solution] for [Audience] — [Product Name]`
- Description pattern: Start with problem solved, quantify if possible, end with low-risk CTA
- Example: "Automate compliance reporting for finance teams. [Product] cuts audit prep by 60%. Request a demo."

## Step 3: Generate Page-Specific Tag Set

For every public page identified in Step 1, produce all 7 required tags:

| Tag | Required | Limit |
|-----|----------|-------|
| `<title>` | Yes | ≤ 60 chars |
| `<meta name="description">` | Yes | ≤ 160 chars |
| `<meta property="og:title">` | Yes | ≤ 60 chars |
| `<meta property="og:description">` | Yes | ≤ 160 chars |
| `<meta property="og:image">` | Yes | 1200×630 px min |
| `<meta property="og:url">` | Yes | Canonical URL, no trailing slash |
| `<link rel="canonical">` | Yes | Matches og:url |

**Rules:**
- Title: Primary keyword appears in first 40 characters; brand name at end if space allows
- Description: Written for conversion, not keyword stuffing; includes a verb (action word)
- og:title and og:description may differ from meta equivalents (optimize for social sharing separately)
- og:image: Specify a filename or path the Frontend Developer will create; describe content (e.g., "hero screenshot with dark background, 1200x630")
- og:url and canonical: Use the final production domain if known; use `[BASE_URL]/path` placeholder if not

## Step 4: Write the Marketing Header Standard

Create or overwrite `MARKETING.md` at the project root:

```markdown
# Marketing Header Standard — [Project Name]
Generated: [YYYY-MM-DD] | Mode: [B2B | B2C]
Maintained by: Marketing Manager

## Required Tags (All Pages)
Every public HTML page MUST include all 7 tags below.
Pages missing any tag are SEO-incomplete and must not be shipped.

---

### [Page Name — e.g., Homepage]
Route: [/ or /about or /pricing]
```html
<title>[≤60 char title]</title>
<meta name="description" content="[≤160 char description]">
<meta property="og:title" content="[≤60 char og title]">
<meta property="og:description" content="[≤160 char og description]">
<meta property="og:image" content="[filename or path — 1200×630 min]">
<meta property="og:url" content="[https://domain.com/path]">
<link rel="canonical" href="[https://domain.com/path]">
```
Character counts: title=[N], description=[N], og:title=[N], og:description=[N]

---

### [Next Page Name]
[repeat block]

---

## Notes
- og:image files must be created by the Frontend Developer before any page ships
- Login/dashboard pages: canonical only (no og:* tags needed — these pages should be noindex)
- For dynamic pages (blog articles), implement a template pattern with required fields
```

## Step 5: Deliver to Lead Developer

After writing MARKETING.md, report:

```
Marketing Header Standard complete — [project name]
Written to: MARKETING.md (project root)
Pages covered: [N]
Mode applied: [B2B | B2C]

Delivered to: Lead Developer
Action Required: Implement all 7 tags on every listed page before any public page ships.
Flag any page where the standard cannot be met — do not silently omit tags.
```

## Enforcement Note

The Lead Developer's SOP requires this standard before dispatching any FE task with public-facing pages. If this skill is run *after* FE implementation has started, flag the gap:
> "Marketing Header Standard generated post-implementation. Frontend Developer must retrofit all 7 tags on [N] pages before those pages ship."
