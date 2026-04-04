#!/bin/bash
# =============================================================================
# run_eval.sh — Automated trial runner for the eval-harness skill
# =============================================================================
# Usage: ./run_eval.sh <EVAL_COMMAND> <NUM_TRIALS> <TIMEOUT_SECONDS>
#
# Runs EVAL_COMMAND exactly NUM_TRIALS times, captures pass/fail results,
# and outputs a structured verdict.
#
# Exit codes:
#   0 = PASS (pass_rate >= threshold)
#   1 = FAIL (pass_rate < threshold)
#   2 = CRASH (all trials crashed)
# =============================================================================

set -uo pipefail

# --- Argument parsing ---
if [ "$#" -lt 3 ]; then
  echo "Usage: $0 <EVAL_COMMAND> <NUM_TRIALS> <TIMEOUT_SECONDS> [THRESHOLD]"
  echo "  EVAL_COMMAND:    Command to run for each trial (quote if multi-word)"
  echo "  NUM_TRIALS:      Number of times to run the eval"
  echo "  TIMEOUT_SECONDS: Max seconds per trial before killing"
  echo "  THRESHOLD:       Pass rate threshold (default: 0.8)"
  exit 1
fi

EVAL_CMD="$1"
NUM_TRIALS="$2"
TIMEOUT="$3"
THRESHOLD="${4:-0.8}"

# --- State ---
PASSES=0
FAILS=0
TIMEOUTS=0
CRASHES=0
RESULTS=()
DURATIONS=()
FAIL_DETAILS=()

TMPDIR_EVAL=$(mktemp -d)
trap 'rm -rf "$TMPDIR_EVAL"' EXIT

# --- Run trials ---
for ((i=1; i<=NUM_TRIALS; i++)); do
  TRIAL_START=$(date +%s)

  STDOUT_FILE="$TMPDIR_EVAL/trial_${i}_stdout.tmp"
  STDERR_FILE="$TMPDIR_EVAL/trial_${i}_stderr.tmp"

  # Run with timeout
  if command -v gtimeout &> /dev/null; then
    TIMEOUT_CMD="gtimeout"
  elif command -v timeout &> /dev/null; then
    TIMEOUT_CMD="timeout"
  else
    TIMEOUT_CMD=""
  fi

  if [ -n "$TIMEOUT_CMD" ]; then
    $TIMEOUT_CMD "$TIMEOUT" bash -c "$EVAL_CMD" > "$STDOUT_FILE" 2> "$STDERR_FILE"
    EXIT_CODE=$?
  else
    # No timeout command available — run without timeout
    bash -c "$EVAL_CMD" > "$STDOUT_FILE" 2> "$STDERR_FILE"
    EXIT_CODE=$?
  fi

  TRIAL_END=$(date +%s)
  DURATION=$((TRIAL_END - TRIAL_START))
  DURATIONS+=("$DURATION")

  if [ "$EXIT_CODE" -eq 0 ]; then
    RESULTS+=("PASS")
    ((PASSES++))
  elif [ "$EXIT_CODE" -eq 124 ]; then
    RESULTS+=("TIMEOUT")
    ((TIMEOUTS++))
    ((FAILS++))
    DETAIL="--- Trial $i (TIMEOUT after ${TIMEOUT}s) ---"
    if [ -f "$STDERR_FILE" ]; then
      DETAIL="$DETAIL\n$(tail -n 50 "$STDERR_FILE")"
    fi
    FAIL_DETAILS+=("$DETAIL")
  else
    RESULTS+=("FAIL")
    ((FAILS++))
    DETAIL="--- Trial $i (FAIL, exit code $EXIT_CODE) ---"
    if [ -f "$STDERR_FILE" ]; then
      DETAIL="$DETAIL\n$(tail -n 50 "$STDERR_FILE")"
    fi
    FAIL_DETAILS+=("$DETAIL")
  fi

  # Clean up trial files
  rm -f "$STDOUT_FILE" "$STDERR_FILE"
done

# --- Compute verdict ---
if [ "$NUM_TRIALS" -gt 0 ]; then
  PASS_RATE=$(echo "scale=4; $PASSES / $NUM_TRIALS" | bc)
else
  PASS_RATE="0.0000"
fi

# Check if pass_rate >= threshold
VERDICT_CHECK=$(echo "$PASS_RATE >= $THRESHOLD" | bc -l)

if [ "$PASSES" -eq 0 ] && [ "$FAILS" -eq "$NUM_TRIALS" ]; then
  VERDICT="CRASH"
  FINAL_EXIT=2
elif [ "$VERDICT_CHECK" -eq 1 ]; then
  VERDICT="PASS"
  FINAL_EXIT=0
else
  VERDICT="FAIL"
  FINAL_EXIT=1
fi

# --- Output structured results ---
echo "========================================"
echo "EVAL RESULTS"
echo "========================================"
echo "verdict:    $VERDICT"
echo "pass_rate:  $PASSES/$NUM_TRIALS ($PASS_RATE)"
echo "threshold:  $THRESHOLD"
echo "----------------------------------------"

for ((i=0; i<NUM_TRIALS; i++)); do
  TRIAL_NUM=$((i+1))
  printf "trial_%d:    %s (%ds)\n" "$TRIAL_NUM" "${RESULTS[$i]}" "${DURATIONS[$i]}"
done

echo "----------------------------------------"

# Print failure details if any
if [ "${#FAIL_DETAILS[@]}" -gt 0 ]; then
  echo ""
  echo "FAILURE DETAILS:"
  for detail in "${FAIL_DETAILS[@]}"; do
    echo -e "$detail"
    echo "---"
  done
fi

exit "$FINAL_EXIT"
