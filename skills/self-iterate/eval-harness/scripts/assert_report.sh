#!/bin/bash
# assert_report.sh — Assertion library for eval_live_test.sh
#
# Source this file, then call assertion functions.
# Tracks ASSERT_PASS / ASSERT_FAIL counters.
# Call assert_summary at the end to print totals and return exit code.
#
# Usage:
#   source eval-harness/scripts/assert_report.sh
#   assert_has_section "Pass Rate Over Time" "$REPORT_FILE"
#   assert_bar_at_iter 0 8 "$REPORT_FILE"
#   assert_numeric_present "0.40" "$REPORT_FILE"
#   assert_summary

ASSERT_PASS=0
ASSERT_FAIL=0

# assert_has_section HEADING FILE
# Passes if the heading string appears in the file (case-insensitive).
assert_has_section() {
  local heading="$1"
  local file="$2"
  if grep -qi "$heading" "$file"; then
    echo "  PASS: section '$heading' found"
    ASSERT_PASS=$((ASSERT_PASS + 1))
  else
    echo "  FAIL: section '$heading' NOT found in $file"
    ASSERT_FAIL=$((ASSERT_FAIL + 1))
  fi
}

# assert_bar_at_iter ITER FILL FILE
# Finds the line for iteration ITER in the ASCII bar chart, then verifies:
#   - It contains exactly FILL '█' characters
#   - The character immediately after the filled region is '░' (boundary guard)
#     Exception: if FILL == 20 (full bar), no boundary guard check is needed.
#
# Uses python3 to build the expected UTF-8 fill string (portable multi-byte repeat).
assert_bar_at_iter() {
  local iter="$1"
  local fill="$2"
  local file="$3"

  # Build expected fill string via python3 (avoids bash UTF-8 width issues)
  local fill_str
  fill_str=$(python3 -c "import sys; sys.stdout.write('█' * ${fill})")

  # Get the line containing "iter N" from the bar chart section
  local line
  line=$(grep "iter ${iter}" "$file" | head -1)

  if [ -z "$line" ]; then
    echo "  FAIL: bar chart line for iter ${iter} NOT found in $file"
    ASSERT_FAIL=$((ASSERT_FAIL + 1))
    return
  fi

  # Check that the fill string appears in the line
  if ! echo "$line" | grep -qF "$fill_str"; then
    echo "  FAIL: iter ${iter} bar does not contain ${fill} filled chars"
    echo "        line: $line"
    ASSERT_FAIL=$((ASSERT_FAIL + 1))
    return
  fi

  # Boundary guard: if fill < 20, the char after fill_str must be '░'
  # This prevents substring false-positives (e.g., a 20-fill bar trivially contains 8-fill)
  if [ "$fill" -lt 20 ]; then
    local boundary_str
    boundary_str=$(python3 -c "import sys; sys.stdout.write('█' * ${fill} + '░')")
    if ! echo "$line" | grep -qF "$boundary_str"; then
      echo "  FAIL: iter ${iter} bar boundary guard failed (fill=${fill}, expected '█'×${fill} followed by '░')"
      echo "        line: $line"
      ASSERT_FAIL=$((ASSERT_FAIL + 1))
      return
    fi
  fi

  echo "  PASS: iter ${iter} bar has ${fill} filled chars"
  ASSERT_PASS=$((ASSERT_PASS + 1))
}

# assert_numeric_present VALUE FILE
# Passes if the plain decimal value appears anywhere in the file.
assert_numeric_present() {
  local value="$1"
  local file="$2"
  if grep -qF "$value" "$file"; then
    echo "  PASS: numeric value '$value' found"
    ASSERT_PASS=$((ASSERT_PASS + 1))
  else
    echo "  FAIL: numeric value '$value' NOT found in $file"
    ASSERT_FAIL=$((ASSERT_FAIL + 1))
  fi
}

# assert_summary
# Prints pass/fail totals and exits 0 if all passed, 1 if any failed.
assert_summary() {
  local total=$((ASSERT_PASS + ASSERT_FAIL))
  echo ""
  echo "Assertions: ${ASSERT_PASS}/${total} passed"
  if [ "$ASSERT_FAIL" -gt 0 ]; then
    return 1
  fi
  return 0
}
