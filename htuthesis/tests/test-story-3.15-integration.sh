#!/usr/bin/env bash
# test-story-3.15-integration.sh — ATDD Integration (rendered) Tests for Story 3.15 (spec-compliance residual-gap pack G1–G6)
# TDD Phase: RED — the RED driver cluster is I04 (G1 TOC 第N章 number-prefix SimHei), I05 (G6 TOC Latin TNR),
#             I06 (G6 HEADING Latin TNR — the heading-side probe cross-story 3.5-I18 misses), I07 (G2 eabstract 4-char
#             indent), I08 (G4 cover date Chinese numerals), I09 (G3 numbering=sc renders NS 1/2). Pre-impl (baseline
#             commit 567e13a, post-3.14): the 6 gaps render WRONG — TOC L1 number-prefix SimSun, TOC+heading Latin
#             LMSans, eabstract indent 2 chars, cover date Arabic, no NS numbering option. Post-impl (spec §2.6/§2.8/
#             §2.10/§1.1.1/§2.15 PRIORITY): all 6 render spec-compliant. GREEN guards I10 (G3 hs default renders
#             第一章 — R-22 both-mode regression), I11 (G5a appendix env source — rendered blocked → 4.1), I12
#             (geometry/baselineskip regression) PASS pre+post.
#
# Usage: bash tests/test-story-3.15-integration.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 (compile gate R-12 + G1/G6-TOC/G6-heading RED drivers) + P1 (G2/G4/G3/G5a + regression)
# Linked ACs: AC-1/G1 (TOC number-prefix SimHei), AC-2/G6 (TOC+heading Latin TNR), AC-3/G2 (eabstract 4-char indent),
#             AC-4/G3 (numbering=sc renders NS; default hs), AC-5/G4 (cover date CJK numerals), AC-6/G5a (appendix font),
#             AC-7 (compile + regression gate), AC-8 (test-suite updates — this suite + cross-story repoints)
# Linked Risk: R-21 (score 6, G6 structural font-leak ripple), R-22 (score 4, G3 dual-mode matrix), R-12 (4, -g recompile),
#              R-G4date (3, \CJK@todaybig compile-date trap)
# TC coverage: TC-E3-58 (G4 — I08), TC-E3-59 (G2 — I07), TC-E3-60 (G1 — I04), TC-E3-61 (G6 — I05/I06),
#              TC-E3-62 (G5a — I11), TC-E3-63 (G3 — I09/I10)
#
# NOTE: every G1–G6 AC probes the RENDERED SPAN the spec governs (fitz get_text('dict') font/size/position), NOT a code
#   grep or a proxied target — the wrong-target-AC root-cause discipline (sprint-change-proposal-2026-06-19 D-22;
#   architecture silent-failure #13 TOC L1 number-prefix font + #14 heading/TOC Latin leak; Epic 2 retro Decision 1
#   extended to font/position ACs). The 3.5-I18 cross-story probe only covers TOC Latin; I06 adds the HEADING-side
#   (cls:463/475/484 \sffamily leak) — the chap01 "TEX/LaTeX" title is the RED signal.
#
# Cross-story RED-phase additions (ALREADY authored, isolated ATDD_315_SKIP gate, preserve the 575-PASS baseline):
#   3.5-I17 (G1 TOC number-prefix), 3.5-I18 (G6 TOC Latin), 3.4-I18 (G2 eabstract indent), 3.1-I17 (G4 cover date),
#   3.13-I14 (G3 sc renders), 3.13-unit-11 (G3 option declared), 3.7-I17 (G5a appendix source). This 3.15 suite is the
#   CONSOLIDATED authoritative gate (+ G6 heading-side I06 + G3 hs-default I10 the cross-story misses) — the dev-story
#   primary RED→GREEN driver. ⚠ Cross-story TC-ID fixup at dev-story: 3.4 G2 cites TC-E3-62 (should be 59), 3.7 G5a
#   cites TC-E3-65 (should be 62); 3.1 G4 line refs cls:601/615-617 stale (actual cls:697) + prescribes \CJK@todaybig
#   (compile-date trap) — align to this suite's correct IDs/refs.
#
# Truth source: 河南师范大学研究生学位论文格式要求.md §2.6 line 207 (G1) + §2.8 line 221 (G2) + §2.10 line 235-237 (G3)
#   + §1.1.1 line 33 (G4) + §2.15 line 439 (G5a) — ALL PRIORITY (CLAUDE.md Decision 4, corrected 2026-06-17).

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
echo "ATDD Integration Tests: Story 3.15 — spec-compliance residual-gap pack (G1–G6; §2.6/§2.8/§2.10/§1.1.1/§2.15)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# Shared Python header: opens main.pdf, locates cover/TOC/eabstract pages by signature, defines rendered-span probes.
#   cover (doctoral) = 博士学位论文 + 10476 (NOT 摘要); toc = 目/录 title or dot-leader chapter page; eabstract = ABSTRACT.
#   latin_in(spans, size_band) = Latin-letter spans in a size band (for G6 heading/TOC Latin-leak detection).
PY_HEAD='
import fitz, sys, re
doc = fitz.open("main.pdf")
W = doc[0].rect.width; H = doc[0].rect.height; mid = W / 2.0
cover = None
for i in range(min(6, doc.page_count)):
    t = doc[i].get_text()
    if "博士学位论文" in t and "10476" in t and "摘要" not in t:
        cover = i; break
toc = None
for i in range(min(16, doc.page_count)):
    t = doc[i].get_text()
    if re.search(r"目\s*录", t):
        toc = i; break
if toc is None:
    for i in range(min(16, doc.page_count)):
        t = doc[i].get_text()
        if ("第一章" in t or "参考文献" in t) and t.count(".") >= 3:
            toc = i; break
eabstract = None
for i in range(min(16, doc.page_count)):
    t = doc[i].get_text()
    if "ABSTRACT" in t or "Abstract" in t:
        eabstract = i; break
def spans_band(pno, lo, hi):
    out = []
    for b in doc[pno].get_text("dict").get("blocks", []):
        if b.get("type", 0) != 0: continue
        for ln in b.get("lines", []):
            for sp in ln.get("spans", []):
                if lo <= sp["size"] <= hi:
                    out.append(sp)
    return out
def is_lm(f):
    return ("LMSans" in f) or ("LMRoman" in f) or ("Latin Modern" in f)
'

# ==========================================
# P0 — Compile gate (R-12 full recompile; G6 structural \heiti + G3 numbering option regenerate .toc/.aux)
# ==========================================
echo "=== P0: Compile gate (R-12 — -g full recompile; G6 heading + G3 numbering regenerate TOC/aux) ==="

# ATDD-3.15-I01: latexmk -xelatex -g main.tex exit 0 (AC-7, compile gate, R-12)
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-3.15-I01" "latexmk -xelatex -g main.tex exit code 0 (AC-7, R-12 full recompile)" test_full_compile

# ATDD-3.15-I02: zero compilation errors in main.log (AC-7)
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
run_test "P0" "ATDD-3.15-I02" "zero compilation errors in main.log (AC-7)" test_no_errors

# ATDD-3.15-I03: warning count <= 3 (AC-7, NFR <=3 vs Story 3.14 baseline = 1 standing xeCJK \CJKsfdefault from 3.9)
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
run_test "P0" "ATDD-3.15-I03" "warning count <= 3 (AC-7, NFR <=3 new vs 3.14 baseline)" test_warning_count

echo ""

# ==========================================
# P0 — G1 TOC L1 chapter number-prefix = SimHei (TC-E3-60)
# ==========================================
echo "=== P0: G1 TOC 第N章 number-prefix span = SimHei (TC-E3-60, §2.6) ==="

# ATDD-3.15-I04: BEHAVIOR — every TOC L1 chapter NUMBER-PREFIX ("第N章" contentslabel) span = SimHei (G1, TC-E3-60).
# Wrong-target-AC root cause: prior 3.5 tests asserted the chapter TITLE span (SimHei, passes) — never the NUMBER
#   PREFIX. Audit found cls:560 {{\rmfamily\thecontentslabel}\quad} forces the prefix to SimSun while the title is
#   SimHei. Spec §2.6 line 207: ENTIRE L1 entry 黑体. Probe the prefix span itself. Pre-impl: SimSun → RED.
test_g1_toc_numberprefix_simhei() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if toc is None:
    print('  (TOC page not found — RED/inconclusive)'); sys.exit(1)
chap_re = re.compile(r'^第[一二三四五六七八九十百]+章')
prefixes = []
for sp in spans_band(toc, 11, 15):
    t = sp['text'].strip()
    if chap_re.match(t):
        prefixes.append((sp['font'], sp['size'], t))
if not prefixes:
    print('  (no 第N章 contentslabel span on TOC — sample-dependent; RED/inconclusive)'); sys.exit(1)
heiti = all(('SimHei' in f or 'Hei' in f) for f, s, t in prefixes)
print('  TOC 第N章 number-prefix spans=%d fonts=%s heiti=%s' %
      (len(prefixes), sorted(set(f for f, s, t in prefixes)), heiti))
for f, s, t in prefixes[:4]:
    print('    %r %.1fpt | %s' % (f, s, t))
sys.exit(0 if heiti else 1)
"
}
run_test "P0" "ATDD-3.15-I04" "BEHAVIOR: TOC 第N章 number-prefix span = SimHei (G1, TC-E3-60, §2.6; *** RED DRIVER *** — SimSun via cls:560 \\rmfamily)" test_g1_toc_numberprefix_simhei

# ==========================================
# P0 — G6 TOC Latin = TNR not LMSans (TC-E3-61)
# ==========================================
echo "=== P0: G6 TOC Latin = TNR not LMSans (TC-E3-61, §2.6/§2.10) ==="

# ATDD-3.15-I05: BEHAVIOR — TOC Latin spans = TNR (G6, TC-E3-61). cls:559 \sffamily (CJK-bold) leaks Latin → LMSans.
#   Probe any non-digit Latin span in TOC entries. Pre-impl: "TEX/L" LMSans → RED. Post-impl: \heiti → TNR → GREEN.
test_g6_toc_latin_tnr() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if toc is None:
    print('  (TOC page not found — RED/inconclusive)'); sys.exit(1)
leak = []; latin_total = 0
for sp in spans_band(toc, 9, 14):
    t = sp['text'].strip()
    if re.search(r'[A-Za-z]', t) and not re.fullmatch(r'\d+', t):
        latin_total += 1
        if is_lm(sp['font']):
            leak.append((sp['font'], t[:20]))
print('  TOC Latin spans=%d LM-leak=%d' % (latin_total, len(leak)))
for f, t in leak[:4]:
    print('    LEAK %r | %s' % (f, t))
if latin_total == 0:
    print('  (no Latin span in TOC — sample-dependent; inconclusive)'); sys.exit(1)
sys.exit(0 if (latin_total >= 1 and not leak) else 1)
"
}
run_test "P0" "ATDD-3.15-I05" "BEHAVIOR: TOC Latin = TNR not LMSans (G6, TC-E3-61, §2.6/§2.10; *** RED DRIVER *** — \\sffamily Latin leak)" test_g6_toc_latin_tnr

# ==========================================
# P0 — G6 HEADING Latin = TNR not LMSans (TC-E3-61; heading-side — the value-add vs cross-story 3.5-I18)
# ==========================================
echo "=== P0: G6 HEADING Latin = TNR not LMSans (heading-side; cls:463/475/484) ==="

# ATDD-3.15-I06: BEHAVIOR — body chapter/section HEADING Latin = TNR (G6 heading-side, TC-E3-61).
#   cls:463/475/484 format={\sffamily...} leaks Latin → LMSans in headings (e.g. chap01 "TEX/LaTeX 系统概述" title).
#   Heading size band: chapter 16bp (\sanhao), section 15bp (\xiaosan). Probe ≥14.5bp Latin spans across body pages.
#   Pre-impl: chap01 heading Latin LMSans → RED. Post-impl: CJK-only \heiti → TNR → GREEN.
#   (Cross-story 3.5-I18 only covers TOC Latin; this is the HEADING-side proof — the G6 cls:463/475/484 target.)
test_g6_heading_latin_tnr() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
leak = []; latin_total = 0
for pno in range(doc.page_count):
    if pno in (cover, toc, eabstract):
        continue
    for sp in spans_band(pno, 13.5, 17.5):  # chapter 16bp / section 15bp / subsection 14bp heading band (floor lowered 13.5 to cover subsection \sihao)
        t = sp['text'].strip()
        if re.search(r'[A-Za-z]', t) and not re.fullmatch(r'\d+', t):
            latin_total += 1
            if is_lm(sp['font']):
                leak.append((pno+1, sp['font'], t[:25]))
print('  HEADING Latin spans=%d LM-leak=%d (heading band 14.5-17.5bp)' % (latin_total, len(leak)))
for p, f, t in leak[:4]:
    print('    p%d LEAK %r | %s' % (p, f, t))
if latin_total == 0:
    print('  (no Latin in any heading — sample-dependent; inconclusive)'); sys.exit(1)
sys.exit(0 if not leak else 1)
"
}
run_test "P0" "ATDD-3.15-I06" "BEHAVIOR: HEADING Latin = TNR not LMSans (G6 heading-side cls:463/475/484, TC-E3-61; *** RED DRIVER *** — value-add vs cross-story TOC-only probe)" test_g6_heading_latin_tnr

echo ""

# ==========================================
# P1 — G2 EN-abstract first-line indent = 4 chars (TC-E3-59)
# ==========================================
echo "=== P1: G2 EN-abstract first-line indent = 4 chars (TC-E3-59, §2.8) ==="

# ATDD-3.15-I07: BEHAVIOR — English abstract first-line indent ≈ 4 TNR chars (G2, TC-E3-59, §2.8 line 221).
#   cls:858-866 eabstract \begingroup sets no \parindent → inherits body 2\ccwd (~2 CJK chars). Probe the eabstract
#   body: first-line x0 − flush-wrap x0 ≈ 4× TNR char (~28-40pt). Pre-impl: ~21pt (2 chars) → RED.
test_g2_eabstract_indent_4chars() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if eabstract is None:
    print('  (eabstract page not found — RED/inconclusive)'); sys.exit(1)
body = [sp for sp in spans_band(eabstract, 9, 13) if re.search(r'[A-Za-z]', sp['text'])]
if len(body) < 4:
    print('  (too few eabstract body spans: %d — RED/inconclusive)' % len(body)); sys.exit(1)
xs = sorted(set(round(sp['bbox'][0], 1) for sp in body))
minx = min(xs)
# first-line indent = the x0 of the indented first line; wrap lines flush at the body left margin (minx).
indents = [x for x in xs if x > minx + 3]
if not indents:
    print('  (no indented first line detected — eabstract may be 1 line; RED/inconclusive)'); sys.exit(1)
first_indent = min(indents) - minx
print('  eabstract body x0 set=%s' % xs[:6])
print('  first-line indent = %.1fpt (4-char target ~28-40pt; pre-impl ~21pt = 2 chars body-inherit)' % first_indent)
# 4 TNR chars ≈ 4 × ~7pt ≈ 28pt; allow 24-44pt band (4 chars); reject the ~21pt 2-char body-inherit.
sys.exit(0 if 24 <= first_indent <= 44 else 1)
"
}
run_test "P1" "ATDD-3.15-I07" "BEHAVIOR: EN-abstract first-line indent = 4 chars (G2, TC-E3-59, §2.8; *** RED DRIVER *** — 2\\ccwd body inherit)" test_g2_eabstract_indent_4chars

# ==========================================
# P1 — G4 cover date = Chinese numerals (TC-E3-58)
# ==========================================
echo "=== P1: G4 cover date = Chinese numerals 二〇…年…月 (TC-E3-58, §1.1.1) ==="

# ATDD-3.15-I08: BEHAVIOR — cover date renders Chinese numerals, NOT Arabic (G4, TC-E3-58, §1.1.1 line 33).
#   cls:697 cover-date node renders \htu@cdate; pre-impl = Arabic "2024年5月". Probe the rendered date span on the cover
#   (near bottom, y≈247mm): must contain a CJK numeral char (〇零一二三四五六七八九) AND no 4-consecutive-ASCII-digit year.
#   ⚠ This is the rendered-glyph proof; unit-04b proves the CJK-numeral MECHANISM exists. \CJK@todaybig alone is NOT
#      sufficient proof — it renders the COMPILE date; the GREEN condition is the GLYPHS (二〇…), regardless of mechanism.
test_g4_cover_date_cn_numerals() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if cover is None:
    print('  (cover page not found — RED/inconclusive)'); sys.exit(1)
cn_num_re = re.compile(r'[〇零一二三四五六七八九]')
arabic_year_re = re.compile(r'\d{4}')
date_spans = []
for b in doc[cover].get_text('dict').get('blocks', []):
    if b.get('type', 0) != 0: continue
    for ln in b.get('lines', []):
        for sp in ln.get('spans', []):
            t = sp['text'].strip()
            y0 = sp['bbox'][1]
            # cover date sits near the bottom (y≈247mm ≈ 700pt); accept any span with 年/月 or a 4-digit/CJK-numeral date
            if ('年' in t or '月' in t or cn_num_re.search(t) or arabic_year_re.search(t)) and y0 > H * 0.6:
                date_spans.append((t, sp['font']))
if not date_spans:
    print('  (no date span found near cover bottom — RED/inconclusive)'); sys.exit(1)
joined = ' '.join(t for t, f in date_spans)
has_cn = bool(cn_num_re.search(joined))
has_arabic_year = bool(arabic_year_re.search(joined))
print('  cover date spans=%s' % date_spans[:4])
print('  cn_numeral=%s arabic_4digit_year=%s' % (has_cn, has_arabic_year))
# GREEN: CJK numeral present AND no Arabic 4-digit year. Pre-impl: Arabic year → RED.
sys.exit(0 if (has_cn and not has_arabic_year) else 1)
"
}
run_test "P1" "ATDD-3.15-I08" "BEHAVIOR: cover date = Chinese numerals 二〇…年…月 (G4, TC-E3-58, §1.1.1; *** RED DRIVER *** — Arabic digits; ⚠ \\CJK@todaybig compile-date trap)" test_g4_cover_date_cn_numerals

echo ""

# ==========================================
# P1 — G3 numbering=sc renders NS chapter 1/2 (TC-E3-63) + hs default renders 第一章 (R-22 both-mode)
# ==========================================
echo "=== P1: G3 numbering=sc renders NS 1/2 (TC-E3-63) + default hs renders 第一章 (R-22 both-mode) ==="

# ATDD-3.15-I09: BEHAVIOR — numbering=sc renders natural-science chapter numbering (G3, TC-E3-63, §2.10 line 235).
#   Story 3.13 DELETED the NS path; G3 restores it as a numbering=sc|hs option (default hs). This test compiles a TEMP
#   numbering=sc variant (sed-copy of main.tex — NOT a SUT mutation; temp file .atdd-315-sc.tex in the build dir) and
#   asserts NS Arabic chapter headings (1/2) render. Pre-impl: no numbering= option → compile FAILs / no NS → RED.
test_g3_sc_renders_ns() {
  if [[ ! -f "main.tex" ]] || [[ ! -f "htuthesis.cls" ]]; then return 1; fi
  # Temp numbering=sc variant (same dir as main.tex so \input paths resolve). main.tex untouched.
  sed 's/\\documentclass\[/\\documentclass[numbering=sc,/' main.tex > .atdd-315-sc.tex 2>/dev/null
  if [[ ! -s ".atdd-315-sc.tex" ]]; then
    echo "  (temp .atdd-315-sc.tex not created — main.tex documentclass signature changed? RED/inconclusive)"; return 1
  fi
  latexmk -xelatex -g -interaction=nonstopmode .atdd-315-sc.tex > /dev/null 2>&1
  local rc=$?
  local sc_clean=".atdd-315-sc.tex .atdd-315-sc.pdf .atdd-315-sc.aux .atdd-315-sc.log .atdd-315-sc.toc .atdd-315-sc.lof .atdd-315-sc.lot .atdd-315-sc.out .atdd-315-sc.fls .atdd-315-sc.fdb_latexmk .atdd-315-sc.bbl .atdd-315-sc.bcf .atdd-315-sc.blg .atdd-315-sc.run.xml .atdd-315-sc.xdv"
  if [[ $rc -ne 0 ]]; then
    rm -f $sc_clean 2>/dev/null
    echo "  (numbering=sc compile FAILED rc=$rc — option not implemented; RED pre-impl)"
    return 1
  fi
  python -c "
import fitz, sys, re
d = fitz.open('.atdd-315-sc.pdf')
ns_arabic = 0; hs_cn = 0
for pno in range(d.page_count):
    t = d[pno].get_text()
    # NS chapter heading = a line starting with an Arabic int + dot/title (1, 2, ...); HS = 第...章
    if re.search(r'(?m)^\s*[1-9]\b', t) and ('绪论' in t or '引言' in t or '概述' in t or '研究' in t):
        ns_arabic += 1
    if re.search(r'第[一二三四五六七八九十]+章', t):
        hs_cn += 1
print('  numbering=sc PDF: NS-arabic-chapter-pages=%d HS-cjk-chapter-pages=%d' % (ns_arabic, hs_cn))
sys.exit(0 if (ns_arabic >= 1 and hs_cn == 0) else 1)
"
  local prc=$?
  rm -f $sc_clean 2>/dev/null
  return $prc
}
run_test "P1" "ATDD-3.15-I09" "BEHAVIOR: numbering=sc renders NS chapter 1/2 (G3, TC-E3-63, §2.10; *** RED DRIVER *** — 3.13 deleted NS; temp compile, SUT untouched)" test_g3_sc_renders_ns

# ATDD-3.15-I10: BEHAVIOR — DEFAULT (numbering=hs) renders humanities 第一章 (G3 hs path, R-22 both-mode regression).
#   G3 restores NS as opt-in; the DEFAULT must stay hs (第一章). R-22: both modes tested. GREEN pre+post (the default
#   main.pdf is hs). RED = G3 accidentally made sc the default (no 第一章 in body).
test_g3_hs_default_renders() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
hs = 0
for pno in range(doc.page_count):
    if pno in (cover, toc, eabstract): continue
    if re.search(r'第[一二三四五六七八九十]+章', doc[pno].get_text()):
        hs += 1
print('  default main.pdf: HS-cjk-chapter (第一章) body pages=%d' % hs)
# GREEN: ≥1 body page with 第一章 (default hs preserved). RED = 0 (G3 flipped default to sc).
sys.exit(0 if hs >= 1 else 1)
"
}
run_test "P1" "ATDD-3.15-I10" "BEHAVIOR: default numbering=hs renders 第一章 (G3 hs default, R-22 both-mode regression; GREEN pre+post)" test_g3_hs_default_renders

# ==========================================
# P1 — G5a appendix env body source check (TC-E3-62; rendered → 4.1)
# ==========================================
echo "=== P1: G5a appendix env body explicit 小四宋体 (TC-E3-62, §2.15; rendered → Story 4.1) ==="

# ATDD-3.15-I11: SOURCE-LEVEL — appendix env body explicitly \xiaosi\songti (G5a, TC-E3-62, §2.15 line 439).
#   The appendix does NOT render in main.pdf (main.tex has no \appendix; G5b wiring = Story 4.1). The RENDERED proof is
#   blocked on 4.1; this source-grep is the available G5a probe (wrong-target-AC note: proxied by necessity — 4.1 owns
#   the rendered appendix-body SimSun-12pt proof). Pre-impl: env body has no \xiaosi\songti (implicit \normalsize) → RED.
test_g5a_appendix_body_source() {
  if [[ ! -f "htuthesis.cls" ]]; then return 1; fi
  python3 - <<'PY'
import re, sys
src = open("htuthesis.cls", encoding="utf-8").read()
lines = [ln for ln in src.splitlines() if not ln.lstrip().startswith("%")]
text = "\n".join(lines)
i = text.find(r"\renewenvironment{appendix}")
if i < 0:
    print("  (\\renewenvironment{appendix} not found — RED)"); sys.exit(1)
seg = text[i:i+700]
has = (r"\xiaosi" in seg) and (("songti" in seg) or ("\\song" in seg))
print("  appendix env begin-clause has explicit \\xiaosi+\\songti: %s" % has)
sys.exit(0 if has else 1)
PY
}
run_test "P1" "ATDD-3.15-I11" "SOURCE-LEVEL: appendix env body explicit 小四宋体 (G5a, TC-E3-62, §2.15; *** RED DRIVER *** — implicit \\normalsize; rendered → 4.1)" test_g5a_appendix_body_source

echo ""

# ==========================================
# P1 — Regression: geometry/baselineskip unchanged (G1–G6 are font/numbering/date scope, NOT geometry/body spacing)
# ==========================================
echo "=== P1: Regression — geometry/baselineskip unchanged (G1–G6 ≠ geometry/body spacing) ==="

# ATDD-3.15-I12: regression — self-check textheight ~688pt + baselineskip ~23.4bp unchanged (AC-7).
#   G1–G6 are font/numbering/date scope (cls:560/559/463/475/484/858/447-498/697/956-968); neither body line-spacing
#   (Story 3.11) nor page geometry (Story 2.1) is touched. Regression watch.
test_geometry_baselineskip_unchanged() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local th bs
  th=$(grep 'textheight = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  bs=$(grep 'baselineskip = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$th" ]] || [[ -z "$bs" ]]; then echo "  (self-check dims not found)"; return 1; fi
  echo "  (textheight: ${th}pt [expect ~688.56]; baselineskip: ${bs}pt [expect ~23.49])"
  local trc brc
  echo "$th" | awk '{exit ($1 >= 686 && $1 <= 690) ? 0 : 1}'; trc=$?
  echo "$bs" | awk '{exit ($1 >= 22.5 && $1 <= 24.5) ? 0 : 1}'; brc=$?
  [[ $trc -eq 0 ]] && [[ $brc -eq 0 ]]
}
run_test "P1" "ATDD-3.15-I12" "regression: textheight ~688pt + baselineskip ~23.4bp unchanged (AC-7; G1–G6 ≠ geometry/body)" test_geometry_baselineskip_unchanged

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
  echo "   RED drivers (FAIL pre-impl 6-gap state, PASS post-impl spec §2.6/§2.8/§2.10/§1.1.1/§2.15):"
  echo "      I04 G1 TOC 第N章 number-prefix SimHei (TC-E3-60, §2.6)"
  echo "      I05 G6 TOC Latin TNR not LMSans (TC-E3-61, §2.6/§2.10)"
  echo "      I06 G6 HEADING Latin TNR (cls:463/475/484 — value-add vs cross-story TOC-only probe)"
  echo "      I07 G2 EN-abstract first-line indent 4 chars (TC-E3-59, §2.8)"
  echo "      I08 G4 cover date Chinese numerals (TC-E3-58, §1.1.1; ⚠ \\CJK@todaybig compile-date trap)"
  echo "      I09 G3 numbering=sc renders NS 1/2 (TC-E3-63, §2.10; temp compile, SUT untouched)"
  echo "      I11 G5a appendix env body 小四宋体 (TC-E3-62, §2.15; source-level — rendered → 4.1)"
  echo "   GREEN guards (PASS pre+post):"
  echo "      I01-03 compile (R-12 -g recompile), I10 G3 hs-default renders 第一章 (R-22 both-mode),"
  echo "         I12 geometry/baselineskip unchanged (G1–G6 ≠ geometry/body)."
  echo ""
  echo "   Every G1–G6 AC probes the RENDERED SPAN (fitz font/size/position), never a code grep or proxied target —"
  echo "      the wrong-target-AC root-cause fix (architecture silent-failure #13/#14; D-22). Cross-story RED additions"
  echo "      (3.5-I17/I18, 3.4-I18, 3.1-I17, 3.13-I14, 3.7-I17) are regression guards in their home suites; this 3.15"
  echo "      suite is the consolidated authoritative gate (+ I06 heading-side + I10 hs-default they miss)."
  echo "   ⚠ Cross-story TC-ID fixup at dev-story: 3.4 G2 TC-E3-62→59, 3.7 G5a TC-E3-65→62; 3.1 G4 cls:601→697 +"
  echo "      \\CJK@todaybig trap. Line refs re-verified vs HEAD 567e13a. Tests are read-only (no SUT mutation — Epic 1"
  echo "      retro); .atdd-315-sc.* temp files cleaned up after I09."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
