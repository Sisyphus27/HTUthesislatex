#!/usr/bin/env bash
# test-story-2.4-unit.sh — ATDD Red-Phase Unit Tests for Story 2.4
# TDD Phase: RED (3 driver tests expected to FAIL before implementation; 13 guards PASS)
#
# Usage: bash tests/test-story-2.4-unit.sh [--run]
#   --run    Remove SKIP markers (for green-phase verification)
#
# Priority: P0 tests are blocking; P1/P2 are best-effort
# Linked Risk: R-7 (score 6, silent failure #9 page-number position + #11 back-matter numbering)
# Truth source: 河南师范大学研究生学位论文格式要求.md §2.4 (page numbers at footer outer side;
#               uppercase Roman front matter; Arabic main body; cover/扉页 no number)
# Epic 1 Retro applied: tests NEVER modify source under test (read-only grep/sed -n);
#                       backslash-safe greps; set -uo pipefail (NO -e).
# Cross-story note: Story 2.4 moves the page-number footer [C] -> [LE,RO], which Story 2.3's
#                   ATDD-2.3-19 guarded as "centered (outer-side = Story 2.4 scope)".
#                   ATDD-2.3-19 is repointed to a font-retention guard as part of 2.4
#                   (see atdd-checklist-2-4-*.md → Cross-Story Conflict Resolution).
# Source-grep tests are necessary but NOT sufficient — rendered-PDF outer-side position is
# verified by the BEHAVIOR test in test-story-2.4-integration.sh (ATDD-2.4-20, fitz).

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
echo "ATDD Unit Tests: Story 2.4 — Outer-side page numbering (Roman and Arabic)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Blocking Tests ==="

# --- AC-3/AC-4: page-number footer moved to outer side ([C] -> [LE,RO]) (TC-E2-15, TC-E2-16) ---

# ATDD-2.4-01: htu@plain block has \fancyfoot[LE,RO]{\wuhao\thepage} (front-matter outer side) (AC-3, TC-E2-15, R-7)
# RED pre-impl: footer is centered \fancyfoot[C]{...}. Post-impl: [LE,RO].
# Block scope bounded by the NEXT style declaration (robust to ^} column shifts).
test_plain_block_outer_footer() {
  [[ -f "htuthesis.cls" ]] || return 1
  sed -n '/fancypagestyle{htu@plain}/,/fancypagestyle{htu@headings}/p' htuthesis.cls 2>/dev/null \
    | grep -q '\\fancyfoot\[LE,RO\]{\\wuhao\\thepage}'
}
run_test "P0" "ATDD-2.4-01" "htu@plain block has \\fancyfoot[LE,RO]{\\wuhao\\thepage} (front-matter outer side) (AC-3, TC-E2-15)" test_plain_block_outer_footer

# ATDD-2.4-02: htu@headings block has \fancyfoot[LE,RO]{\wuhao\thepage} (main-body outer side) (AC-4, TC-E2-16, R-7)
# RED pre-impl. Block scope bounded by \let\sectionmark\@gobble (last statement of the block).
test_headings_block_outer_footer() {
  [[ -f "htuthesis.cls" ]] || return 1
  sed -n '/fancypagestyle{htu@headings}/,/sectionmark.*gobble/p' htuthesis.cls 2>/dev/null \
    | grep -q '\\fancyfoot\[LE,RO\]{\\wuhao\\thepage}'
}
run_test "P0" "ATDD-2.4-02" "htu@headings block has \\fancyfoot[LE,RO]{\\wuhao\\thepage} (main-body outer side) (AC-4, TC-E2-16)" test_headings_block_outer_footer

# ATDD-2.4-03: legacy centered footer \fancyfoot[C]{\wuhao\thepage} fully removed (count == 0) (AC-3/4 cleanup, R-7)
# RED pre-impl: count == 2 (both styles centered). Post-impl: count == 0.
test_no_legacy_centered_footer() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep -c '\\fancyfoot\[C\]{\\wuhao\\thepage}' htuthesis.cls 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  [[ "$count" -eq 0 ]]
}
run_test "P0" "ATDD-2.4-03" "legacy centered \\fancyfoot[C]{\\wuhao\\thepage} removed (count == 0) (AC-3/4 cleanup)" test_no_legacy_centered_footer

# --- Scope regression guards: numbering style + cover suppression (must NOT change) ---

# ATDD-2.4-04: \frontmatter retains \pagenumbering{Roman} (AC-1 uppercase Roman front matter, TC-E2-19)
test_frontmatter_roman() {
  [[ -f "htuthesis.cls" ]] || return 1
  sed -n '/\\renewcommand\\frontmatter/,/\\renewcommand\\mainmatter/p' htuthesis.cls 2>/dev/null \
    | grep -q '\\pagenumbering{Roman}'
}
run_test "P0" "ATDD-2.4-04" "\\frontmatter retains \\pagenumbering{Roman} (AC-1, TC-E2-19)" test_frontmatter_roman

# ATDD-2.4-05: \mainmatter retains \pagenumbering{arabic} (AC-2/6 Arabic body + first page = 1, TC-E2-18)
test_mainmatter_arabic() {
  [[ -f "htuthesis.cls" ]] || return 1
  sed -n '/\\renewcommand\\mainmatter/,/\\renewcommand\\backmatter/p' htuthesis.cls 2>/dev/null \
    | grep -q '\\pagenumbering{arabic}'
}
run_test "P0" "ATDD-2.4-05" "\\mainmatter retains \\pagenumbering{arabic} (AC-2/6, TC-E2-18)" test_mainmatter_arabic

# ATDD-2.4-06: \htu@makeabstract retains \pagenumbering{Roman} (AC-1 abstract = front matter, no header)
test_makeabstract_roman() {
  [[ -f "htuthesis.cls" ]] || return 1
  sed -n '/newcommand{\\htu@makeabstract}/,/^}/p' htuthesis.cls 2>/dev/null \
    | grep -q '\\pagenumbering{Roman}'
}
run_test "P0" "ATDD-2.4-06" "\\htu@makeabstract retains \\pagenumbering{Roman} (AC-1)" test_makeabstract_roman

# ATDD-2.4-07: cover/title pages retain \thispagestyle{htu@empty} (count >= 2) (AC-5 no number, TC-E2-17)
# REPPOINTED 2026-06-19 (Story 3.14, Decision 2): was "count >= 3" (doctoral cover + engcover + abstractcover).
#   Story 3.14 DELETED \htu@abstractcover (spec §1.1 line 5) → only doctoral cover + engcover retain htu@empty
#   (= 2). FR-4 cover-no-number still holds for the 2 remaining covers. Threshold re-anchored 3 → 2.
test_cover_empty_style() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep -c '\\thispagestyle{htu@empty}' htuthesis.cls 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  echo "  (thispagestyle{htu@empty} count: $count, expect >= 2 [doctoral cover + engcover; abstractcover removed])"
  [[ "$count" -ge 2 ]]
}
run_test "P0" "ATDD-2.4-07" "cover/title pages retain \\thispagestyle{htu@empty} (count >= 2) (REPPOINTED by Story 3.14: was >=3; abstractcover deleted, §1.1 line 5)" test_cover_empty_style

# ATDD-2.4-08: \mainmatter sets \pagestyle{htu@headings} (R-11 — main body keeps headers/footers, no 2.3 regression)
test_mainmatter_headings() {
  [[ -f "htuthesis.cls" ]] || return 1
  sed -n '/\\renewcommand\\mainmatter/,/\\renewcommand\\backmatter/p' htuthesis.cls 2>/dev/null \
    | grep -q '\\pagestyle{htu@headings}'
}
run_test "P0" "ATDD-2.4-08" "\\mainmatter sets \\pagestyle{htu@headings} (R-11 no regression)" test_mainmatter_headings

# ATDD-2.4-09: no geometry parameter changes in .def (R-1 regression guard)
test_def_geometry_unchanged() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '\\def\\htu@topmargin{22mm}' htuthesis.def 2>/dev/null && \
  grep -q '\\def\\htu@bottommargin{17.5mm}' htuthesis.def 2>/dev/null && \
  grep -q '\\def\\htu@leftmargin{25mm}' htuthesis.def 2>/dev/null && \
  grep -q '\\def\\htu@rightmargin{25mm}' htuthesis.def 2>/dev/null
}
run_test "P0" "ATDD-2.4-09" "no geometry parameter changes in .def (R-1 regression guard)" test_def_geometry_unchanged

# ATDD-2.4-10: body baselineskip = 23.4bp in .def (REPOINTED by Story 3.11: was 18bp naive ×fontsize via
#   Story 2.5, now 23.4bp = Word「1.5倍」×natural per §2.7/2.9; excludes 21.6bp R-3 trap; gap G4)
test_body_baselineskip_18bp_def() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '\\def\\htu@body@baselineskip{23.4bp}' htuthesis.def 2>/dev/null
}
run_test "P0" "ATDD-2.4-10" "body baselineskip = 23.4bp in .def (REPOINTED by Story 3.11; §2.7/2.9 Word 1.5倍, R-3)" test_body_baselineskip_18bp_def

# ATDD-2.4-11: counter separator externalized as hyphen (REPOINTED by Story 2.6; was "still period, Story 2.6 scope", R-12)
test_separator_unchanged() {
  [[ -f "htuthesis.def" ]] || return 1
  local count
  count=$(grep -c 'htu@.*separator.*-' htuthesis.def 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  # Story 2.6 added \htu@counter@separator{-} → expect >= 1 (was 0 pre-Story-2.6).
  [[ "$count" -ge 1 ]]
}
run_test "P0" "ATDD-2.4-11" "counter separator externalized \\htu@counter@separator{-} (repointed by Story 2.6, R-12)" test_separator_unchanged

# ATDD-2.4-12: total \fancyfoot count == 2 (only htu@plain + htu@headings have footers; htu@empty stays clean)
test_fancyfoot_count_two() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep -c 'fancyfoot' htuthesis.cls 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  echo "  (fancyfoot lines: $count, expected 2)"
  [[ "$count" -eq 2 ]]
}
run_test "P0" "ATDD-2.4-12" "total \\fancyfoot count == 2 (only the 2 numbered styles have footers)" test_fancyfoot_count_two

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Critical Path Tests ==="

# ATDD-2.4-13: header config unchanged — \fancyhead[CE] + \fancyhead[CO] present (Story 2.3 not regressed)
test_header_config_unchanged() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\fancyhead\[CE\]' htuthesis.cls 2>/dev/null && \
  grep -q '\\fancyhead\[CO\]' htuthesis.cls 2>/dev/null
}
run_test "P1" "ATDD-2.4-13" "header config unchanged: \\fancyhead[CE] + \\fancyhead[CO] present (Story 2.3 guard)" test_header_config_unchanged

# ATDD-2.4-14: \headruleskip reconnected to \htu@header@rule@gap (Story 2.3 not regressed)
test_headruleskip_reconnected() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q 'headruleskip.*htu@header@rule@gap' htuthesis.cls 2>/dev/null
}
run_test "P1" "ATDD-2.4-14" "\\headruleskip reconnected to \\htu@header@rule@gap (Story 2.3 guard)" test_headruleskip_reconnected

# ATDD-2.4-15: htu@empty block has \fancyhf{} (cover pages — no footer, AC-5)
test_empty_block_no_footer() {
  [[ -f "htuthesis.cls" ]] || return 1
  sed -n '/fancypagestyle{htu@empty}/,/fancypagestyle{htu@plain}/p' htuthesis.cls 2>/dev/null \
    | grep -q '\\fancyhf{}'
}
run_test "P1" "ATDD-2.4-15" "htu@empty block has \\fancyhf{} (cover pages no footer, AC-5)" test_empty_block_no_footer

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: Secondary Tests ==="

# ATDD-2.4-16: no main.tex content changes (scope boundary)
test_main_tex_unchanged() {
  [[ -f "main.tex" ]] || return 1
  grep -q '\\documentclass\[doctor\]{htuthesis}' main.tex 2>/dev/null
}
run_test "P2" "ATDD-2.4-16" "no main.tex content changes (scope boundary)" test_main_tex_unchanged

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
  echo "   Driver tests (01/02/03) are expected to FAIL until the [C]->[LE,RO] change lands"
  echo "   Guard tests (04-16) must STAY green throughout (no regressions)"
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
