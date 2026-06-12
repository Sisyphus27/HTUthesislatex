#!/usr/bin/env bash
# test-story-1.1-integration.sh — ATDD Red-Phase Integration Tests for Story 1.1
# TDD Phase: RED (all tests expected to FAIL before implementation)
#
# Usage: bash tests/test-story-1.1-integration.sh [--run]
#   --run    Remove SKIP markers (for green-phase verification)
#
# Priority: P0 tests are blocking
# Linked Risk: E1-R1 (Macro rename misses causing compile failure)

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
echo "ATDD Integration Tests: Story 1.1 — Rename to htuthesis"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Compile Verification ==="

# ATDD-1.1-12: Full compile cycle succeeds with htuthesis (AC-9)
test_full_compile() {
  # Must compile using htuthesis.cls (not old zzuthesis.cls)
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -file-line-error -halt-on-error -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-1.1-12" "latexmk -xelatex main.tex (htuthesis.cls) exit code 0" test_full_compile

# ATDD-1.1-13: main.pdf exists and is non-empty (AC-9)
test_pdf_output() {
  [[ -f "htuthesis.cls" ]] || return 1
  [[ -f "main.pdf" ]] && [[ -s "main.pdf" ]]
}
run_test "P0" "ATDD-1.1-13" "main.pdf exists and is non-empty" test_pdf_output

# ATDD-1.1-20: No compilation errors in log (AC-9)
test_no_errors() {
  if [[ -f "htuthesis.cls" ]] && [[ -f "main.log" ]]; then
    local error_count
    error_count=$(grep -c '^!' main.log 2>/dev/null || true)
    error_count=$(echo "$error_count" | tr -d '[:space:]' | head -1)
    [[ "$error_count" -eq 0 ]]
  else
    return 1
  fi
}
run_test "P0" "ATDD-1.1-20" "No compilation errors in main.log" test_no_errors

# ATDD-1.1-21: Warning count within baseline (AC-9)
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
run_test "P0" "ATDD-1.1-21" "Warning count <= baseline + 3" test_warning_count

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Build System Tests ==="

# ATDD-1.1-22: make test succeeds (P1 - depends on Makefile rename)
test_make_test() {
  make test > /dev/null 2>&1
  return $?
}
run_test "P1" "ATDD-1.1-22" "make test completes successfully" test_make_test

echo ""

# ==========================================
# Summary
# ==========================================
echo "=============================================="
printf "Total: \033[32m%d PASS\033[0m  \033[31m%d FAIL\033[0m  \033[33m%d SKIP\033[0m\n" "$PASS" "$FAIL" "$SKIP_COUNT"
echo "=============================================="

if [[ "$SKIP" == "1" ]]; then
  echo ""
  echo "🔴 TDD RED PHASE: All tests are SKIPPED"
  echo "   Run with --run flag or ATDD_SKIP=0 to activate"
  echo "   Tests are expected to FAIL until implementation is complete"
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
