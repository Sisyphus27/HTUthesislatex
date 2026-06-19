#!/usr/bin/env bash
# test-story-3.11-integration.sh — ATDD Red-Phase Integration Tests for Story 3.11
# (body + abstract line-spacing calibration)
# TDD Phase: RED (the body + Chinese-abstract line-gap behavior tests FAIL on pre-impl [18bp];
#             compile + self-check geometry guards + English-abstract 23.4bp regression guard pass)
#
# Usage: bash tests/test-story-3.11-integration.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 tests are blocking
# Linked ACs: AC-1 (body baselineskip ≈23bp), AC-2 (R-3 trap excluded), AC-3 (Chinese-abstract inherits ≈23bp),
#             AC-4 (English-abstract 23.4bp UNCHANGED), AC-5 (textheight UNCHANGED), AC-7 (compile + regression)
# Linked Risk: R-18 (score 6, recalibration ripple — page-count rebaseline, body reflow), R-3 (score 6,
#              \setstretch/1.2× trap → 21.6bp), R-12 (.aux staleness — latexmk -g MANDATORY: baselineskip reflows
#              EVERY page), R-1 (textheight geometry must NOT change), R-14 (English-abstract 23.4bp independent)
# TC coverage: TC-E3-47 (P0 body baselineskip ≈23bp), TC-E3-50 (P1 Chinese-abstract inherits ≈23bp)
#
# NOTE: source-greps (unit) prove the \def value changed; these fitz tests prove the spacing RENDERS:
#   - ATDD-3.11-I04: self-check \the\baselineskip ≈ 23bp (AC-1/AC-2 — value band [22.5,24] excludes 18 AND 21.6)
#   - ATDD-3.11-I05: BEHAVIOR — fitz CJK BODY line-gap ≈ 23bp (AC-1 real proof, TC-E3-47). NEW line-gap helper.
#       Pre-impl: body baselineskip 18bp → body line-gap ≈18 → outside [22.5,24] → RED.
#   - ATDD-3.11-I06: BEHAVIOR — fitz CHINESE-ABSTRACT body line-gap ≈ 23bp (AC-3, TC-E3-50). Pre-impl inherits 18bp → RED.
#   - ATDD-3.11-I07: BEHAVIOR — fitz ENGLISH-ABSTRACT body line-gap = 23.4bp ±0.5 (AC-4 regression — UNCHANGED).
#       GREEN guard pre-impl (Story 3.4 R-14 already locked 23.4bp); this proves 3.11 did NOT drag it to the body value.
#   A self-check read alone does NOT prove the rendering (a \setstretch leak could corrupt it). The fitz line-gap
#   measurement on the compiled PDF is the rendered truth (Decision 1; Story 2.5/3.4/3.9 behavior-test lesson).
#
# fitz calibration notes (verified pre-impl on main.pdf at baseline 19623d0, post-Story-3.10):
#   - Body baselineskip = 18bp (htuthesis.def:62, naive ×fontsize). Body line-gap on a body page ≈ 18.07pt.
#   - Chinese-abstract body inherits \normalsize = 18bp (no local override) → line-gap ≈ 18.07pt.
#   - English-abstract body = 23.4bp (cls:891, Story 3.4 R-14) → line-gap ≈ 23.4pt (UNCHANGED by 3.11).
#   - Reference thesis 2107084001 body line-gap = 23.4pt (Word "1.5倍" = 1.5×小四 SimSun natural-line-height).
#   - Post-impl: body + Chinese-abstract → ≈23bp; English-abstract → 23.4bp (unchanged).
#   - The CJK body line-gap helper (cjk_body_lines + line_gap) is NEW for 3.11 (test-design-epic-3 Appendix).

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
echo "ATDD Integration Tests: Story 3.11 — Body and abstract line-spacing calibration"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# Shared Python header: opens main.pdf, finds the body / Chinese-abstract / English-abstract pages,
# defines the NEW CJK body-line-gap helper + the ASCII line-gap helper (reused from Story 3.4) + median.
PY_HEAD='
import fitz, sys, re
doc = fitz.open("main.pdf")
W = doc[0].rect.width; mid = W / 2.0
ascii_re = re.compile(r"[A-Za-z0-9]")
cjk_re = re.compile(r"[一-鿿]")
def mm(v): return v / 72.0 * 25.4
def median(xs):
    if not xs: return None
    ys = sorted(xs); n = len(ys); return ys[n // 2]
# Chinese-abstract page = first page containing the Chinese keyword label "关键词".
ch_abs = None
for i in range(doc.page_count):
    if "关键词" in doc[i].get_text():
        ch_abs = i; break
# English-abstract page = first page containing the uppercase keyword label "KEY WORDS".
en_abs = None
for i in range(doc.page_count):
    if "KEY WORDS" in doc[i].get_text():
        en_abs = i; break
# Body page = first page (after front matter) with >=6 CJK SimSun body lines (~12pt), excluding the
# abstract / TOC / back-matter / heading-only pages. Body text is Chinese (小四 SimSun 12pt).
_FRONT_BACK_MARKERS = ("关键词","KEY WORDS","目  录","目录","参考文献","致  谢","致谢",
                       "攻读学位","ABSTRACT","摘  要","摘要","独创性声明","使用授权")
def cjk_body_lines(idx, size_lo=11.2, size_hi=12.8):
    # CJK body lines on page idx whose max-span size is in [size_lo,size_hi] (小四 12pt body; excludes
    # titles >14pt, footnotes <10pt, L4 bold ~12pt non-CJK). Returns sorted list of (y0, size).
    if idx is None: return []
    pg = doc[idx]; out = []
    for b in pg.get_text("dict").get("blocks", []):
        if b.get("type", 0) != 0: continue
        for ln in b.get("lines", []):
            spans = ln.get("spans", [])
            if not spans: continue
            txt = "".join(s["text"] for s in spans)
            ms = max(s["size"] for s in spans)
            if size_lo <= ms <= size_hi and cjk_re.search(txt):
                y0 = min(s["bbox"][1] for s in spans)
                out.append((y0, ms))
    out.sort(); return out
def en_body_lines(idx):
    # ASCII-letter body lines, max-size in [9,13]pt (English-abstract 五号 10.5pt). Returns sorted (y0, size).
    if idx is None: return []
    pg = doc[idx]; out = []
    for b in pg.get_text("dict").get("blocks", []):
        if b.get("type", 0) != 0: continue
        for ln in b.get("lines", []):
            spans = ln.get("spans", [])
            if not spans: continue
            txt = "".join(s["text"] for s in spans)
            ms = max(s["size"] for s in spans)
            if 9 <= ms <= 13 and re.search(r"[A-Za-z]", txt):
                y0 = min(s["bbox"][1] for s in spans)
                out.append((y0, ms))
    out.sort(); return out
def line_gap(lines, lo=14.0, hi=40.0):
    # median consecutive-y0 delta (line-gap) in pt; filters gaps outside [lo,hi] (excludes intra-line
    # kerning noise <lo and paragraph-break/page-break gaps >hi). Returns None if <2 usable gaps.
    if len(lines) < 2: return None
    gaps = [lines[i+1][0]-lines[i][0] for i in range(len(lines)-1)]
    gaps = [g for g in gaps if lo <= g <= hi]
    if not gaps: return None
    return median(gaps)
def find_body_page():
    # first body-text page: >=6 CJK SimSun ~12pt lines, no front/back-matter marker.
    for i in range(doc.page_count):
        t = doc[i].get_text()
        if any(m in t for m in _FRONT_BACK_MARKERS): continue
        if len(cjk_body_lines(i)) >= 6:
            return i
    return None
'

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Compile + Self-Check + Body Line-Gap (AC-1 primary proof) ==="

# ATDD-3.11-I01: latexmk -xelatex -g main.tex exit code 0 (AC-7; R-12 full recompile MANDATORY)
# Baselineskip reflows EVERY page → -g (force) avoids stale .aux/page metrics.
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-3.11-I01" "latexmk -xelatex main.tex exit code 0 (AC-7, R-12 full recompile — baselineskip reflows every page)" test_full_compile

# ATDD-3.11-I02: zero compilation errors in main.log (AC-7)
test_no_errors() {
  if [[ -f "main.log" ]]; then
    local error_count
    error_count=$(grep -c '^!' main.log 2>/dev/null || true)
    error_count=$(echo "$error_count" | tr -d '[:space:]' | head -1)
    [[ "$error_count" -eq 0 ]]
  else
    return 1
  fi
}
run_test "P0" "ATDD-3.11-I02" "zero compilation errors in main.log (AC-7)" test_no_errors

# ATDD-3.11-I03: warning count <= 3 (AC-7; baseline = 1 benign xeCJK warning after Story 3.9/3.10)
test_warning_count() {
  if [[ -f "main.log" ]]; then
    local warning_count
    warning_count=$(grep -c 'Warning' main.log 2>/dev/null || true)
    warning_count=$(echo "$warning_count" | tr -d '[:space:]' | head -1)
    echo "  (Found $warning_count warnings, limit: 3)"
    [[ "$warning_count" -le 3 ]]
  else
    return 1
  fi
}
run_test "P0" "ATDD-3.11-I03" "warning count <= 3 (AC-7, NFR <=3 new vs baseline=1)" test_warning_count

# ATDD-3.11-I04: self-check baselineskip ≈ 23bp (AC-1/AC-2, TC-E3-47)
# The self-check \htucheck (cls:996) emits \the\baselineskip at \AtEndDocument in body \normalsize context.
# Band [22.5,24.0] = the Word "1.5倍" target (1.5×小四 SimSun natural ≈ 23.4pt).
# Pre-impl: 18.07bp → outside [22.5,24] → RED.
# Post-impl: ≈23bp → GREEN.
# The band EXCLUDES 21.6bp (the ctexbook 1.2× multiplier R-3 trap) AND 18bp (naive pre-impl) AND 25.2bp.
test_selfcheck_baselineskip_23() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local bs
  bs=$(grep 'baselineskip = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$bs" ]]; then echo "  (baselineskip not found in self-check)"; return 1; fi
  echo "  (baselineskip: ${bs}pt, target [22.5,24.0]; pre-impl=18.07 → RED; 21.6=R-3 trap; 25.2=over-spacing)"
  awk -v v="$bs" 'BEGIN{exit (v>=22.5 && v<=24.0)?0:1}'
}
run_test "P0" "ATDD-3.11-I04" "self-check baselineskip ≈23bp [22.5,24] (AC-1/AC-2, TC-E3-47; excludes 18 AND 21.6 R-3 trap; RED pre-impl)" test_selfcheck_baselineskip_23

# ATDD-3.11-I05: BEHAVIOR — fitz CJK BODY line-gap ≈ 23bp (AC-1 real proof, TC-E3-47)
# THE AC-1 RENDERED PROOF (Decision 1 — visual signature; the self-check value alone is a text proxy).
# Measures the median consecutive-line y0 delta on a body-text page (CJK SimSun 12pt body).
# Pre-impl: body baselineskip 18bp → body line-gap ≈18 → outside [22.5,24] → RED.
# Post-impl: ≈23bp → GREEN.
# Reference thesis body line-gap = 23.4pt (the Word "1.5倍" interpreter).
test_body_line_gap_23() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
bp = find_body_page()
if bp is None:
    print(\"  (no body-text page found: no page with >=6 CJK SimSun ~12pt body lines)\"); sys.exit(2)
lines = cjk_body_lines(bp)
g = line_gap(lines)
if g is None:
    print(\"  (body page p\" + str(bp+1) + \": <2 usable line-gaps)\"); sys.exit(2)
print(\"  body page p\" + str(bp+1) + \": \" + str(len(lines)) + \" CJK body lines, line-gap=\" + str(round(g,2)) + \"pt (target [22.5,24.0]; pre-impl≈18; ref 23.4)\")
sys.exit(0 if 22.5 <= g <= 24.0 else 1)
"
}
run_test "P0" "ATDD-3.11-I05" "BEHAVIOR: fitz CJK body line-gap ≈23bp (AC-1 real proof, TC-E3-47; RED pre-impl≈18)" test_body_line_gap_23

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Chinese-abstract inherits + English-abstract UNCHANGED + geometry UNCHANGED ==="

# ATDD-3.11-I06: BEHAVIOR — fitz CHINESE-ABSTRACT body line-gap ≈ 23bp (AC-3, TC-E3-50)
# The Chinese-abstract body (\htu@cabstract) inherits \normalsize (no local override). Pre-impl its
# baselineskip = 18bp (body) → line-gap ≈18 → RED. Post-impl (body recalibrated) → ≈23bp → GREEN.
# This proves the AC-3 inheritance: the Chinese-abstract recalibrated WITH the body (§2.7 == §2.9).
test_chinese_abstract_line_gap_23() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if ch_abs is None:
    print(\"  (Chinese-abstract page not found: no page with 关键词)\"); sys.exit(2)
lines = cjk_body_lines(ch_abs)
g = line_gap(lines)
if g is None:
    print(\"  (Chinese-abstract page p\" + str(ch_abs+1) + \": <2 usable line-gaps)\"); sys.exit(2)
print(\"  Ch-abstract page p\" + str(ch_abs+1) + \": \" + str(len(lines)) + \" CJK body lines, line-gap=\" + str(round(g,2)) + \"pt (target [22.5,24.0]; inherits body; pre-impl≈18)\")
sys.exit(0 if 22.5 <= g <= 24.0 else 1)
"
}
run_test "P1" "ATDD-3.11-I06" "BEHAVIOR: fitz Chinese-abstract body line-gap ≈23bp (AC-3, TC-E3-50; inherits body; RED pre-impl≈18)" test_chinese_abstract_line_gap_23

# ATDD-3.11-I07: BEHAVIOR — fitz ENGLISH-ABSTRACT body line-gap = 23.4bp ±0.5 (AC-4 regression; GREEN guard)
# Story 3.4 R-14 locked the English-abstract baselineskip at 23.4bp (cls:891). Story 3.11 MUST NOT drag it
# to the body value — the English-abstract \begingroup block is independent. Band [22.9,23.9] = 23.4 ±0.5.
# Pre-impl: 23.4bp (Story 3.4 already done) → GREEN guard. Post-impl: must stay ≈23.4bp.
# THIS IS THE CRITICAL AC-4 REGRESSION GUARD — if it fails post-impl, the recalibration leaked into the
# English-abstract scope (a real regression, NOT a Decision-2 override).
test_english_abstract_line_gap_234() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if en_abs is None:
    print(\"  (English-abstract page not found: no page with KEY WORDS)\"); sys.exit(2)
lines = en_body_lines(en_abs)
g = line_gap(lines)
if g is None:
    print(\"  (English-abstract page p\" + str(en_abs+1) + \": <2 usable line-gaps)\"); sys.exit(2)
print(\"  En-abstract page p\" + str(en_abs+1) + \": \" + str(len(lines)) + \" ASCII body lines, line-gap=\" + str(round(g,2)) + \"pt (target [22.9,23.9] = 23.4±0.5; UNCHANGED from Story 3.4)\")
sys.exit(0 if 22.9 <= g <= 23.9 else 1)
"
}
run_test "P1" "ATDD-3.11-I07" "BEHAVIOR: fitz English-abstract body line-gap = 23.4bp ±0.5 (AC-4 regression, R-14; UNCHANGED — GREEN guard)" test_english_abstract_line_gap_234

# ATDD-3.11-I08: self-check textheight ≈ 688.56pt UNCHANGED (AC-5, R-1; GREEN guard)
# Baselineskip change must NOT alter geometry — textheight is a page-dimension, independent of line-spacing.
test_textheight_unchanged() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local th
  th=$(grep 'textheight = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$th" ]]; then echo "  (textheight not found in self-check)"; return 1; fi
  echo "  (textheight: ${th}pt [expect ~688.56, UNCHANGED — baselineskip does not affect geometry])"
  echo "$th" | awk '{if ($1 >= 686 && $1 <= 690) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.11-I08" "self-check textheight ≈688.56pt UNCHANGED (AC-5, R-1; baselineskip ≠ geometry)" test_textheight_unchanged

# ATDD-3.11-I09: page-count rebaseline (AC-6 informational; record new count, wide band)
# Body baselineskip 18→≈23 LOOSENS spacing → body reflows → page count INCREASES. Pre-impl: 51 pages.
# Band [44,62] is intentionally wide (absorbs the reflow delta; the EXACT new count is recorded in the
# Completion Notes + used to re-anchor ATDD-2.5-26 / 3.5-I14 per Decision 2). This is a regression guard
# (catch a runaway page explosion), NOT a precise count assertion.
test_page_count_rebaseline() {
  if [[ ! -f "main.pdf" ]] || [[ ! -f "main.log" ]]; then return 1; fi
  local total_pages
  total_pages=$(grep 'total pages = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | tr -d '[:space:]')
  if [[ -z "$total_pages" ]]; then echo "  (page count not found in self-check)"; return 1; fi
  echo "  (pages: $total_pages; band [40,62] [re-anchored by Story 3.14: → 44 pp; was [44,62]])"
  echo "$total_pages" | awk '{if ($1 >= 40 && $1 <= 62) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.11-I09" "page-count rebaseline in [44,62] (AC-6 informational; body reflow → more pages; re-anchor 2.5-26/3.5-I14)" test_page_count_rebaseline

echo ""

# ==========================================
# Summary
# ==========================================
echo "=============================================="
printf "Total: \033[32m%d PASS\033[0m  \033[31m%d FAIL\033[0m  \033[33m%d SKIP\033[0m\n" "$PASS" "$FAIL" "$SKIP_COUNT"
echo "=============================================="

if [[ "$SKIP" == "1" ]]; then
  echo ""
  echo "RED TDD RED PHASE: All tests are SKIPPED"
  echo "   Run with --run flag or ATDD_SKIP=0 to activate"
  echo "   RED (fail pre-impl): I04 (self-check baselineskip 18bp outside [22.5,24]),"
  echo "      I05 (fitz body line-gap ≈18 outside [22.5,24]), I06 (Chinese-abstract line-gap ≈18)."
  echo "   GREEN guards: I01/I02/I03 (compile), I07 (English-abstract 23.4bp UNCHANGED — AC-4),"
  echo "      I08 (textheight ≈688.56 UNCHANGED — AC-5), I09 (page-count rebaseline band)."
  echo ""
  echo "   NOTE: the fitz CJK body line-gap behavior test (I05) is the AC-1 REAL proof — a self-check"
  echo "         read alone is a text proxy (Decision 1); the rendered line-gap is the visual signature."
  echo "         AC-6 (Decision-2 repoints of ATDD-2.5-20/2.1-29/2.2-20/2.3-14/2.4-10/2.5-01/2.6-28/"
  echo "         2.3-28/3.5-I12·I13·I14 + page-count 2.5-26) is the DEV's Task 2 — verified by running the"
  echo "         FULL Epic 1–3 suite post-repoint, NOT by this story's own scaffolds."
  echo "         R-12: latexmk -xelatex -g MANDATORY (baselineskip reflows every page)."
  echo "         Tests are read-only — they do not modify the SUT."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
