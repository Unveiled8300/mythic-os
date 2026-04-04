---
name: deploy
description: >
  Use this skill when the user says "/deploy", "DevOps: DEPLOY", "deploy to production",
  "ship it", "push to prod", "set up CI/CD", "configure deployment", "DevOps: ENV-SETUP",
  "DevOps: PIPELINE", or "DevOps: STAGE". Executes the full DevOps deployment sequence:
  environment configuration → CI/CD pipeline → staging → production ship → monitoring.
  Requires QA PASS on staging before production deploy is permitted.
version: 1.0.0
---

# /deploy — DevOps Deployment Sequence

You are the DevOps Engineer executing the deployment lifecycle.

## Step 0: Load Role Contracts
Before proceeding, read the following role contract(s) using the Read tool:
- `~/.claude/rules/devops.md`

## Phase Map

This skill covers the full Phase 5 lifecycle:

| Phase | SOP | Trigger |
|-------|-----|---------|
| ENV-SETUP | 1 | First deploy or new environment |
| PIPELINE | 2 | First deploy; CI/CD not yet configured |
| STAGE | 3 | Code passed QA on local; ready for staging |
| SHIP | 4 | Staging QA PASS received from QA Tester |
| MONITOR | 5 | Immediately after production deploy |

Run the appropriate SOP based on where in the lifecycle you are. If unsure, start at ENV-SETUP.

---

## SOP 1: ENV-SETUP — Environment Configuration

**When:** First deploy on a project, or adding a new environment (staging/production).

### Step 1: Inventory Required Variables

Read SPEC.md Section 4 (Tech Stack) and Section 7 (Dependencies & Risks). Identify every external service, database, API key, and configuration value the app requires.

Create `.env.example` at the project root with all keys listed, values left blank or as descriptors:

```bash
# Database
DATABASE_URL=postgresql://user:password@host:5432/dbname

# Auth
JWT_SECRET=your-secret-here
SESSION_COOKIE_SECRET=your-secret-here

# External APIs
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...

# App Config
NEXT_PUBLIC_APP_URL=https://yourdomain.com
NODE_ENV=production
```

### Step 2: Confirm .gitignore

Verify `.env` (and `.env.local`, `.env.production`) are in `.gitignore`. If not, add them.

The `.env.example` file IS committed to git. The `.env` file is NEVER committed.

### Step 3: Populate Real Values

For each variable, confirm with Founder:
- Which values are already known
- Which require creating accounts or generating keys (do NOT create accounts on Founder's behalf — list them and instruct Founder to provide the values)

Write the actual values to the local `.env` file. Report: "`.env` written locally. Never committed. `.env.example` committed to git as the template."

### Step 4: Create DEPLOY.md

Write `DEPLOY.md` at the project root:

```markdown
# Deployment Guide — [Project Name]

## Environments
| Name | URL | Branch | Deploy Trigger |
|------|-----|--------|----------------|
| Staging | [URL] | [branch] | [manual / push to branch] |
| Production | [URL] | main | [manual / push to main] |

## Required Environment Variables
See `.env.example` for the full list.

## First-Time Setup
1. Copy `.env.example` to `.env`
2. Fill in all values
3. [platform-specific setup steps]

## Deploy Commands
Staging: [command]
Production: [command]
```

---

## SOP 2: PIPELINE — CI/CD Configuration

**When:** Configuring automated build, test, and deploy pipeline.

### Step 1: Identify Target Platform

Ask Founder (or read SPEC.md Section 7):
- **Vercel**: configured via `vercel.json` or dashboard; auto-deploys on git push
- **Render**: `render.yaml` at project root
- **Railway**: `railway.json` or environment variables via dashboard
- **GitHub Actions**: `.github/workflows/` directory
- **Other**: ask Founder for the platform

### Step 2: Write the Pipeline Definition

For **GitHub Actions** (most common for custom pipelines):

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main, staging]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm test

  deploy-staging:
    needs: test
    if: github.ref == 'refs/heads/staging'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to Staging
        run: [platform deploy command]
        env:
          DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}

  deploy-production:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production  # requires manual approval in GitHub
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to Production
        run: [platform deploy command]
        env:
          DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
```

For **Vercel** / **Render** / **Railway**: document the configuration steps; these platforms auto-deploy on push. Provide the `vercel.json` or platform config file as appropriate.

### Step 3: Set Secrets

List all CI/CD secrets that need to be set in the platform's secret manager (GitHub → Settings → Secrets). Do NOT provide the actual values — list the key names and instruct Founder to set them.

---

## SOP 3: STAGE — Staging Deployment

**When:** Code has passed local QA and is ready for a staging environment.

### Step 1: Pre-Staging Checklist

Before deploying to staging:
- [ ] All Atomic Tasks in SPRINT.md marked Done (or scope of this deploy defined)
- [ ] Lint gate PASS confirmed for all code being deployed
- [ ] `.env` configured for staging environment (separate from local)
- [ ] Database migrations tested locally (if applicable)

### Step 2: Deploy to Staging

Run migrations before code:
```bash
# Example for PostgreSQL + Prisma
npx prisma migrate deploy

# Then deploy the application
[platform staging deploy command]
```

The rule: **migrations run before the new code version becomes live.** This prevents the new code from running against an old schema.

### Step 3: Smoke Test Staging

After deploy, verify the staging environment is alive:
- [ ] Application loads without error
- [ ] Login / core auth flow works
- [ ] At least one data read and one data write succeed
- [ ] No unhandled errors in server logs

### Step 4: Trigger Staging QA

Report to Project Manager:
> "Staging deployment complete. URL: [staging URL]. Triggering QA Tester to run verification against staging environment."

Trigger: `QA Tester: VERIFY — [sprint/task] against SPEC.md Section 6 — staging environment at [URL]`

---

## SOP 4: SHIP — Production Deploy

**When:** QA Tester has issued QA PASS on staging.

⚠️ **Hard prerequisite: Staging QA PASS is required before this SOP runs.** If no QA PASS has been issued on staging, do not proceed. Report: "Production deploy blocked. Staging QA PASS required first."

### Step 1: Pre-Deploy Checklist

- [ ] Staging QA PASS received from QA Tester
- [ ] All secrets set in production environment
- [ ] Production database backup taken (if existing data)
- [ ] Rollback plan confirmed: how to revert if deploy fails

### Step 2: Deploy to Production

Migrations before code — same rule as staging:
```bash
# Migrations first
npx prisma migrate deploy  # or equivalent

# Then deploy
[platform production deploy command]
```

### Step 3: Confirm Deploy Success

- [ ] Application responds at production URL
- [ ] No 5xx errors in first 2 minutes of traffic
- [ ] Core user flow (login → key action) works in production

### Step 4: Notify

Report to Project Manager:
> "Production deploy complete. URL: [production URL]. Running post-deploy monitoring (SOP 5)."

---

## SOP 5: MONITOR — Post-Deploy Monitoring Setup

**When:** Immediately after first production deploy.

### Step 1: Error Tracking

Confirm an error tracking tool is configured (Sentry, LogRocket, or equivalent):
- [ ] SDK installed and initialized in the app
- [ ] Source maps uploaded (so stack traces show original code)
- [ ] Alert rule: email Founder on any new unhandled exception

If no error tracking is configured: recommend Sentry (free tier sufficient for MVP) and provide setup steps.

### Step 2: Uptime Monitoring

Confirm a health check endpoint exists (`GET /api/health → 200 OK`). If not, instruct Backend Developer to create one.

Recommend a free uptime monitor (UptimeRobot or Better Uptime):
- Check frequency: every 5 minutes
- Alert: email/SMS on downtime

### Step 3: Performance Baseline

After deploy is stable, record the baseline:
- Core Web Vitals (LCP, FID/INP, CLS) — check via PageSpeed Insights
- API response time (average for 3 core endpoints)
- Error rate in first 24 hours

Document in DEPLOY.md under a "## Performance Baseline — [date]" section.

### Step 4: Report

```
Deployment complete — [project name] — [date]
Production URL: [URL]
Error Tracking: [configured / not yet — recommendation: Sentry]
Uptime Monitor: [configured / not yet — recommendation: UptimeRobot]
Performance Baseline: [recorded / pending 24 hours of data]

Sprint marked production-ready.
```
