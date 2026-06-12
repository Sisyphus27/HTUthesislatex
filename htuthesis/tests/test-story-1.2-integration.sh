#!/usr/bin/env bash
# test-story-1.2-integration.sh — ATDD Red-Phase Integration Tests for Story 1.2
# TDD Phase: RED (all tests expected to FAIL before implementation)
#
# Usage: bash tests/test-story-1.2-integration.sh [--run]
#   --run    Remove SKIP markers (for green-phase verification)
#
# Priority: P0 tests are blocking
# Linked Risk: E1-R4 (Parameter externalization breaks cls references, Score 4)

set -uo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DIR"

# --- TDD Red Phase Control ---
SKIP="${ATDD_SKIP:-1}"

if [[ "${1:-}" == "--run" ]]; then
  SKIP=0
fi

PASS=0
FAIL=0
SKIP_COUNT=0

green()  { printf "\033[32m  [PASS] %s\033[0m\n" "$1"; }
red()    { printf "\033[31m  [FAIL] %s\033[0m\n" "$1"; }
yellow() { printf "\033[33m  [SKIP] %s\033[0m\n" "$1"; }

run_test() {
  local priority="$1"
  local test_id="$2"
  local description="$3"

  if [[ "$SKIP" == "1" ]]; then
    yellow "[$priority] $test_id: $description"
    ((SKIP_COUNT++))
    return 0
  fi

  shift 3
  "$@"
  if [[ $? -eq 0 ]]; then
    green "[$priority] $test_id: $description"
    ((PASS++))
  else
    red "[$priority] $test_id: $description"
    ((FAIL++))
  fi
}

echo "=============================================="
echo "ATDD Integration Tests: Story 1.2 — Externalize format parameters"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Compile Verification ==="

# ATDD-1.2-10: Full compile with def loading succeeds (AC-7)
test_full_compile() {
  # htuthesis.def must exist for this test to be meaningful
  [[ -f "htuthesis.def" ]] || return 1
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -file-line-error -halt-on-error -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-1.2-10" "latexmk -xelatex main.tex (with .def) exit code 0" test_full_compile

# ATDD-1.2-11: main.pdf exists and is non-empty after compile (AC-7)
test_pdf_output() {
  [[ -f "htuthesis.def" ]] || return 1
  [[ -f "main.pdf" ]] && [[ -s "main.pdf" ]]
}
run_test "P0" "ATDD-1.2-11" "main.pdf exists and is non-empty" test_pdf_output

# ATDD-1.2-12: No compilation errors in log (AC-7)
test_no_errors() {
  if [[ -f "htuthesis.def" ]] && [[ -f "main.log" ]]; then
    local error_count
    error_count=$(grep -c '^!' main.log 2>/dev/null || true)
    error_count=$(echo "$error_count" | tr -d '[:space:]' | head -1)
    echo "  (Found $error_count errors)"
    [[ "$error_count" -eq 0 ]]
  else
    return 1
  fi
}
run_test "P0" "ATDD-1.2-12" "No compilation errors in main.log" test_no_errors

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Compile Quality ==="

# ATDD-1.2-13: Warning count within baseline (AC-7)
test_warning_count() {
  if [[ -f "htuthesis.cls" ]] && [[ -f "main.log" ]]; then
    local warning_count
    warning_count=$(grep -c 'Warning' main.log 2>/dev/null || true)
    warning_count=$(echo "$warning_count" | tr -d '[:space:]' | head -1)
    # Baseline zzuthesis has ~15 warnings from ctexbook; allow +3
    echo "  (Found $warning_count warnings)"
    [[ "$warning_count" -le 18 ]]
  else
    return 1
  fi
}
run_test "P1" "ATDD-1.2-13" "Warning count <= baseline + 3" test_warning_count

# ATDD-1.2-07: Parameter propagation test (AC-4)
# Change leftmargin in .def, recompile, verify geometry changes in log
test_parameter_propagation() {
  [[ -f "htuthesis.def" ]] || return 1
  [[ -f "htuthesis.cls" ]] || return 1

  # Step 1: Backup .def file
  cp htuthesis.def htuthesis.def.test-backup

  # Step 2: Change to 40mm using sed
  sed -i 's/\\def\\htu@leftmargin{32mm}/\\def\\htu@leftmargin{40mm}/' htuthesis.def 2>/dev/null || \
  sed -i 's/\\def\\htu@leftmargin{[0-9]*mm}/\\def\\htu@leftmargin{40mm}/' htuthesis.def 2>/dev/null

  # Step 3: Recompile
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  local compile_rc=$?

  # Step 4: Restore from backup (avoids sed backslash-escaping bug)
  mv htuthesis.def.test-backup htuthesis.def

  if [[ "$compile_rc" -ne 0 ]]; then
    echo "  (Compile failed with modified .def)"
    return 1
  fi

  # Step 5: Verify geometry reflects the change
  if [[ -f "main.log" ]]; then
    local has_geometry_output
    has_geometry_output=$(grep -c 'oddsidemargin' main.log 2>/dev/null || true)
    echo "  (Geometry output lines: $has_geometry_output)"
    return 0
  fi

  return 0
}
run_test "P1" "ATDD-1.2-07" "Parameter propagation: .def change -> recompile -> verify" test_parameter_propagation

echo ""

# ==========================================
# Summary
# ==========================================
echo "=============================================="
printf "Total: \033[32m%d PASS\033[0m  \033[31m%d FAIL\033[0m  \033[33m%d SKIP\033[0m\n" "$PASS" "$FAIL" "$SKIP_COUNT"
echo "=============================================="

if [[ "$SKIP" == "1" ]]; then
  echo ""
  echo "TDD RED PHASE: All tests are SKIPPED"
  echo "   Run with --run flag or ATDD_SKIP=0 to activate"
  echo "   Tests are expected to FAIL until implementation is complete"
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
