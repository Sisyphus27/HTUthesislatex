#!/usr/bin/env bash
# test-story-3.1-unit.sh — ATDD Red-Phase Unit Tests for Story 3.1 (doctoral cover page)
# TDD Phase: RED (source-level greps; metadata-label / field-label / no-corner-logo tests FAIL on
#            pre-impl; regression guards pass)
#
# Usage: bash tests/test-story-3.1-unit.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 tests are blocking
# Linked ACs: AC-1 (metadata labels), AC-5 (5 field labels), AC-2 (no corner logo)
# Linked Risk: R-1 (geometry, regression guard), R-3 (baselineskip, regression guard)
# TC-E3-09 (cover-geometry coupling, P1)
#
# NOTE: these are SOURCE-LEVEL greps — they prove the cls/def CONTAIN the right definitions.
# The companion integration test (test-story-3.1-integration.sh) proves the RENDERED cover via
# fitz (element presence, ±3mm positions, fonts). Source-greps prove the labels are DEFINED;
# fitz proves they RENDER at the right place/size (Story 2.5/2.6/3.9 behavior-test lesson).
# Tests are READ-ONLY — they MUST NOT modify the SUT (Epic 1/2 retro lesson).

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
echo "ATDD Unit Tests: Story 3.1 — Doctoral cover page"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: metadata labels + field labels (RED pre-impl) ==="

# ATDD-3.1-01: metadata labels = 单位代码 / 学号 / 分类号 (AC-1, TC-E3-06)
# Truth source: reference PDF page 2 ("单位代码10476", "学号***", "分类号D669.3") + spec §1.1.1
#   (分类号 via 《中国图书馆图书分类法》) + .doc blank form.
# Pre-impl (cls:163-165): 学校代码 / 学号或申请号 / 密级 → all 3 exact-target defs absent → RED.
# Post-impl (Task 1.1): the three label macros are relabeled → GREEN.
# Uses literal {label} so 学号 does NOT substring-match 学号或申请号 (the trailing } excludes it).
test_metadata_labels() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -E 'schoolcode@title\{单位代码\}' htuthesis.cls >/dev/null && \
  grep -E 'id@title\{学号\}' htuthesis.cls >/dev/null && \
  grep -E 'secretlevel@title\{分类号\}' htuthesis.cls >/dev/null
}
run_test "P0" "ATDD-3.1-01" "metadata labels = 单位代码/学号/分类号 (AC-1, TC-E3-06; RED — pre-impl 学校代码/学号或申请号/密级)" test_metadata_labels

# ATDD-3.1-02: 5 field labels present — 学科、专业 / 研究方向 / 申请学位类别 / 申请人 / 指导教师 (AC-5, TC-E3-06)
# Truth source: reference PDF page 2 (5 field rows exactly these labels).
# Pre-impl (cls:167-171): 作者姓名/导师姓名/学科门类/专业名称/完成时间 — NONE of the 5 target labels
#   (申请人/指导教师/研究方向/申请学位类别/学科、专业) are defined → RED.
# Post-impl (Task 4.1-4.2): labels relabeled + 研究方向/申请学位类别 added → GREEN.
test_field_labels() {
  [[ -f "htuthesis.cls" ]] || return 1
  # 申请人, 指导教师, 研究方向, 申请学位类别 present as rendered labels.
  # 学科、专业 = combined field (full-width comma U+3001 between 学科 and 专业).
  grep -q '申请人' htuthesis.cls && \
  grep -q '指导教师' htuthesis.cls && \
  grep -q '研究方向' htuthesis.cls && \
  grep -q '申请学位类别' htuthesis.cls && \
  grep -q '学科、专业' htuthesis.cls
}
run_test "P0" "ATDD-3.1-02" "5 field labels present (学科、专业/研究方向/申请学位类别/申请人/指导教师) (AC-5, TC-E3-06; RED pre-impl)" test_field_labels

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: no-corner-logo + regression guards ==="

# ATDD-3.1-03: NO top-left corner logo on the doctoral cover (AC-2, R-9 baseline)
# Truth source: reference PDF page 2 has NO corner logo (only the centered calligraphic name image).
# Pre-impl (cls:556): \includegraphics[width=3.35cm]{htu-logo} inside \htu@first@titlepage → present → RED.
# Post-impl (Task 1.2): corner logo removed; only the centered htu-text-logo remains → GREEN.
test_no_corner_logo() {
  [[ -f "htuthesis.cls" ]] || return 1
  # The corner-logo line must be GONE from the cls. Pre-impl it is present (1 match) → RED.
  local n
  n=$(grep -c 'includegraphics\[width=3.35cm\]{htu-logo}' htuthesis.cls 2>/dev/null || true)
  n=$(echo "$n" | tr -d '[:space:]' | head -1)
  echo "  (corner-logo 'width=3.35cm{htu-logo}' matches: $n; expect 0 post-impl, 1 pre-impl)"
  [[ "$n" -eq 0 ]]
}
run_test "P1" "ATDD-3.1-03" "no top-left corner logo on doctoral cover (AC-2, R-9 baseline; RED pre-impl cls:556)" test_no_corner_logo

# ATDD-3.1-04: regression — \htu@topmargin{22mm} in .def unchanged (R-1, AC-10)
# Cover rewrite must NOT alter page geometry (cover positions are paper-relative, not geometry-relative).
test_geometry_topmargin() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q 'htu@topmargin{22mm}' htuthesis.def
}
run_test "P1" "ATDD-3.1-04" "regression: \htu@topmargin{22mm} in .def unchanged (R-1, AC-10)" test_geometry_topmargin

# ATDD-3.1-05: regression — \htu@body@baselineskip{18bp} in .def unchanged (R-3, AC-10)
# Cover rewrite must NOT touch body line spacing.
test_body_baselineskip_18bp() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q 'htu@body@baselineskip{18bp}' htuthesis.def
}
run_test "P1" "ATDD-3.1-05" "regression: \htu@body@baselineskip{18bp} in .def unchanged (R-3, AC-10)" test_body_baselineskip_18bp

# ATDD-3.1-06: regression — \htu@songtibold (L4 bold-SimSun, Story 2.5) preserved (AC-10)
test_songtibold_preserved() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q 'newCJKfontfamily\\htu@songtibold{SimSun}\[AutoFakeBold' htuthesis.cls
}
run_test "P1" "ATDD-3.1-06" "regression: \htu@songtibold (L4 bold-SimSun, Story 2.5) preserved (AC-10)" test_songtibold_preserved

# ATDD-3.1-07: regression — NO \setstretch in cls (R-3 anti-pattern, AC-10)
test_no_setstretch() {
  [[ -f "htuthesis.cls" ]] || return 1
  local n
  n=$(grep -c 'setstretch' htuthesis.cls 2>/dev/null || true)
  n=$(echo "$n" | tr -d '[:space:]' | head -1)
  echo "  (setstretch matches: $n; expect 0)"
  [[ "$n" -eq 0 ]]
}
run_test "P1" "ATDD-3.1-07" "regression: NO \setstretch in cls (R-3 anti-pattern, AC-10)" test_no_setstretch

# ATDD-3.1-08: regression — cover uses \thispagestyle{htu@empty} (no-page-number wiring intact) (AC-8, Decision 1)
# The integration test (ATDD-3.1-I04) verifies the RENDERED absence via visual signature;
# this unit guard verifies the SOURCE wiring stays in place inside \htu@first@titlepage.
test_cover_empty_pagestyle() {
  [[ -f "htuthesis.cls" ]] || return 1
  # \htu@first@titlepage must still call \thispagestyle{htu@empty} (suppresses header/footer/page-number).
  grep -q 'thispagestyle{htu@empty}' htuthesis.cls
}
run_test "P1" "ATDD-3.1-08" "regression: cover \thispagestyle{htu@empty} wiring intact (AC-8, Decision 1)" test_cover_empty_pagestyle

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: new metadata macros (RED pre-impl) ==="

# ATDD-3.1-09: new metadata macros researchdirection + degreecategory defined (AC-5, TC-E3-06)
# The 5 reference fields require two NEW user metadata macros (\researchdirection, \degreecategory)
# wired via \htu@def@term (Task 4.2). Pre-impl: neither defined → RED. Post-impl: both defined → GREEN.
test_new_metadata_macros() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q 'def@term{researchdirection}' htuthesis.cls && \
  grep -q 'def@term{degreecategory}' htuthesis.cls
}
run_test "P2" "ATDD-3.1-09" "new metadata macros (researchdirection/degreecategory) defined (AC-5; RED pre-impl)" test_new_metadata_macros

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
  echo "   ATDD-3.1-01 (metadata labels), 3.1-02 (5 field labels), 3.1-03 (no corner logo),"
  echo "   3.1-09 (new macros) FAIL until impl (pre-impl cover is the ZZU layout: 学校代码/密级/"
  echo "   作者姓名/导师姓名/学科门类/专业名称/完成时间 + corner logo)."
  echo "   Regression guards (geometry/baselineskip/songtibold/no-setstretch/empty-pagestyle) stay green."
  echo ""
  echo "   NOTE: source-greps prove the labels/macros are DEFINED; the integration test's fitz checks"
  echo "         (ATDD-3.1-I05 presence, I06 ±3mm, I07-I09 fonts) prove the cover RENDERS correctly —"
  echo "         the real AC proof. Tests are read-only — they do not modify the SUT."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
