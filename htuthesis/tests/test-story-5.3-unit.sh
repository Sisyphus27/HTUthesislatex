#!/usr/bin/env bash
# test-story-5.3-unit.sh — ATDD Unit (source-grep + doc-grep) Tests for Story 5.3 (Real-data usage documentation)
#
# TDD Phase: RED — the PRIMARY RED drivers are U01/U02/U03/U04/U05 (the docs + chap01 source are pre-impl).
#   Pre-impl (current tree, empirically probed 2026-06-23):
#     U01  v1.0.0 chap01.tex:14 = \footcite{XiJinPing} (0 \footfullcite)               → RED
#     U02  "偶数页" (header-alternation term) in USAGE = 0 (both dirs; the 奇数页 at USAGE:57 is openright)  → RED
#     U03  bare \footcite (the misuse warning) in USAGE = 0 (both dirs; 8 \footfullcite but 0 bare)          → RED
#     U04  stale-TOC troubleshooting row (目录.*滞后 / 页码.*滞后) in USAGE = 0 (both dirs)                  → RED
#     U05  README "常见误区"/non-obvious pointer in BOTH dirs = 0                                           → RED
#   Post-impl (Story 5.3 Task 1 + Task 2): the 3 doc additions land on both USAGE + README pointer + chap01
#   \footcite→\footfullcite → U01/U02/U03/U04/U05 GREEN.
#
#   NOTE: the [] placeholder inventory (AC-5, TC-E5-19) is NOT a unit test here. AC-5 is a DECISION POINT — the
#   deliverable is the inventory + decision log recorded in the story Completion Notes (Zy's per-site decisions),
#   NOT an automated count-check. A count == 20 guard would false-fail the moment Zy fills/deletes any [] (the
#   intended AC-5 follow-up), and the SACROSANCT rule blocks editing the test to match — a trap. The inventory
#   lives in Completion Notes; this test suite does not encode the transient count. (Code review 2026-06-23 DN1.)
#
# Usage: bash tests/test-story-5.3-unit.sh [--run]
#   --run    Remove SKIP marker (activate; green-phase verification). Default ATDD_SKIP=1 = RED scaffold inert.
#
# Priority: P0 (U01 — the B1 source fix) + P1 (U02/U03/U04/U05 — the doc additions)
# Linked ACs: AC-1 (header alternation → U02), AC-2 (\footfullcite/\footcite → U03), AC-3 (fresh-TOC → U04),
#             AC-4 (chap01 \footfullcite source → U01), AC-6 (dual-dir → U02/U03/U04/U05)
# Linked Risk: R-37 (documentation discoverability — U02/U03/U04 verify the 3 non-obvious behaviors are documented)
# TC coverage: TC-E5-15 (U02), TC-E5-16 (U03), TC-E5-17 (U04), TC-E5-18 source-gate (U01)
#
# Why doc-grep (not fitz): the 3 documented behaviors are PROSE additions to USAGE.md/README.md. A source-grep
#   verifies the content EXISTS (the AC is "USAGE documents X"). The BEHAVIOR proof (chap01 \footfullcite renders
#   the page-bottom entry) is the integration test test-story-5.3-integration.sh I02/I03 (fitz on v1.0.0 main.pdf).
#   U01 is the SOURCE-gate for that behavior (chap01:14 must have \footfullcite); I02/I03 are the RENDERED proof.
#
# Dual-directory (AC-6): U02/U03/U04/U05 each require the pattern in BOTH htuthesis/ + htuthesis-v1.0.0/ USAGE/README.
#   The two dirs' docs are NOT byte-identical (minor divergence) but the ADDED blocks must be content-identical.
#
# Truth source: FR-33 (README/documentation) + spec §2.5 (header alternation) + §2.14/§1.2.4 (case-2 \footfullcite).

set -uo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DIR"

# v1.0.0 sibling dir (the real-thesis test instance; never git-add'd). TC-E5-18 source-gate targets it.
V100="$(cd "$DIR/../htuthesis-v1.0.0" 2>/dev/null && pwd)"

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

USAGE_C="USAGE.md"
USAGE_V="../htuthesis-v1.0.0/USAGE.md"
README_C="README.md"
README_V="../htuthesis-v1.0.0/README.md"

# ATDD-5.3-U01 (P0, *** RED DRIVER ***, TC-E5-18 source-gate, AC-4): v1.0.0 chap01.tex:14 has \footfullcite{XiJinPing}
#   (NOT \footcite). Pre-impl: line 14 = \footcite{XiJinPing} (bare-number, no page-bottom entry) → RED.
#   Post-impl (Story 5.3 Task 2.1): \footcite → \footfullcite → GREEN. This is the SOURCE-gate for the B1 fix; the
#   RENDERED proof (page-bottom "蒋建忠"+"EB/OL") is the integration test I02/I03.
test_u01_v100_chap01_footfullcite() {
  [[ -n "$V100" && -f "$V100/data/chap01.tex" ]] || return 1
  # line 14 must contain \footfullcite{XiJinPing} (the B1 fix). Pre-fix it is \footcite{XiJinPing}.
  sed -n '14p' "$V100/data/chap01.tex" | grep -q '\\footfullcite{XiJinPing}'
}

# ATDD-5.3-U02 (P1, *** RED DRIVER ***, TC-E5-15, AC-1, R-37): BOTH USAGE.md (canonical + v1.0.0) document header
#   odd/even alternation. The distinctive term is "偶数页" (even-page) — the existing "奇数页" at USAGE:57 is the
#   UNRELATED openright option (章节起始右页), NOT header alternation. Pre-impl: "偶数页" = 0 in both → RED.
#   Post-impl (Task 1.1): the header-alternation troubleshooting/FAQ adds "偶数页页眉为论文题目" → GREEN.
test_u02_header_alternation_in_both_usage() {
  [[ -f "$USAGE_C" && -f "$USAGE_V" ]] || return 1
  # "偶数页" must appear in BOTH dirs' USAGE (the new header-alternation content).
  grep -q '偶数页' "$USAGE_C" && grep -q '偶数页' "$USAGE_V"
}

# ATDD-5.3-U03 (P1, *** RED DRIVER ***, TC-E5-16, AC-2, R-37): BOTH USAGE.md document the \footcite WARNING.
#   Pre-impl: USAGE mentions \footfullcite (8×) but NOT the bare \footcite (0× — no reason to mention the wrong
#   command). The new warning (Task 1.2) adds a troubleshooting row + FAQ warning that \footcite in numeric style
#   produces only a bare number with no page-bottom entry. Note: \footfullcite does NOT contain the \footcite
#   substring (footfullcite = foot+fullcite; footcite is not a substring), so grep '\\footcite' uniquely matches
#   the bare command. Post-impl: bare \footcite ≥1 in both → GREEN.
test_u03_footcite_warning_in_both_usage() {
  [[ -f "$USAGE_C" && -f "$USAGE_V" ]] || return 1
  grep -q '\\footcite' "$USAGE_C" && grep -q '\\footcite' "$USAGE_V"
}

# ATDD-5.3-U04 (P1, *** RED DRIVER ***, TC-E5-17, AC-3, R-37): BOTH USAGE.md document the stale-TOC troubleshooting
#   row. Pre-impl: no "目录...滞后"/"页码...滞后" row in §11 故障排查 (USAGE §6 covers latexmk but §11 lacks the
#   stale-TOC symptom) → RED. Post-impl (Task 1.3): the troubleshooting row "目录页码滞后正文" added → GREEN.
test_u04_stale_toc_row_in_both_usage() {
  [[ -f "$USAGE_C" && -f "$USAGE_V" ]] || return 1
  # stale-TOC troubleshooting: 目录/页码 + 滞后 (lag) in BOTH dirs.
  local pat='目录.*滞后|页码.*滞后|滞后.*目录|滞后.*页码'
  grep -qE "$pat" "$USAGE_C" && grep -qE "$pat" "$USAGE_V"
}

# ATDD-5.3-U05 (P1, *** RED DRIVER ***, AC-1/2/3 README pointer, AC-6 dual-dir): BOTH README.md (canonical + v1.0.0)
#   have a "常见误区"/non-obvious-behaviors pointer (brief subsection pointing to USAGE for the 3 behaviors).
#   Pre-impl: README has no such subsection → RED. Post-impl (Task 1.4): the pointer added → GREEN.
test_u05_readme_pointer_in_both() {
  [[ -f "$README_C" && -f "$README_V" ]] || return 1
  # "常见误区" or "非显然"/"易误" pointer subsection in BOTH dirs' README.
  local pat='常见误区|易误解|非显然|Non-obvious|易错'
  grep -qE "$pat" "$README_C" && grep -qE "$pat" "$README_V"
}

echo "=============================================="
echo "ATDD Unit Tests: Story 5.3 — Real-data usage documentation (doc-grep + source-gate)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped — run with --run post-impl)" || echo "ACTIVE")"
echo "=============================================="
echo ""

run_test P0 ATDD-5.3-U01 "v1.0.0 chap01.tex:14 = \\footfullcite{XiJinPing} (TC-E5-18 source-gate, AC-4; *** RED DRIVER ***)" test_u01_v100_chap01_footfullcite
run_test P1 ATDD-5.3-U02 "BOTH USAGE document header alternation (偶数页; TC-E5-15, AC-1, R-37; *** RED DRIVER ***)" test_u02_header_alternation_in_both_usage
run_test P1 ATDD-5.3-U03 "BOTH USAGE have \\footcite bare-number warning (TC-E5-16, AC-2, R-37; *** RED DRIVER ***)" test_u03_footcite_warning_in_both_usage
run_test P1 ATDD-5.3-U04 "BOTH USAGE have stale-TOC troubleshooting row (TC-E5-17, AC-3, R-37; *** RED DRIVER ***)" test_u04_stale_toc_row_in_both_usage
run_test P1 ATDD-5.3-U05 "BOTH README have 常见误区 pointer (AC-1/2/3 README, AC-6; *** RED DRIVER ***)" test_u05_readme_pointer_in_both

echo ""
echo "=============================="
printf "Total: \033[32m%d PASS\033[0m  \033[31m%d FAIL\033[0m  \033[33m%d SKIP\033[0m\n" "$PASS" "$FAIL" "$SKIP_COUNT"
echo "=============================="

if [[ "$SKIP" == "1" ]]; then
  echo ""
  echo "TDD RED PHASE: All tests are SKIPPED"
  echo "   Run with --run flag or ATDD_SKIP=0 to activate"
  echo "   RED drivers (FAIL pre-impl, PASS post-impl Story 5.3 Task 1 + Task 2):"
  echo "      U01 v1.0.0 chap01:14 \\footfullcite{XiJinPing} (TC-E5-18 source, AC-4) — current: \\footcite"
  echo "      U02 header alternation 偶数页 in BOTH USAGE (TC-E5-15, AC-1) — current: 0 (both dirs)"
  echo "      U03 bare \\footcite warning in BOTH USAGE (TC-E5-16, AC-2) — current: 0 (8 \\footfullcite, 0 bare)"
  echo "      U04 stale-TOC row in BOTH USAGE (TC-E5-17, AC-3) — current: 0"
  echo "      U05 常见误区 pointer in BOTH README (AC-1/2/3, AC-6) — current: 0"
  echo ""
  echo "   AC-5 ([] inventory, TC-E5-19) is NOT automated — it is a manual Completion-Notes deliverable"
  echo "   (DECISION POINT: Zy's per-site decisions; no count-guard that would false-fail on fill/delete)."
  echo ""
  echo "   Truth source: FR-33 + spec §2.5 (header alternation) + §2.14/§1.2.4 (case-2 \\footfullcite)."
  echo "   Dual-dir (AC-6): U02/U03/U04/U05 require BOTH htuthesis/ + htuthesis-v1.0.0/."
  echo "   The RENDERED proof (page-bottom 蒋建忠+EB/OL) is test-story-5.3-integration.sh I02/I03."
fi

# RED scaffolds (SKIP=1) exit 0 so the suite lists inert; activated (--run) exits non-zero on any FAIL.
[[ "$SKIP" == "1" ]] && exit 0
[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
