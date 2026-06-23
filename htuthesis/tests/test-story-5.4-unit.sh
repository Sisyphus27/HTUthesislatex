#!/usr/bin/env bash
# test-story-5.4-unit.sh — ATDD Unit (source-grep) Tests for Story 5.4 (Footnote marker `[N]` bracketed numbering)
#
# TDD Phase: RED — the PRIMARY RED drivers are U01/U02/U03 (the cls \thefootnote line is absent pre-impl AND the
#   Story 3.8/3.12 bare-digit footnote-marker regexes are not yet repointed to [\d+]). Pre-impl (current tree):
#   - htuthesis.cls has NO \thefootnote redefinition (footmisc default \arabic{footnote} → bare digit 1,2,3).
#   - test-story-3.8-integration.sh:162 footnote_pages() + test-story-3.12-integration.sh:153 citation_footnote_pages()
#     + :186 footnote_pages() all use re.fullmatch(r"\d+", t) (bare digit) → would false-RED post-fix.
#   Post-impl (Story 5.4 Task 2 cls edit + Task 3 repoint): \thefootnote{[\arabic{footnote}]} present + 3 repoint
#   sites carry `\[(\d+)\]` + a `REPOINTED by Story 5.4` traceability comment → U01/U02/U03 GREEN.
#
#   U04 is a GREEN-guard (over-repoint guard): footer_num() (page numbers) must STAY bare-digit — it PASSES pre + post,
#   and FAILS only if the dev accidentally repointed page-number regexes too. U05 (bash -n) is a parse-fail guard.
#
# Usage: bash tests/test-story-5.4-unit.sh [--run]
#   --run    Remove SKIP marker (activate; green-phase verification). Default ATDD_SKIP=1 = RED scaffold inert.
#
# Priority: P0 (the cls fix wiring + the cross-story repoint + the over-repoint guard)
# Linked ACs: AC-1 (cls \thefootnote → U01), AC-5 (3.8/3.12 repoint → U02/U03; footer_num untouched → U04),
#             AC-9 (bash -n clean → U05)
# Linked Risk: R-39 (helper repoint — U02/U03 traceability), R-33 (parse-fail = silent hole — U05)
# TC coverage: TC-E5-26 (U02/U03 — repoint wiring), TC-E5-23 (U05 — bash -n)
#
# Why source-grep (not fitz): this unit test audits the WIRING (cls line present? helpers repointed? footer_num
#   untouched?). The RENDERED `[N]` markers are verified by test-story-5.4-integration.sh (fitz on main.pdf).
#
# Truth source: spec §1.2.4 示例1/2 + line 99 (顺序编码制 [N] EXPLICIT) + §2.14 line 289 (end-list [N] EXPLICIT) +
#   §1.2.4 line 109 / §2.5 line 197 SILENT on page-bottom lead shape → reference PDF p20-36 + GB/T 7714-2015 auxiliary.
#   See Story 5.4 Dev Notes for the full truth-source hierarchy + the empirical probe (reference 57+24 [N] / 0 bare).

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

CLS="htuthesis.cls"
T38="tests/test-story-3.8-integration.sh"
T312="tests/test-story-3.12-integration.sh"

# ATDD-5.4-U01 (P0, *** RED DRIVER ***, TC-E5-24, AC-1): htuthesis.cls defines \thefootnote as [N] (bracketed).
#   Pre-impl: NO renewcommand \thefootnote in the cls (footmisc default = \arabic{footnote} = bare digit) → RED.
#   Post-impl (Story 5.4 Task 2.1): \renewcommand\thefootnote{[\arabic{footnote}]} after cls:401 footmisc → GREEN.
#   Accepts either form: \renewcommand\thefootnote{...} or \renewcommand{\thefootnote}{...} — the distinctive token
#   is arabic{footnote} inside square brackets on the renewcommand line.
test_u01_cls_thefootnote_bracketed() {
  [[ -f "$CLS" ]] || return 1
  # The renewcommand line must reference thefootnote AND contain the [N] form (arabic{footnote} in brackets).
  grep -E 'renewcommand.*thefootnote' "$CLS" | grep -qF '[\arabic{footnote}]'
}

# ATDD-5.4-U02 (P0, *** RED DRIVER ***, TC-E5-26, AC-5, R-39, Decision 2): Story 3.8 footnote_pages() helper is
#   repointed from bare-digit (\d+) to bracketed (\[\d+\]). The traceability marker `REPOINTED by Story 5.4` must
#   appear (Decision 2 — never silently delete; repoint + document). Pre-impl: 0 matches → RED. Post-impl: ≥1 → GREEN.
test_u02_38_footnote_pages_repointed() {
  [[ -f "$T38" ]] || return 1
  grep -q 'REPOINTED by Story 5.4' "$T38"
}

# ATDD-5.4-U03 (P0, *** RED DRIVER ***, TC-E5-26, AC-5, R-39, Decision 2): Story 3.12 BOTH footnote-marker helpers
#   repointed — citation_footnote_pages() (:153) + footnote_pages() (:186). ≥2 `REPOINTED by Story 5.4` markers.
#   Pre-impl: 0 → RED. Post-impl: ≥2 → GREEN.
test_u03_312_footnote_helpers_repointed() {
  [[ -f "$T312" ]] || return 1
  local n
  n=$(grep -c 'REPOINTED by Story 5.4' "$T312" 2>/dev/null || echo 0)
  n=$(echo "$n" | tr -d '[:space:]' | head -1)
  [[ "$n" -ge 2 ]]
}

# ATDD-5.4-U04 (P0, *** GREEN-GUARD / OVER-REPOINT GUARD ***, AC-5): footer_num() (PAGE NUMBER) in 3.8/3.12 must
#   STAY bare-digit — it must NOT be repointed to [\d+]. Page numbers are Arabic bare digits by design (spec §2.4).
#   This guard PASSES pre-impl AND post-impl; it FAILS only if the dev over-repointed (repointed footer_num too),
#   which would false-RED every page-number AC. The discriminator: footnote marker = size 5-8 + footnote band;
#   page number = size 8-13 + footer band (y>H-70) — different regex targets.
test_u04_footer_num_stays_bare() {
  local f
  for f in "$T38" "$T312"; do
    [[ -f "$f" ]] || return 1
    # footer_num body (12 lines after def) must STILL contain the bare-digit fullmatch AND must NOT carry the
    # Story 5.4 repoint marker.
    grep -A12 'def footer_num' "$f" | grep -qF 'fullmatch(r"\d+"' || return 1
    grep -A12 'def footer_num' "$f" | grep -q 'REPOINTED by Story 5.4' && return 1
  done
  return 0
}

# ATDD-5.4-U05 (P0, TC-E5-23, AC-9, R-33): the repointed 3.8/3.12 test files pass `bash -n` (syntax check).
#   A parse-fail is a silent coverage hole (Epic 4 retro Lesson 1 / F1) — the repoint must not break bash quoting.
#   GREEN pre-impl (files parse clean today) AND post-impl (the regex change is inside a python string, bash-safe).
#   FAILS only if the repoint introduced a bash quoting error (e.g. an unescaped quote collapsed the PY_HEAD string).
test_u05_repointed_files_bash_n_clean() {
  [[ -f "$T38" ]] || return 1
  [[ -f "$T312" ]] || return 1
  bash -n "$T38" 2>/dev/null && bash -n "$T312" 2>/dev/null
}

echo "=============================================="
echo "ATDD Unit Tests: Story 5.4 — Footnote marker [N] (cls wiring + 3.8/3.12 repoint audit)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped — run with --run post-impl)" || echo "ACTIVE")"
echo "=============================================="
echo ""

run_test P0 ATDD-5.4-U01 "cls defines \\thefootnote as [N] bracketed (TC-E5-24, AC-1, RED driver)" test_u01_cls_thefootnote_bracketed
run_test P0 ATDD-5.4-U02 "3.8 footnote_pages() repointed to [N] (TC-E5-26, AC-5, RED driver, Decision 2)" test_u02_38_footnote_pages_repointed
run_test P0 ATDD-5.4-U03 "3.12 citation_footnote_pages + footnote_pages repointed (TC-E5-26, AC-5, RED driver)" test_u03_312_footnote_helpers_repointed
run_test P0 ATDD-5.4-U04 "footer_num STAYS bare-digit — over-repoint guard (AC-5, GREEN-guard)" test_u04_footer_num_stays_bare
run_test P0 ATDD-5.4-U05 "repointed 3.8/3.12 pass bash -n (TC-E5-23, AC-9, R-33)" test_u05_repointed_files_bash_n_clean

echo ""
echo "=============================="
printf "Total: \033[32m%d PASS\033[0m  \033[31m%d FAIL\033[0m  \033[33m%d SKIP\033[0m\n" "$PASS" "$FAIL" "$SKIP_COUNT"
echo "=============================="

echo ""
echo "RED drivers (FAIL pre-impl, PASS post-impl Story 5.4 Task 2 cls edit + Task 3 repoint):"
echo "   U01 cls \\thefootnote{[\\arabic{footnote}]} absent pre-impl (footmisc default = bare digit)"
echo "   U02 3.8 footnote_pages() bare-digit regex (fullmatch(r\"\\d+\")) not yet repointed to [\\d+]"
echo "   U03 3.12 citation_footnote_pages + footnote_pages not yet repointed (≥2 sites)"
echo "GREEN guards (PASS pre + post — lock-in / over-repoint guard):"
echo "   U04 footer_num (page number) stays bare-digit (AC-5 discriminator: size 5-8 footnote vs 8-13 footer)"
echo "   U05 repointed files bash -n clean (parse-fail = silent hole, Epic 4 retro F1)"
echo ""
echo "Rendered [N] verification (the REAL AC proof): test-story-5.4-integration.sh --run (fitz on main.pdf)."

# RED scaffolds (SKIP=1) exit 0 so the suite lists inert; activated (--run) exits non-zero on any FAIL.
[[ "$SKIP" == "1" ]] && exit 0
[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
