#!/usr/bin/env bash
# test-story-2.3-unit.sh — ATDD Red-Phase Unit Tests for Story 2.3
# TDD Phase: RED (all tests expected to FAIL before implementation)
#
# Usage: bash tests/test-story-2.3-unit.sh [--run]
#   --run    Remove SKIP markers (for green-phase verification)
#
# Priority: P0 tests are blocking; P1/P2 are best-effort
# Linked Risk: R-7 (score 6, even-page rightmark + front-matter header leakage), R-11 (score 4, pagestyle cascade)
# Truth source: 河南师范大学研究生学位论文格式要求.md §2.5 (headers centered, 五号宋体, even=title/odd=chapter, main-body only)
# Epic 1 Retro applied: tests NEVER modify source under test; avoid cross-story ATDD conflicts; backslash-safe greps.
# Cross-story note: 2.3 deliberately changes header behavior guarded by ATDD-2.2-21 and ATDD-2.2-24 —
#                   those MUST be retired/updated as part of 2.3 (see checklist prerequisite).

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
echo "ATDD Unit Tests: Story 2.3 — Odd/even page headers with horizontal rule"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Blocking Tests ==="

# --- AC-2/AC-3/AC-4/AC-6: odd/even centered header differentiation (TC-E2-11, TC-E2-12) ---

# ATDD-2.3-01: cls has \fancyhead[CE] (centered even-page header) (AC-2,3, TC-E2-11, R-7)
test_fancyhead_ce() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\fancyhead\[CE\]' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.3-01" "cls has \\fancyhead[CE] (centered even-page header) (AC-2,3, TC-E2-11)" test_fancyhead_ce

# ATDD-2.3-02: cls has \fancyhead[CO] (centered odd-page header) (AC-2,4, TC-E2-12, R-7)
test_fancyhead_co() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\fancyhead\[CO\]' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.3-02" "cls has \\fancyhead[CO] (centered odd-page header) (AC-2,4, TC-E2-12)" test_fancyhead_co

# ATDD-2.3-03: \fancyhead[CE] references \htu@ctitle (even page = thesis title) (AC-3, TC-E2-11)
test_ce_uses_ctitle() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\fancyhead\[CE\].*\\htu@ctitle' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.3-03" "\\fancyhead[CE] references \\htu@ctitle (even page = thesis title) (AC-3, TC-E2-11)" test_ce_uses_ctitle

# ATDD-2.3-04: \fancyhead[CO] references \rightmark (odd page = chapter via rightmark, not leftmark) (AC-4,6, TC-E2-12)
test_co_uses_rightmark() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\fancyhead\[CO\].*\\rightmark' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.3-04" "\\fancyhead[CO] references \\rightmark (odd page = chapter title) (AC-4,6, TC-E2-12)" test_co_uses_rightmark

# ATDD-2.3-05: \headruleskip reconnected to \htu@header@rule@gap (AC-5; resolves 2.2 dead-code deferral)
test_headruleskip_reconnected() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q 'headruleskip.*htu@header@rule@gap' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.3-05" "\\headruleskip reconnected to \\htu@header@rule@gap (AC-5; closes 2.2 dead-code item)" test_headruleskip_reconnected

# ATDD-2.3-06: \headrulewidth still uses \htu@header@rule@thickness (thin rule retained, AC-5/AC-8, TC-E2-14)
test_headrulewidth_retained() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q 'headrulewidth.*htu@header@rule@thickness' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.3-06" "\\headrulewidth still uses \\htu@header@rule@thickness (AC-5,8, TC-E2-14)" test_headrulewidth_retained

# ATDD-2.3-07: \frontmatter uses htu@plain (front matter NO header) (AC-5, TC-E2-13, R-7)
test_frontmatter_plain() {
  [[ -f "htuthesis.cls" ]] || return 1
  # Within the \renewcommand\frontmatter block, pagestyle must be htu@plain (NOT htu@headings)
  sed -n '/\\renewcommand\\frontmatter/,/\\renewcommand\\mainmatter/p' htuthesis.cls 2>/dev/null \
    | grep -q '\\pagestyle{htu@plain}'
}
run_test "P0" "ATDD-2.3-07" "\\frontmatter uses htu@plain (front matter no header) (AC-5, TC-E2-13)" test_frontmatter_plain

# ATDD-2.3-08: \mainmatter sets \pagestyle{htu@headings} (REQUIRED — main body keeps headers after frontmatter→plain) (AC-9, R-11)
test_mainmatter_headings() {
  [[ -f "htuthesis.cls" ]] || return 1
  sed -n '/\\renewcommand\\mainmatter/,/\\renewcommand\\backmatter/p' htuthesis.cls 2>/dev/null \
    | grep -q '\\pagestyle{htu@headings}'
}
run_test "P0" "ATDD-2.3-08" "\\mainmatter sets \\pagestyle{htu@headings} (AC-9, R-11 critical)" test_mainmatter_headings

# ATDD-2.3-09: \htu@makeabstract uses htu@plain (abstract = front matter, no header) (AC-5, TC-E2-13)
test_makeabstract_plain() {
  [[ -f "htuthesis.cls" ]] || return 1
  sed -n '/\\newcommand{\\htu@makeabstract}/,/^}/p' htuthesis.cls 2>/dev/null \
    | grep -q '\\pagestyle{htu@plain}'
}
run_test "P0" "ATDD-2.3-09" "\\htu@makeabstract uses htu@plain (abstract no header) (AC-5, TC-E2-13)" test_makeabstract_plain

# ATDD-2.3-10: \let\sectionmark\@gobble retained in headings block (AC-4,6 — prevents section overwriting rightmark)
test_sectionmark_gobble_retained() {
  [[ -f "htuthesis.cls" ]] || return 1
  sed -n '/fancypagestyle{htu@headings}/,/^}/p' htuthesis.cls 2>/dev/null \
    | grep -q '\\let\\sectionmark\\@gobble'
}
run_test "P0" "ATDD-2.3-10" "\\let\\sectionmark\\@gobble retained in headings block (AC-4,6)" test_sectionmark_gobble_retained

# ATDD-2.3-11: old single \fancyhead[C]{...leftmark} removed from headings block (AC-2 cleanup, TC-E2-11)
test_no_legacy_centered_header() {
  [[ -f "htuthesis.cls" ]] || return 1
  # The headings block must NOT still contain the pre-2.3 centered \leftmark line
  local block
  block=$(sed -n '/fancypagestyle{htu@headings}/,/^}/p' htuthesis.cls 2>/dev/null)
  # Reject the legacy pattern: \fancyhead[C]{...\leftmark...}
  if echo "$block" | grep -q '\\fancyhead\[C\].*\\leftmark'; then
    return 1
  fi
  return 0
}
run_test "P0" "ATDD-2.3-11" "legacy \\fancyhead[C]{\\leftmark} removed from headings block (AC-2 cleanup)" test_no_legacy_centered_header

# ATDD-2.3-12: CE and CO headers both use \wuhao (五号 = 10.5pt) (AC-5 五号宋体, TC-E2-14)
test_headers_wuhao() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\fancyhead\[CE\].*\\wuhao' htuthesis.cls 2>/dev/null && \
  grep -q '\\fancyhead\[CO\].*\\wuhao' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.3-12" "CE and CO headers use \\wuhao (五号宋体) (AC-5, TC-E2-14)" test_headers_wuhao

# --- Scope boundary: regression guards (must NOT change) ---

# ATDD-2.3-13: no geometry parameter changes in .def (same as Story 2.1/2.2) (R-1)
test_def_geometry_unchanged() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '\\def\\htu@topmargin{22mm}' htuthesis.def 2>/dev/null && \
  grep -q '\\def\\htu@bottommargin{17.5mm}' htuthesis.def 2>/dev/null && \
  grep -q '\\def\\htu@leftmargin{25mm}' htuthesis.def 2>/dev/null && \
  grep -q '\\def\\htu@rightmargin{25mm}' htuthesis.def 2>/dev/null
}
run_test "P0" "ATDD-2.3-13" "no geometry parameter changes in .def (R-1 regression guard)" test_def_geometry_unchanged

# ATDD-2.3-14: body baselineskip = 18bp in .def (REPOINTED by Story 2.5: was a 20bp scope-guard for 2.3, now 18bp per §2.7/2.9 1.5x line spacing)
test_body_baselineskip_18bp_def() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '\\def\\htu@body@baselineskip{18bp}' htuthesis.def 2>/dev/null
}
run_test "P0" "ATDD-2.3-14" "body baselineskip = 18bp in .def (repointed by Story 2.5; §2.7/2.9 1.5x)" test_body_baselineskip_18bp_def

# ATDD-2.3-15: counter separator externalized as hyphen (REPOINTED by Story 2.6; was "still period, Story 2.6 scope", R-12)
test_separator_unchanged() {
  [[ -f "htuthesis.def" ]] || return 1
  local count
  count=$(grep -c 'htu@.*separator.*-' htuthesis.def 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  # Story 2.6 added \htu@counter@separator{-} → expect >= 1 (was 0 pre-Story-2.6).
  [[ "$count" -ge 1 ]]
}
run_test "P0" "ATDD-2.3-15" "counter separator externalized \\htu@counter@separator{-} (repointed by Story 2.6, R-12)" test_separator_unchanged

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Critical Path Tests ==="

# ATDD-2.3-16: \mainmatter retains \pagenumbering{arabic} (no regression)
test_mainmatter_arabic() {
  [[ -f "htuthesis.cls" ]] || return 1
  sed -n '/\\renewcommand\\mainmatter/,/\\renewcommand\\backmatter/p' htuthesis.cls 2>/dev/null \
    | grep -q '\\pagenumbering{arabic}'
}
run_test "P1" "ATDD-2.3-16" "\\mainmatter retains \\pagenumbering{arabic} (no regression)" test_mainmatter_arabic

# ATDD-2.3-17: \frontmatter retains \pagenumbering{Roman} (no regression)
test_frontmatter_roman() {
  [[ -f "htuthesis.cls" ]] || return 1
  sed -n '/\\renewcommand\\frontmatter/,/\\renewcommand\\mainmatter/p' htuthesis.cls 2>/dev/null \
    | grep -q '\\pagenumbering{Roman}'
}
run_test "P1" "ATDD-2.3-17" "\\frontmatter retains \\pagenumbering{Roman} (no regression)" test_frontmatter_roman

# ATDD-2.3-18: \chaptermark populates BOTH markboth fields (AC-7) — proxy: \CTEXifname count >= 2
# Baseline (pre-2.3): \CTEXifname appears once (only first markboth field). Post-2.3: twice (both fields).
# Assumption: \CTEXifname is used only inside \chaptermark (verified true at commit 088f53f).
# Behavioral verification (odd page shows chapter title) is VISUAL — see test matrix.
test_chaptermark_both_marks() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep -c 'CTEXifname' htuthesis.cls 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  [[ "$count" -ge 2 ]]
}
run_test "P1" "ATDD-2.3-18" "\\chaptermark populates both marks (\\CTEXifname count >= 2 proxy) (AC-7)" test_chaptermark_both_marks

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: Secondary Tests ==="

# ATDD-2.3-19: page-number footer retains \wuhao\thepage font (Story 2.4 moved position [C]->[LE,RO];
#              this guard now verifies the FONT survives the position change, not the centered position).
# REPURPOSED by Story 2.4 (cross-story conflict, Epic 1 retro pattern): the original assertion pinned
# the footer as centered \fancyfoot[C]{\wuhao\thepage} until Story 2.4 moved it outer-side. The
# position is now verified by test-story-2.4-unit.sh (ATDD-2.4-01/02/03) + the rendered-PDF behavior
# test ATDD-2.4-20. What 2.3 still legitimately owns: the footer page-number font is \wuhao\thepage
# regardless of position — this stays green across the 2.3->2.4 transition.
test_footer_font_retained() {
  [[ -f "htuthesis.cls" ]] || return 1
  # Matches both the pre-2.4 \fancyfoot[C]{...} and the 2.4 \fancyfoot[LE,RO]{...} forms.
  sed -n '/fancypagestyle{htu@headings}/,/^}/p' htuthesis.cls 2>/dev/null \
    | grep -q '\\fancyfoot\[.*\]{\\wuhao\\thepage}'
}
run_test "P2" "ATDD-2.3-19" "footer page-number retains \\wuhao\\thepage font (repurposed: position moved by Story 2.4)" test_footer_font_retained

# ATDD-2.3-20: no main.tex content changes (scope boundary)
test_main_tex_unchanged() {
  [[ -f "main.tex" ]] || return 1
  grep -q '\\documentclass\[doctor\]{htuthesis}' main.tex 2>/dev/null
}
run_test "P2" "ATDD-2.3-20" "no main.tex content changes (scope boundary)" test_main_tex_unchanged

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
