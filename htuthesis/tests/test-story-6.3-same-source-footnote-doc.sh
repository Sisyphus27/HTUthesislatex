#!/usr/bin/env bash
# test-story-6.3-same-source-footnote-doc.sh — ATDD Unit Tests for Story 6.3
#   (Same-source footnote writing convention — Bug 3 documentation, doc-only / FR-33 / R-47)
#
# TDD Phase: RED — the PRIMARY RED driver is ATDD-6.3-U01 (§9.14 section absent in pre-fix USAGE.md).
#   Pre-impl: USAGE.md has NO "同源脚注" section → U01/U02 RED. Post-impl: §9.14 + §12 FAQ added → GREEN.
#
#   Doc-only story: NO compile, NO fitz, NO fixture. Tests are grep + content-audit on USAGE.md + a
#   no-cls-change guard (TC-E6-16). Mirrors test-story-6.2-unit.sh's harness (SKIP/--run/run_test/((PASS++))||true).
#
# Usage:
#   bash tests/test-story-6.3-same-source-footnote-doc.sh [--run]
#     --run   Remove SKIP marker (activate). Default ATDD_SKIP=1 = RED scaffold inert.
#
# Priority: P0 (U01 §9.14-present RED driver + U02 3-points content + U03 no-cls-change [hardened, E2/E3] + U04 bash-n + U05 dual-dir §9.14 parity + U06 §12 FAQ present)
# Linked ACs: AC-1/U02 (independent event), AC-2/U02 (cite-once convention), AC-3/U02 (B-2 rejected),
#             AC-5/U03 (NO cls change), AC-6/U05 (dual-dir), AC-7/U01 (grep-discoverable)
# Linked Risk: R-47 (Bug 3 documentation fidelity + the no-cls-change ruling guard)
# TC coverage: TC-E6-15 (U01), TC-E6-17 (U02), TC-E6-16 (U03), TC-E6-20 (U04)
#
# SUT PROTECTION: read-only greps/diff on USAGE.md (both dirs) + htuthesis.cls. No edits.
#
# Truth source: Story 6.3 spec + brainstorming-session-2026-06-24-154931.md Bug 3 (writing convention ruling +
#   B-2 6-risk rejection) + architecture.md §同源脚注重复裁定 + spec §2.14 case-2 (silent on same-page same-source).

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

USAGE="USAGE.md"
V111_USAGE="../htuthesis-v1.1.1/USAGE.md"
CLS="htuthesis.cls"
BASELINE="5cf45378da345883f34d44ee2b4bfb840b67c623"   # Story 6.2 committed state (the no-cls-change anchor)

echo "=============================================="
echo "ATDD Unit Tests: Story 6.3 — Same-source footnote writing convention (Bug 3 doc, doc-only)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped — run with --run post-impl)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ---------------------------------------------------------------------------
# ATDD-6.3-U01 (P0, *** RED DRIVER ***, TC-E6-15, AC-7): §9.14 present on BOTH USAGE.md.
#   grep "同源脚注" (the §9.14 header phrase) ≥1 hit in each of canonical + v1.1.1 USAGE.md.
#   Pre-impl: 0 hits → RED. Post-impl: ≥1 each → GREEN.
test_u01_section_present_both_dirs() {
  [[ -f "$USAGE" && -f "$V111_USAGE" ]] || return 1
  local canon v111
  canon=$(grep -c '同源脚注' "$USAGE" || true)
  v111=$(grep -c '同源脚注' "$V111_USAGE" || true)
  printf "    (同源脚注: canonical=%s, v1.1.1=%s; expect ≥1 each post-impl)\n" "$canon" "$v111" >&2
  [[ "$canon" -ge 1 && "$v111" -ge 1 ]]
}

# ---------------------------------------------------------------------------
# ATDD-6.3-U02 (P0, TC-E6-17, AC-1/AC-2/AC-3): the 3 points content-audited in canonical §9.14.
#   (a) "独立引用事件" (independent citation event); (b) "前注" (cite-once + 前注[N] convention);
#   (c) "故意不去重" (deliberately no dedup) OR "B-2" (the rejected scheme). All 3 ≥1 hit.
test_u02_three_points_content() {
  [[ -f "$USAGE" ]] || return 1
  local a b c
  a=$(grep -c '独立引用事件' "$USAGE" || true)
  b=$(grep -c '前注' "$USAGE" || true)
  c=$(grep -cE '故意不去重|B-2' "$USAGE" || true)
  printf "    (a 独立引用事件=%s, b 前注=%s, c 故意不去重|B-2=%s; expect ≥1 each)\n" "$a" "$b" "$c" >&2
  [[ "$a" -ge 1 && "$b" -ge 1 && "$c" -ge 1 ]]
}

# ---------------------------------------------------------------------------
# ATDD-6.3-U03 (P0, TC-E6-16, AC-5): NO cls change for Bug 3.
#   `git diff <baseline> -- htuthesis.cls` exits clean (no Bug-3-dedup code added). Also grep cls for
#   dedup-mechanism markers (\ifciteseen / ibidtracker) — 0 NEW hits (these are the B-2 rejected primitives).
test_u03_no_cls_change() {
  [[ -f "$CLS" ]] || return 1
  # Review fix E2: `git diff rc==0` does NOT prove "no change" (git diff returns 0 regardless of diff
  # presence — empirically false-green). Use an EMPTY-DIFF content check: the captured diff must be empty.
  local clsdiff
  clsdiff=$(git diff "$BASELINE" -- htuthesis/htuthesis.cls 2>/dev/null || true)
  # Review fix E3: broaden the dedup-primitive sentinel beyond the 3 named biblatex trackers to catch
  # differently-named dedup macros (e.g. \AtEveryCitekey + \footref, \ifsamepage hand-roll, custom names).
  local dedup
  dedup=$(grep -cE 'ifciteseen|ibidtracker|pagetracker|ifsamepage|AtEveryCitekey|footref|samesource' "$CLS" || true)
  printf "    (cls diff vs baseline chars=%s [expect 0=empty]; dedup-primitive hits=%s [expect 0])\n" "${#clsdiff}" "$dedup" >&2
  [[ -z "$clsdiff" && "$dedup" -eq 0 ]]
}

# ---------------------------------------------------------------------------
# ATDD-6.3-U04 (P0 gate, TC-E6-20, Epic 4 retro F1): bash -n clean on this 6.3 ATDD.
test_u04_bash_n_clean() {
  bash -n tests/test-story-6.3-same-source-footnote-doc.sh 2>/dev/null
}

# ---------------------------------------------------------------------------
# ATDD-6.3-U05 (P0, TC-E6-15, AC-6): dual-dir §9.14 parity.
#   The §9.14 block (from the "### 9.14 同源脚注" header through the next "### " header) must match
#   between canonical + v1.1.1 USAGE.md (the dual-dir policy requires identical doc content).
#   USAGE.md is prose (not code) — a verbatim block diff is the right check here.
test_u05_dual_dir_section_parity() {
  [[ -f "$USAGE" && -f "$V111_USAGE" ]] || return 1
  local block_a block_b
  # Review fix: removed the phantom `^### 9\.15` anchor (no §9.15 exists; the awk fell through to `## 10.`
  # anyway, but the dead anchor was a landmine for a future §9.15 addition silently truncating the block).
  block_a=$(awk '/^### 9\.14 同源脚注/{flag=1} flag{print} flag&&/^## 10\./{flag=0; exit}' "$USAGE")
  block_b=$(awk '/^### 9\.14 同源脚注/{flag=1} flag{print} flag&&/^## 10\./{flag=0; exit}' "$V111_USAGE")
  if [[ -z "$block_a" || -z "$block_b" ]]; then
    echo "    [U05] §9.14 block not found in one or both (canon=$([ -n "$block_a" ] && echo ok || echo EMPTY) v1.1.1=$([ -n "$block_b" ] && echo ok || echo EMPTY))" >&2
    return 1
  fi
  diff <(printf '%s\n' "$block_a") <(printf '%s\n' "$block_b") >/dev/null
}

# ---------------------------------------------------------------------------
# ATDD-6.3-U06 (P0, TC-E6-15, AC-4): §12 FAQ entry present on BOTH USAGE.md.
#   Review fix (Blind): U01-U05 target §9.14; the §12 FAQ Q/A (a stated part of the change, AC#4) had no
#   dedicated assertion — deleting the FAQ would pass U01-U05. This closes the coverage gap.
test_u06_faq_present_both_dirs() {
  [[ -f "$USAGE" && -f "$V111_USAGE" ]] || return 1
  local canon v111
  canon=$(grep -c '为什么同一句话对同一文献' "$USAGE" || true)
  v111=$(grep -c '为什么同一句话对同一文献' "$V111_USAGE" || true)
  printf "    (§12 FAQ Q: canonical=%s, v1.1.1=%s; expect ≥1 each)\n" "$canon" "$v111" >&2
  [[ "$canon" -ge 1 && "$v111" -ge 1 ]]
}

echo "--- doc-level assertions (U01 is the RED driver; U02/U03/U04/U05 are guards) ---"
run_test P0 ATDD-6.3-U01 "§9.14 同源脚注 section present on BOTH USAGE.md (TC-E6-15, RED driver)" test_u01_section_present_both_dirs
run_test P0 ATDD-6.3-U02 "3 points content-audited: 独立引用事件 + 前注 + 故意不去重/B-2 (TC-E6-17)" test_u02_three_points_content
run_test P0 ATDD-6.3-U03 "NO cls change for Bug 3 (git diff baseline clean + 0 dedup primitives; TC-E6-16)" test_u03_no_cls_change
run_test P0 ATDD-6.3-U04 "bash -n clean (TC-E6-20, Epic 4 retro F1)" test_u04_bash_n_clean
run_test P0 ATDD-6.3-U05 "dual-dir §9.14 block parity: canonical vs v1.1.1 (TC-E6-15, AC-6)" test_u05_dual_dir_section_parity
run_test P0 ATDD-6.3-U06 "§12 FAQ Q entry present on BOTH USAGE.md (TC-E6-15, AC-4)" test_u06_faq_present_both_dirs

echo ""
echo "=============================="
printf "Total: \033[32m%d PASS\033[0m  \033[31m%d FAIL\033[0m  \033[33m%d SKIP\033[0m\n" "$PASS" "$FAIL" "$SKIP_COUNT"
echo "=============================="

[[ "$SKIP" == "1" ]] && exit 0
[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
