#!/usr/bin/env bash
# test-story-3.2-integration.sh — ATDD Red-Phase Integration Tests for Story 3.2 (abstract cover + English title page)
# TDD Phase: RED (page-ordering / no-page-number-VISUAL-SIGNATURE / degree-statement / element-presence
#             behavior tests FAIL on pre-impl; compile + all-TNR + self-check regression guards pass)
#
# Usage: bash tests/test-story-3.2-integration.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 tests are blocking
# Linked ACs: AC-1 (page ordering), AC-2 (English title TNR + degree statement), AC-4 (no emajor/edepartment),
#             AC-5 (abstract cover presence), AC-6 (no page number — VISUAL SIGNATURE, Decision 1), AC-9 (compile+regression)
# Linked Risk: R-6 (score 6, English-cover parbox — verified via no-paperwidth in unit), R-1/R-3 (regression)
# TC-E3-10 (page ordering, P0), TC-E3-11 (English title all TNR, P0), TC-E3-13 (no page number, P0),
# TC-E3-12 (English title elements, P1)
#
# NOTE: source-greps (unit) prove macros are DEFINED; these tests prove the pages RENDER correctly:
#   - ATDD-3.2-I04: page ORDER doctoral→english→abstractcover→chinese (AC-1, TC-E3-10) — the ordering proof
#   - ATDD-3.2-I05: English title ALL Latin spans = TNR (AC-2, TC-E3-11) — Story 3.9 must not regress
#   - ATDD-3.2-I06: abstract cover + English title NO page number via VISUAL SIGNATURE (AC-6, TC-E3-13, Decision 1)
#   - ATDD-3.2-I07: English title degree-statement phrases present + centered (AC-2/AC-3, TC-E3-12)
#   - ATDD-3.2-I08: English title does NOT render emajor/edepartment (AC-4)
#   - ATDD-3.2-I09: abstract cover element presence (AC-5)
#   A source-grep that \makecover calls the covers in order does NOT prove rendered page order. These fitz
#   behavior tests are the real AC proof (Story 2.5/2.6/3.1/3.9 behavior-test lesson).
#
# fitz calibration notes (verified pre-impl on main.pdf at baseline 7e4e339):
#   - Front matter (pre-impl): p1 doctoral cover (3.1) → p2 English title (htu@engcover, "dissertation submitted")
#     → p3 declaration (htu@authorization@mk, "学位论文原创性声明") → p4+ Chinese abstract ("关键词").
#     NO abstract cover exists pre-impl → I04/I06/I09 RED on "abstract cover not found".
#   - Post-impl: p1 doctoral → p2 English title → p3 abstract cover (博士学位论文摘要) → p4 Chinese abstract.
#   - Page signatures: doctoral = "博士学位论文"+"10476" NOT "摘要"; english = "dissertation submitted" or
#     "graduate school of henan normal university" (case-insensitive; covers pre-impl lowercase + post-impl
#     capital forms); abstract cover = "博士学位论文摘要" (Task-0.2 default structure); chinese = "关键词".
#   - Cross-story note: Story 3.9 ATDD-3.9-15 detects the English cover via 'dissertation submitted' OR
#     'Henan Normal University'. After 3.2 the lowercase 'dissertation submitted' becomes 'Dissertation Submitted'
#     (capital D) but 'Henan Normal University' still matches → 3.9-15 still finds the page (no break).
#   - No-page-number = footer-band (bottom 25mm) 0 drawings AND 0 spans (Decision 1 VISUAL SIGNATURE).

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

echo "=============================================="
echo "ATDD Integration Tests: Story 3.2 — Abstract cover page and English title page"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# Shared Python header: opens main.pdf, finds the 4 front-matter pages by signature, defines helpers.
PY_HEAD='
import fitz, sys, re
doc = fitz.open("main.pdf")
def mm(v): return v / 72.0 * 25.4
ascii_re = re.compile(r"[a-zA-Z0-9]")
def classify_font(fn):
    # "lm" = Latin Modern ROMAN (\rmfamily defect Story 3.9 eliminated via \setmainfont).
    # LMSans (\sffamily Latin) and math fonts classify as "other" — out of 3.2/3.9 scope.
    if "LMRoman" in fn: return "lm"
    if "Times" in fn: return "tnr"
    return "other"
def page_blocks(i):
    pg = doc[i]; out = []
    for b in pg.get_text("dict").get("blocks", []):
        if b.get("type", 0) != 0: continue
        spans = [sp for ln in b.get("lines", []) for sp in ln.get("spans", [])]
        txt = "".join(sp["text"] for sp in spans).strip()
        if not txt: continue
        x0, y0, x1, y1 = b["bbox"]
        ms = max((sp["size"] for sp in spans), default=0.0)
        out.append({"txt": txt, "x0": x0, "y0": y0, "x1": x1, "y1": y1, "size": ms,
                    "fonts": set(sp["font"] for sp in spans)})
    return out
def footer_band_visual(i):
    # Decision 1 VISUAL SIGNATURE: footer band = bottom 25mm. Returns (drawings, spans) counts.
    pg = doc[i]; H = pg.rect.height
    band_top = H - 25.0 / 25.4 * 72.0
    dc = sum(1 for d in pg.get_drawings() if d["rect"].y1 > band_top)
    sc = 0
    for b in pg.get_text("dict").get("blocks", []):
        if b.get("type", 0) != 0: continue
        for ln in b.get("lines", []):
            for sp in ln.get("spans", []):
                if sp["bbox"][1] > band_top: sc += 1
    return dc, sc
# --- Page finders (signatures stable pre- AND post-impl, except abstract cover which is the RED signal) ---
doctoral = None
for i in range(min(6, doc.page_count)):
    t = doc[i].get_text()
    if "博士学位论文" in t and "10476" in t and "摘要" not in t:
        doctoral = i; break
english = None
for i in range(min(6, doc.page_count)):
    tl = doc[i].get_text().lower()
    if "dissertation submitted" in tl or "graduate school of henan normal university" in tl:
        english = i; break
abstract_cover = None
for i in range(min(6, doc.page_count)):
    t = doc[i].get_text()
    if "博士学位论文摘要" in t and i != doctoral:
        abstract_cover = i; break
chinese = None
for i in range(min(10, doc.page_count)):
    t = doc[i].get_text()
    if "关键词" in t:
        chinese = i; break
'

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Compile + Page Ordering + All-TNR + No-Page-Number VISUAL SIGNATURE ==="

# ATDD-3.2-I01: latexmk -xelatex -g main.tex exit code 0 (AC-9, compile gate)
# Front-matter reorder + new abstract-cover page shifts pagination → -g (force) full recompile (R-12).
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-3.2-I01" "latexmk -xelatex main.tex exit code 0 (AC-9, R-12 full recompile)" test_full_compile

# ATDD-3.2-I02: zero compilation errors in main.log (AC-9)
test_no_errors() {
  if [[ -f "main.log" ]]; then
    local error_count
    error_count=$(grep -cE '^!|LaTeX Error:|Fatal error' main.log 2>/dev/null || true)
    error_count=$(echo "$error_count" | tr -d '[:space:]' | head -1)
    [[ "$error_count" -eq 0 ]]
  else
    return 1
  fi
}
run_test "P0" "ATDD-3.2-I02" "zero compilation errors in main.log (AC-9)" test_no_errors

# ATDD-3.2-I03: warning count <= 3 (AC-9, NFR <=3 new vs Story 3.1 baseline = 1 standing xeCJK)
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
run_test "P0" "ATDD-3.2-I03" "warning count <= 3 (AC-9, NFR <=3 new)" test_warning_count

# ATDD-3.2-I04: BEHAVIOR — page ORDER doctoral→english→chinese, abstract-cover ABSENT (REPPOINTED by Story 3.14)
# REPPOINTED 2026-06-19 (Story 3.14, Decision 2): was 4-page order doctoral<english<abstract_cover<chinese (3.2 added
#   the abstract cover under FR-12). Story 3.14 DELETED it (spec §1.1 line 5; FR-12 retired). New: 3-page order
#   doctoral<english<chinese (contiguous, matches reference PDF pp.1-12). Assert abstract_cover None + 3-page order.
test_page_ordering() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if abstract_cover is not None:
    print('  abstract-cover page FOUND at p%d — should be DELETED; RED (Story 3.14 §1.1 line 5)' % (abstract_cover+1))
    sys.exit(1)
if None in (doctoral, english, chinese):
    print('  MISSING cover/abstract page (doctoral/english/chinese); front-matter signature changed'); sys.exit(1)
print('  doctoral=p%d, english=p%d, chinese=p%d (abstract-cover absent — contiguous per §1.1 line 5)' %
      (doctoral+1, english+1, chinese+1))
ok = doctoral < english < chinese
print('  order doctoral<english<chinese (no abstract cover): ' + ('OK' if ok else 'WRONG'))
sys.exit(0 if ok else 1)
"
}
run_test "P0" "ATDD-3.2-I04" "BEHAVIOR: page order doctoral→english→chinese, abstract-cover ABSENT (REPPOINTED by Story 3.14: §1.1 line 5; was 4-page)" test_page_ordering

# ATDD-3.2-I05: BEHAVIOR — English title ALL Latin spans = TNR (AC-2, TC-E3-11)
# Story 3.9 made the English cover Latin = TNR; Story 3.2's rewrite (adding the 5-line degree statement)
# must NOT regress it (no \sffamily Latin → LMSans). GREEN guard pre-impl; must stay GREEN post-impl.
# Asserts lm==0 (no Latin Modern defect) AND tnr>=1. Prints other count for visibility (LMSans watch).
test_english_title_all_tnr() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if english is None:
    print('  (English title page not found)'); sys.exit(1)
lm = tnr = other = 0
for blk in doc[english].get_text('dict').get('blocks', []):
    for ln in blk.get('lines', []):
        for sp in ln.get('spans', []):
            if ascii_re.search(sp['text']):
                c = classify_font(sp['font'])
                if c == 'lm': lm += 1
                elif c == 'tnr': tnr += 1
                else: other += 1
print('  english-title=p%d, LatinModern=%d, TNR=%d, other=%d (AC-2 all-TNR; other>0 = sffamily-Latin watch)' %
      (english+1, lm, tnr, other))
sys.exit(0 if (lm == 0 and tnr >= 1) else 1)
"
}
run_test "P0" "ATDD-3.2-I05" "BEHAVIOR: English title page all Latin spans = TNR (AC-2, TC-E3-11; GREEN guard — 3.9 must not regress)" test_english_title_all_tnr

# ATDD-3.2-I06: BEHAVIOR — doctoral + English title NO page number — VISUAL SIGNATURE (REPPOINTED by Story 3.14)
# REPPOINTED 2026-06-19 (Story 3.14, Decision 1): was "abstract cover + English title no-page-number". Story 3.14
#   DELETED the abstract cover (§1.1 line 5) → only doctoral + English title remain with \thispagestyle{htu@empty}.
#   Decision 1 VISUAL SIGNATURE (footer-band get_drawings + spans) — NOT a text proxy.
test_no_page_number_visual() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if english is None:
    print('  (English title page not found)'); sys.exit(1)
edc, esc = footer_band_visual(english)
ddc, dsc = footer_band_visual(doctoral) if doctoral is not None else (None, None)
print('  doctoral=p%d footer-band drawings=%s spans=%s' % (doctoral+1 if doctoral is not None else -1, ddc, dsc))
print('  english-title=p%d footer-band drawings=%d spans=%d' % (english+1, edc, esc))
ok = (edc == 0 and esc == 0) and (ddc == 0 and dsc == 0)
sys.exit(0 if ok else 1)
"
}
run_test "P0" "ATDD-3.2-I06" "BEHAVIOR: doctoral + English title NO page number — VISUAL SIGNATURE (REPPOINTED by Story 3.14: abstract cover deleted; §1.1 line 5)" test_no_page_number_visual

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: English title elements + abstract cover presence + regression guards ==="

# ATDD-3.2-I07: BEHAVIOR — English title degree-statement phrases present + centered (AC-2/AC-3, TC-E3-12)
# The 3 unambiguous phrases absent pre-impl: "Graduate School of Henan Normal University",
#   "Partial Fulfillment", "Requirements". Pre-impl engcover = "dissertation submitted to HNU for degree of Doctor" → RED.
# Post-impl: all 3 present + "By" + "Supervisor" + centered (block cx ≈ page mid within 12mm) → GREEN.
test_english_title_elements() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if english is None:
    print('  (English title page not found)'); sys.exit(1)
pg = doc[english]; W = pg.rect.width; mid = W / 2.0
t = pg.get_text()
required = ['Graduate School of Henan Normal University', 'Partial Fulfillment',
            'Requirements', 'By', 'Supervisor']
missing = [k for k in required if k not in t]
# Centered check: every text block's cx within 12mm of page mid (HTU 扉页 is fully centered).
bs = page_blocks(english)
offcenter = []
for b in bs:
    cx = (b['x0'] + b['x1']) / 2.0
    if abs(mm(cx) - mm(mid)) > 12.0:
        offcenter.append(b['txt'][:30])
if missing:
    print('  english-title=p%d MISSING phrases: %s' % (english+1, ', '.join(missing)))
if offcenter:
    print('  english-title=p%d OFF-CENTER blocks (>12mm from mid): %s' % (english+1, '; '.join(offcenter[:5])))
print('  english-title=p%d phrases-present=%d/%d, blocks=%d, off-center=%d' %
      (english+1, len(required)-len(missing), len(required), len(bs), len(offcenter)))
sys.exit(0 if (not missing and not offcenter) else 1)
"
}
run_test "P1" "ATDD-3.2-I07" "BEHAVIOR: English title degree-statement phrases + By/Supervisor present + centered (AC-2/AC-3, TC-E3-12; RED pre-impl)" test_english_title_elements

# ATDD-3.2-I08: BEHAVIOR — English title does NOT render emajor/edepartment (AC-4)
# Truth source: reference PDF page 3 + .doc 扉页 have NO major/department lines; the current engcover
#   (cls:652-653) renders \htu@emajor ("Materials Science and Engineering") + \htu@edepartment — NOT in spec.
# Pre-impl: "Materials Science" present on the english page → RED. Post-impl (Task 1.4): removed → GREEN.
test_no_emajor_edepartment() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if english is None:
    print('  (English title page not found)'); sys.exit(1)
t = doc[english].get_text()
leaks = [k for k in ['Materials Science', 'School of Materials'] if k in t]
print('  english-title=p%d, emajor/edepartment leaks: %s (expect empty post-impl)' %
      (english+1, leaks if leaks else 'NONE'))
sys.exit(0 if not leaks else 1)
"
}
run_test "P1" "ATDD-3.2-I08" "BEHAVIOR: English title does NOT render emajor/edepartment (AC-4; RED — present pre-impl cls:652-653)" test_no_emajor_edepartment

# ATDD-3.2-I09: BEHAVIOR — abstract cover page ABSENT (REPPOINTED by Story 3.14; was element-presence)
# REPPOINTED 2026-06-19 (Story 3.14): was "abstract cover elements present" (博士学位论文摘要/论文题目/单位代码/学科、专业).
#   Story 3.14 DELETED the abstract cover (spec §1.1 line 5; FR-12 retired). This guard now asserts the page is
#   ABSENT — reversed to the new spec-correct reality, NOT weakened. Mirrors 3.14-I04 / 3.2-01.
test_abstract_cover_elements() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if abstract_cover is not None:
    print('  abstract-cover page FOUND at p%d (博士学位论文摘要) — should be DELETED; RED (Story 3.14 §1.1 line 5)' % (abstract_cover+1))
    sys.exit(1)
print('  abstract-cover page ABSENT (FR-12 retired, §1.1 line 5) — GREEN')
sys.exit(0)
"
}
run_test "P1" "ATDD-3.2-I09" "BEHAVIOR: abstract cover page ABSENT (REPPOINTED by Story 3.14: was element-presence; now deleted §1.1 line 5, FR-12 retired)" test_abstract_cover_elements

# ATDD-3.2-I10: regression — self-check textheight ~688pt unchanged (AC-9, R-1)
# Covers are paper-absolute (TikZ overlay) — must NOT touch geometry.
test_textheight_unchanged() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local th
  th=$(grep 'textheight = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$th" ]]; then echo "  (textheight not found in self-check)"; return 1; fi
  echo "  (textheight: ${th}pt [expect ~688.56])"
  echo "$th" | awk '{if ($1 >= 686 && $1 <= 690) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.2-I10" "regression: self-check textheight unchanged ~688pt (AC-9, R-1)" test_textheight_unchanged

# ATDD-3.2-I11: regression — self-check baselineskip ≈ 23.4bp (AC-9, R-3) — REPOINTED by Story 3.11
test_baselineskip_18bp() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local bs
  bs=$(grep 'baselineskip = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$bs" ]]; then echo "  (baselineskip not found in self-check)"; return 1; fi
  echo "  (baselineskip: ${bs}pt, expect ~23.49 [23.4bp]; 18.0=old naive, 21.6=R-3 trap)"
  echo "$bs" | awk '{if ($1 >= 22.5 && $1 <= 24.5) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.2-I11" "regression: self-check baselineskip ~23.4bp (REPOINTED by Story 3.11; AC-9, R-3)" test_baselineskip_18bp

# ATDD-3.2-I12: total pages ~50 ±5 (AC-9; front-matter reorder + abstract cover shifts pagination — Decision 2)
# Pre-impl: 50 pages. Post-impl: abstract cover +1; declaration removed from front matter (if Task-0.3 default) −1.
# Net may be 49/50/51. Range 44-55 accepts the shift; repoint transparently if it drifts (Decision 2).
test_total_pages() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local total_pages
  total_pages=$(grep 'total pages = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | tr -d '[:space:]')
  if [[ -z "$total_pages" ]]; then echo "  (page count not found)"; return 1; fi
  echo "  (pages: $total_pages, expected 40-55 [re-anchored by Story 3.14: abstract cover DELETED → 44 pp])"
  echo "$total_pages" | awk '{if ($1 >= 40 && $1 <= 55) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.2-I12" "total pages ~50 ±5 (AC-9; front-matter shift — Decision 2 repoint if drifts)" test_total_pages

# ATDD-3.2-I13: regression — no fancyhdr headheight warning (AC-9, R-2)
test_no_headheight_warning() {
  if [[ -f "main.log" ]]; then
    ! grep -qi 'headheight.*too low\|fancyhdr.*headheight' main.log 2>/dev/null
  else
    return 1
  fi
}
run_test "P1" "ATDD-3.2-I13" "regression: no fancyhdr headheight warning (AC-9, R-2)" test_no_headheight_warning

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: ±3mm position diagnostic (AC-8 visual-sampling gate) ==="

# ATDD-3.2-I14: DIAGNOSTIC — English title element positions for manual ±3mm overlay (AC-8)
# AC-8 (±3mm visual sampling) is a STORY-GATE manual overlay item (test-design-epic-3 assigns NO automated
# ±3mm test to 3.2, unlike Story 3.1's TC-E3-07). This records the rendered positions vs the reference
# baseline (reference PDF page 3) for the manual overlay comparison; it does NOT hard pass/fail.
# Exits 0 if the English title page + its blocks were found (prints positions), 1 if not found.
test_english_title_positions_diagnostic() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if english is None:
    print('  (English title page not found)'); sys.exit(1)
# Reference PDF page 3 baseline (y_mm from top): title ~36-51, degree-stmt ~98-142, By/author/sup/date ~189-223.
BASELINE = [('title block (top)', 36.7), ('By', 189.7), ('date (bottom)', 223.4)]
bs = sorted(page_blocks(english), key=lambda b: b['y0'])
print('  english-title=p%d rendered blocks (for manual ±3mm overlay vs reference page 3):' % (english+1))
for b in bs:
    print('    y=%.1fmm cx=%.1fmm size=%.1fpt | %r' %
          (mm(b['y0']), mm((b['x0']+b['x1'])/2.0), b['size'], b['txt'][:48]))
print('  reference baseline: title y~36-51mm, degree-stmt y~98-142mm, By/author/supervisor/date y~189-223mm')
print('  (AC-8: ±3mm verified by overlay at story gate; this diagnostic supplies the rendered positions)')
sys.exit(0)
"
}
run_test "P2" "ATDD-3.2-I14" "DIAGNOSTIC: English title positions for ±3mm overlay (AC-8 visual-sampling gate)" test_english_title_positions_diagnostic

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
  echo "   RED (fail pre-impl): I04 (page ordering — abstract cover absent), I06 (no-page-number — abstract"
  echo "      cover absent), I07 (degree-statement phrases), I08 (no emajor/edepartment), I09 (abstract cover"
  echo "      elements). I11 page-count may shift (Decision 2 repoint)."
  echo "   GREEN guards: I01-I03 (compile), I05 (English title all-TNR — 3.9 must not regress),"
  echo "      I10/I13 (self-check geometry/baselineskip/headheight)."
  echo ""
  echo "   NOTE: the fitz behavior tests are the real AC proof — source-greps cannot prove rendered page"
  echo "         order/fonts/no-page-number (a \makecover-order or \thispagestyle bug could evade a grep)."
  echo "         Decision 1: I06 verifies no-page-number via VISUAL SIGNATURE (footer-band drawings+spans),"
  echo "         not a text proxy. AC-8 ±3mm is a manual story-gate overlay (I14 supplies positions)."
  echo "         Tests are read-only — they do not modify the SUT."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
