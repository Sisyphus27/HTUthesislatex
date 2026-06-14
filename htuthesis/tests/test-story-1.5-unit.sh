#!/usr/bin/env bash
# test-story-1.5-unit.sh — ATDD Red-Phase Unit Tests for Story 1.5
# TDD Phase: RED (all tests expected to FAIL before implementation)
#
# Usage: bash tests/test-story-1.5-unit.sh [--run]
#   --run    Remove SKIP markers (for green-phase verification)
#
# Story 1.5: Verify reusable mechanisms are preserved
# Priority: P0 tests are blocking; P1/P2 are best-effort
# Linked Risks: E1-R1 (macro rename), E1-R4 (parameter externalization)

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
echo "ATDD Unit Tests: Story 1.5 — Verify reusable mechanisms are preserved"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Epic 1 Gate — Zero Residual ==="

# ATDD-1.5-22: Zero ZZU macro residual (carry-forward from Story 1.1, TC-1.1-UNIT-01)
test_zero_zzu_macros() {
  local count
  count=$(grep -r 'zzu@' htuthesis.cls htuthesis.def main.tex 2>/dev/null | wc -l)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  echo "  (Found $count zzu@ macro references)"
  [[ "$count" -eq 0 ]]
}
run_test "P0" "ATDD-1.5-22" "Zero zzu@ macro residual in cls/def/main.tex" test_zero_zzu_macros

# ATDD-1.5-23: Zero ZZU identity residual (carry-forward from Story 1.4, TC-1.4-UNIT-01)
test_zero_zzu_identity() {
  local count
  count=$(grep -ri '郑州大学\|Zhengzhou\|ZZU\|zzu' htuthesis.cls htuthesis.def main.tex 2>/dev/null \
    | grep -v 'zzuthesis.*原始\|zzuthesis.*真值来源\|zzuthesis.*provenance\|zzuthesis.*来源' \
    | wc -l)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  echo "  (Found $count ZZU identity matches)"
  [[ "$count" -eq 0 ]]
}
run_test "P0" "ATDD-1.5-23" "Zero ZZU identity residual in cls/def/main.tex" test_zero_zzu_identity

# ATDD-1.5-24: htuthesis.cls exists and is non-empty (gate prerequisite)
test_cls_exists() {
  [[ -f "htuthesis.cls" ]] && [[ -s "htuthesis.cls" ]]
}
run_test "P0" "ATDD-1.5-24" "htuthesis.cls exists and non-empty" test_cls_exists

# ATDD-1.5-25: htuthesis.def exists and is non-empty (gate prerequisite)
test_def_exists() {
  [[ -f "htuthesis.def" ]] && [[ -s "htuthesis.def" ]]
}
run_test "P0" "ATDD-1.5-25" "htuthesis.def exists and non-empty" test_def_exists

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Mechanism 1 — Font-Size Definition System ==="

# ATDD-1.5-01: htu@def@fontsize macro exists in cls (AC-1)
test_fontsize_macro() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\def\\htu@def@fontsize' htuthesis.cls 2>/dev/null
}
run_test "P1" "ATDD-1.5-01" "htu@def@fontsize macro exists in cls (AC-1)" test_fontsize_macro

# ATDD-1.5-02: All 18 font size commands defined (AC-1)
test_all_font_commands() {
  [[ -f "htuthesis.cls" ]] || return 1
  local commands="chuhao xiaochu yihao xiaoyi erhao xiaoer sanhao xiaosan sihao banxiaosi xiaosi dawu wuhao xiaowu liuhao xiaoliu qihao bahao"
  local missing=0
  for cmd in $commands; do
    if ! grep -q "\\htu@def@fontsize{$cmd}" htuthesis.cls 2>/dev/null; then
      echo "  (Missing: $cmd)"
      ((missing++))
    fi
  done
  echo "  (Missing $missing/18 font size commands)"
  [[ "$missing" -eq 0 ]]
}
run_test "P1" "ATDD-1.5-02" "All 18 font size commands defined in cls (AC-1)" test_all_font_commands

# ATDD-1.5-03: normalsize uses @setfontsize with .def params (AC-1, R-3 CJK trap)
test_normalsize_setfontsize() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\@setfontsize\\normalsize{\\htu@body@fontsize}{\\htu@body@baselineskip}' htuthesis.cls 2>/dev/null
}
run_test "P1" "ATDD-1.5-03" "normalsize uses @setfontsize with .def params (AC-1)" test_normalsize_setfontsize

echo ""
echo "=== P1: Mechanism 2 — clearemptydoublepage ==="

# ATDD-1.5-05: SUPERSEDED by Story 2.2 — 2.2 移植 CTEXcleardoublepage（\def\cleardoublepage +
# \thispagestyle{empty}），移除了 \htu@clearemptydoublepage。
# 本测试意图（"空白页清空机制完整"，AC-2）现由 ATDD-2.2-12 正面覆盖。
# 本测试的断言（htu@clearemptydoublepage >= 2）与 ATDD-2.2-08（= 0）直接冲突，故退役。
# 冲突解决依据：Epic 2 回顾 Decision 2（保留最新 story 现实 + 可追溯性）。2026-06-14。
# test_clearemptydoublepage_impl() {
#   [[ -f "htuthesis.cls" ]] || return 1
#   local count
#   count=$(grep -c 'htu@clearemptydoublepage' htuthesis.cls 2>/dev/null || true)
#   count=$(echo "$count" | tr -d '[:space:]' | head -1)
#   echo "  (Found $count htu@clearemptydoublepage references)"
#   [[ "$count" -ge 2 ]]
# }
# run_test "P1" "ATDD-1.5-05" "clearemptydoublepage implementation intact in cls (AC-2)" test_clearemptydoublepage_impl

# ATDD-1.5-06: frontmatter/mainmatter/backmatter call cleardoublepage (AC-2)
test_matter_cleardoublepage() {
  [[ -f "htuthesis.cls" ]] || return 1
  local front main back
  front=$(grep -A2 '\\renewcommand\\frontmatter' htuthesis.cls 2>/dev/null | grep -c 'cleardoublepage' || true)
  main=$(grep -A2 '\\renewcommand\\mainmatter' htuthesis.cls 2>/dev/null | grep -c 'cleardoublepage' || true)
  back=$(grep -A2 '\\renewcommand\\backmatter' htuthesis.cls 2>/dev/null | grep -c 'cleardoublepage' || true)
  echo "  (frontmatter: $front, mainmatter: $main, backmatter: $back cleardoublepage calls)"
  [[ "$front" -ge 1 ]] && [[ "$main" -ge 1 ]] && [[ "$back" -ge 1 ]]
}
run_test "P1" "ATDD-1.5-06" "frontmatter/mainmatter/backmatter call cleardoublepage (AC-2)" test_matter_cleardoublepage

echo ""
echo "=== P1: Mechanism 3 — Float/Caption Handling ==="

# ATDD-1.5-08: Float parameters reference .def variables (AC-3)
test_float_def_params() {
  [[ -f "htuthesis.cls" ]] || return 1
  local params="htu@floatsep htu@textfraction htu@topfraction htu@bottomfraction htu@floatpagefraction"
  local found=0
  for p in $params; do
    if grep -q "\\$p" htuthesis.cls 2>/dev/null; then
      ((found++))
    else
      echo "  (Missing .def ref: $p)"
    fi
  done
  echo "  (Found $found/5 .def float parameter references)"
  [[ "$found" -eq 5 ]]
}
run_test "P1" "ATDD-1.5-08" "Float parameters reference .def variables (AC-3)" test_float_def_params

# ATDD-1.5-09: captionsetup intact with correct options (AC-3)
test_captionsetup() {
  [[ -f "htuthesis.cls" ]] || return 1
  local labelsep font position
  labelsep=$(grep -c 'labelsep.*=.*htu' htuthesis.cls 2>/dev/null || true)
  font=$(grep -c 'font.*=.*htu' htuthesis.cls 2>/dev/null || true)
  position=$(grep -c 'figureposition.*=.*bottom' htuthesis.cls 2>/dev/null || true)
  echo "  (labelsep: $labelsep, font: $font, figureposition: $position)"
  [[ "$labelsep" -ge 1 ]] && [[ "$font" -ge 1 ]] && [[ "$position" -ge 1 ]]
}
run_test "P1" "ATDD-1.5-09" "captionsetup intact with correct options (AC-3)" test_captionsetup

# ATDD-1.5-16: Superscript citation style active (natbib NAT@citesuper) (AC-4)
test_superscript_citation() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q 'NAT@citesuper' htuthesis.cls 2>/dev/null
}
run_test "P1" "ATDD-1.5-16" "Superscript citation style active in cls (AC-4)" test_superscript_citation

echo ""
echo "=== P1: Mechanism 4 — Bibliography Style ==="

# ATDD-1.5-12: htuthesis.bst exists (AC-4)
test_bst_exists() {
  [[ -f "htuthesis.bst" ]] && [[ -s "htuthesis.bst" ]]
}
run_test "P1" "ATDD-1.5-12" "htuthesis.bst exists and non-empty (AC-4)" test_bst_exists

# ATDD-1.5-13: bibliographystyle reference in main.tex (AC-4)
test_bibliographystyle_ref() {
  [[ -f "main.tex" ]] || return 1
  grep -q 'bibliographystyle{htuthesis}' main.tex 2>/dev/null
}
run_test "P1" "ATDD-1.5-13" "bibliographystyle{htuthesis} in main.tex (AC-4)" test_bibliographystyle_ref

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: Detailed Mechanism Verification ==="

# ATDD-1.5-04: Font size values match spec (42bp through 5bp) (AC-1)
test_fontsize_values() {
  [[ -f "htuthesis.cls" ]] || return 1
  local expected="42bp 36bp 26bp 24bp 22bp 18bp 16bp 15bp 14bp 13bp 12bp 11bp 10.5bp 9bp 7.5bp 6.5bp 5.5bp 5bp"
  local count=0
  local missing=0
  for val in $expected; do
    if grep -q "{$val}" htuthesis.cls 2>/dev/null; then
      ((count++))
    else
      echo "  (Missing value: $val)"
      ((missing++))
    fi
  done
  echo "  (Found $count/18 expected font size values)"
  [[ "$missing" -eq 0 ]]
}
run_test "P2" "ATDD-1.5-04" "Font size values match spec 42bp..5bp (AC-1)" test_fontsize_values

# ATDD-1.5-10: subcaption package loaded with labelformat=simple (AC-3)
test_subcaption() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q 'subcaption.*labelformat=simple' htuthesis.cls 2>/dev/null
}
run_test "P2" "ATDD-1.5-10" "subcaption loaded with labelformat=simple (AC-3)" test_subcaption

# ATDD-1.5-14: thebibliography uses wuhao[1.524] font (AC-4)
test_bibliography_font() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q 'wuhao\[1.524\]' htuthesis.cls 2>/dev/null
}
run_test "P2" "ATDD-1.5-14" "thebibliography uses wuhao[1.524] font (AC-4)" test_bibliography_font

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
