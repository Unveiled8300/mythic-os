---
name: role-audit
description: >
  Use this skill when the user says "/role-audit", "which roles are useful",
  "audit the roles", "trim roles", "which fragments get loaded", or when /boot
  surfaces the "ROLE AUDIT DATA READY" notice. Analyzes fragment usage data to
  determine which roles and context fragments earn their token cost vs dead weight.
  Produces a keep/trim/kill recommendation table.
version: 1.0.0
---

# /role-audit — Data-Driven Role & Fragment Evaluation

You are analyzing real usage data to determine which parts of the governance
system are earning their token cost. This is not opinion-based — it is measured.

## Step 1: Read the Usage Data

Read `~/.claude/brain/log/fragment-usage.jsonl`. Each line is:
```json
{"timestamp": "2026-04-04T12:00:00", "fragments": ["implementation", "security"]}
```

Parse all entries. Build:
1. **Fragment frequency table** — how many times each fragment was loaded
2. **Session count** — total unique timestamps (approximate sessions)
3. **Co-occurrence matrix** — which fragments load together (reveals natural clusters)

## Step 2: Read Fragment Cost Data

Read `~/.claude/hooks/context-loader/fragments.json`. For each fragment, extract:
- `name` (or `phase`)
- `token_estimate` — the cost per load
- `priority` — how aggressively it loads (1 = high, 3 = low)
- `keywords` — what triggers it

## Step 3: Calculate ROI Score

For each fragment, compute:

```
Load Rate   = times_loaded / total_sessions × 100
Token Cost  = token_estimate (from fragments.json)
ROI Score   = Load Rate / Token Cost × 1000
```

High ROI = loaded frequently, low cost (earning its keep).
Low ROI = loaded rarely, high cost (dead weight).

## Step 4: Cross-Reference with Role Contracts

Map fragments to the roles they represent:
- `discovery` → Product Architect, Marketing Manager
- `planning` → Project Manager
- `implementation` → Lead Developer, Frontend Dev, Backend Dev
- `verification` → QA Tester
- `deployment` → DevOps Engineer
- `governance` → Storyteller
- `security` → Security Officer
- `taste` → Quality standards (no specific role)
- `marketing` → Marketing Manager
- `brain-patterns` → Institutional learning (no specific role)

A role that maps to a low-ROI fragment is a candidate for trimming.
A role that maps to a high-ROI fragment is earning its keep.

## Step 5: Produce the Audit Report

```
═══════════════════════════════════════════
ROLE AUDIT REPORT — [YYYY-MM-DD]
Data: [N] entries across [M] approximate sessions
═══════════════════════════════════════════

FRAGMENT USAGE RANKING:

| Rank | Fragment | Loads | Load Rate | Token Cost | ROI Score | Verdict |
|------|----------|-------|-----------|------------|-----------|---------|
| 1 | [name] | [N] | [X]% | [N] tokens | [score] | KEEP |
| 2 | [name] | [N] | [X]% | [N] tokens | [score] | KEEP |
| ... | ... | ... | ... | ... | ... | ... |
| N | [name] | [N] | [X]% | [N] tokens | [score] | TRIM/KILL |

VERDICT KEY:
  KEEP  — Load Rate ≥ 30% OR ROI Score ≥ 5.0
  TRIM  — Load Rate 10-30% — consider reducing token_estimate or merging with another fragment
  KILL  — Load Rate < 10% AND ROI Score < 2.0 — remove or make load-on-explicit-request only

ROLE IMPACT:

| Role | Mapped Fragment | Fragment Verdict | Role Recommendation |
|------|----------------|-----------------|---------------------|
| Security Officer | security | [verdict] | [recommendation] |
| Product Architect | discovery | [verdict] | [recommendation] |
| Project Manager | planning | [verdict] | [recommendation] |
| Lead Developer | implementation | [verdict] | [recommendation] |
| QA Tester | verification | [verdict] | [recommendation] |
| DevOps Engineer | deployment | [verdict] | [recommendation] |
| Storyteller | governance | [verdict] | [recommendation] |
| Marketing Manager | marketing | [verdict] | [recommendation] |
| Quality Standards | taste | [verdict] | [recommendation] |

CO-OCCURRENCE CLUSTERS:
[Which fragments always load together — candidates for merging into one fragment]

CONCRETE RECOMMENDATIONS:
1. [Specific action: "Remove marketing fragment — loaded 2% of sessions, 450 tokens each time"]
2. [Specific action: "Merge taste into implementation — they co-occur 90% of the time"]
3. [...]

═══════════════════════════════════════════
```

## Step 6: Offer to Execute

For each KILL or TRIM recommendation, ask:
"Shall I execute these changes? I'll update fragments.json and optionally archive the trimmed role contracts."

Wait for Founder approval on each change before executing.

For approved changes:
1. Update `~/.claude/hooks/context-loader/fragments.json` (remove entries, adjust token_estimates, merge keywords)
2. If a role is killed: move its contract from `rules/` to `rules/archived/` (don't delete — preserve for potential rollback)
3. Write a decision record to `~/.claude/brain/log/decisions/[date]-role-audit.md` documenting what was changed and why

## Step 7: Self-Iterate Checkpoint

After executing changes, note:
```
Role audit complete. Changes will take effect next session.
After 2-3 more builds, run /role-audit again to measure impact.
The fragment-usage.jsonl log continues collecting data automatically.
```

## Rules

- Never recommend killing the `security` fragment — it is force-emitted and non-negotiable
- Never recommend killing `brain-patterns` — the learning system needs time to accumulate data
- Base recommendations on DATA, not opinion. If the data is insufficient (< 20 entries), say so and suggest collecting more
- The self-iterate suite can be used to A/B test role changes: define an experiment, build with/without a role, score the output
