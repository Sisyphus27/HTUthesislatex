#!/usr/bin/env bash
# test-story-1.3-unit.sh — ATDD Red-Phase Unit Tests for Story 1.3
# TDD Phase: RED (all tests expected to FAIL before implementation)
#
# Usage: bash tests/test-story-1.3-unit.sh [--run]
#   --run    Remove SKIP markers (for green-phase verification)
#
# Priority: P0 tests are blocking; P1/P2 are best-effort
# Linked Risks: E1-R2 (Branch deletion regressions, Score 6)
#               E1-R10 (Review environment residual, Score 2)

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
echo "ATDD Unit Tests: Story 1.3 — Remove bachelor/master branches"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Flag & Branch Removal Verification ==="

# ATDD-1.3-01: No \newif\ifhtu@bachelor in cls (AC-5)
test_no_bachelor_newif() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep -c 'newif\\ifhtu@bachelor' htuthesis.cls 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  echo "  (Found $count matches for \\newif\\ifhtu@bachelor)"
  [[ "$count" -eq 0 ]]
}
run_test "P0" "ATDD-1.3-01" "No \\newif\\ifhtu@bachelor in cls" test_no_bachelor_newif

# ATDD-1.3-02: No \newif\ifhtu@master in cls (AC-5)
test_no_master_newif() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep -c 'newif\\ifhtu@master' htuthesis.cls 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  echo "  (Found $count matches for \\newif\\ifhtu@master)"
  [[ "$count" -eq 0 ]]
}
run_test "P0" "ATDD-1.3-02" "No \\newif\\ifhtu@master in cls" test_no_master_newif

# ATDD-1.3-03: \htu@doctortrue is hardcoded (AC-5)
test_doctor_hardcoded_true() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q 'newif\\ifhtu@doctor\\htu@doctortrue' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-1.3-03" "\\newif\\ifhtu@doctor\\htu@doctortrue present" test_doctor_hardcoded_true

# ATDD-1.3-04: No \ifhtu@bachelor references anywhere in cls (AC-6)
test_no_bachelor_refs() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep -c 'ifhtu@bachelor' htuthesis.cls 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  echo "  (Found $count references to ifhtu@bachelor)"
  [[ "$count" -eq 0 ]]
}
run_test "P0" "ATDD-1.3-04" "No \\ifhtu@bachelor references in cls" test_no_bachelor_refs

# ATDD-1.3-05: No \ifhtu@master references anywhere in cls (AC-6)
test_no_master_refs() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep -c 'ifhtu@master' htuthesis.cls 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  echo "  (Found $count references to ifhtu@master)"
  [[ "$count" -eq 0 ]]
}
run_test "P0" "ATDD-1.3-05" "No \\ifhtu@master references in cls" test_no_master_refs

# ATDD-1.3-06: No review environment in cls (AC-2)
test_no_review_env() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep -cE 'newenvironment\{review\}|\\htu@review@title' htuthesis.cls 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  echo "  (Found $count review environment references)"
  [[ "$count" -eq 0 ]]
}
run_test "P0" "ATDD-1.3-06" "No review environment in cls" test_no_review_env

# ATDD-1.3-07: No \DeclareOption{bachelor} (AC-5)
# Clarification: Error stubs (ClassError) are acceptable defensive design
test_no_bachelor_option() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep 'DeclareOption{bachelor}' htuthesis.cls 2>/dev/null \
    | grep -v 'ClassError' | wc -l)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  echo "  (Found $count non-stub DeclareOption{bachelor})"
  [[ "$count" -eq 0 ]]
}
run_test "P0" "ATDD-1.3-07" "No functional \\DeclareOption{bachelor} in cls (error stubs ok)" test_no_bachelor_option

# ATDD-1.3-08: No \DeclareOption{master} (AC-5)
# Clarification: Error stubs (ClassError) are acceptable defensive design
test_no_master_option() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep 'DeclareOption{master}' htuthesis.cls 2>/dev/null \
    | grep -v 'ClassError' | wc -l)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  echo "  (Found $count non-stub DeclareOption{master})"
  [[ "$count" -eq 0 ]]
}
run_test "P0" "ATDD-1.3-08" "No functional \\DeclareOption{master} in cls (error stubs ok)" test_no_master_option

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Doctor-Only Content Verification ==="

# ATDD-1.3-09: \htu@subtitle hardcoded to 博士学位论文 (AC-1)
test_subtitle_hardcoded() {
  [[ -f "htuthesis.cls" ]] || return 1
  # Should find the def directly, not inside a conditional
  grep -q 'def\\htu@subtitle{博士学位论文}' htuthesis.cls 2>/dev/null
}
run_test "P1" "ATDD-1.3-09" "\\htu@subtitle hardcoded to 博士学位论文" test_subtitle_hardcoded

# ATDD-1.3-10: No bachelor cover block (zzubachelor reference removed) (AC-1)
test_no_bachelor_cover() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep -c 'zzubachelor\|bachelor@title@pre' htuthesis.cls 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  echo "  (Found $count bachelor cover references)"
  [[ "$count" -eq 0 ]]
}
run_test "P1" "ATDD-1.3-10" "No bachelor cover block in cls" test_no_bachelor_cover

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: Framework Preservation ==="

# ATDD-1.3-11: \DeclareOption{doctor} still present (backward compat)
test_doctor_option_preserved() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q 'DeclareOption{doctor}' htuthesis.cls 2>/dev/null
}
run_test "P2" "ATDD-1.3-11" "\\DeclareOption{doctor} preserved for backward compat" test_doctor_option_preserved

# ATDD-1.3-12: No \begin{review} in main.tex
test_no_review_in_main() {
  [[ -f "main.tex" ]] || return 1
  local count
  count=$(grep -c 'begin{review}' main.tex 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  echo "  (Found $count \\begin{review} in main.tex)"
  [[ "$count" -eq 0 ]]
}
run_test "P2" "ATDD-1.3-12" "No \\begin{review} in main.tex" test_no_review_in_main

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
