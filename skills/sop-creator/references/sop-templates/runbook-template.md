# [Runbook Title]

> A runbook is step-by-step instructions for performing a specific task. Use this for deployment, incident response, emergency procedures, or any task that must be executed the same way every time.

**When to Use This**
[1–2 sentences describing when this runbook should be invoked]

**Who Should Know This**
- Role 1: [reason]
- Role 2: [reason]

---

## Definition of Done
- [ ] Verified step 1 completed successfully
- [ ] Verified step 2 completed successfully
- [ ] [Any post-execution verification step]
- [ ] [Documented any unexpected behavior]

---

## Prerequisites

| Prerequisite | Status | Notes |
|--------------|--------|-------|
| [Tool/Access/System] | Required | [Details] |
| [Environment variable] | Required | [How to set it] |
| [Permission/Credential] | Required | [Where to get it] |

---

## The Runbook

### Step 1: [Specific Action]
[Exact command or detailed instruction]
- Expected output: [what you should see]
- If error: [specific troubleshooting]

**Example:**
```bash
# Command here
command --flag value
```

### Step 2: [Next Specific Action]
[Exact command or detailed instruction]
- Expected output: [what you should see]
- Time to complete: [X minutes]

### Step 3: [Verification Step]
[How to confirm the previous step worked]

---

## Verify Completion

After completing all steps, verify these conditions:
- [ ] [Verification check 1] — [how to check]
- [ ] [Verification check 2] — [how to check]
- [ ] Logs show: [specific log pattern]

---

## When Things Go Wrong

| Error / Symptom | Cause | Fix |
|-----------------|-------|-----|
| `[Error message]` | [Root cause] | 1. [Step 1] 2. [Step 2] → Retry from Step [N] |
| [Symptom: service won't start] | [Likely cause] | Check [log file]. If [condition], then [fix]. |

---

## Rollback Procedure

If something goes wrong, execute the rollback **immediately**:

1. [Stop the operation]
2. [Revert state]
3. [Verify rollback]
4. Log incident: [where]

---

## Duration
- Typical time to complete: [X minutes]
- Estimated time if rollback needed: [Y minutes]

---

## Related Runbooks
- [Link to related runbook]
- [Link to related runbook]

---

*Last Updated: [date] | Tested By: [name] | Next Review: [date]*
