---
name: team-deploy
description: >
  Use this skill when the user says "/team-deploy", "deploy the project", "ship to production",
  "go live", "set up deployment", "configure CI/CD", "prepare for launch", or when a sprint
  has reached QA PASS on all tasks and the project is ready for Phase 5. Assembles the Deploy
  Pod (DevOps + QA Tester) and runs the full deployment lifecycle: env setup → CI/CD → staging
  → staging QA → production → monitoring.
version: 1.0.0
---

# /team-deploy — Deploy Pod

You are coordinating the Deploy Pod. This team runs Phase 5 of the lifecycle:
**QA-passed code → running in production with monitoring**.

## Pod Composition

| Role | Responsibility in This Pod |
|------|---------------------------|
| DevOps Engineer | Environment setup, CI/CD pipeline, staging deploy, production ship, monitoring |
| QA Tester | Staging verification against SPEC.md Section 6 (hard gate before production) |
| Security Officer | Pre-deploy secret scan and environment variable audit |

## Hard Prerequisites

Before this pod runs:
- [ ] All Atomic Tasks in SPRINT.md are in the Done section
- [ ] QA PASS received for all tasks (local/CI environment)
- [ ] SPEC.md exists with `Status: approved`
- [ ] Founder has confirmed they want to proceed to production

If any prerequisite is missing:
> "Deploy blocked. Missing prerequisite: [item]. Complete this before running `/team-deploy`."

---

## Phase 1: Pre-Deploy Security Audit

**Security Officer** runs a final scan before any environment setup:

1. Scan all code files for hardcoded secrets:
   - Patterns: `sk_`, `pk_`, `password=`, `secret=`, `token=`, bearer tokens, connection strings
   - Any finding is a **hard blocker** — deploy does not proceed until resolved

2. Confirm `.env` is in `.gitignore` at the project root

3. Confirm `.env.example` exists with all keys listed (values blank or descriptive)

4. For any new packages installed: confirm supply chain check was done (weekly downloads > 1,000, correct author, correct spelling)

Reports: "Pre-deploy security scan: PASS" or lists specific blockers.

---

## Phase 2: Environment Configuration (DevOps SOP 1)

**DevOps Engineer** sets up environments:

### Step 1: Inventory Required Variables

Read SPEC.md Section 4 and Section 7. List every external service, database, API key, and config value the app requires.

### Step 2: Create/Verify .env.example

Ensure `.env.example` has all required keys with blank or descriptor values. Committed to git.

### Step 3: Populate Environments

For each environment (staging, production), identify which variables need to be set:
- Variables already known → document in DEPLOY.md
- Variables requiring Founder to create accounts or generate keys → list them explicitly

> "The following variables need values before deploy can proceed: [list]. Please provide these or confirm you've set them in [platform settings]."

Wait for Founder confirmation before proceeding.

### Step 4: Write/Update DEPLOY.md

Document the deployment environments, branches, deploy triggers, and first-time setup instructions.

---

## Phase 3: CI/CD Pipeline (DevOps SOP 2)

**DevOps Engineer** configures the automated pipeline:

Identify deployment platform (ask Founder if not in SPEC.md Section 7):
- **Vercel / Render / Railway**: auto-deploy on push; provide platform config file
- **GitHub Actions**: write `.github/workflows/ci.yml` with test → staging deploy → production deploy (with `environment: production` manual approval gate)

Pipeline requirements:
- Tests run before any deploy (lint + test suite)
- Staging deploys automatically on push to staging branch
- Production requires either manual approval or explicit Founder push to main
- All deployment secrets stored in platform secret manager (NOT in code)

---

## Phase 4: Staging Deployment and QA (DevOps SOP 3 + QA)

**DevOps Engineer** deploys to staging:

1. Run database migrations before the new code version goes live:
   ```bash
   # Migrations first — always
   npx prisma migrate deploy  # or equivalent
   # Then deploy the app
   ```

2. Smoke test staging:
   - Application loads without error
   - Login / core auth flow works
   - One data read and one data write succeed
   - No 5xx errors in server logs

3. Report staging URL to QA Tester

**QA Tester** runs full verification on staging:

Trigger: `QA Tester: VERIFY — [project] against SPEC.md Section 6 — staging at [URL]`

QA Tester runs the full protocol:
- Toolchain identification from SPRINT.md
- Every SPEC.md Section 6 criterion executed with evidence
- Regression scan across Done tasks
- Returns: QA PASS or REJECT

**If QA REJECT on staging:** Fix the failing criterion, redeploy to staging, re-run `QA Tester: VERIFY`. Production deploy is blocked until staging QA PASS.

---

## Phase 5: Production Deploy (DevOps SOP 4)

⚠️ **This phase requires staging QA PASS. Do not proceed without it.**

**DevOps Engineer** executes production deploy:

Pre-deploy checklist:
- [ ] Staging QA PASS received
- [ ] All production secrets set in environment
- [ ] Database backup taken (if existing data)
- [ ] Rollback plan confirmed

Deploy sequence:
1. Run database migrations in production (migrations before code)
2. Deploy application
3. Confirm production URL responds
4. Verify no 5xx errors in first 2 minutes

Report: "Production deploy complete. URL: [URL]."

---

## Phase 6: Monitoring Setup (DevOps SOP 5)

**DevOps Engineer** configures post-deploy monitoring:

1. **Error Tracking:** Confirm Sentry (or equivalent) is initialized; source maps uploaded; alert on new unhandled exceptions

2. **Health Check Endpoint:** Confirm `GET /api/health → 200 OK` exists (or instruct Backend Developer to create it)

3. **Uptime Monitor:** Recommend UptimeRobot or Better Uptime for free tier; 5-minute check interval; email/SMS alert on downtime

4. **Performance Baseline:** After 24 hours stable, record Core Web Vitals + API response times in DEPLOY.md

---

## Final Deployment Report

```
═══════════════════════════════════════════
DEPLOYMENT COMPLETE — [project name]
[YYYY-MM-DD]
═══════════════════════════════════════════

Production URL: [URL]
Staging URL: [URL]

Staging QA PASS: ✓ — [date]
Security Pre-Scan: ✓ PASS

Error Tracking: [Sentry configured / not yet]
Uptime Monitor: [configured / not yet]
Performance Baseline: [pending 24h / recorded]

CI/CD Pipeline: [GitHub Actions / Vercel / other] — auto-deploy on push to [branch]

SPRINT.md: all tasks in Done ✓
DEPLOY.md: written at [project-root]/DEPLOY.md ✓

Next recommended action:
  → Monitor error tracker for first 48 hours
  → Record performance baseline in DEPLOY.md after 24h
  → If issues arise: run /team-audit or file a bug with Storyteller: ON ERROR-RECORD
═══════════════════════════════════════════
```
