#!/usr/bin/env bash
# test-story-2.6-unit.sh — ATDD Red-Phase Unit Tests for Story 2.6
# TDD Phase: RED (driver tests FAIL before implementation; guards PASS)
#
# Usage: bash tests/test-story-2.6-unit.sh [--run]
#   --run    Remove SKIP markers (for green-phase verification)
#
# Priority: P0 tests are blocking; P1/P2 are best-effort
# Linked Risk: R-12 (score 4, counter separator change — stale .aux / en-dash slip; verified at integration level)
# Truth source: 河南师范大学研究生学位论文格式要求.md §2.8 关键词 + §2.11 插图 + §2.12 表格 + §2.13 公式 + 硬约束「编号分隔符必须用短横线 -」
# Epic 1 Retro applied: tests NEVER modify source under test (read-only grep/sed -n); backslash-safe greps; set -uo pipefail.
# Cross-story note: Story 2.6 externalizes the counter separator as \htu@counter@separator{-} in .def.
#                   The 4 separator-unchanged guards (ATDD-2.2-22, 2.3-15, 2.4-11, 2.5-10) asserted "no separator in .def"
#                   — those are repointed as part of 2.6 (see atdd-checklist-2-6 → Cross-Story Conflict Resolution).
# Source-grep tests verify the DEFINITIONS/MACRO usage; rendered caption/keyword text is verified by the BEHAVIOR
# tests in test-story-2.6-integration.sh (a source-grep that \renewcommand\thefigure exists does NOT prove the
# caption renders "图4-1" — a later \renewcommand could shadow it; the fitz rendered check is the real proof).
#
# Calibration (verified pre-impl on main.pdf, commit dffe776):
#   - Figures/tables/equations all live in chap04 (= chapter 4). Pre-impl rendered: "图4.1"×9, "表4.1"×7, "(4.1)"×11.
#   - Keyword labels: "关键词：" on PDF page 7 (Chinese, fullwidth colon, correct); "Key Words" on page 9 (Title-Case, WRONG case).
#   - body_start = PDF page index 18 (page 19, first Arabic-numbered footer).

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
echo "ATDD Unit Tests: Story 2.6 — Chapter-numbered counters and keyword labels"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Blocking Tests ==="

# --- AC-5: counter separator externalized as ASCII hyphen in .def ---

# ATDD-2.6-01: def has \htu@counter@separator{-} (ASCII hyphen, NOT en-dash) (AC-5, TC-E2-26, 硬约束)
# RED pre-impl: no such macro in .def (separators are hardcoded periods in cls).
# NOTE: the literal {-} asserts ASCII U+002D hyphen; an en-dash {–} (U+2013) would NOT match.
test_counter_separator_def() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '\\def\\htu@counter@separator{-}' htuthesis.def 2>/dev/null
}
run_test "P0" "ATDD-2.6-01" "def has \\htu@counter@separator{-} (ASCII hyphen) (AC-5, TC-E2-26)" test_counter_separator_def

# --- AC-1: figure counter uses hyphen ---

# ATDD-2.6-02: cls \thefigure redefined to use \htu@counter@separator (AC-1, TC-E2-26, §2.11 "图 1-1")
# RED pre-impl: no \renewcommand\thefigure block (ctexbook default = period \thechapter.\arabic{figure}).
test_thefigure_hyphen() {
  [[ -f "htuthesis.cls" ]] || return 1
  sed -n '/\\renewcommand\\thefigure/,/^}/p' htuthesis.cls 2>/dev/null \
    | grep -q 'htu@counter@separator'
}
run_test "P0" "ATDD-2.6-02" "cls \\thefigure uses \\htu@counter@separator (AC-1, TC-E2-26, §2.11)" test_thefigure_hyphen

# --- AC-2: table counter uses hyphen ---

# ATDD-2.6-03: cls \thetable redefined to use \htu@counter@separator (AC-2, TC-E2-26, §2.12 "表1-1")
# RED pre-impl: no \renewcommand\thetable block (ctexbook default = period).
test_thetable_hyphen() {
  [[ -f "htuthesis.cls" ]] || return 1
  sed -n '/\\renewcommand\\thetable/,/^}/p' htuthesis.cls 2>/dev/null \
    | grep -q 'htu@counter@separator'
}
run_test "P0" "ATDD-2.6-03" "cls \\thetable uses \\htu@counter@separator (AC-2, TC-E2-26, §2.12)" test_thetable_hyphen

# --- AC-3: equation counter uses hyphen ---

# ATDD-2.6-04: cls main \theequation uses \htu@counter@separator (AC-3, TC-E2-26, §2.13 "（1-1）")
# RED pre-impl: cls:362 main theequation uses literal period \thechapter.\@arabic.
test_theequation_hyphen() {
  [[ -f "htuthesis.cls" ]] || return 1
  # first \theequation block (the main one, cls:361) must reference the separator macro
  sed -n '/\\renewcommand\\theequation/,/^}/p' htuthesis.cls 2>/dev/null \
    | grep -q 'htu@counter@separator'
}
run_test "P0" "ATDD-2.6-04" "cls main \\theequation uses \\htu@counter@separator (AC-3, TC-E2-26, §2.13)" test_theequation_hyphen

# --- Scope regression guards (must stay green) ---

# ATDD-2.6-05: no geometry parameter changes in .def (R-1 regression guard — counters must not touch geometry)
test_def_geometry_unchanged() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '\\def\\htu@topmargin{22mm}' htuthesis.def 2>/dev/null && \
  grep -q '\\def\\htu@bottommargin{17.5mm}' htuthesis.def 2>/dev/null && \
  grep -q '\\def\\htu@leftmargin{25mm}' htuthesis.def 2>/dev/null && \
  grep -q '\\def\\htu@rightmargin{25mm}' htuthesis.def 2>/dev/null
}
run_test "P0" "ATDD-2.6-05" "no geometry changes in .def (R-1 regression guard)" test_def_geometry_unchanged

# ATDD-2.6-06: body baselineskip = 23.4bp (REPOINTED by Story 3.11: R-3 regression guard — value recalibrated
#   18bp→23.4bp by Story 3.11 Word「1.5倍」×natural; 2.6's counter/keyword change did not touch it; gap G4)
test_body_baselineskip_unchanged() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '\\def\\htu@body@baselineskip{23.4bp}' htuthesis.def 2>/dev/null
}
run_test "P0" "ATDD-2.6-06" "body baselineskip = 23.4bp in .def (REPOINTED by Story 3.11; R-3)" test_body_baselineskip_unchanged

# ATDD-2.6-07: header config unchanged — \fancyhead[CE]/[CO] present (Story 2.3 guard)
test_header_config_unchanged() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\fancyhead\[CE\]' htuthesis.cls 2>/dev/null && \
  grep -q '\\fancyhead\[CO\]' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.6-07" "header config unchanged \\fancyhead[CE]/[CO] (Story 2.3 guard)" test_header_config_unchanged

# ATDD-2.6-08: page-number footer unchanged — \fancyfoot[LE,RO] present (Story 2.4 guard)
test_pagenum_footer_unchanged() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\fancyfoot\[LE,RO\]{\\wuhao\\thepage}' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.6-08" "page-number footer unchanged \\fancyfoot[LE,RO] (Story 2.4 guard)" test_pagenum_footer_unchanged

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Critical Path Tests ==="

# --- AC-8: English keyword label uppercase + uses macro ---

# ATDD-2.6-09: cls \htu@ekeywords@title macro = "KEY WORDS" uppercase (AC-8, TC-E2-30, §2.8 "KEY WORDS：")
# RED pre-impl: cls:171 is {Key words:\enskip} (lowercase w).
test_ekw_title_uppercase() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\newcommand{\\htu@ekeywords@title}{KEY WORDS:' htuthesis.cls 2>/dev/null
}
run_test "P1" "ATDD-2.6-09" "\\htu@ekeywords@title = KEY WORDS (uppercase) (AC-8, TC-E2-30, §2.8)" test_ekw_title_uppercase

# ATDD-2.6-10: cls renders English keywords via the macro (not hardcoded "Key Words") (AC-8, DRY)
# RED pre-impl (Story 2.6): cls:712 was \textbf{Key Words:\enskip} (hardcoded, ignored the macro at cls:171).
# REPOINTED 2026-06-16 (Story 3.4, Decision 2): the original grep pinned the \textbf wrapper, which 3.4 removed
#   (KEY WORDS label → non-bold, user decision 2026-06-16). Intent = render uses the \htu@ekeywords@title MACRO.
#   3.4 render = \htu@put@keywords{\htu@ekeywords@title}{\htu@ekeywords}. Grep code-only (exclude % comments)
#   for the macro in a \htu@put@keywords first-arg; bold-agnostic. A hardcoded label (no macro) → FAILs.
test_ekw_uses_macro() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -v '^[[:space:]]*%' htuthesis.cls | grep -qE 'put@keywords\{[^}]{0,20}ekeywords@title'
}
run_test "P1" "ATDD-2.6-10" "English keyword render uses \\htu@ekeywords@title macro (AC-8, DRY; repointed 2026-06-16 Story 3.4 — \\textbf dropped, Decision 2)" test_ekw_uses_macro

# --- AC-7: Chinese keyword label unchanged (verify only) ---

# ATDD-2.6-11: cls Chinese keyword label = "关键词：" (unchanged, already correct) (AC-7, TC-E2-29, §2.8)
test_ckw_label_unchanged() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\newcommand{\\htu@ckeywords@title}{关键词：}' htuthesis.cls 2>/dev/null
}
run_test "P1" "ATDD-2.6-11" "Chinese keyword label \\htu@ckeywords@title = 关键词： (AC-7, TC-E2-29)" test_ckw_label_unchanged

# --- AC-6: subfigure/subtable counters unchanged (inherit hyphen via parent) ---

# ATDD-2.6-12: cls \thesubfigure/\thesubtable remain (\alph{...}) (AC-6 — inherit hyphen via \thefigure/\thetable)
test_subcounters_unchanged() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\renewcommand{\\thesubfigure}{(\\alph{subfigure})}' htuthesis.cls 2>/dev/null && \
  grep -q '\\renewcommand{\\thesubtable}{(\\alph{subtable})}' htuthesis.cls 2>/dev/null
}
run_test "P1" "ATDD-2.6-12" "subfigure/subtable remain (\\alph) — inherit hyphen (AC-6)" test_subcounters_unchanged

# ATDD-2.6-13: caption label-separator \DeclareCaptionLabelSeparator{htu} declared (scope boundary — FR-18)
# REPOINTED 2026-06-16 per Decision 2 (cross-story override): 2.6-13 originally pinned the literal value
#   {\\hspace{\\ccwd}} (inherited from zzuthesis) as a "2.6 doesn't touch the separator" scope guard. Story 3.6
#   AC-3 (Zy-approved Option A) legitimately CHANGED the separator value to {：} (fullwidth colon, reference PDF
#   per Decision 4). 2.6's scope was the counter NUMBER format (\\thefigure etc.), NOT the caption separator value.
#   This test is repointed value-agnostic — it asserts the separator macro is still DECLARED (2.6 didn't remove
#   captioning); the VALUE is now owned + asserted by Story 3.6 (3.6-07 source guard + 3.6-I12 behavior proof).
test_caption_labelsep_unchanged() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\DeclareCaptionLabelSeparator{htu}' htuthesis.cls 2>/dev/null
}
run_test "P1" "ATDD-2.6-13" "caption label-separator \\DeclareCaptionLabelSeparator{htu} declared (scope, FR-18; REPOINTED value-agnostic — 3.6 owns the value)" test_caption_labelsep_unchanged

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: Secondary Tests ==="

# ATDD-2.6-14: appendix \theequation redundant no-separator redefinition REMOVED (AC-4, TC-E2-28, §2.13 "（A-1）")
# RED pre-impl: cls has TWO \renewcommand\theequation (cls:361 main + cls:783 appendix); the appendix one has no
# separator (→ "A1" bug). Post-impl: appendix block deleted → exactly ONE \theequation remains (global → "A-1").
test_appendix_theequation_removed() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep -c '\\renewcommand\\theequation' htuthesis.cls 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  echo "  (\\renewcommand\\theequation count: $count, expect 1 [appendix block removed])"
  [[ "$count" -eq 1 ]]
}
run_test "P2" "ATDD-2.6-14" "appendix \\theequation removed (count==1, AC-4, TC-E2-28)" test_appendix_theequation_removed

# ATDD-2.6-15: no main.tex content changes (scope boundary)
test_main_tex_unchanged() {
  [[ -f "main.tex" ]] || return 1
  grep -q '\\documentclass\[doctor\]{htuthesis}' main.tex 2>/dev/null
}
run_test "P2" "ATDD-2.6-15" "no main.tex content changes (scope boundary)" test_main_tex_unchanged

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
  echo "   Driver tests (01-04,09-10,14) FAIL until the counter/keyword changes land"
  echo "   Guard tests (05-08,11-13,15) must STAY green (no regressions)"
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
