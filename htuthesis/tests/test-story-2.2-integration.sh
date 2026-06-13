#!/usr/bin/env bash
# test-story-2.2-integration.sh — ATDD Red-Phase Integration Tests for Story 2.2
# TDD Phase: RED (all tests expected to FAIL before implementation)
#
# Usage: bash tests/test-story-2.2-integration.sh [--run]
#   --run    Remove SKIP markers (for green-phase verification)
#
# Priority: P0 tests are blocking
# Linked Risk: R-2 (score 6), R-7 (score 6), R-10 (score 6)
# TC-E2-05~08: twoside, self-check, silent failures (from test-design-epic-2.md)

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
echo "ATDD Integration Tests: Story 2.2 — Twoside Migration with ThuThesis Subsystem"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Compile & Verification ==="

# ATDD-2.2-16: xelatex main.tex exit code 0 (AC-6, TC-E2-05)
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-2.2-16" "latexmk -xelatex main.tex exit code 0 (AC-6)" test_full_compile

# ATDD-2.2-17: zero compilation errors in .log (AC-6)
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
run_test "P0" "ATDD-2.2-17" "zero compilation errors in main.log (AC-6)" test_no_errors

# ATDD-2.2-18: self-check output present in .log with all 7 dimensions (AC-5, TC-E2-06)
test_selfcheck_in_log() {
  if [[ ! -f "main.log" ]]; then
    return 1
  fi
  grep -q '=== HTU Layout Self-Check ===' main.log 2>/dev/null && \
  grep -q '=== End Self-Check ===' main.log 2>/dev/null && \
  grep -q 'textheight' main.log 2>/dev/null && \
  grep -q 'textwidth' main.log 2>/dev/null && \
  grep -q 'baselineskip' main.log 2>/dev/null && \
  grep -q 'headheight' main.log 2>/dev/null && \
  grep -q 'evensidemargin' main.log 2>/dev/null && \
  grep -q 'oddsidemargin' main.log 2>/dev/null && \
  grep -q 'total pages' main.log 2>/dev/null
}
run_test "P0" "ATDD-2.2-18" "self-check output in .log with all 7 dimensions (AC-5, TC-E2-06)" test_selfcheck_in_log

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Quality Gate Tests ==="

# ATDD-2.2-25: compile generates both odd and even pages (AC-3, TC-E2-10)
test_odd_even_pages() {
  if [[ ! -f "main.log" ]]; then
    return 1
  fi
  # In twoside mode, the total page count should be >= 2
  # Also check that the .log mentions twoside-related activity
  local total_pages
  total_pages=$(grep 'total pages = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | tr -d '[:space:]')
  if [[ -z "$total_pages" ]]; then
    echo "  (total pages not found in self-check output)"
    return 1
  fi
  echo "  (total pages: $total_pages, need >= 2 for odd/even test)"
  [[ "$total_pages" -ge 2 ]]
}
run_test "P1" "ATDD-2.2-25" "compile generates both odd and even pages (AC-3)" test_odd_even_pages

# ATDD-2.2-26: self-check values reasonable — textheight > 0, textwidth > 0 (AC-5)
test_selfcheck_reasonable() {
  if [[ ! -f "main.log" ]]; then
    return 1
  fi
  local textheight textwidth
  textheight=$(grep 'textheight = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  textwidth=$(grep 'textwidth = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$textheight" ]] || [[ -z "$textwidth" ]]; then
    echo "  (dimension values not found in log)"
    return 1
  fi
  echo "  (textheight: ${textheight}pt, textwidth: ${textwidth}pt)"
  # Both should be positive numbers
  echo "$textheight" | awk '{if ($1 > 0) exit 0; else exit 1}' && \
  echo "$textwidth" | awk '{if ($1 > 0) exit 0; else exit 1}'
}
run_test "P1" "ATDD-2.2-26" "self-check values reasonable (textheight > 0, textwidth > 0) (AC-5)" test_selfcheck_reasonable

# ATDD-2.2-27: no fancyhdr headheight warning (AC-6, R-2)
test_no_headheight_warning() {
  if [[ -f "main.log" ]]; then
    ! grep -qi 'headheight.*too low\|fancyhdr.*headheight' main.log 2>/dev/null
  else
    return 1
  fi
}
run_test "P1" "ATDD-2.2-27" "no fancyhdr headheight warning (AC-6, R-2)" test_no_headheight_warning

# ATDD-2.2-28: warning count <= baseline + 3 (AC-6)
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
run_test "P1" "ATDD-2.2-28" "warning count <= 3 (AC-6)" test_warning_count

# ATDD-2.2-30: PDF exists and is non-empty (AC-6)
test_pdf_output() {
  [[ -f "main.pdf" ]] && [[ -s "main.pdf" ]]
}
run_test "P1" "ATDD-2.2-30" "main.pdf exists and is non-empty (AC-6)" test_pdf_output

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: Supplementary Tests ==="

# ATDD-2.2-35: PDF page count similar to pre-migration (51 +/- 2) (AC-6)
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
  echo "  (pages: $total_pages, expected 51 +/- 2)"
  echo "$total_pages" | awk '{if ($1 >= 49 && $1 <= 53) exit 0; else exit 1}'
}
run_test "P2" "ATDD-2.2-35" "PDF page count ~51 (+/- 2) (AC-6)" test_page_count

# ATDD-2.2-36: evensidemargin and oddsidemargin both reasonable (AC-5, R-1)
test_margin_values() {
  if [[ ! -f "main.log" ]]; then
    return 1
  fi
  local even odd
  even=$(grep 'evensidemargin = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  odd=$(grep 'oddsidemargin = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$even" ]] || [[ -z "$odd" ]]; then
    echo "  (margin values not found in log)"
    return 1
  fi
  echo "  (evensidemargin: ${even}pt, oddsidemargin: ${odd}pt)"
  # With symmetric 25mm margins, both should be ~-0.4pt (25mm - 1in)
  # In twoside mode they should both be reasonable (not wildly different)
  echo "$even" | awk '{if ($1 > -100 && $1 < 100) exit 0; else exit 1}' && \
  echo "$odd" | awk '{if ($1 > -100 && $1 < 100) exit 0; else exit 1}'
}
run_test "P2" "ATDD-2.2-36" "evensidemargin and oddsidemargin reasonable (AC-5)" test_margin_values

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
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
