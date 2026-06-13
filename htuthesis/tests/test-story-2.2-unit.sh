#!/usr/bin/env bash
# test-story-2.2-unit.sh — ATDD Red-Phase Unit Tests for Story 2.2
# TDD Phase: RED (all tests expected to FAIL before implementation)
#
# Usage: bash tests/test-story-2.2-unit.sh [--run]
#   --run    Remove SKIP markers (for green-phase verification)
#
# Priority: P0 tests are blocking; P1/P2 are best-effort
# Linked Risk: R-2 (score 6), R-7 (score 6), R-10 (score 6)
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
    ((PASS++))
  else
    red "[$priority] $test_id: $description"
    ((FAIL++))
  fi
}

echo "=============================================="
echo "ATDD Unit Tests: Story 2.2 — Twoside Migration with ThuThesis Subsystem"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Blocking Tests ==="

# --- AC-1: twoside + fancyhdr infrastructure ---

# ATDD-2.2-01: cls LoadClass has twoside option (AC-1, R-2)
test_loadclass_twoside() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q 'twoside' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.2-01" "cls LoadClass has twoside option (AC-1, R-2)" test_loadclass_twoside

# ATDD-2.2-02: cls has \newif\ifhtu@openright (AC-1, R-2)
test_openright_flag() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\newif\\ifhtu@openright' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.2-02" "cls has \\newif\\ifhtu@openright (AC-1)" test_openright_flag

# ATDD-2.2-03: cls has \DeclareOption{openright} (AC-1)
test_openright_option() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\DeclareOption{openright}' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.2-03" "cls has \\DeclareOption{openright} (AC-1)" test_openright_option

# ATDD-2.2-04: LoadClass conditional on \ifhtu@openright (AC-1, R-2)
test_loadclass_conditional() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\ifhtu@openright' htuthesis.cls 2>/dev/null && \
  grep -q 'twoside,openright' htuthesis.cls 2>/dev/null && \
  grep -q 'twoside,openany' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.2-04" "LoadClass conditional: openright→twoside,openright / else→twoside,openany (AC-1)" test_loadclass_conditional

# ATDD-2.2-05: cls has \RequirePackage{fancyhdr} (AC-1, R-2)
test_require_fancyhdr() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\RequirePackage{fancyhdr}' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.2-05" "cls has \\RequirePackage{fancyhdr} (AC-1)" test_require_fancyhdr

# ATDD-2.2-06: zero \def\ps@htu@ in cls — replaced by fancypagestyle (AC-1, R-2)
test_no_ps_at_htu() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep -c '\\def\\ps@htu@' htuthesis.cls 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  [[ "$count" -eq 0 ]]
}
run_test "P0" "ATDD-2.2-06" "zero \\def\\ps@htu@ in cls (replaced by fancypagestyle) (AC-1)" test_no_ps_at_htu

# ATDD-2.2-07: cls has all three fancypagestyle definitions (AC-1)
test_fancypagestyle_all() {
  [[ -f "htuthesis.cls" ]] || return 1
  local found=0
  grep -q '\\fancypagestyle{htu@empty}' htuthesis.cls 2>/dev/null && ((found++))
  grep -q '\\fancypagestyle{htu@plain}' htuthesis.cls 2>/dev/null && ((found++))
  grep -q '\\fancypagestyle{htu@headings}' htuthesis.cls 2>/dev/null && ((found++))
  [[ "$found" -eq 3 ]]
}
run_test "P0" "ATDD-2.2-07" "cls has fancypagestyle{htu@empty} + htu@plain + htu@headings (AC-1)" test_fancypagestyle_all

# ATDD-2.2-08: old \htu@cleardoublepage and \htu@clearemptydoublepage removed (AC-1)
test_old_cleardoublepage_removed() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep -c '\\htu@cleardoublepage\|\\htu@clearemptydoublepage' htuthesis.cls 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  [[ "$count" -eq 0 ]]
}
run_test "P0" "ATDD-2.2-08" "old \\htu@cleardoublepage / \\htu@clearemptydoublepage removed (AC-1)" test_old_cleardoublepage_removed

# --- AC-2: ThuThesis port annotations ---

# ATDD-2.2-09: cls has [ThuThesis 移植] markers >= 2 blocks (AC-2, R-10)
test_thuthesis_markers() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep -c '\[ThuThesis 移植\]' htuthesis.cls 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  [[ "$count" -ge 2 ]]
}
run_test "P0" "ATDD-2.2-09" "cls has [ThuThesis 移植] markers >= 2 blocks (AC-2, R-10)" test_thuthesis_markers

# ATDD-2.2-10: ported blocks reference thuthesis.dtx line numbers (AC-2, R-10)
test_thuthesis_source_refs() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q 'thuthesis\.dtx' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.2-10" "ported blocks reference thuthesis.dtx line numbers (AC-2, R-10)" test_thuthesis_source_refs

# ATDD-2.2-11: ported blocks have LPPL license note (AC-2, R-10)
test_lppl_note() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q 'LPPL' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.2-11" "ported blocks have LPPL license note (AC-2, R-10)" test_lppl_note

# ATDD-2.2-12: cls has ThuThesis-style \def\cleardoublepage with \thispagestyle{empty} (AC-2)
test_thuthesis_cleardoublepage() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\def\\cleardoublepage' htuthesis.cls 2>/dev/null && \
  grep -q '\\thispagestyle{empty}' htuthesis.cls 2>/dev/null && \
  grep -q '\\if@twoside' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.2-12" "cls has ThuThesis-style \\def\\cleardoublepage with \\thispagestyle{empty} (AC-2)" test_thuthesis_cleardoublepage

# --- AC-5: self-check infrastructure ---

# ATDD-2.2-13: cls has \AtEndDocument self-check block (AC-5, R-7)
test_atenddocument_selfcheck() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\AtEndDocument{' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.2-13" "cls has \\AtEndDocument self-check block (AC-5)" test_atenddocument_selfcheck

# ATDD-2.2-14: self-check outputs 7 dimensions (AC-5, R-7)
test_selfcheck_seven_dims() {
  [[ -f "htuthesis.cls" ]] || return 1
  local found=0
  grep -q '\\the\\textheight' htuthesis.cls 2>/dev/null && ((found++))
  grep -q '\\the\\textwidth' htuthesis.cls 2>/dev/null && ((found++))
  grep -q '\\the\\baselineskip' htuthesis.cls 2>/dev/null && ((found++))
  grep -q '\\the\\headheight' htuthesis.cls 2>/dev/null && ((found++))
  grep -q '\\the\\evensidemargin' htuthesis.cls 2>/dev/null && ((found++))
  grep -q '\\the\\oddsidemargin' htuthesis.cls 2>/dev/null && ((found++))
  grep -q '\\the\\c@page' htuthesis.cls 2>/dev/null && ((found++))
  [[ "$found" -eq 7 ]]
}
run_test "P0" "ATDD-2.2-14" "self-check outputs 7 dimensions (textheight/textwidth/baselineskip/headheight/evensidemargin/oddsidemargin/c@page) (AC-5)" test_selfcheck_seven_dims

# ATDD-2.2-15: self-check boundary markers correct (AC-5, R-7)
test_selfcheck_markers() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '=== HTU Layout Self-Check ===' htuthesis.cls 2>/dev/null && \
  grep -q '=== End Self-Check ===' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.2-15" "self-check boundary markers (=== HTU Layout Self-Check === / === End Self-Check ===) (AC-5)" test_selfcheck_markers

# --- Scope boundary: negative checks ---

# ATDD-2.2-19: no geometry parameter changes in .def (same as Story 2.1)
test_def_geometry_unchanged() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '\\def\\htu@topmargin{22mm}' htuthesis.def 2>/dev/null && \
  grep -q '\\def\\htu@bottommargin{17.5mm}' htuthesis.def 2>/dev/null && \
  grep -q '\\def\\htu@leftmargin{25mm}' htuthesis.def 2>/dev/null && \
  grep -q '\\def\\htu@rightmargin{25mm}' htuthesis.def 2>/dev/null
}
run_test "P0" "ATDD-2.2-19" "no geometry parameter changes in .def (same as Story 2.1)" test_def_geometry_unchanged

# ATDD-2.2-20: body baselineskip = 18bp (REPOINTED by Story 2.5: was a 20bp scope guard for 2.2, now 18bp per §2.7/§2.9 1.5x)
test_body_baselineskip_18bp_def() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '\\def\\htu@body@baselineskip{18bp}' htuthesis.def 2>/dev/null
}
run_test "P0" "ATDD-2.2-20" "body baselineskip = 18bp in .def (repointed by Story 2.5; §2.7/§2.9 1.5x, R-3)" test_body_baselineskip_18bp_def

# ATDD-2.2-21: SUPERSEDED by Story 2.3 — 2.3 intentionally differentiates odd/even headers
# (replaces centered \leftmark with \fancyhead[CE]{\htu@ctitle} + \fancyhead[CO]{\rightmark}).
# This 2.2 scope-guard is retired; the new behavior is verified by ATDD-2.3-01..04,11 in test-story-2.3-unit.sh.
# test_header_content_unchanged() {
#   [[ -f "htuthesis.cls" ]] || return 1
#   grep -q '\\fancyhead\[C\].*\\leftmark' htuthesis.cls 2>/dev/null
# }
# run_test "P0" "ATDD-2.2-21" "header content unchanged: still centered \\leftmark all pages (Story 2.3 scope)" test_header_content_unchanged

# ATDD-2.2-22: counter separator externalized as hyphen (REPOINTED by Story 2.6; was "still period, Story 2.6 scope")
test_separator_unchanged() {
  [[ -f "htuthesis.def" ]] || return 1
  # Story 2.6 externalized the counter separator as \htu@counter@separator{-} in .def (HTU §2.11/2.12/2.13 + 硬约束).
  # The regex now matches that macro (htu@counter@separator{-}). Pre-Story-2.6 this asserted 0 (no separator yet);
  # post-Story-2.6 it asserts >= 1 (the hyphen separator macro exists).
  local count
  count=$(grep -c 'htu@.*separator.*-' htuthesis.def 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  [[ "$count" -ge 1 ]]
}
run_test "P0" "ATDD-2.2-22" "counter separator externalized \\htu@counter@separator{-} (repointed by Story 2.6, R-12)" test_separator_unchanged

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Critical Path Tests ==="

# ATDD-2.2-23: htu@headings uses \CTEXifname and \CTEXthechapter (AC-2, R-10)
test_ctex_chaptermark() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\CTEXifname' htuthesis.cls 2>/dev/null && \
  grep -q '\\CTEXthechapter' htuthesis.cls 2>/dev/null
}
run_test "P1" "ATDD-2.2-23" "htu@headings uses \\CTEXifname and \\CTEXthechapter (AC-2, R-10)" test_ctex_chaptermark

# ATDD-2.2-24: SUPERSEDED by Story 2.3 — 2.3 intentionally adds \fancyhead[CE]/[CO] differentiation.
# This 2.2 scope-guard (assert zero CE/CO) is retired; the new behavior is verified by ATDD-2.3-01,02 in test-story-2.3-unit.sh.
# test_no_odd_even_differentiation() {
#   [[ -f "htuthesis.cls" ]] || return 1
#   local count
#   count=$(grep -c '\\fancyhead\[C[EO]\]' htuthesis.cls 2>/dev/null || true)
#   count=$(echo "$count" | tr -d '[:space:]' | head -1)
#   [[ "$count" -eq 0 ]]
# }
# run_test "P1" "ATDD-2.2-24" "no odd/even header differentiation yet (Story 2.3 scope, R-7)" test_no_odd_even_differentiation

# ATDD-2.2-29: \htucheck manual command available (AC-5)
test_htucheck_command() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\newcommand{\\htucheck}' htuthesis.cls 2>/dev/null || \
  grep -q '\\newcommand\\htucheck' htuthesis.cls 2>/dev/null || \
  grep -q '\\providecommand{\\htucheck}' htuthesis.cls 2>/dev/null
}
run_test "P1" "ATDD-2.2-29" "\\htucheck manual command available (AC-5)" test_htucheck_command

# ATDD-2.2-31: no main.tex content changes (scope boundary)
test_main_tex_unchanged() {
  [[ -f "main.tex" ]] || return 1
  # main.tex should still reference \documentclass[doctor]{htuthesis} (no openright added)
  grep -q '\\documentclass\[doctor\]{htuthesis}' main.tex 2>/dev/null
}
run_test "P1" "ATDD-2.2-31" "no main.tex content changes (scope boundary)" test_main_tex_unchanged

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: Secondary Tests ==="

# ATDD-2.2-32: header rule uses \htu@header@rule@thickness parameter (AC-1)
test_header_rule_param() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q 'headrulewidth.*htu@header@rule@thickness' htuthesis.cls 2>/dev/null
}
run_test "P2" "ATDD-2.2-32" "header rule uses \\htu@header@rule@thickness parameter (AC-1)" test_header_rule_param

# ATDD-2.2-33: htu@plain has \wuhao font size for page number (AC-1)
test_plain_wuhao() {
  [[ -f "htuthesis.cls" ]] || return 1
  # htu@plain should have \wuhao in the footer
  sed -n '/fancypagestyle{htu@plain}/,/^}/p' htuthesis.cls 2>/dev/null | grep -q '\\wuhao'
}
run_test "P2" "ATDD-2.2-33" "htu@plain has \\wuhao font size for page number (AC-1)" test_plain_wuhao

# ATDD-2.2-34: chaptermark handles unnumbered chapters via \CTEXifname (AC-2, R-10)
test_unnumbered_chapter() {
  [[ -f "htuthesis.cls" ]] || return 1
  # \CTEXifname{...}{} pattern means unnumbered chapters get empty chapter prefix
  grep -q 'CTEXifname.*CTEXthechapter' htuthesis.cls 2>/dev/null
}
run_test "P2" "ATDD-2.2-34" "chaptermark handles unnumbered chapters via \\CTEXifname (AC-2)" test_unnumbered_chapter

# ATDD-2.2-37: \typeout for twoside verification present after LoadClass (AC-1, R-2)
test_twoside_typeout() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q 'htu@twoside=' htuthesis.cls 2>/dev/null || \
  grep -q 'if@twoside' htuthesis.cls 2>/dev/null
}
run_test "P2" "ATDD-2.2-37" "twoside verification typeout present (AC-1, R-2)" test_twoside_typeout

# ATDD-2.2-38: htu@empty style has zero headrulewidth and footrulewidth (AC-1)
test_empty_style_clean() {
  [[ -f "htuthesis.cls" ]] || return 1
  sed -n '/fancypagestyle{htu@empty}/,/^}/p' htuthesis.cls 2>/dev/null | grep -q 'headrulewidth.*0pt' && \
  sed -n '/fancypagestyle{htu@empty}/,/^}/p' htuthesis.cls 2>/dev/null | grep -q 'footrulewidth.*0pt'
}
run_test "P2" "ATDD-2.2-38" "htu@empty has zero headrulewidth and footrulewidth (AC-1)" test_empty_style_clean

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
