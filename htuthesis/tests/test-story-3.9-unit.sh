#!/usr/bin/env bash
# test-story-3.9-unit.sh — ATDD Red-Phase Unit Tests for Story 3.9
# TDD Phase: RED (source-level greps; setmainfont/gate/CJK-decision tests FAIL on pre-impl;
#            regression guards pass)
#
# Usage: bash tests/test-story-3.9-unit.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 tests are blocking
# Linked Risk: R-13 (score 4, global TNR ripple), NFR-2 (font compat), R-3 (baselineskip regression)
# TC-E3-01 (\setmainfont + IfFontExistsTF gate), TC-E3-03 (\PackageError wiring),
# TC-E3-04 (\sffamily CJK decision), regression guards
#
# NOTE: these are SOURCE-LEVEL greps — they prove the cls/def CONTAIN the right definitions.
# The companion integration test (test-story-3.9-integration.sh) proves the RENDERED output
# via fitz (Latin font-name behavior). A source-grep that \setmainfont exists does NOT prove
# Latin text renders TNR (a later override could shadow it); the fitz check is the real proof.
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
echo "ATDD Unit Tests: Story 3.9 — Latin font calibration (Times New Roman)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: \setmainfont wiring (RED pre-impl) ==="

# ATDD-3.9-01: \setmainfont{Times New Roman} present in cls (AC-1, TC-E3-01)
# Pre-impl: NO \setmainfont anywhere (Latin = Latin Modern, deferred-work §2.5 gap) → 0 matches → RED.
# Post-impl: ≥1 match → GREEN.
test_setmainfont_present() {
  [[ -f "htuthesis.cls" ]] || return 1
  local n
  n=$(grep -c 'setmainfont{Times New Roman}' htuthesis.cls 2>/dev/null || true)
  n=$(echo "$n" | tr -d '[:space:]' | head -1)
  echo "  (setmainfont{Times New Roman} matches: $n; expect >=1 post-impl, 0 pre-impl)"
  [[ "$n" -ge 1 ]]
}
run_test "P0" "ATDD-3.9-01" "\setmainfont{Times New Roman} present in cls (AC-1, TC-E3-01)" test_setmainfont_present

# ATDD-3.9-02: \setmainfont gated by \IfFontExistsTF{Times New Roman} (AC-1, TC-E3-01, NFR-2)
# Story Task 1.1 wraps \setmainfont in \IfFontExistsTF{Times New Roman}{...}{}.
# cls:76 ALREADY has one \IfFontExistsTF{Times New Roman} (the existence check, Story 1.4).
# The new gate wrapper adds a SECOND occurrence → count goes 1 (pre-impl) → 2 (post-impl).
test_setmainfont_gated() {
  [[ -f "htuthesis.cls" ]] || return 1
  local n
  n=$(grep -c 'IfFontExistsTF{Times New Roman}' htuthesis.cls 2>/dev/null || true)
  n=$(echo "$n" | tr -d '[:space:]' | head -1)
  echo "  (IfFontExistsTF{Times New Roman} matches: $n; expect >=2 post-impl [cls:76 check + gate wrapper], 1 pre-impl)"
  [[ "$n" -ge 2 ]]
}
run_test "P0" "ATDD-3.9-02" "\setmainfont gated by \IfFontExistsTF{Times New Roman} (AC-1, TC-E3-01, NFR-2)" test_setmainfont_gated

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: \PackageError wiring + regression guards ==="

# ATDD-3.9-03: \PackageError wired for missing Times New Roman (AC-3, TC-E3-03, NFR-2)
# GREEN GUARD: cls:76-79 ALREADY wires this (Story 1.4). This test verifies it stays wired
# (AC-3 is satisfied by the existing check, not newly introduced by 3.9).
test_packageerror_wired() {
  [[ -f "htuthesis.cls" ]] || return 1
  # The TNR existence check + PackageError must both be present near cls:76-79.
  grep -q 'IfFontExistsTF{Times New Roman}' htuthesis.cls && \
  grep -q "Font 'Times New Roman' not found" htuthesis.cls && \
  grep -q 'PackageError{htuthesis}' htuthesis.cls
}
run_test "P1" "ATDD-3.9-03" "\PackageError wired for missing TNR (AC-3, TC-E3-03; GREEN guard — already cls:76-79)" test_packageerror_wired

# ATDD-3.9-05: regression — \htu@body@baselineskip{18bp} in .def unchanged (R-3)
# Font change must NOT alter body baselineskip (set via \@setfontsize, independent of \setmainfont).
test_body_baselineskip_18bp() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q 'htu@body@baselineskip{18bp}' htuthesis.def
}
run_test "P1" "ATDD-3.9-05" "regression: \htu@body@baselineskip{18bp} in .def unchanged (R-3)" test_body_baselineskip_18bp

# ATDD-3.9-06: regression — NO \setstretch in cls (R-3 anti-pattern)
# \setstretch is the CJK line-spacing trap (Epic 2 R-3); must remain absent.
test_no_setstretch() {
  [[ -f "htuthesis.cls" ]] || return 1
  # \setstretch absent (the R-3 trap). Tolerate it only inside comments is not worth the complexity —
  # the cls has never used \setstretch; any appearance is a regression.
  local n
  n=$(grep -c 'setstretch' htuthesis.cls 2>/dev/null || true)
  n=$(echo "$n" | tr -d '[:space:]' | head -1)
  echo "  (setstretch matches: $n; expect 0)"
  [[ "$n" -eq 0 ]]
}
run_test "P1" "ATDD-3.9-06" "regression: NO \setstretch in cls (R-3 anti-pattern)" test_no_setstretch

# ATDD-3.9-07: regression — \htu@songtibold (L4 bold-SimSun, Story 2.5 option A) preserved
# \setmainfont / \setCJKsansfont must NOT disturb the explicit \newCJKfontfamily family (cls:83).
test_songtibold_preserved() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q 'newCJKfontfamily\\htu@songtibold{SimSun}\[AutoFakeBold' htuthesis.cls
}
run_test "P1" "ATDD-3.9-07" "regression: \htu@songtibold (L4 bold-SimSun, Story 2.5) preserved" test_songtibold_preserved

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: \sffamily CJK decision (RED/decision pre-impl) ==="

# ATDD-3.9-04: \sffamily CJK mapping decision made (AC-4, TC-E3-04)
# Story Task 2.3 decision: EITHER (a) add \setCJKsansfont{SimHei} (reference PDF = SimHei),
# OR (b) document YaHei acceptance as a truth-source deviation.
# This test asserts the PRIMARY expected outcome (SimHei). If the dev chooses YaHei-acceptable
# (branch b), this test is repointed/retired per Decision 2 with a traceability note
# (mirrors Epic 2 cross-story-override handling).
test_sffamily_decision() {
  [[ -f "htuthesis.cls" ]] || return 1
  # Primary decision: \setCJKsansfont{SimHei} forces the spec's 黑体.
  if grep -q 'setCJKsansfont{SimHei}' htuthesis.cls; then
    echo "  (decision: setCJKsansfont{SimHei} present — headings forced to SimHei)"
    return 0
  fi
  # Documented-deviation branch: a truth-source comment in the font-setup region records YaHei
  # acceptance. Marker: a comment citing sffamily + the 黑体/YaHei decision.
  if grep -qiE 'sffamily.*CJK.*(SimHei|YaHei|黑体)|(SimHei|YaHei|黑体).*sffamily.*CJK' htuthesis.cls; then
    echo "  (decision: documented deviation — sffamily CJK mapping recorded in cls comment)"
    return 0
  fi
  echo "  (no setCJKsansfont{SimHei} AND no documented sffamily-CJK decision → RED pre-impl)"
  return 1
}
run_test "P2" "ATDD-3.9-04" "\sffamily CJK mapping decision made (AC-4, TC-E3-04)" test_sffamily_decision

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
  echo "   ATDD-3.9-01/02 (setmainfont wiring), 3.9-04 (sffamily decision) FAIL until impl"
  echo "   Compile-regression + PackageError + songtibold guards stay green"
  echo ""
  echo "   NOTE: source-greps prove definitions EXIST; the integration test's fitz Latin-font-name"
  echo "         check (ATDD-3.9-15/16/17) proves Latin text RENDERS TNR — the real AC-2 proof."
  echo "         Tests are read-only — they do not modify the SUT."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
