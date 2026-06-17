#!/usr/bin/env bash
# test-story-3.12-unit.sh — ATDD Unit Tests for Story 3.12 (References dual-mode citation — §2.14 case-2)
# TDD Phase: RED — ALL assertions are RED drivers (FAIL pre-impl, PASS post-impl). Pre-impl state (baseline after
#             Story 3.11): natbib `[numbers,super]` (cls:118) + `\bibliography{ref/refs}` end-only `thebibliography`
#             (cls:942-970, Story 3.7 reverse-hanging) → case-1 end-only mode. NONE of the case-2 wiring exists:
#             no biblatex, no `\addbibresource`, no `\printbibliography`, no `\footcite`, no type-sectioned end-list,
#             no §2.14 case-2 truth-source comment. Post-impl (Option A locked by Zy 2026-06-17): biblatex+biber+
#             `biblatex-gb7714-2015` backend, `\footcite` per-page citation footnotes, type-sectioned `\printbibliography`
#             end-list. Every unit test below asserts the POST-IMPL wiring → RED pre-impl, GREEN post-impl.
#
# Usage: bash tests/test-story-3.12-unit.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 (AC-7 mechanism wiring — biblatex backend) + P1 (AC-1/AC-3/AC-4 source-level guards)
# Linked ACs: AC-1 (citation footnote full entry), AC-3 (end-list type-sectioned re-grouped), AC-4 (\cite→\footcite),
#             AC-5 (per-page footnote reset preserved), AC-7 (Option A biblatex mechanism — LOCKED Zy 2026-06-17)
# Linked Risk: R-19 (score 4 — dual-mode citation mechanism change), R-12 (score 4 — biber cycle), R-16 (footnote reset)
# TC coverage: TC-E3-48 (P0 per-page citation footnote — wiring-level driver), TC-E3-49 (P1 end-refs present)
#
# NOTE: source-greps prove the WIRING (Option A biblatex backend swapped in, natbib removed, \footcite used,
#   type-sectioned \printbibliography, case-2 comment). The fitz behavior tests (test-story-3.12-integration.sh)
#   prove the RENDERED per-page citation footnotes + end-list. A source-grep alone does NOT prove the footnotes
#   render correctly (Decision 1) — but it is the wiring-level RED driver.
#
# Truth source: 河南师范大学研究生学位论文格式要求.md §2.14 line 291 (case-2 PRIORITY) + §1.2.4 line 109
#   (per-page renumber) + §2.4 line 197 (footnote 小五号宋体). spec is PRIORITY (CLAUDE.md Decision 4, corrected
#   2026-06-17). Reference PDF (2107084001-任子辛-...pdf p20-36 footnotes + p227 type-sectioned end-list) confirms.
#   See sprint-change-proposal-2026-06-17.md gap M1.

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
echo "ATDD Unit Tests: Story 3.12 — References dual-mode citation (§2.14 case-2, Option A biblatex)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests — AC-7 Option A biblatex backend wiring (RED drivers)
# ==========================================
echo "=== P0: AC-7 Option A biblatex backend wiring (RED drivers — pre-impl = natbib end-only) ==="

# ATDD-3.12-01: biblatex loaded with biber backend (AC-7 Option A) — RED driver
# Pre-impl: cls:118 = `\RequirePackage[numbers,super,sort&compress]{natbib}` (no biblatex) → FAIL.
# Post-impl: `\RequirePackage[backend=biber,...]{biblatex}` (cls idiom) → PASS.
test_biblatex_wired() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE '\\(RequirePackage|usepackage)\[backend=biber[^]]*\]\{biblatex\}' htuthesis.cls
}
run_test "P0" "ATDD-3.12-01" "biblatex loaded with backend=biber (AC-7 Option A; RED — pre-impl natbib)" test_biblatex_wired

# ATDD-3.12-02: natbib REMOVED (AC-7 Option A) — RED driver
# Pre-impl: `\RequirePackage[...]{natbib}` present (cls:118) → FAIL (when asserting absent).
# Post-impl: natbib gone (biblatex replaces it) → PASS. Exclude comments.
test_natbib_removed() {
  [[ -f "htuthesis.cls" ]] || return 1
  # no non-comment line requires natbib
  ! grep -vE '^\s*%' htuthesis.cls | grep -qE '\\usepackage(\[[^]]*\])?\{natbib\}|\\RequirePackage(\[[^]]*\])?\{natbib\}'
}
run_test "P0" "ATDD-3.12-02" "natbib RequirePackage/usepackage REMOVED (AC-7 Option A; RED — pre-impl present)" test_natbib_removed

# ATDD-3.12-03: biblatex-gb7714-2015 style configured (AC-7 Option A) — RED driver
# Pre-impl: no gb7714-2015 style → FAIL. Post-impl: `style=gb7714-2015` in biblatex options → PASS.
test_gb7714_style() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'style=gb7714-2015' htuthesis.cls
}
run_test "P0" "ATDD-3.12-03" "biblatex style=gb7714-2015 configured (AC-7 Option A; RED)" test_gb7714_style

# ATDD-3.12-04: \addbibresource wired (AC-7 Option A) — RED driver
# Pre-impl: `\bibliography{ref/refs}` (natbib/bibtex) → no \addbibresource → FAIL.
# Post-impl: `\addbibresource{ref/refs.bib}` → PASS.
test_addbibresource() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE '\\addbibresource\{[^}]*refs\.bib\}' htuthesis.cls
}
run_test "P0" "ATDD-3.12-04" "\\addbibresource{ref/refs.bib} wired (AC-7 Option A; RED — pre-impl \\bibliography)" test_addbibresource

echo ""

# ==========================================
# P1 Tests — AC-1/AC-4 citation-footnote command + AC-3 end-list type-sectioned (RED drivers)
# ==========================================
echo "=== P1: AC-1/AC-4 \\footcite command + AC-3 type-sectioned end-list (RED drivers) ==="

# ATDD-3.12-05: \footcite/\footfullcite used in sample chapter (AC-1/AC-4) — RED driver
# Pre-impl: data/chap03.tex uses `\cite{...}` / `\onlinecite{...}` (natbib) → no \footcite → FAIL.
# Post-impl: `\footcite{key}` / `\footfullcite{key}` present → PASS.
test_footcite_used() {
  [[ -f "data/chap03.tex" ]] || return 1
  grep -qE '\\foot(full)?cite' data/chap03.tex
}
run_test "P1" "ATDD-3.12-05" "\\footcite/\\footfullcite used in data/chap03.tex (AC-1/AC-4; RED — pre-impl \\cite/\\onlinecite)" test_footcite_used

# ATDD-3.12-06: natbib \onlinecite/\bibpunct/\NAT@ customizations REMOVED (AC-7 ripple) — RED driver
# Pre-impl: cls:936-941 has `\bibpunct`/`\NAT@citesuper`/`\onlinecite` → FAIL (asserting absent).
# Post-impl: biblatex has no NAT@ → these gone → PASS. Exclude comments.
test_natbib_customizations_removed() {
  [[ -f "htuthesis.cls" ]] || return 1
  ! grep -vE '^\s*%' htuthesis.cls | grep -qE '\\bibpunct|\\NAT@|\\onlinecite|\\DeclareRobustCommand\{\\onlinecite\}'
}
run_test "P1" "ATDD-3.12-06" "natbib customizations (\\bibpunct/\\NAT@/\\onlinecite) REMOVED (AC-7 ripple; RED — pre-impl present)" test_natbib_customizations_removed

# ATDD-3.12-07: end-list = \printbibliography (NOT \renewenvironment{thebibliography}) (AC-3/AC-7) — RED driver
# Pre-impl: cls:942 `\renewenvironment{thebibliography}` (Story 3.7) → FAIL (asserting \printbibliography present).
# Post-impl: `\printbibliography` (type-sectioned) replaces thebibliography → PASS.
test_printbibliography() {
  [[ -f "htuthesis.cls" ]] || return 1
  # \printbibliography wired (the end-list mechanism) AND the old thebibliography redef gone
  grep -vE '^\s*%' htuthesis.cls | grep -qE '\\printbibliography' && \
  ! grep -vE '^\s*%' htuthesis.cls | grep -qE '\\renewenvironment\{thebibliography\}'
}
run_test "P1" "ATDD-3.12-07" "end-list = \\printbibliography (thebibliography redef removed) (AC-3/AC-7; RED — pre-impl thebibliography)" test_printbibliography

# ATDD-3.12-08: end-list TYPE-SECTIONED re-grouping (AC-3 §2.14 case-2 "先按照文献类型分类") — RED driver
# Pre-impl: single continuous \bibliography (no type-sectioning) → FAIL.
# Post-impl: `\printbibliography[type=...]` sections (OR a biblatex sectioning config) → PASS.
test_endlist_type_sectioned() {
  [[ -f "htuthesis.cls" ]] || return 1
  # type-sectioned: \printbibliography[type=...] (one or more sections by entry type), OR an explicit section config
  grep -vE '^\s*%' htuthesis.cls | grep -qE '\\printbibliography\s*(\[type=|\[category=)'
}
run_test "P1" "ATDD-3.12-08" "end-list type-sectioned (\\printbibliography[type=...]) (AC-3 §2.14 case-2; RED — pre-impl continuous)" test_endlist_type_sectioned

echo ""

# ==========================================
# P1 Tests — AC-5 footnote reset preserved (GREEN guard) + AC-7 truth-source comment (RED driver)
# ==========================================
echo "=== P1: AC-5 per-page footnote reset preserved (GREEN) + AC-7 case-2 comment (RED) ==="

# ATDD-3.12-09: per-page footnote reset mechanism preserved (AC-5 — Story 3.8 regression) — GREEN guard
# The per-page reset (Story 3.8) must SURVIVE the biblatex switch. Either \@addtoreset{footnote}{page} (cls:369,
#   no-package Option A) OR \usepackage[perpage]{footmisc}. Citation footnotes SHARE this counter (AC-5).
# Pre-impl: \@addtoreset{footnote}{page} present (3.8) → PASS. Post-impl: still present (or footmisc) → PASS.
test_perpage_reset_preserved() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -vE '^\s*%' htuthesis.cls | grep -qE '@addtoreset\{footnote\}\{page\}' || \
  grep -vE '^\s*%' htuthesis.cls | grep -qE '\\usepackage\s*(\[[^]]*perpage[^]]*\])?\{footmisc\}'
}
run_test "P1" "ATDD-3.12-09" "per-page footnote reset preserved (AC-5 Story 3.8 regression; GREEN — \\@addtoreset OR footmisc[perpage])" test_perpage_reset_preserved

# ATDD-3.12-10: §2.14 case-2 dual-mode truth-source comment present (AC-7 Decision-4 documentation) — RED driver
# Pre-impl: no case-2 / dual-mode / 引文脚注 comment → FAIL. (The Story 3.8 explanatory-footnote comment at cls:358
#   mentions 页下注/每页重新编号 but is NOT dual-mode — it lacks 引文/case-2; excluded by requiring 引文 OR case-2.)
# Post-impl: a [基础] comment documenting §2.14 case-2 (per-page 引文 footnote citations + end-list) → PASS.
test_case2_comment() {
  [[ -f "htuthesis.cls" ]] || return 1
  # a comment citing §2.14 case-2 + the dual-mode 引文-footnote mechanism (case-2 OR 引文+脚注/页下注)
  grep -qE 'case-2|引文.{0,6}(脚注|页下注)|(脚注|页下注).{0,6}引文|dual-mode|引文参考文献' htuthesis.cls
}
run_test "P1" "ATDD-3.12-10" "§2.14 case-2 dual-mode truth-source comment present (AC-7 Decision 4; RED — pre-impl absent)" test_case2_comment

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
  echo "   RED drivers (FAIL pre-impl, PASS post-impl Option A):"
  echo "      3.12-01 biblatex backend=biber wired (AC-7)"
  echo "      3.12-02 natbib RequirePackage/usepackage REMOVED (AC-7)"
  echo "      3.12-03 biblatex style=gb7714-2015 (AC-7)"
  echo "      3.12-04 \\addbibresource{ref/refs.bib} (AC-7)"
  echo "      3.12-05 \\footcite/\\footfullcite in chap03 (AC-1/AC-4)"
  echo "      3.12-06 natbib customizations (\\bibpunct/\\NAT@/\\onlinecite) REMOVED (AC-7 ripple)"
  echo "      3.12-07 end-list = \\printbibliography (thebibliography redef removed) (AC-3/AC-7)"
  echo "      3.12-08 end-list type-sectioned (\\printbibliography[type=...]) (AC-3 §2.14 case-2)"
  echo "      3.12-10 §2.14 case-2 dual-mode truth-source comment (AC-7 Decision 4)"
  echo "   GREEN guard (PASS pre+post):"
  echo "      3.12-09 per-page footnote reset preserved (AC-5 Story 3.8 regression — \\@addtoreset OR footmisc)"
  echo ""
  echo "   Pre-impl baseline (after Story 3.11): natbib [numbers,super] (cls:118) + end-only thebibliography"
  echo "      (cls:942-970, Story 3.7 reverse-hanging) = §2.14 case-1. NONE of the case-2 wiring exists → all"
  echo "      RED drivers FAIL pre-impl. Post-impl (Option A biblatex, Zy 2026-06-17) → GREEN."
  echo "   NOTE: these source-greps prove the WIRING. The fitz behavior tests (test-story-3.12-integration.sh)"
  echo "      prove the RENDERED per-page citation footnotes (full GB/T 7714 entry, SimSun 9pt) + end-list."
  echo "      spec §2.14 line 291 (case-2 PRIORITY) + §1.2.4 line 109 (每页重新编号) + §2.4 line 197 (小五号宋体)."
  echo "      R-19 = 4; R-12 = 4 (biber cycle); R-16 = 4. Tests are read-only (no SUT mutation)."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
