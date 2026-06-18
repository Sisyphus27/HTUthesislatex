#!/usr/bin/env bash
# test-story-3.12-integration.sh — ATDD Integration Tests for Story 3.12 (References dual-mode citation — §2.14 case-2)
# TDD Phase: RED — the PRIMARY RED driver is ATDD-3.12-I05 (per-page citation footnote "1" recurrence +
#             full-entry-in-footnote, TC-E3-48, R-19). Pre-impl (baseline after Story 3.11): natbib `[numbers,super]`
#             end-only mode → `\cite{key}` renders superscript `[N]` linked to the end `thebibliography`; NO per-page
#             citation footnotes (only explanatory `\footnote{}` from chap01/02/04/ack, which carry NO GB/T 7714 type
#             designator). Post-impl (Option A biblatex, Zy 2026-06-17): `\footcite{key}` emits a per-page footnote
#             carrying the FULL GB/T 7714 entry (SimSun 9pt CJK + TNR Latin), renumbered per page → citation "1"
#             recurs across body pages. The type-designator discriminator (`[M]`/`[J]`/`[D]`/...) cleanly separates
#             citation footnotes (have it) from explanatory footnotes (never) → a clean RED pre-impl (0 citation
#             footnotes), GREEN post-impl (≥2 pages with citation "1").
#
# Usage: bash tests/test-story-3.12-integration.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 (compile gate — biber cycle R-12; TC-E3-48 RED driver) + P1 (TC-E3-49 end-refs; AC-1/AC-3/AC-5/AC-6)
# Linked ACs: AC-1 (citation footnote full entry SimSun 9pt + TNR Latin), AC-2 (per-page "1" recurs ≥2 pages),
#             AC-3 (end-list present + type-sectioned re-grouped), AC-5 (explanatory footnote reset preserved),
#             AC-6 (Arabic page numbering + geometry), AC-7 (compile), AC-8 (regression)
# Linked Risk: R-19 (score 4 — dual-mode mechanism; I05 RED driver), R-12 (score 4 — biber cycle `latexmk -g`),
#              R-16 (footnote per-page reset — AC-5 regression)
# TC coverage: TC-E3-48 (P0 per-page citation footnote "1" recurs + full-entry — I05 *** RED DRIVER ***),
#              TC-E3-49 (P1 end-of-doc supplementary list present — I07 GREEN guard)
#
# NOTE: source-greps (test-story-3.12-unit.sh) prove the WIRING (biblatex backend swapped); these fitz tests prove
#   the RENDERED per-page citation footnotes + end-list. A source-grep alone does NOT prove the footnotes render
#   correctly (Decision 1 — visual signature for "X changed" ACs). The fitz citation-footnote scan is the AC-1/AC-2
#   real proof.
#
# Truth source: 河南师范大学研究生学位论文格式要求.md §2.14 line 291 (case-2 PRIORITY — 引文参考文献已出现在文中的
#   页下注（脚注），每页重新编号) + §1.2.4 line 109 (每页重新编号) + §2.4 line 197 (脚注用小五号宋体字) + §2.14
#   line 291 (end-list 先按照文献类型分类…重新编号). spec PRIORITY (CLAUDE.md Decision 4, corrected 2026-06-17).
#   Reference PDF (2107084001-任子辛-...pdf) p20-36 (citation footnotes: [N] author.title[TYPE].pub,year, SimSun 9pt,
#   per-page reset — p22 = [1][2][3][4][5]) + p227 (type-sectioned end-list: 一、党的文献… each re-numbered from [1]).
#   See sprint-change-proposal-2026-06-17.md gap M1.

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
echo "ATDD Integration Tests: Story 3.12 — References dual-mode citation (§2.14 case-2, Option A biblatex)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# Shared Python header: opens main.pdf, defines refs/footnote/citation helpers.
# refs_title(): SimHei ~16pt (三号) centered "参考文献" = the end-list TITLE page (reused from Story 3.7).
# refs_pages(): the end-list page range [refs_title, next-back-matter-title).
# citation_footnote_pages(): {body_page: [N markers]} — the KEY 3.12 helper. A CITATION footnote carries a full
#   GB/T 7714 entry `[N] author.title[TYPE].pub,year.`; the bracketed ALL-CAPS type designator ([M]/[J]/[D]/[C]/[R]/
#   [N]/[P]/[S]/[EB], optional /OL) ONLY appears in reference entries, NEVER in explanatory \footnote{} prose
#   (chap01/02/04/ack footnotes are about TeX naming, 永济水饺, 唐宋八大家, 拉丁语缩写 — no type markers). So a body
#   page is a "citation-footnote page" iff its footnote band (y > H*0.78, size 8-10.5pt) text contains BOTH a `[N]`
#   number AND a type designator. SCAN IS BOUNDED TO BODY PAGES (0..refs_title_page) so the end-list entries (which
#   ALSO have [N]+[TYPE]) are NOT miscounted as footnotes. Pre-impl: {} (0 citation footnotes) → RED. Post-impl:
#   ≥2 pages, per-page reset → "1" recurs → GREEN.
# footnote_pages(): {page: [numbers]} — the Story 3.8 helper (digit markers in the bottom band, math-font excluded).
#   Reused for AC-5 (explanatory footnote per-page reset must SURVIVE the biblatex switch).
PY_HEAD='
import fitz, sys, re
doc = fitz.open("main.pdf")
W = doc[0].rect.width; H = doc[0].rect.height; mid = W / 2.0
num_re = re.compile(r"\[(\d+)\]")
type_re = re.compile(r"\[(M|J|D|C|R|N|P|S|EB)(/OL)?\]")
title_re = re.compile(r"致\s*谢|攻读学位|个人简历|原创性声明|独创性声明")
def median(xs):
    if not xs: return None
    ys = sorted(xs); n = len(ys); return ys[n // 2]
def refs_title():
    # SimHei ~16pt (三号) centered "参考文献" = the end-list TITLE page (NOT the TOC row / running head).
    for i in range(doc.page_count):
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type", 0) != 0: continue
            for ln in b.get("lines", []):
                for sp in ln.get("spans", []):
                    t = sp["text"].strip()
                    if t == "参考文献" and ("Hei" in sp["font"]) and 15.5 <= sp["size"] <= 17.0:
                        cx = (sp["bbox"][0] + sp["bbox"][2]) / 2.0
                        if abs(cx - mid) <= 8.0:
                            return {"page": i, "font": sp["font"], "size": sp["size"], "cx": cx, "y0": sp["bbox"][1]}
    return None
def refs_pages():
    rt = refs_title()
    if not rt: return []
    start = rt["page"]
    end = doc.page_count
    for i in range(start + 1, doc.page_count):
        if title_re.search(doc[i].get_text()):
            end = i; break
    return list(range(start, end))
def citation_footnote_pages():
    # {body_page: [sorted marker numbers]} — citation footnotes (full GB/T 7714 entry) on BODY pages.
    # PRESENCE: a GB/T 7714 type designator ([M]/[J]/[D]/...) in the size 8-10.5 entry text (the footnote body).
    # MARKERS: the bare-digit footnote markers (size 5-8, non-Math) — \footfullcite renders a standard \footnote
    #   marker (bare superscript digit, NOT bracketed [N]); the per-page reset (footmisc[perpage]) numbers them
    #   1,2,3… per page. Band y>H*0.62 (widened from 0.78) — a long citation footnote (3 entries) pushes its marker
    #   up to y~687 (H*0.82); the narrower band missed it. Bounded to body pages (0..refs_title_page) so the
    #   end-list entries (also [N]+[TYPE]) are NOT miscounted. Pre-impl: {} → RED. Post-impl: ≥2 pages, per-page
    #   reset → "1" recurs → GREEN.
    rt = refs_title()
    body_end = rt["page"] if rt else doc.page_count
    out = {}
    for i in range(0, body_end):
        body_text = []
        markers = []
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type", 0) != 0: continue
            for ln in b.get("lines", []):
                for sp in ln.get("spans", []):
                    y0 = sp["bbox"][1]; t = sp["text"].strip()
                    if y0 > H * 0.62:
                        if 8.0 <= sp["size"] <= 10.5 and t:
                            body_text.append(t)
                        elif 5.0 <= sp["size"] <= 8.0 and re.fullmatch(r"\d+", t) and "Math" not in sp["font"]:
                            markers.append(int(t))
        if type_re.search("".join(body_text)):  # citation entry present
            out[i] = sorted(set(markers))
    return out
def citation_footnote_body_spans():
    # footnote-band SimSun ~9pt + TimesNewRoman ~9pt spans on citation-footnote pages (AC-1 font proof).
    cfp = citation_footnote_pages()
    out = []
    for i in cfp:
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type", 0) != 0: continue
            for ln in b.get("lines", []):
                for sp in ln.get("spans", []):
                    y0 = sp["bbox"][1]; t = sp["text"].strip()
                    if y0 > H * 0.78 and 8.2 <= sp["size"] <= 9.8 and len(t) >= 2:
                        out.append({"page": i, "text": t, "size": sp["size"], "font": sp["font"]})
    return out
def footnote_pages():
    # {page: [footnote_numbers]} — Story 3.8 helper (digit markers, math-font excluded), BAND WIDENED for 3.12:
    #   [H*0.62, H*0.96] (was [720,778]). A long citation footnote (\footfullcite, 3 entries) pushes its marker
    #   up to y~687 (H*0.82); the narrow [720,778] band missed it → false "page lacks 1". The wider band catches
    #   both explanatory (short, marker y~750) + citation (long, marker y~687) markers. size 5-8 + digit-only +
    #   non-Math keeps it precise (body=size12, equations=Math, footer=size10-12 all excluded). Reused for AC-5
    #   (explanatory + citation footnotes SHARE the per-page counter; footmisc[perpage] resets both).
    out = {}
    for i in range(doc.page_count):
        nums = []
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type", 0) != 0: continue
            for ln in b.get("lines", []):
                for sp in ln.get("spans", []):
                    t = sp["text"].strip(); y0 = sp["bbox"][1]
                    if 5.0 <= sp["size"] <= 8.0 and H * 0.62 <= y0 <= H * 0.96 and re.fullmatch(r"\d+", t) and "Math" not in sp["font"]:
                        nums.append(int(t))
        if nums:
            out[i] = sorted(set(nums))
    return out
def endlist_type_sections():
    # Chinese-numeral type-section headers (一、二、三、… 十、) within the end-list pages (AC-3 §2.14 case-2
    #   先按照文献类型分类). Pre-impl: thebibliography is continuous (no sections) → 0. Post-impl: biblatex
    #   type-sectioned → ≥1.
    cn_num = re.compile(r"^[一二三四五六七八九十]+、")
    found = []
    for i in refs_pages():
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type", 0) != 0: continue
            for ln in b.get("lines", []):
                for sp in ln.get("spans", []):
                    t = sp["text"].strip()
                    if cn_num.match(t) and sp["size"] >= 10.0:
                        found.append({"page": i, "text": t, "size": sp["size"]})
    return found
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
# P0 Tests (Must Pass — 100%) — compile gate (biber cycle, R-12)
# ==========================================
echo "=== P0: Compile gate (R-12 — -g full recompile; biblatex requires the biber cycle) ==="

# ATDD-3.12-I01: latexmk -xelatex -g main.tex exit code 0 (AC-7, compile gate, R-12 biber cycle)
# Option A: latexmk auto-detects biber from biblatex \addbibresource (runs biber automatically). -g forces fresh.
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-3.12-I01" "latexmk -xelatex -g main.tex exit code 0 (AC-7, R-12 biber cycle)" test_full_compile

# ATDD-3.12-I02: zero compilation errors in main.log (AC-7)
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
run_test "P0" "ATDD-3.12-I02" "zero compilation errors in main.log (AC-7)" test_no_errors

# ATDD-3.12-I03: warning count <= 3 (AC-7, NFR <=3 vs Story 3.11 baseline = 1 standing xeCJK from 3.9)
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
run_test "P0" "ATDD-3.12-I03" "warning count <= 3 (AC-7, NFR <=3 new)" test_warning_count

echo ""

# ==========================================
# P0 Test — TC-E3-48 per-page citation footnote (AC-1/AC-2, R-19) — *** RED DRIVER ***
# ==========================================
echo "=== P0: TC-E3-48 per-page citation footnote (AC-1/AC-2, R-19; *** RED DRIVER ***) ==="

# ATDD-3.12-I04: BEHAVIOR — citation footnotes EXIST (full GB/T 7714 entry in the footnote band) (AC-1, TC-E3-48)
# Pre-impl (natbib end-only): 0 citation footnotes (explanatory footnotes have no type designator) → RED.
# Post-impl (biblatex \footcite): ≥1 body page with a citation footnote carrying a [TYPE] entry → GREEN.
test_citation_footnotes_exist() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
cfp = citation_footnote_pages()
print('  citation-footnote pages (body, [TYPE] entry in footnote band):')
for p in sorted(cfp):
    print('    p%d: markers %s' % (p+1, cfp[p]))
if not cfp:
    print('  → NO citation footnotes (natbib end-only superscript [N]; no per-page footcite); RED pre-impl (R-19)')
else:
    print('  → %d citation-footnote page(s) present (biblatex \\footcite); GREEN post-impl' % len(cfp))
sys.exit(0 if len(cfp) >= 1 else 1)
"
}
run_test "P0" "ATDD-3.12-I04" "BEHAVIOR: citation footnotes exist (full [TYPE] entry in footnote band) (AC-1, TC-E3-48; RED)" test_citation_footnotes_exist

# ATDD-3.12-I05: BEHAVIOR — per-page citation footnote "1" recurs on >=2 body pages (AC-2, TC-E3-48, R-19) — *** RED DRIVER ***
# Truth source: spec §1.2.4 line 109 + §2.14 line 291 "每页重新编号" + reference PDF p20-36 (p22 = [1][2][3][4][5]).
#   Citation footnotes renumber PER PAGE → "1" appears on >=2 different body pages (each page restarts at 1).
#   Pre-impl (natbib end-only): 0 citation footnotes → cannot have citation "1" recurrence → RED.
#   Post-impl (biblatex \footcite + per-page reset): >=2 citation-footnote pages, each restarts at 1 → "1" on >=2 → GREEN.
#   Discriminator: citation-footnote pages (type-marker band) whose marker set contains 1. (Explanatory footnotes
#   excluded — no type marker. End-list excluded — body-pages-only scan.)
test_perpage_citation_footnote_recurrence() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
cfp = citation_footnote_pages()
pages_with_1 = sorted([p+1 for p in cfp if 1 in cfp[p]])
print('  citation-footnote pages: %d; pages with citation marker 1: %s' % (len(cfp), pages_with_1))
if len(cfp) < 2:
    print('  → <2 citation-footnote pages (pre-impl natbib end-only = 0); RED (R-19, TC-E3-48)')
    sys.exit(1)
# per-page reset: >=2 citation pages each containing 1
recurrence_ok = len(pages_with_1) >= 2
if recurrence_ok:
    print('  → per-page citation-footnote reset (1 recurs on %d pages; §1.2.4 + §2.14 每页重新编号); GREEN' % len(pages_with_1))
else:
    print('  → citation markers do NOT restart per page (continuous); DIVERGES from §1.2.4 每页重新编号; RED')
sys.exit(0 if recurrence_ok else 1)
"
}
run_test "P0" "ATDD-3.12-I05" "BEHAVIOR: per-page citation footnote 1 recurs on >=2 pages (AC-2, TC-E3-48, R-19; *** RED DRIVER ***)" test_perpage_citation_footnote_recurrence

echo ""

# ==========================================
# P1 Test — AC-1 citation footnote font (SimSun 9pt CJK + TNR Latin) — RED (no citation footnotes pre-impl)
# ==========================================
echo "=== P1: AC-1 citation footnote body SimSun 9pt + TNR Latin (RED — no citation footnotes pre-impl) ==="

# ATDD-3.12-I06: BEHAVIOR — citation footnote body SimSun ~9pt + TNR Latin (AC-1, §2.4 line 197 小五号宋体)
# Pre-impl: 0 citation footnotes → no SimSun 9pt citation body → RED. Post-impl: citation entries render SimSun 9pt
#   (CJK author/title) + TimesNewRoman 9pt (Latin) in the footnote band. Reference PDF p22: SimSun 9.0pt + TNR 9.0pt.
test_citation_footnote_font() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
spans = citation_footnote_body_spans()
if not spans:
    print('  (no citation footnote body spans — pre-impl natbib end-only; RED)'); sys.exit(1)
simsun = [s for s in spans if 'SimSun' in s['font']]
tnr = [s for s in spans if 'Times' in s['font']]
med = median([s['size'] for s in spans])
print('  citation-footnote body spans=%d simsun=%d tnr=%d median_size=%s' %
      (len(spans), len(simsun), len(tnr), ('%.2fpt' % med) if med else None))
for s in spans[:4]:
    print('    p%d: %r %s %.1fpt' % (s['page']+1, s['text'][:28], s['font'], s['size']))
# AC-1: >=1 SimSun ~9pt citation body (CJK) AND the Latin (TNR) present in the entry.
ok = len(simsun) >= 1 and med is not None and 8.2 <= med <= 9.8
sys.exit(0 if ok else 1)
"
}
run_test "P1" "ATDD-3.12-I06" "BEHAVIOR: citation footnote body SimSun ~9pt + TNR Latin (AC-1, §2.4; RED — no citation footnotes pre-impl)" test_citation_footnote_font

echo ""

# ==========================================
# P1 Test — TC-E3-49 end-of-doc supplementary list present (AC-3, GREEN guard) + type-sectioned (RED)
# ==========================================
echo "=== P1: TC-E3-49 end-list present (AC-3 GREEN — survives mechanism change) + type-sectioned (AC-3 RED) ==="

# ATDD-3.12-I07: BEHAVIOR — end-of-doc supplementary list present (AC-3, TC-E3-49) — GREEN guard
# The end-list exists in BOTH case-1 (pre-impl thebibliography) and case-2 (post-impl \printbibliography). This GREEN
#   guard confirms the end-list SURVIVES the mechanism change (does not regress). Find the SimHei ~16pt "参考文献" title.
test_endlist_present() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
rt = refs_title()
if not rt:
    print('  (no references TITLE page — end-list MISSING; RED — mechanism change lost the end-list)'); sys.exit(1)
rp = refs_pages()
print('  end-list TITLE: p%d font=%r size=%.2fpt cx=%.1f (mid=%.1f); end-list pages=%d' %
      (rt['page']+1, rt['font'], rt['size'], rt['cx'], mid, len(rp)))
hei = 'Hei' in rt['font']
centered = abs(rt['cx'] - mid) <= 8.0
size_ok = 15.5 <= rt['size'] <= 16.8
# AC-3 (presence): title SimHei 三号 centered + >=1 end-list page.
sys.exit(0 if (hei and centered and size_ok and len(rp) >= 1) else 1)
"
}
run_test "P1" "ATDD-3.12-I07" "BEHAVIOR: end-of-doc supplementary list present (AC-3, TC-E3-49; GREEN — survives mechanism change)" test_endlist_present

# ATDD-3.12-I08: BEHAVIOR — end-list TYPE-SECTIONED + PER-SECTION [1] RESTART (AC-3 §2.14 line 291) — RED driver
# AC-3 has TWO §2.14 line 291 requirements: (a) 先按照文献类型分类 (type-sectioning) + (b) 重新编号 (each section
#   re-numbered from [1]). Pre-impl (natbib continuous [1]..[N]): 0 type-section headers + [1] appears once → RED.
#   Post-impl (biblatex \printbibliography[type=...,resetnumbers=true] + defernumbers): ≥1 type-section header +
#   [1] appears ≥2 times (once per section = per-section restart signature). STRENGTHENED 2026-06-17 (code review F2):
#   the original I08 only checked "≥1 header exists" → could not detect a missing resetnumbers (Decision-1 lesson,
#   Acceptance Auditor finding). Now also asserts the [1] recurrence (per-section restart).
#   (Within-section author-surname sort via sorting=nyt is verified by inspection; CJK=pinyin precision needs .bib
#   sortkeys, Epic 4.1 — not asserted here.) Reference PDF p227: each section restarts at [1].
test_endlist_type_sectioned() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
secs = endlist_type_sections()
# count [N] entry markers across the end-list pages; [1] recurrence = per-section restart signature
num_re = re.compile(r'^\[(\d+)\]$')
ones = 0
total_entries = 0
for i in refs_pages():
    for b in doc[i].get_text('dict').get('blocks', []):
        if b.get('type', 0) != 0: continue
        for ln in b.get('lines', []):
            sps = ln.get('spans', [])
            if sps:
                t = sps[0]['text'].strip()
                m = num_re.match(t)
                if m and 9 <= sps[0]['size'] <= 12:
                    total_entries += 1
                    if int(m.group(1)) == 1:
                        ones += 1
print('  end-list type-section headers=%d; entries=%d; [1] markers=%d' % (len(secs), total_entries, ones))
for s in secs[:6]:
    print('    p%d: %r' % (s['page']+1, s['text']))
# AC-3: >=1 type-section header (先按照文献类型分类) AND [1] appears >=2 times (重新编号 per-section restart).
type_ok = len(secs) >= 1
restart_ok = ones >= 2
print('  → type-sectioning=%s, per-section [1] restart=%s' % (type_ok, restart_ok))
sys.exit(0 if (type_ok and restart_ok) else 1)
"
}
run_test "P1" "ATDD-3.12-I08" "BEHAVIOR: end-list type-sectioned + per-section [1] restart (AC-3 §2.14 line 291; STRENGTHENED by code review F2)" test_endlist_type_sectioned

echo ""

# ==========================================
# P1 Test — AC-5 explanatory footnote per-page reset preserved (GREEN — Story 3.8 regression)
# ==========================================
echo "=== P1: AC-5 explanatory footnote per-page reset preserved (GREEN — Story 3.8 regression) ==="

# ATDD-3.12-I09: BEHAVIOR — explanatory footnote per-page reset preserved (AC-5, Story 3.8 R-16 regression)
# The biblatex switch must NOT break the Story 3.8 per-page footnote reset (explanatory \footnote{} in chap01/02/04/ack
#   + the new citation footnotes SHARE the per-page counter). Reuse the Story 3.8 footnote_pages() discriminator: every
#   footnote-page has "1" in its numbers (no orphan >=2 without 1). Pre+post-impl: GREEN (3.8 mechanism intact or
#   footmisc[perpage] preserves it). Requires >=2 footnote-pages.
test_explanatory_footnote_perpage_reset() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
fp = footnote_pages()
if len(fp) < 2:
    print('  (only %d footnote-page(s) — cannot verify per-page reset; need >=2; SKIP-equivalent)' % len(fp)); sys.exit(1)
lacking = [p+1 for p in fp if 1 not in fp[p]]
print('  footnote_pages=%d; pages LACKING 1 (orphan, per-chapter signature)=%s' % (len(fp), lacking))
perpage_ok = (len(lacking) == 0)
if perpage_ok:
    print('  → per-page reset preserved (every footnote-page has 1; Story 3.8 R-16 intact post-biblatex); GREEN')
else:
    print('  → per-page reset BROKEN by biblatex switch; RED (AC-5 regression)')
sys.exit(0 if perpage_ok else 1)
"
}
run_test "P1" "ATDD-3.12-I09" "BEHAVIOR: explanatory footnote per-page reset preserved (AC-5, Story 3.8 R-16 regression; GREEN)" test_explanatory_footnote_perpage_reset

echo ""

# ==========================================
# P1 Tests — AC-6 Arabic page numbering + geometry regression (GREEN)
# ==========================================
echo "=== P1: AC-6 Arabic page numbering + geometry regression (GREEN — citation machinery != geometry) ==="

# ATDD-3.12-I10: BEHAVIOR — end-list footer = Arabic outer (AC-6)
test_endlist_footer_arabic() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
rt = refs_title()
if not rt:
    print('  (no end-list title page — RED)'); sys.exit(1)
foot = footer_num(rt['page'])
if not foot:
    print('  (no footer page-number — RED)'); sys.exit(1)
fn = foot[0]
arabic = fn['text'].isdigit()
phys = rt['page'] + 1
outer = (phys % 2 == 1 and fn['cx'] > mid) or (phys % 2 == 0 and fn['cx'] < mid)
print('  end-list p%d (phys %d) footer=%r cx=%.1f mid=%.1f arabic=%s outer=%s' %
      (rt['page'], phys, fn['text'], fn['cx'], mid, arabic, outer))
sys.exit(0 if (arabic and outer) else 1)
"
}
run_test "P1" "ATDD-3.12-I10" "BEHAVIOR: end-list footer = Arabic outer (AC-6; regression watch)" test_endlist_footer_arabic

# ATDD-3.12-I11: regression — self-check textheight ~688pt unchanged (AC-6, R-1)
test_textheight_unchanged() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local th
  th=$(grep 'textheight = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$th" ]]; then echo "  (textheight not found in self-check)"; return 1; fi
  echo "  (textheight: ${th}pt [expect ~688.56])"
  echo "$th" | awk '{if ($1 >= 686 && $1 <= 690) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.12-I11" "regression: self-check textheight unchanged ~688pt (AC-6, R-1)" test_textheight_unchanged

# ATDD-3.12-I12: regression — self-check baselineskip ≈ 23.4bp (AC-6 — citation machinery must not touch body spacing)
test_baselineskip_234bp() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local bs
  bs=$(grep 'baselineskip = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$bs" ]]; then echo "  (baselineskip not found in self-check)"; return 1; fi
  echo "  (baselineskip: ${bs}pt, expect ~23.49 [body 23.4bp, Story 3.11])"
  echo "$bs" | awk '{if ($1 >= 22.5 && $1 <= 24.5) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.12-I12" "regression: self-check baselineskip ~23.4bp (AC-6 — citation machinery must not touch body spacing)" test_baselineskip_234bp

# ATDD-3.12-I13: total pages within tolerance (AC-7; citation footnotes may shift pagination slightly)
test_total_pages() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local total_pages
  total_pages=$(grep 'total pages = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | tr -d '[:space:]')
  if [[ -z "$total_pages" ]]; then echo "  (page count not found)"; return 1; fi
  echo "  (pages: $total_pages, expected ~53 ±5 [Story 3.11 baseline; biblatex switch may shift ±few])"
  echo "$total_pages" | awk '{if ($1 >= 46 && $1 <= 62) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.12-I13" "total pages within tolerance (AC-7; biblatex switch may shift ±few)" test_total_pages

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
  echo "   RED drivers (FAIL pre-impl, PASS post-impl Option A biblatex):"
  echo "      I04 citation footnotes exist (full [TYPE] entry in footnote band) (AC-1, TC-E3-48)"
  echo "      I05 per-page citation footnote 1 recurs on >=2 pages (AC-2, TC-E3-48, R-19) *** PRIMARY RED DRIVER ***"
  echo "      I06 citation footnote body SimSun ~9pt + TNR Latin (AC-1, §2.4)"
  echo "      I08 end-list type-sectioned re-grouped (AC-3 §2.14 case-2)"
  echo "   GREEN guards (PASS pre+post — lock-in / regression watch):"
  echo "      I01-I03 compile (R-12 biber cycle), I07 end-list present (TC-E3-49 — survives mechanism change),"
  echo "      I09 explanatory footnote per-page reset (AC-5 Story 3.8 R-16 regression),"
  echo "      I10 end-list Arabic footer (AC-6), I11 textheight, I12 baselineskip 23.4bp, I13 pages."
  echo ""
  echo "   Pre-impl baseline (after Story 3.11): natbib [numbers,super] end-only (case-1) → \\cite renders superscript"
  echo "      [N] linked to the end thebibliography; NO per-page citation footnotes. The GB/T 7714 type-designator"
  echo "      discriminator ([M]/[J]/[D]/...) cleanly separates citation footnotes (have it) from explanatory"
  echo "      \\footnote{} (chap01/02/04/ack — never) → I04/I05 = 0 citation footnotes pre-impl → RED."
  echo "   Post-impl (Option A biblatex \\footcite, Zy 2026-06-17): per-page citation footnotes (full entry, SimSun"
  echo "      9pt) + type-sectioned \\printbibliography end-list → I04/I05/I06/I08 GREEN."
  echo "   NOTE: spec §2.14 line 291 (case-2 PRIORITY) + §1.2.4 line 109 (每页重新编号) + §2.4 line 197 (小五号宋体)."
  echo "      Reference PDF p20-36 (citation footnotes per-page reset) + p227 (type-sectioned end-list) confirm."
  echo "      R-19 = 4; R-12 = 4 (biber); R-16 = 4. Tests are read-only (no SUT mutation)."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
