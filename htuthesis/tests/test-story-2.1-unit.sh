#!/usr/bin/env bash
# test-story-2.1-unit.sh — ATDD Red-Phase Unit Tests for Story 2.1
# TDD Phase: RED (all tests expected to FAIL before implementation)
#
# Usage: bash tests/test-story-2.1-unit.sh [--run]
#   --run    Remove SKIP markers (for green-phase verification)
#
# Priority: P0 tests are blocking; P1/P2 are best-effort
# Linked Risk: R-1 (CRITICAL score 9), R-6 (score 6)
# Epic 1 Retro: backslash check, no SUT modification, no cross-story conflicts

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

echo "=============================================="
echo "ATDD Unit Tests: Story 2.1 — Page Geometry Calibration"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Blocking Tests ==="

# ATDD-2.1-01: .def has \htu@topmargin{22mm} with backslash (AC-1, retro lesson)
test_def_topmargin() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '\\def\\htu@topmargin{22mm}' htuthesis.def 2>/dev/null
}
run_test "P0" "ATDD-2.1-01" ".def has \\htu@topmargin{22mm} (backslash verified)" test_def_topmargin

# ATDD-2.1-02: .def has \htu@bottommargin{17.5mm} with backslash (AC-1)
test_def_bottommargin() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '\\def\\htu@bottommargin{17.5mm}' htuthesis.def 2>/dev/null
}
run_test "P0" "ATDD-2.1-02" ".def has \\htu@bottommargin{17.5mm}" test_def_bottommargin

# ATDD-2.1-03: .def has \htu@leftmargin{25mm} with backslash (AC-1)
test_def_leftmargin() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '\\def\\htu@leftmargin{25mm}' htuthesis.def 2>/dev/null
}
run_test "P0" "ATDD-2.1-03" ".def has \\htu@leftmargin{25mm}" test_def_leftmargin

# ATDD-2.1-04: .def has \htu@rightmargin{25mm} with backslash (AC-1)
test_def_rightmargin() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '\\def\\htu@rightmargin{25mm}' htuthesis.def 2>/dev/null
}
run_test "P0" "ATDD-2.1-04" ".def has \\htu@rightmargin{25mm}" test_def_rightmargin

# ATDD-2.1-05: .def has \htu@headerheight{5.6mm} (recalibrated in Story 2.3: clears the
#   fancyhdr headheight warning introduced by reconnecting \headruleskip, and aligns the
#   header-rule position with the reference thesis measured 27.5mm; approved change)
test_def_headerheight() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '\\def\\htu@headerheight{5.6mm}' htuthesis.def 2>/dev/null
}
run_test "P0" "ATDD-2.1-05" ".def has \\htu@headerheight{5.6mm} (Story 2.3 recalibration)" test_def_headerheight

# ATDD-2.1-06: .def has \htu@footskip{7.5mm} with backslash (AC-2)
test_def_footskip() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '\\def\\htu@footskip{7.5mm}' htuthesis.def 2>/dev/null
}
run_test "P0" "ATDD-2.1-06" ".def has \\htu@footskip{7.5mm}" test_def_footskip

# ATDD-2.1-07: cls geometry uses includeheadfoot mode (AC-1)
test_cls_includeheadfoot() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q 'includeheadfoot' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.1-07" "cls geometry uses includeheadfoot" test_cls_includeheadfoot

# ATDD-2.1-08: cls geometry uses all 7 .def variable references (AC-6)
test_cls_six_def_refs() {
  [[ -f "htuthesis.cls" ]] || return 1
  local refs_found=0
  grep -q 'top=\\htu@topmargin' htuthesis.cls 2>/dev/null && ((refs_found++))
  grep -q 'bottom=\\htu@bottommargin' htuthesis.cls 2>/dev/null && ((refs_found++))
  grep -q 'left=\\htu@leftmargin' htuthesis.cls 2>/dev/null && ((refs_found++))
  grep -q 'right=\\htu@rightmargin' htuthesis.cls 2>/dev/null && ((refs_found++))
  grep -q 'headheight=\\htu@headerheight' htuthesis.cls 2>/dev/null && ((refs_found++))
  grep -q 'headsep=\\htu@headsep' htuthesis.cls 2>/dev/null && ((refs_found++))
  grep -q 'footskip=\\htu@footskip' htuthesis.cls 2>/dev/null && ((refs_found++))
  [[ "$refs_found" -eq 7 ]]
}
run_test "P0" "ATDD-2.1-08" "cls geometry uses all 7 .def variables (top/bottom/left/right/headheight/headsep/footskip)" test_cls_six_def_refs

# ATDD-2.1-09: No ignoreall in cls (AC-1 negative — replaced by includeheadfoot)
test_no_ignoreall() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep -c 'ignoreall' htuthesis.cls 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  [[ "$count" -eq 0 ]]
}
run_test "P0" "ATDD-2.1-09" "cls has no ignoreall (replaced by includeheadfoot)" test_no_ignoreall

# ATDD-2.1-10: No hcentering or vcentering in cls (AC-1 negative)
test_no_centering() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep -c 'hcentering\|vcentering' htuthesis.cls 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  [[ "$count" -eq 0 ]]
}
run_test "P0" "ATDD-2.1-10" "cls has no hcentering/vcentering" test_no_centering

# ATDD-2.1-11: Zero hardcoded dimension values in cls geometry call (AC-6)
test_no_hardcoded_dims() {
  [[ -f "htuthesis.cls" ]] || return 1
  # Extract geometry block and check for raw mm/cm/pt values (not preceded by \htu@)
  local geo_block
  geo_block=$(sed -n '/\\geometry{/,/}/p' htuthesis.cls 2>/dev/null)
  # Should NOT contain patterns like "=25mm" or "=30mm" etc. (hardcoded values)
  echo "$geo_block" | grep -qP '=\d+(\.\d+)?mm' && return 1
  echo "$geo_block" | grep -qP '=\d+(\.\d+)?cm' && return 1
  echo "$geo_block" | grep -qP '=\d+(\.\d+)?pt' && return 1
  return 0
}
run_test "P0" "ATDD-2.1-11" "cls geometry has zero hardcoded dimension values" test_no_hardcoded_dims

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Critical Path Tests ==="

# ATDD-2.1-12: No bindingoffset in cls geometry (AC-3)
test_no_bindingoffset() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep -c 'bindingoffset' htuthesis.cls 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  [[ "$count" -eq 0 ]]
}
run_test "P1" "ATDD-2.1-12" "cls has no bindingoffset (AC-3: no binding offset)" test_no_bindingoffset

# ATDD-2.1-13: All new .def params have truth-source comments (NFR-3)
test_truth_source_comments() {
  [[ -f "htuthesis.def" ]] || return 1
  local comment_count=0
  # Each new parameter section should have "HTU" or "格式要求" in nearby comment
  grep -B1 'htu@bottommargin\|htu@rightmargin\|htu@headerheight\|htu@footskip\|htu@headsep' htuthesis.def 2>/dev/null | grep -q 'HTU\|格式要求\|推导' && ((comment_count++))
  grep -B3 'htu@topmargin{22mm}' htuthesis.def 2>/dev/null | grep -q 'HTU\|格式要求' && ((comment_count++))
  grep -B1 'htu@leftmargin{25mm}' htuthesis.def 2>/dev/null | grep -q 'HTU\|格式要求' && ((comment_count++))
  [[ "$comment_count" -ge 3 ]]
}
run_test "P1" "ATDD-2.1-13" ".def new params have truth-source comments (NFR-3)" test_truth_source_comments

# ATDD-2.1-14: No defhtu corruption — all .def \def lines have backslash (Epic 1 retro)
test_no_defhtu_corruption() {
  [[ -f "htuthesis.def" ]] || return 1
  # Check that no line has "defhtu@" without preceding backslash
  # Pattern: line contains "def" followed by "htu@" but NOT "\def\htu@"
  local corrupt
  corrupt=$(grep -nP '^\s*def\\?htu@' htuthesis.def 2>/dev/null | grep -v '\\def\\htu@' | wc -l)
  corrupt=$(echo "$corrupt" | tr -d '[:space:]' | head -1)
  [[ "$corrupt" -eq 0 ]]
}
run_test "P1" "ATDD-2.1-14" ".def has no defhtu corruption (Epic 1 retro backslash check)" test_no_defhtu_corruption

# ATDD-2.1-15: .def old topmargin value (38mm) no longer present
test_old_topmargin_gone() {
  [[ -f "htuthesis.def" ]] || return 1
  local count
  count=$(grep -c 'htu@topmargin{38mm}' htuthesis.def 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  [[ "$count" -eq 0 ]]
}
run_test "P1" "ATDD-2.1-15" ".def old \\htu@topmargin{38mm} removed" test_old_topmargin_gone

# ATDD-2.1-16: .def old leftmargin value (32mm) no longer present
test_old_leftmargin_gone() {
  [[ -f "htuthesis.def" ]] || return 1
  local count
  count=$(grep -c 'htu@leftmargin{32mm}' htuthesis.def 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  [[ "$count" -eq 0 ]]
}
run_test "P1" "ATDD-2.1-16" ".def old \\htu@leftmargin{32mm} removed" test_old_leftmargin_gone

# ATDD-2.1-29: body baselineskip = 23.4bp (REPOINTED by Story 3.11: was 18bp naive ×fontsize via Story 2.5,
#   now 23.4bp = Word「1.5倍」×natural per §2.7/§2.9; sprint-change-proposal-2026-06-17 gap G4)
test_body_baselineskip_18bp_def() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '\\def\\htu@body@baselineskip{23.4bp}' htuthesis.def 2>/dev/null
}
run_test "P1" "ATDD-2.1-29" "body baselineskip = 23.4bp in .def (REPOINTED by Story 3.11; §2.7/§2.9 Word 1.5倍)" test_body_baselineskip_18bp_def

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: Secondary Tests ==="

# ATDD-2.1-17: .def header comment references "HTU 格式要求 §2.3"
test_def_header_truth_source() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '§2.3\|HTU 格式要求' htuthesis.def 2>/dev/null
}
run_test "P2" "ATDD-2.1-17" ".def header references HTU 格式要求 §2.3" test_def_header_truth_source

# ATDD-2.1-18: .def calibration date updated to 2026-06-13
test_def_calibration_date() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '2026-06-13\|校准日期.*2026' htuthesis.def 2>/dev/null
}
run_test "P2" "ATDD-2.1-18" ".def calibration date updated to 2026-06-13" test_def_calibration_date

# ATDD-2.1-19: cls comment block references HTU spec values
test_cls_comment_updated() {
  [[ -f "htuthesis.cls" ]] || return 1
  # The comment block above \geometry should reference HTU spec
  sed -n '/页面设置/,/\\geometry/p' htuthesis.cls 2>/dev/null | grep -q 'HTU\|格式要求'
}
run_test "P2" "ATDD-2.1-19" "cls comment block references HTU spec" test_cls_comment_updated

# ATDD-2.1-30: SUPERSEDED by Story 2.2 — 2.2 intentionally added twoside to LoadClass.
# This 2.1 scope-guard ("no twoside yet") is obsolete; twoside presence is verified by ATDD-2.2-01.
# test_no_twoside() {
#   [[ -f "htuthesis.cls" ]] || return 1
#   grep '\\LoadClass' htuthesis.cls 2>/dev/null | grep -q 'twoside' && return 1
#   return 0
# }
# run_test "P2" "ATDD-2.1-30" "cls has no twoside yet (Story 2.2 scope)" test_no_twoside

# ATDD-2.1-31: SUPERSEDED by Story 2.2/2.3 — 2.2 replaced \ps@htu@ with \fancypagestyle{htu@},
# and 2.3 customized the header/footer styles. This 2.1 scope-guard is obsolete.
# test_no_pagestyle_changes() {
#   [[ -f "htuthesis.cls" ]] || return 1
#   local count
#   count=$(grep -c 'ps@htu@' htuthesis.cls 2>/dev/null || true)
#   count=$(echo "$count" | tr -d '[:space:]' | head -1)
#   [[ "$count" -ge 3 ]]
# }
# run_test "P2" "ATDD-2.1-31" "cls page styles unchanged (Stories 2.3/2.4 scope)" test_no_pagestyle_changes

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
