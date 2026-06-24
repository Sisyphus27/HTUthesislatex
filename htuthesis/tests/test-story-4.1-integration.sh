#!/usr/bin/env bash
# test-story-4.1-integration.sh — ATDD Integration (rendered) Tests for Story 4.1 (complete example thesis with sample content)
# TDD Phase: RED — the RED driver cluster is I04 (appendix body 小四宋体 first-render — G5a), I05 (appendix counter
#             图A-1/表A-1/（A-1） first-render — G5b; app01-03 zero floats pre), I06 (full content cover→declaration incl
#             appendix), I09 (appendix env font-restore — no 小四宋体 leak into ack/declaration). Pre-impl (baseline
#             commit ed20363, post-Epic-3-retro): main.tex has NO \appendix → appendix region unrenderable → G5a/G5b
#             unprovable. Post-impl (spec §2.15 line 439 PRIORITY): appendix renders 小四宋体 + 图A-1 + full content.
#             GREEN guards I01-03 (compile gate R-12), I07 (cross-refs), I08 (bibliography [N]) PASS pre+post.
#             GREEN-leaning I10/I11 (numbering=sc — 3.15-I09 already proved sc compiles + NS renders; 4.1 extends to
#             full content + appendix-under-sc regression). P2 I12 (sc subsubsection L4 — verify-then-decide).
#
# Usage: bash tests/test-story-4.1-integration.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 (compile gate + G5a/G5b/appendix RED drivers) + P1 (font-restore + cross-refs + bibliography + sc regression)
# Linked ACs: AC-1 (compile gate), AC-2 (appendix body 小四宋体, §2.15), AC-3 (appendix counter 图A-1, §2.11/2.12/2.13),
#             AC-4 (numbering=sc renders NS, §2.10), AC-5 (full content + cross-refs), AC-6 (bibliography), AC-8 (no regression)
# Linked Risk: R-23 (score 6 — appendix first-compile; I04/I05/I09 are the G5a/G5b/font-restore first-proofs), R-12 (4, -g recompile),
#              R-22 (4, sc both-mode regression), R-25 (4, wrong-target-AC — every probe is rendered-span)
# TC coverage: TC-E4-01 (I01-03), TC-E4-02 (I04), TC-E4-03 (I05), TC-E4-04 (I10), TC-E4-05 (I06), TC-E4-06 (I07),
#              TC-E4-07 (I08), TC-E4-08 (I09), TC-E4-09 (I11), TC-E4-10 (I12)
#
# NOTE: every RED driver probes the RENDERED SPAN the spec governs (fitz get_text('dict') font/size/position + rendered-text
#   regex), NOT a code grep or proxied target — the wrong-target-AC root-cause discipline (Epic 3 retro Lesson 3;
#   architecture silent-failure #13/#14; TC-E4-36 suite audit). appendix body font = rendered span font-name/size (not
#   \the\baselineskip); appendix counter = rendered-text regex 图A-1 (not \thefigure source); sc numbering = rendered heading
#   text (not \ctexset source).
#
# RED/GREEN reconciliation (3.15 → 4.1): Story 3.15-I09 ALREADY proved numbering=sc compiles + renders NS 1/2 (3.15 is
#   done). So I10/I11 are GREEN-leaning full-content regression guards, NOT first-compile RED drivers. The genuinely NEW
#   unverified paths are the appendix cluster (I04/I05/I06/I09) — appendix has zero floats + main.tex has no \appendix
#   at baseline ed20363. R-23 residual sc concerns (L4 subsubsection) = P2 verify-then-decide (I12).
#
# Truth source: 河南师范大学研究生学位论文格式要求.md §2.15 line 439 (appendix 小四宋体) + §2.11/2.12/2.13 (counter form) +
#   §2.10 line 235-237 (numbering) + §2.14 (references) + §2.16/2.17 (ack/resume) + §1.1 (declaration). spec PRIORITY.

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
echo "ATDD Integration Tests: Story 4.1 — complete example thesis with sample content (§2.15 appendix + §2.10 numbering)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# Shared Python header: opens main.pdf, locates cover/TOC/eabstract/appendix/ack/declaration pages by signature.
#   appendix = first page with "附录 A/B/C" (\@chapapp under \appendix); ack = 致谢; declaration = 独创性声明.
#   spans_band(pno, lo, hi) = size-filtered spans; is_song(f) / is_hei(f) / is_lm(f) = font classifiers.
PY_HEAD='
import fitz, sys, re
doc = fitz.open("main.pdf")
W = doc[0].rect.width; H = doc[0].rect.height; mid = W / 2.0
cover = None
for i in range(min(6, doc.page_count)):
    t = doc[i].get_text()
    if "博士学位论文" in t and "摘要" not in t:
        cover = i; break
toc = None
for i in range(min(16, doc.page_count)):
    t = doc[i].get_text()
    if re.search(r"目\s*录", t):
        toc = i; break
eabstract = None
for i in range(min(16, doc.page_count)):
    t = doc[i].get_text()
    if "ABSTRACT" in t or "Abstract" in t:
        eabstract = i; break
appendix = None
for i in range(min(doc.page_count, 60)):
    t = doc[i].get_text()
    # [Review patch 2026-06-20] exclude TOC/LOF/LOT pages — the TOC lists "附录A" WITH dot-leaders,
    #   so the raw "附录\s*[A-Z]" match grabbed TOC p7 instead of the real appendix body. Anchor on
    #   the body page (no dot-leaders, not a 目录/清单 title page). Wrong-target-AC fix (Epic 3 retro L3).
    if re.search(r"\.{4,}|…", t) or "目录" in t[:24] or "插图清单" in t or "表格清单" in t:
        continue
    if re.search(r"附录\s*[A-Z]", t):
        appendix = i; break
ack = None
# [Review patch 2026-06-20] order-anchored: ack follows appendix in backmatter (spec §1.1: refs→appendix→ack→
#   resume→declaration). Content heuristics alone were insufficient — chap03 demo pages mid-body mention
#   "致谢"/"独创性声明" in verbatim template-usage examples (no dot-leader, no "include{data/"). Anchoring
#   the scan AFTER the appendix page skips those body demo pages. Fallback: if appendix not found (RED
#   phase, unwired), scan from 0 — test is in SKIP mode then anyway.
_ack_start = (appendix + 1) if appendix is not None else 0
for i in range(_ack_start, min(doc.page_count, 90)):
    t = doc[i].get_text()
    if "include{data/" in t or re.search(r"\.{4,}|…", t):
        continue
    if "致谢" in t:
        ack = i; break
declaration = None
# [Review patch 2026-06-20] order-anchored: declaration follows ack. Scan after ack page.
_decl_start = (ack + 1) if ack is not None else _ack_start
for i in range(_decl_start, min(doc.page_count, 100)):
    t = doc[i].get_text()
    if re.search(r"\.{4,}|…", t) or "目录" in t[:24]:
        continue
    if "独创性声明" in t or "原创性声明" in t:
        declaration = i; break
def spans_band(pno, lo, hi):
    out = []
    if pno is None or pno >= doc.page_count: return out
    for b in doc[pno].get_text("dict").get("blocks", []):
        if b.get("type", 0) != 0: continue
        for ln in b.get("lines", []):
            for sp in ln.get("spans", []):
                if lo <= sp["size"] <= hi:
                    out.append(sp)
    return out
def is_song(f):
    return ("SimSun" in f) or ("Song" in f) or ("宋" in f)
def is_hei(f):
    return ("SimHei" in f) or ("Hei" in f)
def is_lm(f):
    return ("LMSans" in f) or ("LMRoman" in f) or ("Latin Modern" in f)
'

# ==========================================
# P0 — Compile gate (R-12 full recompile; appendix wiring + counter regenerate .toc/.aux/.lof/.lot)
# ==========================================
echo "=== P0: Compile gate (R-12 — -g full recompile; appendix wiring regenerates TOC/LOF/LOT/aux) ==="

# ATDD-4.1-I01: latexmk -xelatex -g main.tex exit 0 (AC-1, compile gate, R-12 — full recompile after appendix/counter wiring)
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-4.1-I01" "latexmk -xelatex -g main.tex exit code 0 (AC-1, R-12 full recompile)" test_full_compile

# ATDD-4.1-I02: zero compilation errors in main.log (AC-1)
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
run_test "P0" "ATDD-4.1-I02" "zero compilation errors in main.log (AC-1)" test_no_errors

# ATDD-4.1-I03: warning count <= 3 (AC-1, NFR ≤3 new vs Epic 3 baseline = benign hyperref)
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
run_test "P0" "ATDD-4.1-I03" "warning count <= 3 (AC-1, NFR ≤3 new vs Epic 3 baseline)" test_warning_count

echo ""

# ==========================================
# P0 — G5a appendix body = 小四宋体 (TC-E4-02; first-render proof)
# ==========================================
echo "=== P0: G5a appendix body 小四宋体 rendered (TC-E4-02, §2.15 line 439) ==="

# ATDD-4.1-I04: BEHAVIOR — appendix body text renders in 小四 SimSun (12bp). Wrong-target-AC discipline: probe the
#   RENDERED span font-name/size, not \the\baselineskip or a source grep. Appendix env BEGIN sets \xiaosi\songti
#   (cls:1026, Story 3.15 G5a) but it has NEVER rendered (main.tex has no \appendix at baseline). Pre-impl: appendix
#   page not found → RED. Post-impl: appendix body spans SimSun ≈12bp → GREEN. Spec §2.15 line 439 小四号宋体.
test_appendix_body_xiaosi_songti() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if appendix is None:
    print('  (appendix page not found — main.tex has no \\appendix at baseline; RED)'); sys.exit(1)
# probe body spans on the first appendix page: 小四 = 12bp band; body text = CJK spans
band = spans_band(appendix, 11.0, 13.0)
cjk = [sp for sp in band if re.search(r'[\\u4e00-\\u9fff]', sp['text'])]
if not cjk:
    print('  (no CJK body span in 小四 band on appendix page — sample-dependent; RED/inconclusive)'); sys.exit(1)
song = [sp for sp in cjk if is_song(sp['font'])]
non_song = [(sp['font'], sp['text'][:12]) for sp in cjk if not is_song(sp['font'])]
print('  appendix body CJK spans=%d SimSun=%d non-SimSun=%d' % (len(cjk), len(song), len(non_song)))
for f, t in non_song[:4]:
    print('    NON-SONG %r | %s' % (f, t))
# GREEN: majority of appendix body CJK = SimSun (allow occasional heading/caption spans). RED = body not SimSun.
sys.exit(0 if len(song) >= max(1, len(cjk)//2) else 1)
"
}
run_test "P0" "ATDD-4.1-I04" "BEHAVIOR: appendix body 小四宋体 rendered (G5a, TC-E4-02, §2.15; *** RED DRIVER *** — appendix unrendered at ed20363)" test_appendix_body_xiaosi_songti

# ==========================================
# P0 — G5b appendix counter 图A-1/表A-1/（A-1） rendered (TC-E4-03)
# ==========================================
echo "=== P0: G5b appendix counter 图A-1/表A-1/（A-1） rendered (TC-E4-03, §2.11/2.12/2.13) ==="

# ATDD-4.1-I05: BEHAVIOR — appendix floats render the A-1 counter form (\appendix → \thechapter=\@Alph → 图 A-1 / 表 A-1
#   / （A-1） via global \thefigure/\thetable/\theequation + G-A fullwidth parens). Wrong-target-AC: probe RENDERED TEXT
#   regex, not \thefigure source. Pre-impl: app01-03 zero floats → no A-1 counter anywhere → RED. Post-impl (Task 3 adds
#   ≥1 figure/table/equation to appendix): rendered regex matches → GREEN. Spec §2.11/2.12/2.13.
test_appendix_counter_renders() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
# scan appendix-region pages (from 'appendix' onward) for the A-1 counter glyphs
start = appendix if appendix is not None else max(0, doc.page_count - 20)
fig = tab = eq = False
for pno in range(start, doc.page_count):
    t = doc[pno].get_text()
    if re.search(r'图\s*A[-‐-]?1', t): fig = True
    if re.search(r'表\s*A[-‐-]?1', t): tab = True
    # equation counter （A-1）fullwidth parens (G-A tagform@) OR (A-1) ASCII fallback
    if re.search(r'（A[-‐-]?1）', t) or re.search(r'\(A[-‐-]?1\)', t): eq = True
print('  appendix counter: 图A-1=%s 表A-1=%s （A-1）=%s' % (fig, tab, eq))
# GREEN: at least the figure + table + equation counter all render. RED = any missing (Task 3 not done).
sys.exit(0 if (fig and tab and eq) else 1)
"
}
run_test "P0" "ATDD-4.1-I05" "BEHAVIOR: appendix counter 图A-1/表A-1/（A-1） rendered (G5b, TC-E4-03, §2.11/2.12/2.13; *** RED DRIVER *** — zero appendix floats at ed20363)" test_appendix_counter_renders

# ==========================================
# P0 — AC-5 full content cover→declaration incl appendix (TC-E4-05)
# ==========================================
echo "=== P0: full content cover→…→declaration incl appendix (TC-E4-05, FR-32) ==="

# ATDD-4.1-I06: BEHAVIOR — the PDF contains the full thesis sequence: cover, abstract (CN+EN), TOC, body chapters,
#   references, APPENDIX, ack, declaration. Pre-impl: appendix absent → RED on the appendix piece. Post-impl: all
#   present → GREEN. This is the end-to-end "complete example thesis" proof (FR-32).
test_full_content_present() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
alltext = ''.join(doc[pno].get_text() for pno in range(doc.page_count))
checks = {
    'cover (博士学位论文)': cover is not None,
    'TOC (目录)': toc is not None,
    'English abstract': eabstract is not None,
    'appendix (附录 A/B/C)': appendix is not None,
    'ack (致谢)': ack is not None,
    'declaration (独创性声明)': declaration is not None,
    'references (参考文献)': '参考文献' in alltext,
    'body chapter (第一章 or 绪论)': bool(re.search(r'第一章|绪论|引言', alltext)),
}
missing = [k for k, v in checks.items() if not v]
for k, v in checks.items():
    print('  %s: %s' % ('OK ' if v else 'MISS', k))
sys.exit(0 if not missing else 1)
"
}
run_test "P0" "ATDD-4.1-I06" "BEHAVIOR: full content cover→…→declaration incl appendix (TC-E4-05, FR-32; *** RED DRIVER *** — appendix absent at ed20363)" test_full_content_present

echo ""

# ==========================================
# P1 — AC-5 cross-references resolve, no ?? (TC-E4-06)
# ==========================================
echo "=== P1: cross-references resolve, no ?? (TC-E4-06, FR-32) ==="

# ATDD-4.1-I07: no unresolved cross-references in the rendered PDF (no '??' tokens from \ref/\eqref/\cite). Also main.aux
#   has no undefined references. GREEN pre+post (existing content resolves); guard that appendix wiring + new appendix
#   floats + their \ref/\eqref do not introduce ??. RED = appendix float referenced but not labeled, or counter mismatch.
test_crossrefs_resolve() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  local undef
  undef=$(python -c "$PY_HEAD
alltext = ''.join(doc[pno].get_text() for pno in range(doc.page_count))
import re
n = len(re.findall(r'\\?\\?', alltext))  # ?? literal occurrences (rough proxy)
print(n)
" 2>/dev/null | tr -d '[:space:]')
  # also check main.log for undefined references/citations
  local log_undef=0
  if [[ -f "main.log" ]]; then
    log_undef=$(grep -cE 'There were undefined references|Citation .* undefined|LaTeX Warning: Reference .* undefined' main.log 2>/dev/null | tr -d '[:space:]')
  fi
  echo "  (rendered '??' proxy=$undef, log undefined-ref warnings=$log_undef [expect 0])"
  [[ "${undef:-0}" -eq 0 && "${log_undef:-0}" -eq 0 ]]
}
run_test "P1" "ATDD-4.1-I07" "cross-references resolve, no ?? (TC-E4-06, FR-32; GREEN guard — appendix refs must resolve)" test_crossrefs_resolve

# ==========================================
# P1 — AC-6 bibliography ≥1 entry [N] (TC-E4-07)
# ==========================================
echo "=== P1: bibliography ≥1 entry [N] rendered (TC-E4-07, FR-32) ==="

# ATDD-4.1-I08: bibliography renders ≥1 [N] entry (\makebibliography, Story 3.12 dual-mode). GREEN pre+post. Guard that
#   appendix wiring (which adds \include after \makebibliography) does not break the bib section. RED = no [N] entry.
test_bibliography_present() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
# references page = a page containing 参考文献 with [N] entries
found = False
for pno in range(doc.page_count):
    t = doc[pno].get_text()
    if '参考文献' in t and re.search(r'\[\s*1\s*\]', t):
        found = True; break
# also scan any page for [1]-style entries near 参考文献
if not found:
    for pno in range(doc.page_count):
        if re.search(r'\[\s*[1-9]\s*\]', doc[pno].get_text()) and '参考文献' in ''.join(doc[q].get_text() for q in range(max(0,pno-3), pno+1)):
            found = True; break
print('  bibliography [1] entry present: %s' % found)
sys.exit(0 if found else 1)
"
}
run_test "P1" "ATDD-4.1-I08" "bibliography ≥1 entry [N] rendered (TC-E4-07, FR-32; GREEN guard)" test_bibliography_present

# ==========================================
# P1 — AC-2,8 appendix env font-restore — no 小四宋体 leak into ack/declaration (TC-E4-08)
# ==========================================
echo "=== P1: appendix font-restore — no 小四宋体 leak into ack/declaration (TC-E4-08, R-23) ==="

# ATDD-4.1-I09: BEHAVIOR — the appendix env BEGIN sets \xiaosi\songti (G5a); it must NOT leak past the appendix into the
#   ack/declaration body (R-23 mitigation #1, Task 1). ack env resets \songti\xiaosi[1.524] (cls:955); \makedeclaration
#   \xiaosi[1.6] (cls:832) — both self-reset on entry, so leak is benign in practice; this test PROVES it rendered.
#   Wrong-target-AC: probe ack/declaration body span font directly. Pre-impl: appendix not wired → ack/declaration pages
#   exist but the leak-precondition is absent → test treats "appendix absent" as RED (unprovable). Post-impl: ack body =
#   SimSun; declaration present → GREEN.
test_appendix_font_restore() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
if appendix is None:
    print('  (appendix not wired — font-restore unprovable; RED pre-impl)'); sys.exit(1)
if ack is None:
    print('  (ack page not found — sample-dependent; RED/inconclusive)'); sys.exit(1)
# ack body should be SimSun (ack env \songti\xiaosi[1.524]); a leaked wrong-family would show non-SimSun CJK body
band = spans_band(ack, 11.0, 13.5)
cjk = [sp for sp in band if re.search(r'[\\u4e00-\\u9fff]', sp['text'])]
if not cjk:
    print('  (no CJK body span on ack page — sample-dependent; inconclusive)'); sys.exit(1)
song = [sp for sp in cjk if is_song(sp['font'])]
non_song = [(sp['font'], sp['text'][:12]) for sp in cjk if not is_song(sp['font'])]
print('  ack body CJK spans=%d SimSun=%d non-SimSun=%d (post-appendix; leak check)' % (len(cjk), len(song), len(non_song)))
for f, t in non_song[:4]:
    print('    LEAK? %r | %s' % (f, t))
# GREEN: ack body majority SimSun (env self-reset works). RED = leaked non-SimSun body majority.
sys.exit(0 if len(song) >= max(1, len(cjk)//2) else 1)
"
}
run_test "P1" "ATDD-4.1-I09" "BEHAVIOR: appendix font-restore — no 小四宋体 leak into ack (TC-E4-08, R-23; *** RED DRIVER *** — unprovable until appendix wired)" test_appendix_font_restore

# ==========================================
# P1 — AC-4 numbering=sc full-content renders NS 1/1.1/1.1.1 (TC-E4-04; GREEN-leaning — 3.15-I09 proved sc; 4.1 = full-content regression)
# ==========================================
echo "=== P1: numbering=sc full-content renders NS 1/1.1/1.1.1 (TC-E4-04, §2.10; temp compile, SUT untouched) ==="

# ATDD-4.1-I10: BEHAVIOR — a TEMP numbering=sc variant (sed-copy of main.tex → .atdd-41-sc.tex; main.tex UNTOUCHED,
#   no SUT mutation — Epic 1 retro + 3.15-I09 pattern) compiles with the FULL thesis content wired and renders NS
#   Arabic chapter headings (1/2…). GREEN-leaning: 3.15-I09 already proved sc compiles + NS renders on minimal content;
#   4.1 proves it holds with appendix + all chapters wired (R-23 residual: appendix-under-sc, L4 = I12). Spec §2.10.
test_sc_full_content_renders_ns() {
  if [[ ! -f "main.tex" ]] || [[ ! -f "htuthesis.cls" ]]; then return 1; fi
  sed 's/\\documentclass\[/\\documentclass[numbering=sc,/' main.tex > .atdd-41-sc.tex 2>/dev/null
  if [[ ! -s ".atdd-41-sc.tex" ]]; then
    echo "  (temp .atdd-41-sc.tex not created — main.tex documentclass signature changed? RED/inconclusive)"; return 1
  fi
  # [Review patch 2026-06-20] assert the sed substitution actually occurred. If main.tex \documentclass ever
  #   drops the '[' option-list (e.g. \documentclass{htuthesis}), sed produces an UNCHANGED HS copy that
  #   passes the -s guard, compiles as HS, and I10 would fail with the misleading "appendix-under-sc latent
  #   bug?" message. Guard: numbering=sc must be present post-sed (and not duplicated).
  local sc_clean=".atdd-41-sc.tex .atdd-41-sc.pdf .atdd-41-sc.aux .atdd-41-sc.log .atdd-41-sc.toc .atdd-41-sc.lof .atdd-41-sc.lot .atdd-41-sc.out .atdd-41-sc.fls .atdd-41-sc.fdb_latexmk .atdd-41-sc.bbl .atdd-41-sc.bcf .atdd-41-sc.blg .atdd-41-sc.run.xml .atdd-41-sc.xdv"
  if ! grep -q 'numbering=sc' .atdd-41-sc.tex 2>/dev/null; then
    rm -f $sc_clean 2>/dev/null
    echo "  (sed no-match — main.tex \\documentclass has no [option-list]; signature drifted. RED/inconclusive)"; return 1
  fi
  latexmk -xelatex -g -interaction=nonstopmode .atdd-41-sc.tex > /dev/null 2>&1
  local rc=$?
  if [[ $rc -ne 0 ]]; then
    rm -f $sc_clean 2>/dev/null
    echo "  (numbering=sc full-content compile FAILED rc=$rc — RED; appendix-under-sc latent bug?)"
    return 1
  fi
  python -c "
import fitz, sys, re
d = fitz.open('.atdd-41-sc.pdf')
ns_arabic = 0; hs_cn = 0
for pno in range(d.page_count):
    t = d[pno].get_text()
    if re.search(r'(?m)^\s*[1-9]\b', t) and ('绪论' in t or '引言' in t or '概述' in t or '研究' in t or '附件' in t or 'Game' in t):
        ns_arabic += 1
    if re.search(r'第[一二三四五六七八九十]+章', t):
        hs_cn += 1
print('  numbering=sc full-content PDF: NS-arabic-chapter-pages=%d HS-cjk-chapter-pages=%d' % (ns_arabic, hs_cn))
sys.exit(0 if (ns_arabic >= 1 and hs_cn == 0) else 1)
"
  local prc=$?
  rm -f $sc_clean 2>/dev/null
  return $prc
}
run_test "P1" "ATDD-4.1-I10" "BEHAVIOR: numbering=sc full-content renders NS 1/1.1/1.1.1 (TC-E4-04, §2.10; GREEN-leaning — 3.15 proved sc, 4.1 = full-content regression; temp compile, SUT untouched)" test_sc_full_content_renders_ns

# ==========================================
# P1 — AC-4,8 default hs still renders 第一章 + sc did not flip default (TC-E4-09 both-mode regression, R-22)
# ==========================================
echo "=== P1: default numbering=hs renders 第一章 — sc did not flip default (TC-E4-09, R-22 both-mode) ==="

# ATDD-4.1-I11: the DEFAULT main.pdf (numbering=hs) still renders humanities 第一章 (G3 hs path). GREEN-leaning guard
#   (R-22 both-mode regression: sc is opt-in, hs stays default). RED = 4.1 accidentally made sc the default.
test_hs_default_renders() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
hs = 0
for pno in range(doc.page_count):
    if pno in (cover, toc, eabstract): continue
    if re.search(r'第[一二三四五六七八九十]+章', doc[pno].get_text()):
        hs += 1
print('  default main.pdf: HS-cjk-chapter (第一章) body pages=%d' % hs)
sys.exit(0 if hs >= 1 else 1)
"
}
run_test "P1" "ATDD-4.1-I11" "default numbering=hs renders 第一章 (TC-E4-09, R-22 both-mode regression; GREEN guard)" test_hs_default_renders

# ==========================================
# P2 — sc subsubsection L4 numbering (TC-E4-10; verify-then-decide, deferred §3.15)
# ==========================================
echo "=== P2: sc subsubsection L4 numbering — verify-then-decide (TC-E4-10, deferred §3.15) ==="

# ATDD-4.1-I12: INFORMATIONAL — under numbering=sc, subsubsection (L4) inherits HS name={（,）} → renders （1） instead of
#   an NS-consistent form (spec §2.10 silent on L4 NS; deferred-work §3.15). This is verify-then-decide, NOT a gate:
#   record what L4 renders under sc; the decision (keep HS （N） or add sc L4 override) is a transparent-deviation call.
#   Always passes (informational) — prints the observed L4 form for the dev/retro to judge.
test_sc_l4_informational() {
  if [[ ! -f "main.tex" ]] || [[ ! -f "htuthesis.cls" ]]; then return 0; fi
  sed 's/\\documentclass\[/\\documentclass[numbering=sc,/' main.tex > .atdd-41-sc.tex 2>/dev/null
  local sc_clean=".atdd-41-sc.tex .atdd-41-sc.pdf .atdd-41-sc.aux .atdd-41-sc.log .atdd-41-sc.toc .atdd-41-sc.lof .atdd-41-sc.lot .atdd-41-sc.out .atdd-41-sc.fls .atdd-41-sc.fdb_latexmk .atdd-41-sc.bbl .atdd-41-sc.bcf .atdd-41-sc.blg .atdd-41-sc.run.xml .atdd-41-sc.xdv"
  if [[ ! -s ".atdd-41-sc.tex" ]]; then
    echo "  (P2 informational skipped — temp file not created)"; return 0
  fi
  latexmk -xelatex -g -interaction=nonstopmode .atdd-41-sc.tex > /dev/null 2>&1
  if [[ -f ".atdd-41-sc.pdf" ]]; then
    python -c "
import fitz, re
d = fitz.open('.atdd-41-sc.pdf')
l4hs = 0; l4ns = 0
for pno in range(d.page_count):
    t = d[pno].get_text()
    if re.search(r'（\s*\d+\s*）', t): l4hs += 1     # HS （N） form inherited at L4
    if re.search(r'(?m)^\s*\d+\.\d+\.\d+\.\d+', t): l4ns += 1  # NS 1.1.1.1 form (if override added)
print('  sc L4: HS-form （N） pages=%d  NS-form N.N.N.N pages=%d (verify-then-decide; spec §2.10 silent on L4 NS)' % (l4hs, l4ns))
" 2>/dev/null || echo "  (sc L4 probe inconclusive)"
  else
    echo "  (sc compile did not produce PDF — L4 probe skipped)"
  fi
  rm -f $sc_clean 2>/dev/null
  return 0
}
run_test "P2" "ATDD-4.1-I12" "sc subsubsection L4 numbering informational (TC-E4-10, deferred §3.15; verify-then-decide — always passes)" test_sc_l4_informational

echo ""
echo "=============================================="
echo "Summary: PASS=$PASS FAIL=$FAIL SKIP=$SKIP_COUNT"
echo "=============================================="
if [[ "$SKIP" == "1" ]]; then
  echo ""
  echo "   TDD RED phase — scaffolds inert (ATDD_SKIP=1). Activate with --run or ATDD_SKIP=0."
  echo "   RED drivers (FAIL pre-impl ed20363 — appendix unrendered; PASS post-impl spec §2.15):"
  echo "      I04 G5a appendix body 小四宋体 rendered (TC-E4-02, §2.15 line 439)"
  echo "      I05 G5b appendix counter 图A-1/表A-1/（A-1） (TC-E4-03, §2.11/2.12/2.13)"
  echo "      I06 full content cover→…→declaration incl appendix (TC-E4-05, FR-32)"
  echo "      I09 appendix font-restore — no 小四宋体 leak into ack (TC-E4-08, R-23)"
  echo "   GREEN guards (PASS pre+post — 4.1 wiring must not regress):"
  echo "      I01-03 compile gate (R-12 -g recompile), I07 cross-refs no ??, I08 bibliography [N],"
  echo "      I10 numbering=sc NS (GREEN-leaning — 3.15-I09 proved sc; 4.1 = full-content regression),"
  echo "      I11 default hs 第一章 (R-22 both-mode)."
  echo "   P2 informational: I12 sc L4 verify-then-decide (TC-E4-10, deferred §3.15; spec §2.10 silent on L4 NS)."
  echo ""
  echo "   ⚠ RED/GREEN reconciliation: 3.15-I09 ALREADY proved numbering=sc compiles + NS renders (3.15 done). So the"
  echo "      genuinely NEW unverified paths are the APPENDIX cluster (I04/I05/I06/I09) — appendix has zero floats +"
  echo "      main.tex has no \\appendix at baseline. sc tests (I10/I11) are full-content regression guards."
  echo "   Every RED driver probes the RENDERED SPAN (fitz font/size + rendered-text regex), never a code grep or"
  echo "      proxied \\the<dim>/\\the<counter> — wrong-target-AC discipline (Epic 3 retro Lesson 3; TC-E4-36 audit)."
  echo "   Tests are read-only (no SUT mutation — Epic 1 retro). sc uses temp .atdd-41-sc.tex sed-copy + cleanup"
  echo "      (3.15-I09 pattern; main.tex untouched). .atdd-41-sc.* temp files cleaned up after I10/I12."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
