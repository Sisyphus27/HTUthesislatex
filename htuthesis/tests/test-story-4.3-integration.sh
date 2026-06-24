#!/usr/bin/env bash
# test-story-4.3-integration.sh — ATDD Integration (compile + inject + fitz) Tests for Story 4.3 (debug + calibrate)
# TDD Phase: RED — the RED driver cluster is I03 ([doctor,debug] compile → main.log must contain a --- debug
#             diagnostics --- section ABSENT on the default compile — at baseline 23696b0 no \ifhtu@debug switch, so
#             [doctor,debug] is passed through to ctexbook and NO debug section emits), I04 (tools/calibrate.tex
#             standalone compile exit=0 + 1-page PDF — NO tools/ dir at baseline), I05 (fitz get_drawings rulers
#             present for all margins on calibrate.pdf — absent), I06 (calibrate \InputIfFileExists resilience —
#             compiles with overlay absent — absent), I07 (calibrate ruler dims match \htucheck textheight/textwidth
#             ±tolerance — absent), I08 (make debug-check clean→exit 0 — no target at baseline). GREEN guards: I01
#             (default compile exit=0/errors=0/warnings≤baseline+3/pages), I02 (default .log self-check 4.2 sections
#             font/coverage/audit PRESERVED — AC-8, [debug] gating must not leak), I09 (overfull inject → the NFR-5
#             grep contract catches it — mechanism proof pre+post, like 4.2-I04).
#
# Usage: bash tests/test-story-4.3-integration.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 (I01 compile gate + I02 AC-8 regression + I03 debug section + I04 calibrate standalone + I08 debug-check
#           target — the debug/calibrate pillars compiled) / P1 (I05 rulers + I06 InputIfFileExists + I07 accuracy +
#           I09 overfull mechanism)
# Linked ACs: AC-1 (debug option), AC-2 (verbose self-check), AC-3 (calibrate rulers/accuracy), AC-4 (calibrate
#             independent), AC-5 (InputIfFileExists), AC-6 (NFR-5 warnings as errors), AC-7 (Makefile targets), AC-8
#             (no regression)
# Linked Risk: R-29 (calibrate accuracy + independence — I04/I05/I07), R-25 (wrong-target-AC — I07 fitz-vs-\htucheck
#             agreement is rendered-vs-internal, not a self-check proxy)
# TC coverage: TC-E4-19 (I03 debug verbose), TC-E4-20 (I04 calibrate standalone), TC-E4-21 (I05 rulers), TC-E4-22 (I06
#              InputIfFileExists), TC-E4-23 (I07 accuracy), TC-E4-24 (I08 debug-check target)
#
# INJECT/TEMP-COMPILE PATTERN (extended from 4.2): LaTeX has no native assert-this-errors framework.
#   debug_copy <tmp>  — python-replaces \documentclass[doctor]{htuthesis} → [doctor,debug] in a temp <tmp>.tex (option
#                       REPLACEMENT, not line insertion; SUT untouched).
#   inject_copy       — python line-insertion into a temp copy (reused verbatim from 4.2; avoids awk/sed backslash
#                       noise on \documentclass/\end{document}).
#   calibrate temps   — tools/calibrate.tex is compiled IN PLACE (cd tools && xelatex); no temp copy (it IS the SUT
#                       deliverable, standalone by design AC-4).
#   Cleanup of .atdd-43-*.* + tools/calibrate.{aux,log,pdf} artifacts after each test where appropriate. SUT UNTOUCHED.
#
# Truth source: architecture.md §342 (debug 4b) + §343 (calibrate 4c) + §449-452 (\ifhtu@debug style) + §618-621 (tools/
#   boundary + \InputIfFileExists); htuthesis.def geometry (top 22/bottom 17.5/left+right 25/headheight 5.6/headsep
#   2.4/footskip 7.5 mm); test-design-epic-4.md R-29 + TC-E4-19..24.
#
# Line refs verified vs HEAD 23696b0: main.tex \documentclass = line 8 (\documentclass[doctor]{htuthesis}); \end{document}
#   = last line; \htucheck = cls:1060-1130 (4.2 self-check, no \ifhtu@debug); tools/ dir ABSENT; Makefile has no
#   calibrate/debug-check targets. Baseline compile: 1 warning, ~52 pages (Story 4.2 close-out).

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
    ((PASS++)) || true
  else
    red "[$priority] $test_id: $description"
    ((FAIL++))
  fi
}

# Makefile actual flags (Makefile:3)
LATEXMK="latexmk -xelatex -file-line-error -halt-on-error -interaction=nonstopmode"
CALIBRATE_XELATEX="xelatex -file-line-error -halt-on-error -interaction=nonstopmode"

# debug_copy <tmp_base>
#   Read main.tex, replace \documentclass[doctor]{htuthesis} → \documentclass[doctor,debug]{htuthesis}, write <tmp>.tex.
#   Scaffolding note: uses sed to exactly mirror the Makefile debug-check recipe (single source of truth) — robust +
#   keeps the test contract identical to the production target. The python-heredoc regex variant was unreliable in
#   this dev env; sed avoids that. Returns 0 if the replacement verified (grep guard), 1 else. SUT UNTOUCHED.
debug_copy() {
  local tmp="$1"
  sed 's/\\documentclass\[doctor\]{htuthesis}/\\documentclass[doctor,debug]{htuthesis}/' main.tex > "$tmp.tex"
  grep -q '\\documentclass\[doctor,debug\]{htuthesis}' "$tmp.tex" || { echo "NO_MATCH"; rm -f "$tmp.tex"; return 1; }
  return 0
}

# inject_copy <tmp_base> <anchor_regex> <inject_line> <before|after>
#   Read main.tex, find the first line matching <anchor_regex>, insert <inject_line> before/after it, write <tmp>.tex.
#   (Reused verbatim from 4.2.) Returns 0 if insertion verified, 1 on no-match. SUT UNTOUCHED.
inject_copy() {
  local tmp="$1" anchor="$2" line="$3" pos="$4"
  python - "$tmp" "$anchor" "$line" "$pos" <<'PY'
import re, sys
tmp, anchor, line, pos = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
src = open("main.tex", encoding="utf-8").read().splitlines()
out = []
inserted = False
for ln in src:
    if not inserted and re.search(anchor, ln):
        if pos == "before":
            out.append(line); out.append(ln)
        else:
            out.append(ln); out.append(line)
        inserted = True
    else:
        out.append(ln)
if not inserted:
    print("NO_MATCH"); sys.exit(1)
open(tmp + ".tex", "w", encoding="utf-8").write("\n".join(out) + "\n")
sys.exit(0)
PY
}

echo "=============================================="
echo "ATDD Integration Tests: Story 4.3 — debug mode and calibration tool (compile + inject + fitz)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# Shared state: the default compile (I01 gate) produces main.log + main.pdf; I02 reads main.log (no recompile).
COMPILE_OK=0
MAIN_LOG=""

# ==========================================
# P0 — AC-8, TC-E4-01-equivalent: default compile gate (GREEN — pre+post)
# ==========================================
echo "=== P0: default compile gate (AC-8, exit=0, errors=0, warnings<=baseline+3, pages) ==="

# I01: latexmk -xelatex -g main → exit 0; ^! errors = 0; warnings ≤ baseline(1)+3 = 4; pages ≥ 40. R-12 force (-g).
#   GREEN pre+post (4.2 baseline = 1 warning, ~52 pages). RED = 4.3 broke compilation. The [debug] option (when off)
#   adds no output → warning count stays ~1.
test_compile_gate() {
  $LATEXMK -g main.tex >/dev/null 2>&1
  local rc=$?
  [[ -f "main.log" ]] || { echo "  (main.log missing after compile — FAIL)"; return 1; }
  MAIN_LOG="main.log"
  local errors warnings
  errors=$(grep -cE '^\!' main.log 2>/dev/null | tr -d '[:space:]')
  warnings=$(grep -cE '^Package Memoir Warning|^LaTeX Warning|^Package biblatex Warning|^Package hyperref Warning|^Package fancyhdr Warning|Warning:' main.log 2>/dev/null | tr -d '[:space:]')
  local pages
  pages=$(python -c "import fitz; print(fitz.open('main.pdf').page_count)" 2>/dev/null || echo 0)
  echo "  compile rc=$rc errors=$errors warnings=$warnings pages=$pages (expect rc=0 errors=0 warnings<=4 pages>=40)"
  COMPILE_OK=1
  [[ "$rc" -eq 0 && "$errors" -eq 0 && "$warnings" -le 4 && "$pages" -ge 40 ]]
}
run_test "P0" "ATDD-4.3-I01" "default compile exit=0 errors=0 warnings<=4 pages>=40 (AC-8; GREEN gate — R-12 -g full recompile)" test_compile_gate

# ==========================================
# P0 — AC-8 regression guard: default .log self-check block preserves 4.2 sections (GREEN — pre+post)
# ==========================================
echo "=== P0: default .log self-check block preserves 4.2 sections (AC-8 regression guard) ==="

# I02: the DEFAULT (non-debug) compile's main.log self-check block must contain the 4.2 sections — markers + 8 dims +
#   font-check + coverage-map + assertion-audit. This is the AC-8 linchpin: [debug] gating must NOT leak into the
#   default path (the 4.2 sections stay always-on; only the NEW debug section is gated). GREEN pre+post (4.2 shipped
#   them). RED = 4.3 moved a 4.2 section behind [debug] (default compile lost it).
test_default_log_preserves_42_sections() {
  [[ "$COMPILE_OK" == "1" && -n "$MAIN_LOG" ]] || { echo "  (compile gate did not run — skip)"; return 1; }
  [[ -f "$MAIN_LOG" ]] || return 1
  python - "$MAIN_LOG" <<'PY'
import re, sys
log = open(sys.argv[1], encoding="utf-8", errors="replace").read()
blocks = re.findall(r'=== HTU Layout Self-Check ===.*?=== End Self-Check ===', log, re.DOTALL)
if not blocks:
    print("  (no self-check block in default .log — RED)"); sys.exit(1)
block = "\n".join(blocks)
dims = len(re.findall(r'^(textheight|textwidth|baselineskip|headheight|evensidemargin|oddsidemargin|total pages|page counter) =', block, re.M))
font = bool(re.search(r'font[ _-]?check|--- font', block, re.I))
cov  = bool(re.search(r'coverage|silent[ _-]?fail', block, re.I))
aud  = bool(re.search(r'assertion[ _-]?audit|proxied', block, re.I))
print("  dims=%d/8 font=%s coverage=%s audit=%s" % (dims, font, cov, aud))
sys.exit(0 if (dims >= 8 and font and cov and aud) else 1)
PY
}
run_test "P0" "ATDD-4.3-I02" "default .log self-check: markers + 8 dims + font + coverage + audit (AC-8; GREEN guard pre+post — [debug] gating must not leak)" test_default_log_preserves_42_sections

# ==========================================
# P0 — AC-1/2, TC-E4-19: [doctor,debug] compile → debug diagnostics section in .log (absent on default)
# ==========================================
echo "=== P0: [doctor,debug] compile → debug diagnostics section (AC-1/2, TC-E4-19) ==="

# I03: debug_copy .atdd-43-debug (main.tex with [doctor,debug]) → compile → .log must contain a debug-diagnostics
#   section that is ABSENT on the default compile. The CONTRAST (present in debug, absent in default) proves AC-1
#   (debug activates verbose output) + AC-2 (gated by \ifhtu@debug) + AC-8 (additive — default unchanged).
#   Pre-impl (23696b0): no \ifhtu@debug switch → [doctor,debug] passes to ctexbook (ignored), NO debug section emits in
#   either compile → the "present in debug" half fails → RED. Post-impl: \ifhtu@debug true → section emits.
test_debug_compile_emits_section() {
  [[ -f "main.tex" ]] || return 1
  local tmp=".atdd-43-debug"
  debug_copy "$tmp" || { echo "  (debug_copy failed — \\documentclass[doctor]{htuthesis} anchor no-match — abort)"; rm -f "$tmp".*; return 1; }
  $LATEXMK "$tmp.tex" >/dev/null 2>&1
  local rc=$?
  # debug-section marker present in the DEBUG compile .log? (capture stdout, not exit code — scaffolding fix)
  local dbg=0
  if [[ -f "$tmp.log" ]]; then
    dbg=$(python - "$tmp.log" <<'PY'
import re, sys
log = open(sys.argv[1], encoding="utf-8", errors="replace").read()
blocks = re.findall(r'=== HTU Layout Self-Check ===.*?=== End Self-Check ===', log, re.DOTALL)
block = "\n".join(blocks)
print(1 if re.search(r'debug[ _-]?diagnostic|debug[ _-]?mode|NFR-5|watch[ _-]?list', block, re.I) else 0)
PY
)
  fi
  # default compile (I01) must NOT have the debug section (additive gating, AC-8)
  local dflt=0
  if [[ "$COMPILE_OK" == "1" && -n "$MAIN_LOG" ]]; then
    dflt=$(python - "$MAIN_LOG" <<'PY'
import re, sys
log = open(sys.argv[1], encoding="utf-8", errors="replace").read()
blocks = re.findall(r'=== HTU Layout Self-Check ===.*?=== End Self-Check ===', log, re.DOTALL)
block = "\n".join(blocks)
print(1 if re.search(r'debug[ _-]?diagnostic|debug[ _-]?mode|NFR-5|watch[ _-]?list', block, re.I) else 0)
PY
)
  fi
  echo "  debug compile rc=$rc debug_section_in_debug=$dbg debug_section_in_default=$dflt (expect dbg=1 dflt=0 post-impl)"
  rm -f "$tmp".*
  # post-impl: debug section present in debug compile + absent in default. pre-impl: dbg=0 → FAIL.
  [[ "$dbg" -eq 1 && "$dflt" -eq 0 ]]
}
run_test "P0" "ATDD-4.3-I03" "[doctor,debug] → debug section in .log + absent on default (AC-1/2, TC-E4-19; *** RED DRIVER *** — no \\ifhtu@debug at 23696b0)" test_debug_compile_emits_section

# ==========================================
# P0 — AC-3/4, TC-E4-20: tools/calibrate.tex standalone compile → exit 0 + 1-page PDF
# ==========================================
echo "=== P0: tools/calibrate.tex standalone compile exit=0 (AC-3/4, TC-E4-20) ==="

# I04: compile tools/calibrate.tex INDEPENDENTLY (cd tools && xelatex; does NOT load htuthesis.cls — AC-4 independence).
#   Exit 0 + tools/calibrate.pdf exists + 1 page. Pre-impl (23696b0): NO tools/calibrate.tex → xelatex error → FAIL.
test_calibrate_standalone_compile() {
  [[ -f "tools/calibrate.tex" ]] || { echo "  (tools/calibrate.tex absent — RED, no tools/ dir at 23696b0)"; return 1; }
  ( cd tools && $CALIBRATE_XELATEX calibrate.tex >/dev/null 2>&1 )
  local rc=$?
  local pages=0
  [[ -f "tools/calibrate.pdf" ]] && pages=$(python -c "import fitz; print(fitz.open('tools/calibrate.pdf').page_count)" 2>/dev/null || echo 0)
  echo "  calibrate compile rc=$rc pages=$pages (expect rc=0 pages=1)"
  # cleanup calibrate aux artifacts (keep the .pdf for I05/I07 — those re-probe it; final cleanup at end)
  rm -f tools/calibrate.aux tools/calibrate.log
  [[ "$rc" -eq 0 && "$pages" -ge 1 ]]
}
run_test "P0" "ATDD-4.3-I04" "tools/calibrate.tex standalone compile exit=0 + 1-page PDF (AC-3/4, TC-E4-20; *** RED DRIVER *** — no tools/ at 23696b0)" test_calibrate_standalone_compile

# ==========================================
# P1 — AC-3, TC-E4-21: calibrate.pdf fitz rulers present for all margins
# ==========================================
echo "=== P1: calibrate.pdf TikZ rulers present for all margins (AC-3, TC-E4-21, R-29) ==="

# I05: fitz get_drawings on tools/calibrate.pdf → ruler/frame line segments present for the margins (top/bottom/left/
#   right body edges + header/footer). A calibrate page with TikZ rulers draws ≥4 distinct line/rect items spanning the
#   text box. Pre-impl (23696b0): no calibrate.pdf → FAIL. (Tolerant threshold: ≥4 drawn items — proves rulers exist;
#   I07 proves they're ACCURATE.)
test_calibrate_rulers_present() {
  [[ -f "tools/calibrate.pdf" ]] || { echo "  (tools/calibrate.pdf absent — RED; run I04 first or no calibrate.tex)"; return 1; }
  python - <<'PY'
import sys
import fitz
doc = fitz.open("tools/calibrate.pdf")
page = doc[0]
draws = page.get_drawings()
# count distinct stroked items (lines 'l', rects 're', curves 'c') — rulers produce many segments
items = 0
for d in draws:
    for it in d.get("items", []):
        if it[0] in ("l", "re", "c", "qu"):
            items += 1
print("  calibrate.pdf drawn items: %d [expect >=4 for margin rulers]" % items)
sys.exit(0 if items >= 4 else 1)
PY
}
run_test "P1" "ATDD-4.3-I05" "calibrate.pdf TikZ rulers present (≥4 drawn items, all margins) (AC-3, TC-E4-21; *** RED DRIVER *** — no calibrate.pdf at 23696b0)" test_calibrate_rulers_present

# ==========================================
# P1 — AC-5, TC-E4-22: calibrate \InputIfFileExists resilience (compiles with overlay absent)
# ==========================================
echo "=== P1: calibrate \\InputIfFileExists resilience — overlay absent (AC-5, TC-E4-22, architecture §621) ==="

# I06: calibrate.tex uses \InputIfFileExists for an optional overlay; with the overlay file ABSENT it must still compile
#   exit 0 (graceful degradation). Ensure no overlay present (rm if exists), compile, assert exit 0.
#   Pre-impl (23696b0): no calibrate.tex → FAIL. Post-impl: \InputIfFileExists false-branch → defaults → exit 0.
test_calibrate_inputifexists_resilience() {
  [[ -f "tools/calibrate.tex" ]] || { echo "  (tools/calibrate.tex absent — RED)"; return 1; }
  grep -qE '\\InputIfFileExists' tools/calibrate.tex || { echo "  (no \\InputIfFileExists in calibrate.tex — RED, see unit-04)"; return 1; }
  # Test the absent-overlay false-branch WITHOUT destroying the shipped deliverable: rename to a temp, restore after.
  # (Review P1 fix: the prior `rm -f tools/calibrate-overlay.cfg` deleted the tracked SUT file — git status showed `D`
  # after a --run. Rename+restore keeps the SUT intact regardless of compile outcome.)
  local bak="tools/.calibrate-overlay.cfg.atdd43bak"
  if [[ -f "tools/calibrate-overlay.cfg" ]]; then mv -f tools/calibrate-overlay.cfg "$bak"; fi
  ( cd tools && $CALIBRATE_XELATEX calibrate.tex >/dev/null 2>&1 )
  local rc=$?
  # restore the shipped overlay regardless of compile outcome (never leave the SUT missing a deliverable)
  if [[ -f "$bak" ]]; then mv -f "$bak" tools/calibrate-overlay.cfg; fi
  rm -f tools/calibrate.aux tools/calibrate.log
  echo "  calibrate compile (overlay absent) rc=$rc (expect rc=0 — graceful \\InputIfFileExists false-branch)"
  [[ "$rc" -eq 0 ]]
}
run_test "P1" "ATDD-4.3-I06" "calibrate \\InputIfFileExists resilience (overlay absent → exit 0) (AC-5, TC-E4-22; *** RED DRIVER *** — absent at 23696b0)" test_calibrate_inputifexists_resilience

# ==========================================
# P1 — AC-3, TC-E4-23: calibrate ruler dims match \htucheck textheight/textwidth (accuracy, R-29)
# ==========================================
echo "=== P1: calibrate ruler dims match \\htucheck textheight/textwidth (AC-3, TC-E4-23, R-29) ==="

# I07: the calibrate.pdf body-box (drawn rulers) must agree with \htucheck's textheight/textwidth within tolerance —
#   this is the R-29 accuracy guard (wrong calibration → wrong margins believed at physical review). fitz reads the
#   drawn rect/line spans on calibrate.pdf; reads textheight/textwidth from main.log \htucheck (pt → mm); compares.
#   Pre-impl (23696b0): no calibrate.pdf → FAIL. Generous ±5mm tolerance (ruler tick precision + pt→mm rounding).
test_calibrate_dims_match_htucheck() {
  [[ -f "tools/calibrate.pdf" ]] || { echo "  (tools/calibrate.pdf absent — RED)"; return 1; }
  [[ "$COMPILE_OK" == "1" && -n "$MAIN_LOG" ]] || { echo "  (default compile did not run — cannot read \\htucheck dims)"; return 1; }
  python - "$MAIN_LOG" <<'PY'
import re, sys, math
import fitz
log = open(sys.argv[1], encoding="utf-8", errors="replace").read()
# read \htucheck textheight/textwidth from the self-check block (pt)
def read_dim(name):
    m = re.search(r'^' + name + r'\s*=\s*([0-9.]+)pt', log, re.M)
    return float(m.group(1)) if m else None
th_pt = read_dim("textheight"); tw_pt = read_dim("textwidth")
if th_pt is None or tw_pt is None:
    print("  (could not read textheight/textwidth from \\htucheck in main.log — RED)"); sys.exit(1)
PT2MM = 25.4 / 72.275
th_mm = th_pt * PT2MM; tw_mm = tw_pt * PT2MM
# fitz: collect drawn rect widths/heights + line spans on calibrate.pdf page 0
doc = fitz.open("tools/calibrate.pdf")
page = doc[0]
rects = []  # (w_mm, h_mm) for each 're' item
hspans, vspans = [], []
for d in page.get_drawings():
    for it in d.get("items", []):
        if it[0] == "re":
            r = it[1]
            rects.append((abs(r.width), abs(r.height)))
        elif it[0] == "l":
            p1, p2 = it[1], it[2]
            dx, dy = abs(p1.x - p2.x), abs(p1.y - p2.y)
            if dx > dy * 2: hspans.append(dx)   # horizontal ruler
            elif dy > dx * 2: vspans.append(dy) # vertical ruler
allw = [w for w, _ in rects] + hspans
allh = [h for _, h in rects] + vspans
# find the drawn span closest to the htucheck dim
def closest(vals, target):
    return min(vals, key=lambda v: abs(v - target)) if vals else None
cw = closest([v * PT2MM for v in allw], tw_mm)
ch = closest([v * PT2MM for v in allh], th_mm)
dw = abs(cw - tw_mm) if cw is not None else None
dh = abs(ch - th_mm) if ch is not None else None
print("  \\htucheck textwidth=%.1fmm textheight=%.1fmm | closest calibrate ruler w=%s h=%s | Δw=%smm Δh=%smm" % (
    tw_mm, th_mm,
    ("%.1f" % cw) if cw else "none", ("%.1f" % ch) if ch else "none",
    ("%.1f" % dw) if dw is not None else "?", ("%.1f" % dh) if dh is not None else "?"))
ok = (dw is not None and dw <= 5.0 and dh is not None and dh <= 5.0)
sys.exit(0 if ok else 1)
PY
}
run_test "P1" "ATDD-4.3-I07" "calibrate ruler dims match \\htucheck textheight/textwidth ±5mm (AC-3, TC-E4-23; *** RED DRIVER *** — no calibrate.pdf at 23696b0)" test_calibrate_dims_match_htucheck

# ==========================================
# P0 — AC-6/7, TC-E4-24: debug-check contract runs, clean tree → exit 0
# ==========================================
echo "=== P0: debug-check contract clean tree → no NFR-5 warning (AC-6/7, TC-E4-24, NFR-5) ==="

# I08: the debug-check CONTRACT (sed [doctor,debug] + compile + 6-warning grep) must run clean on the default tree
#   (no NFR-5 warning present — 4.1/4.2 compile is clean). unit-06 verifies the Makefile `debug-check:` target
#   EXISTS; this test verifies the MECHANISM fires clean. Project convention: tests invoke latexmk directly (make is
#   absent on some Windows dev envs — verified here: `make` not on PATH); so this test runs the contract inline using
#   the SAME sed+latexmk+grep steps the Makefile debug-check target performs, AND asserts the Makefile target is
#   authored with those steps. If `make` IS available, it is invoked as a bonus. Pre-impl (23696b0): no target + no
#   [debug] section → FAIL. Post-impl: clean → 0 NFR-5 hits (excluding watch-list self-lines) → PASS.
test_debug_check_contract_clean() {
  [[ -f "Makefile" ]] || return 1
  grep -qE '^[[:space:]]*debug-check[[:space:]]*:' Makefile || { echo "  (no 'debug-check:' target — RED, see unit-06)"; return 1; }
  # the Makefile debug-check recipe must author the [doctor,debug] sed + 6-signature grep
  grep -qE "documentclass\\[doctor,debug\\]" Makefile || { echo "  (debug-check recipe missing [doctor,debug] sed — RED)"; return 1; }
  grep -qE "Overfull \\\\hbox|headheight is too low|Token not allowed in a PDF string" Makefile || { echo "  (debug-check recipe missing NFR-5 grep signatures — RED)"; return 1; }
  # run the contract inline (clean tree → expect 0 NFR-5 hits excluding the watch-list self-documentation lines)
  local tmp=".atdd-43-dc"
  sed 's/\\documentclass\[doctor\]{htuthesis}/\\documentclass[doctor,debug]{htuthesis}/' main.tex > "$tmp.tex"
  # P2 review fix: guard that the sed actually injected [doctor,debug] — a no-op sed (documentclass line changed)
  # would compile a non-debug main + grep a non-debug log → false-green. Abort if the replacement didn't take.
  grep -q '\\documentclass\[doctor,debug\]{htuthesis}' "$tmp.tex" || { echo "  (sed no-op — main.tex documentclass changed; [doctor,debug] not injected — RED)"; rm -f "$tmp".*; return 1; }
  $LATEXMK "$tmp.tex" >/dev/null 2>&1
  local rc=$?
  local hits=0
  if [[ -f "$tmp.log" ]]; then
    hits=$(grep -E 'Overfull \\hbox|geometry Warning: Over-specification|fancyhdr Warning: \\headheight is too low|natbib Warning: Citation.*undefined|Token not allowed in a PDF string|caption Warning' "$tmp.log" | grep -v -E 'watch.list|NFR-5 warning-as-error|^\[[0-9]\]|^\[debug\]' | wc -l | tr -d '[:space:]')
  fi
  echo "  debug-check contract inline: compile rc=$rc NFR-5 hits (excl watch-list) =$hits (expect rc=0 hits=0 clean)"
  rm -f "$tmp".*
  # bonus: if make is available, also exercise the actual target
  if command -v make >/dev/null 2>&1; then
    make debug-check >/dev/null 2>&1 && echo "  (make debug-check: exit 0 bonus)" || echo "  (make debug-check: non-zero — note)"
    rm -f .debug-main.*
  fi
  [[ "$rc" -eq 0 && "$hits" -eq 0 ]]
}
run_test "P0" "ATDD-4.3-I08" "debug-check contract clean tree → 0 NFR-5 hits (AC-6/7, TC-E4-24; *** RED DRIVER *** — no target + no [debug] at 23696b0)" test_debug_check_contract_clean

# ==========================================
# P1 — AC-6 mechanism: overfull inject → NFR-5 grep contract catches it (GREEN mechanism proof, pre+post)
# ==========================================
echo "=== P1: overfull inject → NFR-5 grep catches Overfull \\hbox (AC-6 mechanism, NFR-5) ==="

# I09: MECHANISM proof (like 4.2-I04) — proves the NFR-5 grep contract catches a REAL overfull warning. debug_copy
#   .atdd-43-overflow + inject_copy a too-wide \framebox before \end{document} (forces 'Overfull \hbox'); compile; grep
#   the .log for 'Overfull \hbox' using the SAME signature unit-07 / the Makefile debug-check target uses. Assert match.
#   GREEN pre+post: the overfull trigger + the 'Overfull \hbox' signature are LaTeX-constants independent of 4.3 impl.
#   The test's VALUE: (a) confirms the overfull trigger reliably produces the warning, (b) confirms the grep signature
#   matches — so when debug-check runs this grep on a real warning, it WILL flag it (warnings treated as errors).
#   (This does NOT call `make debug-check` — that compiles the clean main.tex which has no overfull; I08 covers the
#   target-exists+clean half. I09 covers the grep-catches-warning half. Together = full AC-6 contract, no SUT mutation.)
test_overfull_inject_caught() {
  [[ -f "main.tex" ]] || return 1
  local tmp=".atdd-43-overflow"
  debug_copy "$tmp" || { echo "  (debug_copy failed — abort)"; rm -f "$tmp".*; return 1; }
  # inject a too-wide framed box → forces Overfull \hbox (line wider than \textwidth)
  inject_copy "$tmp" '\\end\{document\}' '\noindent\framebox[1.5\textwidth]{overflow-trigger-for-atdd-43}' before || { echo "  (inject failed — \\end{document} anchor no-match — abort)"; rm -f "$tmp".*; return 1; }
  $LATEXMK "$tmp.tex" >/dev/null 2>&1
  local rc=$?
  local caught=0
  [[ -f "$tmp.log" ]] && caught=$(grep -cE 'Overfull \\hbox' "$tmp.log" 2>/dev/null | tr -d '[:space:]')
  echo "  overflow compile rc=$rc Overfull_hbox_lines=$caught (expect caught>=1 — the NFR-5 grep signature matches)"
  rm -f "$tmp".*
  # the overfull must appear + the grep signature must catch it (rc may be 0 — overfull is a warning, non-fatal)
  [[ "$caught" -ge 1 ]]
}
run_test "P1" "ATDD-4.3-I09" "overfull inject → NFR-5 grep catches 'Overfull \\hbox' (AC-6 mechanism, NFR-5; GREEN mechanism proof pre+post — grep contract independent of impl)" test_overfull_inject_caught

# Final cleanup of any calibrate.pdf left by I04/I06 (the SUT deliverable .tex stays; remove build artifacts + the
# probe-PDF so the tree is clean post-run; dev regenerates via `make calibrate`).
rm -f tools/calibrate.pdf tools/calibrate.aux tools/calibrate.log 2>/dev/null

echo ""
echo "=============================================="
echo "Summary: PASS=$PASS FAIL=$FAIL SKIP=$SKIP_COUNT"
echo "=============================================="
if [[ "$SKIP" == "1" ]]; then
  echo ""
  echo "   TDD RED phase — scaffolds inert (ATDD_SKIP=1). Activate with --run or ATDD_SKIP=0."
  echo "   RED drivers (FAIL pre-impl 23696b0, PASS post-impl debug+calibrate):"
  echo "      I03 [doctor,debug] → debug section in .log + absent on default (AC-1/2, TC-E4-19)"
  echo "      I04 tools/calibrate.tex standalone compile exit=0 (AC-3/4, TC-E4-20)"
  echo "      I05 calibrate.pdf TikZ rulers present (AC-3, TC-E4-21)"
  echo "      I06 calibrate \\InputIfFileExists resilience (AC-5, TC-E4-22)"
  echo "      I07 calibrate dims match \\htucheck ±5mm (AC-3, TC-E4-23, R-29)"
  echo "      I08 debug-check contract clean→0 NFR-5 hits (AC-6/7, TC-E4-24)"
  echo "   GREEN guards (PASS pre+post):"
  echo "      I01 default compile exit=0 errors=0 warnings<=4 pages>=40 (AC-8, R-12 -g)"
  echo "      I02 default .log self-check 4.2 sections preserved (AC-8 — [debug] gating must not leak)"
  echo "      I09 overfull inject → NFR-5 grep catches 'Overfull \\hbox' (AC-6 mechanism, NFR-5)"
  echo ""
  echo "   Inject/temp-compile pattern (extended from 4.2): debug_copy (option replace) + inject_copy (line insert)"
  echo "      into .atdd-43-*.tex temps; calibrate.tex compiled in place (standalone SUT deliverable). SUT untouched;"
  echo "      .atdd-43-*.* + tools/calibrate build artifacts cleaned up after each test (Epic 1 retro: no SUT mutation)."
  echo "   AC-8 is the linchpin: [debug] ADDS verbose output; it does NOT SUPPRESS the 4.2 baseline. I02 + unit-08"
  echo "      enforce it (default-compile self-check unchanged). I03 proves the gating is ADDITIVE (debug section"
  echo "      present in [doctor,debug], absent in default)."
  echo "   Wrong-target-AC (I07): calibrate accuracy = rendered fitz vs \\htucheck internal dims agreement, NOT a"
  echo "      self-check proxy (R-25). Source greps (unit) prove WIRING; integration proves MECHANISM."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
