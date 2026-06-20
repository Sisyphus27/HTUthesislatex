#!/usr/bin/env bash
# test-story-3.13-integration.sh — ATDD Integration Tests for Story 3.13 (spec-priority correction pack)
# TDD Phase: RED — the RED driver cluster is AC-3 (humanities heading numbering: I04 chapter 第一章, I06 section 第一节,
#             I07 subsection 一、) + AC-4 (I08 caption half-space, no ：) + AC-5 (I09 KEY WORDS bold). Pre-impl (baseline
#             commit 6a3b2cf, post-Story 3.12 = reference-wins hierarchy): Arabic heading numbering (1/1.1/1.1.1) + caption
#             fullwidth colon ： (Story 3.6) + KEY WORDS non-bold (Story 3.4) + chapter aftername half-space. Post-impl
#             (spec-priority, CLAUDE.md Decision 4 corrected 2026-06-17): humanities 第一章/第一节/一、 + caption half-space
#             (\hspace{0.5\ccwd}) + KEY WORDS bold (BoldMT). The linchpin GREEN guard is I05 (figures stay 图 1-1 Arabic,
#             AC-3a) — it MUST stay GREEN pre+post; RED post-impl = the \thechapter-redefinition disaster (图 一-1).
#
# Usage: bash tests/test-story-3.13-integration.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 (compile gate R-12 + AC-3 humanities RED driver + AC-3a linchpin guard) + P1 (AC-1/4/5 + geometry regression)
# Linked ACs: AC-1 (refs standard hanging 序号左顶格), AC-3 (humanities 第一章/第一节/一、), AC-3a (figures stay 图 1-1 Arabic),
#             AC-4 (caption half-space, no ：), AC-5 (KEY WORDS bold), AC-6 (compile + geometry)
# Linked Risk: R-13-new (score 4 — Chinese display × Arabic float counter; I05 linchpin), R-12 (score 4 — -g recompile),
#              R-cross-story (3 — Decision-2 repoints of 3.4/3.6/3.7/3.12/2.5/2.6)
# TC coverage: TC-E3-51 (refs standard hanging — I10), TC-E3-52 (appendix centered — unit 08, source-level),
#              TC-E3-53 (humanities numbering — I04/I06/I07 + I05 AC-3a sub), TC-E3-54 (caption half-space — I08),
#              TC-E3-23 rework (KEY WORDS bold — I09)
#
# NOTE: source-greps (test-story-3.13-unit.sh) prove the WIRING (ctex humanities, caption \hspace{0.5\ccwd}, \bfseries);
#   these fitz tests prove the RENDERED result. A source-grep alone does NOT prove \thechapter stayed Arabic (Decision 1) —
#   I05 (figures still 图 1-1) is the AC-3a rendered proof.
#
# Truth source: 河南师范大学研究生学位论文格式要求.md §2.8 line 223 (KEY WORDS 加粗) + §2.10 line 239-243 (humanities
#   numbering + 不空格) + §2.11 line 253 / §2.12 line 269 (空半格) + §2.14 line 293 (序号左顶格) + §2.15 line 437 (appendix
#   centered). spec is PRIORITY (CLAUDE.md Decision 4, corrected 2026-06-17). Reference PDF deviates on 4 of 5 (reverse-
#   hanging refs p227, left-aligned appendix, non-bold KEY WORDS p9, fullwidth-colon captions) — all OVERRIDDEN by spec;
#   AGREES on 1 (humanities numbering). See sprint-change-proposal-2026-06-17.md gaps M2/M3/M4/1a/1b.

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

# --- Story 3.15 Red-Phase Gate (wrong-target-AC refactor — G1–G6) ---
# These assertions probe the RENDERED SPAN the spec governs (fitz font/size/position), NOT a code grep or a proxied
# target — the root-cause discipline of the 2026-06-19 spec→code audit (sprint-change-proposal-2026-06-19, 6 residual
# gaps G1–G6; D-22). Isolated from the global SKIP so the existing 575-PASS baseline is preserved while Story 3.15 code
# is pending (sprint-status: backlog). Activate: ATDD_315_SKIP=0 bash tests/test-story-3.13-integration.sh --run
SKIP_315="${ATDD_315_SKIP:-1}"
run_test_315() {
  local priority="$1"; local test_id="$2"; local description="$3"
  if [[ "$SKIP_315" == "1" ]]; then
    yellow "[$priority] $test_id: $description  [Story 3.15 RED-phase]"
    ((SKIP_COUNT++)); return 0
  fi
  shift 3; "$@"
  if [[ $? -eq 0 ]]; then green "[$priority] $test_id: $description"; ((PASS++))
  else red "[$priority] $test_id: $description"; ((FAIL++)); fi
}

echo "=============================================="
echo "ATDD Integration Tests: Story 3.13 — spec-priority correction pack (§2.8/2.10/2.11-2.12/2.14/2.15)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# Shared Python header: opens main.pdf, defines the 3.13 helpers.
# refs_title()/refs_pages(): reused from Stories 3.7/3.12 — SimHei ~16pt (三号) centered "参考文献" = end-list title page.
# body_left_margin(): leftmost body-text span x0 on a mainmatter body page = the text left margin (geometry constant).
# humanities_chapter_count(): 第X章 spans (doc-wide — also appears in TOC + odd-page header post-impl; all prove humanities).
# humanities_section_count(): 第X节 spans (body pages < refs_title_page).
# humanities_subsection_count(): 一、 spans on body pages, size ~14pt (四号 SimHei) — BOUNDED to body pages + size-gated
#   to EXCLUDE the biblatex end-list type-section headers (一、期刊论文 … on refs pages, 小四 12pt, Story 3.12).
# figure_caption_chinese_disaster() / figure_caption_arabic_ok(): 图 [chapter]-[n] caption labels — AC-3a linchpin.
#   Disaster = 图 一-1 (Chinese chapter number from a \thechapter redefinition); OK = 图 1-1 (Arabic, guardrail holds).
# caption_fullwidth_colon_count(): ： (U+FF1A) occurrences in figure/table caption lines — AC-4 (0 post-impl).
# keywords_label_font(): the "KEY WORDS" span font on the English abstract page — AC-5 (Bold post-impl).
# refs_label_x0(): [N] entry label x0 on refs pages vs body_left_margin — AC-1 (序号左顶格 standard hanging).
# footer_num(): page-number span at the page bottom — reused (AC-6 Arabic page numbering).
PY_HEAD='
import fitz, sys, re
doc = fitz.open("main.pdf")
W = doc[0].rect.width; H = doc[0].rect.height; mid = W / 2.0
num_re = re.compile(r"\[(\d+)\]")
title_re = re.compile(r"致\s*谢|攻读学位|个人简历|原创性声明|独创性声明")
chap_cn_re = re.compile(r"第[一二三四五六七八九十百]+章")
sec_cn_re = re.compile(r"第[一二三四五六七八九十百]+节")
sub_cn_re = re.compile(r"^[一二三四五六七八九十]+\、")
fig_label_re = re.compile(r"图\s*([0-9一二三四五六七八九十百]+)[-‐-](\d+)")
tbl_label_re = re.compile(r"表\s*([0-9一二三四五六七八九十百]+)[-‐-](\d+)")
def median(xs):
    if not xs: return None
    ys = sorted(xs); n = len(ys); return ys[n // 2]
def refs_title():
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
    start = rt["page"]; end = doc.page_count
    for i in range(start + 1, doc.page_count):
        if title_re.search(doc[i].get_text()): end = i; break
    return list(range(start, end))
def body_left_margin():
    # leftmost body-text span x0 on a mainmatter body page (size 11.5-12.5pt SimSun, before refs title page).
    rt = refs_title(); upper = rt["page"] if rt else doc.page_count
    xs = []
    for i in range(0, upper):
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type", 0) != 0: continue
            for ln in b.get("lines", []):
                for sp in ln.get("spans", []):
                    t = sp["text"].strip()
                    if 11.5 <= sp["size"] <= 12.5 and "Sun" in sp["font"] and len(t) >= 6 and "Hei" not in sp["font"]:
                        xs.append(sp["bbox"][0])
    return min(xs) if xs else None
def humanities_chapter_count():
    rt = refs_title(); upper = rt["page"] if rt else doc.page_count
    n = 0; samples = []
    for i in range(0, upper):
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type", 0) != 0: continue
            for ln in b.get("lines", []):
                for sp in ln.get("spans", []):
                    if "Hei" in sp["font"] and chap_cn_re.search(sp["text"]):
                        n += 1
                        if len(samples) < 6: samples.append((i+1, sp["text"][:16]))
    return n, samples
def humanities_section_count():
    rt = refs_title(); upper = rt["page"] if rt else doc.page_count
    n = 0; samples = []
    for i in range(0, upper):
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type", 0) != 0: continue
            for ln in b.get("lines", []):
                for sp in ln.get("spans", []):
                    if "Hei" in sp["font"] and sec_cn_re.search(sp["text"]):
                        n += 1
                        if len(samples) < 6: samples.append((i+1, sp["text"][:16]))
    return n, samples
def humanities_subsection_count():
    # 一、 spans on BODY pages (< refs_title), size ~14pt (四号 SimHei) — excludes biblatex end-list type-sections
    # (一、期刊论文 … on refs pages, 12pt 小四). Double-safe: page-bound + size gate.
    rt = refs_title(); upper = rt["page"] if rt else doc.page_count
    n = 0; samples = []
    for i in range(0, upper):
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type", 0) != 0: continue
            for ln in b.get("lines", []):
                for sp in ln.get("spans", []):
                    t = sp["text"].strip()
                    if "Hei" in sp["font"] and 13.5 <= sp["size"] <= 14.8 and sub_cn_re.match(t):
                        n += 1
                        if len(samples) < 6: samples.append((i+1, t[:16], sp["size"]))
    return n, samples
def figure_caption_labels():
    # 图 [chapter]-[n] caption labels — detect Chinese chapter number (disaster 图 一-1) vs Arabic (ok 图 1-1).
    # JOIN the LINE text (fitz splits CJK 图 / digit 4 / hyphen / digit 1 into separate spans — a per-span scan
    #   sees only "图" or "4", never "图4-1", so finds 0). Size gate on the line max (caption 五号 ~10.5pt) excludes
    #   header/footer. Returns (arabic_count, chinese_count, samples).
    arabic = 0; chinese = 0; samples = []
    cn_num = "一二三四五六七八九十百"
    for i in range(doc.page_count):
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type", 0) != 0: continue
            for ln in b.get("lines", []):
                sps = ln.get("spans", [])
                if not sps: continue
                line_text = "".join(s["text"] for s in sps)
                m = re.search(r"图\s*([0-9一二三四五六七八九十百]+)\s*[-‐-]\s*\d", line_text) or \
                    re.search(r"表\s*([0-9一二三四五六七八九十百]+)\s*[-‐-]\s*\d", line_text)
                if m:
                    sz = max(s["size"] for s in sps)
                    if 9.0 <= sz <= 12.5:
                        ch = m.group(1)
                        if ch.isdigit(): arabic += 1
                        elif any(c in ch for c in cn_num): chinese += 1
                        if len(samples) < 8: samples.append((i+1, line_text[:14]))
    return arabic, chinese, samples
def caption_fullwidth_colon_count():
    # ： (U+FF1A) in figure/table caption lines. Caption line = a line whose joined text matches 图N-M / 表N-M.
    n = 0; samples = []
    for i in range(doc.page_count):
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type", 0) != 0: continue
            for ln in b.get("lines", []):
                sps = ln.get("spans", [])
                if not sps: continue
                line_text = "".join(s["text"] for s in sps)
                # [Story 4.1 Decision-2 repoint] exclude TOC/LOT dot-leader entries. Appendix \addcontentsline
                #   entries "附表 N：毕业设计..." (Story 4.1 wired \appendix+app01) legitimately contain ： as
                #   descriptive TITLE text, not a caption separator — they carry dot-leaders (.{4,} / …) which
                #   real float captions never do. Traceability: appendix wiring (Story 4.1) surfaced this
                #   over-broad match; spec §2.11/2.12 caption separator = half-space, unaffected.
                if re.search(r"图\s*\d|表\s*\d", line_text) and "：" in line_text and not re.search(r"\.{4,}|…", line_text):
                    n += line_text.count("：")
                    if len(samples) < 6: samples.append((i+1, line_text[:24]))
    return n, samples
def keywords_label_font():
    # the "KEY WORDS" span on the English abstract page. Returns font string or None.
    for i in range(doc.page_count):
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type", 0) != 0: continue
            for ln in b.get("lines", []):
                for sp in ln.get("spans", []):
                    t = sp["text"].strip()
                    if t.startswith("KEY WORDS") and 9.5 <= sp["size"] <= 11.5:
                        return {"page": i, "text": t, "font": sp["font"], "size": sp["size"]}
    return None
def refs_label_x0():
    # [N] entry label x0 on refs pages (standard 序号左顶格 = flush-left ≈ body_left_margin). Returns (min_x0, all_x0).
    rp = refs_pages()
    x0s = []
    for i in rp:
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type", 0) != 0: continue
            for ln in b.get("lines", []):
                sps = ln.get("spans", [])
                if sps:
                    t = sps[0]["text"].strip()
                    if num_re.fullmatch(t) and 9 <= sps[0]["size"] <= 12:
                        x0s.append(sps[0]["bbox"][0])
    return (min(x0s) if x0s else None), x0s
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
# P0 Tests (Must Pass — 100%) — compile gate (R-12 full recompile)
# ==========================================
echo "=== P0: Compile gate (R-12 — -g full recompile; numbering/caption/bib need fresh .aux/.toc/.bbl) ==="

# ATDD-3.13-I01: latexmk -xelatex -g main.tex exit code 0 (AC-6, compile gate, R-12)
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-3.13-I01" "latexmk -xelatex -g main.tex exit code 0 (AC-6, R-12 full recompile)" test_full_compile

# ATDD-3.13-I02: zero compilation errors in main.log (AC-6)
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
run_test "P0" "ATDD-3.13-I02" "zero compilation errors in main.log (AC-6)" test_no_errors

# ATDD-3.13-I03: warning count <= 3 (AC-6, NFR <=3 vs Story 3.12 baseline = 1 standing xeCJK from 3.9)
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
run_test "P0" "ATDD-3.13-I03" "warning count <= 3 (AC-6, NFR <=3 new)" test_warning_count

echo ""

# ==========================================
# P0 Test — AC-3 humanities chapter numbering (RED driver) + AC-3a figure-counter linchpin (GREEN guard)
# ==========================================
echo "=== P0: AC-3 humanities chapter (RED driver) + AC-3a figures-stay-Arabic (GREEN linchpin guard) ==="

# ATDD-3.13-I04: BEHAVIOR — chapter titles render humanities 第一章/第二章 (Chinese, not Arabic) (AC-3, TC-E3-53)
# Pre-impl (Arabic name=\relax): 0 第X章 spans → RED. Post-impl (name={第,章} number=\chinese): ≥1 (chap01 第一章 …) → GREEN.
test_chapter_humanities_rendered() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
n, samples = humanities_chapter_count()
print('  humanities 第X章 spans (body+TOC+header): %d' % n)
for p, t in samples:
    print('    p%d: %r' % (p, t))
if n < 1:
    print('  → 0 第X章 (pre-impl Arabic 1/2); RED (AC-3, TC-E3-53)')
    sys.exit(1)
print('  → %d humanities chapter marker(s) (第一章…); GREEN (AC-3 §2.10)' % n)
sys.exit(0)
"
}
run_test "P0" "ATDD-3.13-I04" "BEHAVIOR: chapter titles render humanities 第一章 (Chinese) (AC-3, TC-E3-53; *** RED DRIVER ***)" test_chapter_humanities_rendered

# ATDD-3.13-I05: BEHAVIOR — figure captions STILL render 图 1-1 (Arabic, NOT 图 一-1) (AC-3a linchpin, TC-E3-53 sub)
# GREEN guard pre+post — the \thechapter-redefinition disaster would render 图 一-1 (Chinese chapter) → this catches it.
# Pre-impl: 图 1-1 Arabic (GREEN). Post-impl: MUST stay 图 1-1 Arabic (guardrail holds). RED post-impl = disaster.
test_figures_arabic_linchpin() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
arabic, chinese, samples = figure_caption_labels()
print('  figure/table caption labels: arabic_chapter=%d chinese_chapter=%d' % (arabic, chinese))
for p, t in samples:
    print('    p%d: %r' % (p, t))
if chinese > 0:
    print('  → DISASTER: %d caption(s) with CHINESE chapter number (图 一-1) — \\thechapter redefined; RED (AC-3a broken)' % chinese)
    sys.exit(1)
if arabic < 1:
    print('  → no figure captions found to verify (sample-data); inconclusive — flag for chap04 figures')
    sys.exit(1)
print('  → %d caption(s) with ARABIC chapter number (图 1-1); \\thechapter stayed \\arabic; GREEN (AC-3a guardrail holds)' % arabic)
sys.exit(0)
"
}
run_test "P0" "ATDD-3.13-I05" "BEHAVIOR: figure captions stay 图 1-1 Arabic (AC-3a linchpin; GREEN — RED = \\thechapter disaster 图 一-1)" test_figures_arabic_linchpin

echo ""

# ==========================================
# P1 Tests — AC-3 section/subsection humanities (RED drivers)
# ==========================================
echo "=== P1: AC-3 section 第一节 + subsection 一、 humanities (RED drivers) ==="

# ATDD-3.13-I06: BEHAVIOR — section titles render 第一节 (Chinese) (AC-3, TC-E3-53)
# Pre-impl (Arabic 1.1): 0 第X节 → RED. Post-impl: ≥1 (chap02/03/04 sections) → GREEN.
test_section_humanities_rendered() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
n, samples = humanities_section_count()
print('  humanities 第X节 spans (body pages): %d' % n)
for p, t in samples:
    print('    p%d: %r' % (p, t))
if n < 1:
    print('  → 0 第X节 (pre-impl Arabic 1.1); RED (AC-3, TC-E3-53)')
    sys.exit(1)
print('  → %d humanities section marker(s) (第一节…); GREEN (AC-3 §2.10)' % n)
sys.exit(0)
"
}
run_test "P1" "ATDD-3.13-I06" "BEHAVIOR: section titles render 第一节 (Chinese) (AC-3, TC-E3-53; RED)" test_section_humanities_rendered

# ATDD-3.13-I07: BEHAVIOR — subsection titles render 一、 (Chinese) (AC-3, TC-E3-53)
# Pre-impl (Arabic 1.1.1): 0 一、 on body pages at ~14pt → RED. Post-impl: ≥1 (chap04 subsections) → GREEN.
# Body-bound + 14pt size gate EXCLUDES the biblatex end-list type-sections (一、期刊论文 on refs pages, 12pt).
test_subsection_humanities_rendered() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
n, samples = humanities_subsection_count()
print('  humanities 一、 subsection spans (body, ~14pt SimHei): %d' % n)
for p, t, sz in samples:
    print('    p%d: %r (%.1fpt)' % (p, t, sz))
if n < 1:
    print('  → 0 一、 subsection (pre-impl Arabic 1.1.1); RED (AC-3, TC-E3-53)')
    sys.exit(1)
print('  → %d humanities subsection marker(s) (一、…); GREEN (AC-3 §2.10)' % n)
sys.exit(0)
"
}
run_test "P1" "ATDD-3.13-I07" "BEHAVIOR: subsection titles render 一、 (Chinese) (AC-3, TC-E3-53; RED)" test_subsection_humanities_rendered

echo ""

# ==========================================
# P1 Tests — AC-4 caption half-space (RED) + AC-5 KEY WORDS bold (RED)
# ==========================================
echo "=== P1: AC-4 caption half-space no-colon (RED) + AC-5 KEY WORDS bold (RED) ==="

# ATDD-3.13-I08: BEHAVIOR — caption separator = half-space, NO fullwidth colon ： (AC-4, TC-E3-54)
# Pre-impl (Story 3.6 fullwidth colon DeclareCaptionLabelSeparator{htu}{：}) ： present in caption lines → RED.
# Post-impl (\hspace{0.5\ccwd}) ： absent → GREEN.
test_caption_halfspace_rendered() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
n, samples = caption_fullwidth_colon_count()
print('  fullwidth ： in figure/table caption lines: %d' % n)
for p, t in samples:
    print('    p%d: %r' % (p, t))
if n > 0:
    print('  → %d caption(s) with fullwidth ： (pre-impl Story 3.6 colon); RED (AC-4, TC-E3-54)' % n)
    sys.exit(1)
print('  → 0 fullwidth ： in captions (half-space separator); GREEN (AC-4 §2.11/2.12 空半格)')
sys.exit(0)
"
}
run_test "P1" "ATDD-3.13-I08" "BEHAVIOR: caption separator half-space, NO fullwidth ： (AC-4, TC-E3-54; RED — pre-impl ：)" test_caption_halfspace_rendered

# ATDD-3.13-I09: BEHAVIOR — KEY WORDS label bold (TimesNewRomanPS-BoldMT) (AC-5, TC-E3-23 rework)
# Pre-impl (Story 3.4 non-bold): KEY WORDS span = TimesNewRomanPSMT → RED. Post-impl (\bfseries): BoldMT → GREEN.
test_keywords_bold_rendered() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
kw = keywords_label_font()
if not kw:
    print('  (no KEY WORDS label span found — English abstract page?); RED'); sys.exit(1)
bold = 'Bold' in kw['font']
print('  KEY WORDS label: p%d font=%r size=%.2fpt bold=%s' % (kw['page']+1, kw['font'], kw['size'], bold))
if not bold:
    print('  → KEY WORDS label NON-bold (pre-impl Story 3.4 PSMT); RED (AC-5, TC-E3-23 rework, §2.8 加粗)')
    sys.exit(1)
print('  → KEY WORDS label BOLD (BoldMT); GREEN (AC-5 §2.8 加粗)')
sys.exit(0)
"
}
run_test "P1" "ATDD-3.13-I09" "BEHAVIOR: KEY WORDS label bold (BoldMT) (AC-5, TC-E3-23 rework, §2.8; RED — pre-impl non-bold)" test_keywords_bold_rendered

echo ""

# ==========================================
# P1 Test — AC-1 references standard hanging 序号左顶格 (RED-or-GREEN per story R-new verify-only framing)
# ==========================================
echo "=== P1: AC-1 references standard hanging 序号左顶格 (RED if reverse; GREEN if gb7714 default already standard) ==="

# ATDD-3.13-I10: BEHAVIOR — references standard hanging [N] flush-left (序号左顶格) (AC-1, TC-E3-51)
# spec §2.14 line 293: 序号左顶格 (label flush-left at margin, continuation wraps right = standard hanging).
# Honest framing (story R-new): biblatex gb7714-2015 default MAY already be standard → GREEN pre-impl (verify-only);
#   if reverse/indented → RED. The test asserts the spec-correct state (flush-left) either way.
# Discriminator: [N] entry label min x0 ≈ body_left_margin (flush-left). Reverse-hanging = [N] x0 > margin by ~2\ccwd.
test_refs_standard_hanging() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
min_x0, x0s = refs_label_x0()
blm = body_left_margin()
print('  refs [N] label min x0=%s; body_left_margin=%s; count=%d' %
      ('%.1f' % min_x0 if min_x0 is not None else None, '%.1f' % blm if blm is not None else None, len(x0s)))
if min_x0 is None or blm is None or len(x0s) < 2:
    print('  (insufficient refs entries / body margin to verify; sample); inconclusive'); sys.exit(1)
delta = min_x0 - blm
print('  [N] flush-left delta = %.1fpt (0 = flush 序号左顶格; +24 = reverse-hanging, indented ~2ccwd)' % delta)
# standard 序号左顶格: [N] flush at margin (|delta| <= 8pt). reverse: delta > ~16pt (2\ccwd ~21pt at 五号).
if abs(delta) <= 10.0:
    print('  → refs standard hanging 序号左顶格 ([N] flush-left); GREEN (AC-1 §2.14 line 293)')
    sys.exit(0)
print('  → refs NOT flush-left (delta=%.1fpt; reverse-hanging or non-standard); RED (AC-1 §2.14 序号左顶格)' % delta)
sys.exit(1)
"
}
run_test "P1" "ATDD-3.13-I10" "BEHAVIOR: references standard hanging [N] flush-left 序号左顶格 (AC-1, TC-E3-51; RED if reverse)" test_refs_standard_hanging

echo ""

# ==========================================
# P1 Tests — AC-6 geometry regression (GREEN — numbering/caption/bib ≠ body/geometry)
# ==========================================
echo "=== P1: AC-6 geometry regression (GREEN — numbering/caption/bib != geometry/body spacing) ==="

# ATDD-3.13-I11: regression — self-check textheight ~688pt unchanged (AC-6, R-1)
test_textheight_unchanged() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local th
  th=$(grep 'textheight = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$th" ]]; then echo "  (textheight not found in self-check)"; return 1; fi
  echo "  (textheight: ${th}pt [expect ~688.56])"
  echo "$th" | awk '{if ($1 >= 686 && $1 <= 690) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.13-I11" "regression: self-check textheight unchanged ~688pt (AC-6, R-1)" test_textheight_unchanged

# ATDD-3.13-I12: regression — self-check baselineskip ≈ 23.4bp (AC-6 — numbering/caption/bib must not touch body spacing)
test_baselineskip_234bp() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local bs
  bs=$(grep 'baselineskip = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$bs" ]]; then echo "  (baselineskip not found in self-check)"; return 1; fi
  echo "  (baselineskip: ${bs}pt, expect ~23.49 [body 23.4bp, Story 3.11])"
  echo "$bs" | awk '{if ($1 >= 22.5 && $1 <= 24.5) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.13-I12" "regression: self-check baselineskip ~23.4bp (AC-6 — must not touch body spacing)" test_baselineskip_234bp

# ATDD-3.13-I13: total pages within tolerance (AC-6; humanities numbering width + caption separator may shift ±few)
test_total_pages() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local total_pages
  total_pages=$(grep 'total pages = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | tr -d '[:space:]')
  if [[ -z "$total_pages" ]]; then echo "  (page count not found)"; return 1; fi
  echo "  (pages: $total_pages, expected 40-62 [re-anchored by Story 3.14: → 44 pp; was [46,62]])"
  echo "$total_pages" | awk '{if ($1 >= 40 && $1 <= 62) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.13-I13" "total pages within tolerance (AC-6; humanities/caption may shift ±few)" test_total_pages

echo ""

# ==========================================
# Story 3.15 Red-Phase — G3 numbering=sc dual-mode (§2.10, TC-E3-63)
# ==========================================
echo "=== Story 3.15 RED: G3 numbering=sc renders NS chapter 1/2 (not 第一章) (§2.10; RED pre-impl — no option) ==="

# ATDD-3.13-I14 (Story 3.15): BEHAVIOR — numbering=sc renders natural-science chapter numbering (G3, TC-E3-63)
# WRONG-TARGET-AC root cause: the AC-3 linchpin (I04/I06/I07) tests ONLY the default hs mode (第一章/第一节/一、). The
#   2026-06-19 audit's G3 gap: Story 3.13 DELETED the natural-science (NS) path that spec §2.10 line 235 lists as the
#   PRIMARY numbering ("1、1.1、1.1.1"). G3 restores it as a `numbering=sc|hs` cls option (default hs). This test proves
#   BOTH modes by compiling a temp numbering=sc variant + asserting NS Arabic chapter headings render (1/2) AND no
#   humanities 第一章. Pre-impl: cls has no numbering= option → temp compile ERRORS (unknown option) → RED.
#   Post-impl: option accepted + chapter renders Arabic 1/2 → GREEN.
# NOTE: temp .atdd-315-sc.tex is a sed-modified copy of main.tex (documentclass [doctor,numbering=sc]); same dir so
#   \include paths resolve. Isolated jobname; removed after. NOT a SUT edit (cls/def/main/data untouched). \include
#   aux files (data/chap*.aux) are shared with main — this is an isolated red-phase run; main's next -g rebuild
#   restores them. Slow (~3 min full compile) — red-phase only (ATDD_315_SKIP=0 ... --run).
test_numbering_sc_renders_ns() {
  [[ -f "htuthesis.cls" && -f "main.tex" ]] || return 1
  sed 's/\\documentclass\[doctor\]{htuthesis}/\\documentclass[doctor,numbering=sc]{htuthesis}/' main.tex > .atdd-315-sc.tex
  latexmk -xelatex -g -interaction=nonstopmode .atdd-315-sc.tex > /dev/null 2>&1
  local rc=$?
  if [[ $rc -ne 0 ]]; then
    rm -f .atdd-315-sc.* 2>/dev/null
    echo "  (numbering=sc compile FAILED rc=$rc — option not implemented; RED pre-impl)"
    return 1
  fi
  python -c "
import fitz, sys, re
d = fitz.open('.atdd-315-sc.pdf')
chap_cn = re.compile(r'第[一二三四五六七八九十百]+章')
ns_arabic = 0; hs_cn = 0
for i in range(min(d.page_count, 20)):
    for b in d[i].get_text('dict').get('blocks', []):
        if b.get('type', 0) != 0: continue
        for ln in b.get('lines', []):
            for sp in ln.get('spans', []):
                t = sp['text'].strip()
                if sp['size'] > 14:
                    # REPPOINTED (Story 3.15 G6): NS Arabic chapter digit「1/2…」is LATIN → renders TNR (not SimHei) per G6
                    #   Latin-TNR fix. Dropped the prior 'Hei' in font gate (it excluded the TNR digit → false 0). Detect by
                    #   heading-size + leading Arabic digit (lone or followed by non-digit/title). HS = 第N章 (CJK SimHei).
                    if re.match(r'^[1-9](\D|$)', t):
                        ns_arabic += 1
                    if chap_cn.search(t):
                        hs_cn += 1
print('  numbering=sc PDF: NS-arabic-chapter=%d HS-cjk-chapter=%d' % (ns_arabic, hs_cn))
# G3 GREEN: sc mode → ≥1 Arabic chapter AND no 第一章 humanities.
sys.exit(0 if (ns_arabic >= 1 and hs_cn == 0) else 1)
" 2>/dev/null
  local prc=$?
  rm -f .atdd-315-sc.* 2>/dev/null
  return $prc
}
run_test_315 "P1" "ATDD-3.13-I14" "BEHAVIOR: numbering=sc renders NS chapter 1/2 not 第一章 (G3, TC-E3-63, §2.10; RED pre-impl — no numbering= option)" test_numbering_sc_renders_ns

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
  echo "   RED drivers (FAIL pre-impl reference-wins, PASS post-impl spec-priority):"
  echo "      I04 chapter titles render humanities 第一章 (AC-3, TC-E3-53) *** PRIMARY RED DRIVER ***"
  echo "      I06 section titles render 第一节 (AC-3, TC-E3-53)"
  echo "      I07 subsection titles render 一、 (AC-3, TC-E3-53)"
  echo "      I08 caption half-space, NO fullwidth ： (AC-4, TC-E3-54)"
  echo "      I09 KEY WORDS label bold BoldMT (AC-5, TC-E3-23 rework)"
  echo "      I10 refs standard hanging 序号左顶格 (AC-1, TC-E3-51; RED if reverse, GREEN if gb7714 default)"
  echo "   GREEN guards (PASS pre+post — compile / AC-3a linchpin / geometry):"
  echo "      I01-I03 compile (R-12 -g recompile), I05 figures stay 图 1-1 (AC-3a linchpin — RED = \\thechapter disaster),"
  echo "      I11 textheight, I12 baselineskip 23.4bp, I13 pages."
  echo ""
  echo "   Pre-impl baseline (commit 6a3b2cf, post-Story 3.12 = reference-wins): Arabic heading numbering (1/1.1/1.1.1) +"
  echo "      caption ： (Story 3.6) + KEY WORDS non-bold (Story 3.4). The 5 RED drivers FAIL pre-impl (Arabic/colon/"
  echo "      non-bold). Post-impl (spec-priority humanities + half-space + bold + 序号左顶格) → GREEN."
  echo "   NOTE: the linchpin guard I05 (figures stay 图 1-1) is the AC-3a rendered proof (Decision 1) — a source-grep"
  echo "      (ctex humanities wired) does NOT prove \\thechapter stayed Arabic; only the fitz 图 1-1 vs 图 一-1 check does."
  echo "      spec §2.8 (KEY WORDS 加粗) + §2.10 (humanities) + §2.11/2.12 (空半格) + §2.14 line 293 (序号左顶格) + §2.15 (附录居中)."
  echo "      R-13-new = 4 (AC-3a); R-12 = 4 (-g recompile). Reference PDF deviates on 4 of 5 — OVERRIDDEN by spec."
  echo "      Tests are read-only (no SUT mutation). chap02/03/04 numbered \\section/\\subsection exercise I06/I07."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
