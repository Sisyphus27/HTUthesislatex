#!/usr/bin/env bash
# test-story-2.5-unit.sh — ATDD Red-Phase Unit Tests for Story 2.5
# TDD Phase: RED (driver tests FAIL before implementation; guards PASS)
#
# Usage: bash tests/test-story-2.5-unit.sh [--run]
#   --run    Remove SKIP markers (for green-phase verification)
#
# Priority: P0 tests are blocking; P1/P2 are best-effort
# Linked Risk: R-3 (score 6, CJK line-spacing trap — baselineskip 18bp not 21.6bp), R-1 (geometry regression)
# Truth source: 河南师范大学研究生学位论文格式要求.md §2.10 标题层次 + §2.7/§2.9 行距
# Epic 1 Retro applied: tests NEVER modify source under test (read-only grep/sed -n); backslash-safe greps; set -uo pipefail.
# Cross-story note: Story 2.5 changes body baselineskip 20→18bp, which ATDD-2.3-14/2.3-28/2.4-10 guarded at 20bp.
#                   Those are repointed to 18bp as part of 2.5 (see atdd-checklist-2-5 → Cross-Story Conflict).
# Source-grep tests verify the VALUES/FONT/ALIGNMENT; rendered centering + bold are verified by the
# BEHAVIOR tests in test-story-2.5-integration.sh (a source-grep that `format+=\centering` exists does NOT
# prove the title renders centered — the cls:111 raggedright-override lesson from this story shows why).

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
echo "ATDD Unit Tests: Story 2.5 — Body line spacing and heading hierarchy"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Blocking Tests ==="

# --- AC-1: body line spacing 20bp → 18bp (R-3 crux) ---

# ATDD-2.5-01: def has \htu@body@baselineskip{23.4bp} (REPOINTED by Story 3.11: AC-1, TC-E2-20, R-3)
# Was {18bp} (Story 2.5 naive ×fontsize); Story 3.11 recalibrated to 23.4bp = Word「1.5倍」×natural (§2.7/2.9, gap G4).
test_body_baselineskip_18bp() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '\\def\\htu@body@baselineskip{23.4bp}' htuthesis.def 2>/dev/null
}
run_test "P0" "ATDD-2.5-01" "def has \\htu@body@baselineskip{23.4bp} (REPOINTED by Story 3.11; AC-1, TC-E2-20, R-3)" test_body_baselineskip_18bp

# --- AC-2: Level 1 (chapter) centered + 36bp spacing ---

# ATDD-2.5-02: mainmatter centers chapters (chapter/format+=\centering, NOT \raggedright) (AC-2, TC-E2-22)
# RED pre-impl: cls:111 is format+=\raggedright (chapters render LEFT-aligned).
test_mainmatter_chapter_centered() {
  [[ -f "htuthesis.cls" ]] || return 1
  sed -n '/\\renewcommand\\mainmatter/,/\\renewcommand\\backmatter/p' htuthesis.cls 2>/dev/null \
    | grep -q 'chapter/format+=\\centering'
}
run_test "P0" "ATDD-2.5-02" "\\mainmatter centers chapters (format+=\\centering) (AC-2, TC-E2-22)" test_mainmatter_chapter_centered

# ATDD-2.5-03: def chapter spacing = 46.8bp before AND after (AC-2; §2.10 一级 2 行 = 2×正文行 23.4bp; REPOINTED by Story 3.11)
# Was 36bp = 2×18bp (naive old body); Story 3.11 re-anchored to 2×23.4bp = 46.8bp (§2.10 2行 under new body line).
test_chapter_spacing_36bp() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '\\def\\htu@chapter@beforeskip{46.8bp}' htuthesis.def 2>/dev/null && \
  grep -q '\\def\\htu@chapter@afterskip{46.8bp}' htuthesis.def 2>/dev/null
}
run_test "P0" "ATDD-2.5-03" "def chapter spacing = 46.8bp/46.8bp (REPOINTED by Story 3.11; AC-2, §2.10 2行=2×23.4)" test_chapter_spacing_36bp

# --- AC-3: Level 2 (section) xiaosan 15bp + centered + 9bp ---

# ATDD-2.5-04: cls section format uses \xiaosan (15bp) AND \centering (AC-3, TC-E2-23, §2.10 二级小三号居中)
# RED pre-impl: cls:404 is {\sffamily\sihao[...]} (14bp, no centering).
test_section_xiaosan_centered() {
  [[ -f "htuthesis.cls" ]] || return 1
  sed -n '/section={/,/^  },/p' htuthesis.cls 2>/dev/null \
    | grep -q 'format={\\sffamily\\xiaosan.*\\centering}'
}
run_test "P0" "ATDD-2.5-04" "section format = \\xiaosan + \\centering (AC-3, TC-E2-23)" test_section_xiaosan_centered

# ATDD-2.5-05: def section spacing = 9bp before AND after (AC-3; §2.10 二级 0.5 行)
# RED pre-impl: def:82/85 = 24bp/6bp.
test_section_spacing_9bp() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '\\def\\htu@section@beforeskip{11.7bp}' htuthesis.def 2>/dev/null && \
  grep -q '\\def\\htu@section@afterskip{11.7bp}' htuthesis.def 2>/dev/null
}
run_test "P0" "ATDD-2.5-05" "def section spacing = 11.7bp/11.7bp (REPOINTED by Story 3.11; AC-3, §2.10 0.5行=0.5×23.4)" test_section_spacing_9bp

# --- AC-4: Level 3 (subsection) sihao 14bp + indent 2ccwd ---

# ATDD-2.5-06: cls subsection format uses \sihao (14bp) AND indent=2\ccwd (AC-4, TC-E2-24, §2.10 三级四号居左空两格)
# RED pre-impl: cls:408/411 is indent=0pt + \banxiaosi (13bp).
test_subsection_sihao_indent() {
  [[ -f "htuthesis.cls" ]] || return 1
  local block
  block=$(sed -n '/subsection={/,/^  },/p' htuthesis.cls 2>/dev/null)
  echo "$block" | grep -q 'indent=2\\ccwd' && echo "$block" | grep -q 'format={\\sffamily\\sihao'
}
run_test "P0" "ATDD-2.5-06" "subsection = \\sihao + indent=2\\ccwd (AC-4, TC-E2-24)" test_subsection_sihao_indent

# --- AC-5: Level 4 (subsubsection) Songti bold + indent 2ccwd ---

# ATDD-2.5-07: cls subsubsection format uses \htu@songtibold (bold-SimSun family, option A) + indent=2\ccwd (AC-5, TC-E2-25)
# NOTE: original spec prescribed \rmfamily\bfseries, but ctex maps CJK bold → SimHei (not bold SimSun).
# Option A (verified empirically): \newCJKfontfamily\htu@songtibold{SimSun}[AutoFakeBold=2.5] → true 宋体加粗.
# RED pre-impl: cls:415/418 is indent=0pt + \sffamily (Heiti); no \htu@songtibold family defined.
test_subsubsection_songti_bold_indent() {
  [[ -f "htuthesis.cls" ]] || return 1
  local block
  block=$(sed -n '/subsubsection={/,/^  },/p' htuthesis.cls 2>/dev/null)
  echo "$block" | grep -q 'indent=2\\ccwd' && echo "$block" | grep -q 'format={\\htu@songtibold\\bfseries\\xiaosi'
  # also confirm the bold-SimSun family is defined
  grep -q '\\newCJKfontfamily\\htu@songtibold{SimSun}' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.5-07" "subsubsection = \\htu@songtibold (bold-SimSun, option A) + indent=2\\ccwd (AC-5, TC-E2-25)" test_subsubsection_songti_bold_indent

# --- Scope regression guards (must stay green) ---

# ATDD-2.5-08: body still uses \@setfontsize (R-3 mechanism preserved — never \setstretch)
test_body_uses_setfontsize() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\@setfontsize\\normalsize{\\htu@body@fontsize}{\\htu@body@baselineskip}' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.5-08" "body uses \\@setfontsize (R-3 mechanism preserved)" test_body_uses_setfontsize

# ATDD-2.5-09: no geometry parameter changes in .def (R-1 regression guard)
test_def_geometry_unchanged() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '\\def\\htu@topmargin{22mm}' htuthesis.def 2>/dev/null && \
  grep -q '\\def\\htu@bottommargin{17.5mm}' htuthesis.def 2>/dev/null && \
  grep -q '\\def\\htu@leftmargin{25mm}' htuthesis.def 2>/dev/null && \
  grep -q '\\def\\htu@rightmargin{25mm}' htuthesis.def 2>/dev/null
}
run_test "P0" "ATDD-2.5-09" "no geometry changes in .def (R-1 regression guard)" test_def_geometry_unchanged

# ATDD-2.5-10: counter separator externalized as hyphen (REPOINTED by Story 2.6; was "still period, Story 2.6 scope", R-12)
test_separator_unchanged() {
  [[ -f "htuthesis.def" ]] || return 1
  local count
  count=$(grep -c 'htu@.*separator.*-' htuthesis.def 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  # Story 2.6 added \htu@counter@separator{-} → expect >= 1 (was 0 pre-Story-2.6).
  [[ "$count" -ge 1 ]]
}
run_test "P0" "ATDD-2.5-10" "counter separator externalized \\htu@counter@separator{-} (repointed by Story 2.6, R-12)" test_separator_unchanged

# ATDD-2.5-11: header config unchanged — \fancyhead[CE]/[CO] present (Story 2.3 guard)
test_header_config_unchanged() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\fancyhead\[CE\]' htuthesis.cls 2>/dev/null && \
  grep -q '\\fancyhead\[CO\]' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.5-11" "header config unchanged \\fancyhead[CE]/[CO] (Story 2.3 guard)" test_header_config_unchanged

# ATDD-2.5-12: page-number footer unchanged — \fancyfoot[LE,RO] present (Story 2.4 guard)
test_pagenum_footer_unchanged() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '\\fancyfoot\[LE,RO\]{\\wuhao\\thepage}' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-2.5-12" "page-number footer unchanged \\fancyfoot[LE,RO] (Story 2.4 guard)" test_pagenum_footer_unchanged

# ATDD-2.5-13: chapter font unchanged — \sffamily\sanhao (三号 16bp Heiti, AC-2 font part)
test_chapter_font_unchanged() {
  [[ -f "htuthesis.cls" ]] || return 1
  sed -n '/chapter={/,/lofskip/p' htuthesis.cls 2>/dev/null \
    | grep -q 'format={\\sffamily\\sanhao'
}
run_test "P0" "ATDD-2.5-13" "chapter font unchanged \\sffamily\\sanhao (三号 16bp Heiti)" test_chapter_font_unchanged

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Critical Path Tests ==="

# ATDD-2.5-14: def subsection + subsubsection spacing = 11.7bp/11.7bp (AC-4/5; §2.10 0.5 行 = 0.5×23.4bp; REPOINTED by Story 3.11)
# Was 9bp = 0.5×18bp (naive old body); Story 3.11 re-anchored to 0.5×23.4bp = 11.7bp.
test_sub_spacing_9bp() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '\\def\\htu@subsection@beforeskip{11.7bp}' htuthesis.def 2>/dev/null && \
  grep -q '\\def\\htu@subsection@afterskip{11.7bp}' htuthesis.def 2>/dev/null && \
  grep -q '\\def\\htu@subsubsection@beforeskip{11.7bp}' htuthesis.def 2>/dev/null && \
  grep -q '\\def\\htu@subsubsection@afterskip{11.7bp}' htuthesis.def 2>/dev/null
}
run_test "P1" "ATDD-2.5-14" "def subsection/subsubsection spacing = 11.7bp/11.7bp (REPOINTED by Story 3.11; AC-4/5, §2.10 0.5行=0.5×23.4)" test_sub_spacing_9bp

# ATDD-2.5-15: backmatter still centers chapters (cls:117 unchanged — no regression from mainmatter change)
test_backmatter_chapter_centered() {
  [[ -f "htuthesis.cls" ]] || return 1
  sed -n '/\\renewcommand\\backmatter/,/%% 中文配置/p' htuthesis.cls 2>/dev/null \
    | grep -q 'chapter/format+=\\centering'
}
run_test "P1" "ATDD-2.5-15" "backmatter chapter centering retained (cls:117 unchanged)" test_backmatter_chapter_centered

# ATDD-2.5-16: body font size unchanged — \htu@body@fontsize{12bp} (小四号, AC-1)
test_body_fontsize_unchanged() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q '\\def\\htu@body@fontsize{12bp}' htuthesis.def 2>/dev/null
}
run_test "P1" "ATDD-2.5-16" "body font size unchanged \\htu@body@fontsize{12bp} (AC-1)" test_body_fontsize_unchanged

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: Secondary Tests ==="

# ATDD-2.5-17: no main.tex content changes (scope boundary)
test_main_tex_unchanged() {
  [[ -f "main.tex" ]] || return 1
  grep -q '\\documentclass\[doctor\]{htuthesis}' main.tex 2>/dev/null
}
run_test "P2" "ATDD-2.5-17" "no main.tex content changes (scope boundary)" test_main_tex_unchanged

# ATDD-2.5-18: no stray \setstretch or body \linespread introduced (R-3 — body must stay \@setfontsize)
test_no_setstretch_for_body() {
  [[ -f "htuthesis.cls" ]] || return 1
  # \setstretch must NOT appear for body; only allowed in cover \parbox (cls ~579-593). Check normalsize area clean.
  local normalsize_block
  normalsize_block=$(sed -n '/\\renewcommand\\normalsize/,/^}/p' htuthesis.cls 2>/dev/null)
  if echo "$normalsize_block" | grep -q '\\setstretch\|\\linespread'; then
    return 1
  fi
  return 0
}
run_test "P2" "ATDD-2.5-18" "no \\setstretch/\\linespread in normalsize (R-3 body mechanism)" test_no_setstretch_for_body

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
  echo "   Driver tests (01-07,14) FAIL until the line-spacing/heading changes land"
  echo "   Guard tests (08-13,15-18) must STAY green (no regressions)"
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
