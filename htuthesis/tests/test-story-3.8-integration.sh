#!/usr/bin/env bash
# test-story-3.8-integration.sh — ATDD Integration Tests for Story 3.8 (Free-form back matter — ack, papers, footnotes)
# TDD Phase: MIXED — ONE RED driver (footnote per-page reset, R-16, TC-E3-41) + DECISION-PENDING diagnostics (ack body
#             face TC-E3-38-sub, papers title text TC-E3-39, papers entry format AC-4) + GREEN guards. The ack title
#             "致 谢" SimHei 16.0pt 三号 centered renders correctly (main.pdf p47: 致 SimHei 16pt x0≈271 + 谢 SimHei 16pt
#             x0≈308, pair centered ~mid). Papers title SimHei 16pt centered (p49). Footnote body SimSun 9.0pt 小五号
#             (p47 "重庆大学化工博士..."). Footnote NUMBERING = per-CHAPTER (ctexbook/book default) NOT per-page → orphan
#             [2] markers on p19/p47 (a page with footnote "2" but no "1" = per-chapter, impossible under per-page) →
#             the I08 RED driver asserts per-page reset (FAILS pre-impl).
#
# Usage: bash tests/test-story-3.8-integration.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 (compile gate — counter change R-12) + P1 (architecture.md:41 后置内容 MEDIUM; R-16 footnote reset)
# Linked ACs: AC-1 (致谢 title SimHei 三号 centered), AC-2 (ack body face — DIAGNOSTIC), AC-3 (papers title — text
#             DIAGNOSTIC + format GREEN), AC-4 (papers entry format — DIAGNOSTIC), AC-5 (footnote 9pt SimSun GREEN +
#             per-page reset RED), AC-6 (Arabic page numbering continues), AC-7/8 (compile + regression)
# Linked Risk: R-16 (score 4 — footnote per-page reset; I08 RED driver), R-12 (score 4 — counter change; `latexmk -g`)
# TC coverage: TC-E3-38 (P1 致谢 title 三号 SimHei centered), TC-E3-39 (P2 papers title centered — text decision-pending),
#              TC-E3-40 (P1 footnote 9pt SimSun), TC-E3-41 (P1 footnote per-page reset — RED driver)
#
# NOTE: source-greps (unit) prove the WIRING; these fitz tests prove the RENDERED ack/papers/footnotes. fitz baseline
#   (pre-impl, commit 1619625):
#   - 致谢 TITLE page = p47 — 致 SimHei 16.0pt x0≈271 + 谢 SimHei 16.0pt x0≈308 (the \hspace{\ccwd} splits the pair into
#     2 spans), combined center ≈ page-mid (W/2=297.6). (p31 "致谢" SimHei 14pt x0≈98.9 = a TOC/索引 entry, NOT the title —
#     excluded by the size≥15.5 + centered-pair filter.)
#   - papers TITLE page = p49 — SimHei 16.0pt centered (cx=297.6=mid); text = "个人简历、在学期间发表的学术论文与研究成果"
#     (≠ spec §2.17 "攻读学位期间发表的学术论文目录" — DECISION-PENDING).
#   - footnote body (p47) = SimSun 9.0pt 小五号 ✓; marker = 6.0pt digit @ y≈762 x0≈83.6 (TimesNewRomanPSMT superscript).
#   - footnote numbering = per-CHAPTER: p19=[2], p24=[1], p29=[1], p43=[1], p47=[2] → p19/p47 show orphan [2] without
#     [1] on the same page (per-page reset would force every footnote-page to start at 1). I08 FAILS pre-impl.
#
#   - ATDD-3.8-I04: 致谢 title SimHei 三号 centered (AC-1, TC-E3-38) — GREEN guard
#   - ATDD-3.8-I05: ack body face DIAGNOSTIC (AC-2; decision-pending fangsong vs songti)
#   - ATDD-3.8-I06: papers title SimHei 三号 centered (AC-3, TC-E3-39 format GREEN; text DIAGNOSTIC)
#   - ATDD-3.8-I07: footnote body SimSun ~9pt (AC-5, TC-E3-40) — GREEN guard
#   - ATDD-3.8-I08: footnote per-page reset (AC-5, TC-E3-41, R-16) — *** RED DRIVER ***
#   A source-grep cannot prove rendered font/size/position/numbering. These fitz behavior tests are the real AC proof.

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
echo "ATDD Integration Tests: Story 3.8 — Free-form back matter (acknowledgement, papers, footnotes)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# Shared Python header: opens main.pdf, defines ack/papers/footnote helpers.
# ack_title(): the 致谢 TITLE page = a SimHei ~16pt "致" span + a SimHei ~16pt "谢" span whose combined center ≈ mid.
#   (Excludes the p31 TOC/索引 "致谢" SimHei 14pt left-aligned entry — fails the size≥15.5 + centered-pair filters.)
# papers_title(): a SimHei ~16pt centered span whose text contains 个人简历 OR 攻读学位 (the papers/resume TITLE page).
# footnote_pages(): {page_index: [footnote_numbers]} — the 6pt digit markers at the page-bottom footnote band
#   (y 750-775, size 5-8pt). Per-page reset ⟺ every footnote-page has "1" in its numbers (no orphan ≥2 without 1).
# footer_num(pno): a numeric span in the footer band (y0 > H-70), 8-13pt — the page number.
PY_HEAD='
import fitz, sys, re
doc = fitz.open("main.pdf")
W = doc[0].rect.width; H = doc[0].rect.height; mid = W / 2.0
def median(xs):
    if not xs: return None
    ys = sorted(xs); n = len(ys); return ys[n // 2]
def ack_title():
    # SimHei ~16pt "致" + "谢" pair centered (the \hspace{\ccwd} splits them into 2 spans). Combined center ≈ mid.
    for i in range(doc.page_count):
        d = doc[i].get_text("dict")
        zhi = xie = None
        for b in d.get("blocks", []):
            if b.get("type", 0) != 0: continue
            for ln in b.get("lines", []):
                for sp in ln.get("spans", []):
                    t = sp["text"].strip()
                    sz = sp["size"]; f = sp["font"]
                    if ("Hei" in f) and 15.5 <= sz <= 16.8:
                        if t == "致" and zhi is None: zhi = sp
                        elif t == "谢" and xie is None: xie = sp
        if zhi and xie:
            c = ((zhi["bbox"][0] + zhi["bbox"][2]) / 2.0 + (xie["bbox"][0] + xie["bbox"][2]) / 2.0) / 2.0
            if abs(c - mid) <= 12.0:
                return {"page": i, "zhi": zhi, "xie": xie, "center": c,
                        "size": (zhi["size"] + xie["size"]) / 2.0, "y0": min(zhi["bbox"][1], xie["bbox"][1])}
    return None
def papers_title():
    # SimHei ~16pt centered span whose text contains 个人简历 or 攻读学位 (the papers/resume TITLE).
    for i in range(doc.page_count):
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type", 0) != 0: continue
            for ln in b.get("lines", []):
                for sp in ln.get("spans", []):
                    t = sp["text"].strip()
                    if ("Hei" in sp["font"]) and 15.5 <= sp["size"] <= 16.8 and \
                       ("个人简历" in t or "攻读学位" in t):
                        cx = (sp["bbox"][0] + sp["bbox"][2]) / 2.0
                        if abs(cx - mid) <= 12.0:
                            return {"page": i, "text": t, "font": sp["font"], "size": sp["size"],
                                    "cx": cx, "y0": sp["bbox"][1]}
    return None
def footnote_pages():
    # {page_index: [footnote_numbers]} — 5-8pt digit markers in the page-bottom footnote band (y 720-778; widened from
    #   750-775 after empirical probe: a page with 2 footnotes stacks them at y≈736 + y≈762, so the narrow band missed
    #   the first marker). The 10.5pt page-number footer (y≈783) is excluded by both the size gate (5-8pt) and y<778.
    # TIGHTENED 2026-06-17 (Story 3.11 ripple, Decision 2): exclude MATH-FONT digits (`"Math" not in font`). The body
    #   baselineskip recalibration (18→23.4bp) reflowed body content → a math equation exponents (LatinModernMath-Regular,
    #   size 6, y≈730 on phys 41: R³/R² orbital-equation superscripts) landed in the footnote y-band, producing a spurious
    #   [3,2,2] false-positive → I08 false-FAIL. Genuine footnote markers render in the body font (SimSun digit), NOT a math
    #   font — excluding math fonts removes the false-positive without weakening real detection. Footnote per-page-RESET
    #   mechanism proven intact (5 genuine reset pages: phys 19/25/30/45/49, all contain "1"). See deferred-work §3.8
    #   (footnote_pages sample-calibrated + false-match-prone — this tightens it).
    # WIDENED 2026-06-17 (Story 3.12 ripple, Decision 2): band [720,778] → [H*0.62, H*0.96]. Story 3.12 Option A
    #   biblatex \footfullcite citation footnotes share the per-page counter (footmisc[perpage]); a long citation
    #   footnote (3 entries) pushes its marker up to y≈687 (H*0.82), outside the old [720,778] band → the helper
    #   saw only the later explanatory marker (e.g. [4]) on a citation-bearing page → false "lacking 1" → I08
    #   false-FAIL. The wider band catches both citation (y~687) + explanatory (y~750) markers; per-page reset
    #   (footmisc[perpage]) means every footnote-page still has "1". size 5-8 + digit + non-Math stays precise.
    out = {}
    for i in range(doc.page_count):
        nums = []
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type", 0) != 0: continue
            for ln in b.get("lines", []):
                for sp in ln.get("spans", []):
                    t = sp["text"].strip(); y0 = sp["bbox"][1]
                    if 5.0 <= sp["size"] <= 8.0 and H * 0.62 <= y0 <= H * 0.96 and (_m := re.fullmatch(r"\[(\d+)\]", t)) and "Math" not in sp["font"]:  # REPOINTED by Story 5.4 (2026-06-23): bare \d+→[\d+] (\thefootnote{[\arabic{footnote}]} under footmisc[perpage]; spec §1.2.4 示例 + 参考 PDF p20-36 + GB/T 7714-2015; single-span confirmed)
                        nums.append(int(_m.group(1)))
        if nums:
            out[i] = sorted(set(nums))
    return out
def footnote_body_spans():
    # footnote BODY text spans: SimSun ~9pt in the bottom band (the 小五号宋体 footnote prose).
    out = []
    for i in range(doc.page_count):
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type", 0) != 0: continue
            for ln in b.get("lines", []):
                for sp in ln.get("spans", []):
                    t = sp["text"].strip(); y0 = sp["bbox"][1]
                    if ("SimSun" in sp["font"]) and 8.2 <= sp["size"] <= 9.8 and y0 > H - 110 and len(t) >= 4:
                        out.append({"page": i, "text": t, "size": sp["size"], "font": sp["font"]})
    return out
def footer_num(pno):
    out = []
    for b in doc[pno].get_text("dict").get("blocks", []):
        if b.get("type", 0) != 0: continue
        for ln in b.get("lines", []):
            for sp in ln.get("spans", []):
                t = sp["text"].strip()
                x0, y0, x1, y1 = sp["bbox"]
                if re.fullmatch(r"\d+", t) and y0 > H - 70 and 8 <= sp["size"] <= 13:
                    out.append({"text": t, "font": sp["font"], "x0": x0, "cx": (x0 + x1) / 2.0})
    return out
'

# ==========================================
# P0 Tests (Must Pass — 100%) — compile gate (counter change R-12)
# ==========================================
echo "=== P0: Compile gate (R-12 — -g full recompile; AC-5 footnote counter change) ==="

# ATDD-3.8-I01: latexmk -xelatex -g main.tex exit code 0 (AC-7, compile gate, R-12)
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-3.8-I01" "latexmk -xelatex -g main.tex exit code 0 (AC-7, R-12 counter change)" test_full_compile

# ATDD-3.8-I02: zero compilation errors in main.log (AC-7)
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
run_test "P0" "ATDD-3.8-I02" "zero compilation errors in main.log (AC-7)" test_no_errors

# ATDD-3.8-I03: warning count <= 3 (AC-7, NFR <=3 vs Story 3.5-review baseline 1619625 = 1 standing xeCJK from 3.9)
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
run_test "P0" "ATDD-3.8-I03" "warning count <= 3 (AC-7, NFR <=3 new)" test_warning_count

echo ""

# ==========================================
# P1 Tests — 致谢 title (AC-1, TC-E3-38) — GREEN guard
# ==========================================
echo "=== P1: 致谢 title SimHei 三号 centered (AC-1, TC-E3-38; GREEN — inherited) ==="

# ATDD-3.8-I04: BEHAVIOR — 致谢 title SimHei 三号 ~16pt centered (AC-1, TC-E3-38)
# GREEN guard. Find the 致谢 TITLE page (致+谢 SimHei ~16pt pair centered at cx≈mid). Assert both spans are SimHei
#   (三号黑体), size ~16, pair centered. main.pdf p47: 致 SimHei 16.0pt + 谢 SimHei 16.0pt centered. spec §2.16
#   "「致谢」用三号黑体字，居中".
test_ack_title_simhei_centered() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
at = ack_title()
if not at:
    print('  (no 致谢 TITLE page found — 致+谢 SimHei ~16pt centered pair; RED; ack may not render)'); sys.exit(1)
hei = ('Hei' in at['zhi']['font']) and ('Hei' in at['xie']['font'])
centered = abs(at['center'] - mid) <= 8.0
size_ok = 15.5 <= at['size'] <= 16.8
print('  ack title: p%d 致=%r 谢=%r size=%.2fpt center=%.1f (mid=%.1f) hei=%s centered=%s' %
      (at['page']+1, at['zhi']['font'], at['xie']['font'], at['size'], at['center'], mid, hei, centered))
sys.exit(0 if (hei and centered and size_ok) else 1)
"
}
run_test "P1" "ATDD-3.8-I04" "BEHAVIOR: 致谢 title SimHei 三号 centered (AC-1, TC-E3-38; GREEN)" test_ack_title_simhei_centered

# ATDD-3.8-I05: BEHAVIOR — ack body face = SimSun (AC-2 Option A RESOLVED 2026-06-16)
# AC-2 DECISION RESOLVED: Zy chose Option A — 宋体 (spec §2.16 line 445; reference SILENT → spec governs). The ack
#   body must render SimSun (小四号宋体), NOT FangSong (the old zzuthesis 仿宋). main.pdf p47 body post-impl = SimSun.
#   PROMOTED from value-agnostic diagnostic (which only REPORTED the face) to a real assertion guarding Option A —
#   so a future story cannot silently revert to 仿宋 (mirror Story 3.7 ATDD-3.7-I05 promotion).
test_ack_body_face_diagnostic() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
at = ack_title()
if not at:
    print('  (no 致谢 title page — cannot probe body face)'); sys.exit(1)
pg = at['page']
faces = {}
for b in doc[pg].get_text('dict').get('blocks', []):
    if b.get('type', 0) != 0: continue
    for ln in b.get('lines', []):
        for sp in ln.get('spans', []):
            t = sp['text'].strip()
            if t and 11.0 <= sp['size'] <= 13.0 and sp['bbox'][1] > at['y0'] + 20 and len(t) >= 2:
                key = sp['font']
                faces[key] = faces.get(key, 0) + 1
dominant = max(faces, key=faces.get) if faces else None
print('  ack body faces (12pt CJK, below title): %s' % faces)
print('  dominant body face = %s' % dominant)
# AC-2 Option A: dominant body face = SimSun (NOT FangSong).
is_simsun = dominant is not None and 'SimSun' in dominant
is_fangsong = dominant is not None and 'FangSong' in dominant
print('  -> AC-2 Option A (宋体): SimSun=%s FangSong=%s' % (is_simsun, is_fangsong))
sys.exit(0 if (is_simsun and not is_fangsong) else 1)
"
}
run_test "P1" "ATDD-3.8-I05" "BEHAVIOR: ack body face = SimSun (AC-2 Option A resolved 2026-06-16; PROMOTED from diagnostic)" test_ack_body_face_diagnostic

echo ""

# ==========================================
# P1 Tests — papers title (AC-3, TC-E3-39) — format GREEN + text DIAGNOSTIC
# ==========================================
echo "=== P1: papers title SimHei 三号 centered (AC-3, TC-E3-39 format GREEN; title text DECISION-PENDING) ==="

# ATDD-3.8-I06: BEHAVIOR — papers title SimHei 三号 centered + text "攻读学位..." (AC-3 RESOLVED, TC-E3-39)
# AC-3 DECISION RESOLVED: Zy chose Option A1 — \htu@resume@title = "攻读学位期间发表的学术论文目录" (spec §2.17;
#   reference SILENT → spec governs). The title must render SimHei 三号 centered AND the text = 攻读学位... (NOT the old
#   个人简历...). main.pdf p49 post-impl: SimHei 16pt centered, text "攻读学位期间发表的学术论文目录". PROMOTED: the
#   title-TEXT is now asserted (was a diagnostic), guarding Option A1 against revert.
test_papers_title_simhei_centered() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
pt = papers_title()
if not pt:
    print('  (no papers TITLE page found — SimHei ~16pt centered 个人简历/攻读学位; RED)'); sys.exit(1)
hei = 'Hei' in pt['font']
centered = abs(pt['cx'] - mid) <= 8.0
size_ok = 15.5 <= pt['size'] <= 16.8
text_ok = '攻读学位' in pt['text']  # AC-3 Option A1: spec §2.17 title text
print('  papers title: p%d font=%r size=%.2fpt cx=%.1f (mid=%.1f) hei=%s centered=%s' %
      (pt['page']+1, pt['font'], pt['size'], pt['cx'], mid, hei, centered))
print('  papers title TEXT = %r  (AC-3 Option A1 攻读学位 = %s)' % (pt['text'], text_ok))
# AC-3: SimHei 三号 centered (format) AND title text = 攻读学位 (Option A1).
sys.exit(0 if (hei and centered and size_ok and text_ok) else 1)
"
}
run_test "P1" "ATDD-3.8-I06" "BEHAVIOR: papers title SimHei 三号 centered + text 攻读学位 (AC-3 resolved A1, TC-E3-39; PROMOTED)" test_papers_title_simhei_centered

echo ""

# ==========================================
# P1 Tests — footnotes (AC-5, TC-E3-40/41) — size GREEN + per-page reset RED DRIVER
# ==========================================
echo "=== P1: footnote 9pt SimSun (TC-E3-40 GREEN) + per-page reset (TC-E3-41, R-16 *** RED DRIVER ***) ==="

# ATDD-3.8-I07: BEHAVIOR — footnote body SimSun ~9pt 小五号 (AC-5 size/font, TC-E3-40)
# GREEN guard. The footnote body renders SimSun ~9pt (小五号宋体). main.pdf p47 "重庆大学化工博士..." SimSun 9.0pt.
#   spec §1.2.4 line 197 "脚注用小五号宋体字".
test_footnote_body_simsun_9pt() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
bodies = footnote_body_spans()
if not bodies:
    print('  (no footnote body found — SimSun ~9pt bottom-band span; RED; no footnotes in sample)'); sys.exit(1)
simsun = [b for b in bodies if 'SimSun' in b['font']]
sizes = [b['size'] for b in bodies]
med = median(sizes)
print('  footnote bodies=%d simsun=%d median_size=%s' % (len(bodies), len(simsun), ('%.2fpt' % med) if med else None))
for b in bodies[:3]:
    print('    p%d: %r %s %.1fpt' % (b['page']+1, b['text'][:30], b['font'], b['size']))
# AC-5 size/font: >=1 SimSun ~9pt footnote body.
ok = len(simsun) >= 1 and med is not None and 8.2 <= med <= 9.8
sys.exit(0 if ok else 1)
"
}
run_test "P1" "ATDD-3.8-I07" "BEHAVIOR: footnote body SimSun ~9pt 小五号 (AC-5, TC-E3-40; GREEN)" test_footnote_body_simsun_9pt

# ATDD-3.8-I08: BEHAVIOR — footnote PER-PAGE RESET (AC-5, TC-E3-41, R-16) — *** RED DRIVER ***
# Truth source: spec §1.2.4 line 109 "每页重新编号" + reference PDF (p15=[3],p18=[1],p19=[2],p20=[1] → per-PAGE reset).
#   CURRENT (pre-impl): ctexbook/book default = per-CHAPTER reset → some pages show footnote "2" (or higher) WITHOUT
#   "1" on the same page (the "1" was on an earlier page in the chapter). main.pdf: p19=[2], p47=[2] (orphan 2s).
#   PER-PAGE reset ⟺ every footnote-page has "1" in its numbers (each page restarts at 1; a page with N footnotes shows
#   1..N). DISCRIMINATOR: no footnote-page lacks "1". Pre-impl: p19/p47 lack "1" → RED. Post-impl (AC-5 fix): every
#   footnote-page has "1" → GREEN. Requires ≥2 footnote-pages (else SKIP — can't verify; the sample has 5).
test_footnote_perpage_reset() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
fp = footnote_pages()
print('  footnote_pages = {page: numbers}')
for p in sorted(fp):
    print('    p%d: %s' % (p+1, fp[p]))
if len(fp) < 2:
    print('  (only %d footnote-page(s) — cannot verify per-page reset; need >=2; SKIP-equivalent)' % len(fp)); sys.exit(1)
# PER-PAGE reset: every footnote-page must contain 1 (each page restarts at 1).
lacking = [p+1 for p in fp if 1 not in fp[p]]
pages_with_1 = [p+1 for p in fp if 1 in fp[p]]
print('  pages with a 1 marker = %d; pages LACKING 1 (orphan >=2, per-chapter signature) = %s' % (len(pages_with_1), lacking))
perpage_ok = (len(lacking) == 0)
if perpage_ok:
    print('  → PER-PAGE reset (every footnote-page has 1; matches spec §1.2.4 + reference p15-34)')
else:
    print('  → per-CHAPTER (orphan markers without 1); DIVERGES from spec §1.2.4 每页重新编号; RED pre-impl (R-16)')
sys.exit(0 if perpage_ok else 1)
"
}
run_test "P1" "ATDD-3.8-I08" "BEHAVIOR: footnote per-page reset (AC-5, TC-E3-41, R-16; *** RED DRIVER ***)" test_footnote_perpage_reset

echo ""

# ==========================================
# P1 Test — Arabic page numbering continues through back matter (AC-6) + regression
# ==========================================
echo "=== P1: Arabic page numbering continues (AC-6; GREEN — regression watch post-AC-5) ==="

# ATDD-3.8-I09: BEHAVIOR — ack/papers footer = Arabic outer (AC-6)
# GREEN guard + AC-5 REGRESSION WATCH. Ack + papers are in \backmatter → Arabic continues (no reset). The \@addtoreset
#   {footnote}{page} (AC-5) resets `footnote` only, NOT `page` — verify the page-number footer is unaffected. main.pdf: ack
#   p47 footer Arabic, papers p49 Arabic. Reference back-matter footers Arabic.
test_backmatter_footer_arabic() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
at = ack_title(); pt = papers_title()
target = at or pt
if not target:
    print('  (no ack/papers title page — RED)'); sys.exit(1)
foot = footer_num(target['page'])
if not foot:
    print('  (no footer page-number — RED)'); sys.exit(1)
fn = foot[0]
arabic = fn['text'].isdigit()
phys = target['page'] + 1
outer = (phys % 2 == 1 and fn['cx'] > mid) or (phys % 2 == 0 and fn['cx'] < mid)
print('  back-matter p%d (phys %d) footer=%r cx=%.1f mid=%.1f arabic=%s outer=%s (AC-5 foot-reset must NOT affect page)' %
      (target['page'], phys, fn['text'], fn['cx'], mid, arabic, outer))
sys.exit(0 if (arabic and outer) else 1)
"
}
run_test "P1" "ATDD-3.8-I09" "BEHAVIOR: ack/papers footer = Arabic outer (AC-6; regression watch post-AC-5)" test_backmatter_footer_arabic

# ATDD-3.8-I10: regression — self-check textheight ~688pt unchanged (AC-7, R-1)
test_textheight_unchanged() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local th
  th=$(grep 'textheight = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$th" ]]; then echo "  (textheight not found in self-check)"; return 1; fi
  echo "  (textheight: ${th}pt [expect ~688.56])"
  echo "$th" | awk '{if ($1 >= 686 && $1 <= 690) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.8-I10" "regression: self-check textheight unchanged ~688pt (AC-7, R-1)" test_textheight_unchanged

# ATDD-3.8-I11: regression — self-check baselineskip ≈ 23.4bp (AC-7 — ack/papers/footnote must not touch body spacing) — REPOINTED by Story 3.11
test_baselineskip_18bp() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local bs
  bs=$(grep 'baselineskip = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$bs" ]]; then echo "  (baselineskip not found in self-check)"; return 1; fi
  echo "  (baselineskip: ${bs}pt, expect ~23.49 [body 23.4bp])"
  echo "$bs" | awk '{if ($1 >= 22.5 && $1 <= 24.5) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.8-I11" "regression: self-check baselineskip ~23.4bp (REPOINTED by Story 3.11; AC-7 — ack/papers/footnote must not touch body spacing)" test_baselineskip_18bp

# ATDD-3.8-I12: total pages ~51 ±5 (AC-7; ack/papers in-place; footnote reset is zero-page-shift)
test_total_pages() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local total_pages
  total_pages=$(grep 'total pages = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | tr -d '[:space:]')
  if [[ -z "$total_pages" ]]; then echo "  (page count not found)"; return 1; fi
  echo "  (pages: $total_pages, expected 40-56 [re-anchored by Story 3.14: → 44 pp; was ~51 ±5] [ack/papers in-place; footnote reset zero-shift])"
  echo "$total_pages" | awk '{if ($1 >= 40 && $1 <= 56) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.8-I12" "total pages ~51 ±5 (AC-7; ack/papers in-place; footnote reset zero-shift)" test_total_pages

# ATDD-3.8-I13: regression — no fancyhdr headheight warning (AC-7, R-2)
test_no_headheight_warning() {
  if [[ -f "main.log" ]]; then
    ! grep -qi 'headheight.*too low\|fancyhdr.*headheight' main.log 2>/dev/null
  else
    return 1
  fi
}
run_test "P1" "ATDD-3.8-I13" "regression: no fancyhdr headheight warning (AC-7, R-2)" test_no_headheight_warning

echo ""

# ==========================================
# P2 Tests — papers entry-format DIAGNOSTIC (AC-4 — decision-pending)
# ==========================================
echo "=== P2: papers entry-format DIAGNOSTIC (AC-4; decision-pending enumerate vs references-style) ==="

# ATDD-3.8-I14: BEHAVIOR — papers entries = references reversed-hanging ~2\ccwd (AC-4 Option A RESOLVED)
# AC-4 DECISION RESOLVED: Zy chose Option A — "书写格式同参考文献" (spec §2.17 line 453) = Story 3.7 thebibliography
#   Option B reversed-hanging ([N] indented ~2\ccwd into the body, continuation at the margin). main.pdf p49 post-impl:
#   [N]_x0≈92.2, continuation_x0≈70.9 → [N]-indent≈21.4pt ≈ 2\ccwd (matches references 21.0pt). PROMOTED from diagnostic
#   to assert the reversed-hanging geometry (band 10-28pt ≈ 2\ccwd) — guards Option A against revert to flat enumerate.
test_papers_entry_format_diagnostic() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
import re as _re
pt = papers_title()
if not pt:
    print('  (no papers title page — cannot probe entries)'); sys.exit(1)
num_re = _re.compile(r'^\[\d+\]$')
start = pt['page']; end = min(start + 3, doc.page_count)
nums = []; conts = []
for i in range(start, end):
    for b in doc[i].get_text('dict').get('blocks', []):
        if b.get('type', 0) != 0: continue
        for ln in b.get('lines', []):
            spans = ln.get('spans', [])
            if not spans: continue
            t0 = spans[0]['text'].strip(); x0 = spans[0]['bbox'][0]; y0 = spans[0]['bbox'][1]
            if num_re.match(t0) and 9 <= spans[0]['size'] <= 12 and y0 > 120:
                nums.append(x0)
            elif x0 < 80 and 9.8 <= spans[0]['size'] <= 11.2 and y0 < H - 70 and len(t0) >= 2:
                conts.append(x0)
if not nums:
    print('  (no [N] entries detected — RED; papers list may not render)'); sys.exit(1)
num_x0 = sum(nums) / len(nums)
cont_x0 = min(conts) if conts else None
indent = (num_x0 - cont_x0) if cont_x0 is not None else None
reversed_ok = indent is not None and 10.0 <= indent <= 28.0  # ~2\ccwd (references baseline 21pt)
print('  papers [N] entries=%d [N]_x0=%.1f continuation_x0=%s [N]-indent=%s → %s' %
      (len(nums), num_x0, ('%.1f' % cont_x0) if cont_x0 is not None else None,
       ('%.1fpt' % indent) if indent is not None else None,
       'REVERSED ~2\\ccwd (matches references 21pt)' if reversed_ok else 'NOT reversed-hanging'))
sys.exit(0 if reversed_ok else 1)
"
}
run_test "P2" "ATDD-3.8-I14" "BEHAVIOR: papers entries reversed-hanging ~2\\ccwd (AC-4 Option A resolved; PROMOTED from diagnostic)" test_papers_entry_format_diagnostic

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
  echo "   RED driver: ATDD-3.8-I08 — footnote per-page reset (R-16, TC-E3-41). Current = per-CHAPTER (ctexbook/book"
  echo "      default); main.pdf p19=[2], p47=[2] show orphan markers without 1. Spec §1.2.4 line 109 + reference PDF"
  echo "      (p15-34 restart each page) require per-PAGE. FAILS pre-impl; PASSES post-impl (AC-5 fix)."
  echo "      (Unit ATDD-3.8-05 is the wiring-level RED driver — \@addtoreset{footnote}{page} / footmisc.)"
  echo "   GREEN guards (lock-in): I01-I03 (compile — R-12), I04 (致谢 title SimHei 三号 centered),"
  echo "      I07 (footnote SimSun 9pt), I09 (back-matter Arabic footer — AC-5 regression watch),"
  echo "      I10 (textheight), I11 (baselineskip 18bp), I12 (pages), I13 (no headheight)."
  echo "   DIAGNOSTICS (value-agnostic; PROMOTED post-decision):"
  echo "      I05 (ack body face — fangsong vs songti), I06 (papers title text — 个人简历 vs 攻读学位; format GREEN),"
  echo "      I14 (papers entry format — enumerate vs references-style)."
  echo ""
  echo "   NOTE: spec §2.16/§2.17 govern AC-2/3/4 (reference PDF SILENT on 致谢/攻读 titles → spec text tiebreaker,"
  echo "         mirror of 3.6 AC-6 / 3.7 AC-2). AC-5 (footnote per-page reset) is reference-CONFIRMED (p15-34)."
  echo "         architecture.md:41 = MEDIUM; R-16 = 4; R-12 = 4. Tests are read-only (no SUT mutation)."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
