---
name: git-audit
description: >
  Periodic git audit and cleanup. Verifies .gitignore compliance, checks for
  accidentally-committed secrets, syncs with origin (multi-machine support),
  and reports branch health. Run weekly or before major architecture work.
version: 1.0.0
slash_command: /git-audit
trigger_pattern: "Vendor Manager: GIT-AUDIT|git audit|weekly cleanup|sync machines"
---

# Skill: Git Audit

Periodic governance maintenance: verify `.gitignore` compliance, detect leaks, sync cross-machine, and report branch health.

---

## SOP 1: Fetch Latest From Origin (Cross-Machine Sync)

Ensure you have the latest governance state from other machines:

```bash
git fetch origin
```

Report:
- ✅ if fetch succeeds: "Fetched latest from origin"
- ❌ if fetch fails: "Remote unreachable. Check your internet connection."

Compare local vs. remote:
```bash
git status
```

- If ahead of origin: ask "Commit and push these changes? (yes/no)"
  - If yes: trigger git-sync
  - If no: continue audit
- If behind origin: `git pull origin main`
  - Report: "Updated local branch to match origin"
- If diverged: ⚠️ warn "Local and remote history differ. Requires manual merge conflict resolution. Contact Founder."

---

## SOP 2: Verify `.gitignore` Compliance

Check if any sensitive files would be caught by `.gitignore`:

```bash
# Test: would .env files be ignored?
git check-ignore -v .env .env.local .env.*.local
```

Expected output: all `.env*` files listed as ignored

If `.env` files are NOT ignored: ❌ **CRITICAL** — update `.gitignore` immediately:
```bash
cat >> .gitignore << EOF
.env
.env.*
!.env.example
EOF
```

Then run `git add .gitignore` and stage for next sync.

Check other sensitive patterns:
```bash
git check-ignore -v *.pem *.key *.p12 secrets/ credentials/
```

All should be ignored. If any are NOT: update `.gitignore` and flag to user.

---

## SOP 3: Scan Git History for Leaked Secrets

Search the entire commit history for common secret patterns:

```bash
git log --all --pretty='%h %s' | grep -iE '\.env|password|secret|api.?key|token|credentials'
```

If results appear: ⚠️ **ALERT** — potential secret leak detected

For each suspected leak:
```bash
git show [COMMIT_HASH] | grep -iE 'password|secret|key|token'
```

If confirmed leak:
```
❌ SECURITY ALERT: Suspected secret in commit [COMMIT_HASH]
Description: [what looks like a secret]
Action Required: Forensic review recommended. Contact Founder.
```

Recommend to user: "Run `git log -p | grep -iE [pattern]` to review suspected commits"

---

## SOP 4: Check Branch Health

Report status of local branches:

```bash
git branch -v --list
```

Identify stale branches (not updated in 30+ days):

```bash
git branch -v | awk '{
  cmd = "git log -1 --format=\"%ci\" " $1
  cmd | getline date
  close(cmd)
  split(date, d, "-")
  # Simple day-of-year calc (not exact, but close)
  print $0, date
}'
```

For each local branch:
- If on `main` and recent: ✅ "main branch is current"
- If on `main` and stale: ⚠️ "main branch not updated in [N] days. Run git pull origin main?"
- If on other branch and stale: 🗑️ "Stale branch [name]. Consider deleting: git branch -d [name]"
- If on other branch and recent: ✅ "Active branch [name]"

---

## SOP 5: Report Full Audit Status

Generate comprehensive audit report:

```
═══════════════════════════════════════════════════════════════════════════
                         GIT AUDIT REPORT
                         [2026-03-14 12:34 UTC]
═══════════════════════════════════════════════════════════════════════════

CROSS-MACHINE SYNC
  Status: ✅ Synced with origin
  Last fetch: [timestamp]
  Local branch: main
  Remote branch: main
  Commits ahead: 0
  Commits behind: 0

.GITIGNORE COMPLIANCE
  Status: ✅ All sensitive patterns protected
  Tested patterns:
    ✅ .env* files excluded
    ✅ *.pem, *.key files excluded
    ✅ secrets/ directory excluded
    ✅ credentials/ directory excluded

SECRET LEAK DETECTION
  Status: ✅ No suspected leaks in history
  Scanned: [N] commits
  Patterns checked: password, secret, api_key, token, credentials

BRANCH HEALTH
  Current branch: main ✅ (updated [N] days ago)
  Local branches: [N] total
    - main (updated [N] days ago)
    - [other branches if any, with recency status]
  Stale branches: [N] (older than 30 days)

═══════════════════════════════════════════════════════════════════════════
                              SUMMARY
═══════════════════════════════════════════════════════════════════════════

OVERALL STATUS: ✅ CLEAN
  - Governance state synced across machines
  - No secrets detected in history
  - .gitignore properly configured
  - Branch health: good

ACTIONS TAKEN THIS AUDIT:
  - git fetch origin
  - Verified .gitignore compliance
  - Scanned commit history for secrets
  - Checked branch health

RECOMMENDED NEXT ACTIONS:
  - None (all systems nominal)
  [or if issues found:]
  - Update .gitignore: [items]
  - Review suspected leaks: [commits]
  - Delete stale branches: [branch names]

═══════════════════════════════════════════════════════════════════════════
```

---

## Usage Patterns

### Pattern A: Weekly Maintenance
```
Every Monday morning:
/git-audit
  → Syncs from other machines
  → Verifies no secrets leaked
  → Reports branch health
  → Flags any issues for action
```

### Pattern B: Before Major Refactor
```
[Plan to restructure LIBRARY.md or rules/]

/git-audit
  → Ensure clean state before major changes
  → Verify no outstanding merges or conflicts
  → Confirm synced with all machines

[Proceed with refactor]
```

### Pattern C: Post-Secret Incident
```
[Discover that .env was almost committed]

/git-audit
  → Scan entire history to confirm no .env exists
  → Verify .gitignore is correctly configured
  → Report: "No secrets in git history. Safe to continue."
```

---

## Verification Checklist

- [ ] `git fetch origin` succeeded (cross-machine sync working)
- [ ] Local branch status is current (not stale)
- [ ] `.gitignore` includes `.env*`, `*.pem`, `*.key`, `secrets/`, `credentials/`
- [ ] Git history scan shows no password/secret/token strings
- [ ] All local branches are either current or flagged as stale
- [ ] Audit report generated and reviewed
- [ ] Any issues from this audit noted in SPRINT.md or flagged for Founder

---

## Integration with Other Skills

**After git-sync:**
- Run /git-audit to verify that nothing sensitive was accidentally committed

**Before /git-tag:**
- Run /git-audit to ensure clean state before creating a milestone tag

**After git-tag:**
- Run /git-audit to confirm tag is clean and pushed correctly
