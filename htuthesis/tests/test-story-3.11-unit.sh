#!/usr/bin/env bash
# test-story-3.11-unit.sh — ATDD Red-Phase Unit Tests for Story 3.11 (body + abstract line-spacing calibration)
# TDD Phase: RED (the \htu@body@baselineskip value-extraction test FAILS on pre-impl [18bp];
#             wiring/regression guards pass)
#
# Usage: bash tests/test-story-3.11-unit.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 tests are blocking
# Linked ACs: AC-1 (body baselineskip recalibrated 18→≈23bp), AC-2 (R-3 trap excluded),
#             AC-3 (Chinese-abstract inherits — NO local override), AC-4 (English-abstract 23.4bp UNCHANGED)
# Linked Risk: R-18 (score 6, the recalibration + ripple), R-3 (score 6, CJK \setstretch/1.2× trap)
# TC coverage: TC-E3-47 (P0 body baselineskip ≈23bp), TC-E3-50 (P1 Chinese-abstract inherits)
#
# NOTE: these are SOURCE-LEVEL greps — they prove the .def/cls CONTAIN the recalibration wiring.
# The companion integration test (test-story-3.11-integration.sh) proves the RENDERED line-gap via
# fitz (body ≈23bp, Chinese-abstract ≈23bp, English-abstract = 23.4bp). A source-grep that the \def
# value changed does NOT prove the spacing RENDERS correctly (a \setstretch leak could corrupt it);
# the fitz line-gap check is the real AC-1 proof (Story 2.5/2.6/3.9/3.10 behavior-test lesson).
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
echo "ATDD Unit Tests: Story 3.11 — Body and abstract line-spacing calibration"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: body baselineskip recalibrated (RED pre-impl) ==="

# ATDD-3.11-01: \htu@body@baselineskip recalibrated to ≈23bp (AC-1, TC-E3-47)
# Extract the numeric value from `\def\htu@body@baselineskip{<n>bp}` in htuthesis.def.
# Mechanism-agnostic to the exact value the dev picks (23 / 23.4 / 23.5 from the Task 1.2 empirical probe):
#   asserts the value is in the Word-"1.5倍" band [22.0, 24.0]bp (1.5×小四 SimSun natural ≈ 23.4pt).
#   Pre-impl: 18bp (naive ×fontsize) → 18 < 22.0 → RED.
#   Post-impl: 22.0–24.0 → GREEN.
#   The band also EXCLUDES 21.6bp (the ctexbook 1.2× multiplier R-3 trap) and 25.2bp (over-spacing).
test_body_baselineskip_recalibrated() {
  [[ -f "htuthesis.def" ]] || return 1
  local val
  val=$(grep -oE '\\def\\htu@body@baselineskip\{[0-9]+\.?[0-9]*bp\}' htuthesis.def 2>/dev/null \
        | grep -oE '[0-9]+\.?[0-9]*' | head -1)
  if [[ -z "$val" ]]; then echo "  (could not extract \htu@body@baselineskip value from .def)"; return 1; fi
  echo "  (\htu@body@baselineskip = ${val}bp; target band [22.0,24.0]; pre-impl=18 → RED; 21.6=R-3 trap)"
  awk -v v="$val" 'BEGIN{exit (v>=22.0 && v<=24.0)?0:1}'
}
run_test "P0" "ATDD-3.11-01" "\\htu@body@baselineskip recalibrated to ≈23bp [22.0,24.0] (AC-1, TC-E3-47; RED pre-impl=18bp)" test_body_baselineskip_recalibrated

# ATDD-3.11-02: \@setfontsize\normalsize wiring uses \htu@body@baselineskip (AC-1; GREEN guard)
# The recalibration propagates via the existing \@setfontsize wiring (cls:247); the dev changes ONLY the
# \def value, NOT the wiring. Pre-impl: present (Story 1.2) → GREEN guard. Post-impl: must stay present.
test_normalsize_wiring() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE '@setfontsize\\normalsize\{\\htu@body@fontsize\}\{\\htu@body@baselineskip\}' htuthesis.cls
}
run_test "P0" "ATDD-3.11-02" "\\@setfontsize\\normalsize uses \\htu@body@baselineskip (AC-1; GREEN guard — wiring unchanged)" test_normalsize_wiring

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: no \\setstretch (R-3) + English-abstract UNCHANGED + Chinese-abstract inheritance ==="

# ATDD-3.11-03: NO \setstretch in cls (R-3 anti-pattern; GREEN guard)
# \setstretch is the CJK line-spacing trap (ctexbook applies ~1.2× → 21.6bp). The recalibration MUST stay
# in \@setfontsize (architecture.md:84). Pre-impl: 0 setstretch → GREEN guard.
test_no_setstretch() {
  [[ -f "htuthesis.cls" ]] || return 1
  local n
  n=$(grep -c 'setstretch' htuthesis.cls 2>/dev/null || true)
  n=$(echo "$n" | tr -d '[:space:]' | head -1)
  echo "  (setstretch matches: $n; expect 0 — recalibration must use \@setfontsize, not \setstretch)"
  [[ "$n" -eq 0 ]]
}
run_test "P1" "ATDD-3.11-03" "regression: NO \\setstretch in cls (R-3 anti-pattern; \@setfontsize only)" test_no_setstretch

# ATDD-3.11-04: English-abstract block UNCHANGED at \fontsize{10.5bp}{23.4bp} (AC-4; GREEN guard)
# Story 3.4 R-14 locked the English-abstract baselineskip at 23.4bp (cls:891). Story 3.11 recalibrates ONLY
# the body + Chinese-abstract; the English-abstract \begingroup...\endgroup block is UNTOUCHED.
# Pre-impl: present (Story 3.4) → GREEN guard. Post-impl: must stay present at 23.4bp (NOT dragged to body value).
test_english_abstract_unchanged() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'fontsize\{10\.5bp\}\{23\.4bp\}' htuthesis.cls
}
run_test "P1" "ATDD-3.11-04" "English-abstract \\fontsize{10.5bp}{23.4bp} UNCHANGED (AC-4, R-14; GREEN guard)" test_english_abstract_unchanged

# ATDD-3.11-05: Chinese-abstract body has NO local \fontsize/\setstretch override (AC-3; GREEN guard)
# The Chinese-abstract body (\htu@cabstract, rendered in \htu@makeabstract) inherits \normalsize — that is
# the AC-3 inheritance mechanism. Assert the \htu@cabstract call is NOT wrapped in a \begingroup with a local
# \fontsize/\setstretch (which would DECOUPLE it from the body recalibration, breaking §2.7 == §2.9).
# Extract the \htu@makeabstract body; assert \htu@cabstract appears WITHOUT a preceding \begingroup/\fontsize
# on the same region (the English-abstract \begingroup is a SEPARATE block after \htu@cabstract).
test_chinese_abstract_inherits() {
  [[ -f "htuthesis.cls" ]] || return 1
  local mk_body
  mk_body=$(sed -n '/\\newcommand{\\htu@makeabstract}{/,/^}/p' htuthesis.cls 2>/dev/null)
  if [[ -z "$mk_body" ]]; then echo "  (could not extract \htu@makeabstract body)"; return 1; fi
  # The Chinese-abstract call \htu@cabstract must be present.
  printf '%s\n' "$mk_body" | grep -q '\\htu@cabstract' || { echo "  (\htu@cabstract call not found)"; return 1; }
  # Count local baselineskip overrides in the makeabstract body. The English-abstract block legitimately has
  # ONE \fontsize{10.5bp}{23.4bp}. The Chinese body must add NONE beyond that. So total \fontsize in
  # makeabstract should be exactly 1 (the English one) — a Chinese-body local override would make it 2+.
  local n
  n=$(printf '%s\n' "$mk_body" | grep -cE '\\fontsize\{|\\setstretch' 2>/dev/null || true)
  n=$(echo "$n" | tr -d '[:space:]' | head -1)
  echo "  (\\fontsize/\\setstretch in \\htu@makeabstract: $n; expect 1 — the English-abstract block ONLY; Chinese body inherits)"
  [[ "$n" -eq 1 ]]
}
run_test "P1" "ATDD-3.11-05" "Chinese-abstract body inherits \\normalsize (NO local override; AC-3, TC-E3-50)" test_chinese_abstract_inherits

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: [基础] comment reflects Word semantics (doc guard) ==="

# ATDD-3.11-06: the [基础] truth-source comment on \htu@body@baselineskip reflects Word "倍数行距" semantics
# (NOT the old "1.5 倍小四号 = 18bp" naive text). The dev updates it in Task 1.5. This is a doc-consistency
# guard — the comment must mention the Word/natural semantics and reference spec §2.9/§2.7. Pre-impl: the
# comment says "18bp" (stale) → RED. Post-impl: mentions Word/natural semantics → GREEN.
test_baselineskip_comment_updated() {
  [[ -f "htuthesis.def" ]] || return 1
  # Extract the 2-line region around \htu@body@baselineskip.
  local region
  region=$(grep -n -A1 -B1 'htu@body@baselineskip' htuthesis.def 2>/dev/null)
  # Post-impl comment should mention Word semantics / natural line-height / 23 (NOT just "18bp").
  # Pre-impl comment: "[基础] 正文行距 = 1.5 倍小四号 = 18bp" → lacks Word/natural phrasing → RED.
  printf '%s\n' "$region" | grep -qiE 'natural|Word|倍数|23|参考' && \
  ! printf '%s\n' "$region" | grep -qiE '= *18bp|18bp *[（(]'
}
run_test "P2" "ATDD-3.11-06" "[基础] comment reflects Word 倍数行距 semantics (doc guard; RED pre-impl stale text)" test_baselineskip_comment_updated

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
  echo "   RED (fail pre-impl): 3.11-01 (\htu@body@baselineskip = 18bp, outside [22,24] band),"
  echo "      3.11-06 ([基础] comment stale, says 18bp)."
  echo "   GREEN guards: 3.11-02 (\@setfontsize wiring), 3.11-03 (no \setstretch),"
  echo "      3.11-04 (English-abstract 23.4bp UNCHANGED), 3.11-05 (Chinese-abstract inherits)."
  echo ""
  echo "   NOTE: source-greps prove the \def VALUE changed + wiring/regression invariants hold; the"
  echo "         integration test's fitz line-gap check (ATDD-3.11-I05/I06/I07) proves the spacing RENDERS"
  echo "         (body ≈23bp, Chinese-abstract ≈23bp, English-abstract = 23.4bp) — the real AC-1 proof."
  echo "         AC-6 (Decision-2 repoints of the 2.x/3.5 baselineskip-18bp guards) is the DEV's Task 2 —"
  echo "         not asserted here (coupling to other stories' test files would be fragile)."
  echo "         Tests are read-only — they do not modify the SUT."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
