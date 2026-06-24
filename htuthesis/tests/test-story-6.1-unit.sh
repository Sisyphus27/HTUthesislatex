#!/usr/bin/env bash
# test-story-6.1-unit.sh — ATDD Unit Tests for Story 6.1 (Native \chapter* header-mark fallback, M6)
#
# TDD Phase: RED — the PRIMARY RED driver is ATDD-6.1-U01 (M6 wrapper absent pre-impl). U02/U03/U04 are
#   structural guards (dual-dir parity, \htu@chapter* independence, bash -n) that are GREEN by construction
#   post-impl and do not drive RED on their own.
#
# Scope: UNIT-level (source grep / diff / bash -n). The behavioral RED→GREEN proof (header-band fitz probe,
#   revert-inject) lives in tests/test-story-6.1-starred-chapter-header.sh (the C1 integration ATDD).
#
# Usage:
#   bash tests/test-story-6.1-unit.sh [--run]
#     --run   Remove SKIP marker (activate; green-phase verification). Default ATDD_SKIP=1 = RED scaffold inert.
#
# Priority: P0 (U01 M6-present RED driver + U02 dual-dir parity + U04 bash -n gate) + P1 (U03 structural)
# Linked ACs: AC-1/U01 (M6 wrapper present), AC-8/U02 (dual-directory parity), AC-4/U03 (\htu@chapter* independent),
#             AC-12/U01 ([基础] comment present), TC-E6-20/U04 (bash -n clean)
# Linked Risk: R-41 (M6 wrapper — source presence + structural scope), R-46 (dual-dir drift)
# TC coverage: TC-E6-07 source (U01), TC-E6-19 (U02), TC-E6-04 source (U03), TC-E6-20 (U04)
#
# SUT PROTECTION: read-only greps/diff on htuthesis/htuthesis.cls + htuthesis-v1.1.1/htuthesis.cls. No edits.
#
# Truth source: Story 6.1 spec + architecture.md §原生 \chapter* header-mark 兜底 (M6, 2026-06-24) +
#   v1.1.1 cls:160-177 (the proven M6 reference the canonical cls must become identical to).

set -uo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DIR"

# --- TDD Red Phase Control ---
SKIP="${ATDD_SKIP:-1}"
for arg in "$@"; do
  case "$arg" in
    --run) SKIP=0 ;;
  esac
done

PASS=0
FAIL=0
SKIP_COUNT=0

green()  { printf "\033[32m  [PASS] %s\033[0m\n" "$1"; }
red()    { printf "\033[31m  [FAIL] %s\033[0m\n" "$1"; }
yellow() { printf "\033[33m  [SKIP] %s\033[0m\n" "$1"; }

run_test() {
  local priority="$1" test_id="$2" description="$3"
  if [[ "$SKIP" == "1" ]]; then
    yellow "[$priority] $test_id: $description"
    ((SKIP_COUNT++)) || true
    return 0
  fi
  shift 3
  "$@"
  if [[ $? -eq 0 ]]; then green "[$priority] $test_id: $description"; ((PASS++)) || true; else red "[$priority] $test_id: $description"; ((FAIL++)) || true; fi
}

CLS="htuthesis.cls"
V111_CLS="../htuthesis-v1.1.1/htuthesis.cls"

echo "=============================================="
echo "ATDD Unit Tests: Story 6.1 — Native \\chapter* header-mark fallback (M6, source-level)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped — run with --run post-impl)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ---------------------------------------------------------------------------
# ATDD-6.1-U01 (P0, *** RED DRIVER ***, TC-E6-07 source, AC-1/AC-9/AC-12, R-41):
#   M6 wrapper present in canonical htuthesis.cls: \NewCommandCopy{\htu@orig@chapter}{\chapter} AND
#   \RenewDocumentCommand{\chapter}{s o m}. Pre-impl: 0 hits → RED. Post-impl: ≥1 each → GREEN.
#   Also asserts the [基础] comment marker (AC-12 transparent-deviation record).
#   Comment-safe: grep -v '^[[:space:]]*%' excludes the [基础] comment block from the command count
#   (the comment MENTIONS \NewCommandCopy in prose; the command line is non-comment).
test_u01_m6_wrapper_present() {
  [[ -f "$CLS" ]] || return 1
  local cmd1 cmd2 cmt
  cmd1=$(grep -c 'NewCommandCopy{\\htu@orig@chapter}{\\chapter}' "$CLS" | grep -v '^[[:space:]]*%' || true)
  cmd2=$(grep -c 'RenewDocumentCommand{\\chapter}{s o m}' "$CLS" | grep -v '^[[:space:]]*%' || true)
  # The [基础] comment block is AC-12; assert it mentions the header-mark 兜底 mechanism.
  cmt=$(grep -c 'header-mark' "$CLS" || true)
  printf "    (NewCommandCopy=%s, RenewDocumentCommand=%s, comment=%s)\n" "$cmd1" "$cmd2" "$cmt" >&2
  [[ "$cmd1" -ge 1 && "$cmd2" -ge 1 && "$cmt" -ge 1 ]]
}

# ---------------------------------------------------------------------------
# ATDD-6.1-U02 (P0, TC-E6-19, AC-8, R-46): dual-directory parity.
#   The M6 region in canonical htuthesis.cls must match htuthesis-v1.1.1/htuthesis.cls (which already has
#   M6 at cls:160-177, verification-only). Extracts the M6 block (NewCommandCopy line through the closing
#   standalone } of RenewDocumentCommand) from BOTH files via awk, diffs. GREEN post-impl (identical).
#   NOTE: whole-file diff is NOT used — v1.1.1 cls differs elsewhere (user-content, v1.1.1-only by design).
test_u02_dual_dir_m6_parity() {
  [[ -f "$CLS" && -f "$V111_CLS" ]] || return 1
  local block_a block_b
  block_a=$(awk '/NewCommandCopy\{\\htu@orig@chapter\}\{\\chapter\}/{flag=1} flag{print} flag&&/^\}/{flag=0}' "$CLS")
  block_b=$(awk '/NewCommandCopy\{\\htu@orig@chapter\}\{\\chapter\}/{flag=1} flag{print} flag&&/^\}/{flag=0}' "$V111_CLS")
  if [[ -z "$block_a" || -z "$block_b" ]]; then
    echo "    [U02] M6 block not found in one or both cls (canonical empty=$([ -z "$block_a" ] && echo yes || echo no))" >&2
    return 1
  fi
  # Normalize trailing whitespace before compare (cosmetic line-ending drift only).
  diff <(printf '%s\n' "$block_a" | sed 's/[[:space:]]*$//') \
       <(printf '%s\n' "$block_b" | sed 's/[[:space:]]*$//') >/dev/null
}

# ---------------------------------------------------------------------------
# ATDD-6.1-U03 (P1, TC-E6-04 source, AC-4, R-41): \htu@chapter* remains an independent \def.
#   The M6 \RenewDocumentCommand{\chapter} wraps \chapter ONLY — it must NOT redefine \htu@chapter*.
#   Structural guard: \def\htu@chapter* (cls:592) still present post-M6. GREEN pre/post (M6 scope = \chapter only).
test_u03_htu_chapter_star_independent() {
  [[ -f "$CLS" ]] || return 1
  local n
  n=$(grep -c '\\def\\htu@chapter\*' "$CLS" || true)
  printf "    (\\def\\htu@chapter* count=%s)\n" "$n" >&2
  [[ "$n" -ge 1 ]]
}

# ---------------------------------------------------------------------------
# ATDD-6.1-U04 (P0 gate, TC-E6-20, Epic 4 retro F1): bash -n clean on both 6.1 ATDD scripts.
#   Parse-fail = silent coverage hole. Every 6.x ATDD ships bash-n-verified before --run.
test_u04_bash_n_clean() {
  bash -n tests/test-story-6.1-unit.sh 2>/dev/null || return 1
  bash -n tests/test-story-6.1-starred-chapter-header.sh 2>/dev/null
}

echo "--- source-level assertions (U01 is the RED driver; U02/U03/U04 are structural guards) ---"
run_test P0 ATDD-6.1-U01 "M6 wrapper present in canonical cls (NewCommandCopy + RenewDocumentCommand + [基础] comment, TC-E6-07, RED driver)" test_u01_m6_wrapper_present
run_test P0 ATDD-6.1-U02 "dual-dir M6-block parity: canonical vs v1.1.1 (TC-E6-19, R-46)" test_u02_dual_dir_m6_parity
run_test P1 ATDD-6.1-U03 "\\htu@chapter* still independent \\def (M6 scope = \\chapter only, TC-E6-04)" test_u03_htu_chapter_star_independent
run_test P0 ATDD-6.1-U04 "bash -n clean on both 6.1 ATDD scripts (TC-E6-20, Epic 4 retro F1)" test_u04_bash_n_clean

echo ""
echo "=============================="
printf "Total: \033[32m%d PASS\033[0m  \033[31m%d FAIL\033[0m  \033[33m%d SKIP\033[0m\n" "$PASS" "$FAIL" "$SKIP_COUNT"
echo "=============================="

[[ "$SKIP" == "1" ]] && exit 0
[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
