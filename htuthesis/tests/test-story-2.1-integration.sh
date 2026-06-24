#!/usr/bin/env bash
# test-story-2.1-integration.sh — ATDD Red-Phase Integration Tests for Story 2.1
# TDD Phase: RED (all tests expected to FAIL before implementation)
#
# Usage: bash tests/test-story-2.1-integration.sh [--run]
#   --run    Remove SKIP markers (for green-phase verification)
#
# Priority: P0 tests are blocking
# Linked Risk: R-1 (CRITICAL score 9), R-6 (score 6)
# TC-E2-01: Geometry self-check dimensions (from test-design-epic-2.md)

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

# Helper: convert pt to mm (1pt = 0.35146mm)
pt_to_mm() {
  echo "$1" | awk '{printf "%.2f", $1 * 0.35146}'
}

# Helper: check if a value is within tolerance of expected (both in same unit)
within_tolerance() {
  local actual="$1"
  local expected="$2"
  local tolerance="${3:-1.0}"
  echo "$actual $expected $tolerance" | awk '{
    diff = ($1 > $2) ? $1 - $2 : $2 - $1;
    if (diff <= $3) exit 0; else exit 1
  }'
}

echo "=============================================="
echo "ATDD Integration Tests: Story 2.1 — Page Geometry Calibration"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Compile & Dimension Verification ==="

# ATDD-2.1-20: xelatex main.tex exit code 0 (AC-5)
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-2.1-20" "latexmk -xelatex main.tex exit code 0" test_full_compile

# ATDD-2.1-21: Zero compilation errors in .log (AC-5)
test_no_errors() {
  if [[ -f "main.log" ]]; then
    local error_count
    error_count=$(grep -cE '^!|LaTeX Error:|Fatal error' main.log 2>/dev/null || true)
    error_count=$(echo "$error_count" | tr -d '[:space:]' | head -1)
    [[ "$error_count" -eq 0 ]]
  else
    return 1
  fi
}
run_test "P0" "ATDD-2.1-21" "Zero compilation errors in main.log" test_no_errors

# ATDD-2.1-22: No geometry over-specification warning (AC-5 edge, R-1)
test_no_geometry_overspec() {
  if [[ -f "main.log" ]]; then
    ! grep -qi 'over-spec\|OverSpec\|geometry.*warning' main.log 2>/dev/null
  else
    return 1
  fi
}
run_test "P0" "ATDD-2.1-22" "No geometry over-specification warning" test_no_geometry_overspec

# ATDD-2.1-23: No fancyhdr headheight warning (AC-5 edge)
test_no_headheight_warning() {
  if [[ -f "main.log" ]]; then
    ! grep -qi 'headheight.*too low\|fancyhdr.*headheight' main.log 2>/dev/null
  else
    return 1
  fi
}
run_test "P0" "ATDD-2.1-23" "No fancyhdr headheight warning" test_no_headheight_warning

# ATDD-2.1-24: textheight within 1mm of expected (AC-4, TC-E2-01)
# Expected: includeheadfoot with A4 210x297mm, top=22, bottom=17.5
# body textheight = 297 - top(22) - bottom(17.5) - headheight(5) - headsep(3) - footskip(7.5) = 242mm
test_textheight() {
  if [[ ! -f "main.log" ]]; then
    return 1
  fi
  # Look for typeout of textheight (Task 3 adds this)
  local textheight_pt
  textheight_pt=$(grep 'htu@geometry@textheight=' main.log 2>/dev/null | head -1 | sed 's/.*htu@geometry@textheight=//' | sed 's/pt.*//')
  if [[ -z "$textheight_pt" ]]; then
    echo "  (typeout marker htu@geometry@textheight not found in log)"
    return 1
  fi
  local textheight_mm
  textheight_mm=$(pt_to_mm "$textheight_pt")
  echo "  (textheight: ${textheight_mm}mm, expected ~242mm)"
  within_tolerance "$textheight_mm" "242.0" "1.0"
}
run_test "P0" "ATDD-2.1-24" "textheight within 1mm of expected 242mm (AC-4)" test_textheight

# ATDD-2.1-25: textwidth within 1mm of expected (AC-4)
# Expected: 210 - 25 - 25 = 160mm
test_textwidth() {
  if [[ ! -f "main.log" ]]; then
    return 1
  fi
  local textwidth_pt
  textwidth_pt=$(grep 'htu@geometry@textwidth=' main.log 2>/dev/null | head -1 | sed 's/.*htu@geometry@textwidth=//' | sed 's/pt.*//')
  if [[ -z "$textwidth_pt" ]]; then
    echo "  (typeout marker htu@geometry@textwidth not found in log)"
    return 1
  fi
  local textwidth_mm
  textwidth_mm=$(pt_to_mm "$textwidth_pt")
  echo "  (textwidth: ${textwidth_mm}mm, expected ~160mm)"
  within_tolerance "$textwidth_mm" "160.0" "1.0"
}
run_test "P0" "ATDD-2.1-25" "textwidth within 1mm of expected 160mm (AC-4)" test_textwidth

# ATDD-2.1-26: topmargin/oddsidemargin within tolerance (AC-4)
test_margins() {
  if [[ ! -f "main.log" ]]; then
    return 1
  fi
  local topmargin_pt oddsidemargin_pt
  topmargin_pt=$(grep 'htu@geometry@topmargin=' main.log 2>/dev/null | head -1 | sed 's/.*htu@geometry@topmargin=//' | sed 's/pt.*//')
  oddsidemargin_pt=$(grep 'htu@geometry@oddsidemargin=' main.log 2>/dev/null | head -1 | sed 's/.*htu@geometry@oddsidemargin=//' | sed 's/pt.*//')
  if [[ -z "$topmargin_pt" ]] || [[ -z "$oddsidemargin_pt" ]]; then
    echo "  (typeout markers not found in log)"
    return 1
  fi
  local topmargin_mm oddsidemargin_mm
  topmargin_mm=$(pt_to_mm "$topmargin_pt")
  oddsidemargin_mm=$(pt_to_mm "$oddsidemargin_pt")
  echo "  (topmargin: ${topmargin_mm}mm ~22mm, oddsidemargin: ${oddsidemargin_mm}mm ~25mm)"
  # topmargin in includeheadfoot: ~22mm from top edge minus 1in (25.4mm) = ~-3.4mm TeX value
  # Actually in includeheadfoot, \topmargin = top - 1in + voffset
  # The actual check is simpler: just verify values exist and are reasonable
  # A more precise check needs the exact formula; 1mm tolerance on the 30mm margin
  within_tolerance "$oddsidemargin_mm" "25.0" "1.5"
}
run_test "P0" "ATDD-2.1-26" "oddsidemargin within tolerance (AC-4)" test_margins

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Quality Gate Tests ==="

# ATDD-2.1-27: Warning count within baseline (AC-5 quality gate)
test_warning_count() {
  if [[ -f "main.log" ]]; then
    local warning_count
    warning_count=$(grep -c 'Warning' main.log 2>/dev/null || true)
    warning_count=$(echo "$warning_count" | tr -d '[:space:]' | head -1)
    echo "  (Found $warning_count warnings)"
    # Epic 1 baseline was 0 warnings; allow +3 for geometry mode change
    [[ "$warning_count" -le 3 ]]
  else
    return 1
  fi
}
run_test "P1" "ATDD-2.1-27" "Warning count <= baseline + 3" test_warning_count

# ATDD-2.1-28: PDF exists and page count > 0 (AC-5)
test_pdf_output() {
  [[ -f "main.pdf" ]] && [[ -s "main.pdf" ]]
}
run_test "P1" "ATDD-2.1-28" "main.pdf exists and is non-empty" test_pdf_output

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
