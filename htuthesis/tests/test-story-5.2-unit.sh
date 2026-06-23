#!/usr/bin/env bash
# test-story-5.2-unit.sh — ATDD Unit (source-grep + bash -n) Tests for Story 5.2 (Bibliography self-check sentinel)
#
# TDD Phase: RED — the PRIMARY RED drivers are U03/U04 (the Makefile sentinel-check wiring is absent pre-impl).
#   Pre-impl (current tree): the sentinel script sentinel-bibliography-chapter.sh MAY exist (ATDD-provided) but the
#   Makefile `test` chain is still `compile-check lint-check structure-check` (no sentinel-check) AND no
#   `sentinel-check:` target is defined → U03/U04 FAIL. Post-impl (Story 5.2 Task 3): the `test` chain includes
#   `sentinel-check` + the target is defined → U03/U04 GREEN.
#
#   U01/U02/U05 verify the sentinel script ITSELF is sound (exists, rendered-span-anchored, bash -n clean). These are
#   GREEN once the ATDD-provided sentinel is in place — they guard the sentinel's construction, not the wiring.
#
# Usage: bash tests/test-story-5.2-unit.sh [--run]
#   --run    Remove SKIP marker (activate; green-phase verification). Default ATDD_SKIP=1 = RED scaffold inert.
#
# Priority: P0 (the sentinel wiring + construction — the detection layer)
# Linked ACs: AC-4 (sentinel wired into make test), AC-5 (rendered-span-anchored, NOT proxied), AC-7 (bash -n clean)
# Linked Risk: R-35 (sentinel wrong-target-AC tension — U02 enforces rendered-span anchor), R-33 (parse-fail = silent hole — U05)
# TC coverage: TC-E5-13 (U03/U04 — make test wiring), TC-E5-14 (U02 — rendered-span audit), TC-E5-23 (U05 — bash -n)
#
# Why source-grep (not fitz): the sentinel script sentinel-bibliography-chapter.sh is ITSELF the fitz probe. This unit
#   test audits the sentinel's CONSTRUCTION (rendered-anchored? exists?) + its WIRING (in make test?). The sentinel's
#   own behavior (GREEN on current tree, RED on --inject) is verified by running the sentinel directly — see the
#   checklist's "Test Execution Evidence" section.
#
# Truth source: NFR-4 (silent-failure #15) + NFR-6 + Story 5.2 spec (R-35: rendered-span-anchored sentinel wired into make test).

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

SENTINEL="tests/sentinel-bibliography-chapter.sh"
MAKEFILE="Makefile"

# ATDD-5.2-U01 (P0, AC-4, TC-E5-13): the sentinel script EXISTS in tests/. Pre-impl (before ATDD provides it): RED.
#   Post-ATDD (sentinel provided): GREEN. This is a construction guard — the sentinel file must be present to wire in.
test_u01_sentinel_exists() {
  [[ -f "$SENTINEL" ]]
}

# ATDD-5.2-U02 (P0, *** RED-CONSTRUCTION-GUARD ***, TC-E5-14, AC-5, R-35): the sentinel is RENDERED-SPAN-ANCHORED —
#   it uses fitz + get_text on main.pdf (the rendered PDF), NOT a proxied .bbl/.aux/source-grep as the PASS/FAIL gate.
#   A proxied check is the wrong-target-AC trap (Epic 3 retro Lesson 3 / R-25) — it can PASS while the chapter is absent.
#   This audit enforces the rendered anchor exists (fitz + get_text + main.pdf). GREEN once the ATDD-provided sentinel
#   (which uses the fitz probe) is in place.
test_u02_sentinel_rendered_anchored() {
  [[ -f "$SENTINEL" ]] || return 1
  # fitz + get_text + main.pdf must ALL appear (the rendered-span probe is the gate).
  grep -q 'import fitz' "$SENTINEL" \
    && grep -q 'get_text' "$SENTINEL" \
    && grep -q 'main.pdf' "$SENTINEL"
}

# ATDD-5.2-U03 (P0, *** RED DRIVER ***, TC-E5-13, AC-4, R-35): the Makefile `test` target chain INCLUDES sentinel-check.
#   Pre-impl: `^test:` line is `compile-check lint-check structure-check` (no sentinel-check) → RED.
#   Post-impl (Story 5.2 Task 3.2): `test: compile-check lint-check structure-check sentinel-check` → GREEN.
#   This is the detection-layer-dividend AC — the sentinel runs on EVERY make test.
test_u03_makefile_test_chain_has_sentinel() {
  [[ -f "$MAKEFILE" ]] || return 1
  grep -E '^test:' "$MAKEFILE" | grep -q 'sentinel-check'
}

# ATDD-5.2-U04 (P0, *** RED DRIVER ***, TC-E5-13, AC-4): the Makefile DEFINES a sentinel-check target.
#   Pre-impl: no `^sentinel-check:` line → RED. Post-impl (Story 5.2 Task 3.1): target defined → GREEN.
test_u04_makefile_sentinel_target_defined() {
  [[ -f "$MAKEFILE" ]] || return 1
  grep -qE '^sentinel-check:' "$MAKEFILE"
}

# ATDD-5.2-U05 (P0, TC-E5-23, AC-7, R-33): the sentinel script passes `bash -n` (syntax check).
#   Pre-impl (sentinel absent): bash -n fails on the missing file → RED. Post-ATDD: parse-clean → GREEN.
#   A parse-fail is a silent coverage hole (Epic 4 retro Lesson 1 / F1) — worse than no sentinel if wired into make test.
test_u05_sentinel_bash_n_clean() {
  [[ -f "$SENTINEL" ]] || return 1
  bash -n "$SENTINEL" 2>/dev/null
}

echo "=============================================="
echo "ATDD Unit Tests: Story 5.2 — Bibliography self-check sentinel (wiring + construction audit)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped — run with --run post-impl)" || echo "ACTIVE")"
echo "=============================================="
echo ""

run_test P0 ATDD-5.2-U01 "sentinel script sentinel-bibliography-chapter.sh exists (AC-4)" test_u01_sentinel_exists
run_test P0 ATDD-5.2-U02 "sentinel is rendered-span-anchored — fitz + get_text + main.pdf (TC-E5-14, AC-5, RED-construction-guard)" test_u02_sentinel_rendered_anchored
run_test P0 ATDD-5.2-U03 "Makefile test chain includes sentinel-check (TC-E5-13, AC-4, RED driver)" test_u03_makefile_test_chain_has_sentinel
run_test P0 ATDD-5.2-U04 "Makefile defines sentinel-check target (TC-E5-13, AC-4, RED driver)" test_u04_makefile_sentinel_target_defined
run_test P0 ATDD-5.2-U05 "sentinel passes bash -n (TC-E5-23, AC-7, R-33)" test_u05_sentinel_bash_n_clean

echo ""
echo "=============================="
printf "Total: \033[32m%d PASS\033[0m  \033[31m%d FAIL\033[0m  \033[33m%d SKIP\033[0m\n" "$PASS" "$FAIL" "$SKIP_COUNT"
echo "=============================="

# RED scaffolds (SKIP=1) exit 0 so the suite lists inert; activated (--run) exits non-zero on any FAIL.
[[ "$SKIP" == "1" ]] && exit 0
[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
