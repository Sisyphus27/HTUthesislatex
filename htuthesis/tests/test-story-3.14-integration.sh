#!/usr/bin/env bash
# test-story-3.14-integration.sh — ATDD Integration Tests for Story 3.14 (structural cleanup — abstract cover + blank pages)
# TDD Phase: RED — the RED driver cluster is I04 (abstract-cover page ABSENT, AC-1) + I05 (blank pages ≤2, AC-3).
#             Pre-impl (baseline commit b348f30, post-Story 3.13 review = the over-shoot): \htu@abstractcover renders a
#             "博士学位论文摘要" page between English title and Chinese abstract; 9 \cleardoublepage command-call sites
#             force ~12 blank left pages. Post-impl (spec §1.1 line 5 + §2.4 line 187-189, PRIORITY): abstract-cover page
#             DELETED (doctoral → English → Chinese contiguous, matches reference PDF pp.1-12); blank pages ≤2 (only the
#             2 recto-keepers mainmatter+makeabstract can each emit ≤1). The GREEN guards I06/I07 (blank-page + cover
#             no-header/number VISUAL SIGNATURE, Decision 1) + I08-I10 (geometry regression) PASS pre+post.
#
# Usage: bash tests/test-story-3.14-integration.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 (compile gate R-12 + AC-1 abstract-cover-absent RED + AC-3 blank-≤2 RED) + P1 (AC-4 visual signature + regression)
# Linked ACs: AC-1 (delete abstract cover), AC-2 (cleardoublepage→clearpage except 2 keepers — unit proof + I05 blank≤2 consequence),
#             AC-3 (blank pages ≤2), AC-4 (FR-4 numbering + blank visual signature), AC-5 (compile + regression)
# Linked Risk: R-20 (score 4 — structural continuity + blank budget), R-keeper-mechanism (3 — Chinese-abstract recto held),
#              R-12 (score 4 — -g recompile), R-cross-story (3 — Decision-2 repoints of 3.2/3.3/3.10/1.5)
# TC coverage: TC-E3-55 (abstract-cover absent — I04), TC-E3-56 (blank pages ≤2 — I05), TC-E3-57 (mechanism — unit 02/03)
#
# NOTE: source-greps (test-story-3.14-unit.sh) prove the WIRING (abstractcover gone; cleardoublepage count==2). These
#   fitz tests prove the RENDERED result: abstract-cover page ABSENT (I04) + blank pages ≤2 (I05) + the surviving blanks
#   have NO header/number via VISUAL SIGNATURE (I06, Decision 1 — a text proxy false-passes a leaked number, the 2.3
#   CRITICAL lesson; get_drawings rule-absence + footer-band span count is the reliable signal).
#
# Truth source: 河南师范大学研究生学位论文格式要求.md §1.1 line 5 (前置部分: 封面、扉页、摘要、ABSTRACT、目录 — NO 摘要封面)
#   + §2.4 line 187 (扉页独立页；摘要/ABSTRACT/目录/章首页另起一页，一般从右页开始) + §2.4 line 189 (所有起始页码页共 2 个起始页
#   必须为右页). spec is PRIORITY (CLAUDE.md Decision 4, corrected 2026-06-17). Reference PDF (参考博士论文政治与
#   公共管理学院.pdf pp.1-12, direct fitz read 2026-06-19) AGREES — p3 English title → p4 Chinese abstract contiguous
#   (NO 摘要封面), 0 blank pages in front matter. See sprint-change-proposal-2026-06-17.md gap rows.

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
echo "ATDD Integration Tests: Story 3.14 — structural cleanup (abstract cover + blank pages; §1.1 + §2.4)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# Shared Python header: opens main.pdf, finds the 4 front-matter pages by signature (reused from Story 3.2),
#   defines blank_pages() / footer_num() / footer_band_visual() helpers.
#   doctoral = 博士学位论文 + 10476 (NOT 摘要); english = "dissertation submitted"/"graduate school of henan normal university";
#   abstract_cover = 博士学位论文摘要 (NOT doctoral) — the RED signal (must be None post-impl); chinese = 关键词.
#   blank_pages() = pages with <5 chars of text (the \cleardoublepage-inserted empty versos — htu@empty, no header/footer).
#   footer_num() = page-number span in the bottom band (reused from 3.13).
#   footer_band_visual(i) = Decision-1 VISUAL SIGNATURE (bottom-25mm drawings + spans count) — proves no header/number.
PY_HEAD='
import fitz, sys, re
doc = fitz.open("main.pdf")
W = doc[0].rect.width; H = doc[0].rect.height; mid = W / 2.0
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
for i in range(min(8, doc.page_count)):
    t = doc[i].get_text()
    if "博士学位论文摘要" in t and i != doctoral:
        abstract_cover = i; break
chinese = None
for i in range(min(10, doc.page_count)):
    t = doc[i].get_text()
    if "关键词" in t:
        chinese = i; break
def blank_pages():
    # pages with <5 chars of text = the \cleardoublepage-inserted empty versos (htu@empty: no header/footer/number).
    # cover/engcover have TikZ text (not blank); TOC/body/abstract have content. Only true filler blanks match.
    return [i for i in range(doc.page_count) if len(doc[i].get_text().strip()) < 5]
def footer_num(pno):
    out = []
    for b in doc[pno].get_text("dict").get("blocks", []):
        if b.get("type", 0) != 0: continue
        for ln in b.get("lines", []):
            for sp in ln.get("spans", []):
                t = sp["text"].strip()
                x0, y0, x1, y1 = sp["bbox"]
                if re.fullmatch(r"\d+", t) and y0 > H - 70 and 8 <= sp["size"] <= 13:
                    out.append({"text": t, "x0": x0, "cx": (x0 + x1) / 2.0})
    return out
def footer_band_visual(i):
    # Decision 1 VISUAL SIGNATURE: footer band = bottom 25mm. Returns (drawings, spans) counts.
    pg = doc[i]
    band_top = H - 25.0 / 25.4 * 72.0
    dc = sum(1 for d in pg.get_drawings() if d["rect"].y1 > band_top)
    sc = 0
    for b in pg.get_text("dict").get("blocks", []):
        if b.get("type", 0) != 0: continue
        for ln in b.get("lines", []):
            for sp in ln.get("spans", []):
                if sp["bbox"][1] > band_top: sc += 1
    return dc, sc
'

# ==========================================
# P0 Tests (Must Pass — 100%) — compile gate (R-12 full recompile) + AC-1/AC-3 RED drivers
# ==========================================
echo "=== P0: Compile gate (R-12 — -g full recompile; cover deletion + cleardoublepage→clearpage regenerate pagination) ==="

# ATDD-3.14-I01: latexmk -xelatex -g main.tex exit code 0 (AC-5, compile gate, R-12)
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-3.14-I01" "latexmk -xelatex -g main.tex exit code 0 (AC-5, R-12 full recompile)" test_full_compile

# ATDD-3.14-I02: zero compilation errors in main.log (AC-5)
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
run_test "P0" "ATDD-3.14-I02" "zero compilation errors in main.log (AC-5)" test_no_errors

# ATDD-3.14-I03: warning count <= 3 (AC-5, NFR <=3 vs Story 3.13 baseline = 1 standing xeCJK from 3.9)
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
run_test "P0" "ATDD-3.14-I03" "warning count <= 3 (AC-5, NFR <=3 new)" test_warning_count

echo ""

# ==========================================
# P0 Test — AC-1 abstract-cover page ABSENT (RED driver)
# ==========================================
echo "=== P0: AC-1 abstract-cover page ABSENT (RED driver — present pre-impl) ==="

# ATDD-3.14-I04: BEHAVIOR — abstract-cover page ABSENT (AC-1, TC-E3-55, FR-12 removed)
# spec §1.1 line 5 front-matter enumeration has NO 摘要封面; reference PDF pp.1-12 has none (p3 English → p4 Chinese).
# Pre-impl: \htu@abstractcover renders a "博士学位论文摘要" page between english and chinese → abstract_cover found → RED.
# Post-impl: macro deleted → abstract_cover is None → GREEN. Page order doctoral→english→chinese (contiguous).
test_abstract_cover_absent() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if abstract_cover is not None:
    print('  abstract-cover page FOUND at p%d (博士学位论文摘要) — still present; RED (AC-1, TC-E3-55)' % (abstract_cover+1))
    sys.exit(1)
print('  abstract-cover page ABSENT (no 博士学位论文摘要 page between english and chinese)')
if english is not None and chinese is not None:
    print('  page order: doctoral=p%d english=p%d chinese=p%d (contiguous per §1.1 line 5)' %
          (doctoral+1 if doctoral is not None else -1, english+1, chinese+1))
print('  → abstract-cover deleted; GREEN (AC-1 §1.1 line 5, FR-12 removed)')
sys.exit(0)
"
}
run_test "P0" "ATDD-3.14-I04" "BEHAVIOR: abstract-cover page ABSENT (doctoral→english→chinese contiguous) (AC-1, TC-E3-55; *** RED DRIVER ***)" test_abstract_cover_absent

# ==========================================
# P0 Test — AC-3 blank pages <= 2 (RED driver)
# ==========================================
echo "=== P0: AC-3 blank pages <= 2 (RED driver — ~12 pre-impl) ==="

# ATDD-3.14-I05: BEHAVIOR — blank pages <= 2 (AC-3, TC-E3-56, spec §2.4 line 189)
# spec §2.4 line 189: only 2 start-pages must be right pages (左页可以是空白页) → ≤2 blank fillers total.
# Pre-impl: 9 \cleardoublepage call sites each potentially emit a blank verso → ~12 blanks → RED.
# Post-impl: only the 2 recto-keepers (mainmatter + makeabstract) can each emit ≤1 blank → ≤2 → GREEN.
test_blank_pages_le_2() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
blanks = blank_pages()
print('  blank pages (<5 chars): count=%d at physical pages %s' %
      (len(blanks), [b+1 for b in blanks] if blanks else '[]'))
if len(blanks) > 2:
    print('  → %d blank pages (pre-impl ~12 from 9 cleardoublepage sites); RED (AC-3, TC-E3-56, §2.4 line 189 共2起始页)' % len(blanks))
    sys.exit(1)
print('  → %d blank page(s) (≤2 = the 2 recto-keeper fillers); GREEN (AC-3 §2.4 line 189)' % len(blanks))
sys.exit(0)
"
}
run_test "P0" "ATDD-3.14-I05" "BEHAVIOR: blank pages <= 2 (AC-3, TC-E3-56, §2.4 line 189; *** RED DRIVER ***)" test_blank_pages_le_2

echo ""

# ==========================================
# P1 Tests — AC-4 blank-page + cover no-header/number VISUAL SIGNATURE (GREEN guards, Decision 1)
# ==========================================
echo "=== P1: AC-4 blank-page + cover no-header/number VISUAL SIGNATURE (Decision 1; GREEN guards) ==="

# ATDD-3.14-I06: BEHAVIOR — blank pages have NO header/number (VISUAL SIGNATURE, Decision 1, AC-4, silent-failure-#6)
# The surviving blanks (≤2 from I05) route through the ThuThesis \def\cleardoublepage \thispagestyle{empty} mechanism
#   (cls:290). Decision 1: verify via VISUAL SIGNATURE (footer-band get_drawings + span count == 0), NOT a text proxy
#   (a leaked number shares no distinguishing text → text check false-passes; the 2.3 CRITICAL lesson).
# GREEN pre+post — the empty-style mechanism works regardless of blank count. RED = header/number leaked onto a blank.
test_blank_pages_no_header_number() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
blanks = blank_pages()
if not blanks:
    print('  (no blank pages to verify — 0 blanks is also GREEN; §2.4 permits ≤2)'); sys.exit(0)
bad = []
for b in blanks:
    dc, sc = footer_band_visual(b)
    print('  blank p%d: footer-band drawings=%d spans=%d (expect 0,0 — htu@empty)' % (b+1, dc, sc))
    if dc != 0 or sc != 0:
        bad.append((b+1, dc, sc))
if bad:
    print('  → %d blank page(s) with header/number leak: %s; RED (AC-4, silent-failure-#6)' % (len(bad), bad))
    sys.exit(1)
print('  → all %d blank page(s) header-less + number-less (VISUAL SIGNATURE); GREEN (AC-4 §2.4 + Decision 1)' % len(blanks))
sys.exit(0)
"
}
run_test "P1" "ATDD-3.14-I06" "BEHAVIOR: blank pages have NO header/number — VISUAL SIGNATURE (AC-4, silent-failure-#6, Decision 1; GREEN)" test_blank_pages_no_header_number

# ATDD-3.14-I07: BEHAVIOR — doctoral + English title pages have NO page number (VISUAL SIGNATURE, AC-4, FR-4)
# Covers use \thispagestyle{htu@empty} (cls:702 engcover; doctoral cover same) → no number. FR-4: cover/title no number.
# GREEN pre+post (regression watch — the structural cleanup must not regress cover page-style). Decision 1 visual signature.
test_cover_pages_no_number() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
bad = []
for label, p in (('doctoral', doctoral), ('english', english)):
    if p is None:
        print('  (%s page not found — front-matter signature changed?)' % label); continue
    dc, sc = footer_band_visual(p)
    fn = footer_num(p)
    print('  %s=p%d footer-band drawings=%d spans=%d footer_num=%s' % (label, p+1, dc, sc, [x['text'] for x in fn]))
    if dc != 0 or sc != 0 or fn:
        bad.append((label, p+1))
if bad:
    print('  → cover page(s) with page-number leak: %s; RED (AC-4, FR-4 cover no-number)' % bad)
    sys.exit(1)
print('  → doctoral + english pages number-less (VISUAL SIGNATURE); GREEN (AC-4, FR-4)')
sys.exit(0)
"
}
run_test "P1" "ATDD-3.14-I07" "BEHAVIOR: doctoral + English title pages NO page number — VISUAL SIGNATURE (AC-4, FR-4; GREEN)" test_cover_pages_no_number

echo ""

# ==========================================
# P1 Tests — AC-5 geometry regression (GREEN — structural cleanup != geometry/body spacing)
# ==========================================
echo "=== P1: AC-5 geometry regression (GREEN — cover deletion + cleardoublepage->clearpage != geometry/body spacing) ==="

# ATDD-3.14-I08: regression — self-check textheight ~688pt unchanged (AC-5, R-1)
# Covers are paper-absolute (TikZ overlay); cleardoublepage->clearpage is page-flow only. Neither touches geometry.
test_textheight_unchanged() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local th
  th=$(grep 'textheight = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$th" ]]; then echo "  (textheight not found in self-check)"; return 1; fi
  echo "  (textheight: ${th}pt [expect ~688.56])"
  echo "$th" | awk '{if ($1 >= 686 && $1 <= 690) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.14-I08" "regression: self-check textheight unchanged ~688pt (AC-5, R-1)" test_textheight_unchanged

# ATDD-3.14-I09: regression — self-check baselineskip ≈ 23.4bp (AC-5 — structural cleanup must not touch body spacing)
test_baselineskip_234bp() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local bs
  bs=$(grep 'baselineskip = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$bs" ]]; then echo "  (baselineskip not found in self-check)"; return 1; fi
  echo "  (baselineskip: ${bs}pt, expect ~23.49 [body 23.4bp, Story 3.11])"
  echo "$bs" | awk '{if ($1 >= 22.5 && $1 <= 24.5) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.14-I09" "regression: self-check baselineskip ~23.4bp (AC-5 — structural cleanup != body spacing)" test_baselineskip_234bp

# ATDD-3.14-I10: total pages — re-anchored LOWER (AC-5; abstract cover −1 + ~6 blanks removed)
# Pre-impl (post-3.13): 55 pages. Post-impl: abstract cover removed (−1) + ~6 blanks removed (−~6) → ~48 ±3.
# Range 42-55 accepts the drop; repoint transparently if it drifts (Decision 2).
test_total_pages() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local total_pages
  total_pages=$(grep 'total pages = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | tr -d '[:space:]')
  if [[ -z "$total_pages" ]]; then echo "  (page count not found)"; return 1; fi
  echo "  (pages: $total_pages, expected 40-55 [Story 3.14: abstract cover + 10 blanks removed → 44 pp])"
  echo "$total_pages" | awk '{if ($1 >= 40 && $1 <= 55) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.14-I10" "total pages re-anchored lower ~48 (AC-5; abstract cover + blanks removed — Decision 2 repoint if drifts)" test_total_pages

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
  echo "   Run with --run flag or ATDD_SKIP=0 to activate"
  echo "   RED drivers (FAIL pre-impl over-shoot, PASS post-impl spec §1.1/§2.4):"
  echo "      I04 abstract-cover page ABSENT (AC-1, TC-E3-55) *** PRIMARY RED DRIVER ***"
  echo "      I05 blank pages <= 2 (AC-3, TC-E3-56, §2.4 line 189)"
  echo "   GREEN guards (PASS pre+post — visual signature / geometry regression):"
  echo "      I01-I03 compile (R-12 -g recompile), I06 blank pages no header/number (VISUAL SIGNATURE, Decision 1,"
  echo "         silent-failure-#6), I07 doctoral+english no page number (FR-4), I08 textheight, I09 baselineskip 23.4bp,"
  echo "         I10 total pages (re-anchor lower — abstract cover + blanks removed)."
  echo ""
  echo "   Pre-impl baseline (commit b348f30, post-Story 3.13 review = over-shoot): \\htu@abstractcover renders a"
  echo "      博士学位论文摘要 page (between english and chinese); 9 \\cleardoublepage call sites → ~12 blanks. I04/I05"
  echo "      FAIL pre-impl. Post-impl (spec §1.1 line 5 + §2.4 line 187-189 PRIORITY) → GREEN."
  echo "   NOTE: the fitz behavior tests are the real AC proof — source-greps (unit) cannot prove rendered page"
  echo "         absence / blank count / no-header (a makecover or \\thispagestyle bug could evade a grep). Decision 1:"
  echo "         I06/I07 verify no-header/number via VISUAL SIGNATURE (footer-band drawings+spans), not a text proxy."
  echo "         spec §1.1 line 5 (无摘要封面) + §2.4 line 189 (共 2 个起始页必须为右页). R-20 = 4 (structural continuity)."
  echo "         Reference PDF AGREES (pp.1-12 direct fitz read 2026-06-19: p3 English → p4 Chinese contiguous, 0 blanks)."
  echo "         Tests are read-only (no SUT mutation)."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
