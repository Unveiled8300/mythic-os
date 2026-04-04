#!/bin/bash
# eval_live_test.sh — Live execution eval for self-iterate skill suite
#
# Two-phase structure (autoresearch pattern):
#   Phase 1 — Static pre-screen (C1-C3, <1s): grep checks against SKILL.md files
#              Eliminates expensive live trials when structural issues exist.
#   Phase 2 — Live execution (C4-C5, 20-60s): invoke history-report via claude --print,
#              feed pinned fixture data inline, assert behavioral output quality.
#
# Exit 0 = all criteria PASS, Exit 1 = any criterion FAIL
#
# Usage:
#   cd ~/.claude
#   bash skills/self-iterate/eval_live_test.sh

set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "$SELF_DIR/../.." && pwd)"
cd "$CLAUDE_DIR"

PASS=0
FAIL=0
TOTAL=5

echo "=== Eval: self-iterate live test ==="
echo "Target: skills/self-iterate/history-report/SKILL.md"
echo ""

# ─── Phase 1: Static Pre-screen (C1-C3) ──────────────────────────────────────

echo "--- Phase 1: Static pre-screen ---"

# C1: Was the git branch created? (git-experiment has explicit checkout -b)
echo -n "C1: git-experiment has explicit checkout -b ... "
if grep -qi "checkout -b\|checkout.*-b" skills/self-iterate/git-experiment/SKILL.md 2>/dev/null; then
  echo "PASS"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

# C2: Was the git branch managed without conflict? (git-experiment has conflict detection)
echo -n "C2: git-experiment has conflict detection ... "
if grep -qi "conflict\|already exists\|branch.*exist" skills/self-iterate/git-experiment/SKILL.md 2>/dev/null; then
  echo "PASS"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

# C3: Did the skill complete without human intervention? (optimize-loop has NEVER STOP TO ASK)
echo -n "C3: optimize-loop has autonomous execution mandate ... "
if grep -qi "NEVER STOP\|never.*ask\|autonomous\|without.*human\|do not.*ask\|never.*pause" skills/self-iterate/optimize-loop/SKILL.md 2>/dev/null; then
  echo "PASS"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

# Abort before Phase 2 if static pre-screen has failures
# (mirrors autoresearch speed mandate: eliminate slow trials on structural issues)
if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Static pre-screen FAILED ($FAIL/$TOTAL criteria). Skipping live execution."
  echo ""
  echo "Results: $PASS/$TOTAL passed, $FAIL/$TOTAL failed"
  echo "VERDICT: FAIL"
  exit 1
fi

echo ""
echo "Static pre-screen PASSED (3/3). Proceeding to live execution..."
echo ""

# ─── Phase 2: Live Execution (C4-C5) ─────────────────────────────────────────

echo "--- Phase 2: Live execution ---"

# Source assertion library
source "$SELF_DIR/eval-harness/scripts/assert_report.sh"

# Create temp workspace; cleaned up on exit
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

# Read pinned fixture data
FIXTURE_RESULTS=$(cat "$SELF_DIR/eval-harness/fixtures/results.tsv")
SKILL_CONTENT=$(cat "$SELF_DIR/history-report/SKILL.md")

# Build the fixture config inline (matches fixtures/config.yaml values)
FIXTURE_CONFIG=$(cat <<'YAML'
experiment:
  tag: "fixture-test"
  created: "2026-03-28T00:00:00Z"
  status: "completed"
target:
  artifact: "eval-harness/fixtures/target_artifact.md"
evaluation:
  command: "bash skills/self-iterate/eval_live_test.sh"
  timeout_seconds: 120
  criteria:
    - "C1: Was the git branch created?"
    - "C2: Was the git branch managed without conflict?"
    - "C3: Did the skill complete without human intervention?"
    - "C4: Was a visual representation of eval findings displayed?"
    - "C5: Were before/after eval metrics displayed?"
  num_trials: 3
  success_threshold: 0.67
optimization:
  max_iterations: 150
  branch: "experiment/fixture-test"
history:
  results_file: "eval-harness/fixtures/results.tsv"
  report_dir: "eval-harness/fixtures/expected-report"
YAML
)

# Build user prompt — passes all fixture data inline
# "Model only sees what we control" (autoresearch pattern)
USER_PROMPT="Execute the history-report skill procedure now using the following fixture data.

CONFIG YAML:
${FIXTURE_CONFIG}

RESULTS TSV:
${FIXTURE_RESULTS}

TARGET ARTIFACT (placeholder):
# Fixture Target Artifact
This is a placeholder artifact for the fixture experiment.

GIT LOG (fixture):
efg5678 restore examples with improvements
def4567 remove examples (regression)
cde3456 add explicit examples
bcd2345 add section headers
abc1234 unmodified fixture artifact

TASK: Generate a complete experiment report using the history-report skill procedure.
Output ONLY the complete report.md content — no explanation, no preamble, no code fences."

echo "Invoking history-report skill via claude --print..."
echo "(This will take 20-60 seconds)"

# Single claude --print invocation shared by C4 and C5
# --tools "" disables all tools (output-only mode)
# --permission-mode bypassPermissions suppresses interactive prompts
if claude \
  --print \
  --system-prompt "$SKILL_CONTENT" \
  --tools "" \
  --permission-mode bypassPermissions \
  --output-format text \
  "$USER_PROMPT" > "$WORK_DIR/report.md" 2>"$WORK_DIR/claude_stderr.log"; then
  echo "claude --print completed successfully"
else
  EXIT_CODE=$?
  echo "claude --print FAILED (exit $EXIT_CODE)"
  echo "Stderr:"
  cat "$WORK_DIR/claude_stderr.log" | head -20
  echo ""
  echo "Results: $PASS/$TOTAL passed, $((TOTAL - PASS)) failed"
  echo "VERDICT: FAIL"
  exit 1
fi

echo ""
echo "Asserting C4 (bar chart quality):"

# C4 assertions — bar chart quality
# Pre-computed: round(0.40 × 20) = 8, round(1.00 × 20) = 20
assert_has_section "Pass Rate Over Time" "$WORK_DIR/report.md"
assert_has_section "█" "$WORK_DIR/report.md"
assert_bar_at_iter 0 8 "$WORK_DIR/report.md"   # iter 0: 0.40 × 20 = 8 filled
assert_bar_at_iter 4 20 "$WORK_DIR/report.md"  # iter 4: 1.00 × 20 = 20 filled

C4_PASS=$ASSERT_PASS
C4_FAIL=$ASSERT_FAIL

if [ "$C4_FAIL" -gt 0 ]; then
  echo "C4: FAIL (${C4_PASS}/4 bar chart assertions passed)"
  FAIL=$((FAIL + 1))
else
  echo "C4: PASS (bar chart assertions)"
  PASS=$((PASS + 1))
fi

echo ""
echo "Asserting C5 (before/after metrics):"

# Reset assertion counters for C5
ASSERT_PASS=0
ASSERT_FAIL=0

# C5 assertions — before/after metrics
# BASELINE = 0.40, BEST = 1.00, IMPROVEMENT = 0.60
assert_numeric_present "0.40" "$WORK_DIR/report.md"   # baseline pass rate
assert_numeric_present "0.60" "$WORK_DIR/report.md"   # improvement
assert_numeric_present "1.00" "$WORK_DIR/report.md"   # best pass rate

C5_PASS=$ASSERT_PASS
C5_FAIL=$ASSERT_FAIL

if [ "$C5_FAIL" -gt 0 ]; then
  echo "C5: FAIL (${C5_PASS}/3 metric assertions passed)"
  FAIL=$((FAIL + 1))
else
  echo "C5: PASS (before/after metric assertions)"
  PASS=$((PASS + 1))
fi

# ─── Final Results ────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL/$TOTAL failed"

if [ "$FAIL" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
else
  echo "VERDICT: FAIL"
  # Print generated report for debugging
  echo ""
  echo "--- Generated report (for debugging) ---"
  cat "$WORK_DIR/report.md" | head -60
  exit 1
fi
