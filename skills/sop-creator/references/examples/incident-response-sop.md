# Incident Response SOP: Production Outage

**When to Use This**
When production is down, users are impacted, or a critical error is occurring.

**Who Should Know This**
- On-call engineer: responds and executes
- Engineering lead: approves escalations
- Manager: communicates status to stakeholders

---

## Definition of Done
- [ ] Incident severity classified (P1/P2/P3)
- [ ] Incident logged with timestamp
- [ ] Root cause identified
- [ ] Service restored or workaround deployed
- [ ] Team notified of resolution
- [ ] Error record filed
- [ ] Post-incident review scheduled (P1/P2 only)

---

## Incident Severity Classification

| Severity | Definition | Response Time | Escalation |
|----------|-----------|---|-------------|
| **P1 — Critical** | Service down, data loss risk, security breach | **Immediate** | CEO + Engineering Lead |
| **P2 — High** | Core feature broken, significant degradation | < 1 hour | Engineering Lead |
| **P3 — Low** | Minor bug, cosmetic issue | Next business day | Team lead |

---

## Immediate Actions (First 2 Minutes)

### 1. Acknowledge & Classify
```
Incident detected: [what is broken]
Severity: [P1 / P2 / P3]
Start time: [timestamp]
Impact: [how many users, what's broken]
```

**For P1/P2:** Skip to Step 3 immediately.
**For P3:** Log and handle in standard sprint flow.

### 2. Gather Info (30 seconds)
- Is the service completely down or partially degraded?
- Did this just start or was it broken for a while?
- Can you reproduce it?

### 3. Notify Stakeholders (Immediately for P1/P2)

Send to **#incidents** Slack channel:
```
🚨 P[1/2] Incident — [Title]
Status: INVESTIGATING
Started: [time]
Impact: [description]
```

---

## Diagnosis (5–15 minutes)

### Check These in Order

**1. Status Dashboard**
```bash
# Check uptime monitor
curl https://uptime.example.com/status
# Check error tracking
# Visit: https://sentry.example.com/issues
```

**2. Server Status**
```bash
# AWS / Railway / Vercel status check
# e.g., for AWS: aws ec2 describe-instances --region us-east-1

# Verify database is responding
# Database connection test (check logs)
```

**3. Recent Changes**
```bash
# What deployed in the last hour?
git log --oneline -5

# Was there a recent deploy?
# Check DEPLOY.md for what went out
```

**4. Logs**
```bash
# Check application error logs
tail -100 /var/log/app.log  # or equivalent for your system

# Look for patterns:
#   - Database connection failures
#   - Memory/CPU spikes
#   - Auth errors
#   - Dependency timeouts
```

---

## Resolution Paths

### Path A: Recent Deploy Caused It → ROLLBACK

If the incident started right after a deploy:

```bash
# Immediately execute rollback
git revert HEAD --no-edit
git push origin main
vercel --prod  # or your deploy command

# Verify rollback succeeded
# Run smoke tests again
curl https://your-app.com/api/health
```

**Time limit:** If you're not certain in 5 minutes, rollback anyway. Investigate later.

### Path B: Database Issue → Scale or Restart

If error tracking shows database timeouts:

```bash
# Check database connection pool
# (varies by platform)

# Option 1: Restart the application
vercel --prod --force-rebuild

# Option 2: Scale up database
# (Platform-specific — AWS RDS scale, Railway upgrade, etc.)
```

### Path C: Third-Party Dependency Down → Notify Users

If error tracking shows calls to external service failing:

```bash
# Verify the dependency status
# e.g., for AWS: https://status.aws.amazon.com
# e.g., for payment service: check their status page

# If dependency is down:
# 1. Update status page: "We're experiencing issues due to [service] outage"
# 2. Implement feature flag to gracefully degrade (if time allows)
# 3. Wait for dependency to recover OR escalate
```

---

## Communication During Incident

### Update Every 10 Minutes

Post to **#incidents** channel:

```
P[1/2] Update — [Title]
Status: INVESTIGATING / DIAGNOSING / RESOLVING
Current finding: [what we know]
ETA to fix: [best estimate]
```

### When Resolved

```
🟢 RESOLVED — [Title]
Resolved at: [time]
Root cause: [brief explanation]
Action taken: [rollback / restart / scale-up / fix]
Error record: [link]
Post-incident review: [date/time]
```

---

## When Things Go Wrong

| Scenario | Action |
|----------|--------|
| Rollback fails | Alert Engineering Lead immediately. Escalate to CTO. |
| Root cause unknown after 15 min (P1) | Escalate to Engineering Lead + call for extra hands. |
| Service still down after 30 min (P1) | Declare disaster, consider failover or manual workaround. |

---

## Post-Incident Actions (P1/P2 Only)

### Immediately After Resolution

1. **File an error-record:**
   ```
   Storyteller: ON ERROR-RECORD — [incident title]
   Root cause: [why did this happen]
   Prevention: [what can we do to prevent next time]
   ```

2. **Schedule post-mortem**
   - When: Within 24 hours
   - Who: Engineering team + stakeholders
   - Duration: 30 minutes
   - Agenda: What happened, why, how to prevent, action items

3. **Update playbooks** (if this is a pattern)
   - Example: "If database timeouts spike, immediately restart app before investigating logs"

---

## On-Call Resources

| Resource | Location | Purpose |
|----------|----------|---------|
| Runbook | `DEPLOY.md` | Step-by-step for normal operations |
| Error tracking | `https://sentry.example.com` | Real-time error log |
| Status page | `https://status.example.com` | User-facing incident status |
| On-call schedule | [link] | Who to escalate to |
| Escalation contacts | [link] | CEO, CTO, Engineering Lead phone numbers |

---

## Templates

### Incident Reporting Template

```
Incident Report: [Title]
Severity: P[1/2/3]
Detected: [time]
Resolved: [time]
Duration: [X minutes]

What users experienced:
[Impact description]

Root cause:
[Technical explanation]

How we fixed it:
[Resolution steps]

How we prevent this next time:
[Preventive measures]
```

---

*Last Updated: 2026-03-13 | Owned By: On-Call Rotation | Review: Quarterly*
