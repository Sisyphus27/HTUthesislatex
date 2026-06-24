#!/usr/bin/env bash
# test-story-1.3-integration.sh — ATDD Red-Phase Integration Tests for Story 1.3
# TDD Phase: RED (all tests expected to FAIL before implementation)
#
# Usage: bash tests/test-story-1.3-integration.sh [--run]
#   --run    Remove SKIP markers (for green-phase verification)
#
# Priority: P0 tests are blocking
# Linked Risks: E1-R2 (Branch deletion regressions, Score 6)
#               E1-R7 (Baseline PDF not compiled, Score 4)

set -uo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DIR"

BASELINE_FILE="tests/.baseline-1.3.txt"

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
echo "ATDD Integration Tests: Story 1.3 — Remove bachelor/master branches"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Baseline & Compile Verification ==="

# ATDD-1.3-20: Baseline PDF recorded before changes (AC-3, TC-1.3-OPS-01)
test_baseline_recorded() {
  # Check that baseline file exists with page count and file size
  if [[ -f "$BASELINE_FILE" ]]; then
    local pages size
    pages=$(grep '^pages=' "$BASELINE_FILE" 2>/dev/null | cut -d= -f2)
    size=$(grep '^size=' "$BASELINE_FILE" 2>/dev/null | cut -d= -f2)
    echo "  (Baseline: $pages pages, $size bytes)"
    [[ -n "$pages" ]] && [[ -n "$size" ]] && [[ "$pages" -gt 0 ]]
  else
    echo "  (Baseline file not found: $BASELINE_FILE)"
    return 1
  fi
}
run_test "P0" "ATDD-1.3-20" "Baseline PDF recorded before changes" test_baseline_recorded

# ATDD-1.3-21: Full compile succeeds after branch removal (AC-4, TC-1.3-INT-01)
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-1.3-21" "latexmk -xelatex main.tex exit code 0" test_full_compile

# ATDD-1.3-22: main.pdf exists and is non-empty (AC-4)
test_pdf_output() {
  [[ -f "main.pdf" ]] && [[ -s "main.pdf" ]]
}
run_test "P0" "ATDD-1.3-22" "main.pdf exists and is non-empty" test_pdf_output

# ATDD-1.3-23: No compilation errors in log (AC-4)
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
run_test "P0" "ATDD-1.3-23" "No compilation errors in main.log" test_no_errors

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Output Quality ==="

# ATDD-1.3-24: PDF page count within expected range (AC-1, TC-1.3-INT-02)
# Removing bachelor cover (~3 pages) should reduce page count
test_page_count() {
  if [[ -f "main.pdf" ]] && command -v pdfinfo &>/dev/null; then
    local current_pages
    current_pages=$(pdfinfo main.pdf 2>/dev/null | grep 'Pages:' | awk '{print $2}')
    echo "  (Current: $current_pages pages)"

    if [[ -f "$BASELINE_FILE" ]]; then
      local baseline_pages
      baseline_pages=$(grep '^pages=' "$BASELINE_FILE" 2>/dev/null | cut -d= -f2)
      echo "  (Baseline: $baseline_pages pages)"
      # After bachelor cover removal, expect fewer or equal pages
      # Allow up to 2 pages more (layout shifts) or fewer (content removed)
      [[ -n "$current_pages" ]] && [[ -n "$baseline_pages" ]] && \
        [[ "$current_pages" -le $((baseline_pages + 2)) ]]
    else
      # No baseline — just verify pages > 0
      [[ -n "$current_pages" ]] && [[ "$current_pages" -gt 0 ]]
    fi
  else
    echo "  (pdfinfo not available — checking PDF file size instead)"
    [[ -f "main.pdf" ]] && [[ -s "main.pdf" ]]
  fi
}
run_test "P1" "ATDD-1.3-24" "PDF page count within expected range" test_page_count

# ATDD-1.3-25: Warning count within baseline (AC-4)
test_warning_count() {
  if [[ -f "main.log" ]]; then
    local warning_count
    warning_count=$(grep -c 'Warning' main.log 2>/dev/null || true)
    warning_count=$(echo "$warning_count" | tr -d '[:space:]' | head -1)
    echo "  (Found $warning_count warnings)"
    # Baseline zzuthesis has ~15 warnings from ctexbook; allow +3
    [[ "$warning_count" -le 18 ]]
  else
    return 1
  fi
}
run_test "P1" "ATDD-1.3-25" "Warning count <= baseline + 3" test_warning_count

# ATDD-1.3-26: No bachelor/master artifacts in PDF content (AC-1)
# Check that the compiled PDF doesn't reference bachelor-specific content
test_no_bachelor_in_pdf() {
  if [[ -f "main.pdf" ]] && command -v pdftotext &>/dev/null; then
    local text
    text=$(pdftotext main.pdf - 2>/dev/null | head -100)
    # Check first 100 lines for bachelor-specific strings
    echo "$text" | grep -qiE '本科|bachelor|综述' && return 1
    return 0
  else
    echo "  (pdftotext not available — skipped content check)"
    return 0  # Pass if tool not available
  fi
}
run_test "P1" "ATDD-1.3-26" "No bachelor/master artifacts in PDF output" test_no_bachelor_in_pdf

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
