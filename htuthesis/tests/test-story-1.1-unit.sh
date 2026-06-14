#!/usr/bin/env bash
# test-story-1.1-unit.sh — ATDD Red-Phase Unit Tests for Story 1.1
# TDD Phase: RED (all tests expected to FAIL before implementation)
#
# Usage: bash tests/test-story-1.1-unit.sh [--run]
#   --run    Remove SKIP markers (for green-phase verification)
#
# Priority: P0 tests are blocking; P1/P2 are best-effort
# Linked Risk: E1-R1 (Macro rename misses, Score 6)

set -uo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DIR"

# --- TDD Red Phase Control ---
# Set to "1" to skip all tests (RED phase). Set to "0" or pass --run to activate.
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
echo "ATDD Unit Tests: Story 1.1 — Rename to htuthesis"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Blocking Tests ==="

# ATDD-1.1-01: htuthesis.cls exists and is non-empty
test_cls_exists() {
  [[ -f "htuthesis.cls" ]] && [[ -s "htuthesis.cls" ]]
}
run_test "P0" "ATDD-1.1-01" "htuthesis.cls exists and is non-empty" test_cls_exists

# ATDD-1.1-02: htuthesis.bst exists and is non-empty
test_bst_exists() {
  [[ -f "htuthesis.bst" ]] && [[ -s "htuthesis.bst" ]]
}
run_test "P0" "ATDD-1.1-02" "htuthesis.bst exists and is non-empty" test_bst_exists

# ATDD-1.1-03: Zero \zzu@ in htuthesis.cls (AC-2, AC-8)
test_zero_zzu_at() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep -c 'zzu@' htuthesis.cls 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  [[ "$count" -eq 0 ]]
}
run_test "P0" "ATDD-1.1-03" "grep -c 'zzu@' htuthesis.cls = 0" test_zero_zzu_at

# ATDD-1.1-04: \htu@ count >= 221 in htuthesis.cls (AC-2)
test_htu_at_count() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep -c 'htu@' htuthesis.cls 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  [[ "$count" -ge 221 ]]
}
run_test "P0" "ATDD-1.1-04" "grep -c 'htu@' htuthesis.cls >= 221" test_htu_at_count

# ATDD-1.1-05: \ProvidesClass{htuthesis} present (AC-3)
test_provides_class() {
  grep -q 'ProvidesClass{htuthesis}' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-1.1-05" "ProvidesClass{htuthesis} in cls" test_provides_class

# ATDD-1.1-06: \def\htuthesis{HtuThesis} present (AC-3)
test_def_htuthesis() {
  grep -q 'def\\htuthesis{HtuThesis}' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-1.1-06" "def\htuthesis{HtuThesis} in cls" test_def_htuthesis

# ATDD-1.1-07: \ClassError{htuthesis} present (AC-3)
test_class_error() {
  grep -q 'ClassError{htuthesis}' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-1.1-07" "ClassError{htuthesis} in cls" test_class_error

# ATDD-1.1-08: SUPERSEDED by Story 2.2 — 2.2 用 \fancypagestyle{htu@...} 取代了 \ps@htu@。
# 本测试意图（"页面样式已重命名为 htu@"，AC-4）现由 ATDD-2.2-07 正面覆盖
# （断言 3 个 \fancypagestyle{htu@empty/plain/headings} 存在）。
# 本测试的断言（ps@htu@ >= 3）与 ATDD-2.2-06（\def\ps@htu@ = 0）直接冲突，故退役。
# 冲突解决依据：Epic 2 回顾 Decision 2（保留最新 story 现实 + 可追溯性）。2026-06-14。
# test_page_styles() {
#   local count
#   count=$(grep -c 'ps@htu@' htuthesis.cls 2>/dev/null || echo "0")
#   [[ "$count" -ge 3 ]]
# }
# run_test "P0" "ATDD-1.1-08" "ps@htu@ styles (>= 3) in cls" test_page_styles

# ATDD-1.1-09: main.tex uses \documentclass[doctor]{htuthesis} (AC-5)
test_main_documentclass() {
  grep -q 'documentclass\[doctor\]{htuthesis}' main.tex 2>/dev/null
}
run_test "P0" "ATDD-1.1-09" "main.tex uses documentclass[doctor]{htuthesis}" test_main_documentclass

# ATDD-1.1-10: main.tex references htuthesis.bst (AC-5)
test_main_bst() {
  grep -q 'htuthesis.bst' main.tex 2>/dev/null
}
run_test "P0" "ATDD-1.1-10" "main.tex references htuthesis.bst" test_main_bst

# ATDD-1.1-11: Comprehensive zero zzu@ across all source files (AC-8)
test_comprehensive_zero_zzu() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep -r 'zzu@' . --include="*.cls" --include="*.tex" --include="*.bst" --include="*.sty" 2>/dev/null | grep -v 'data/' | wc -l)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  [[ "$count" -eq 0 ]]
}
run_test "P0" "ATDD-1.1-11" "grep -r 'zzu@' source files = 0 matches" test_comprehensive_zero_zzu

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Critical Path Tests ==="

# ATDD-1.1-14: Makefile PACKAGE = htuthesis (AC-6)
test_makefile_package() {
  grep -q 'PACKAGE = htuthesis' Makefile 2>/dev/null
}
run_test "P1" "ATDD-1.1-14" "Makefile PACKAGE = htuthesis" test_makefile_package

# ATDD-1.1-15: bst file header references htuthesis (Edge)
test_bst_header() {
  grep -q "This is file.*htuthesis.bst" htuthesis.bst 2>/dev/null
}
run_test "P1" "ATDD-1.1-15" "bst header identifies as htuthesis.bst" test_bst_header

# ATDD-1.1-16: \hyphenation{Htu-Thesis} updated (AC-3)
test_hyphenation() {
  grep -q 'hyphenation{Htu-Thesis}' htuthesis.cls 2>/dev/null
}
run_test "P1" "ATDD-1.1-16" "hyphenation{Htu-Thesis} in cls" test_hyphenation

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: Secondary Tests ==="

# ATDD-1.1-17: README.md header (AC-7)
test_readme_header() {
  grep -q '^# htuthesis' README.md 2>/dev/null
}
run_test "P2" "ATDD-1.1-17" "README.md header = # htuthesis" test_readme_header

# ATDD-1.1-18: \ifhtu@bachelor should NOT exist in main.tex (AC-5)
# Superseded by Story 1.3: bachelor references intentionally removed
test_main_bachelor_ref() {
  [[ -f "main.tex" ]] || return 1
  local count
  count=$(grep -c 'ifhtu@bachelor' main.tex 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  [[ "$count" -eq 0 ]]
}
run_test "P2" "ATDD-1.1-18" "main.tex has no ifhtu@bachelor (superseded by Story 1.3)" test_main_bachelor_ref

# ATDD-1.1-19: .chktexrc does not reference zzuthesis (Edge)
test_chktexrc() {
  if [[ -f ".chktexrc" ]]; then
    ! grep -q 'zzuthesis\|zzu' .chktexrc 2>/dev/null
  else
    return 0  # File may not exist, skip gracefully
  fi
}
run_test "P2" "ATDD-1.1-19" ".chktexrc has no zzuthesis references" test_chktexrc

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
