#!/usr/bin/env bash
# test-story-5.1-unit.sh — ATDD Unit (source-grep) Tests for Story 5.1 (Bibliography chapter heading decoupling)
#
# TDD Phase: RED — pre-impl the entry-point \htu@chapter*{\bibname} is ABSENT from \makebibliography
#   (cls:1013-1014: \nocite{*} is followed directly by \printbibliography[type=article,heading=htu-refs,...])
#   so U01/U02 FAIL on the current tree. Post-impl (Story 5.1 decouple): entry-point present after \nocite{*}
#   AND the first type=article section carries heading=htu-refs-sub → U01/U02 GREEN.
#
# Usage: bash tests/test-story-5.1-unit.sh [--run]
#   --run    Remove SKIP marker (activate; green-phase verification). Default ATDD_SKIP=1 = RED scaffold inert.
#
# Priority: P0 (source structure — the decouple wiring)
# Linked ACs: AC-4 (cls decouple structure: entry-point + first section htu-refs-sub),
#             AC-9 ([基础] comment + decision record; architecture.md:123-127 already recorded)
# Linked Risk: R-32 (heading-decouple double-title/regression — the structure must be exactly right)
# TC coverage: TC-E5-04 (P0 source-grep: entry-point present + first section htu-refs-sub)
#
# Why source-grep (not fitz): the INTEGRATION test (test-story-5.1-online-only-regression.sh) proves the
#   decouple RENDERERS (参考文献 present on a degenerate bib). This unit test pins the STRUCTURE that makes
#   it render — so a future refactor that breaks the structure is caught even if a representative sample
#   still happens to render the title (the sample-data-mask trap, R-33).
#
# Truth source: NFR-6 (参考文献 chapter independent of refs.bib type distribution) +
#   architecture.md:123-127 (§参考文献章标题与分节数据分布解耦). See Story 5.1 spec.

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

# ATDD-5.1-U01 (P0, *** RED DRIVER ***, TC-E5-04, R-32, AC-4):
#   Entry-point \htu@chapter*{\bibname} present in \makebibliography (NOT only in the \defbibheading{htu-refs}
#   definition). Pre-impl: the only \htu@chapter*{\bibname} is inside \defbibheading{htu-refs} (cls:1003) →
#   entry_point=0 → RED. Post-impl: +1 inside \makebibliography → entry_point>=1 → GREEN.
#   Robust to the retain-vs-delete decision for \defbibheading{htu-refs} (both yield entry_point>=1 post-fix).
test_u01_entry_point_present() {
  local total in_def entry_point
  total=$(grep -c '\\htu@chapter\*{\\bibname}' "$CLS" 2>/dev/null || true)
  in_def=$(grep -E '\\defbibheading\{htu-refs\}' "$CLS" | grep -c '\\htu@chapter\*{\\bibname}' 2>/dev/null || true)
  entry_point=$((total - in_def))
  [[ "$entry_point" -ge 1 ]]
}

# ATDD-5.1-U02 (P0, *** RED DRIVER ***, TC-E5-04, R-32, AC-4):
#   First type=article \printbibliography section uses heading=htu-refs-sub (NOT htu-refs).
#   Pre-impl: cls:1014 is heading=htu-refs → RED. Post-impl: heading=htu-refs-sub → GREEN.
test_u02_article_section_subheading() {
  grep -qE '\\printbibliography\[type=article,heading=htu-refs-sub' "$CLS"
}

# ATDD-5.1-U03 (P0, AC-9): [基础] decouple comment recorded in cls (Story 5.1 / NFR-6).
#   The decouple MUST be documented in a cls [基础] comment block (architecture.md:123-127 records it at the
#   design level; the cls comment is the implementation-level record). Pre-impl: absent → RED.
test_u03_decouple_comment() {
  # Match entry-point-specific comment markers (NOT bare 'NFR-6' — too broad, false-green risk; code review 2026-06-23 P6).
  grep -qE '参考文献 章标题入口|Story 5\.1 解耦|参考文献章标题与分节数据分布解耦' "$CLS"
}

# ATDD-5.1-U04 (P0, AC-4, R-32): NO \printbibliography section still uses heading=htu-refs (the main-title
#   heading). Post-decouple ALL sections are htu-refs-sub; htu-refs is retained (def only) but attached to
#   nothing. A residual heading=htu-refs on any section would re-couple title↔section → double-title risk (R-32).
#   Regex `heading=htu-refs(,|\])` matches htu-refs followed by option-separator (NOT htu-refs-sub, where `-` follows).
test_u04_no_section_on_main_heading() {
  if grep -qE '\\printbibliography.*heading=htu-refs(,|\])' "$CLS"; then
    return 1  # a section is still coupled to the main-title heading → NOT decoupled
  fi
  return 0
}

echo "=============================================="
echo "ATDD Unit Tests: Story 5.1 — Bibliography chapter heading decoupling (source-grep, TC-E5-04)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped — run with --run post-impl)" || echo "ACTIVE")"
echo "=============================================="
echo ""

run_test P0 ATDD-5.1-U01 "entry-point \htu@chapter*{\bibname} in \makebibliography (TC-E5-04, RED driver)" test_u01_entry_point_present
run_test P0 ATDD-5.1-U02 "first type=article section uses heading=htu-refs-sub (TC-E5-04, RED driver)" test_u02_article_section_subheading
run_test P0 ATDD-5.1-U03 "[基础] decouple comment recorded in cls (Story 5.1 / NFR-6, AC-9)" test_u03_decouple_comment
run_test P0 ATDD-5.1-U04 "no \printbibliography section still on heading=htu-refs (AC-4, R-32)" test_u04_no_section_on_main_heading

echo ""
echo "=============================="
printf "Total: \033[32m%d PASS\033[0m  \033[31m%d FAIL\033[0m  \033[33m%d SKIP\033[0m\n" "$PASS" "$FAIL" "$SKIP_COUNT"
echo "=============================="

# RED scaffolds (SKIP=1) exit 0 so the suite lists inert; activated (--run) exits non-zero on any FAIL.
[[ "$SKIP" == "1" ]] && exit 0
[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
