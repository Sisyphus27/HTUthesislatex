#!/usr/bin/env bash
# test-story-5.4-integration.sh — ATDD Integration (fitz behavior) Tests for Story 5.4 (Footnote marker `[N]`)
#
# TDD Phase: RED — the PRIMARY RED drivers are I02/I03/I04/I05 (the current main.pdf renders BARE-DIGIT footnote
#   markers, not [N]). Empirical probe 2026-06-23 (this story's creation): in-text superscripts = 0 bracket / 22 bare;
#   page-bottom leads = 0 bracket / 11 bare. Post-impl (Story 5.4 Task 2: \renewcommand\thefootnote{[\arabic{footnote}]})
#   → both paths render [N] → I02/I03/I04/I05 GREEN. I06 (end-list [N]) is a GREEN-guard (already correct via gbt7714).
#   I07 is a fragmentation diagnostic (TC-E5-27, R-39).
#
# Usage: bash tests/test-story-5.4-integration.sh [--run]
#   --run    Remove SKIP marker (activate; green-phase verification). Default ATDD_SKIP=1 = RED scaffold inert.
#
# Priority: P0 (the [N] render proof — the core AC) + GREEN-guards (compile, end-list)
# Linked ACs: AC-1 (in-text [N] → I02), AC-2 (page-bottom [N] → I03), AC-3 (per-page reset → I04),
#             AC-4 (both paths → I05), AC-6 (fragmentation → I07), AC-7 (end-list [N] guard → I06), AC-8 (compile → I01)
# Linked Risk: R-38 (footmisc × \thefootnote + both-paths → I02/I03/I05), R-39 (fragmentation → I07)
# TC coverage: TC-E5-24 (I02), TC-E5-25 (I03), TC-E5-26 (I04 per-page reset), TC-E5-27 (I07 fragmentation),
#              TC-E5-28 (I05 both paths)
#
# NOTE: the rendered [N] is verified by fitz on the COMPILED main.pdf (Decision 1 — visual signature; the cls
#   \thefootnote wiring is verified by test-story-5.4-unit.sh U01). A source-grep alone does NOT prove the marker
#   renders [N] (footmisc could override \thefootnote) — this fitz probe is the real AC proof.
#
# Truth source: spec §1.2.4 示例1/2 + line 99 (顺序编码制 [N] EXPLICIT for in-text) + §2.14 line 289 (end-list [N]
#   EXPLICIT) + §1.2.4 line 109 / §2.5 line 197 SILENT on page-bottom lead shape → reference PDF p20-36 + GB/T 7714-2015
#   auxiliary (assumption 8). Reference probe 2026-06-23: 57 in-text [N] + 24 page-bottom [N] / 0 bare.

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

# Shared Python header: opens main.pdf, defines [N]-marker helpers (content-normalized → fragmentation-robust, R-39).
#   intext_markers(): [N] found IN-LINE on body-region lines bearing a small (5-8.5pt) non-Math span (the superscript).
#                     Content-normalized (line-span concat) so [1] matches whether single-span or fragmented.
#   lead_markers():   [N] at the START of a footnote-band line (the page-bottom lead). Per-page → {page: [N]}.
#   bare_intext / bare_lead: the PRE-FIX bug signal (bare digits) — diagnostic, proves RED phase.
#   endlist_bracket / endlist_bare: the end-list entry [N] (AC-7 regression guard).
#   type_re: GB/T 7714 type designator ([M]/[J]/...) — distinguishes citation footnotes (I05).
PY_HEAD='
import fitz, sys, re
doc = fitz.open("main.pdf")
W = doc[0].rect.width; H = doc[0].rect.height; mid = W / 2.0
type_re = re.compile(r"\[(M|J|D|C|R|N|P|S|EB)(/OL)?\]")
title_re = re.compile(r"致\s*谢|攻读学位|个人简历|原创性声明|独创性声明|参考文献")
def _refs_page():
    # the end-list TITLE page (SimHei ~16pt centered 参考文献) — body pages = before it.
    for i in range(doc.page_count):
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type",0)!=0: continue
            for ln in b.get("lines", []):
                for sp in ln.get("spans", []):
                    t = sp["text"].strip()
                    if t == "参考文献" and ("Hei" in sp["font"]) and 15.5 <= sp["size"] <= 17.0:
                        return i
    return doc.page_count
_REFS = _refs_page()
def _line_markers(pno, y_min, y_max, size_min, size_max, at_start):
    # [N] markers on lines in the y-band bearing a span in the size band (non-Math). Line-concat → fragmentation-robust.
    out = []
    for b in doc[pno].get_text("dict").get("blocks", []):
        if b.get("type",0)!=0: continue
        for ln in b.get("lines", []):
            spans = ln.get("spans", [])
            if not spans: continue
            y0 = min(sp["bbox"][1] for sp in spans)
            if not (y_min <= y0 <= y_max): continue
            if not any(size_min <= sp["size"] <= size_max and "Math" not in sp["font"] for sp in spans):
                continue
            text = "".join(sp["text"] for sp in spans).strip()
            if at_start:
                m = re.match(r"^\[(\d+)\]", text)
                if m: out.append(int(m.group(1)))
            else:
                for m in re.finditer(r"\[(\d+)\]", text):
                    out.append(int(m.group(1)))
    return out
def _bare_line_markers(pno, y_min, y_max, size_min, size_max):
    # bare-digit markers (the PRE-FIX bug) — single-span fullmatch (bare digits do not fragment).
    out = []
    for b in doc[pno].get_text("dict").get("blocks", []):
        if b.get("type",0)!=0: continue
        for ln in b.get("lines", []):
            for sp in ln.get("spans", []):
                t = sp["text"].strip(); y0 = sp["bbox"][1]
                if size_min <= sp["size"] <= size_max and y_min <= y0 <= y_max and re.fullmatch(r"\d+", t) and "Math" not in sp["font"]:
                    out.append(int(t))
    return out
def intext_markers():
    # in-text superscript [N] on BODY pages (exclude end-list region + footer). Band: y < H*0.62 (above footnote band).
    out = []
    for i in range(0, min(_REFS, doc.page_count)):
        out += [(i, n) for n in _line_markers(i, 0, H*0.62, 5.0, 8.5, at_start=False)]
    return out
def bare_intext():
    out = []
    for i in range(0, min(_REFS, doc.page_count)):
        out += [(i, n) for n in _bare_line_markers(i, 0, H*0.62, 5.0, 8.5)]
    return out
def lead_markers():
    # page-bottom footnote lead [N] (at line start, footnote band). size_max 9.5 EXCLUDES the 10.5pt end-list/papers
    # [N] ENTRIES (§2.14 五号 = 10.5pt / §2.17 same-as-refs) — only the footnote MARKER (5-9pt; reference = 6pt)
    # qualifies. Pre-fix FALSE-GREEN fix (2026-06-23): size_max was 10.5 → caught end-list entries on p40/p51.
    out = {}
    for i in range(doc.page_count):
        ns = _line_markers(i, H*0.62, H*0.96, 5.0, 9.5, at_start=True)
        if ns: out[i] = ns
    return out
def bare_lead():
    out = {}
    for i in range(doc.page_count):
        ns = _bare_line_markers(i, H*0.62, H*0.96, 5.0, 8.0)
        if ns: out[i] = ns
    return out
def endlist_entries():
    # end-list [N] entries (line-start, size 9-12, on end-list pages). Returns (bracket_count, bare_count).
    bracket = 0; bare = 0
    for i in range(_REFS, doc.page_count):
        for b in doc[i].get_text("dict").get("blocks", []):
            if b.get("type",0)!=0: continue
            for ln in b.get("lines", []):
                sps = ln.get("spans", [])
                if sps:
                    t0 = sps[0]["text"].strip()
                    if 9 <= sps[0]["size"] <= 12:
                        if re.fullmatch(r"\[\d+\]", t0): bracket += 1
                        elif re.fullmatch(r"\d+", t0): bare += 1
    return bracket, bare
def _footnote_band_text(pno):
    # concat all footnote-band (y>H*0.62) text on a page — for [TYPE] citation detection.
    out = []
    for b in doc[pno].get_text("dict").get("blocks", []):
        if b.get("type",0)!=0: continue
        for ln in b.get("lines", []):
            for sp in ln.get("spans", []):
                if sp["bbox"][1] > H*0.62 and 8.0 <= sp["size"] <= 10.5:
                    out.append(sp["text"])
    return "".join(out)
def citation_lead_pages():
    # body pages whose footnote band carries a [TYPE] designator (citation footnote present).
    out = []
    for i in range(0, min(_REFS, doc.page_count)):
        if type_re.search(_footnote_band_text(i)):
            out.append(i)
    return out
def explanatory_lead_pages(lead_pages):
    # body pages with footnote leads but NO [TYPE] (explanatory \footnote{} only).
    cit = set(citation_lead_pages())
    return [p for p in lead_pages if p not in cit]
'

echo "=============================================="
echo "ATDD Integration Tests: Story 5.4 — Footnote marker [N] (fitz behavior on main.pdf)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped — run with --run post-impl)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests — compile gate + the [N] render proof (RED pre-fix)
# ==========================================
echo "=== P0: compile gate (AC-8) + in-text/page-bottom [N] (AC-1/2, TC-E5-24/25; *** RED DRIVER ***) ==="

# ATDD-5.4-I01: latexmk -xelatex -g main.tex exit code 0 (AC-8, compile gate; \thefootnote must not break compile)
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-5.4-I01" "latexmk -xelatex -g main.tex exit 0 (AC-8; \\thefootnote must not break compile)" test_full_compile

# ATDD-5.4-I02: BEHAVIOR — in-text superscript footnote marker renders [N] (AC-1, TC-E5-24, R-38/R-39) — RED DRIVER
# Pre-fix: 0 bracket [N] (bare digits). Post-fix: ≥1 in-text [N]. Content-normalized (fragmentation-robust).
test_intext_marker_bracketed() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
m = intext_markers()
bare = bare_intext()
print('  in-text [N] markers=%d  bare-digit (pre-fix bug)=%d' % (len(m), len(bare)))
if m:
    pages = sorted(set(p for p,n in m))
    print('  [N] on pages (1-based): %s' % [p+1 for p in pages[:8]])
sys.exit(0 if len(m) >= 1 else 1)
"
}
run_test "P0" "ATDD-5.4-I02" "BEHAVIOR: in-text superscript marker = [N] (AC-1, TC-E5-24; *** RED DRIVER ***)" test_intext_marker_bracketed

# ATDD-5.4-I03: BEHAVIOR — page-bottom footnote lead renders [N] (AC-2, TC-E5-25, R-38/R-39) — RED DRIVER
test_lead_marker_bracketed() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
lm = lead_markers()
bl = bare_lead()
total = sum(len(v) for v in lm.values())
bare_total = sum(len(v) for v in bl.values())
print('  page-bottom [N] leads=%d (on %d pages)  bare-digit leads (pre-fix bug)=%d' % (total, len(lm), bare_total))
sys.exit(0 if total >= 1 else 1)
"
}
run_test "P0" "ATDD-5.4-I03" "BEHAVIOR: page-bottom footnote lead = [N] (AC-2, TC-E5-25; *** RED DRIVER ***)" test_lead_marker_bracketed

echo ""

# ==========================================
# P0 Tests — per-page reset + both paths (RED pre-fix)
# ==========================================
echo "=== P0: per-page [1] reset (AC-3, TC-E5-26) + both paths [N] (AC-4, TC-E5-28; *** RED DRIVER ***) ==="

# ATDD-5.4-I04: BEHAVIOR — per-page reset: [1] recurs on >=2 body pages (AC-3, TC-E5-26, §1.2.4 line 109) — RED DRIVER
# footmisc[perpage] resets the counter; \thefootnote changes only the print form → [1] recurs post-fix. Pre-fix: bare 1
# recurs (reset works) but [1] (bracketed) does not appear → RED on the bracketed form.
test_perpage_reset_bracketed() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
lm = lead_markers()
pages_with_1 = sorted([p+1 for p,v in lm.items() if 1 in v])
print('  footnote-lead pages with [1]: %s (%d pages)' % (pages_with_1[:10], len(pages_with_1)))
# per-page reset (bracketed): [1] recurs on >=2 pages
sys.exit(0 if len(pages_with_1) >= 2 else 1)
"
}
run_test "P0" "ATDD-5.4-I04" "BEHAVIOR: per-page [1] reset recurs on >=2 pages (AC-3, TC-E5-26; *** RED DRIVER ***)" test_perpage_reset_bracketed

# ATDD-5.4-I05: BEHAVIOR — BOTH citation (\footfullcite) AND explanatory (\footnote{}) markers = [N] (AC-4, TC-E5-28, R-38c)
# Catches the consistency-hole sub-risk where biblatex \footfullcite might bypass \thefootnote. Pre-fix: both bare → RED.
test_both_paths_bracketed() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
lm = lead_markers()
lead_pages = list(lm.keys())
cit = [p for p in citation_lead_pages() if p in lm]
expl = [p for p in explanatory_lead_pages(lead_pages) if p in lm]
print('  citation-footnote pages with [N] lead: %d %s' % (len(cit), [p+1 for p in cit[:5]]))
print('  explanatory-footnote pages with [N] lead: %d %s' % (len(expl), [p+1 for p in expl[:5]]))
# BOTH paths must have >=1 [N] lead (consistency — R-38 sub-risk c)
sys.exit(0 if (len(cit) >= 1 and len(expl) >= 1) else 1)
"
}
run_test "P0" "ATDD-5.4-I05" "BEHAVIOR: both \\footfullcite + \\footnote paths render [N] (AC-4, TC-E5-28, R-38c; *** RED DRIVER ***)" test_both_paths_bracketed

echo ""

# ==========================================
# P0 GREEN-guard — end-list stays [N] (AC-7, regression guard)
# ==========================================
echo "=== P0: end-list stays [N] (AC-7 regression guard; GREEN — already correct via gbt7714-2015) ==="

# ATDD-5.4-I06: BEHAVIOR — end-list entries stay [N] (AC-7, regression guard). The \thefootnote edit must NOT affect
# the end-list (cls:139 gbt7714-2015 owns it). Pre + post: ≥1 bracket [N] end-list entry. Probe 2026-06-23 = 13 bracket.
test_endlist_stays_bracketed() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
bracket, bare = endlist_entries()
print('  end-list entries: bracket [N]=%d  bare=%d' % (bracket, bare))
# AC-7: end-list stays [N] (regression guard — the \thefootnote edit must not touch the end-list)
sys.exit(0 if bracket >= 1 else 1)
"
}
run_test "P0" "ATDD-5.4-I06" "BEHAVIOR: end-list entries stay [N] (AC-7 regression guard, GREEN; \\thefootnote must not affect end-list)" test_endlist_stays_bracketed

echo ""

# ==========================================
# P1 Test — bracket-span fragmentation diagnostic (AC-6, TC-E5-27, R-39)
# ==========================================
echo "=== P1: bracket-span fragmentation audit (AC-6, TC-E5-27, R-39) ==="

# ATDD-5.4-I07: DIAGNOSTIC — does [N] render as a single fitz span or fragmented across spans? Drives the helper
# repoint form (single-span fullmatch vs content-normalized line concat). This test ALWAYS PASSES (informational) once
# [N] markers exist; it REPORTS the structure. The integration test I02/I03 already use content-normalized matching
# (robust to either), so this is diagnostic only — it informs the 3.8/3.12 helper repoint choice (Story 5.4 Task 3.1).
test_fragmentation_diagnostic() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
# count single-span [N] fullmatches (size 5-8.5, non-Math) across the whole doc
single = 0
for i in range(doc.page_count):
    for b in doc[i].get_text('dict').get('blocks', []):
        if b.get('type',0)!=0: continue
        for ln in b.get('lines', []):
            for sp in ln.get('spans', []):
                t = sp['text'].strip()
                if 5.0 <= sp['size'] <= 8.5 and 'Math' not in sp['font'] and re.fullmatch(r'\[\d+\]', t):
                    single += 1
# count orphan '[' or ']' small spans (fragmentation signal)
orphan = 0
for i in range(doc.page_count):
    for b in doc[i].get_text('dict').get('blocks', []):
        if b.get('type',0)!=0: continue
        for ln in b.get('lines', []):
            for sp in ln.get('spans', []):
                t = sp['text'].strip()
                if 5.0 <= sp['size'] <= 8.5 and 'Math' not in sp['font'] and t in ('[', ']'):
                    orphan += 1
m = intext_markers()
norm_total = len(m)
print('  [N] structure: single-span fullmatches=%d  content-normalized=%d  orphan [/] spans=%d' % (single, norm_total, orphan))
if norm_total == 0:
    print('  -> no [N] markers yet (pre-fix); fragmentation undetermined until [N] renders')
    sys.exit(1)  # RED pre-fix (no [N] yet) — consistent with I02
elif single == norm_total:
    print('  -> SINGLE-SPAN (reference-consistent): 3.8/3.12 repoint may use a bracket-digit fullmatch directly')
    sys.exit(0)
else:
    print('  -> FRAGMENTED (%d single vs %d normalized): 3.8/3.12 repoint MUST use content-normalized line concat' % (single, norm_total))
    sys.exit(0)  # informational PASS — the structure is reported; I02/I03 already handle it
"
}
run_test "P1" "ATDD-5.4-I07" "DIAGNOSTIC: [N] span structure — single vs fragmented (AC-6, TC-E5-27, R-39; informs helper repoint)" test_fragmentation_diagnostic

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
  echo "   RED drivers (FAIL pre-impl, PASS post-impl Story 5.4 Task 2 \\thefootnote):"
  echo "      I02 in-text superscript [N] (AC-1, TC-E5-24) — current: 0 bracket / 22 bare"
  echo "      I03 page-bottom lead [N] (AC-2, TC-E5-25) — current: 0 bracket / 11 bare"
  echo "      I04 per-page [1] reset (AC-3, TC-E5-26, §1.2.4 line 109)"
  echo "      I05 both \\footfullcite + \\footnote paths [N] (AC-4, TC-E5-28, R-38c)"
  echo "      I07 fragmentation diagnostic (AC-6, TC-E5-27 — RED until [N] renders)"
  echo "   GREEN guards (PASS pre + post — lock-in / regression watch):"
  echo "      I01 compile exit 0 (AC-8), I06 end-list stays [N] (AC-7 — already correct via gbt7714-2015)"
  echo ""
  echo "   Truth source: spec §1.2.4 示例1/2 + line 99 ([N] EXPLICIT) + §2.14 line 289 (end-list [N] EXPLICIT);"
  echo "      §1.2.4 line 109 / §2.5 line 197 SILENT on lead shape → reference PDF p20-36 + GB/T 7714-2015 (auxiliary)."
  echo "      Reference probe: 57 in-text [N] + 24 page-bottom [N] / 0 bare. R-38=4; R-39=6. Read-only (no SUT mutation)."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
