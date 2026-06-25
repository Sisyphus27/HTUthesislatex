#!/usr/bin/env bash
# test-story-6.2-unit.sh — ATDD Unit Tests for Story 6.2 (Footnote atomicity M1 + URL/DOI line-break xurl)
#
# TDD Phase: RED — the PRIMARY RED drivers are ATDD-6.2-U01 (M1 penalty absent pre-impl) and U02 (xurl
#   absent pre-impl). U03/U04 are structural guards (dual-dir parity, bash -n) that are GREEN by
#   construction post-impl and do not drive RED on their own.
#
# Scope: UNIT-level (source grep / diff / line-order / bash -n). The behavioral RED→GREEN proof
#   (footnote-band orphan-fragment fitz probe, revert-inject) lives in tests/test-story-6.2-footnote-atomicity.sh
#   (the C1 integration ATDD).
#
# Usage:
#   bash tests/test-story-6.2-unit.sh [--run]
#     --run   Remove SKIP marker (activate; green-phase verification). Default ATDD_SKIP=1 = RED scaffold inert.
#
# Priority: P0 (U01 M1-present RED driver + U02 xurl-present+order RED driver + U03 dual-dir parity + U04 bash -n gate)
# Linked ACs: AC-1/U01 (M1 present), AC-5/U02 (xurl after hyperref), AC-11/U01+U02 ([基础] comments),
#             AC-8/U03 (dual-directory parity), TC-E6-20/U04 (bash -n clean)
# Linked Risk: R-43 (M1 footnote atomicity — source presence), R-44 (xurl load-order), R-46 (dual-dir drift)
# TC coverage: TC-E6-14 source (U01/U02), TC-E6-19 (U03), TC-E6-13 (U02 order), TC-E6-20 (U04)
#
# SUT PROTECTION: read-only greps/diff on htuthesis/htuthesis.cls + htuthesis-v1.1.1/htuthesis.cls. No edits.
#
# Truth source: Story 6.2 spec + architecture.md §脚注原子化 + URL/DOI 换行美化 (Story 6.2, 2026-06-24) +
#   v1.1.1 cls:151-155 (xurl) + cls:431-437 (M1) — the proven references the canonical cls must become identical to.

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
echo "ATDD Unit Tests: Story 6.2 — Footnote atomicity (M1) + URL/DOI line-break (xurl), source-level"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped — run with --run post-impl)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ---------------------------------------------------------------------------
# ATDD-6.2-U01 (P0, *** RED DRIVER ***, TC-E6-14 source, AC-1/AC-11, R-43):
#   M1 penalty present in canonical htuthesis.cls: \interfootnotelinepenalty=10000 (non-comment line).
#   Pre-impl: 0 hits → RED. Post-impl: ≥1 → GREEN. Also asserts the [基础] comment (AC-11 transparent-deviation).
#   Comment-safe: grep -v '^[[:space:]]*%' excludes the [基础] comment block (which MENTIONS the penalty in prose).
test_u01_m1_penalty_present() {
  [[ -f "$CLS" ]] || return 1
  local cmd cmt
  cmd=$(grep -v '^[[:space:]]*%' "$CLS" | grep -c 'interfootnotelinepenalty=10000' || true)
  cmt=$(grep -c '脚注禁止跨页拆分\|interfootnotelinepenalty' "$CLS" || true)
  printf "    (interfootnotelinepenalty=10000 non-comment=%s, comment-mention=%s)\n" "$cmd" "$cmt" >&2
  [[ "$cmd" -ge 1 && "$cmt" -ge 1 ]]
}

# ---------------------------------------------------------------------------
# ATDD-6.2-U02 (P0, *** RED DRIVER ***, TC-E6-13/TC-E6-14 source, AC-4/AC-5/AC-11, R-44):
#   xurl present in canonical htuthesis.cls (\RequirePackage{xurl}, non-comment) AND loaded AFTER hyperref
#   (xurl line number > hyperref line number). Pre-impl: 0 xurl hits → RED. Post-impl: ≥1 + order correct → GREEN.
#   Also asserts the xurl [基础] comment (AC-11).
test_u02_xurl_present_after_hyperref() {
  [[ -f "$CLS" ]] || return 1
  local xurl_cmd xurl_ln hyper_ln cmt
  xurl_cmd=$(grep -v '^[[:space:]]*%' "$CLS" | grep -c 'RequirePackage{xurl}' || true)
  cmt=$(grep -c 'URL/DOI 行内换行美化\|RequirePackage{xurl}' "$CLS" || true)
  xurl_ln=$(grep -n 'RequirePackage{xurl}' "$CLS" | head -1 | cut -d: -f1)
  hyper_ln=$(grep -n 'RequirePackage{hyperref}' "$CLS" | head -1 | cut -d: -f1)
  local order_ok=0
  if [[ -n "$xurl_ln" && -n "$hyper_ln" && "$xurl_ln" -gt "$hyper_ln" ]]; then order_ok=1; fi
  printf "    (xurl non-comment=%s, xurl@line=%s, hyperref@line=%s, order-ok=%s, comment=%s)\n" \
    "$xurl_cmd" "${xurl_ln:-NA}" "${hyper_ln:-NA}" "$order_ok" "$cmt" >&2
  [[ "$xurl_cmd" -ge 1 && "$order_ok" -eq 1 && "$cmt" -ge 1 ]]
}

# ---------------------------------------------------------------------------
# ATDD-6.2-U03 (P0, TC-E6-19, AC-8, R-46): dual-directory parity (BOTH regions).
#   The M1 region (footmisc line through the \interfootnotelinepenalty=10000 line) + the xurl region
#   (the \RequirePackage{xurl} line + its [基础] comment) must match between canonical htuthesis.cls and
#   htuthesis-v1.1.1/htuthesis.cls (which already has both, verification-only). Extracts via awk, diffs.
#   GREEN post-impl (identical). NOTE: whole-file diff is NOT used — v1.1.1 cls differs elsewhere (user-content).
test_u03_dual_dir_parity() {
  [[ -f "$CLS" && -f "$V111_CLS" ]] || return 1
  # M1 block: from the footmisc line through the interfootnotelinepenalty=10000 line.
  local m1_a m1_b xurl_a xurl_b
  m1_a=$(awk '/usepackage\[perpage\]\{footmisc\}/{flag=1} flag{print} flag&&/interfootnotelinepenalty=10000/{flag=0; exit}' "$CLS")
  m1_b=$(awk '/usepackage\[perpage\]\{footmisc\}/{flag=1} flag{print} flag&&/interfootnotelinepenalty=10000/{flag=0; exit}' "$V111_CLS")
  # xurl block: from the [基础] URL/DOI comment through the RequirePackage{xurl} line.
  xurl_a=$(awk '/URL\/DOI 行内换行美化/{flag=1} flag{print} flag&&/RequirePackage\{xurl\}/{flag=0; exit}' "$CLS")
  xurl_b=$(awk '/URL\/DOI 行内换行美化/{flag=1} flag{print} flag&&/RequirePackage\{xurl\}/{flag=0; exit}' "$V111_CLS")
  # Guard against over-capture: if M1 is absent, the footmisc-awk runs to EOF (huge non-empty block).
  # Require the extracted M1 block to CONTAIN the penalty line (else the region is genuinely absent).
  local m1a_ok=0 m1b_ok=0
  [[ -n "$m1_a" && "$m1_a" == *"interfootnotelinepenalty=10000"* ]] && m1a_ok=1
  [[ -n "$m1_b" && "$m1_b" == *"interfootnotelinepenalty=10000"* ]] && m1b_ok=1
  if [[ "$m1a_ok" -eq 0 || "$m1b_ok" -eq 0 || -z "$xurl_a" || -z "$xurl_b" ]]; then
    echo "    [U03] a region absent (m1_canon_penalty=$m1a_ok m1_v111_penalty=$m1b_ok xurl_canon=$([ -n "$xurl_a" ] && echo ok || echo EMPTY) xurl_v111=$([ -n "$xurl_b" ] && echo ok || echo EMPTY))" >&2
    return 1
  fi
  # Compare NON-COMMENT lines only (extraction still anchors on the [基础] comment to LOCATE the block,
  # but the diff ignores comment prose → a legitimate comment-wording edit in one dir does NOT false-RED
  # when the code lines match). Review fix F15 (comment-wording-drift tripwire).
  diff <(printf '%s\n' "$m1_a" | grep -v '^[[:space:]]*%' | sed 's/[[:space:]]*$//') \
       <(printf '%s\n' "$m1_b" | grep -v '^[[:space:]]*%' | sed 's/[[:space:]]*$//') >/dev/null || return 1
  diff <(printf '%s\n' "$xurl_a" | grep -v '^[[:space:]]*%' | sed 's/[[:space:]]*$//') \
       <(printf '%s\n' "$xurl_b" | grep -v '^[[:space:]]*%' | sed 's/[[:space:]]*$//') >/dev/null
}

# ---------------------------------------------------------------------------
# ATDD-6.2-U04 (P0 gate, TC-E6-20, Epic 4 retro F1): bash -n clean on both 6.2 ATDD scripts.
#   Parse-fail = silent coverage hole. Every 6.x ATDD ships bash-n-verified before --run.
test_u04_bash_n_clean() {
  bash -n tests/test-story-6.2-unit.sh 2>/dev/null || return 1
  bash -n tests/test-story-6.2-footnote-atomicity.sh 2>/dev/null
}

echo "--- source-level assertions (U01/U02 are RED drivers; U03/U04 are structural guards) ---"
run_test P0 ATDD-6.2-U01 "M1 penalty present in canonical cls (interfootnotelinepenalty=10000 + [基础] comment, TC-E6-14, RED driver)" test_u01_m1_penalty_present
run_test P0 ATDD-6.2-U02 "xurl present + AFTER hyperref (order + [基础] comment, TC-E6-13/14, RED driver)" test_u02_xurl_present_after_hyperref
run_test P0 ATDD-6.2-U03 "dual-dir parity: M1 + xurl regions canonical vs v1.1.1 (TC-E6-19, R-46)" test_u03_dual_dir_parity
run_test P0 ATDD-6.2-U04 "bash -n clean on both 6.2 ATDD scripts (TC-E6-20, Epic 4 retro F1)" test_u04_bash_n_clean

echo ""
echo "=============================="
printf "Total: \033[32m%d PASS\033[0m  \033[31m%d FAIL\033[0m  \033[33m%d SKIP\033[0m\n" "$PASS" "$FAIL" "$SKIP_COUNT"
echo "=============================="

[[ "$SKIP" == "1" ]] && exit 0
[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
