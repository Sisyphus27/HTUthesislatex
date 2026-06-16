#!/usr/bin/env bash
# test-story-3.5-integration.sh — ATDD Red-Phase Integration Tests for Story 3.5 (TOC formatting)
# TDD Phase: RED (L1 chapter entry behavior test FAILS on pre-impl — renders SimSun 14pt, should be SimHei
#             12pt; the L1 page-number TNR guard + title/L2/indent/dot-leader/depth guards pass — those are
#             already correct). The L1 黑体小四号 fix is the sole RED behavior; everything else is GREEN.
#
# Usage: bash tests/test-story-3.5-integration.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P1/P2 (R-17 = score 2 LOW; no P0 — TOC styling is cosmetic, compilation still passes pre-impl)
# Linked ACs: AC-1 (title 目 录), AC-2 (L1 黑体小四号 + page-number TNR), AC-3 (L2 宋体小四号),
#             AC-5 (indent per level), AC-6 (dot leaders), AC-7 (depth), AC-8 (compile+regression)
# Linked Risk: R-17 (score 2, LOW — TOC dot leaders + level fonts; cosmetic), R-12 (.aux/.toc staleness — -g)
# TC coverage: TC-E3-24 (P1 title), TC-E3-25 (P2 L1 SimHei/L2-3 SimSun), TC-E3-26 (P2 dot leaders),
#              TC-E3-27 (P2 depth 3 + indent 1 char/level)
#
# NOTE: source-greps (unit) prove the WIRING; these fitz tests prove the RENDERED TOC page:
#   - ATDD-3.5-I04: TOC title "目 录" SimHei ~16pt centered (AC-1, TC-E3-24) — GREEN (already correct)
#   - ATDD-3.5-I05: L1 chapter entries SimHei 小四号 12pt (AC-2, TC-E3-25) — RED pre-impl (SimSun 14pt). THE FIX proof.
#   - ATDD-3.5-I06: L1 page-number = TNR (not LMSans) (AC-2 Task 1.2 guard) — GREEN guard; RED if Task 1.2 omitted.
#   - ATDD-3.5-I07: L2 section entries SimSun 小四号 12pt at 2\ccwd (AC-3, TC-E3-25) — GREEN
#   - ATDD-3.5-I08: per-level indent delta ≈ 24pt (2\ccwd) (AC-5, TC-E3-27) — GREEN
#   - ATDD-3.5-I09: dot leaders present (AC-6, TC-E3-26) — GREEN
#   - ATDD-3.5-I10: tocdepth=2, no 4th-level rows (AC-7, TC-E3-27) — GREEN
#   - ATDD-3.5-I11: no \wuhao 10.5pt CJK span on TOC (AC-4 \wuhao-leak guard) — GREEN (no L3 row renders at depth 2;
#                   the real AC-4 behavior proof is the scratch depth-3 raise per story Dev Notes Task 2.2 + unit 3.5-03)
#   A source-grep cannot prove rendered font/size/indent (a \sffamily override could evade it). These fitz behavior
#   tests are the real AC proof (Story 2.5/2.6/3.1/3.2/3.4 behavior-test lesson).
#
# fitz calibration notes (verified pre-impl on main.pdf at baseline acb4e5b, TOC page p11 / idx 10):
#   - TOC title: SimHei 16.0pt, 目 at cx≈279 + 录 at cx≈316 (centered ~297 = page mid). GREEN.
#   - L1 entries (4): 模板简介及安装 / 关于该模板的使用 / 常用排版示例 / 参考文献 — all SimSun 14.0pt x0≈92. RED
#     (should be SimHei 12.0pt per spec §2.6 + reference p10).
#   - L2 section entries: SimSun 12.0pt x0≈95 (e.g. 模板简介 at the 2.1 label row). GREEN.
#   - Page-number spans (20): all TimesNewRomanPSMT 12pt at x0≈518. GREEN pre-impl; the \rmfamily guard keeps
#     them TNR post-impl (a missing guard + L1 \sffamily would regress them to LMSans).
#   - Dot leaders: \titlerule*{.} dots present between entry text and page number. GREEN.

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
echo "ATDD Integration Tests: Story 3.5 — Table of contents formatting"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# Shared Python header: opens main.pdf, finds the TOC page, defines L1/L2 entry + page-number helpers.
# TOC page = first page with a SimHei size>14 '目' span AND a SimHei size>14 '录' span near the top (y<170).
PY_HEAD='
import fitz, sys, re
doc = fitz.open("main.pdf")
W = doc[0].rect.width; mid = W / 2.0
cjk_re = re.compile(r"[一-鿿]")
sec_label_re = re.compile(r"^\s*\d+\.\d+")
# TOC page detection: SimHei title 目/录 size>14 at y<170.
toc = None
for i in range(doc.page_count):
    d = doc[i].get_text("dict")
    has_mu = has_lu = False
    for b in d.get("blocks", []):
        for ln in b.get("lines", []):
            for sp in ln.get("spans", []):
                if sp["size"] > 14 and sp["bbox"][1] < 170:
                    if "目" in sp["text"]: has_mu = True
                    if "录" in sp["text"]: has_lu = True
    if has_mu and has_lu:
        toc = i; break
def mm(v): return v / 72.0 * 25.4
def median(xs):
    if not xs: return None
    ys = sorted(xs); n = len(ys); return ys[n // 2]
def l1_entries(idx):
    # L1 chapter entries: CJK text at x0<100, size in [11,15], len>=2 CJK chars, NOT a N.N section label.
    # Pre-impl: SimSun 14pt; post-impl: SimHei 12pt. Returns list of (font, size, x0, text).
    if idx is None: return []
    pg = doc[idx]; out = []
    for b in pg.get_text("dict").get("blocks", []):
        if b.get("type", 0) != 0: continue
        for ln in b.get("lines", []):
            for sp in ln.get("spans", []):
                tx = sp["text"].strip(); x0 = sp["bbox"][0]
                if x0 < 100 and cjk_re.search(tx) and 11 <= sp["size"] <= 15 and len(tx) >= 2:
                    if sec_label_re.match(tx): continue   # skip "2.1" section labels
                    out.append((sp["font"], sp["size"], x0, tx))
    return out
def section_entries(idx):
    # L2 section entries: CJK title span at x0 in [115,130], size in [11,13]. (Our section indent = 2\ccwd
    # renders x0≈121.9.) Returns list of (font, size, x0, text).
    if idx is None: return []
    pg = doc[idx]; out = []
    for b in pg.get_text("dict").get("blocks", []):
        if b.get("type", 0) != 0: continue
        for ln in b.get("lines", []):
            for sp in ln.get("spans", []):
                tx = sp["text"].strip(); x0 = sp["bbox"][0]
                if 115 <= x0 <= 130 and cjk_re.search(tx) and 11 <= sp["size"] <= 13 and len(tx) >= 2:
                    out.append((sp["font"], sp["size"], x0, tx))
    return out
def subsection_entries(idx):
    # L3 subsection entries: CJK title span at x0 in [140,165], size in [9,13] (pre-impl 10.5pt, post-impl 12pt).
    # Our subsection indent = 4\ccwd renders x0≈150.4. chap04 has non-starred \subsection → L3 rows DO render at
    # \tocdepth=2 (subsection = level 2; N.N.N). AC-4 is directly behavior-testable (no scratch depth-3 raise
    # needed — the create-story assumption of "no L3 row" was WRONG; verified pre-impl baseline acb4e5b).
    if idx is None: return []
    pg = doc[idx]; out = []
    for b in pg.get_text("dict").get("blocks", []):
        if b.get("type", 0) != 0: continue
        for ln in b.get("lines", []):
            for sp in ln.get("spans", []):
                tx = sp["text"].strip(); x0 = sp["bbox"][0]
                if 140 <= x0 <= 165 and cjk_re.search(tx) and 9 <= sp["size"] <= 13 and len(tx) >= 2:
                    out.append((sp["font"], sp["size"], x0, tx))
    return out
def pagenum_fonts(idx):
    # Page-number spans: rightmost digit-only spans (x>500). Returns set of fonts (the \rmfamily-guard target).
    if idx is None: return set()
    pg = doc[idx]; out = set()
    for b in pg.get_text("dict").get("blocks", []):
        for ln in b.get("lines", []):
            for sp in ln.get("spans", []):
                tx = sp["text"].strip()
                if sp["bbox"][0] > 500 and re.fullmatch(r"\d+", tx):
                    out.add(sp["font"])
    return out
'

# ==========================================
# P0 Tests (Must Pass — 100%) — compile gate
# ==========================================
echo "=== P0: Compile gate (R-12 full recompile — the L1 font/size change alters the .toc) ==="

# ATDD-3.5-I01: latexmk -xelatex -g main.tex exit code 0 (AC-8, compile gate, R-12)
# The L1 font/size change (\sihao→\xiaosi+\sffamily) alters the .toc entry rendering → -g full recompile.
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-3.5-I01" "latexmk -xelatex -g main.tex exit code 0 (AC-8, R-12 full recompile)" test_full_compile

# ATDD-3.5-I02: zero compilation errors in main.log (AC-8)
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
run_test "P0" "ATDD-3.5-I02" "zero compilation errors in main.log (AC-8)" test_no_errors

# ATDD-3.5-I03: warning count <= 3 (AC-8, NFR <=3 vs Story 3.4 baseline = 1 standing xeCJK from 3.9)
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
run_test "P0" "ATDD-3.5-I03" "warning count <= 3 (AC-8, NFR <=3 new)" test_warning_count

echo ""

# ==========================================
# P1 Tests — title (GREEN) + L1 entry (RED — THE FIX) + regression guards
# ==========================================
echo "=== P1: TOC title (GREEN) + L1 SimHei 小四号 (RED — THE FIX) + L1 page-number TNR guard ==="

# ATDD-3.5-I04: BEHAVIOR — TOC title "目 录" SimHei ~16pt centered (AC-1, TC-E3-24)
# GREEN guard (already correct via \htu@chapter*[]{\contentsname} → \sffamily\sanhao → SimHei 三号). "目" and "录"
#   render as TWO SimHei 16pt spans (\contentsname = 目\hspace{\ccwd} 录). Assert both SimHei ~16pt and the
#   combined bbox centered (cx ≈ mid).
test_toc_title_simhei() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if toc is None:
    print('  (TOC page not found — RED)'); sys.exit(1)
mu = lu = None
for b in doc[toc].get_text('dict').get('blocks', []):
    for ln in b.get('lines', []):
        for sp in ln.get('spans', []):
            if '目' in sp['text'] and sp['size'] > 14: mu = sp
            if '录' in sp['text'] and sp['size'] > 14: lu = sp
if mu is None or lu is None:
    print('  (title 目/录 spans size>14 not found — RED)'); sys.exit(1)
ms = max(mu['size'], lu['size'])
heiti = all(('SimHei' in s['font'] or 'Hei' in s['font']) for s in [mu, lu])
x0 = min(mu['bbox'][0], lu['bbox'][0]); x1 = max(mu['bbox'][2], lu['bbox'][2])
cx = (x0 + x1) / 2.0; centered = abs(cx - mid) < 18.0
print('  toc-title 目=%r 录=%r size=%.1f heiti=%s cx=%.1f centered=%s' %
      (mu['font'], lu['font'], ms, heiti, cx, centered))
sys.exit(0 if (heiti and 15.0 <= ms <= 17.0 and centered) else 1)
"
}
run_test "P1" "ATDD-3.5-I04" "BEHAVIOR: TOC title 目 录 SimHei ~16pt centered (AC-1, TC-E3-24; GREEN — already correct)" test_toc_title_simhei

# ATDD-3.5-I05: BEHAVIOR — L1 chapter entries SimHei 小四号 ~12pt (AC-2, TC-E3-25) — THE FIX proof
# Pre-impl: L1 entries render SimSun 14.0pt (the \sihao[1] before-arg). Post-impl: \xiaosi[1]\sffamily → SimHei
#   12.0pt. Assert: at least one L1 entry, the median size ≈12 (NOT 14), and the entries are SimHei (NOT SimSun).
#   This is the AC-2 proof (RED driver = font SimHei + size ≈12). Reference p10: SimHei 12.00pt.
test_l1_entries_simhei_xiaosi() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
ents = l1_entries(toc)
if len(ents) < 1:
    print('  (no L1 chapter entries found — RED)'); sys.exit(1)
fonts = [e[0] for e in ents]; sizes = [e[1] for e in ents]
med = median(sizes)
heiti = all(('SimHei' in f or 'Hei' in f) for f in fonts)
print('  L1 entries=%d fonts=%s median size=%.2fpt heiti=%s (spec §2.6 黑体小四号; ref p10 SimHei 12.0)' %
      (len(ents), set(fonts), med, heiti))
for f, s, x, t in ents[:4]:
    print('    %r %.1fpt x0=%.1f | %s' % (f, s, x, t[:24]))
# AC-2: SimHei (RED driver — pre-impl SimSun) AND size ≈12 (NOT 14).
sys.exit(0 if (heiti and 11.3 <= med <= 12.7) else 1)
"
}
run_test "P1" "ATDD-3.5-I05" "BEHAVIOR: L1 chapter entries SimHei 小四号 ~12pt (AC-2, TC-E3-25; RED pre-impl — SimSun 14pt)" test_l1_entries_simhei_xiaosi

# ATDD-3.5-I06: BEHAVIOR — L1 page-number = TNR (not LMSans) (AC-2 Task 1.2 \rmfamily guard)
# GREEN guard — catches a MISSING Task 1.2. Pre-impl: page-numbers are TNR (all TimesNewRomanPSMT). Post-impl:
#   if the dev adds \sffamily (Task 1.1) but FORGETS the \rmfamily leader guard (Task 1.2), the L1 page-number
#   digit renders LMSans (Latin Modern Sans) → this FAILs. Assert ALL page-number spans on the TOC page are TNR
#   (no LMSans). Pre-impl GREEN; post-impl GREEN iff Task 1.2 done.
test_l1_pagenum_tnr() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if toc is None:
    print('  (TOC page not found — RED)'); sys.exit(1)
fonts = pagenum_fonts(toc)
if not fonts:
    print('  (no page-number spans x>500 found — RED)'); sys.exit(1)
all_tnr = all('Times' in f for f in fonts)
any_lmsans = any('LMSans' in f for f in fonts)
print('  page-number fonts=%s all_tnr=%s any_lmsans=%s (Task 1.2 \\\\rmfamily guard — TNR, NOT LMSans)' %
      (fonts, all_tnr, any_lmsans))
sys.exit(0 if (all_tnr and not any_lmsans) else 1)
"
}
run_test "P1" "ATDD-3.5-I06" "BEHAVIOR: L1 page-number = TNR not LMSans (AC-2 Task 1.2 guard; GREEN — RED if Task 1.2 omitted)" test_l1_pagenum_tnr

# ATDD-3.5-I07: BEHAVIOR — L2 section entries SimSun 小四号 ~12pt at 2\ccwd (AC-3, TC-E3-25)
# GREEN guard (already correct: \titlecontents{section}[2\ccwd]{\vspace{6bp}\xiaosi[1]} → SimSun 12pt). Assert at
#   least one L2 entry, median size ≈12, and the entries are SimSun (Songti). Reference p10: SimSun 12.00pt.
test_l2_entries_simsun_xiaosi() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
ents = section_entries(toc)
if len(ents) < 1:
    print('  (no L2 section entries found — regression)'); sys.exit(1)
fonts = [e[0] for e in ents]; sizes = [e[1] for e in ents]
med = median(sizes)
song = all(('SimSun' in f or 'Song' in f or '宋' in f) for f in fonts)
print('  L2 entries=%d fonts=%s median size=%.2fpt song=%s (spec §2.6 宋体小四号; ref p10 SimSun 12.0)' %
      (len(ents), set(fonts), med, song))
sys.exit(0 if (song and 11.3 <= med <= 12.7) else 1)
"
}
run_test "P1" "ATDD-3.5-I07" "BEHAVIOR: L2 section entries SimSun 小四号 ~12pt (AC-3, TC-E3-25; GREEN — already correct)" test_l2_entries_simsun_xiaosi

# ATDD-3.5-I12: regression — self-check textheight ~688pt unchanged (AC-8, R-1)
# TOC formatting must NOT touch geometry.
test_textheight_unchanged() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local th
  th=$(grep 'textheight = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$th" ]]; then echo "  (textheight not found in self-check)"; return 1; fi
  echo "  (textheight: ${th}pt [expect ~688.56])"
  echo "$th" | awk '{if ($1 >= 686 && $1 <= 690) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.5-I12" "regression: self-check textheight unchanged ~688pt (AC-8, R-1)" test_textheight_unchanged

# ATDD-3.5-I13: regression — self-check baselineskip ≈ 18bp (AC-8 — TOC must not touch body spacing)
# The TOC \titlecontents before-args use their own size-macro baselineskip (\xiaosi[1] single); they do NOT touch
#   the body \baselinestretch. Assert the self-check still reads body 18bp.
test_baselineskip_18bp() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local bs
  bs=$(grep 'baselineskip = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$bs" ]]; then echo "  (baselineskip not found in self-check)"; return 1; fi
  echo "  (baselineskip: ${bs}pt, expect ~18.07 [body 18bp])"
  echo "$bs" | awk '{if ($1 >= 17.5 && $1 <= 19.0) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.5-I13" "regression: self-check baselineskip ~18bp (AC-8 — TOC must not touch body spacing)" test_baselineskip_18bp

# ATDD-3.5-I14: total pages ~51 ±5 (AC-8; TOC is one page pre- and post-impl — font change is in-place)
test_total_pages() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local total_pages
  total_pages=$(grep 'total pages = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | tr -d '[:space:]')
  if [[ -z "$total_pages" ]]; then echo "  (page count not found)"; return 1; fi
  echo "  (pages: $total_pages, expected ~51 ±5 [TOC stays 1 page — font change is in-place])"
  echo "$total_pages" | awk '{if ($1 >= 46 && $1 <= 56) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.5-I14" "total pages ~51 ±5 (AC-8; TOC stays 1 page — font change in-place)" test_total_pages

# ATDD-3.5-I15: regression — no fancyhdr headheight warning (AC-8, R-2)
test_no_headheight_warning() {
  if [[ -f "main.log" ]]; then
    ! grep -qi 'headheight.*too low\|fancyhdr.*headheight' main.log 2>/dev/null
  else
    return 1
  fi
}
run_test "P1" "ATDD-3.5-I15" "regression: no fancyhdr headheight warning (AC-8, R-2)" test_no_headheight_warning

echo ""

# ==========================================
# P2 Tests — indent / dot leaders / depth / L3 \wuhao-leak guard
# ==========================================
echo "=== P2: indent per level + dot leaders + depth + L3 \\wuhao-leak guard ==="

# ATDD-3.5-I08: BEHAVIOR — per-level indent ≈ 24pt (2\ccwd; AC-5, TC-E3-27)
# GREEN guard (AC-5 = VERIFY; story does NOT change indent). Measures the TRUE indent = label-start x0 delta
#   (N.N section label → N.N.N subsection label), NOT the title-text x0 delta (which is confounded by label-width
#   differences: L1 label 第N章 vs Latin 2.1/4.1.1). Reference PDF p10 = uniform +24.0pt/level (= 2\ccwd at 12pt).
#   PATCHED 2026-06-16 (code review): the original measured title-text x0 (91.9/121.9/150.4 → 30/28.5pt, a
#   measurement artifact); label-start is a clean 24.0pt/level matching the reference. Assert subsection_label_x0 −
#   section_label_x0 ≈ 24pt (the per-level indent, reference-independent) + section_label_x0 − margin ≈ 24pt.
test_indent_per_level() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if toc is None:
    print('  (TOC page not found — RED)'); sys.exit(1)
sec_lab = []; sub_lab = []; l1_edge = None
for b in doc[toc].get_text('dict').get('blocks', []):
    for ln in b.get('lines', []):
        for sp in ln.get('spans', []):
            tx = sp['text'].strip(); x0 = sp['bbox'][0]
            if re.fullmatch(r'\d+\.\d+', tx) and 11 <= sp['size'] <= 13:
                sec_lab.append(x0)                                  # section label-start (e.g. 2.1)
            elif re.fullmatch(r'\d+\.\d+\.\d+', tx) and 9 <= sp['size'] <= 13:
                sub_lab.append(x0)                                  # subsection label-start (e.g. 4.1.1)
            elif cjk_re.search(tx) and sp['size'] > 13 and len(tx) >= 2 and x0 < 100:
                if l1_edge is None or x0 < l1_edge:
                    l1_edge = x0                                    # chapter entry left edge (margin)
sec_x = median(sec_lab) if sec_lab else None
sub_x = median(sub_lab) if sub_lab else None
# Per-level delta (subsection − section) is the clean, reference-matching indent. If subsection labels are absent
# (a build with no L3), fall back to section − margin.
if sub_x is not None and sec_x is not None:
    delta = sub_x - sec_x; where = 'subsection-section'
elif sec_x is not None and l1_edge is not None:
    delta = sec_x - l1_edge; where = 'section-margin'
else:
    print('  (no N.N or N.N.N labels found to measure indent — L1=%s sec=%d sub=%d)' %
          (l1_edge, len(sec_lab), len(sub_lab))); sys.exit(1)
print('  l1_edge=%s sec_label_x0=%s sub_label_x0=%s | %s delta=%.1fpt (expect ≈24 = 2\\ccwd; ref p10 24/level)' %
      (l1_edge, sec_x, sub_x, where, delta))
sys.exit(0 if 22.0 <= delta <= 26.0 else 1)
"
}
run_test "P2" "ATDD-3.5-I08" "BEHAVIOR: per-level indent ≈ 24pt (label-start delta; AC-5, TC-E3-27; GREEN — PATCHED to measure true indent)" test_indent_per_level

# ATDD-3.5-I09: BEHAVIOR — dot leaders present (AC-6, TC-E3-26)
# GREEN guard. \titlerule*{.} produces a run of '.' spans between entry text and page number. Assert the TOC page
#   has dot-leader spans (a span containing a run of '.', len>=5). Pre-impl and post-impl both present.
test_dot_leaders() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if toc is None:
    print('  (TOC page not found — RED)'); sys.exit(1)
dots = 0
for b in doc[toc].get_text('dict').get('blocks', []):
    for ln in b.get('lines', []):
        for sp in ln.get('spans', []):
            tx = sp['text']
            if re.search(r'\.{5,}', tx):
                dots += 1
print('  dot-leader spans (>=5 dots) on TOC: %d (expect >=1)' % dots)
sys.exit(0 if dots >= 1 else 1)
"
}
run_test "P2" "ATDD-3.5-I09" "BEHAVIOR: dot leaders present (\\titlerule*{.}; AC-6, TC-E3-26; GREEN)" test_dot_leaders

# ATDD-3.5-I10: BEHAVIOR — tocdepth=2, no 4th-level N.N.N.N rows (AC-7, TC-E3-27)
# GREEN guard. \htu@tocdepth{2} = subsection (level 2). LaTeX numbering: chapter=N, section=N.N, subsection=N.N.N,
#   subsubsection=N.N.N.N (level 3, NOT shown at tocdepth=2). So tocdepth=2 shows N.N.N (subsection) and MUST NOT
#   show N.N.N.N (subsubsection). Assert no N.N.N.N labels. (N.N.N rows ARE expected — they are subsection.)
test_no_fourth_level() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if toc is None:
    print('  (TOC page not found — RED)'); sys.exit(1)
leak = []
for b in doc[toc].get_text('dict').get('blocks', []):
    for ln in b.get('lines', []):
        for sp in ln.get('spans', []):
            tx = sp['text'].strip()
            if re.fullmatch(r'\d+\.\d+\.\d+\.\d+', tx):   # N.N.N.N = subsubsection (level 3, beyond tocdepth=2)
                leak.append(tx)
print('  4th-level labels (N.N.N.N) found: %d %s (expect 0 — tocdepth=2 caps at subsection N.N.N)' % (len(leak), leak[:3]))
sys.exit(0 if len(leak) == 0 else 1)
"
}
run_test "P2" "ATDD-3.5-I10" "BEHAVIOR: tocdepth=2, no 4th-level N.N.N.N rows (AC-7, TC-E3-27; GREEN)" test_no_fourth_level

# ATDD-3.5-I11: BEHAVIOR — L3 subsection entries SimSun 小四号 ~12pt (AC-4, TC-E3-27) — THE FIX proof
# RED pre-impl (verified on baseline acb4e5b): the sample TOC DOES render L3 subsection rows (chap04 has non-starred
#   \subsection → N.N.N at tocdepth=2 — the create-story assumption of "no L3 row" was WRONG). They render SimSun
#   **10.5pt** (\wuhao[1] at cls:524), spec §2.6 + reference p10 require 小四号 12pt. Post-impl (Task 2.1
#   \wuhao→\xiaosi) → 12pt → GREEN. Assert median size ≈12 (NOT 10.5). AC-4 is directly behavior-testable (no
#   scratch depth-3 raise needed — supersedes story Dev Notes Task 2.2). Reference p10: SimSun 12.00pt.
test_l3_entries_simsun_xiaosi() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
ents = subsection_entries(toc)
if len(ents) < 1:
    print('  (no L3 subsection entries found — was expected pre-impl; if gone post-impl, investigate)'); sys.exit(1)
fonts = [e[0] for e in ents]; sizes = [e[1] for e in ents]
med = median(sizes)
song = all(('SimSun' in f or 'Song' in f or '宋' in f) for f in fonts)
print('  L3 entries=%d fonts=%s median size=%.2fpt song=%s (spec §2.6 宋体小四号; ref p10 SimSun 12.0)' %
      (len(ents), set(fonts), med, song))
for f, s, x, t in ents[:3]:
    print('    %r %.1fpt x0=%.1f | %s' % (f, s, x, t[:24]))
# AC-4: SimSun (Songti) AND size ≈12 (NOT 10.5 — the \wuhao pre-impl value).
sys.exit(0 if (song and 11.3 <= med <= 12.7) else 1)
"
}
run_test "P2" "ATDD-3.5-I11" "BEHAVIOR: L3 subsection entries SimSun 小四号 ~12pt (AC-4, TC-E3-27; RED pre-impl — 10.5pt \wuhao; L3 rows DO render)" test_l3_entries_simsun_xiaosi

# ATDD-3.5-I16: DIAGNOSTIC — TOC rendered layout for manual reference-overlay (visual-sampling #6)
# Records the rendered title/L1/L2 fonts+sizes+positions for manual comparison vs the reference thesis PDF p10.
# Does NOT hard pass/fail — exits 0 if the page was found (prints layout). The reference is the VISUAL truth
# (目录 SimHei 16pt; L1 SimHei 12pt; L2/L3 SimSun 12pt; +24pt/level indent; dot leaders).
test_toc_layout_diagnostic() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if toc is None:
    print('  (TOC page not found — RED pre-impl)'); sys.exit(1)
pg = doc[toc]
print('  TOC=p%d rendered layout (for manual reference-overlay vs p10):' % (toc+1))
ents = l1_entries(toc) + section_entries(toc)
for f, s, x, t in ents[:8]:
    print('    x0=%5.1f size=%.1fpt font=%r | %s' % (x, s, f, t[:40]))
print('  page-number fonts: %s' % pagenum_fonts(toc))
print('  reference p10: 目录 SimHei 15.95pt centered; L1(章) SimHei 12.0pt x0=70.8;')
print('                  L2(节) SimSun 12.0pt x0=94.8; L3(一、) SimSun 12.0pt x0=118.8; dot leaders present.')
sys.exit(0)
"
}
run_test "P2" "ATDD-3.5-I16" "DIAGNOSTIC: TOC rendered layout for reference-overlay (AC visual-sampling #6)" test_toc_layout_diagnostic

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
  echo "   RED (fail pre-impl): I05 (L1 entries SimHei 12pt — pre-impl SimSun 14pt),"
  echo "      I11 (L3 subsection entries SimSun 12pt — pre-impl 10.5pt \wuhao; L3 rows DO render in sample)."
  echo "   GREEN guards: I01-I03 (compile), I04 (title SimHei ~16pt), I06 (L1 page-number TNR — catches a"
  echo "      missing Task-1.2 \rmfamily), I07 (L2 SimSun 12pt), I08 (indent ≈24pt label-start delta),"
  echo "      I09 (dot leaders), I10 (no N.N.N.N 4th-level), I12 (textheight), I13 (baselineskip 18bp),"
  echo "      I14 (pages), I15 (no headheight). I16 = diagnostic (reference-overlay positions)."
  echo ""
  echo "   NOTE: the fitz behavior tests are the real AC proof — source-greps cannot prove rendered font/size."
  echo "         I05 (L1 SimHei 小四号) + I11 (L3 SimSun 小四号) are the two RED behaviors (the \sihao→\xiaosi+\sffamily"
  echo "         L1 fix + the \wuhao→\xiaosi L3 fix). I06 is the Task-1.2 \rmfamily guard (page-number stays TNR —"
  echo "         RED if the dev adds L1 \sffamily but omits the \rmfamily leader restore). RED-phase finding: the"
  echo "         sample TOC DOES render L3 subsection rows (chap04 non-starred \subsection) at 10.5pt → AC-4 is"
  echo "         directly behavior-testable (I11), NO scratch depth-3 raise needed (supersedes story Dev Notes 2.2)."
  echo "         R-17 = LOW risk (cosmetic); compile passes pre-impl → no P0 RED tests (I01-I03 GREEN compile gates)."
  echo "         Tests are read-only — they do not modify the SUT."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
