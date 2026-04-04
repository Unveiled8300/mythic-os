# Deployment Runbook: Production Release

**When to Use This**
Every time code is ready to ship to production after staging QA passes.

**Who Should Know This**
- DevOps Engineer: executes the runbook
- Lead Developer: approves the code
- Engineering Lead: monitors for issues during and 30 minutes after deploy

---

## Definition of Done
- [ ] All staging QA tests pass
- [ ] Code reviewed and approved by Lead Developer
- [ ] Smoke tests pass on production (after deploy)
- [ ] Monitoring dashboards show normal metrics
- [ ] Team notified of successful deploy
- [ ] Rollback plan documented and ready

---

## Prerequisites

| Prerequisite | Status | Notes |
|--------------|--------|-------|
| Staging QA PASS | Required | Must have QA sign-off before proceeding |
| Access to production database | Required | Verify AWS/Railway/Vercel access is active |
| Rollback plan confirmed | Required | Have rollback command ready before starting |
| Database backups current | Required | Last backup < 1 hour old |
| On-call engineer available | Required | 30 min after deploy for incident response |

---

## The Runbook

### Step 1: Pre-Deploy Checklist (5 minutes)

Run this command to verify readiness:
```bash
# Check staging QA status
cat SPRINT.md | grep "QA PASS"
```

Expected output: Should see `QA PASS — T-[N]` for all completed tasks.

If missing: **STOP**. Ask: "Is QA verification actually complete?" Do not proceed until QA signs off.

### Step 2: Tag the Release (2 minutes)

```bash
git tag -a v1.2.0 -m "Release: [feature summary]"
git push origin v1.2.0
```

Expected output: Tag appears on GitHub under "Releases"

### Step 3: Deploy to Production (10 minutes)

**Choose your platform:**

**For Vercel:**
```bash
vercel --prod
```

**For Railway:**
```bash
railway up --environment production
```

**For AWS/Custom:**
```bash
# Run your deployment script
./deploy.sh production
```

Expected output:
```
Deployment successful ✓
URL: https://your-app.com
Deployment ID: abc123def456
```

If deployment fails: See "When Things Go Wrong" section below.

### Step 4: Run Smoke Tests (5 minutes)

After deployment completes, immediately verify critical paths:

```bash
# Test 1: App loads
curl -I https://your-app.com
# Expected: 200 OK

# Test 2: API health check
curl https://your-app.com/api/health
# Expected: {"status": "ok"}

# Test 3: Authentication flow (manual)
# Visit https://your-app.com
# Try logging in with test account
# Expected: Login succeeds, redirects to dashboard
```

All three tests must pass. If any fails → Execute rollback immediately.

### Step 5: Monitor for 30 Minutes (30 minutes)

Watch these dashboards:

1. **Error Tracking** (Sentry/LogRocket)
   - Expected: 0 new errors
   - If error rate spikes: Execute rollback

2. **Uptime Monitor** (UptimeRobot/Better Uptime)
   - Expected: All checks passing
   - If any down alerts: Investigate immediately

3. **Performance** (Lighthouse/Web Vitals)
   - Expected: Load time < 3 seconds
   - If > 3 seconds: Investigate before accepting

### Step 6: Notify Team (2 minutes)

Send message to #deployments Slack channel:

```
🚀 Production Deployment Successful
Release: v1.2.0 ([feature summary])
Deployed by: [your name]
Smoke tests: PASS ✓
Monitoring: ACTIVE ✓

Status page: [link]
Rollback command (if needed): [command]
```

---

## Verify Completion

After all steps:
- [ ] App is live and responding at production URL
- [ ] Smoke tests all passed
- [ ] No new errors in error tracking dashboard
- [ ] Team notified in Slack
- [ ] You are ready to stay on alert for 30 minutes

---

## When Things Go Wrong

| Error / Symptom | Cause | Fix |
|-----------------|-------|-----|
| `Connection refused` | Network issue or deployment incomplete | Wait 2 minutes for DNS to propagate. Try again. If persists after 5 min, execute rollback. |
| `502 Bad Gateway` | Application crashed or database unreachable | Check error logs. Database connection string correct? Execute rollback if unsure. |
| Smoke test returns 500 | Code error in production | Check error tracking dashboard. Fix the bug → redeploy OR execute rollback. |
| High error rate (>1% of requests) | Unexpected behavior in production | Execute rollback immediately. Investigate in staging first. |
| Page load > 5 seconds | Database slow or missing index | Check database performance. If query slow, revert + optimize → redeploy. |

### Rollback Procedure (If Anything Fails)

Execute this immediately if smoke tests fail or error rates spike:

```bash
# Revert to previous version
git revert HEAD --no-edit
git push origin main

# Redeploy previous version
vercel --prod  # or your deploy command
```

Then:
1. Confirm rollback succeeded (smoke tests again)
2. Notify team: "Rollback executed — investigating"
3. Document the failure in error-records/
4. Do NOT attempt second deploy until root cause is found

---

## Expected Timeline

| Phase | Time |
|-------|------|
| Pre-deploy checklist | 5 min |
| Tag release | 2 min |
| Deploy | 10 min |
| Smoke tests | 5 min |
| Monitoring period | 30 min |
| Team notification | 2 min |
| **Total** | **54 min** |

---

## Related Docs
- `DEPLOY.md` — Deployment runbook for this project
- `error-records/` — Past deployment failures and lessons learned

---

*Last Updated: 2026-03-13 | Tested By: DevOps Team | Next Review: 2026-04-13*
