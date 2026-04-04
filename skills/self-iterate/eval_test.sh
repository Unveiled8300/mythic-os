#!/bin/bash
# Eval script for: self-iterate skill suite
# Tag: mar28-self-iterate
#
# Criteria:
#   C1: Was the git branch created?
#       → git-experiment/SKILL.md has explicit `git checkout -b` instruction
#   C2: Was the git branch managed without conflict?
#       → git-experiment/SKILL.md has explicit conflict detection + recovery
#   C3: Did the skill complete without human intervention?
#       → optimize-loop/SKILL.md has explicit autonomous execution directive
#   C4: Was a visual representation of eval findings displayed?
#       → history-report/SKILL.md has explicit instructions for chart/visual generation
#   C5: Were before/after eval metrics displayed?
#       → history-report/SKILL.md computes baseline+improvement AND template has both fields
#
# Usage: bash eval_test.sh
# Exit 0 = PASS (all criteria met), Exit 1 = FAIL

PASS=0
FAIL=0
TOTAL=5
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Eval: mar28-self-iterate ==="
echo "Target: skills/self-iterate/history-report/SKILL.md"
echo ""

# ---------------------------------------------------------------------------
# C1: Git branch creation is explicitly instructed
# The git-experiment sub-skill must contain the actual git checkout command
# ---------------------------------------------------------------------------
echo -n "C1: Git branch creation explicitly instructed ... "
if grep -q "git checkout -b" "$DIR/git-experiment/SKILL.md"; then
  echo "PASS"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# C2: Git branch conflict detection is present
# The git-experiment sub-skill must detect an existing tag and stop/recover
# ---------------------------------------------------------------------------
echo -n "C2: Branch conflict detection present ... "
if grep -q "STOP and report the conflict\|already exist" "$DIR/git-experiment/SKILL.md"; then
  echo "PASS"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# C3: Optimize-loop runs autonomously without pausing for human input
# Must have an explicit "NEVER STOP TO ASK" or equivalent bold directive
# ---------------------------------------------------------------------------
echo -n "C3: Autonomous execution directive present ... "
if grep -q "NEVER STOP TO ASK" "$DIR/optimize-loop/SKILL.md"; then
  echo "PASS"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# C4: Visual representation of eval findings explicitly instructed
# history-report/SKILL.md must explicitly mention how to render a chart or
# visual. Checking for keywords: ascii, bar chart, visual, chart, █, ░
# NOTE: Checking the SKILL.md instructions, NOT just the template placeholder
# ---------------------------------------------------------------------------
echo -n "C4: Visual chart generation explicitly instructed ... "
if grep -qi "ascii\|bar chart\|chart generation\|render.*chart\|chart.*render\|visual chart\|pass rate.*chart\|chart.*pass rate\|█\|░\|sparkline\|visual.*progression\|progression.*visual" "$DIR/history-report/SKILL.md"; then
  echo "PASS"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# C5: Before/after eval metrics are explicitly tracked and displayed
# Both the SKILL.md (instructions) and template (output format) must support
# baseline vs best comparison and improvement calculation
# ---------------------------------------------------------------------------
echo -n "C5: Before/after metrics (baseline vs best) present ... "
if grep -q "Baseline pass rate\|baseline pass\|baseline" "$DIR/history-report/SKILL.md" && \
   grep -q "BASELINE_PASS_RATE" "$DIR/history-report/resources/report_template.md" && \
   grep -q "IMPROVEMENT" "$DIR/history-report/resources/report_template.md"; then
  echo "PASS"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# Results
# ---------------------------------------------------------------------------
echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL/$TOTAL failed"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
else
  echo "VERDICT: FAIL"
  exit 1
fi
