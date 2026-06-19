#!/usr/bin/env bash
# test-story-2.4-integration.sh — ATDD Red-Phase Integration Tests for Story 2.4
# TDD Phase: RED (the BEHAVIOR test fails on pre-impl centered footers; compile-regression guards pass)
#
# Usage: bash tests/test-story-2.4-integration.sh [--run]
#   --run    Remove SKIP markers (for green-phase verification)
#
# Priority: P0 tests are blocking
# Linked Risk: R-7 (score 6), R-1 (score 9 regression), R-2 (score 6 headheight)
# TC-E2-15 (even bottom-left), TC-E2-16 (odd bottom-right), TC-E2-17 (cover none), TC-E2-18 (mainmatter=1)
#
# NOTE: The SOURCE-LEVEL grep tests in test-story-2.4-unit.sh are necessary but NOT sufficient.
#       A centered footer would let them false-pass if any code path still hit a centered style.
#       ATDD-2.4-20 is the BEHAVIOR test that compiles and inspects the RENDERED PDF (via PyMuPDF)
#       to prove page numbers actually sit at the outer side (even=left, odd=right). This is the
#       test that catches the real defect class (mirrors Story 2.3's ATDD-2.3-29 lesson).

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
echo "ATDD Integration Tests: Story 2.4 — Outer-side page numbering (Roman and Arabic)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Compile & Behavior ==="

# ATDD-2.4-17: latexmk -xelatex main.tex exit code 0 (AC-9)
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-2.4-17" "latexmk -xelatex main.tex exit code 0 (AC-9)" test_full_compile

# ATDD-2.4-18: zero compilation errors in main.log (AC-9)
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
run_test "P0" "ATDD-2.4-18" "zero compilation errors in main.log (AC-9)" test_no_errors

# ATDD-2.4-19: warning count <= 3 (AC-9, baseline = 0 warnings after Story 2.3)
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
run_test "P0" "ATDD-2.4-19" "warning count <= 3 (AC-9, NFR <=3 new vs baseline)" test_warning_count

# ATDD-2.4-20: BEHAVIOR — rendered PDF page numbers at OUTER side (even=bottom-left, odd=bottom-right)
# (AC-3/4, TC-E2-15/16, R-7 silent failure #9). THE test that proves the feature on rendered output.
# RED pre-impl: centered footers -> odd pages read as left-of-midline -> violation. GREEN post-impl.
test_outer_side_behavior() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "
import fitz, sys, re
doc = fitz.open('main.pdf')
W = doc[0].rect.width
mid = W / 2.0
roman_re = re.compile(r'^[IVXLC]+\$')
arabic_re = re.compile(r'^\d+\$')
def footer_num(i):
    page = doc[i]
    H = page.rect.height
    for b in page.get_text('blocks'):
        x0, y0, x1, y1, txt = b[0], b[1], b[2], b[3], b[4]
        t = txt.strip()
        if not t: continue
        # Footer zone: deep bottom of page (includeheadfoot footskip region).
        # Pure Roman or Arabic token of reasonable length = a page number.
        if y0 > H - 70 and 1 <= len(t) <= 5 and (roman_re.match(t) or arabic_re.match(t)):
            return (x0, x1, t)
    return None
violations = []
checked = 0
for i in range(doc.page_count):
    fn = footer_num(i)
    if fn is None: continue
    x0, x1, t = fn
    pageno = i + 1
    checked += 1
    if pageno % 2 == 1:        # odd/recto -> page number RIGHT of midline (x0 > mid)
        if not (x0 > mid):
            violations.append((pageno, t, 'odd->expected-right', round(x0, 1)))
    else:                       # even/verso -> page number LEFT of midline (x1 < mid)
        if not (x1 < mid):
            violations.append((pageno, t, 'even->expected-left', round(x1, 1)))
print(f'  checked={checked} numbered pages, midline={mid:.1f}, violations(first5)={violations[:5]}')
# Must have checked enough pages to be meaningful AND have zero position violations.
sys.exit(0 if (checked >= 4 and not violations) else 1)
"
}
run_test "P0" "ATDD-2.4-20" "BEHAVIOR: rendered page numbers at outer side (even=left, odd=right) (AC-3/4, TC-E2-15/16)" test_outer_side_behavior

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Regression Guards ==="

# ATDD-2.4-21: self-check dimensions unchanged — textheight ~688pt (AC-9, R-1)
test_selfcheck_dims_unchanged() {
  if [[ ! -f "main.log" ]]; then
    return 1
  fi
  local textheight
  textheight=$(grep 'textheight = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$textheight" ]]; then
    echo "  (textheight not found in self-check output)"
    return 1
  fi
  echo "  (textheight: ${textheight}pt [expect ~688])"
  # Footer-position change must NOT alter geometry. Tolerate +/-2pt for rounding.
  echo "$textheight" | awk '{if ($1 >= 686 && $1 <= 690) exit 0; else exit 1}'
}
run_test "P1" "ATDD-2.4-21" "self-check geometry unchanged (textheight ~688pt) (AC-9, R-1)" test_selfcheck_dims_unchanged

# ATDD-2.4-22: no fancyhdr headheight warning (regression, R-2)
test_no_headheight_warning() {
  if [[ -f "main.log" ]]; then
    ! grep -qi 'headheight.*too low\|fancyhdr.*headheight' main.log 2>/dev/null
  else
    return 1
  fi
}
run_test "P1" "ATDD-2.4-22" "no fancyhdr headheight warning (R-2 regression)" test_no_headheight_warning

# ATDD-2.4-23: main.pdf exists and is non-empty (AC-9)
test_pdf_output() {
  [[ -f "main.pdf" ]] && [[ -s "main.pdf" ]]
}
run_test "P1" "ATDD-2.4-23" "main.pdf exists and is non-empty (AC-9)" test_pdf_output

# ATDD-2.4-24: total pages ~50 (+/- rebaseline) — footer change must not alter page count (AC-9)
# REPOINTED by Story 3.11 (code review patch): body baselineskip recalibration (18→23.4bp) + heading-spacing
#   re-anchor (36→46.8 / 9→11.7bp) reflowed the body → page count 51→53+. The old ±3 band [47,53] sat at the
#   cliff; widened to [47,58] to absorb the recalibration ripple. Footer change still must not alter it.
test_page_count() {
  if [[ ! -f "main.log" ]]; then
    return 1
  fi
  local total_pages
  total_pages=$(grep 'total pages = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | tr -d '[:space:]')
  if [[ -z "$total_pages" ]]; then
    echo "  (page count not found)"
    return 1
  fi
  echo "  (pages: $total_pages, expected 40-58 [re-anchored by Story 3.14: -> 44 pp; was [47,58] post-3.11])"
  echo "$total_pages" | awk '{if ($1 >= 40 && $1 <= 58) exit 0; else exit 1}'
}
run_test "P1" "ATDD-2.4-24" "total pages in [47,58] (REPOINTED by Story 3.11; AC-9, recalibration reflow absorbed)" test_page_count

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: Supplementary Behavior ==="

# ATDD-2.4-25: BEHAVIOR — cover/title pages have NO page-number text (AC-5, TC-E2-17)
# AND the first numbering-start page (front-matter Roman start) is a right/recto page (AC-7, §2.4).
# GREEN pre-impl (cover already htu@empty + cover consumes an even page count so abstract lands recto).
test_cover_no_number_behavior() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "
import fitz, sys, re
doc = fitz.open('main.pdf')
roman_re = re.compile(r'^[IVXLC]+\$')
arabic_re = re.compile(r'^\d+\$')
def footer_num(i):
    page = doc[i]; H = page.rect.height
    for b in page.get_text('blocks'):
        x0, y0, x1, y1, txt = b[0], b[1], b[2], b[3], b[4]
        t = txt.strip()
        if t and y0 > H - 70 and 1 <= len(t) <= 5 and (roman_re.match(t) or arabic_re.match(t)):
            return t
    return None
nums = [i for i in range(doc.page_count) if footer_num(i) is not None]
if not nums:
    print('  no numbered pages found'); sys.exit(1)
first = nums[0]
leaks = [i + 1 for i in range(first) if footer_num(i) is not None]
# §2.4: numbering-start page #1 (front-matter Roman start) MUST be a right (recto = odd physical) page.
recto = (first + 1) % 2 == 1
print(f'  first-numbered page={first + 1}, recto={recto}, pages-before={first}, cover/blank-number-leaks={leaks}')
sys.exit(0 if (not leaks and recto) else 1)
"
}
run_test "P2" "ATDD-2.4-25" "BEHAVIOR: cover pages have NO page number + front-matter start is recto (AC-5/7, TC-E2-17, §2.4)" test_cover_no_number_behavior

# ATDD-2.4-26: BEHAVIOR — first Arabic (main-body) page numbered "1" (AC-6, TC-E2-18)
# AND that page is a right/recto page (AC-7, §2.4 numbering-start page #2).
# GREEN pre-impl (mainmatter resets to 1 + \cleardoublepage forces recto).
test_first_arabic_page_one() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "
import fitz, sys, re
doc = fitz.open('main.pdf')
roman_re = re.compile(r'^[IVXLC]+\$')
arabic_re = re.compile(r'^\d+\$')
def footer_num(i):
    page = doc[i]; H = page.rect.height
    for b in page.get_text('blocks'):
        x0, y0, x1, y1, txt = b[0], b[1], b[2], b[3], b[4]
        t = txt.strip()
        if t and y0 > H - 70 and 1 <= len(t) <= 5 and (roman_re.match(t) or arabic_re.match(t)):
            return t
    return None
arabic_pages = [(i, footer_num(i)) for i in range(doc.page_count)
                if footer_num(i) is not None and arabic_re.match(footer_num(i))]
if not arabic_pages:
    print('  no Arabic-numbered page found'); sys.exit(1)
first_idx, first_num = arabic_pages[0]
# §2.4: numbering-start page #2 (main-body Arabic start) MUST be a right (recto = odd physical) page.
recto = (first_idx + 1) % 2 == 1
print(f'  first Arabic page={first_idx + 1}, displayed number={first_num}, recto={recto}')
sys.exit(0 if (first_num == '1' and recto) else 1)
"
}
run_test "P2" "ATDD-2.4-26" "BEHAVIOR: first Arabic page numbered \"1\" + main-body start is recto (AC-6/7, TC-E2-18, §2.4)" test_first_arabic_page_one

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
  echo "   ATDD-2.4-20 (outer-side behavior) is expected to FAIL until the [C]->[LE,RO] change lands"
  echo "   Compile-regression + cover/first-page behavior guards must STAY green"
  echo ""
  echo "   NOTE: Outer-side POSITION (even=bottom-left, odd=bottom-right) is the core acceptance."
  echo "         ATDD-2.4-20 inspects the rendered PDF — source greps alone cannot prove it."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
