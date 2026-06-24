#!/usr/bin/env bash
# test-story-5.3-integration.sh — ATDD Integration (fitz behavior) Tests for Story 5.3 (Real-data usage documentation)
#
# TDD Phase: RED — the PRIMARY RED drivers are I02/I03 (the v1.0.0 main.pdf footnote band has NO 蒋建忠/EB/OL).
#   Empirical probe 2026-06-23 (current v1.0.0 main.pdf, compiled with \footcite{XiJinPing}):
#     蒋建忠 in footnote band (y>H*0.62) = 0   (the sole 蒋建忠 is on page 62 end-list BODY, y/H=0.32 — excluded)
#     EB/OL  in footnote band (y>H*0.62) = 0   (the sole [EB/OL] is on page 62 end-list BODY — excluded)
#   Post-impl (Story 5.3 Task 2: chap01.tex:14 \footcite{XiJinPing} → \footfullcite{XiJinPing} + recompile):
#   the \footfullcite renders the full GB/T 7714 @online entry as a page-bottom footnote → 蒋建忠 + [EB/OL] present
#   in the footnote band of the 绪论 page → I02/I03 GREEN.
#
# *** ATYPICAL: this test targets htuthesis-v1.0.0/ (the real-thesis test instance), NOT canonical htuthesis/. ***
#   Reason: the \footcite→\footfullcite fix (AC-4) is v1.0.0-ONLY (canonical chap01:93 already uses \footfullcite
#   correctly). So the behavior proof MUST probe the v1.0.0 main.pdf. The script computes V100 = sibling
#   htuthesis-v1.0.0/ and compiles+probes THERE (each probe `cd "$V100"` in a subshell + relative "main.pdf" —
#   the Windows-native PyMuPDF cannot resolve Git-Bash POSIX paths like /d/..., so the probe MUST cd + use the
#   relative name, matching the test-story-5.4 idiom). Graceful SKIP+warn if V100 absent.
#
# Usage: bash tests/test-story-5.3-integration.sh [--run]
#   --run    Remove SKIP marker (activate; recompiles v1.0.0 + green-phase verification). Default ATDD_SKIP=1 = inert.
#
# Priority: P0 (the B1 acceptance proof — the rendered page-bottom \footfullcite entry)
# Linked ACs: AC-4 (chap01 \footcite→\footfullcite; fitz confirms page-bottom 蒋建忠+EB/OL)
# Linked Risk: R-37 (the \footcite misuse produced no page-bottom entry; \footfullcite restores it)
# TC coverage: TC-E5-18 (I01 compile + I02 蒋建忠 + I03 EB/OL — the B1 acceptance proof)
#
# Truth source: spec §2.14 (case-2 页下注, 每页重新编号) + §1.2.4 (GB/T 7714-2015) + v1.0.0 ref/refs.bib:9-15
#   (@online{XiJinPing, author={蒋建忠}, ...}). Reference PDF p22-24 confirms the case-2 页下注 full-entry form.

set -uo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DIR"

# v1.0.0 sibling dir (the real-thesis test instance; the AC-4 fix + probe target).
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

# Guard: v1.0.0 must exist for this test (atypical — targets the test instance, not canonical).
v100_ready() {
  [[ -n "$V100" && -f "$V100/main.tex" && -f "$V100/htuthesis.cls" ]]
}

# Shared Python header: opens main.pdf (RELATIVE — the probe runs inside `cd "$V100"` so "main.pdf" resolves to the
#   v1.0.0 PDF; the Windows-native PyMuPDF cannot resolve Git-Bash POSIX paths like /d/...).
#   footnote_band_has(needle): ≥1 span in the footnote band (any page) whose text contains `needle`.
#   The band y>H*0.62 EXCLUDES the end-list BODY entry on page 62 (蒋建忠 at y/H=0.32, [EB/OL] at y/H≈0.32) —
#   those are 参考文献 end-list text, NOT page-bottom footnotes. Post-fix, the \footfullcite page-bottom footnote
#   (绪论 page, y>H*0.62) carries 蒋建忠 + [EB/OL] → the band probe catches it.
PY_HEAD='
import fitz, sys
doc = fitz.open("main.pdf")
H = doc[0].rect.height
def footnote_band_has(needle):
    """≥1 span in the footnote band (y > H*0.62, any page) whose text contains needle."""
    hits = []
    for i in range(doc.page_count):
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type", 0) != 0: continue
            for ln in b.get("lines", []):
                for sp in ln.get("spans", []):
                    y0 = sp["bbox"][1]
                    if y0 > H * 0.62 and needle in sp["text"]:
                        hits.append((i, round(sp["size"], 1), sp["text"][:50]))
    return hits
'

echo "=============================================="
echo "ATDD Integration Tests: Story 5.3 — \\footcite→\\footfullcite (fitz on htuthesis-v1.0.0/main.pdf)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped — run with --run post-impl)" || echo "ACTIVE")"
echo "Target: $([ -n "$V100" ] && echo "$V100/main.pdf" || echo "(htuthesis-v1.0.0 NOT FOUND — will SKIP)")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests — v1.0.0 compile gate + the B1 acceptance proof (RED pre-fix)
# ==========================================
echo "=== P0: v1.0.0 compile gate (AC-4) + page-bottom 蒋建忠/EB/OL (TC-E5-18; *** RED DRIVER ***) ==="

# V100-absent guard (P1, code review 2026-06-23): ACTIVE mode + no v1.0.0 → SKIP (not FAIL) all 3. They target
#   the test instance; a machine without htuthesis-v1.0.0/ cannot run them. Mirrors check-structure.sh's
#   main.pdf-absent SKIP idiom + matches the header's "Graceful SKIP+warn if V100 absent" claim. In SKIP mode
#   (default), the run_test calls below emit yellow SKIP themselves — this guard only changes the ACTIVE-mode fate.
if [[ "$SKIP" == "0" ]] && ! v100_ready; then
  printf "\033[33m  [WARN] htuthesis-v1.0.0/ not found — AC-4 fix + probe target the test instance; 3 tests skipped (not failed).\033[0m\n"
  SKIP_COUNT=$((SKIP_COUNT + 3))
else

# ATDD-5.3-I01: v1.0.0 latexmk -xelatex -g main.tex exit 0 (AC-4 compile gate). The \footcite→\footfullcite change
#   must not break the v1.0.0 compile. Runs ONLY when activated (--run) + v1.0.0 present. ~3 min (full rebuild).
#   (P3, code review 2026-06-23): capture latexmk output to a temp log + tail on failure — a ~3-min compile that
#   fails with no diagnostic is opaque; the tail gives the last 15 log lines so the operator sees why.)
test_v100_compile() {
  v100_ready || return 1
  local log; log="$(mktemp)"
  ( cd "$V100" && latexmk -xelatex -g -interaction=nonstopmode main.tex ) > "$log" 2>&1
  local rc=$?
  if [[ $rc -ne 0 ]]; then
    printf "\033[31m  [diag] latexmk failed (rc=%d); last 15 log lines:\033[0m\n" "$rc"
    tail -15 "$log"
  fi
  rm -f "$log"
  return $rc
}
run_test "P0" "ATDD-5.3-I01" "v1.0.0 latexmk -xelatex -g main.tex exit 0 (AC-4 compile gate)" test_v100_compile

# ATDD-5.3-I02: BEHAVIOR — v1.0.0 main.pdf footnote band contains 蒋建忠 (AC-4, TC-E5-18, R-37) — RED DRIVER
#   Pre-fix (\footcite): 0 (the \footcite produces no page-bottom entry; 蒋建忠 only in end-list BODY page 62).
#   Post-fix (\footfullcite): ≥1 (the full GB/T 7714 @online entry renders as a page-bottom footnote on the 绪论 page).
#   Probe runs in a `cd "$V100"` subshell + relative "main.pdf" (Windows PyMuPDF can't resolve POSIX /d/... paths).
test_v100_footnote_jiang() {
  v100_ready || return 1
  [[ -f "$V100/main.pdf" ]] || return 1
  ( cd "$V100" && python -c "$PY_HEAD
hs = footnote_band_has('蒋建忠')
print('  蒋建忠 in footnote band (y>H*0.62): %d hits  pages(1-based): %s' % (len(hs), [h[0]+1 for h in hs]))
for h in hs[:5]: print('    p%d size=%.1f %r' % (h[0]+1, h[1], h[2]))
sys.exit(0 if len(hs) >= 1 else 1)
" )
}
run_test "P0" "ATDD-5.3-I02" "BEHAVIOR: v1.0.0 page-bottom footnote has 蒋建忠 (AC-4, TC-E5-18; *** RED DRIVER ***)" test_v100_footnote_jiang

# ATDD-5.3-I03: BEHAVIOR — v1.0.0 main.pdf footnote band contains EB/OL (AC-4, TC-E5-18, R-37) — RED DRIVER
#   The GB/T 7714 @online type designator [EB/OL] appears in the page-bottom footnote post-fix. Pre-fix: 0 in the
#   footnote band (the sole [EB/OL] is the end-list BODY entry page 62). Post-fix: ≥1.
test_v100_footnote_ebol() {
  v100_ready || return 1
  [[ -f "$V100/main.pdf" ]] || return 1
  ( cd "$V100" && python -c "$PY_HEAD
hs = footnote_band_has('EB/OL')
print('  EB/OL in footnote band (y>H*0.62): %d hits  pages(1-based): %s' % (len(hs), [h[0]+1 for h in hs]))
for h in hs[:5]: print('    p%d size=%.1f %r' % (h[0]+1, h[1], h[2]))
sys.exit(0 if len(hs) >= 1 else 1)
" )
}
run_test "P0" "ATDD-5.3-I03" "BEHAVIOR: v1.0.0 page-bottom footnote has EB/OL (AC-4, TC-E5-18; *** RED DRIVER ***)" test_v100_footnote_ebol

fi   # end V100-absent guard

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
  echo "   Run with --run flag or ATDD_SKIP=0 to activate (recompiles htuthesis-v1.0.0/, ~3 min)"
  echo "   RED drivers (FAIL pre-impl, PASS post-impl Story 5.3 Task 2 \\footcite→\\footfullcite):"
  echo "      I02 v1.0.0 page-bottom footnote 蒋建忠 (AC-4, TC-E5-18) — current: 0 in footnote band"
  echo "      I03 v1.0.0 page-bottom footnote EB/OL  (AC-4, TC-E5-18) — current: 0 in footnote band"
  echo "   GREEN gate:"
  echo "      I01 v1.0.0 latexmk exit 0 (AC-4 compile — the \\footfullcite must not break compile)"
  echo ""
  echo "   Target: htuthesis-v1.0.0/main.pdf (ATYPICAL — the fix is v1.0.0-only; canonical chap01:93 already"
  echo "      uses \\footfullcite[][26]{ding2001} correctly). Probe: cd \"\$V100\" + relative main.pdf (Windows PyMuPDF"
  echo "      can't resolve POSIX /d/... paths); footnote band y>H*0.62 (excludes end-list BODY)."
  echo "   Empirical RED baseline (2026-06-23): 蒋建忠 footnote-band=0 (sole hit p62 BODY y/H=0.32); EB/OL ditto."
  echo "   Truth source: spec §2.14 + §1.2.4 (case-2 页下注 GB/T 7714) + v1.0.0 ref/refs.bib:9-15 (@online XiJinPing 蒋建忠)."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
