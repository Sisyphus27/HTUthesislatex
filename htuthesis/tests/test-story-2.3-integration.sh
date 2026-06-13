#!/usr/bin/env bash
# test-story-2.3-integration.sh — ATDD Red-Phase Integration Tests for Story 2.3
# TDD Phase: RED (all tests expected to FAIL before implementation)
#
# Usage: bash tests/test-story-2.3-integration.sh [--run]
#   --run    Remove SKIP markers (for green-phase verification)
#
# Priority: P0 tests are blocking
# Linked Risk: R-7 (score 6), R-11 (score 4), R-1 (score 9 regression)
# TC-E2-13 (front-matter no header + compile), TC-E2-14 (header format)
#
# NOTE: Header CONTENT parity (even page = title, odd page = chapter, front-matter no header)
#       is VISUAL verification — not automatable in bash without a PDF text-extraction tool.
#       These integration tests cover COMPILE REGRESSION (exit code, errors, warnings,
#       self-check dimensions, page count). Visual parity is recorded in the test matrix
#       (see atdd-checklist-2-3-*.md → Visual Verification Matrix).

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
echo "ATDD Integration Tests: Story 2.3 — Odd/even page headers with horizontal rule"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Compile & Regression ==="

# ATDD-2.3-21: latexmk -xelatex main.tex exit code 0 (AC-9, TC-E2-13)
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-2.3-21" "latexmk -xelatex main.tex exit code 0 (AC-9, TC-E2-13)" test_full_compile

# ATDD-2.3-22: zero compilation errors in main.log (AC-9)
test_no_errors() {
  if [[ -f "main.log" ]]; then
    local error_count
    error_count=$(grep -c '^!' main.log 2>/dev/null || true)
    error_count=$(echo "$error_count" | tr -d '[:space:]' | head -1)
    [[ "$error_count" -eq 0 ]]
  else
    return 1
  fi
}
run_test "P0" "ATDD-2.3-22" "zero compilation errors in main.log (AC-9)" test_no_errors

# ATDD-2.3-23: warning count <= 3 (AC-9, baseline = 0 warnings after Story 2.2)
test_warning_count() {
  if [[ -f "main.log" ]]; then
    local warning_count
    warning_count=$(grep -c 'Warning' main.log 2>/dev/null || true)
    warning_count=$(echo "$warning_count" | tr -d '[:space:]' | head -1)
    echo "  (Found $warning_count warnings, limit: 3)"
    [[ "$warning_count" -le 3 ]]
  else
    return 1
  fi
}
run_test "P0" "ATDD-2.3-23" "warning count <= 3 (AC-9, NFR ≤3 new vs baseline)" test_warning_count

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Regression Guards ==="

# ATDD-2.3-24: self-check dimensions unchanged — textheight ≈ 688pt, headheight ≈ 14pt (AC-9, R-1)
test_selfcheck_dims_unchanged() {
  if [[ ! -f "main.log" ]]; then
    return 1
  fi
  local textheight headheight
  textheight=$(grep 'textheight = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  headheight=$(grep 'headheight = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$textheight" ]] || [[ -z "$headheight" ]]; then
    echo "  (dimensions not found in self-check output)"
    return 1
  fi
  echo "  (textheight: ${textheight}pt [expect ~688], headheight: ${headheight}pt [expect ~14])"
  # Header/pagestyle changes must NOT alter geometry. Tolerate ±2pt for rounding.
  echo "$textheight" | awk '{if ($1 >= 686 && $1 <= 690) exit 0; else exit 1}' && \
  echo "$headheight" | awk '{if ($1 >= 12 && $1 <= 16) exit 0; else exit 1}'
}
run_test "P1" "ATDD-2.3-24" "self-check geometry unchanged (textheight ~688pt, headheight ~14pt) (AC-9, R-1)" test_selfcheck_dims_unchanged

# ATDD-2.3-25: no fancyhdr headheight warning (regression, R-2)
test_no_headheight_warning() {
  if [[ -f "main.log" ]]; then
    ! grep -qi 'headheight.*too low\|fancyhdr.*headheight' main.log 2>/dev/null
  else
    return 1
  fi
}
run_test "P1" "ATDD-2.3-25" "no fancyhdr headheight warning (R-2 regression)" test_no_headheight_warning

# ATDD-2.3-26: main.pdf exists and is non-empty (AC-9)
test_pdf_output() {
  [[ -f "main.pdf" ]] && [[ -s "main.pdf" ]]
}
run_test "P1" "ATDD-2.3-26" "main.pdf exists and is non-empty (AC-9)" test_pdf_output

# ATDD-2.3-27: total pages ~50 (+/- 3) — header changes must not alter page count (AC-9)
test_page_count() {
  if [[ ! -f "main.log" ]]; then
    return 1
  fi
  local total_pages
  total_pages=$(grep 'total pages = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | tr -d '[:space:]')
  if [[ -z "$total_pages" ]]; then
    echo "  (page count not found)"
    return 1
  fi
  echo "  (pages: $total_pages, expected 50 +/- 3)"
  echo "$total_pages" | awk '{if ($1 >= 47 && $1 <= 53) exit 0; else exit 1}'
}
run_test "P1" "ATDD-2.3-27" "total pages ~50 (+/- 3) (AC-9, no page-count regression)" test_page_count

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: Supplementary ==="

# ATDD-2.3-28: self-check baselineskip still 20bp (regression guard for Story 2.5, R-3)
test_baselineskip_regression() {
  if [[ ! -f "main.log" ]]; then
    return 1
  fi
  local bs
  bs=$(grep 'baselineskip = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$bs" ]]; then
    echo "  (baselineskip not found)"
    return 1
  fi
  echo "  (baselineskip: ${bs}pt, expect ~20 [18bp target is Story 2.5])"
  echo "$bs" | awk '{if ($1 >= 19 && $1 <= 21) exit 0; else exit 1}'
}
run_test "P2" "ATDD-2.3-28" "baselineskip still ~20pt (Story 2.5 scope, R-3 regression)" test_baselineskip_regression

echo ""

# ==========================================
# Summary
# ==========================================
echo "=============================================="
printf "Total: \033[32m%d PASS\033[0m  \033[31m%d FAIL\033[0m  \033[33m%d SKIP\033[0m\n" "$PASS" "$FAIL" "$SKIP_COUNT"
echo "=============================================="

if [[ "$SKIP" == "1" ]]; then
  echo ""
  echo "RED TDD RED PHASE: All tests are SKIPPED"
  echo "   Run with --run flag or ATDD_SKIP=0 to activate"
  echo "   Tests are expected to FAIL until implementation is complete"
  echo ""
  echo "   NOTE: Header CONTENT parity (even=title, odd=chapter, front-matter none)"
  echo "         is VISUAL verification — record in the test matrix, not here."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
