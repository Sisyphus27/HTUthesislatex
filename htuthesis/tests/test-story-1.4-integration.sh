#!/usr/bin/env bash
# test-story-1.4-integration.sh — ATDD Red-Phase Integration Tests for Story 1.4
# TDD Phase: RED (all tests expected to FAIL before implementation)
#
# Usage: bash tests/test-story-1.4-integration.sh [--run]
#   --run    Remove SKIP markers (for green-phase verification)
#
# Priority: P0 tests are blocking
# Linked Risks: E1-R3 (Font detection not implemented, Score 6)
#               E1-R6 (Logo file quality, Score 4)

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
    ((PASS++)) || true
  else
    red "[$priority] $test_id: $description"
    ((FAIL++))
  fi
}

echo "=============================================="
echo "ATDD Integration Tests: Story 1.4 — Replace ZZU identity with HTU identity"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Compile Verification ==="

# ATDD-1.4-20: Full compile succeeds with HTU identity (AC-6, TC-1.4-INT-02)
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-1.4-20" "latexmk -xelatex main.tex exit code 0 (AC-6)" test_full_compile

# ATDD-1.4-21: main.pdf exists and is non-empty (AC-6)
test_pdf_output() {
  [[ -f "main.pdf" ]] && [[ -s "main.pdf" ]]
}
run_test "P0" "ATDD-1.4-21" "main.pdf exists and is non-empty (AC-6)" test_pdf_output

# ATDD-1.4-22: No compilation errors in log (AC-6)
test_no_errors() {
  if [[ -f "main.log" ]]; then
    local error_count
    error_count=$(grep -cE '^!|LaTeX Error:|Fatal error' main.log 2>/dev/null || true)
    error_count=$(echo "$error_count" | tr -d '[:space:]' | head -1)
    echo "  (Found $error_count errors)"
    [[ "$error_count" -eq 0 ]]
  else
    return 1
  fi
}
run_test "P0" "ATDD-1.4-22" "No compilation errors in main.log (AC-6)" test_no_errors

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Logo Files & Quality ==="

# ATDD-1.4-23: HTU logo files exist and are non-empty (AC-3, TC-1.4-INT-01)
test_htu_logos_exist() {
  local found=0
  for f in figures/htu-logo.pdf figures/htu-text-logo.pdf; do
    if [[ -f "$f" ]] && [[ -s "$f" ]]; then
      ((found++))
    else
      echo "  (Missing or empty: $f)"
    fi
  done
  echo "  (Found $found/2 HTU logo files)"
  [[ "$found" -eq 2 ]]
}
run_test "P1" "ATDD-1.4-23" "HTU logo files exist and non-empty (AC-3)" test_htu_logos_exist

# ATDD-1.4-24: Warning count within baseline (AC-6)
test_warning_count() {
  if [[ -f "main.log" ]]; then
    local warning_count
    warning_count=$(grep -c 'Warning' main.log 2>/dev/null || true)
    warning_count=$(echo "$warning_count" | tr -d '[:space:]' | head -1)
    echo "  (Found $warning_count warnings)"
    [[ "$warning_count" -le 18 ]]
  else
    return 1
  fi
}
run_test "P1" "ATDD-1.4-24" "Warning count <= baseline + 3 (AC-6)" test_warning_count

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: File Quality ==="

# ATDD-1.4-25: Logo files < 500KB (AC-3, TC-1.4-INT-01)
test_logo_file_size() {
  local ok=0
  for f in figures/htu-logo.pdf figures/htu-text-logo.pdf; do
    if [[ -f "$f" ]]; then
      local size
      size=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null || echo "0")
      size=$(echo "$size" | tr -d '[:space:]' | head -1)
      local max_size=$((500 * 1024))
      echo "  ($f: $size bytes, limit: $max_size)"
      if [[ "$size" -gt 0 ]] && [[ "$size" -lt "$max_size" ]]; then
        ((ok++))
      fi
    else
      echo "  ($f not found)"
    fi
  done
  [[ "$ok" -eq 2 ]]
}
run_test "P2" "ATDD-1.4-25" "Logo files < 500KB (AC-3)" test_logo_file_size

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
