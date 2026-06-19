#!/usr/bin/env bash
# test-story-2.5-integration.sh — ATDD Red-Phase Integration Tests for Story 2.5
# TDD Phase: RED (baselineskip + centering behavior tests FAIL on pre-impl; compile-regression guards pass)
#
# Usage: bash tests/test-story-2.5-integration.sh [--run]
#   --run    Remove SKIP markers (for green-phase verification)
#
# Priority: P0 tests are blocking
# Linked Risk: R-3 (score 6, baselineskip 18bp NOT 21.6bp), R-1 (geometry regression)
# TC-E2-20 (baselineskip 18bp), TC-E2-21 (CJK trap), TC-E2-22 (L1 chapter centered),
# TC-E2-23 (L2 section centered), TC-E2-24 (L3 subsection), TC-E2-25 (L4 subsubsection bold Songti)
#
# NOTE: source-greps (unit) prove the VALUES are set; these tests prove the RENDERED output:
#   - ATDD-2.5-20: self-check baselineskip ≈ 18bp (the R-3 trap detector — excludes 21.6bp)
#   - ATDD-2.5-21/22: fitz BEHAVIOR — chapter/section CENTERED on rendered body pages (block-level detection)
#   - ATDD-2.5-27/28: subsection LEFT + subsubsection bold Songti (CJK span check)
#   A source-grep that `format+=\centering` exists does NOT prove the title renders centered (the cls:111
#   raggedright-override is the cautionary tale). These behavior tests are the real proof.
#
# fitz calibration notes (verified pre-impl on main.pdf):
#   - Headings detected at BLOCK level (get_text('dict') blocks), joining line spans for text + max size.
#     Line-level detection is unreliable (number + title split into separate spans/lines; \ccwd is glue, not a char).
#   - Chapter = block with a ~16bp (sanhao) span. Pre-impl: 4 body chapters LEFT + 3 back-matter (\chapter*) CENTERED.
#   - Section = block text matching ^N.N (excl N.N.N). Subsection = ^N.N.N (excl N.N.N.N).
#   - L4 bold: the CJK span (Chinese chars) must be bold AND not SimHei (Latin number span is a separate font).

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
echo "ATDD Integration Tests: Story 2.5 — Body line spacing and heading hierarchy"
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

# ATDD-2.5-17: latexmk -xelatex main.tex exit code 0 (AC-7)
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-2.5-17" "latexmk -xelatex main.tex exit code 0 (AC-7)" test_full_compile

# ATDD-2.5-18: zero compilation errors in main.log (AC-7)
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
run_test "P0" "ATDD-2.5-18" "zero compilation errors in main.log (AC-7)" test_no_errors

# ATDD-2.5-19: warning count <= 3 (AC-7, baseline = 0 warnings after Story 2.4)
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
run_test "P0" "ATDD-2.5-19" "warning count <= 3 (AC-7, NFR <=3 new vs baseline)" test_warning_count

# ATDD-2.5-20: self-check baselineskip ≈ 23.4bp (R-3 trap detector) (AC-1, TC-E2-20/21) — REPOINTED by Story 3.11
# Was ~18bp (Story 2.5 naive ×fontsize); Story 3.11 recalibrated to 23.4bp = Word「1.5倍」×natural (§2.7/2.9, gap G4).
# If R-3 trap fires: ~21.6pt → FAIL (caught, below the 22.5 floor). THE R-3 test (band [22.5,24.5] excludes 21.6 AND 18).
test_baselineskip_18bp() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local bs
  bs=$(grep 'baselineskip = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$bs" ]]; then echo "  (baselineskip not found in self-check)"; return 1; fi
  echo "  (baselineskip: ${bs}pt, expect ~23.49 [23.4bp]; 18.0=old naive, 21.6=R-3 trap)"
  echo "$bs" | awk '{if ($1 >= 22.5 && $1 <= 24.5) exit 0; else exit 1}'
}
run_test "P0" "ATDD-2.5-20" "self-check baselineskip ≈ 23.4bp (NOT 18, NOT 21.6) (REPOINTED by Story 3.11; AC-1, TC-E2-20/21, R-3)" test_baselineskip_18bp

# ATDD-2.5-21: BEHAVIOR — chapter titles CENTERED on rendered body pages (AC-2, TC-E2-22)
# Block-level: find 16bp (sanhao) blocks on body pages. Pre-impl: 4 body chapters LEFT + 3 back-matter
# (\chapter*) CENTERED → not-all-centered → RED. Post-impl: all centered → GREEN.
test_chapter_centered_behavior() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
chap = []
for i in range(body_start, doc.page_count):
    for blk in doc[i].get_text('dict').get('blocks', []):
        txt, ms, _ = block_ts(blk)
        if not txt: continue
        if 15.5 <= ms <= 16.6:
            bx = blk['bbox']; cx = (bx[0] + bx[2]) / 2
            chap.append((i + 1, round(cx, 1)))
centered = [c for _, c in chap if abs(c - mid) < 45]
print(f'  body_start=p{body_start+1}, chapter blocks={len(chap)}, centered={len(centered)} (centers: {chap[:6]})')
sys.exit(0 if (len(chap) >= 3 and len(centered) >= len(chap) - 2) else 1)
"
}
run_test "P0" "ATDD-2.5-21" "BEHAVIOR: chapter titles CENTERED on body pages (AC-2, TC-E2-22)" test_chapter_centered_behavior

# ATDD-2.5-22: BEHAVIOR — section titles CENTERED on rendered body pages (AC-3, TC-E2-23)
# REPOINTED by Story 3.13: detection was ^N.N Arabic (Story 2.5 natural-science); now humanities 第一节
#   (spec §2.10, gap M4). Section (= L2) stays CENTERED under humanities §2.10「一、二级标题居中」— the
#   centering assertion is unchanged; only the detection regex updated.
test_section_centered_behavior() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
sect = []
for i in range(body_start, doc.page_count):
    for blk in doc[i].get_text('dict').get('blocks', []):
        txt, ms, _ = block_ts(blk)
        if not txt: continue
        if re.match(r'^第[一二三四五六七八九十百]+节', txt):  # REPOINTED by 3.13: humanities 第一节 (was ^\d+\.\d+)
            bx = blk['bbox']; cx = (bx[0] + bx[2]) / 2
            sect.append((i + 1, round(cx, 1)))
centered = [c for _, c in sect if abs(c - mid) < 45]
print(f'  section blocks={len(sect)}, centered={len(centered)} (centers: {sect[:6]})')
sys.exit(0 if (len(sect) >= 3 and len(centered) >= len(sect) - 2) else 1)
"
}
run_test "P0" "ATDD-2.5-22" "BEHAVIOR: section titles CENTERED on body pages (AC-3, TC-E2-23)" test_section_centered_behavior

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Regression Guards ==="

# ATDD-2.5-23: self-check textheight unchanged (~688pt) — baselineskip change must NOT alter geometry (AC-7, R-1)
test_textheight_unchanged() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local th
  th=$(grep 'textheight = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$th" ]]; then echo "  (textheight not found)"; return 1; fi
  echo "  (textheight: ${th}pt [expect ~688.56])"
  echo "$th" | awk '{if ($1 >= 686 && $1 <= 690) exit 0; else exit 1}'
}
run_test "P1" "ATDD-2.5-23" "self-check textheight unchanged ~688pt (AC-7, R-1)" test_textheight_unchanged

# ATDD-2.5-24: no fancyhdr headheight warning (R-2 regression)
test_no_headheight_warning() {
  if [[ -f "main.log" ]]; then
    ! grep -qi 'headheight.*too low\|fancyhdr.*headheight' main.log 2>/dev/null
  else
    return 1
  fi
}
run_test "P1" "ATDD-2.5-24" "no fancyhdr headheight warning (R-2 regression)" test_no_headheight_warning

# ATDD-2.5-25: main.pdf exists and is non-empty (AC-7)
test_pdf_output() {
  [[ -f "main.pdf" ]] && [[ -s "main.pdf" ]]
}
run_test "P1" "ATDD-2.5-25" "main.pdf exists and is non-empty (AC-7)" test_pdf_output

# ATDD-2.5-26: total pages within ±5 of 50 (18bp tightens body lines → likely fewer pages) (AC-7)
test_page_count() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local total_pages
  total_pages=$(grep 'total pages = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | tr -d '[:space:]')
  if [[ -z "$total_pages" ]]; then echo "  (page count not found)"; return 1; fi
  echo "  (pages: $total_pages, expected 50 +/- 5)"
  echo "$total_pages" | awk '{if ($1 >= 45 && $1 <= 55) exit 0; else exit 1}'
}
run_test "P1" "ATDD-2.5-26" "total pages within ±5 of 50 (AC-7)" test_page_count

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: Supplementary Behavior ==="

# ATDD-2.5-27: BEHAVIOR — subsection titles LEFT-aligned + indented (AC-4, TC-E2-24)
# REPOINTED by Story 3.13: detection was ^N.N.N Arabic; now humanities 一、 (spec §2.10, gap M4). Subsection
#   (= L3) stays LEFT + 空两格 under humanities §2.10「三级以下居左、空两格」— assertion unchanged.
test_subsection_left_behavior() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
subs = []
# REPOINTED by Story 3.13: detection ^N.N.N Arabic → humanities 一、 (spec §2.10, gap M4). LEFT-check switched
#   from block CENTER (cx) to block LEFT-EDGE (bx[0]): a left-aligned subsection has bx[0] at the L3 indent
#   (~95pt); the CENTERED biblatex end-list type-sections (一、期刊论文 … cls centerline, Story 3.12, in back
#   matter) have bx[0]~200 — the bx[0] check cleanly excludes them. (A page-bound heuristic is unviable: chap03
#   has a demo \\section{参考文献} in the body.) Subsection (= L3) stays LEFT per §2.10「三级以下居左、空两格」.
for i in range(body_start, doc.page_count):
    for blk in doc[i].get_text('dict').get('blocks', []):
        txt, ms, _ = block_ts(blk)
        if not txt: continue
        if re.match(r'^[一二三四五六七八九十]+、', txt):  # REPOINTED by 3.13: humanities 一、 (was ^\d+\.\d+\.\d+)
            bx = blk['bbox']
            subs.append((i + 1, round(bx[0], 1)))
left = [x0 for _, x0 in subs if x0 < 150.0]  # left-edge at L3 indent (excludes centered type-sections)
print(f'  subsection 一、 blocks={len(subs)}, left-edge-aligned={len(left)} (left-edges: {subs[:6]})')
sys.exit(0 if (len(subs) >= 1 and len(left) >= 3) else 1)
"
}
run_test "P2" "ATDD-2.5-27" "BEHAVIOR: subsection titles LEFT-aligned (AC-4, TC-E2-24)" test_subsection_left_behavior

# ATDD-2.5-28: BEHAVIOR — subsubsection title CJK span is SimSun (bold-SimSun via AutoFakeBold, option A) (AC-5, TC-E2-25)
# REPOINTED by Story 3.13: detection was ^N.N.N.N Arabic; now humanities L4 （1） (spec §2.10 四级以下「（1）」, gap M4).
#   The L4 FONT (\htu@songtibold\bfseries → SimSun + AutoFakeBold) is UNCHANGED — only the number form changed.
# Option A: \htu@songtibold\bfseries → SimSun + AutoFakeBold. Check the CJK span font NAME = SimSun (not SimHei).
test_subsubsection_bold_songti_behavior() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
cjk_re = re.compile(r'[一-鿿]')
found = ok = 0
for i in range(body_start, doc.page_count):
    for blk in doc[i].get_text('dict').get('blocks', []):
        txt, ms, spans = block_ts(blk)
        if txt and re.match(r'^（\d+）', txt):  # REPOINTED by 3.13: humanities L4 （1） (was ^\d+\.\d+\.\d+\.\d+)
            found += 1
            for sp in spans:
                # L4 must render its CJK span as SimSun (bold-SimSun via AutoFakeBold), NOT SimHei/YaHei.
                if cjk_re.search(sp['text']) and ('SimSun' in sp['font']):
                    ok += 1; break
print(f'  subsubsection blocks={found}, bold-simSun={ok}')
sys.exit(0 if (found >= 1 and ok >= 1) else 1)
"
}
run_test "P2" "ATDD-2.5-28" "BEHAVIOR: subsubsection CJK span = SimSun (bold-SimSun, option A) (AC-5, TC-E2-25)" test_subsubsection_bold_songti_behavior

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
  echo "   ATDD-2.5-20 (baselineskip 18bp), 2.5-21 (chapter centered), 2.5-22 (section centered), 2.5-28 (bold Songti)"
  echo "   FAIL until impl; compile-regression + textheight + subsection-left guards stay green"
  echo ""
  echo "   NOTE: R-3 trap detector (ATDD-2.5-20) excludes 21.6bp — the core acceptance."
  echo "         Centering behavior (2.5-21/22) inspects the rendered PDF — source-greps cannot prove it."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
