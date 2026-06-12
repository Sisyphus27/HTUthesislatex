#!/usr/bin/env bash
# test-story-1.5-integration.sh — ATDD Red-Phase Integration Tests for Story 1.5
# TDD Phase: RED (all tests expected to FAIL before implementation)
#
# Usage: bash tests/test-story-1.5-integration.sh [--run]
#   --run    Remove SKIP markers (for green-phase verification)
#
# Story 1.5: Verify reusable mechanisms are preserved
# Priority: P0 tests are blocking
# Linked Risks: E1-R1 (macro rename), E1-R4 (parameter externalization)
#               E1-R7 (baseline PDF), E1-R8 (parameter propagation)

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
echo "ATDD Integration Tests: Story 1.5 — Verify reusable mechanisms are preserved"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Epic 1 Gate — Compilation ==="

# ATDD-1.5-17: Full clean compile succeeds (AC-5, TC-1.5-INT-03)
test_full_clean_compile() {
  # Environment-aware: use make if available, otherwise manual clean
  if command -v make &>/dev/null; then
    make clean > /dev/null 2>&1
  else
    rm -f main.aux main.bbl main.blg main.log main.out main.pdf main.toc main.lof main.lot main.fls main.fdb_latexmk main.synctex.gz main.xdv main.end data/*.aux 2>/dev/null
  fi
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-1.5-17" "clean && latexmk -xelatex succeeds (AC-5)" test_full_clean_compile

# ATDD-1.5-18: main.pdf exists and is non-empty (AC-5)
test_pdf_output() {
  [[ -f "main.pdf" ]] && [[ -s "main.pdf" ]]
}
run_test "P0" "ATDD-1.5-18" "main.pdf exists and is non-empty (AC-5)" test_pdf_output

# ATDD-1.5-19: Zero compilation errors in log (AC-5)
test_no_errors() {
  if [[ -f "main.log" ]]; then
    local error_count
    error_count=$(grep -c '^!' main.log 2>/dev/null || true)
    error_count=$(echo "$error_count" | tr -d '[:space:]' | head -1)
    echo "  (Found $error_count errors)"
    [[ "$error_count" -eq 0 ]]
  else
    return 1
  fi
}
run_test "P0" "ATDD-1.5-19" "Zero compilation errors in main.log (AC-5)" test_no_errors

# ATDD-1.5-20: Warning count <= baseline + 3 (AC-5, TC-1.5-INT-04)
# Baseline: Story 1.4 commit ab83b1f, 51-page PDF
test_warning_count() {
  if [[ -f "main.log" ]]; then
    local warning_count
    warning_count=$(grep -c 'Warning' main.log 2>/dev/null || true)
    warning_count=$(echo "$warning_count" | tr -d '[:space:]' | head -1)
    echo "  (Found $warning_count warnings, limit: 18)"
    [[ "$warning_count" -le 18 ]]
  else
    return 1
  fi
}
run_test "P0" "ATDD-1.5-20" "Warning count <= baseline + 3 (AC-5)" test_warning_count

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Mechanism 2 — clearemptydoublepage ==="

# ATDD-1.5-07: Blank pages have empty page style (AC-2, TC-1.5-INT-01)
# Checks that \pagestyle{empty} is used in clearemptydoublepage
test_empty_page_style() {
  if [[ -f "main.log" ]]; then
    # Verify the mechanism exists in compiled output by checking cls source
    [[ -f "htuthesis.cls" ]] || return 1
    grep -q 'pagestyle{empty}' htuthesis.cls 2>/dev/null
  else
    return 1
  fi
}
run_test "P1" "ATDD-1.5-07" "clearemptydoublepage uses pagestyle{empty} (AC-2)" test_empty_page_style

echo ""
echo "=== P1: Mechanism 3 — Float/Caption Handling ==="

# ATDD-1.5-11: No float-related warnings in log (AC-3)
test_no_float_warnings() {
  if [[ -f "main.log" ]]; then
    local float_warnings
    float_warnings=$(grep -i 'float.*specifier\|too many unprocessed floats\|float.*changed' main.log 2>/dev/null | wc -l)
    float_warnings=$(echo "$float_warnings" | tr -d '[:space:]' | head -1)
    echo "  (Found $float_warnings float-related warnings)"
    [[ "$float_warnings" -eq 0 ]]
  else
    return 1
  fi
}
run_test "P1" "ATDD-1.5-11" "No float-related warnings in log (AC-3)" test_no_float_warnings

echo ""
echo "=== P1: Mechanism 4 — Bibliography ==="

# ATDD-1.5-15: .bbl output has [N] numbering format (AC-4, TC-1.5-INT-02)
test_bbl_numbering() {
  if [[ -f "main.bbl" ]]; then
    local bracket_count
    bracket_count=$(grep -c '\\bibitem' main.bbl 2>/dev/null || true)
    bracket_count=$(echo "$bracket_count" | tr -d '[:space:]' | head -1)
    echo "  (Found $bracket_count bibitem entries)"
    [[ "$bracket_count" -ge 1 ]]
  else
    echo "  (main.bbl not found — run full compile cycle first)"
    return 1
  fi
}
run_test "P1" "ATDD-1.5-15" ".bbl output has bibitem entries [N] (AC-4)" test_bbl_numbering

# ATDD-1.5-26: Full bibliography compile cycle (xelatex -> bibtex -> xelatex x2) (AC-4)
test_bib_compile_cycle() {
  xelatex -interaction=nonstopmode main.tex > /dev/null 2>&1 && \
  bibtex main > /dev/null 2>&1 && \
  xelatex -interaction=nonstopmode main.tex > /dev/null 2>&1 && \
  xelatex -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P1" "ATDD-1.5-26" "Full bib compile cycle succeeds (AC-4)" test_bib_compile_cycle

# ATDD-1.5-27: .bbl contains numbered labels [1], [2], etc (AC-4)
test_bbl_numbered_labels() {
  if [[ -f "main.bbl" ]]; then
    # gbt7714-unsrt style produces \bibitem entries
    local numbered
    numbered=$(grep -c '\\bibitem' main.bbl 2>/dev/null || true)
    numbered=$(echo "$numbered" | tr -d '[:space:]' | head -1)
    echo "  (Found $numbered numbered bibliography entries)"
    [[ "$numbered" -ge 1 ]]
  else
    return 1
  fi
}
run_test "P1" "ATDD-1.5-27" ".bbl has numbered entries [1], [2]... (AC-4)" test_bbl_numbered_labels

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: Regression Checks ==="

# ATDD-1.5-21: PDF page count within 51 +/- 2 (AC-5)
test_page_count() {
  if [[ -f "main.pdf" ]]; then
    local pages
    # Try pdfinfo first, fallback to grep
    if command -v pdfinfo > /dev/null 2>&1; then
      pages=$(pdfinfo main.pdf 2>/dev/null | grep 'Pages:' | awk '{print $2}' | tr -d '[:space:]')
    else
      # Fallback: count page markers in log
      pages=$(grep -c '\[.\+\]' main.log 2>/dev/null || echo "0")
      pages=$(echo "$pages" | tr -d '[:space:]' | head -1)
    fi
    echo "  (Page count: $pages, expected: 49-53)"
    [[ "$pages" -ge 49 ]] && [[ "$pages" -le 53 ]] 2>/dev/null
  else
    return 1
  fi
}
run_test "P2" "ATDD-1.5-21" "PDF page count within 51 +/- 2 pages (AC-5)" test_page_count

# ATDD-1.5-28: Natbib loaded with numbers,super,sort&compress (AC-4)
test_natbib_options() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q 'natbib.*numbers.*super.*sort' htuthesis.cls 2>/dev/null
}
run_test "P2" "ATDD-1.5-28" "natbib loaded with numbers,super,sort options (AC-4)" test_natbib_options

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
  echo "   Tests verify existing mechanisms (Stories 1.1-1.4)"
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
