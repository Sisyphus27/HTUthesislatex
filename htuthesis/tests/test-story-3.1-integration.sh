#!/usr/bin/env bash
# test-story-3.1-integration.sh — ATDD Red-Phase Integration Tests for Story 3.1 (doctoral cover page)
# TDD Phase: RED (cover-presence / ±3mm-position / font behavior tests FAIL on pre-impl;
#             compile + no-page-number + self-check regression guards pass)
#
# Usage: bash tests/test-story-3.1-integration.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 tests are blocking
# Linked ACs: AC-7 (±3mm, R-9), AC-8 (no page number — VISUAL SIGNATURE, Decision 1),
#             AC-1/2/3/4/5/6 (element presence + fonts), AC-10 (compile + regression)
# Linked Risk: R-9 (score 6, cover precision), R-6 (score 6, geometry coupling), R-1/R-3 (regression)
# TC-E3-05 (compile), TC-E3-06 (presence), TC-E3-07 (±3mm), TC-E3-08 (no page number)
#
# NOTE: source-greps (unit) prove labels are DEFINED; these tests prove the cover RENDERS correctly:
#   - ATDD-3.1-I04: cover NO page number via VISUAL SIGNATURE (get_drawings + footer span scan, Decision 1)
#   - ATDD-3.1-I05: cover element presence (单位代码/分类号/研究方向/申请学位类别/申请人/指导教师/学科、专业)
#   - ATDD-3.1-I06: cover ±3mm vs reference PDF page 2 baseline (R-9 — the dominant Epic 3 risk)
#   - ATDD-3.1-I07/I08/I09/I16: fonts (FangSong metadata / SimHei title / SimHei fields / SimSun label)
#   A source-grep that labels are defined does NOT prove they render at the right place/size (a layout
#   bug could misplace them). These fitz behavior tests are the real AC proof (Story 2.5/2.6/3.9 lesson).
#
# fitz calibration notes (verified pre-impl on main.pdf at baseline 004e20e):
#   - The doctoral cover is page 0 (physical 1) of main.pdf; found by signature "博士学位论文" + "10476".
#   - Pre-impl cover (ZZU layout): metadata top-RIGHT KaiTi 14pt ("学校代码10476"/"学号或申请号..."/"密级"),
#     博士学位论文 SimHei 36pt at y=121.8mm (sffamily xiaochu), title KaiTi 22pt (kaishu erhao),
#     5 fields KaiTi 16pt (作者姓名/导师姓名/学科门类/专业名称/完成时间), date inside the table.
#   - Target (reference PDF page 2): metadata top-LEFT FangSong 12pt (单位代码/学号/分类号),
#     博士学位论文 SimSun 45pt at y=89.1mm, title SimHei 18pt, 5 fields SimHei 15pt
#     (学科、专业/研究方向/申请学位类别/申请人/指导教师), date centered at y=247.7mm.
#   - Cover has NO page number (htu@empty); verified via get_drawings footer band (0 drawings) +
#     footer-band span scan (0 spans) — Decision 1 VISUAL SIGNATURE, not a text proxy.

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
echo "ATDD Integration Tests: Story 3.1 — Doctoral cover page"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# Shared Python header: opens main.pdf + reference PDF, finds the cover page, defines helpers.
# Reference PDF (reference thesis 2107084001) page 2 = doctoral cover = the R-9 baseline truth source.
PY_HEAD='
import fitz, sys, re
doc = fitz.open("main.pdf")
def mm(v): return v / 72.0 * 25.4
# Find the doctoral cover page: signature "博士学位论文" + "10476" (present pre- AND post-impl).
cover = None
for i in range(min(5, doc.page_count)):
    t = doc[i].get_text()
    if "博士学位论文" in t and "10476" in t:
        cover = i; break
if cover is None:
    print("  (doctoral cover page not found: no page with 博士学位论文 + 10476)"); sys.exit(2)
pg = doc[cover]; W = pg.rect.width; H = pg.rect.height
mid = W / 2.0
def blocks():
    out = []
    for b in pg.get_text("dict").get("blocks", []):
        if b.get("type", 0) != 0: continue
        spans = [sp for ln in b.get("lines", []) for sp in ln.get("spans", [])]
        txt = "".join(sp["text"] for sp in spans).strip()
        if not txt: continue
        x0, y0, x1, y1 = b["bbox"]
        ms = max((sp["size"] for sp in spans), default=0.0)
        fonts = set(sp["font"] for sp in spans)
        out.append({"txt": txt, "x0": x0, "y0": y0, "x1": x1, "y1": y1, "size": ms, "fonts": fonts})
    return out
'

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Compile + No-Page-Number + Presence + R-9 ±3mm ==="

# ATDD-3.1-I01: latexmk -xelatex -g main.tex exit code 0 (AC-10, compile gate; TC-E3-05)
# Cover layout rewrite can shift pagination → -g (force) full recompile is mandatory (R-12).
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-3.1-I01" "latexmk -xelatex main.tex exit code 0 (AC-10, TC-E3-05, R-12 full recompile)" test_full_compile

# ATDD-3.1-I02: zero compilation errors in main.log (AC-10)
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
run_test "P0" "ATDD-3.1-I02" "zero compilation errors in main.log (AC-10)" test_no_errors

# ATDD-3.1-I03: warning count <= 3 (AC-10, NFR ≤3 new vs Epic 2 baseline)
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
run_test "P0" "ATDD-3.1-I03" "warning count <= 3 (AC-10, NFR ≤3 new)" test_warning_count

# ATDD-3.1-I04: cover NO page number — VISUAL SIGNATURE (AC-8, TC-E3-08, Decision 1)
# Decision 1 conditional hard rule: "absence of page number" verified via the page-number's VISUAL
# SIGNATURE (get_drawings for any rule in the footer band + footer-band span scan), NOT a text proxy.
# A text proxy would false-pass if the number's digits overlapped other cover text (Epic 2 R-7 / 2.3
# CRITICAL lesson). GREEN guard pre-impl (htu@empty already suppresses); catches regression if the
# cover rewrite accidentally re-enables a footer.
test_cover_no_page_number_visual() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
# Footer band = bottom 25mm of the page (where outer-side page numbers live, cls LE/RO fancyfoot).
band_top = H - 25.0 / 25.4 * 72.0
# (1) VISUAL: any drawing (rule/line) in the footer band?
draw_count = sum(1 for d in pg.get_drawings() if d[\"rect\"].y1 > band_top)
# (2) VISUAL: any text span in the footer band?
span_count = 0
for b in pg.get_text(\"dict\").get(\"blocks\", []):
    if b.get(\"type\", 0) != 0: continue
    for ln in b.get(\"lines\", []):
        for sp in ln.get(\"spans\", []):
            if sp[\"bbox\"][1] > band_top:
                span_count += 1
print(f\"  cover=p{cover+1}, footer-band drawings={draw_count}, footer-band spans={span_count}\")
# No page number = 0 drawings AND 0 spans in the footer band.
sys.exit(0 if (draw_count == 0 and span_count == 0) else 1)
"
}
run_test "P0" "ATDD-3.1-I04" "cover NO page number — VISUAL SIGNATURE (AC-8, TC-E3-08, Decision 1)" test_cover_no_page_number_visual

# ATDD-3.1-I05: cover element PRESENCE (AC-1/2/4/5/6, TC-E3-06)
# Rendered-text search on the cover page for the HTU reference labels.
# Pre-impl (ZZU layout): 单位代码/分类号/研究方向/申请学位类别/申请人/指导教师/学科、专业 are ALL
#   ABSENT (current has 学校代码/密级/作者姓名/导师姓名/学科门类/专业名称/完成时间) → RED.
# Post-impl: all present → GREEN.
test_cover_elements_present() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
t = pg.get_text()
required = [\"单位代码\", \"分类号\", \"学科、专业\", \"研究方向\", \"申请学位类别\", \"申请人\", \"指导教师\"]
missing = [k for k in required if k not in t]
# Sanity anchor: 博士学位论文 must always be present (cover identity).
if \"博士学位论文\" not in t:
    missing.append(\"博士学位论文(sanity)\")
if missing:
    print(\"  cover=p\" + str(cover+1) + \", MISSING labels: \" + \", \".join(missing))
    sys.exit(1)
print(\"  cover=p\" + str(cover+1) + \", all reference labels present: \" + \", \".join(required))
sys.exit(0)
"
}
run_test "P0" "ATDD-3.1-I05" "cover element presence (单位代码/分类号/学科、专业/研究方向/申请学位类别/申请人/指导教师) (AC-1/2/4/5/6, TC-E3-06; RED pre-impl)" test_cover_elements_present

# ATDD-3.1-I06: cover ±3mm vs reference PDF page 2 baseline (AC-7, TC-E3-07, R-9 — dominant risk)
# THE R-9 PROOF. Extracts each anchor element's bbox on main.pdf's cover and diffs against the
# reference-PDF-page-2 baseline (extracted during story creation, embedded below). ±3mm tolerance.
# Pre-impl: 单位代码/学科、专业/指导教师 NOT found (RED), 博士学位论文 found but at y=121.8 vs 89.1
#   (off 32mm → RED). → test RED.
# Post-impl: all anchors within ±3mm → GREEN.
test_cover_r9_positions() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  # Reference PDF at project root (one level up from htuthesis/).
  local ref="../2107084001-任子辛-政治与公共管理学院.pdf"
  [[ -f "$ref" ]] || ref="2107084001-任子辛-政治与公共管理学院.pdf"
  [[ -f "$ref" ]] || { echo "  (reference PDF not found)"; return 1; }
  python -c "$PY_HEAD
# R-9 baseline — reference thesis page 2 (doctoral cover). A4 210x297mm. y_mm from paper top.
# (keyword, target_y_mm, target_x_center_mm_or_None). x_center None = left-anchor (x not checked).
BASELINE = [
    (\"单位代码\",    22.8, None),    # metadata row 1, top-left
    (\"博士学位论文\", 89.1, 105.0),   # label, centered ~105mm
    (\"学科、专业\",  191.9, None),    # field 1, left x≈60mm
    (\"指导教师\",    224.4, None),    # field 5 (last), left x≈60mm
]
TOL = 3.0
bs = blocks()
bad = []
for kw, ty, tx in BASELINE:
    hit = next((b for b in bs if kw in b[\"txt\"]), None)
    if hit is None:
        bad.append(kw + \" NOT FOUND\"); continue
    y = mm(hit[\"y0\"]); dy = abs(y - ty)
    msg = kw + \" y=%.1fmm (target %.1f, Δ%.1f)\" % (y, ty, dy)
    if tx is not None:
        xc = mm((hit[\"x0\"] + hit[\"x1\"]) / 2.0); dx = abs(xc - tx)
        msg += \" | x_center=%.1fmm (target %.1f, Δ%.1f)\" % (xc, tx, dx)
        if dy > TOL or dx > TOL: bad.append(msg)
    else:
        if dy > TOL: bad.append(msg)
print(\"  cover=p\" + str(cover+1) + \" R-9 element positions:\")
for kw, ty, tx in BASELINE:
    hit = next((b for b in bs if kw in b[\"txt\"]), None)
    if hit:
        print(\"    \" + kw + \" y=%.1fmm (target %.1f)\" % (mm(hit[\"y0\"]), ty))
    else:
        print(\"    \" + kw + \" NOT FOUND\")
if bad:
    print(\"  OUT OF ±3mm OR MISSING: \" + \" | \".join(bad)); sys.exit(1)
sys.exit(0)
"
}
run_test "P0" "ATDD-3.1-I06" "cover ±3mm vs reference PDF page 2 baseline (AC-7, TC-E3-07, R-9; RED pre-impl)" test_cover_r9_positions

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Fonts + Regression Guards ==="

# ATDD-3.1-I07: metadata font = FangSong ~12pt (AC-1; RED pre-impl KaiTi 14pt)
# Anchor: the block containing the schoolcode value "10476" (present pre- AND post-impl).
# Pre-impl: "学校代码10476" KaiTi 14pt → assert FangSong → RED.
# Post-impl: "单位代码10476" FangSong 12pt → GREEN.
test_metadata_fangsong() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
hit = next((b for b in blocks() if \"10476\" in b[\"txt\"]), None)
if hit is None: print(\"  (10476 metadata block not found)\"); sys.exit(1)
fonts = \",\".join(sorted(hit[\"fonts\"]))
print(\"  metadata block fonts=[%s] size=%.1fpt (target FangSong ~12pt)\" % (fonts, hit[\"size\"]))
ok = any(\"FangSong\" in f or \"仿宋\" in f or \"Fang\" in f for f in hit[\"fonts\"])
sys.exit(0 if ok else 1)
"
}
run_test "P1" "ATDD-3.1-I07" "metadata font = FangSong ~12pt (AC-1; RED pre-impl KaiTi 14pt)" test_metadata_fangsong

# ATDD-3.1-I08: title font = SimHei ~18pt (AC-4; RED pre-impl KaiTi 22pt)
# Anchor: the largest-font text block on the cover EXCLUDING the 博士学位论文 label (which is 36/45pt).
# Pre-impl: title KaiTi 22pt → assert SimHei → RED. Post-impl: title SimHei 18pt → GREEN.
test_title_simhei() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
bs = blocks()
label = next((b for b in bs if \"博士学位论文\" in b[\"txt\"]), None)
cand = [b for b in bs if b is not label and b[\"size\"] >= 15.0]
if not cand: print(\"  (no title candidate block found)\"); sys.exit(1)
title = max(cand, key=lambda b: b[\"size\"])
fonts = \",\".join(sorted(title[\"fonts\"]))
print(\"  title block fonts=[%s] size=%.1fpt (target SimHei ~18pt)\" % (fonts, title[\"size\"]))
ok = any(\"SimHei\" in f or \"Hei\" in f for f in title[\"fonts\"])
sys.exit(0 if ok else 1)
"
}
run_test "P1" "ATDD-3.1-I08" "title font = SimHei ~18pt (AC-4; RED pre-impl KaiTi 22pt)" test_title_simhei

# ATDD-3.1-I09: fields font = SimHei ~15pt (AC-5; RED pre-impl KaiTi 16pt)
# Anchor: a field-label block (申请人/指导教师 post; 作者姓名/导师姓名 pre) at y>180mm, size 14-17pt.
test_fields_simhei() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
field_labels = [\"申请人\", \"指导教师\", \"研究方向\", \"申请学位类别\", \"学科、专业\",
                \"作者姓名\", \"导师姓名\", \"学科门类\", \"专业名称\", \"完成时间\"]
cand = [b for b in blocks() if mm(b[\"y0\"]) > 180 and 13 <= b[\"size\"] <= 18
        and any(k in b[\"txt\"] for k in field_labels)]
if not cand: print(\"  (no field block found at y>180mm)\"); sys.exit(1)
fld = cand[0]
fonts = \",\".join(sorted(fld[\"fonts\"]))
print(\"  field block fonts=[%s] size=%.1fpt txt=%r (target SimHei ~15pt)\" % (fonts, fld[\"size\"], fld[\"txt\"][:30]))
ok = any(\"SimHei\" in f or \"Hei\" in f for f in fld[\"fonts\"])
sys.exit(0 if ok else 1)
"
}
run_test "P1" "ATDD-3.1-I09" "fields font = SimHei ~15pt (AC-5; RED pre-impl KaiTi 16pt)" test_fields_simhei

# ATDD-3.1-I10: regression — self-check textheight ~688pt unchanged (AC-10, R-1)
# Cover rewrite must NOT alter geometry (cover positions are paper-relative).
test_textheight_unchanged() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local th
  th=$(grep 'textheight = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$th" ]]; then echo "  (textheight not found in self-check)"; return 1; fi
  echo "  (textheight: ${th}pt [expect ~688.56])"
  echo "$th" | awk '{if ($1 >= 686 && $1 <= 690) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.1-I10" "self-check textheight unchanged ~688pt (AC-10, R-1)" test_textheight_unchanged

# ATDD-3.1-I11: regression — self-check baselineskip ~18bp (AC-10, R-3)
test_baselineskip_18bp() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local bs
  bs=$(grep 'baselineskip = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$bs" ]]; then echo "  (baselineskip not found in self-check)"; return 1; fi
  echo "  (baselineskip: ${bs}pt, expect ~18.07 [18bp]; 21.6=R-3 trap)"
  echo "$bs" | awk '{if ($1 >= 17.5 && $1 <= 19.0) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.1-I11" "self-check baselineskip ~18bp (AC-10, R-3)" test_baselineskip_18bp

# ATDD-3.1-I12: cover = exactly 1 page (AC-10; the 45pt label + 5 fields + date must fit one page)
# The reference cover is 1 page; overflow to 2 pages is a defect. Watch: if the new layout is too tall,
# the doctoral cover could spill. Detect: the page AFTER the cover must NOT also be a cover-signature page.
test_cover_one_page() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
nxt = cover + 1
if nxt >= doc.page_count:
    print(\"  cover=p\" + str(cover+1) + \" is the last page (1-page cover OK)\"); sys.exit(0)
nt = doc[nxt].get_text()
# A 2nd cover page would repeat 博士学位论文 + 10476. The next page is normally the English cover
# (htu@engcover) which has neither → distinct. If the NEXT page also has both, the cover overflowed.
if \"博士学位论文\" in nt and \"10476\" in nt:
    print(\"  cover overflow: page \" + str(nxt+1) + \" also has 博士学位论文 + 10476\"); sys.exit(1)
print(\"  cover=p\" + str(cover+1) + \" is exactly 1 page (next page is distinct)\"); sys.exit(0)
"
}
run_test "P1" "ATDD-3.1-I12" "cover is exactly 1 page (AC-10; no overflow)" test_cover_one_page

# ATDD-3.1-I13: total pages ~50 ±5 (AC-10; cover change may shift — Decision 2 repoint if legitimate)
test_total_pages() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local total_pages
  total_pages=$(grep 'total pages = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | tr -d '[:space:]')
  if [[ -z "$total_pages" ]]; then echo "  (page count not found)"; return 1; fi
  echo "  (pages: $total_pages, expected ~49-50 ±5 [cover change may shift — repoint transparently if drifts])"
  echo "$total_pages" | awk '{if ($1 >= 44 && $1 <= 55) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.1-I13" "total pages ~49-50 ±5 (AC-10; Decision 2 repoint if cover shifts pagination)" test_total_pages

# ATDD-3.1-I14: regression — no fancyhdr headheight warning (AC-10, R-2)
test_no_headheight_warning() {
  if [[ -f "main.log" ]]; then
    ! grep -qi 'headheight.*too low\|fancyhdr.*headheight' main.log 2>/dev/null
  else
    return 1
  fi
}
run_test "P1" "ATDD-3.1-I14" "no fancyhdr headheight warning (AC-10, R-2)" test_no_headheight_warning

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: 博士学位论文 label font = SimSun ~45pt ==="

# ATDD-3.1-I16: 博士学位论文 label font = SimSun ~45pt (AC-3; RED pre-impl SimHei 36pt)
# Truth source: reference PDF page 2 "博士学位论文" = SimSun 45.0pt (NOT sffamily/Heiti).
# Pre-impl: cls:578 \ziju{0}\xiaochu\sffamily → SimHei 36pt → assert SimSun → RED.
# Post-impl (Task 2.2): SimSun ~45pt (non-standard size; closest 号 is 初号 42bp) → GREEN.
# Note: 45pt is non-standard; the dev may pick 42-46bp — size band 40-48 accepts the empirical choice.
test_label_simsum() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
hit = next((b for b in blocks() if \"博士学位论文\" in b[\"txt\"]), None)
if hit is None: print(\"  (博士学位论文 label block not found)\"); sys.exit(1)
fonts = \",\".join(sorted(hit[\"fonts\"]))
print(\"  label block fonts=[%s] size=%.1fpt (target SimSun ~45pt)\" % (fonts, hit[\"size\"]))
font_ok = any(\"SimSun\" in f or \"宋\" in f for f in hit[\"fonts\"])
size_ok = 40.0 <= hit[\"size\"] <= 48.0
sys.exit(0 if (font_ok and size_ok) else 1)
"
}
run_test "P2" "ATDD-3.1-I16" "博士学位论文 label font = SimSun ~45pt (AC-3; RED pre-impl SimHei 36pt)" test_label_simsum

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
  echo "   RED (fail pre-impl): I05 (element presence), I06 (R-9 ±3mm), I07 (FangSong metadata),"
  echo "      I08 (SimHei title), I09 (SimHei fields), I16 (SimSun label) — pre-impl cover is the ZZU"
  echo "      layout (学校代码/密级/作者姓名/导师姓名/学科门类/专业名称/完成时间; KaiTi/SimHei-36pt)."
  echo "   GREEN guards: I01-I03 (compile), I04 (no page number — VISUAL SIGNATURE),"
  echo "      I10-I14 (self-check geometry/baselineskip/page-count/headheight)."
  echo ""
  echo "   NOTE: the fitz behavior tests are the real AC proof — source-greps cannot prove positions/"
  echo "         fonts (a layout bug could misplace a correctly-defined label). R-9 (I06) is the"
  echo "         dominant Epic 3 risk; ±3mm element-by-element vs reference PDF page 2."
  echo "         Decision 1: I04 verifies no-page-number via VISUAL SIGNATURE, not a text proxy."
  echo "         Tests are read-only — they do not modify the SUT."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
