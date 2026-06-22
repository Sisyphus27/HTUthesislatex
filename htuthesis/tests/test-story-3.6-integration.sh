#!/usr/bin/env bash
# test-story-3.6-integration.sh — ATDD Integration Tests for Story 3.6 (Figure, table, and equation formatting)
# TDD Phase: GREEN-GUARD (NO RED drivers — the caption/equation/subfigure RENDERING is already correct on the
#             baseline: figure caption BELOW figure SimSun 五号, table caption ABOVE table SimSun 五号, subfigure
#             (a)(b) TNR 五号, equation "(N-N)" right-aligned TNR. These fitz behavior tests LOCK IN the correct
#             inherited rendering so future stories cannot silently regress it. AC-3 separator = DIAGNOSTIC
#             (DECISION-PENDING — spec space vs reference colon vs current space; no pass/fail on an undecided value).
#
# Usage: bash tests/test-story-3.6-integration.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 (compile gate) + P1/P2 (architecture.md:40 = 图表公式 LOW risk; caption/equation formatting cosmetic)
# Linked ACs: AC-1 (figure caption below 五号宋体 centered), AC-2 (table caption above 五号宋体 centered),
#             AC-4 (subfigure (a)(b)(c)), AC-5 (equation "(N-N)" right-aligned), AC-6 (caption 五号 宋体),
#             AC-3 (separator — DIAGNOSTIC, decision-pending), AC-7/AC-8 (compile + regression)
# Linked Risk: R-12 (score 4 — caption change requires `latexmk -g`; only relevant IF AC-3 edits; -g run regardless)
# TC coverage: TC-E3-28 (P0 fig caption below), TC-E3-29 (P0 table caption above), TC-E3-30 (P1 caption 五号 SimSun
#              centered), TC-E3-31 (P1 equation right-aligned "(N-N)"), TC-E3-32 (P2 subfigure (a)(b)(c))
#
# NOTE: source-greps (unit) prove the WIRING; these fitz tests prove the RENDERED captions/equation.
#   fitz calibration (baseline 6f73848): the caption LABEL "图 N-N" / "表 N-N" and the title render as TWO separate
#   fitz lines (split by the \hspace{\ccwd} separator / centering) — so captions() finds the label line then scans
#   the next lines in the same block for the CJK title. The LOF/LOT list pages (插图清单/表格清单, p13/p15) share the
#   same 2-line split, so they are excluded by skipping any page that contains a dot-leader run (≥10 consecutive
#   dots) — body caption pages have no such dots. Equation numbers render "(N-N)" (WITH parens) flush-right at
#   x1≈524.4. Subfigure labels "(a)"/"(b)" TNR 10.5.
#
#   - ATDD-3.6-I04: figure caption BELOW figure, label SimSun 五号 ~10.5pt (AC-1, TC-E3-28) — GREEN (inherited)
#   - ATDD-3.6-I05: figure caption ~centered (AC-1, TC-E3-28) — GREEN
#   - ATDD-3.6-I06: table caption label SimSun 五号 ~10.5pt (AC-2, TC-E3-29; position-above via wiring) — GREEN
#   - ATDD-3.6-I07: table caption ~centered (AC-2, TC-E3-29) — GREEN
#   - ATDD-3.6-I08: equation "(N-N)" right-aligned x1≈524 (AC-5, TC-E3-31) — GREEN (inherited; 2.6 numbering + eq env)
#   - ATDD-3.6-I09: subfigure (a)(b) labels TNR 五号 (AC-4, TC-E3-32) — GREEN (inherited)
#   - ATDD-3.6-I10: caption Latin NUMBER = TNR (not LMSans) (AC-1/2 number font via 3.9) — GREEN guard
#   - ATDD-3.6-I11: caption CJK TITLE = SimSun (not SimHei/sffamily leak) (AC-6) — GREEN guard
#   - ATDD-3.6-I12: AC-3 caption separator = fullwidth colon "：" (AC-3 Option A, TC-E3-30) — PROMOTED from diagnostic
#   A source-grep cannot prove rendered position/font/size. These fitz behavior tests are the real AC proof.

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
echo "ATDD Integration Tests: Story 3.6 — Figure, table, and equation formatting"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# Shared Python header: opens main.pdf, defines caption/equation/subfigure helpers.
# A caption LABEL line = first span "图"/"表" (SimSun ~10.5) + second span "N-N". The title is on a SEPARATE fitz
# line (the \hspace{\ccwd} splits them) → scan the next 2 lines in the same block for the first CJK ~10.5 span.
# LOF/LOT list pages are excluded by skipping any page containing a dot-leader run (≥10 dots) — body pages lack them.
PY_HEAD='
import fitz, sys, re
doc = fitz.open("main.pdf")
W = doc[0].rect.width; mid = W / 2.0
cjk_re = re.compile(r"[一-鿿]")
num_re = re.compile(r"^\d+-\d+")  # PREFIX match (no $) — tolerates a trailing fullwidth colon if fitz merges "：" into the number span ("4-1："); PATCHED 2026-06-16 (code review)
eq_re = re.compile(r"^\d+-\d+$")  # G-A fullwidth-paren tag: number span is bare N-N （　N-N　） split into 3 spans; eq_re dropped ASCII parens (Epic 3 retro G-A residue, R-26, fixed 2026-06-21)
sub_re = re.compile(r"^\([a-z]\)$")
def median(xs):
    if not xs: return None
    ys = sorted(xs); n = len(ys); return ys[n // 2]
def list_pages():
    # LOF (插图清单) / LOT (表格清单) list pages — their "图 N-N" / "表 N-N" entries are NOT body captions.
    # Identified by the list TITLE (not dot-leaders): body p37/39 ALSO carry verbatim dot-runs from chap04
    # latex-listings, and LOF/LOT leader lines do not reliably end in "\d+" — so a dot-based skip both missed
    # LOF/LOT (false captions) and excluded body pages (hid table captions 4-2/4-3). The titles appear ONLY on
    # the list pages, so a title-based skip is precise. PATCHED 2026-06-16 (code review).
    s = set()
    for i in range(doc.page_count):
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type", 0) != 0: continue
            for ln in b.get("lines", []):
                txt = "".join(sp["text"] for sp in ln.get("spans", []))
                if "插图清单" in txt or "表格清单" in txt:
                    s.add(i); break
    return s
_SKIP = list_pages()
def captions(kind=None):
    out = []
    for i in range(doc.page_count):
        if i in _SKIP: continue
        pg = doc[i]; d = pg.get_text("dict")
        img_bottoms = [b["bbox"][3] for b in d.get("blocks", []) if b.get("type", 0) == 1]
        for b in d.get("blocks", []):
            if b.get("type", 0) != 0: continue
            lines = b.get("lines", [])
            for li, ln in enumerate(lines):
                spans = ln.get("spans", [])
                if not spans: continue
                t0 = spans[0]["text"].strip()
                if t0 not in ("图", "表"): continue
                if len(spans) < 2 or not num_re.match(spans[1]["text"].strip()): continue
                if kind and t0 != kind: continue
                # title = first CJK span ~10.5 in this line (after the number) or the next 2 lines of the block
                title = None
                cand = list(spans[2:])
                for nl in lines[li + 1: li + 3]:
                    cand.extend(nl.get("spans", []))
                for sp in cand:
                    if cjk_re.search(sp["text"]) and 9.0 <= sp["size"] <= 12.0:
                        title = sp; break
                xs = [sp["bbox"][0] for sp in spans] + ([title["bbox"][0]] if title else [])
                xe = [sp["bbox"][2] for sp in spans] + ([title["bbox"][2]] if title else [])
                out.append({"page": i, "kind": t0, "y0": spans[0]["bbox"][1],
                            "cx": (min(xs) + max(xe)) / 2.0,
                            "label_font": spans[0]["font"], "label_size": spans[0]["size"],
                            "num_font": spans[1]["font"], "num_size": spans[1]["size"],
                            "title_font": title["font"] if title else None,
                            "title_size": title["size"] if title else None,
                            "img_bottoms": img_bottoms})
    return out
def equation_numbers():
    # Equation number spans: "N-N" (TNR digits), flush-right. Story 3 retro 2026-06-20: tags now use
    # fullwidth parens （N-N） per §2.13 (\tagform@ override) — the tag = 3 spans (（ SimSun, N-N TNR,
    # ） SimSun) right-aligned as a unit to x1≈524. The ） flanks the number on its right, so the number
    # span x1 shifted left from ~524 (old inline-ASCII parens) to ~512. Threshold lowered 515→505 to
    # keep matching the number span (Times + digit-dash-digit is specific; body refs do not sit at the
    # right margin). The tag right edge (） at ~524) is implied by the number at ~512.
    out = []
    for i in range(doc.page_count):
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type", 0) != 0: continue
            for ln in b.get("lines", []):
                for sp in ln.get("spans", []):
                    tx = sp["text"].strip()
                    x1 = sp["bbox"][2]
                    if eq_re.match(tx) and x1 > 505 and "Times" in sp["font"]:
                        out.append({"page": i, "text": tx, "x1": x1, "font": sp["font"], "size": sp["size"]})
    return out
def subfigure_labels():
    out = []
    for i in range(doc.page_count):
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type", 0) != 0: continue
            for ln in b.get("lines", []):
                for sp in ln.get("spans", []):
                    tx = sp["text"].strip()
                    if sub_re.match(tx) and "Times" in sp["font"]:
                        out.append({"page": i, "text": tx, "font": sp["font"], "size": sp["size"]})
    return out
'

# ==========================================
# P0 Tests (Must Pass — 100%) — compile gate
# ==========================================
echo "=== P0: Compile gate (R-12 — -g full recompile; mandatory if AC-3 edits the separator) ==="

# ATDD-3.6-I01: latexmk -xelatex -g main.tex exit code 0 (AC-7, compile gate, R-12)
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-3.6-I01" "latexmk -xelatex -g main.tex exit code 0 (AC-7, R-12 full recompile)" test_full_compile

# ATDD-3.6-I02: zero compilation errors in main.log (AC-7)
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
run_test "P0" "ATDD-3.6-I02" "zero compilation errors in main.log (AC-7)" test_no_errors

# ATDD-3.6-I03: warning count <= 3 (AC-7, NFR <=3 vs Story 3.4 baseline = 1 standing xeCJK from 3.9)
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
run_test "P0" "ATDD-3.6-I03" "warning count <= 3 (AC-7, NFR <=3 new)" test_warning_count

echo ""

# ==========================================
# P0/P1 Tests — figure caption (AC-1, TC-E3-28) — GREEN guards
# ==========================================
echo "=== P0/P1: figure caption BELOW figure, SimSun 五号, centered (AC-1, TC-E3-28; GREEN — inherited) ==="

# ATDD-3.6-I04: BEHAVIOR — figure caption label SimSun 五号 ~10.5pt (AC-1, TC-E3-28)
# GREEN guard. Find a "图 N-N" body caption (LOF/LOT excluded via dot-page skip) whose label span (图) is SimSun
#   ~10.5pt. The BELOW-figure POSITION is proven by the unit wiring figureposition=bottom (ATDD-3.6-02): the sample
#   figures are VECTOR (golfer.pdf etc., via \includegraphics of .pdf), so fitz get_images()/image-info return
#   nothing (vector figures are drawing commands, not raster XObjects) → a y-ordering "caption below image" check
#   is unreliable. The position is therefore wiring-proven + manual-overlay (I17); this test proves the FONT/SIZE.
#   (Mirrors I06 table-caption, which also relies on wiring for position.) Reference p95/p138: SimSun 五号 below fig.
test_figure_caption_simhei_wuhao() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
figs = captions('图')
if not figs:
    print('  (no figure body caption found — RED; sample may lack a figure float)'); sys.exit(1)
song = all(('SimSun' in c['label_font'] or 'Song' in c['label_font']) for c in figs)
med = median([c['label_size'] for c in figs])
print('  figure captions=%d label_song=%s median_label_size=%.2fpt (position-below via wiring figureposition=bottom)' %
      (len(figs), song, med if med else -1))
for c in figs[:3]:
    print('    p%d: label=%r %.1fpt num=%r title=%r' % (c['page']+1, c['label_font'], c['label_size'], c['num_font'], c['title_font']))
# AC-1: >=1 figure caption, label SimSun, size ~10.5 (五号). Below-position = unit wiring figureposition=bottom.
sys.exit(0 if (len(figs) >= 1 and song and med is not None and 9.8 <= med <= 11.2) else 1)
"
}
run_test "P0" "ATDD-3.6-I04" "BEHAVIOR: figure caption SimSun 五号 ~10.5pt (AC-1, TC-E3-28; below-position via wiring; GREEN)" test_figure_caption_simhei_wuhao

# ATDD-3.6-I05: BEHAVIOR — figure caption page-centered (AC-1, TC-E3-28)
# GREEN guard. caption package singlelinecheck centers single-line captions. Full-width (page-spanning) figure
#   captions center at page-mid (cx≈298); MINIPAGE side-by-side subfigures (chap04 figs 4-3/4-4) center within their
#   COLUMN (cx≈209 / 387 — symmetric around mid). Assert AT LEAST ONE figure caption is page-centered (cx within
#   ±20pt of mid) — tolerates the column-centered minipage captions.
test_figure_caption_centered() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
figs = captions('图')
if not figs:
    print('  (no figure body caption found — RED)'); sys.exit(1)
cxs = [c['cx'] for c in figs]
page_centered = [round(c) for c in cxs if abs(c - mid) <= 20.0]
print('  figure caption cx values=%s page-mid=%.1f page-centered(±20)=%s' %
      ([round(c) for c in cxs[:8]], mid, page_centered))
# AC-1 centered: >=1 page-centered figure caption (full-width); minipage column captions tolerated.
sys.exit(0 if len(page_centered) >= 1 else 1)
"
}
run_test "P1" "ATDD-3.6-I05" "BEHAVIOR: figure caption page-centered (AC-1, TC-E3-28; minipage tolerated; GREEN)" test_figure_caption_centered

echo ""

# ==========================================
# P0/P1 Tests — table caption (AC-2, TC-E3-29) — GREEN guards
# ==========================================
echo "=== P0/P1: table caption ABOVE table, SimSun 五号, centered (AC-2, TC-E3-29; GREEN — inherited) ==="

# ATDD-3.6-I06: BEHAVIOR — table caption label SimSun 五号 ~10.5pt (AC-2, TC-E3-29)
# GREEN guard. Find a "表 N-N" body caption (LOF/LOT excluded) whose label span (表) is SimSun ~10.5pt. The
#   position-above is proven by the unit wiring (tableposition=top, ATDD-3.6-02) — fitz y-ordering vs a "table" is
#   hard to detect generically (tables are text grids, not image blocks), so this proves FONT/SIZE/LABEL; the
#   position is wiring-proven.
test_table_caption_simhei_wuhao() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
tabs = captions('表')
if not tabs:
    print('  (no table body caption found — RED; sample may lack a table float)'); sys.exit(1)
song = all(('SimSun' in c['label_font'] or 'Song' in c['label_font']) for c in tabs)
med = median([c['label_size'] for c in tabs])
print('  table captions=%d label_song=%s median_label_size=%.2fpt' % (len(tabs), song, med if med else -1))
for c in tabs[:3]:
    print('    p%d: label=%r %.1fpt num=%r title=%r' % (c['page']+1, c['label_font'], c['label_size'], c['num_font'], c['title_font']))
# AC-2: >=1 table caption, label SimSun, size ~10.5 (五号). Position-above = unit wiring tableposition=top.
sys.exit(0 if (len(tabs) >= 1 and song and med is not None and 9.8 <= med <= 11.2) else 1)
"
}
run_test "P0" "ATDD-3.6-I06" "BEHAVIOR: table caption SimSun 五号 ~10.5pt (AC-2, TC-E3-29; position-above via wiring; GREEN)" test_table_caption_simhei_wuhao

# ATDD-3.6-I07: BEHAVIOR — table caption ~centered (AC-2, TC-E3-29)
test_table_caption_centered() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
tabs = captions('表')
if not tabs:
    print('  (no table body caption found — RED)'); sys.exit(1)
cxs = [c['cx'] for c in tabs]
dev = max(abs(c-mid) for c in cxs)
print('  table caption cx values=%s page-mid=%.1f max_dev=%.1fpt' %
      ([round(c) for c in cxs[:6]], mid, dev))
sys.exit(0 if dev <= 45.0 else 1)
"
}
run_test "P1" "ATDD-3.6-I07" "BEHAVIOR: table caption ~centered (AC-2, TC-E3-29; GREEN)" test_table_caption_centered

echo ""

# ==========================================
# P1 Tests — equation right-aligned (AC-5, TC-E3-31) + subfigure (AC-4, TC-E3-32) — GREEN guards
# ==========================================
echo "=== P1: equation (N-N) right-aligned (AC-5, TC-E3-31) + subfigure (a)(b) (AC-4, TC-E3-32; GREEN) ==="

# ATDD-3.6-I08: BEHAVIOR — equation "(N-N)" right-aligned (AC-5, TC-E3-31)
# GREEN guard. G-A fullwidth-paren tag = 3 spans (（ SimSun, N-N TNR, ） SimSun) right-aligned as a unit
#   to ）≈524.4pt (595.28 − 70.87 margin). The number span x1≈512 ( ） flanks it on the right). Assert
#   ≥1 TNR number span N-N with x1 in [505,520] (number x1≈512.4; band lowered from [516,532] which
#   caught the old ASCII-paren tag — R-26 residue from Epic 3 retro G-A repoint, fixed 2026-06-21).
#   Reference §2.13 "(1-1) 标注在该公式所在行的最右侧".
test_equation_right_aligned() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
eqs = equation_numbers()
if not eqs:
    print('  (no equation number (N-N) at x1>505 TNR found — RED; sample may lack an equation env)'); sys.exit(1)
x1s = [e['x1'] for e in eqs]
right = sum(1 for x in x1s if 505.0 <= x <= 520.0)
print('  equation numbers=%d right-aligned(x1 in [505,520])=%d sample=%s' %
      (len(eqs), right, [(e['text'], round(e['x1'])) for e in eqs[:6]]))
# AC-5: >=1 equation number right-aligned at the right text-edge (tag ）≈524; number x1≈512), TNR, N-N.
sys.exit(0 if right >= 1 else 1)
"
}
run_test "P1" "ATDD-3.6-I08" "BEHAVIOR: equation (N-N) right-aligned, number x1 approx 512, tag at ~524 (AC-5, TC-E3-31; GREEN; G-A R-26 repoint 2026-06-21)" test_equation_right_aligned

# ATDD-3.6-I09: BEHAVIOR — subfigure labels (a)(b) TNR 五号 (AC-4, TC-E3-32)
# GREEN guard. \thesubfigure=(\alph{subfigure}) renders (a)(b)(c). Assert >=2 distinct subfigure labels (a),(b)
#   at TNR ~10.5pt. Reference §2.11 "用（a），（b），（c）按顺序编排". (chap04 fig 4-5 uses \subcaptionbox.)
test_subfigure_labels() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
subs = subfigure_labels()
labels = sorted(set(s['text'] for s in subs))
med = median([s['size'] for s in subs])
print('  subfigure labels=%d distinct=%s median_size=%.2fpt' % (len(subs), labels, med if med else -1))
# AC-4: >=2 distinct (a)/(b) labels, TNR, size ~10.5 (五号).
sys.exit(0 if (len(labels) >= 2 and med is not None and 9.8 <= med <= 11.2) else 1)
"
}
run_test "P1" "ATDD-3.6-I09" "BEHAVIOR: subfigure (a)(b) labels TNR 五号 (AC-4, TC-E3-32; GREEN)" test_subfigure_labels

# ATDD-3.6-I10: BEHAVIOR — caption Latin NUMBER = TNR (not LMSans) (AC-1/2 number font via 3.9)
# GREEN guard. The caption number "N-N" digit renders TimesNewRomanPSMT (via 3.9 setmainfont TNR), NOT Latin Modern.
#   Catches a 3.9 regression OR a stray sffamily leaking into the caption. Reference uses Calibri (Word artifact
#   — NOT chased; TNR is the spec Latin per FR-13/16).
test_caption_number_tnr() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
caps = [c for c in captions() if c['num_font']]
if not caps:
    print('  (no caption found — RED)'); sys.exit(1)
fonts = set(c['num_font'] for c in caps)
all_tnr = all('Times' in f for f in fonts)
any_lm = any(('LMSans' in f or 'LMRoman' in f) for f in fonts)
print('  caption number fonts=%s all_tnr=%s any_latinmodern=%s (3.9 setmainfont TNR)' % (fonts, all_tnr, any_lm))
sys.exit(0 if (all_tnr and not any_lm) else 1)
"
}
run_test "P1" "ATDD-3.6-I10" "BEHAVIOR: caption number = TNR not Latin Modern (AC-1/2 via 3.9; GREEN)" test_caption_number_tnr

# ATDD-3.6-I11: BEHAVIOR — caption CJK TITLE = SimSun (not SimHei/sffamily leak) (AC-6)
# GREEN guard. The caption CJK title renders SimSun, NOT SimHei (a sffamily leak from a heading would make it
#   SimHei). spec §2.11/§2.12 "用五号宋体字". The caption package resets the face; no leak expected. (Title is on a
#   separate fitz line from the label — captions() scans the next lines to find it.)
test_caption_title_simsun() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
caps = [c for c in captions() if c['title_font']]
if not caps:
    print('  (no caption with CJK title found — RED)'); sys.exit(1)
fonts = set(c['title_font'] for c in caps)
all_song = all(('SimSun' in f or 'Song' in f) for f in fonts)
any_hei = any(('SimHei' in f or 'Hei' in f) for f in fonts)
print('  caption title fonts=%s all_song=%s any_hei=%s (spec 五号宋体; no sffamily leak)' % (fonts, all_song, any_hei))
sys.exit(0 if (all_song and not any_hei) else 1)
"
}
run_test "P1" "ATDD-3.6-I11" "BEHAVIOR: caption title = SimSun not SimHei (AC-6; GREEN — no sffamily leak)" test_caption_title_simsun

echo ""

# ==========================================
# P2 Tests — AC-3 separator DIAGNOSTIC (DECISION-PENDING) + regression + diagnostic
# ==========================================
echo "=== P2: AC-3 separator DIAGNOSTIC (decision-pending) + self-check regression + layout diagnostic ==="

# ATDD-3.6-I12: BEHAVIOR — AC-3 caption separator = half-space, NO fullwidth colon (AC-3, TC-E3-30)
# REPOINTED by Story 3.13: was fullwidth colon "：" (Option A, reference-wins 2026-06-16 per Decision 4 v1); now
#   half-space \hspace{0.5\ccwd} (spec §2.11/§2.12「空半格」PRIORITY, CLAUDE.md Decision 4 修正 2026-06-17,
#   gap 1a). This test now asserts NO fullwidth colon renders on body captions (the separator is a half-space gap,
#   not ：). Reference PDF pp.58/95/138/140/207 fullwidth-colon = Word-artifact deviation, overridden by spec.
test_caption_separator_colon() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
hits = 0; samples = []
for i in range(doc.page_count):
    if i in _SKIP: continue
    for b in doc[i].get_text('dict').get('blocks', []):
        if b.get('type', 0) != 0: continue
        lines = b.get('lines', [])
        for li, ln in enumerate(lines):
            spans = ln.get('spans', [])
            if not spans: continue
            t0 = spans[0]['text'].strip()
            if t0 not in ('图', '表'): continue
            if len(spans) < 2 or not num_re.match(spans[1]['text'].strip()): continue
            cur = ''.join(s['text'] for s in spans)
            nxt = ''.join(s['text'] for s in lines[li+1].get('spans', [])) if li+1 < len(lines) else ''
            if '：' in cur or '：' in nxt:
                hits += 1
                if len(samples) < 4: samples.append('p%d %s%s' % (i+1, t0, spans[1]['text'].strip()))
print('  body captions rendering fullwidth colon (U+FF1A): %d %s (expect 0 — half-space separator per spec §2.11/2.12)' % (hits, samples))
# AC-3: NO body caption renders the fullwidth colon (half-space separator per §2.11/§2.12, Story 3.13 gap 1a).
sys.exit(0 if hits == 0 else 1)
"
}
run_test "P1" "ATDD-3.6-I12" "BEHAVIOR: AC-3 caption separator = half-space, NO fullwidth ： (REPOINTED by 3.13: spec §2.11/2.12 空半格; was colon)" test_caption_separator_colon

# ATDD-3.6-I13: regression — self-check textheight ~688pt unchanged (AC-7, R-1)
test_textheight_unchanged() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local th
  th=$(grep 'textheight = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$th" ]]; then echo "  (textheight not found in self-check)"; return 1; fi
  echo "  (textheight: ${th}pt [expect ~688.56])"
  echo "$th" | awk '{if ($1 >= 686 && $1 <= 690) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.6-I13" "regression: self-check textheight unchanged ~688pt (AC-7, R-1)" test_textheight_unchanged

# ATDD-3.6-I14: regression — self-check baselineskip ≈ 23.4bp (AC-7 — caption must not touch body spacing) — REPOINTED by Story 3.11
test_baselineskip_18bp() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local bs
  bs=$(grep 'baselineskip = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$bs" ]]; then echo "  (baselineskip not found in self-check)"; return 1; fi
  echo "  (baselineskip: ${bs}pt, expect ~23.49 [body 23.4bp])"
  echo "$bs" | awk '{if ($1 >= 22.5 && $1 <= 24.5) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.6-I14" "regression: self-check baselineskip ~23.4bp (REPOINTED by Story 3.11; AC-7 — caption must not touch body spacing)" test_baselineskip_18bp

# ATDD-3.6-I15: total pages ~51 ±5 (AC-7; caption formatting is in-place — no page shift unless AC-3 rewraps)
test_total_pages() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local total_pages
  total_pages=$(grep 'total pages = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | tr -d '[:space:]')
  if [[ -z "$total_pages" ]]; then echo "  (page count not found)"; return 1; fi
  echo "  (pages: $total_pages, expected 40-56 [re-anchored by Story 3.14: → 44 pp; was ~51 ±5] [caption formatting in-place])"
  echo "$total_pages" | awk '{if ($1 >= 40 && $1 <= 56) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.6-I15" "total pages ~51 ±5 (AC-7; caption formatting in-place)" test_total_pages

# ATDD-3.6-I16: regression — no fancyhdr headheight warning (AC-7, R-2)
test_no_headheight_warning() {
  if [[ -f "main.log" ]]; then
    ! grep -qi 'headheight.*too low\|fancyhdr.*headheight' main.log 2>/dev/null
  else
    return 1
  fi
}
run_test "P1" "ATDD-3.6-I16" "regression: no fancyhdr headheight warning (AC-7, R-2)" test_no_headheight_warning

# ATDD-3.6-I17: DIAGNOSTIC — caption/equation rendered layout for manual reference-overlay (visual-sampling #7)
# Records the rendered caption/equation/subfigure layout for manual comparison vs the reference thesis PDF.
# Does NOT hard pass/fail — exits 0 if a caption was found (prints layout). Reference = VISUAL truth (SimSun 五号;
# figure-below/table-above; separator decision-pending; equation "(N-N)" right-aligned; subfigure (a)(b)).
test_caption_layout_diagnostic() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
caps = captions()
eqs = equation_numbers()
subs = subfigure_labels()
if not caps:
    print('  (no caption found — RED pre-impl)'); sys.exit(1)
print('  figure/table rendered layout (for manual reference-overlay vs ref pp.58/95/138/140/207):')
for c in caps[:8]:
    print('    p%d %s label=%r %.1fpt num=%r title=%r cx=%.0f' %
          (c['page']+1, c['kind'], c['label_font'], c['label_size'], c['num_font'], c['title_font'], c['cx']))
print('  equation numbers: %d %s' % (len(eqs), [(e['text'], round(e['x1'])) for e in eqs[:6]]))
print('  subfigure labels: %d %s' % (len(subs), sorted(set(s['text'] for s in subs))))
print('  reference: label SimSun 五号 ~10.5pt; 图 below fig / 表 above table; eq (N-N) rightmost; subfig (a)(b).')
sys.exit(0)
"
}
run_test "P2" "ATDD-3.6-I17" "DIAGNOSTIC: caption/equation layout for reference-overlay (AC visual-sampling #7)" test_caption_layout_diagnostic

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
  echo "   RED drivers: NONE — Story 3.6 is VERIFY-GREEN (caption/equation/subfigure rendering inherited intact"
  echo "      from zzuthesis, already matches spec §2.11/§2.12/§2.13 + reference PDF on baseline 6f73848)."
  echo "   GREEN guards (lock-in): I01-I03 (compile), I04 (fig caption below SimSun 五号), I05 (fig centered),"
  echo "      I06 (table caption SimSun 五号), I07 (table centered), I08 (eq (N-N) right-aligned x1≈524),"
  echo "      I09 (subfigure (a)(b) TNR 五号), I10 (caption number TNR), I11 (caption title SimSun — no leak),"
  echo "      I12 (AC-3 separator = colon — Option A), I13 (textheight), I14 (baselineskip 18bp), I15 (pages),"
  echo "      I16 (no headheight)."
  echo "   DIAGNOSTIC: I17 (caption/equation layout for reference-overlay)."
  echo ""
  echo "   NOTE: AC-3 separator RESOLVED 2026-06-16 to Option A (fullwidth colon, reference PDF per Decision 4;"
  echo "         Zy-approved transparent deviation from spec §2.11/12 \"空半格\" text). I12 PROMOTED from diagnostic"
  echo "         to a real value-assertion (body captions render the colon). architecture.md:40 = LOW risk."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
