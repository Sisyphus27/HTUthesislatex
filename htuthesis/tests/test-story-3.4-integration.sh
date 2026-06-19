#!/usr/bin/env bash
# test-story-3.4-integration.sh — ATDD Red-Phase Integration Tests for Story 3.4 (abstract formatting)
# TDD Phase: RED (English-title/body/keyword behavior tests FAIL on pre-impl; Chinese-side + compile +
#             self-check regression guards pass). The English abstract is where the defects live.
#
# Usage: bash tests/test-story-3.4-integration.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 tests are blocking
# Linked ACs: AC-1 (Ch title), AC-2 (Ch body), AC-3 (Ch keywords), AC-4 (En title ABSTRACT TNR Bold),
#             AC-5 (En body 五号 TNR ~23.4bp — R-14), AC-6 (En keywords comma + non-bold), AC-8 (compile+regression),
#             AC-9 (cross-story: 3.4 closes 3.9's deferred LMSans gap)
# Linked Risk: R-14 (score 6, English-abstract independent baselineskip ~23.4bp — THE dominant risk),
#              R-3 (baselineskip leak into self-check), R-12 (.aux staleness — -g full recompile)
# TC coverage: TC-E3-18 (P0 Ch title), TC-E3-19 (P1 Ch body), TC-E3-20 (P1 Ch keywords),
#              TC-E3-21 (P0 En title), TC-E3-22 (P0 En body baselineskip ~23.4bp — R-14), TC-E3-23 (P1 En keywords)
#
# NOTE: source-greps (unit) prove the WIRING; these fitz tests prove the RENDERED abstract pages:
#   - ATDD-3.4-I04: English title "ABSTRACT" TNR Bold ~16pt centered (AC-4, TC-E3-21) — RED pre-impl (LMSans "Abstract")
#   - ATDD-3.4-I05: English body ASCII spans median size ≈ 五号 10.5pt (AC-5) — RED pre-impl (inherits 12pt)
#   - ATDD-3.4-I06: English body line-gap ≈ 23.4bp (R-14 — NOT 18bp body, NOT 25.2bp trap) — RED pre-impl (18bp)
#   - ATDD-3.4-I07: English keyword separator = half-width comma (AC-6, TC-E3-23) — RED pre-impl ("; ")
#   - ATDD-3.4-I08: English KEY WORDS label NON-bold (AC-6, user decision) — RED pre-impl (\textbf bold)
#   - ATDD-3.4-I09/I10/I11: Chinese title/body/keywords SimHei/SimSun (AC-1/2/3) — GREEN guards (already correct)
#   - ATDD-3.4-I16: English abstract page 0 LMSans + 0 LMRoman (AC-9 — closes 3.9's deferred gap) — RED pre-impl
#   A source-grep cannot prove rendered font/size/line-gap (a \fontsize/\setmainfont override could evade it).
#   These fitz behavior tests are the real AC proof (Story 2.5/2.6/3.1/3.2/3.9 behavior-test lesson).
#
# fitz calibration notes (verified pre-impl on main.pdf at baseline 227362f):
#   - Post-3.9, \rmfamily Latin = TNR. The English abstract BODY is already TNR (just at the wrong size 12pt + wrong
#     baselineskip 18bp, inheriting the body). The English TITLE "Abstract" routes through \sffamily → LMSans.
#   - Chinese abstract (page with "关键词"): title "摘 要" SimHei ~16pt; body SimSun ~12pt; keyword label SimHei ~12pt.
#   - English abstract (page with "KEY WORDS"): title LMSans ~16pt; body TNR ~12pt (pre) → ~10.5pt (post); keyword
#     separator "; " (pre) → ", " (post); KEY WORDS label BoldMT (pre) → PSMT non-bold (post).
#   - R-14 target ~23.4bp = Word "2倍行距" (2×natural-line-height ~11.7), NOT 2×10.5=21 (architecture.md:151
#     assumption, transparently superseded by the reference-PDF measurement — user-confirmed 2026-06-16).

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
echo "ATDD Integration Tests: Story 3.4 — Chinese and English abstract formatting"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# Shared Python header: opens main.pdf, finds the Ch/En abstract pages, defines font + line-gap helpers.
PY_HEAD='
import fitz, sys, re
doc = fitz.open("main.pdf")
W = doc[0].rect.width; mid = W / 2.0
ascii_re = re.compile(r"[A-Za-z0-9]")
cjk_re = re.compile(r"[一-鿿]")
# Chinese abstract page = first page containing the Chinese keyword label "关键词".
ch_abs = None
for i in range(doc.page_count):
    if "关键词" in doc[i].get_text():
        ch_abs = i; break
# English abstract page = first page containing the uppercase keyword label "KEY WORDS".
en_abs = None
for i in range(doc.page_count):
    if "KEY WORDS" in doc[i].get_text():
        en_abs = i; break
def mm(v): return v / 72.0 * 25.4
def classify_font(fn):
    # 3.4-specific: distinguish LMRoman (\rmfamily defect, closed by 3.9), LMSans (\sffamily Latin — the
    # English-title gap 3.4 closes), TNR, and other (CJK/math). 3.9 treated LMSans as "other"; 3.4 needs it.
    if "LMRoman" in fn: return "lm_roman"
    if "LMSans" in fn: return "lm_sans"
    if "Times" in fn: return "tnr"
    return "other"
def en_body_lines(idx):
    # ASCII-letter body lines, max-size in [9,13]pt (五号 10.5 post-impl OR body 12 pre-impl); excludes the
    # title (>14pt) and footer/header. Returns sorted list of (y0, size).
    if idx is None: return []
    pg = doc[idx]; out = []
    for b in pg.get_text("dict").get("blocks", []):
        if b.get("type", 0) != 0: continue
        for ln in b.get("lines", []):
            spans = ln.get("spans", [])
            if not spans: continue
            txt = "".join(s["text"] for s in spans)
            ms = max(s["size"] for s in spans)
            if 9 <= ms <= 13 and re.search(r"[A-Za-z]", txt):
                y0 = min(s["bbox"][1] for s in spans)
                out.append((y0, ms))
    out.sort(); return out
def median(xs):
    if not xs: return None
    ys = sorted(xs); n = len(ys); return ys[n // 2]
'

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Compile + English title/body behavior (TC-E3-21, TC-E3-22, R-14) ==="

# ATDD-3.4-I01: latexmk -xelatex -g main.tex exit code 0 (AC-8, compile gate, R-12 full recompile)
# The English-abstract font/spacing + textual changes alter text metrics → -g (force) full recompile.
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-3.4-I01" "latexmk -xelatex main.tex exit code 0 (AC-8, R-12 full recompile)" test_full_compile

# ATDD-3.4-I02: zero compilation errors in main.log (AC-8)
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
run_test "P0" "ATDD-3.4-I02" "zero compilation errors in main.log (AC-8)" test_no_errors

# ATDD-3.4-I03: warning count <= 3 (AC-8, NFR <=3 new vs Story 3.3 baseline = 1 standing xeCJK)
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
run_test "P0" "ATDD-3.4-I03" "warning count <= 3 (AC-8, NFR <=3 new)" test_warning_count

# ATDD-3.4-I04: BEHAVIOR — English title "ABSTRACT" TNR Bold ~16pt centered (AC-4, TC-E3-21)
# Find the title span (case-insensitive ABSTRACT/Abstract, size>14). Pre-impl: "Abstract" via \sffamily → LMSans
#   (no "Times", no "Bold"). Post-impl: "ABSTRACT" \rmfamily\bfseries → TNR Bold. Assert font has "Times" AND
#   "Bold" (RED driver); centering + size are GREEN both. THE AC-4 PROOF.
test_english_title_tnr_bold() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if en_abs is None:
    print('  (English abstract page not found)'); sys.exit(1)
title = None
for b in doc[en_abs].get_text('dict').get('blocks', []):
    for ln in b.get('lines', []):
        for sp in ln.get('spans', []):
            if re.fullmatch(r'ABSTRACT|Abstract', sp['text'].strip(), re.I) and sp['size'] > 14:
                title = sp; break
if title is None:
    print('  (title span ABSTRACT/Abstract size>14 NOT found — RED)'); sys.exit(1)
fn = title['font']; cx = (title['bbox'][0] + title['bbox'][2]) / 2.0
bold = 'Bold' in fn or 'bold' in fn; tnr = 'Times' in fn; centered = abs(cx - mid) < 18.0
print('  en-title text=%r font=%r size=%.1f cx=%.1fpt (mid=%.1f) bold=%s tnr=%s centered=%s' %
      (title['text'].strip(), fn, title['size'], cx, mid, bold, tnr, centered))
# AC-4: TNR AND Bold (RED driver) AND ~三号 AND centered.
ok = tnr and bold and 15.0 <= title['size'] <= 17.0 and centered
sys.exit(0 if ok else 1)
"
}
run_test "P0" "ATDD-3.4-I04" "BEHAVIOR: English title ABSTRACT TNR Bold ~16pt centered (AC-4, TC-E3-21; RED pre-impl — LMSans \"Abstract\")" test_english_title_tnr_bold

# ATDD-3.4-I05: BEHAVIOR — English body ASCII spans median size ≈ 五号 10.5pt (AC-5)
# Pre-impl: body inherits \normalsize (小四号 12pt) → median ≈12 → RED. Post-impl: 五号 scope → ≈10.5 → GREEN.
test_english_body_wuhao_size() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
lines = en_body_lines(en_abs)
if not lines:
    print('  (no English body lines size∈[9,13] found — RED)'); sys.exit(1)
sizes = [s for _, s in lines]; med = median(sizes)
print('  en-body lines=%d median size=%.2fpt (五号 target ≈10.5; pre-impl body ≈12)' % (len(lines), med))
sys.exit(0 if 9.8 <= med <= 11.2 else 1)
"
}
run_test "P0" "ATDD-3.4-I05" "BEHAVIOR: English body ASCII size ≈ 五号 10.5pt (AC-5; RED pre-impl — inherits 12pt)" test_english_body_wuhao_size

# ATDD-3.4-I06: BEHAVIOR — English body line-gap ≈ 23.4bp (AC-5, R-14 — THE dominant-risk proof)
# R-14: independent 2× line spacing calibrated to the reference (23.4bp = Word "2倍行距"). Set via \fontsize,
#   NEVER \setstretch (R-3 → 25.2bp trap). Pre-impl: body inherits 18bp → median gap ≈18 → RED.
#   Post-impl: ≈23.4 → GREEN. Range [22.4, 24.4] (±1.0bp).
test_english_body_linegap_r14() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
lines = en_body_lines(en_abs)
if len(lines) < 3:
    print('  (too few English body lines to measure gap: %d — RED)' % len(lines)); sys.exit(1)
gaps = [round(lines[i+1][0] - lines[i][0], 2) for i in range(len(lines)-1) if lines[i+1][0] - lines[i][0] > 5.0]
med = median(gaps)
print('  en-body line-gaps=%d median=%.2fpt (R-14 target ≈23.4; pre-impl body 18bp; R-3-trap 25.2)' % (len(gaps), med))
# AC-5/R-14: ≈23.4bp (NOT 18 body, NOT 25.2 trap).
sys.exit(0 if 22.4 <= med <= 24.4 else 1)
"
}
run_test "P0" "ATDD-3.4-I06" "BEHAVIOR: English body line-gap ≈ 23.4bp (AC-5, R-14 dominant risk; RED pre-impl — 18bp body)" test_english_body_linegap_r14

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: En keywords (comma + non-bold) + Chinese title/body/keywords + regression guards ==="

# ATDD-3.4-I07: BEHAVIOR — English keyword separator = half-width comma (not semicolon) (AC-6, TC-E3-23)
# Find the keyword block (contains "KEY WORDS"). Our keywords (data/abstract.tex) have no internal ";"/",",
# so the separator is the ONLY ";" (pre) or "," (post) in that block. Pre-impl: "; " (cls:197) → block has ";".
#   Post-impl: ", " → block has "," and no ";". Assert: no ";" AND has ",".
test_english_keyword_comma() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if en_abs is None:
    print('  (English abstract page not found)'); sys.exit(1)
kwtext = None
for b in doc[en_abs].get_text('dict').get('blocks', []):
    spans = [sp for ln in b.get('lines', []) for sp in ln.get('spans', [])]
    t = ''.join(sp['text'] for sp in spans)
    if 'KEY WORDS' in t:
        kwtext = t; break
if kwtext is None:
    print('  (KEY WORDS block not found — RED)'); sys.exit(1)
# Separator detection — robust to a TNR ToUnicode quirk: the cls ASCII ';' (U+003B, cls:197) renders/extracts
# as U+037E (GREEK QUESTION MARK, ;lookalike) in this env (verified: body ASCII ','→U+002C and ':'→U+003A extract
# correctly, but the ';' separator → U+037E). Use chr(0x37E) explicitly (the literal ;looks identical to ;).
# ASCII comma (U+002C) extracts correctly → post-impl separator passes.
has_semi = any(ch in kwtext for ch in [';', '；', chr(0x37E)])   # U+003B / U+FF1B / U+037E
has_comma = ',' in kwtext   # U+002C — post-impl half-width comma; extracts correctly (verified)
print('  keyword-block has_semi=%s has_comma=%s | %r' % (has_semi, has_comma, kwtext[:80]))
sys.exit(0 if ((not has_semi) and has_comma) else 1)
"
}
run_test "P1" "ATDD-3.4-I07" "BEHAVIOR: English keyword separator = half-width comma (AC-6, TC-E3-23; RED pre-impl — \"; \")" test_english_keyword_comma

# ATDD-3.4-I08: BEHAVIOR — English KEY WORDS label BOLD (AC-6 §2.8 加粗)
# REPOINTED by Story 3.13: was NON-bold (user decision 2026-06-16, reference-wins per Decision 4 v1); now BOLD
#   (spec §2.8 line 223「'KEY WORDS：'用五号 TNR，加粗」PRIORITY, CLAUDE.md Decision 4 修正 2026-06-17,
#   sprint-change-proposal-2026-06-17 gap 1b). \bfseries wrap → TNR Bold (font has "Bold"). Reference p9
#   non-bold = Word-artifact deviation, overridden by spec. Find the label span, assert font HAS "Bold".
test_english_keywords_label_nonbold() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if en_abs is None:
    print('  (English abstract page not found)'); sys.exit(1)
label = None
for b in doc[en_abs].get_text('dict').get('blocks', []):
    for ln in b.get('lines', []):
        for sp in ln.get('spans', []):
            if sp['text'].strip().startswith('KEY WORDS') or sp['text'].strip() == 'KEY WORDS:':
                label = sp; break
        if label: break
    if label: break
if label is None:
    print('  (KEY WORDS label span not found — RED)'); sys.exit(1)
fn = label['font']; bold = 'Bold' in fn or 'bold' in fn
print('  KEY WORDS label font=%r size=%.1f bold=%s (spec §2.8 加粗; ref p9 deviation overridden)' % (fn, label['size'], bold))
sys.exit(0 if bold else 1)
"
}
run_test "P1" "ATDD-3.4-I08" "BEHAVIOR: English KEY WORDS label BOLD (REPOINTED by 3.13: spec §2.8 加粗; was NON-bold reference-wins)" test_english_keywords_label_nonbold

# ATDD-3.4-I09: BEHAVIOR — Chinese title "摘 要" SimHei ~16pt centered (AC-1, TC-E3-18)
# GREEN guard (already correct via \htu@chapter* \sffamily\sanhao → SimHei 三号). "摘" and "要" render as TWO
#   separate SimHei 16pt spans (\cabstractname = 摘\hspace{\ccwd}要 splits them; they may land in separate fitz
#   lines/blocks). Detection is span-level: find a 摘-span and a 要-span at size>14, assert both SimHei ~16pt and
#   the combined bbox centered. The title is the only ~16pt text on the Chinese-abstract page.
test_chinese_title_simhei() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if ch_abs is None:
    print('  (Chinese abstract page not found)'); sys.exit(1)
zhai = yao = None
for b in doc[ch_abs].get_text('dict').get('blocks', []):
    for ln in b.get('lines', []):
        for sp in ln.get('spans', []):
            if '摘' in sp['text'] and sp['size'] > 14: zhai = sp
            if '要' in sp['text'] and sp['size'] > 14: yao = sp
if zhai is None or yao is None:
    print('  (Chinese title 摘/要 spans at size>14 not found — regression)'); sys.exit(1)
ms = max(zhai['size'], yao['size'])
heiti = all(('SimHei' in s['font'] or 'Hei' in s['font']) for s in [zhai, yao])
x0 = min(zhai['bbox'][0], yao['bbox'][0]); x1 = max(zhai['bbox'][2], yao['bbox'][2])
cx = (x0 + x1) / 2.0; centered = abs(cx - mid) < 18.0
print('  ch-title 摘=%r 要=%r fonts=%s size=%.1f heiti=%s cx=%.1f centered=%s' %
      (zhai['font'], yao['font'], set(s['font'] for s in [zhai, yao]), ms, heiti, cx, centered))
sys.exit(0 if (heiti and 15.0 <= ms <= 17.0 and centered) else 1)
"
}
run_test "P1" "ATDD-3.4-I09" "BEHAVIOR: Chinese title 摘 要 SimHei ~16pt centered (AC-1, TC-E3-18; GREEN — already correct)" test_chinese_title_simhei

# ATDD-3.4-I10: BEHAVIOR — Chinese body SimSun ~12pt (inherits body; AC-2, TC-E3-19)
# GREEN guard. The Chinese body inherits \normalsize (小四号 12pt 宋体). Confirms 3.4 keeps it (no separate Ch baselineskip).
test_chinese_body_simsun() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if ch_abs is None:
    print('  (Chinese abstract page not found)'); sys.exit(1)
sizes = []; fonts = {}
for b in doc[ch_abs].get_text('dict').get('blocks', []):
    for ln in b.get('lines', []):
        for sp in ln.get('spans', []):
            if cjk_re.search(sp['text']) and 11.0 <= sp['size'] <= 13.0 and '摘' not in sp['text'] and '关键' not in sp['text']:
                sizes.append(sp['size']); fonts[sp['font']] = fonts.get(sp['font'], 0) + 1
if not sizes:
    print('  (no Chinese body spans size∈[11,13] found — regression)'); sys.exit(1)
med = median(sizes); song = any('SimSun' in f or 'Song' in f or '宋' in f for f in fonts)
print('  ch-body spans=%d median size=%.2fpt fonts=%s (expect SimSun ~12pt, inherits body)' % (len(sizes), med, fonts))
sys.exit(0 if (11.3 <= med <= 12.7 and song) else 1)
"
}
run_test "P1" "ATDD-3.4-I10" "BEHAVIOR: Chinese body SimSun ~12pt inherits body (AC-2, TC-E3-19; GREEN)" test_chinese_body_simsun

# ATDD-3.4-I11: BEHAVIOR — Chinese keyword label "关键词：" SimHei (AC-3, TC-E3-20)
# RED pre-impl (verified on baseline 227362f): the label renders **SimSun** (font='SimSun' 12.0pt), NOT SimHei —
#   the \textbf\htu@ckeywords@title yields SimSun-bold (AutoFakeBold), not the 黑体 face. Story 2.5's
#   "\rmfamily\bfseries→SimHei" finding does NOT apply to \textbf here. AC-3 requires Heiti (spec §2.7 黑体;
#   reference p5 SimHei) → Story Task 4.3 fix (replace \textbf with \sffamily). Post-impl → SimHei → GREEN.
test_chinese_keyword_label_heiti() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if ch_abs is None:
    print('  (Chinese abstract page not found)'); sys.exit(1)
label = None
# Search ch_abs AND the next 2 pages: Story 3.11's body baselineskip recalibration (18→23.4bp) LOOSENED the
#   abstract body → the Chinese abstract now spills onto a 2nd page, so the 关键词： label moved from ch_abs
#   (phys 7, now body-prose mentioning 关键词) to ch_abs+1 (phys 8). Searching only ch_abs missed the label
#   (detection-drift from the reflow, NOT a font regression — the label is still SimHei). Search ch_abs..ch_abs+2.
for pi in range(ch_abs, min(ch_abs + 3, doc.page_count)):
    for b in doc[pi].get_text('dict').get('blocks', []):
        for ln in b.get('lines', []):
            for sp in ln.get('spans', []):
                # Match the LABEL span EXACTLY ("关键词：" + full-width colon), NOT body text mentioning 关键词.
                # Detection-accuracy fix: the Ch-abstract BODY discusses 关键词 at size 12 SimSun (appears BEFORE
                # the label), so a substring match false-grabs the body span. The label is its own boxed span
                # (exactly "关键词："). A genuinely-SimSun label would still FAIL this (it checks the label span).
                if sp['text'].strip() == '关键词：' and 11.0 <= sp['size'] <= 13.0:
                    label = sp; break
            if label: break
        if label: break
    if label: break
if label is None:
    print('  (关键词 label span not found on ch_abs..ch_abs+2 — regression)'); sys.exit(1)
heiti = 'SimHei' in label['font'] or 'Hei' in label['font']
print('  关键词 label (phys %d) font=%r size=%.1f heiti=%s (spec §2.7 黑体; ref p5 SimHei)' % (pi+1, label['font'], label['size'], heiti))
sys.exit(0 if heiti else 1)
"
}
run_test "P1" "ATDD-3.4-I11" "BEHAVIOR: Chinese keyword label 关键词： SimHei (AC-3, TC-E3-20; RED pre-impl — renders SimSun, needs \\sffamily fix per Task 4.3)" test_chinese_keyword_label_heiti

# ATDD-3.4-I12: regression — self-check textheight ~688pt unchanged (AC-8, R-1)
# Abstract formatting must NOT touch geometry.
test_textheight_unchanged() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local th
  th=$(grep 'textheight = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$th" ]]; then echo "  (textheight not found in self-check)"; return 1; fi
  echo "  (textheight: ${th}pt [expect ~688.56])"
  echo "$th" | awk '{if ($1 >= 686 && $1 <= 690) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.4-I12" "regression: self-check textheight unchanged ~688pt (AC-8, R-1)" test_textheight_unchanged

# ATDD-3.4-I13: regression — self-check baselineskip ≈ 23.4bp (AC-8, R-3) — REPOINTED by Story 3.11
# LEAK-GUARD NOTE (Decision 2): pre-3.11 this guard asserted body self-check = 18bp to discriminate it from the
#   English-abstract 23.4bp scope (a 23.4bp read = English scope LEAKED into the self-check). Story 3.11
#   RECALIBRATED the body itself to 23.4bp (Word「1.5倍」×natural) — so body and English-abstract are now BOTH
#   ~23.4bp BY DESIGN. The self-check can no longer distinguish them (they coincide). The English-abstract
#   independence is now verified via the fitz English-abstract line-gap test (3.4-I06 / 3.11-I07: English page
#   line-gap = 23.4bp specifically), NOT via this self-check value. This guard now asserts the recalibrated body
#   value (band [22.5,24.5]; still excludes the 21.6bp R-3 trap and the old 18bp naive).
test_baselineskip_18bp_leak_guard() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local bs
  bs=$(grep 'baselineskip = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$bs" ]]; then echo "  (baselineskip not found in self-check)"; return 1; fi
  echo "  (baselineskip: ${bs}pt, expect ~23.49 [body 23.4bp, recalibrated by Story 3.11]; 21.6=R-3 trap)"
  echo "$bs" | awk '{if ($1 >= 22.5 && $1 <= 24.5) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.4-I13" "regression: self-check baselineskip ~23.4bp (REPOINTED by Story 3.11; body=English=23.4 by design; English-independence via fitz 3.4-I06)" test_baselineskip_18bp_leak_guard

# ATDD-3.4-I14: total pages ~51 ±5 (AC-8; abstract already exists pre-impl → no new page expected)
# The abstract renders pre-impl (just wrongly formatted); 3.4 changes formatting, not page count. Expect ~51
# (Story 3.3 baseline). Range 46-56 absorbs drift; repoint transparently if a 2.x/3.x page-count assertion FAILs.
test_total_pages() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local total_pages
  total_pages=$(grep 'total pages = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | tr -d '[:space:]')
  if [[ -z "$total_pages" ]]; then echo "  (page count not found)"; return 1; fi
  echo "  (pages: $total_pages, expected ~51 ±5 [abstract already exists — no new page])"
  echo "$total_pages" | awk '{if ($1 >= 46 && $1 <= 56) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.4-I14" "total pages ~51 ±5 (AC-8; abstract already exists — no new page)" test_total_pages

# ATDD-3.4-I15: regression — no fancyhdr headheight warning (AC-8, R-2)
test_no_headheight_warning() {
  if [[ -f "main.log" ]]; then
    ! grep -qi 'headheight.*too low\|fancyhdr.*headheight' main.log 2>/dev/null
  else
    return 1
  fi
}
run_test "P1" "ATDD-3.4-I15" "regression: no fancyhdr headheight warning (AC-8, R-2)" test_no_headheight_warning

# ATDD-3.4-I16: BEHAVIOR — English abstract page 0 LMSans + 0 LMRoman (AC-9 — closes 3.9's deferred gap)
# Story 3.9 deferred the English-title LMSans gap to 3.4. Post-3.4 the title is TNR Bold → the page has 0 LMSans
#   and 0 LMRoman spans (all Latin = TNR). Pre-impl: 1 LMSans (the "Abstract" title) → RED. This is the AC-9
#   cross-story proof that 3.4 closed 3.9's gap (ATDD-3.9-16's "other"/LMSans span → 0).
test_english_abstract_no_lm() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if en_abs is None:
    print('  (English abstract page not found)'); sys.exit(1)
counts = {'lm_roman': 0, 'lm_sans': 0, 'tnr': 0, 'other': 0}
for b in doc[en_abs].get_text('dict').get('blocks', []):
    for ln in b.get('lines', []):
        for sp in ln.get('spans', []):
            if ascii_re.search(sp['text']):
                counts[classify_font(sp['font'])] += 1
print('  en-abstract ASCII font counts: %s' % counts)
# AC-9: 0 Latin Modern (Roman AND Sans) — all Latin = TNR. (Pre-impl: 1 LMSans title span → RED.)
sys.exit(0 if (counts['lm_roman'] == 0 and counts['lm_sans'] == 0 and counts['tnr'] >= 1) else 1)
"
}
run_test "P1" "ATDD-3.4-I16" "BEHAVIOR: English abstract 0 LMSans + 0 LMRoman (AC-9 — closes 3.9 deferred gap; RED pre-impl)" test_english_abstract_no_lm

echo ""

# ==========================================
# P2 Tests (Best-Effort) — diagnostic
# ==========================================
echo "=== P2: English abstract rendered layout diagnostic (AC visual-sampling pages #4/#5) ==="

# ATDD-3.4-I17: DIAGNOSTIC — English abstract rendered layout for manual reference-overlay (visual-sampling #5)
# Records the rendered title/body/keyword fonts+sizes+positions for manual comparison vs the reference thesis
# PDF (p6/p9). Does NOT hard pass/fail — exits 0 if the page was found (prints layout). The reference is the
# VISUAL truth (TNR Bold ABSTRACT ~16pt; body TNR 10.5pt gap 23.4bp; KEY WORDS: non-bold, comma separator).
test_english_abstract_layout_diagnostic() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if en_abs is None:
    print('  (English abstract page not found — RED pre-impl)'); sys.exit(1)
pg = doc[en_abs]
print('  en-abstract=p%d rendered layout (for manual reference-overlay vs p6/p9):' % (en_abs+1))
for b in pg.get_text('dict').get('blocks', []):
    if b.get('type', 0) != 0: continue
    spans = [sp for ln in b.get('lines', []) for sp in ln.get('spans', [])]
    txt = ''.join(sp['text'] for sp in spans).strip()
    if not txt: continue
    x0,y0,x1,y1 = b['bbox']; ms = max((sp['size'] for sp in spans), default=0.0)
    fnts = {}
    for sp in spans:
        fnts[sp['font']] = fnts.get(sp['font'], 0) + 1
    print('    y=%.1fmm cx=%.1fmm size=%.1fpt fonts=%s | %r' % (mm(y0), mm((x0+x1)/2.0), ms, fnts, txt[:55]))
print('  reference p6: ABSTRACT TimesNewRomanPS-BoldMT ~16pt; body TNR 10.4pt gap 23.4bp.')
print('  reference p9: KEY WORDS: TimesNewRomanPSMT (non-bold) + \", \" separator, no colon-space.')
sys.exit(0)
"
}
run_test "P2" "ATDD-3.4-I17" "DIAGNOSTIC: English abstract rendered layout for reference-overlay (AC visual-sampling #5)" test_english_abstract_layout_diagnostic

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
  echo "   RED (fail pre-impl): I04 (En title TNR Bold — LMSans 'Abstract'), I05 (En body 五号 — inherits 12pt),"
  echo "      I06 (En body line-gap ~23.4bp [R-14] — 18bp body), I07 (En keyword comma — ';' renders U+037E),"
  echo "      I08 (KEY WORDS non-bold — \\textbf), I11 (Ch keyword label SimSun — needs \\sffamily Heiti),"
  echo "      I16 (En abstract 0 LMSans — title is LMSans pre-impl)."
  echo "   GREEN guards: I01-I03 (compile), I09 (Ch title SimHei), I10 (Ch body SimSun),"
  echo "      I12 (textheight), I13 (baselineskip 18bp — R-3 LEAK GUARD), I14 (pages), I15 (no headheight)."
  echo "      I17 = diagnostic (reference-overlay positions)."
  echo ""
  echo "   NOTE: the fitz behavior tests are the real AC proof — source-greps cannot prove rendered font/size/"
  echo "         line-gap (a \\fontsize/\\setmainfont override could evade a grep). I06 is the R-14 dominant-risk"
  echo "         proof (≈23.4bp, NOT 18bp body, NOT 25.2bp R-3-trap). I13 is the R-3 LEAK GUARD (self-check must"
  echo "         still read body 18bp — the English ~23.4bp scope must NOT leak). AC-9 cross-story: I16 closes"
  echo "         3.9's deferred LMSans gap (ATDD-3.9-16 stays GREEN — its RED condition = LMRoman, unaffected)."
  echo "         Tests are read-only — they do not modify the SUT."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
