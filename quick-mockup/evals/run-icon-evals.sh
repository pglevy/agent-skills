#!/bin/bash
# Automated eval runner for validate-icons.sh
# Runs all icon validation test cases and reports pass/fail.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VALIDATE="$SCRIPT_DIR/scripts/validate-icons.sh"
FILES_DIR="$SCRIPT_DIR/evals/files"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

passed=0
failed=0

run_eval() {
  local name="$1"
  local file="$2"
  local expect_exit="$3"
  local expect_invalid_count="$4"
  shift 4
  local must_not_flag=("$@")

  local dir="$TMPDIR/$name"
  mkdir -p "$dir"
  cp "$file" "$dir/"

  local output
  local actual_exit
  output=$(bash "$VALIDATE" "$dir" 2>&1) && actual_exit=0 || actual_exit=$?

  local eval_passed=true

  # Check exit code
  if [ "$actual_exit" -ne "$expect_exit" ]; then
    echo "FAIL [$name]: Expected exit $expect_exit, got $actual_exit"
    eval_passed=false
  fi

  # Check icon count loaded (should be >= 2000 after grouped-selector fix)
  local loaded_count
  loaded_count=$(echo "$output" | grep -oE 'Loaded [0-9]+' | grep -oE '[0-9]+')
  if [ -n "$loaded_count" ] && [ "$loaded_count" -lt 2000 ]; then
    echo "FAIL [$name]: Only loaded $loaded_count icons (expected >= 2000)"
    eval_passed=false
  fi

  # Check invalid count if specified
  if [ -n "$expect_invalid_count" ]; then
    local actual_invalid
    actual_invalid=$(echo "$output" | grep -c '^INVALID:' || true)
    if [ "$actual_invalid" -ne "$expect_invalid_count" ]; then
      echo "FAIL [$name]: Expected $expect_invalid_count invalid, got $actual_invalid"
      eval_passed=false
    fi
  fi

  # Check that specified icons are NOT flagged
  for icon in "${must_not_flag[@]}"; do
    if echo "$output" | grep -q "INVALID: $icon"; then
      echo "FAIL [$name]: $icon was incorrectly flagged as invalid"
      eval_passed=false
    fi
  done

  if [ "$eval_passed" = true ]; then
    echo "PASS [$name]"
    passed=$((passed + 1))
  else
    echo "  Output was:"
    echo "$output" | sed 's/^/    /'
    failed=$((failed + 1))
  fi
}

echo "=== Icon Validation Evals ==="
echo ""

# Eval 1: All valid icons — no false positives
run_eval "all-valid-no-false-positives" \
  "$FILES_DIR/icons-all-valid.html" \
  0 0

# Eval 2: Pro/fictional icons — should catch exactly 4
run_eval "pro-icons-detected" \
  "$FILES_DIR/icons-pro-mixed.html" \
  1 4 \
  "fa-house" "fa-folder" "fa-circle-info" "fa-linkedin"

# Eval 3: Grouped-selector icons — no false positives (the original bug)
run_eval "grouped-selector-icons-pass" \
  "$FILES_DIR/icons-grouped-selectors.html" \
  0 0 \
  "fa-user" "fa-house-chimney-crack" "fa-user-alt" "fa-house-damage"

echo ""
echo "=== Results: $passed passed, $failed failed ==="

if [ "$failed" -gt 0 ]; then
  exit 1
fi
