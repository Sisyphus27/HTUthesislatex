#!/usr/bin/env bash
# test-story-2.6-integration.sh — ATDD Red-Phase Integration Tests for Story 2.6
# TDD Phase: RED (counter/keyword behavior tests FAIL on pre-impl; compile-regression guards pass)
#
# Usage: bash tests/test-story-2.6-integration.sh [--run]
#   --run    Remove SKIP markers (for green-phase verification)
#
# Priority: P0 tests are blocking
# Linked Risk: R-12 (score 4, counter separator change — stale .aux after partial recompile)
# TC-E2-26 (counters hyphen), TC-E2-28 (appendix A-1), TC-E2-29 (Chinese keyword), TC-E2-30 (English keyword)
#
# NOTE: source-greps (unit) prove the DEFINITIONS are set; these tests prove the RENDERED output:
#   - ATDD-2.6-19/20/21: fitz BEHAVIOR — figure/table/equation captions read "图4-1"/"表4-1"/"(4-1)" (hyphen)
#   - ATDD-2.6-22: fitz BEHAVIOR — English keyword label "KEY WORDS" uppercase (not Title-Case)
#   A source-grep that \renewcommand\thefigure exists does NOT prove the caption renders "图4-1" (a later
#   \renewcommand could shadow it). These behavior tests are the real proof.
#
# .aux regex intentionally AVOIDED: "4.1" in the PDF/.aux is ambiguous — it can be a figure number (→ hyphen)
#   OR a section number (§2.10 natural-science heading numbering keeps the period). fitz distinguishes by the
#   图/表 prefix and the parenthesized equation form, so it is unambiguous. (Lesson: ATDD-2.2-22's .aux regex
#   matched nothing — fragile; deferred-work.md. fitz is the reliable signal.)
#
# fitz calibration notes (verified pre-impl on main.pdf, commit dffe776):
#   - All floats live in chap04 (chapter 4): figures "图4.1"(×9), tables "表4.1"(×7), equations "(4.1)"(×11).
#   - Format is "图4.1" (figurename directly concatenated, NO space) — regex 图\s*4([-.])\d+ handles both.
#   - English keyword on PDF page 9 ("Key Words", Title-Case → RED); Chinese keyword on page 7 ("关键词：", GREEN guard).
#   - body_start = PDF page index 18 (page 19).

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
echo "ATDD Integration Tests: Story 2.6 — Chapter-numbered counters and keyword labels"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# Shared Python header: opens main.pdf, finds body_start (first Arabic-numbered page), defines block helper.
PY_HEAD='
import fitz, sys, re
doc = fitz.open("main.pdf")
W = doc[0].rect.width; mid = W / 2.0
roman_re = re.compile(r"^[IVXLC]+$"); arabic_re = re.compile(r"^\d+$")
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
'

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Compile & Behavior ==="

# ATDD-2.6-16: latexmk -xelatex main.tex exit code 0 (AC-9)
# Full multi-pass flow (xelatex → bibtex → xelatex × 2) — MANDATORY for R-12 (.aux refresh after counter change).
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-2.6-16" "latexmk -xelatex main.tex exit code 0 (AC-9, R-12 full recompile)" test_full_compile

# ATDD-2.6-17: zero compilation errors in main.log (AC-9)
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
run_test "P0" "ATDD-2.6-17" "zero compilation errors in main.log (AC-9)" test_no_errors

# ATDD-2.6-18: warning count <= 3 (AC-9, baseline = 0 warnings after Story 2.5)
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
run_test "P0" "ATDD-2.6-18" "warning count <= 3 (AC-9, NFR <=3 new vs baseline)" test_warning_count

# ATDD-2.6-19: BEHAVIOR — figure captions read "图4-1" (hyphen, NOT "图4.1") (AC-1, TC-E2-26, §2.11)
# Scan body pages for 图<ch>(<sep>)<n>. Pre-impl: all period (calibrated 9); expect 0 period, >=3 hyphen post-impl.
test_figure_caption_hyphen_behavior() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
fig_hy = fig_per = 0
for i in range(body_start, doc.page_count):
    txt = doc[i].get_text()
    fig_hy += len(re.findall(r'图\s*4-\d+', txt))
    fig_per += len(re.findall(r'图\s*4\.\d+', txt))
print(f'  fig captions: hyphen={fig_hy}, period={fig_per} (pre-impl period=9)')
sys.exit(0 if (fig_hy >= 3 and fig_per == 0) else 1)
"
}
run_test "P0" "ATDD-2.6-19" "BEHAVIOR: figure captions hyphen 图4-1 (not 图4.1) (AC-1, TC-E2-26)" test_figure_caption_hyphen_behavior

# ATDD-2.6-20: BEHAVIOR — table captions read "表4-1" (hyphen, NOT "表4.1") (AC-2, TC-E2-26, §2.12)
test_table_caption_hyphen_behavior() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
tab_hy = tab_per = 0
for i in range(body_start, doc.page_count):
    txt = doc[i].get_text()
    tab_hy += len(re.findall(r'表\s*4-\d+', txt))
    tab_per += len(re.findall(r'表\s*4\.\d+', txt))
print(f'  tab captions: hyphen={tab_hy}, period={tab_per} (pre-impl period=7)')
sys.exit(0 if (tab_hy >= 3 and tab_per == 0) else 1)
"
}
run_test "P0" "ATDD-2.6-20" "BEHAVIOR: table captions hyphen 表4-1 (not 表4.1) (AC-2, TC-E2-26)" test_table_caption_hyphen_behavior

# ATDD-2.6-21: BEHAVIOR — equation labels read "(4-1)" (hyphen, NOT "(4.1)") (AC-3, TC-E2-26, §2.13)
test_equation_label_hyphen_behavior() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
eq_hy = eq_per = 0
for i in range(body_start, doc.page_count):
    txt = doc[i].get_text()
    eq_hy += len(re.findall(r'\(4-\d+\)', txt))
    eq_per += len(re.findall(r'\(4\.\d+\)', txt))
print(f'  eq labels: hyphen={eq_hy}, period={eq_per} (pre-impl period=11)')
sys.exit(0 if (eq_hy >= 3 and eq_per == 0) else 1)
"
}
run_test "P0" "ATDD-2.6-21" "BEHAVIOR: equation labels hyphen (4-1) (not (4.1)) (AC-3, TC-E2-26)" test_equation_label_hyphen_behavior

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Behavior & Regression Guards ==="

# ATDD-2.6-22: BEHAVIOR — English keyword label "KEY WORDS" uppercase (NOT "Key Words") (AC-8, TC-E2-30, §2.8)
# Scan ALL pages (English abstract is in frontmatter, before body_start). Pre-impl: "Key Words" Title-Case → RED.
test_english_keyword_uppercase_behavior() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
upper = mixed = 0
for i in range(doc.page_count):
    txt = doc[i].get_text()
    upper += txt.count('KEY WORDS')   # exact uppercase
    mixed += txt.count('Key Words')    # Title-Case (pre-impl defect)
print(f'  KEY WORDS(upper)={upper}, Key Words(mixed)={mixed}')
sys.exit(0 if (upper >= 1 and mixed == 0) else 1)
"
}
run_test "P1" "ATDD-2.6-22" "BEHAVIOR: English keyword KEY WORDS uppercase (not Key Words) (AC-8, TC-E2-30)" test_english_keyword_uppercase_behavior

# ATDD-2.6-23: BEHAVIOR — Chinese keyword label "关键词：" present (AC-7, TC-E2-29, §2.8) [guard: unchanged]
test_chinese_keyword_present_behavior() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
found = sum(doc[i].get_text().count('关键词：') for i in range(doc.page_count))
print(f'  关键词： occurrences={found} (expect >=1 on abstract page)')
sys.exit(0 if found >= 1 else 1)
"
}
run_test "P1" "ATDD-2.6-23" "BEHAVIOR: Chinese keyword 关键词： present (AC-7, TC-E2-29)" test_chinese_keyword_present_behavior

# ATDD-2.6-24: self-check textheight unchanged (~688pt) — counter change must NOT alter geometry (AC-9, R-1)
test_textheight_unchanged() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local th
  th=$(grep 'textheight = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$th" ]]; then echo "  (textheight not found)"; return 1; fi
  echo "  (textheight: ${th}pt [expect ~688.56])"
  echo "$th" | awk '{if ($1 >= 686 && $1 <= 690) exit 0; else exit 1}'
}
run_test "P1" "ATDD-2.6-24" "self-check textheight unchanged ~688pt (AC-9, R-1)" test_textheight_unchanged

# ATDD-2.6-25: no fancyhdr headheight warning (R-2 regression)
test_no_headheight_warning() {
  if [[ -f "main.log" ]]; then
    ! grep -qi 'headheight.*too low\|fancyhdr.*headheight' main.log 2>/dev/null
  else
    return 1
  fi
}
run_test "P1" "ATDD-2.6-25" "no fancyhdr headheight warning (R-2 regression)" test_no_headheight_warning

# ATDD-2.6-26: main.pdf exists and is non-empty (AC-9)
test_pdf_output() {
  [[ -f "main.pdf" ]] && [[ -s "main.pdf" ]]
}
run_test "P1" "ATDD-2.6-26" "main.pdf exists and is non-empty (AC-9)" test_pdf_output

# ATDD-2.6-27: total pages within ±5 of 49 (counter format doesn't add/remove lines; calibrated pre-impl = 49) (AC-9)
test_page_count() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local total_pages
  total_pages=$(grep 'total pages = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | tr -d '[:space:]')
  if [[ -z "$total_pages" ]]; then echo "  (page count not found)"; return 1; fi
  echo "  (pages: $total_pages, expected 49 +/- 5)"
  echo "$total_pages" | awk '{if ($1 >= 44 && $1 <= 54) exit 0; else exit 1}'
}
run_test "P1" "ATDD-2.6-27" "total pages within ±5 of 49 (AC-9)" test_page_count

# ATDD-2.6-28: self-check baselineskip ≈ 18bp (R-3 regression — body unchanged from Story 2.5)
test_baselineskip_18bp() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local bs
  bs=$(grep 'baselineskip = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$bs" ]]; then echo "  (baselineskip not found in self-check)"; return 1; fi
  echo "  (baselineskip: ${bs}pt, expect ~18.07 [18bp]; 21.6=R-3 trap regression)"
  echo "$bs" | awk '{if ($1 >= 17.5 && $1 <= 19.0) exit 0; else exit 1}'
}
run_test "P1" "ATDD-2.6-28" "self-check baselineskip ≈ 18bp (R-3 regression, Story 2.5 unchanged)" test_baselineskip_18bp

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
  echo "   ATDD-2.6-19/20/21 (counter hyphen behavior), 2.6-22 (English keyword uppercase)"
  echo "   FAIL until impl; compile-regression + textheight + keyword-Chinese guards stay green"
  echo ""
  echo "   NOTE: counter behavior (2.6-19/20/21) inspects the rendered PDF — source-greps cannot prove it."
  echo "         R-12 full recompile (2.6-16 latexmk -g) is mandatory; a stale .aux would false-FAIL."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
