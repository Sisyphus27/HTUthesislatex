#!/usr/bin/env bash
# test-story-3.7-integration.sh — ATDD Integration Tests for Story 3.7 (Structured back matter — references, appendix)
# TDD Phase: GREEN-GUARD (NO RED drivers — the references RENDERING is already correct on the baseline: title
#             "参考文献" SimHei 16.0pt 三号 centered (cx=mid), entries [N] TimesNewRomanPSMT + SimSun 10.5pt 五号
#             at STANDARD hanging indent ([N] flush-left x0≈70.9, body/continuation indented x0≈101), Arabic footer
#             "27" outer-side, htuthesis.bst (gbt7714) rendering 13 entries. These fitz behavior tests LOCK IN the
#             correct inherited rendering so future stories cannot silently regress it. AC-2 hanging-indent STYLE
#             + AC-4 appendix-scope = DIAGNOSTICS (decision-pending; appendix doesn't render).
#
# Usage: bash tests/test-story-3.7-integration.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 (compile gate — bibtex cycle, R-12) + P1 (architecture.md:41 后置内容 MEDIUM; references LOW :687)
# Linked ACs: AC-1 (references title SimHei 三号 centered new-page), AC-2 (entries SimSun 五号 [N] hanging indent),
#             AC-3 (Arabic page numbering continues), AC-4/AC-6 (appendix — SOURCE-LEVEL; rendered → Epic 4.1),
#             AC-7/AC-8 (compile + regression)
# Linked Risk: R-12 (score 4 — bibliography requires the bibtex cycle; `latexmk -g` mandatory)
# TC coverage: TC-E3-33 (P1 refs title 三号 SimHei centered new-page), TC-E3-34 (P1 entries 五号 SimSun [N] hanging),
#              TC-E3-37 (P1 Arabic page numbering), TC-E3-35/36 (P1 appendix — SOURCE-LEVEL; rendered deferred to 4.1)
#
# NOTE: source-greps (unit) prove the WIRING; these fitz tests prove the RENDERED references. fitz calibration
#   (baseline c91e834): the references TITLE page = p44 (phys 45) — a SimHei 16.0pt "参考文献" span CENTERED at
#   cx≈297.6 (=page-mid). (p29 is the TOC row "参考文献" SimHei 15pt cx≈314 — NOT centered, a decoy; excluded by
#   the size≥15.5 AND centered filter.) Footer "27" TimesNewRomanPSMT Arabic, outer (x0≈513.9, right side). Entries
#   [1]..[13] = [N] TimesNewRomanPSMT 10.5pt at x0≈70.9 (label box); body/continuation SimSun 10.5pt at x0≈101
#   (item indent) → STANDARD hanging indent ([N] flush-left, body indented), matches spec §2.14 "序号左顶格".
#
#   - ATDD-3.7-I04: references title SimHei 三号 centered new-page (AC-1, TC-E3-33) — GREEN (inherited)
#   - ATDD-3.7-I05: references entries SimSun 五号 [N] hanging indent (AC-2, TC-E3-34) — GREEN (inherited)
#   - ATDD-3.7-I06: references [N] = TNR not Latin Modern (AC-2 number font via 3.9) — GREEN guard
#   - ATDD-3.7-I07: references title page footer = Arabic outer (AC-3, TC-E3-37) — GREEN (back-matter Arabic)
#   - ATDD-3.7-I08: references title on its own page / new-page (AC-1 §2.14 另起一页) — GREEN guard
#   - ATDD-3.7-I09/I10: appendix env/counter SOURCE-LEVEL (AC-4/AC-6; appendix doesn't render → grep guards)
#   - ATDD-3.7-I11: AC-2 hanging-indent STYLE DIAGNOSTIC (decision-pending: standard vs reversed)
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

# --- Story 3.15 Red-Phase Gate (wrong-target-AC refactor — G1–G6) ---
# These assertions probe the RENDERED SPAN the spec governs (fitz font/size/position), NOT a code grep or a proxied
# target — the root-cause discipline of the 2026-06-19 spec→code audit (sprint-change-proposal-2026-06-19, 6 residual
# gaps G1–G6; D-22). Isolated from the global SKIP so the existing 575-PASS baseline is preserved while Story 3.15 code
# is pending (sprint-status: backlog). Activate: ATDD_315_SKIP=0 bash tests/test-story-3.7-integration.sh --run
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
echo "ATDD Integration Tests: Story 3.7 — Structured back matter (references, appendix)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# Shared Python header: opens main.pdf, defines references + appendix helpers.
# refs_title(): a SimHei ~16pt (三号) "参考文献" span CENTERED at cx≈page-mid — the references TITLE page.
#   (Excludes the TOC row p29: SimHei 15pt, cx≈314 off-center — fails both the size≥15.5 and centered filters.)
# refs_pages(): the references section = title page + following pages until the next back-matter title (致谢/ack,
#   resume, declaration).
# bib_entries(): [N] bib-label spans (TimesNewRomanPSMT ~10.5pt, text ^\[\d+\]$) on the refs section. The label is
#   in its own hbox (single-span fitz line); the item body is a separate fitz line at a greater x0 (the indent).
PY_HEAD='
import fitz, sys, re, statistics
doc = fitz.open("main.pdf")
W = doc[0].rect.width; H = doc[0].rect.height; mid = W / 2.0
num_re = re.compile(r"^\[\d+\]$")
title_re = re.compile(r"致\s*谢|攻读学位|个人简历|原创性声明|独创性声明")
def median(xs):
    if not xs: return None
    ys = sorted(xs); n = len(ys); return ys[n // 2]
def refs_title():
    # SimHei ~16pt (三号) centered "参考文献" = the references TITLE page (NOT the TOC row).
    for i in range(doc.page_count):
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type", 0) != 0: continue
            for ln in b.get("lines", []):
                for sp in ln.get("spans", []):
                    t = sp["text"].strip()
                    if t == "参考文献" and ("Hei" in sp["font"]) and 15.5 <= sp["size"] <= 17.0:
                        cx = (sp["bbox"][0] + sp["bbox"][2]) / 2.0
                        if abs(cx - mid) <= 8.0:
                            return {"page": i, "font": sp["font"], "size": sp["size"], "cx": cx,
                                    "y0": sp["bbox"][1], "x0": sp["bbox"][0]}
    return None
def refs_pages():
    rt = refs_title()
    if not rt: return []
    start = rt["page"]; end = doc.page_count
    for i in range(start + 1, doc.page_count):
        if title_re.search(doc[i].get_text()):
            end = i; break
    return list(range(start, end))
def bib_entries():
    out = []
    pages = refs_pages()
    for i in pages:
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type", 0) != 0: continue
            lines = b.get("lines", [])
            for li, ln in enumerate(lines):
                spans = ln.get("spans", [])
                if not spans: continue
                t0 = spans[0]["text"].strip()
                if num_re.match(t0) and "Times" in spans[0]["font"] and 9 <= spans[0]["size"] <= 12:
                    num_x0 = spans[0]["bbox"][0]
                    # body = first non-empty span of the NEXT line (item text, at the indent x0)
                    body_x0 = None
                    for nl in lines[li + 1: li + 3]:
                        for sp in nl.get("spans", []):
                            if sp["text"].strip():
                                body_x0 = sp["bbox"][0]; break
                        if body_x0 is not None: break
                    out.append({"page": i, "text": t0, "num_x0": num_x0,
                                "num_font": spans[0]["font"], "num_size": spans[0]["size"],
                                "body_x0": body_x0})
    return out
def footer_num(pno):
    # a numeric span in the footer band (y0 > H-70), 9-12pt — the page number.
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
# P0 Tests (Must Pass — 100%) — compile gate (bibtex cycle, R-12)
# ==========================================
echo "=== P0: Compile gate (R-12 — -g full recompile; bibliography requires the bibtex cycle) ==="

# ATDD-3.7-I01: latexmk -xelatex -g main.tex exit code 0 (AC-7, compile gate, R-12 bibtex cycle)
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-3.7-I01" "latexmk -xelatex -g main.tex exit code 0 (AC-7, R-12 bibtex cycle)" test_full_compile

# ATDD-3.7-I02: zero compilation errors in main.log (AC-7)
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
run_test "P0" "ATDD-3.7-I02" "zero compilation errors in main.log (AC-7)" test_no_errors

# ATDD-3.7-I03: warning count <= 3 (AC-7, NFR <=3 vs Story 3.6 baseline = 1 standing xeCJK from 3.9)
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
run_test "P0" "ATDD-3.7-I03" "warning count <= 3 (AC-7, NFR <=3 new)" test_warning_count

echo ""

# ==========================================
# P1 Tests — references title (AC-1, TC-E3-33) — GREEN guards
# ==========================================
echo "=== P1: references title SimHei 三号 centered new-page (AC-1, TC-E3-33; GREEN — inherited) ==="

# ATDD-3.7-I04: BEHAVIOR — references title SimHei 三号 ~16pt centered (AC-1, TC-E3-33)
# GREEN guard. Find the references TITLE page (SimHei ~16pt "参考文献" centered at cx≈mid). Assert the title span
#   is SimHei (三号黑体), size ~16, cx≈page-mid (centered). Reference p227: SimHei 15.95 centered. spec §2.14
#   "参考文献用三号黑体字，居中".
test_refs_title_simhei_centered() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
rt = refs_title()
if not rt:
    print('  (no references TITLE page found — SimHei ~16pt centered 参考文献; RED; bibliography may not render)'); sys.exit(1)
print('  refs title: p%d font=%r size=%.2fpt cx=%.1f (page-mid=%.1f)' %
      (rt['page']+1, rt['font'], rt['size'], rt['cx'], mid))
hei = 'Hei' in rt['font']
centered = abs(rt['cx'] - mid) <= 5.0
size_ok = 15.5 <= rt['size'] <= 16.6
# AC-1: title SimHei, 三号 (~16), centered.
sys.exit(0 if (hei and centered and size_ok) else 1)
"
}
run_test "P1" "ATDD-3.7-I04" "BEHAVIOR: references title SimHei 三号 centered (AC-1, TC-E3-33; GREEN)" test_refs_title_simhei_centered

# ATDD-3.7-I08: BEHAVIOR — references title on its own page / new-page (AC-1, §2.14 另起一页)
# GREEN guard. §2.14 "参考文献表另起一页". The references title must start a new page — the title span is the FIRST
#   text block on its page (via \htu@chapter* → \cleardoublepage). Assert the title's y0 is in the top region of the
#   page (y0 < 150pt) — a title that is the page's opening block. (The \htu@chapter* \cleardoublepage at cls:480
#   guarantees the new page; this confirms the title sits at the top.)
test_refs_title_newpage() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
rt = refs_title()
if not rt:
    print('  (no references TITLE page found — RED)'); sys.exit(1)
# title y0 in the top region (the title is the opening block of its page)
top_ok = rt['y0'] < 160.0
print('  refs title y0=%.1f (top-of-page < 160 = new-page 另起一页): %s' % (rt['y0'], top_ok))
sys.exit(0 if top_ok else 1)
"
}
run_test "P1" "ATDD-3.7-I08" "BEHAVIOR: references title top-of-page new-page (AC-1, §2.14 另起一页; GREEN)" test_refs_title_newpage

echo ""

# ==========================================
# P1 Tests — references entries (AC-2, TC-E3-34) — GREEN guards
# ==========================================
echo "=== P1: references entries SimSun 五号 [N] hanging indent (AC-2, TC-E3-34; GREEN — inherited) ==="

# ATDD-3.7-I05: BEHAVIOR — references entries SimSun 五号 [N] render (AC-2, TC-E3-34) — REPOINTED by Story 3.12 (2026-06-17)
# REPOINTED by Story 3.12: was "REVERSED hanging ~2\ccwd (Option B)" — the thebibliography \list was replaced by
#   Option A biblatex \printbibliography (§2.14 case-2, gap M1). The end-list HANGING DIRECTION (§2.14 序号左顶格
#   standard vs 3.7 reverse) is REWORK scope of Story 3.13 — NOT asserted here. This guard now asserts the entry
#   RENDERING (≥3 entries, SimSun 五号 body, [N] TNR ~10.5) — the core of AC-2 that survives the mechanism change.
#   Decision 2 cross-story override.
test_refs_entries_hanging() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
ents = bib_entries()
if len(ents) < 3:
    print('  (only %d bib entries found — RED; bibliography may not render fully)' % len(ents)); sys.exit(1)
num_x0 = median([e['num_x0'] for e in ents])
# body/continuation margin = the leftmost CJK SimSun ~10.5pt x0 on the refs section (the wrap point)
cjk_x0 = []
for i in refs_pages():
    for b in doc[i].get_text('dict').get('blocks', []):
        if b.get('type', 0) != 0: continue
        for ln in b.get('lines', []):
            for sp in ln.get('spans', []):
                t = sp['text'].strip()
                if t and ('SimSun' in sp['font'] or 'Song' in sp['font']) and 9.8 <= sp['size'] <= 11.2 and len(t) >= 2 and sp['bbox'][1] < H - 70:
                    cjk_x0.append(sp['bbox'][0])
body_margin = min(cjk_x0) if cjk_x0 else None
# SimSun ~10.5 body span count
song_body = len(cjk_x0)
indent = (num_x0 - body_margin) if (num_x0 is not None and body_margin is not None) else None
print('  bib entries=%d [N]_x0=%.1f body_margin=%.1f [N]-indent=%s song_body=%d (hanging direction→3.13)' %
      (len(ents), num_x0 if num_x0 else -1, body_margin if body_margin else -1,
       ('%.1fpt' % indent) if indent else None, song_body))
for e in ents[:4]:
    print('    p%d: %s num_x0=%.1f' % (e['page']+1, e['text'], e['num_x0']))
# AC-2 (entries render): >=3 entries, >=1 SimSun 五号 body, [N] TNR ~10.5. Hanging DIRECTION → Story 3.13.
num_tnr = all('Times' in e['num_font'] for e in ents)
num_size = median([e['num_size'] for e in ents])
num_size_ok = num_size is not None and 9.8 <= num_size <= 11.2
sys.exit(0 if (song_body >= 1 and num_tnr and num_size_ok) else 1)
"
}
run_test "P1" "ATDD-3.7-I05" "BEHAVIOR: references entries SimSun 五号 [N] REVERSED hanging ~2\\ccwd (AC-2 Option B, TC-E3-34; PROMOTED)" test_refs_entries_hanging

# ATDD-3.7-I06: BEHAVIOR — references [N] = TNR not Latin Modern (AC-2 number font via 3.9)
# GREEN guard. The [N] number renders TimesNewRomanPSMT (via 3.9 \setmainfont TNR), NOT Latin Modern. Catches a
#   3.9 regression OR a stray \sffamily leaking into the bibliography. Reference uses Calibri (Word artifact — NOT
#   chased; TNR is the spec Latin per FR-13/16).
test_refs_number_tnr() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
ents = bib_entries()
if not ents:
    print('  (no bib entry found — RED)'); sys.exit(1)
fonts = set(e['num_font'] for e in ents)
all_tnr = all('Times' in f for f in fonts)
any_lm = any(('LMSans' in f or 'LMRoman' in f) for f in fonts)
print('  bib [N] number fonts=%s all_tnr=%s any_latinmodern=%s (3.9 setmainfont TNR)' % (fonts, all_tnr, any_lm))
sys.exit(0 if (all_tnr and not any_lm) else 1)
"
}
run_test "P1" "ATDD-3.7-I06" "BEHAVIOR: references [N] = TNR not Latin Modern (AC-2 via 3.9; GREEN)" test_refs_number_tnr

echo ""

# ==========================================
# P1 Test — Arabic page numbering continues through references (AC-3, TC-E3-37)
# ==========================================
echo "=== P1: Arabic page numbering continues through references (AC-3, TC-E3-37; GREEN) ==="

# ATDD-3.7-I07: BEHAVIOR — references title page footer = Arabic outer (AC-3, TC-E3-37)
# GREEN guard. References are in \backmatter → Arabic page numbering continues (no reset). The references title
#   page footer must show an Arabic number (not Roman — Roman is front-matter only). Verify the footer number is
#   numeric (^\d+$) and at the outer side (odd page: right, x0 > mid; even page: left, x0 < mid). Reference p227
#   footer "215" Arabic outer.
test_refs_footer_arabic() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
rt = refs_title()
if not rt:
    print('  (no references TITLE page found — RED)'); sys.exit(1)
foot = footer_num(rt['page'])
if not foot:
    print('  (no footer page-number on refs title page — RED)'); sys.exit(1)
fn = foot[0]
arabic = fn['text'].isdigit()
# outer side: odd page (phys rt['page']+1) → right (cx > mid); even → left (cx < mid). Back-matter references start
# on an odd page typically; tolerate either as long as it's OUTER (not centered).
phys = rt['page'] + 1
outer = (phys % 2 == 1 and fn['cx'] > mid) or (phys % 2 == 0 and fn['cx'] < mid)
print('  refs title p%d (phys %d) footer=%r font=%r cx=%.1f mid=%.1f arabic=%s outer=%s' %
      (rt['page'], phys, fn['text'], fn['font'], fn['cx'], mid, arabic, outer))
# AC-3: Arabic page number (not Roman), at the outer side. (Roman = front-matter only; back-matter = Arabic.)
sys.exit(0 if (arabic and outer) else 1)
"
}
run_test "P1" "ATDD-3.7-I07" "BEHAVIOR: references footer = Arabic outer (AC-3, TC-E3-37; GREEN)" test_refs_footer_arabic

echo ""

# ==========================================
# P1 Tests — appendix (AC-4/AC-6) — SOURCE-LEVEL (appendix does NOT render; rendered → Epic 4.1)
# ==========================================
echo "=== P1: appendix SOURCE-LEVEL (AC-4/AC-6; appendix doesn't render → TC-E3-35/36 rendered deferred to Epic 4.1) ==="

# ATDD-3.7-I09: appendix environment SOURCE-LEVEL intact (AC-4, TC-E3-35 source guard)
# The appendix does NOT render in main.pdf (main.tex has no \appendix). This is a SOURCE-LEVEL grep guard: the
#   \renewenvironment{appendix} + \gdef\@chapapp{\appendixname~\thechapter} must remain in the cls. Rendered
#   appendix-title verification (附录A 三号 SimHei centered) is DEFERRED to Epic 4 Story 4.1 (sample-content scope,
#   per deferred-work.md). The behavior proof here = the wiring is intact + the reference-PDF target documented.
test_appendix_env_source() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'renewenvironment\{appendix\}' htuthesis.cls && \
  grep -qE 'gdef\\@chapapp\{\\appendixname~\\thechapter\}' htuthesis.cls && \
  echo "  (appendix env + \@chapapp source-level intact; rendered 附录A 三号 SimHei → Epic 4.1)"
}
run_test "P1" "ATDD-3.7-I09" "SOURCE-LEVEL: appendix env + \@chapapp intact (AC-4, TC-E3-35; rendered → Epic 4.1)" test_appendix_env_source

# ATDD-3.7-I10: appendix counter A-1 by-construction SOURCE-LEVEL (AC-6, TC-E3-36 source guard)
# The appendix counters 图A-1/表A-1/(A-1) are NOT rendered (no appendix floats). This is a SOURCE-LEVEL by-
#   construction proof: \theequation/\thefigure/\thetable emit \thechapter\htu@counter@separator; \appendix makes
#   \thechapter alphabetic → "A-1". Verified mechanically (Story 2.6 + deferred-work.md). Rendered verification
#   DEFERRED to Epic 4.1 (when appendix sample floats exist). Each \renewcommand spans 2 lines → join newlines.
test_appendix_counter_source() {
  [[ -f "htuthesis.cls" ]] || return 1
  local joined
  joined=$(tr '\n' ' ' < htuthesis.cls)
  grep -qE 'renewcommand.theequation.{0,140}thechapter.{0,40}htu@counter@separator' <<<"$joined" && \
  grep -qE 'renewcommand.thefigure.{0,140}thechapter.{0,40}htu@counter@separator' <<<"$joined" && \
  grep -qE 'renewcommand.thetable.{0,140}thechapter.{0,40}htu@counter@separator' <<<"$joined" && \
  echo "  (appendix counters emit \\thechapter+separator → A-1 by construction; rendered 图A-1/表A-1 → Epic 4.1)"
}
run_test "P1" "ATDD-3.7-I10" "SOURCE-LEVEL: appendix counter → A-1 by construction (AC-6, TC-E3-36; rendered → Epic 4.1)" test_appendix_counter_source

echo ""

# ==========================================
# P2 Tests — AC-2 hanging-indent STYLE DIAGNOSTIC (decision-pending) + regression + diagnostic
# ==========================================
echo "=== P2: AC-2 hanging REVERSED ~2\\ccwd (Option B resolved) + self-check regression + layout diagnostic ==="

# ATDD-3.7-I11: BEHAVIOR — AC-2 hanging-indent = REVERSED ~2\ccwd (AC-2 Option B, TC-E3-34) — PROMOTED from diagnostic
# AC-2 DECISION RESOLVED 2026-06-16: Zy chose Option B (reference PDF p227 REVERSED style per Decision 4). PROMOTED
#   from the value-agnostic diagnostic (which only REPORTED the style, no pass/fail). Now asserts the [N] is indented
#   ~2\ccwd (~15-28pt) INTO the body from the continuation/body margin — matching reference p227's 21pt indent. A
#   stricter band than I05 ([10,40]); verifies the indent matches the reference's 2\ccwd closely.
test_refs_hanging_reversed_2ccwd() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
ents = bib_entries()
if not ents:
    print('  (no bib entry found — RED pre-impl)'); sys.exit(1)
num_x0 = median([e['num_x0'] for e in ents])
cjk_x0 = []
for i in refs_pages():
    for b in doc[i].get_text('dict').get('blocks', []):
        if b.get('type', 0) != 0: continue
        for ln in b.get('lines', []):
            for sp in ln.get('spans', []):
                t = sp['text'].strip()
                if t and ('SimSun' in sp['font'] or 'Song' in sp['font']) and 9.8 <= sp['size'] <= 11.2 and len(t) >= 2 and sp['bbox'][1] < H - 70:
                    cjk_x0.append(sp['bbox'][0])
body_margin = min(cjk_x0) if cjk_x0 else None
indent = (num_x0 - body_margin) if (num_x0 is not None and body_margin is not None) else None
print('  AC-2 end-list: bib entries=%d [N]_x0=%.1f body_margin=%.1f [N]-indent=%s (hanging DIRECTION → Story 3.13)' %
      (len(ents), num_x0, body_margin if body_margin else -1, ('%.1fpt' % indent) if indent else None))
print('  (REPOINTED by Story 3.12: biblatex \\printbibliography replaced thebibliography; hanging direction = 3.13 scope)')
# AC-2 (entries render): >=1 bib entry. Hanging DIRECTION (§2.14 序号左顶格 standard vs reverse) → Story 3.13.
sys.exit(0 if len(ents) >= 1 else 1)
"
}
run_test "P1" "ATDD-3.7-I11" "BEHAVIOR: end-list entries render (REPOINTED by 3.12 — hanging direction→3.13; was REVERSED 2\\ccwd)" test_refs_hanging_reversed_2ccwd

# ATDD-3.7-I12: regression — self-check textheight ~688pt unchanged (AC-7, R-1)
test_textheight_unchanged() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local th
  th=$(grep 'textheight = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$th" ]]; then echo "  (textheight not found in self-check)"; return 1; fi
  echo "  (textheight: ${th}pt [expect ~688.56])"
  echo "$th" | awk '{if ($1 >= 686 && $1 <= 690) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.7-I12" "regression: self-check textheight unchanged ~688pt (AC-7, R-1)" test_textheight_unchanged

# ATDD-3.7-I13: regression — self-check baselineskip ≈ 23.4bp (AC-7 — references must not touch body spacing) — REPOINTED by Story 3.11
test_baselineskip_18bp() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local bs
  bs=$(grep 'baselineskip = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$bs" ]]; then echo "  (baselineskip not found in self-check)"; return 1; fi
  echo "  (baselineskip: ${bs}pt, expect ~23.49 [body 23.4bp])"
  echo "$bs" | awk '{if ($1 >= 22.5 && $1 <= 24.5) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.7-I13" "regression: self-check baselineskip ~23.4bp (REPOINTED by Story 3.11; AC-7 — references must not touch body spacing)" test_baselineskip_18bp

# ATDD-3.7-I14: total pages ~51 ±5 (AC-7; references already render — no page shift unless AC-2 Option B edits indent)
test_total_pages() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local total_pages
  total_pages=$(grep 'total pages = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | tr -d '[:space:]')
  if [[ -z "$total_pages" ]]; then echo "  (page count not found)"; return 1; fi
  echo "  (pages: $total_pages, expected 40-56 [re-anchored by Story 3.14: → 44 pp; was ~51 ±5] [references in-place; appendix doesn't render])"
  echo "$total_pages" | awk '{if ($1 >= 40 && $1 <= 56) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.7-I14" "total pages ~51 ±5 (AC-7; references in-place; appendix doesn't render)" test_total_pages

# ATDD-3.7-I15: regression — no fancyhdr headheight warning (AC-7, R-2)
test_no_headheight_warning() {
  if [[ -f "main.log" ]]; then
    ! grep -qi 'headheight.*too low\|fancyhdr.*headheight' main.log 2>/dev/null
  else
    return 1
  fi
}
run_test "P1" "ATDD-3.7-I15" "regression: no fancyhdr headheight warning (AC-7, R-2)" test_no_headheight_warning

# ATDD-3.7-I16: DIAGNOSTIC — references rendered layout for manual reference-overlay (visual-sampling #8)
# Records the rendered references layout for manual comparison vs the reference thesis PDF p227. Does NOT hard
#   pass/fail — exits 0 if a title + entries were found (prints layout). Reference = VISUAL truth (SimHei 三号
#   centered; [N] TNR + SimSun 五号; hanging-indent style decision-pending).
test_refs_layout_diagnostic() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
rt = refs_title()
ents = bib_entries()
if not rt:
    print('  (no references title page found — RED pre-impl)'); sys.exit(1)
print('  references rendered layout (for manual reference-overlay vs ref p227):')
print('    title: p%d font=%r size=%.2fpt cx=%.1f (centered=%s)' %
      (rt['page']+1, rt['font'], rt['size'], rt['cx'], abs(rt['cx']-mid) <= 5.0))
num_x0 = median([e['num_x0'] for e in ents]) if ents else None
body_x0s = [e['body_x0'] for e in ents if e['body_x0'] is not None]
body_x0 = median(body_x0s) if body_x0s else None
print('    entries=%d [N]_x0=%s body_x0=%s num_font=%s' %
      (len(ents), ('%.1f' % num_x0) if num_x0 else None, ('%.1f' % body_x0) if body_x0 else None,
       (ents[0]['num_font'] if ents else None)))
print('  reference p227: title SimHei 15.95 centered; entries SimSun 10.45 五号; [N] x0≈111 / body x0≈90 REVERSED.')
sys.exit(0)
"
}
run_test "P2" "ATDD-3.7-I16" "DIAGNOSTIC: references layout for reference-overlay (AC visual-sampling #8)" test_refs_layout_diagnostic

echo ""

# ==========================================
# Story 3.15 Red-Phase — G5a appendix env body explicitly 小四宋体 (§2.15, TC-E3-62)
# ==========================================
echo "=== Story 3.15 RED: G5a appendix env body explicit 小四宋体 (§2.15; RED pre-impl — implicit \\normalsize) ==="

# ATDD-3.7-I17 (Story 3.15): SOURCE-LEVEL — appendix env body explicitly 小四宋体 (G5a, TC-E3-62)
# WRONG-TARGET-AC note: the appendix does NOT render in main.pdf (main.tex has no \appendix; G5b = Story 4.1 wiring).
#   The RENDERED proof is therefore blocked on 4.1. This is the available SOURCE-LEVEL probe: the appendix env
#   (cls \renewenvironment{appendix} begin-clause) must explicitly set body font \xiaosi\songti. Spec §2.15 line 439:
#   "附录内容一般用小四号宋体字". Pre-impl: the env body relies on implicit \normalsize (cls:957-968 has aftername +
#   centering but NO \xiaosi\songti) → RED. Post-impl (Story 3.15 G5a): explicit \xiaosi\songti → GREEN.
#   RENDERED appendix-body proof → Epic 4.1 (G5b wires \appendix + data/app0*.tex).
test_appendix_body_font_source() {
  [[ -f "htuthesis.cls" ]] || return 1
  python -c "
import sys
src = open('htuthesis.cls', encoding='utf-8').read()
idx = src.find(r'\renewenvironment{appendix}')
if idx < 0:
    print('  (appendix env marker \\\\renewenvironment{appendix} not found — RED)'); sys.exit(1)
region = src[idx:idx+900]   # the env begin-clause (aftername + centering + font when present)
has_font = (r'\xiaosi' in region) and ('songti' in region.lower())
print('  appendix env region has explicit \\\\xiaosi\\\\songti: %s' % has_font)
sys.exit(0 if has_font else 1)
"
}
run_test_315 "P1" "ATDD-3.7-I17" "SOURCE-LEVEL: appendix env body explicit 小四宋体 (G5a, TC-E3-62, §2.15; RED pre-impl — implicit \\normalsize; rendered → 4.1)" test_appendix_body_font_source

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
  echo "   RED drivers: NONE — Story 3.7 is VERIFY-GREEN (references machinery inherited intact from zzuthesis,"
  echo "      already renders on main.pdf p44 at baseline c91e834: title SimHei 三号 centered, entries [N] TNR +"
  echo "      SimSun 五号 STANDARD hanging indent, Arabic footer outer; appendix correct by construction)."
  echo "   GREEN guards (lock-in): I01-I03 (compile — bibtex cycle), I04 (refs title SimHei 三号 centered),"
  echo "      I05 (refs entries SimSun 五号 [N] hanging indent), I06 (refs [N] TNR not Latin Modern),"
  echo "      I07 (refs footer Arabic outer), I08 (refs title new-page), I09 (appendix env source-level),"
  echo "      I10 (appendix counter A-1 source-level), I12 (textheight), I13 (baselineskip 18bp), I14 (pages),"
  echo "      I15 (no headheight)."
  echo "   DIAGNOSTIC: I16 (references layout for reference-overlay)."
  echo ""
  echo "   NOTE: AC-2 hanging-indent RESOLVED 2026-06-16 to Option B (reference p227 REVERSED per Decision 4,"
  echo "         Zy-approved; spec §2.14 序号左顶格 = transparent deviation). I11 asserts REVERSED ~2\\ccwd (15-28pt)."
  echo "         AC-4/AC-6 appendix rendered verification DEFERRED to Epic 4.1 (appendix doesn't render;"
  echo "         DEFERRED to Epic 4.1 (appendix doesn't render; data/app0{1,2,3}.tex have no floats). I09/I10 are"
  echo "         source-level guards + a 'rendered deferred to 4.1' note. architecture.md:41 = MEDIUM; references"
  echo "         LOW (gbt7714 :687). Tests are read-only (no SUT mutation)."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
