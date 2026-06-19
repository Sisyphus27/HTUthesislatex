#!/usr/bin/env bash
# test-story-3.9-integration.sh — ATDD Red-Phase Integration Tests for Story 3.9
# TDD Phase: RED (Latin-font-name behavior tests FAIL on pre-impl; compile-regression guards pass)
#
# Usage: bash tests/test-story-3.9-integration.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 tests are blocking
# Linked Risk: R-13 (score 4, global TNR ripple → page-count may shift), R-1 (geometry regression),
#              R-3 (baselineskip regression), NFR-2 (font compat)
# TC-E3-02 (Latin renders TNR via fitz), compile + self-check regression guards
#
# NOTE: source-greps (unit) prove \setmainfont EXISTS; these tests prove Latin text RENDERS TNR:
#   - ATDD-3.9-15: English cover ASCII spans = TNR (NOT Latin Modern) — the AC-2 primary proof
#   - ATDD-3.9-16: English abstract ASCII spans = TNR
#   - ATDD-3.9-17: L4 heading Latin numeral = TNR (deferred-work §2.5 "LMRoman12-Bold" gap)
#   - ATDD-3.9-18: records \sffamily CJK rendered font (AC-4 empirical input)
#   A source-grep that \setmainfont exists does NOT prove Latin text renders TNR (a later override
#   could shadow it). These fitz behavior tests are the real proof (Story 2.5/2.6 centering lesson).
#
# fitz calibration notes (verified pre-impl on main.pdf at baseline 3ac6949):
#   - Latin Modern rmfamily embeds as "LMRoman*" (e.g. LMRoman10-Regular, LMRoman12-Bold).
#   - Times New Roman via \setmainfont embeds with "Times" in the font name (TimesNewRomanPSMT /
#     "Times New Roman" / *-Bold variants). The dual-count (TNR>0 AND LMRoman==0) is the RED→GREEN signal.
#   - Math fonts (Latin Modern Math, unicode-math) are a SEPARATE axis — \setmainfont does NOT touch
#     them. So this test targets TEXT regions (English cover, English abstract, L4 numerals), NOT
#     equation pages, to avoid false-FAILs on legitimately-math Latin Modern.
#   - English cover (htu@engcover) = page with "dissertation submitted" / "Henan Normal University".
#   - English abstract = front-matter page with "KEY WORDS" (cls:174 label, post-2.6 uppercase).
#   - L4 heading = body block matching ^N.N.N.N (excl N.N.N.N.N); its ASCII numeral span is the probe.

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
echo "ATDD Integration Tests: Story 3.9 — Latin font calibration (Times New Roman)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# Shared Python header: opens main.pdf, defines footer_num/body_start (for L4 test) + font analyzer.
PY_HEAD='
import fitz, sys, re
doc = fitz.open("main.pdf")
W = doc[0].rect.width; mid = W / 2.0
roman_re = re.compile(r"^[IVXLC]+$"); arabic_re = re.compile(r"^\d+$")
ascii_re = re.compile(r"[a-zA-Z0-9]")
def footer_num(i):
    page = doc[i]; H = page.rect.height
    for b in page.get_text("blocks"):
        x0,y0,x1,y1,txt = b[0],b[1],b[2],b[3],b[4]; t = txt.strip()
        if t and y0 > H - 70 and 1 <= len(t) <= 5 and (roman_re.match(t) or arabic_re.match(t)):
            return t
    return None
body_start = next((i for i in range(doc.page_count) if footer_num(i) and arabic_re.match(footer_num(i))), None)
if body_start is None: print("  no body start found"); sys.exit(1)
def block_ts(blk):
    spans = [sp for ln in blk.get("lines", []) for sp in ln.get("spans", [])]
    if not spans: return "", 0.0, []
    txt = "".join(sp["text"] for sp in spans).strip()
    ms = max(sp["size"] for sp in spans)
    return txt, ms, spans
def classify_font(fn):
    # "lm" = Latin Modern ROMAN — the \rmfamily defect Story 3.9 eliminates via \setmainfont (LMRoman*).
    # LMSans (\sffamily Latin, e.g. the English-abstract title "Abstract" via \htu@chapter* \sffamily
    # chapter format) is OUT of 3.9 scope: Story 3.4 AC-4 fixes the abstract title to TNR bold.
    # 3.9 owns \rmfamily Latin only; \sffamily Latin (LMSans) and math fonts classify as "other".
    # RED-phase preserved: pre-impl the abstract BODY is LMRoman (rmfamily) → still "lm" → still RED.
    if "LMRoman" in fn: return "lm"
    if "Times" in fn: return "tnr"
    return "other"
'

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Compile & Latin-Font Behavior ==="

# ATDD-3.9-08: latexmk -xelatex main.tex exit code 0 (AC-6, R-13 full recompile)
# \setmainfont changes text metrics → -g (force) full recompile is mandatory (R-12/R-13 pattern).
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-3.9-08" "latexmk -xelatex main.tex exit code 0 (AC-6, R-13 full recompile)" test_full_compile

# ATDD-3.9-09: zero compilation errors in main.log (AC-6)
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
run_test "P0" "ATDD-3.9-09" "zero compilation errors in main.log (AC-6)" test_no_errors

# ATDD-3.9-10: warning count <= 3 (AC-6, baseline = 0 warnings after Epic 2)
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
run_test "P0" "ATDD-3.9-10" "warning count <= 3 (AC-6, NFR <=3 new vs Epic 2 baseline=0)" test_warning_count

# ATDD-3.9-15: BEHAVIOR — English cover ASCII spans render TNR (NOT Latin Modern) (AC-2, TC-E3-02)
# Find English cover page by "dissertation submitted" / "Henan Normal University" signature.
# Pre-impl: all ASCII spans = LMRoman (Latin Modern throughout) → lm>0, tnr==0 → RED.
# Post-impl: ASCII spans = Times New Roman → lm==0, tnr>0 → GREEN.
test_english_cover_tnr_behavior() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
eng = None
for i in range(min(doc.page_count, 8)):
    t = doc[i].get_text()
    if 'dissertation submitted' in t or 'Henan Normal University' in t:
        eng = i; break
if eng is None:
    print('  (English cover page not found)'); sys.exit(1)
lm = tnr = other = 0
for blk in doc[eng].get_text('dict').get('blocks', []):
    for ln in blk.get('lines', []):
        for sp in ln.get('spans', []):
            if ascii_re.search(sp['text']):
                c = classify_font(sp['font'])
                if c == 'lm': lm += 1
                elif c == 'tnr': tnr += 1
                else: other += 1
print(f'  eng-cover=p{eng+1}, LatinModern spans={lm}, TNR spans={tnr}, other={other}')
sys.exit(0 if (lm == 0 and tnr >= 1) else 1)
"
}
run_test "P0" "ATDD-3.9-15" "BEHAVIOR: English cover ASCII spans render TNR (not Latin Modern) (AC-2, TC-E3-02)" test_english_cover_tnr_behavior

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Regression Guards + English-Abstract Behavior ==="

# ATDD-3.9-11: self-check textheight unchanged (~688pt) — font change must NOT alter geometry (AC-6, R-1)
test_textheight_unchanged() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local th
  th=$(grep 'textheight = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$th" ]]; then echo "  (textheight not found)"; return 1; fi
  echo "  (textheight: ${th}pt [expect ~688.56])"
  echo "$th" | awk '{if ($1 >= 686 && $1 <= 690) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.9-11" "self-check textheight unchanged ~688pt (AC-6, R-1)" test_textheight_unchanged

# ATDD-3.9-12: self-check baselineskip ≈ 23.4bp (REPOINTED by Story 3.11: was 18bp, now 23.4bp Word「1.5倍」×natural;
#   R-3 — \setmainfont still did not touch it; §2.7/2.9, gap G4)
test_baselineskip_18bp() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local bs
  bs=$(grep 'baselineskip = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$bs" ]]; then echo "  (baselineskip not found in self-check)"; return 1; fi
  echo "  (baselineskip: ${bs}pt, expect ~23.49 [23.4bp]; 18.0=old naive, 21.6=R-3 trap regression)"
  echo "$bs" | awk '{if ($1 >= 22.5 && $1 <= 24.5) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.9-12" "self-check baselineskip ≈ 23.4bp (REPOINTED by Story 3.11; R-3)" test_baselineskip_18bp

# ATDD-3.9-16: BEHAVIOR — English abstract ASCII spans render TNR (AC-2, TC-E3-02)
# Find English abstract page by "KEY WORDS" label (cls:174, post-2.6 uppercase). Pre-impl: Latin Modern → RED.
test_english_abstract_tnr_behavior() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
eabs = None
for i in range(doc.page_count):
    t = doc[i].get_text()
    if 'KEY WORDS' in t or 'Key Words' in t:
        eabs = i; break
if eabs is None:
    print('  (English abstract page not found)'); sys.exit(1)
lm = tnr = other = 0
for blk in doc[eabs].get_text('dict').get('blocks', []):
    for ln in blk.get('lines', []):
        for sp in ln.get('spans', []):
            if ascii_re.search(sp['text']):
                c = classify_font(sp['font'])
                if c == 'lm': lm += 1
                elif c == 'tnr': tnr += 1
                else: other += 1
print(f'  eng-abstract=p{eabs+1}, LatinModern spans={lm}, TNR spans={tnr}, other={other}')
sys.exit(0 if (lm == 0 and tnr >= 1) else 1)
"
}
run_test "P1" "ATDD-3.9-16" "BEHAVIOR: English abstract ASCII spans render TNR (AC-2, TC-E3-02)" test_english_abstract_tnr_behavior

# ATDD-3.9-13: main.pdf exists and is non-empty (AC-6)
test_pdf_output() {
  [[ -f "main.pdf" ]] && [[ -s "main.pdf" ]]
}
run_test "P1" "ATDD-3.9-13" "main.pdf exists and is non-empty (AC-6)" test_pdf_output

# ATDD-3.9-14: no fancyhdr headheight warning (R-2 regression)
test_no_headheight_warning() {
  if [[ -f "main.log" ]]; then
    ! grep -qi 'headheight.*too low\|fancyhdr.*headheight' main.log 2>/dev/null
  else
    return 1
  fi
}
run_test "P1" "ATDD-3.9-14" "no fancyhdr headheight warning (R-2 regression)" test_no_headheight_warning

# ATDD-3.9-19: total pages ~50 (+/- 5) — font metrics change MAY shift pagination (AC-6, R-13 watch)
# R-13: TNR glyph metrics != Latin Modern → page count may drift. If it shifts outside +/-5 post-impl,
# re-calibrate transparently (Decision 2 cross-story override) and document the new baseline.
test_page_count() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local total_pages
  total_pages=$(grep 'total pages = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | tr -d '[:space:]')
  if [[ -z "$total_pages" ]]; then echo "  (page count not found)"; return 1; fi
  echo "  (pages: $total_pages, expected 40-55 [re-anchored by Story 3.14: → 44 pp; was 45-55])"
  echo "$total_pages" | awk '{if ($1 >= 40 && $1 <= 55) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.9-19" "total pages ~50 (+/- 5; R-13 watch — TNR may shift pagination)" test_page_count

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: L4 Latin Numeral + \sffamily Diagnostic ==="

# ATDD-3.9-17: BEHAVIOR — L4 heading Latin numeral renders TNR (AC-2, TC-E3-02; deferred-work §2.5 gap)
# The L4 heading CJK span is bold-SimSun (Story 2.5 \htu@songtibold); its Latin NUMERAL span is \bfseries
# rmfamily → Latin Modern Bold (LMRoman12-Bold) pre-impl, TNR Bold post-impl.
# REPOINTED by Story 3.13 (spec §2.10, gap M4): heading numbering Arabic→humanities. L4 was ^N.N.N.N
#   (subsubsection); now L4 = （N） (the 4th humanities level). The numeral "N" inside （N） is still Latin/
#   \bfseries rmfamily → the TNR-vs-LatinModern assertion is UNCHANGED (only the heading-block detection
#   regex changed: ^\d+\.\d+\.\d+\.\d+ → ^（\d+）). The probe target = the ASCII digit span in the block.
test_l4_numeral_tnr_behavior() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
bs = body_start
l4_re = re.compile(r'^（\d+）')        # REPOINTED by Story 3.13: humanities L4 label （N） (was ^N.N.N.N)
lm = tnr = other = found = 0
for i in range(bs, doc.page_count):
    for blk in doc[i].get_text('dict').get('blocks', []):
        txt, ms, spans = block_ts(blk)
        if txt and l4_re.match(txt):                                # L4 heading block （N）title
            # probe the ASCII digit span (the （N） numeral), separate from the CJK title span
            for sp in spans:
                if re.match(r'^\d+\$', sp['text'].strip()):
                    found += 1
                    c = classify_font(sp['font'])
                    if c == 'lm': lm += 1
                    elif c == 'tnr': tnr += 1
                    else: other += 1
                    break
print(f'  L4 （N） numeral spans={found}, LatinModern={lm}, TNR={tnr}, other={other}')
sys.exit(0 if (found >= 1 and lm == 0 and tnr >= 1) else 1)
"
}
run_test "P2" "ATDD-3.9-17" "BEHAVIOR: L4 heading Latin numeral renders TNR (AC-2, deferred-work §2.5 gap; REPOINTED to （N） humanities label by Story 3.13)" test_l4_numeral_tnr_behavior

# ATDD-3.9-18: DIAGNOSTIC — record \sffamily CJK rendered font name on a heading (AC-4 empirical input)
# This RECORDS the current heading CJK font (SimHei / YaHei / other) as input to the AC-4 decision.
# It does not hard-pass/fail — it prints the value for the dev/reference-PDF comparison (Story Task 2.2).
# Info-only: exits 0 if a heading CJK span was found (regardless of which font), 1 if none found.
# REPOINTED by Story 3.13 (spec §2.10, gap M4): heading numbering Arabic→humanities. Headings no longer
#   start with ^\d (was N.N.N etc.); now they start with 第N章 (chapter, size≈16) / 第N节 (section, size≈15).
#   The size band 14.5-16.6 still captures both; only the block-prefix predicate changed (^\d → ^第).
test_sffamily_cjk_diagnostic() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
cjk_re = re.compile(r'[一-鿿]')
bs = body_start
seen = {}
for i in range(bs, min(bs + 10, doc.page_count)):
    for blk in doc[i].get_text('dict').get('blocks', []):
        txt, ms, spans = block_ts(blk)
        if not txt: continue
        # heading CJK spans: chapter (~16bp sffamily) or section (~15bp) — the \sffamily headings
        # REPOINTED by Story 3.13: prefix ^第 (was ^\d) — humanities 第N章/第N节
        if 14.5 <= ms <= 16.6 and re.match(r'^第', txt):
            for sp in spans:
                if cjk_re.search(sp['text']):
                    seen[sp['font']] = seen.get(sp['font'], 0) + 1
if not seen:
    print('  (no heading CJK span found in first 10 body pages)'); sys.exit(1)
print('  heading \\\\sffamily CJK font-name distribution: ' + str(seen))
print('  (AC-4 input: compare to reference PDF heading 黑体 face; decide SimHei-vs-YaHei per Story Task 2.2)')
sys.exit(0)
"
}
run_test "P2" "ATDD-3.9-18" "DIAGNOSTIC: record \sffamily CJK font on headings (AC-4 empirical input; REPOINTED to ^第 humanities headings by Story 3.13)" test_sffamily_cjk_diagnostic

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
  echo "   ATDD-3.9-15 (English cover TNR), 3.9-16 (English abstract TNR), 3.9-17 (L4 numeral TNR)"
  echo "   FAIL until impl (Latin Modern pre-impl); compile-regression + self-check guards stay green"
  echo ""
  echo "   NOTE: the fitz Latin-font-name behavior test is the AC-2 real proof — source-greps cannot"
  echo "         prove rendered TNR (a later \\setmainfont override could shadow it)."
  echo "         R-13: page-count (3.9-19) may shift post-impl; repoint transparently if so (Decision 2)."
  echo "         Tests are read-only — they do not modify the SUT."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
