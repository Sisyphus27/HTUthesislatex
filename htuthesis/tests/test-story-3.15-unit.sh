#!/usr/bin/env bash
# test-story-3.15-unit.sh — ATDD Unit (source-level) Tests for Story 3.15 (spec-compliance residual-gap pack G1–G6)
# TDD Phase: RED — the RED driver cluster is unit-01 (G1 cls:560 \rmfamily on TOC number-prefix), unit-02 (G6 heading
#             \sffamily Latin-leak), unit-03 (G3 numbering=sc option absent — 3.13 deleted NS), unit-04 (G5a appendix
#             env body font), unit-05 (G4 cover-date Chinese-numeral mechanism). Pre-impl (baseline commit 567e13a,
#             post-Story 3.14): the 6 gaps are OPEN — TOC L1 number-prefix SimSun (cls:560 \rmfamily), heading Latin
#             LMSans (\sffamily at cls:463/475/484), no numbering=sc option, appendix env no explicit \xiaosi\songti,
#             cover date Arabic. Post-impl (spec §2.6/§2.8/§2.10/§1.1.1/§2.15 PRIORITY): all 6 closed at the SOURCE.
#             GREEN guards unit-06 (HS default retained — G3 must not delete humanities) + unit-07 (\thechapter Arabic
#             lock cls:505 retained — G3 sc mode must not break 图 1-1 counters) PASS pre+post.
#
# Usage: bash tests/test-story-3.15-unit.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0/P1 — source greps prove the WIRING; the rendered proof lives in test-story-3.15-integration.sh (fitz).
# Linked ACs: AC-1/G1 (cls:560 \rmfamily removed), AC-2/G6 (heading \sffamily→CJK-only \heiti), AC-4/G3 (numbering=sc
#             option declared, default hs), AC-6/G5a (appendix env body \xiaosi\songti), AC-5/G4 (cover date CJK numerals)
# Linked Risk: R-21 (G6 structural font-leak), R-22 (G3 dual-mode), R-G4date (\CJK@todaybig compile-date trap)
# TC coverage (wiring): TC-E3-60 (G1), TC-E3-61 (G6), TC-E3-63 (G3), TC-E3-62 (G5a), TC-E3-58 (G4)
#
# NOTE: these source-greps prove the CLS WIRING; the fitz integration tests prove the RENDERED span (font/size/position).
#   This story EXISTS because prior ATDDs asserted proxied/wrong targets (e.g. TOC list font, not the number-prefix span;
#   eabstract \parindent never asserted). The wiring greps + rendered fitz probes TOGETHER close the wrong-target-AC gap
#   (architecture silent-failure #13/#14; sprint-change-proposal-2026-06-19 D-22; Epic 2 retro Decision 1 extended to
#   font/position ACs — probe the RENDERED SPAN the spec governs, never a code grep or proxied target).
#
# Truth source: 河南师范大学研究生学位论文格式要求.md §2.6 line 207 (G1 TOC 黑体) + §2.10 line 235-237 (G3 NS primary +
#   半格) + §1.1.1 line 33 (G4 二〇二四年五月) + §2.15 line 439 (G5a 小四宋体). spec is PRIORITY (CLAUDE.md Decision 4,
#   corrected 2026-06-17). Reference PDF auxiliary.
#
# Line refs RE-VERIFIED vs HEAD 567e13a (post-3.14): G4 cover-date node = cls:697 (NOT the audit's stale cls:602);
#   G6 \sffamily headings = cls:463/475/484 (cls:493 subsubsection is \htu@songtibold, NOT a G6 target).

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
echo "ATDD Unit Tests: Story 3.15 — spec-compliance residual-gap pack (G1–G6; §2.6/§2.8/§2.10/§1.1.1/§2.15)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# Shared Python helper: loads cls source (comment-stripped) for region-scoped source assertions.
#   Comment-stripping (grep -v '^[[:space:]]*%') prevents false-RED from matching commented-out lines (Epic 1 retro
#   lesson — ATDD-2.6-10 / 3.4-01 comment-exclusion discipline).
read_cls_stripped() {
  grep -vE '^[[:space:]]*%' htuthesis.cls
}

# ==========================================
# P0 — G1 TOC L1 chapter number-prefix: \rmfamily removed (cls:560)
# ==========================================
echo "=== P0: G1 TOC 第N章 number-prefix — \rmfamily removed (cls:560) ==="

# ATDD-3.15-01: G1 — the TOC chapter \titlecontents number-prefix fillin must NOT force \rmfamily (→SimSun).
# cls:560 pre-impl: {{\rmfamily\thecontentslabel}\quad}{} — the \rmfamily forces the "第N章" prefix to SimSun while the
#   title span is SimHei (via the entry's \sffamily) → inconsistent. Spec §2.6 line 207: ENTIRE L1 entry 黑体.
# Post-impl: \rmfamily removed (or switched to \heiti/\sffamily) → prefix SimHei. RED pre: \rmfamily\thecontentslabel
#   present in the chapter titlecontents block. GREEN: not present.
test_g1_toc_numberprefix_no_rmfamily() {
  [[ -f "htuthesis.cls" ]] || return 1
  # Extract the \titlecontents{chapter} block; assert \rmfamily does NOT immediately precede \thecontentslabel.
  # Robust: any non-commented \rmfamily\thecontentslabel co-occurrence within the chapter titlecontents = RED.
  local hit
  hit=$(read_cls_stripped | awk '/\\titlecontents\{chapter\}/{f=1} f&&/\\titlecontents\{section\}/{f=0} f' | grep -c '\\rmfamily\\thecontentslabel' || true)
  hit=$(echo "$hit" | tr -d '[:space:]' | head -1)
  echo "  (\\rmfamily\\thecontentslabel in chapter titlecontents: $hit [expect 0])"
  [[ "$hit" -eq 0 ]]
}
run_test "P0" "ATDD-3.15-01" "G1: TOC chapter number-prefix \rmfamily removed (cls:560; TC-E3-60, §2.6; RED pre-impl — SimSun prefix)" test_g1_toc_numberprefix_no_rmfamily

# ==========================================
# P0 — G6 heading \sffamily Latin-leak: chapter/section/subsection format CJK-only (cls:463/475/484)
# ==========================================
echo "=== P0: G6 heading format CJK-only (cls:463/475/484) — \sffamily needs Latin \rmfamily guard ==="

# ATDD-3.15-02: G6 — each CJK-bold heading format= line that uses \sffamily MUST also set Latin \rmfamily (else Latin
#   leaks to LMSans). Pre-impl: cls:463 \sffamily\sanhao, cls:475 \sffamily\xiaosan, cls:484 \sffamily\sihao — none has
#   \rmfamily → Latin (e.g. chap01 "TEX/LaTeX" title) renders LMSans. Post-impl: either (a) \sffamily + \rmfamily on
#   the same format line, or (b) CJK-only \heiti (no \sffamily → vacuous pass). Spec §2.6/§2.10 Latin consistency.
# NOTE: cls:493 subsubsection uses \htu@songtibold\bfseries (NOT \sffamily) — correctly EXCLUDED from this check.
test_g6_heading_format_latin_guard() {
  [[ -f "htuthesis.cls" ]] || return 1
  # For each of chapter/section/subsection format= lines: if \sffamily present, \rmfamily must also be present.
  python3 - <<'PY'
import re, sys
src = open("htuthesis.cls", encoding="utf-8").read()
# strip full-line comments
lines = [ln for ln in src.splitlines() if not ln.lstrip().startswith("%")]
text = "\n".join(lines)
bad = []
# scope to the \ctexset{...} heading block (HS default; the sc override block carries the same guard — rendered I05/I06 covers both)
m = re.search(r'\\ctexset\{%', text)
block = text[m.start():] if m else text
# find each "level={...format={...}}" — grab the format= value per level.
# Anchor level with a preceding non-letter boundary so "section" does not match inside "subsection".
for level in ("chapter", "section", "subsection"):
    lm = re.search(r'(?<![a-z])' + level + r'\s*=\s*\{', block)
    if not lm:
        continue
    # grab a window after the level opening brace
    seg = block[lm.start(): lm.start()+400]
    fm = re.search(r'format\s*=\s*\{([^}]*)\}', seg)
    if not fm:
        continue
    fmt = fm.group(1)
    has_sf = "\\sffamily" in fmt
    has_tnr = "\\htu@tnr" in fmt      # G6 implemented mechanism (Story 3.15): \newfontfamily\htu@tnr{TNR} pins Latin=TNR after \sffamily (CJK stays SimHei)
    has_rm = "\\rmfamily" in fmt
    has_heiti = "\\heiti" in fmt
    # REPPOINTED (Story 3.15 G6 impl): the guard recognizes \htu@tnr (the implemented Latin-TNR switch) in addition to
    # \rmfamily/\heiti. Intent preserved: every \sffamily CJK-bold heading format carries a Latin-TNR guard so Latin
    # does not leak to LMSans. Authoritative rendered proof = integration ATDD-3.15-I05 (TOC) + I06 (heading).
    if has_sf and not has_tnr and not has_rm and not has_heiti:
        bad.append((level, fmt.strip()))
if bad:
    print("  heading format lines with \\sffamily Latin-leak (no \\rmfamily/\\heiti guard):")
    for lv, fmt in bad:
        print("    %s: %s" % (lv, fmt))
    print("  → RED (G6, TC-E3-61, §2.6/§2.10 — Latin leaks LMSans)")
    sys.exit(1)
print("  → all CJK-bold heading formats carry a Latin-TNR guard (\\rmfamily/\\heiti); GREEN (G6)")
sys.exit(0)
PY
}
run_test "P0" "ATDD-3.15-02" "G6: heading format lines carry Latin-TNR guard (cls:463/475/484; TC-E3-61; RED pre-impl — \\sffamily LMSans leak)" test_g6_heading_format_latin_guard

# ==========================================
# P0 — G3 numbering=sc option declared (NS-path restore; 3.13 deleted it)
# ==========================================
echo "=== P0: G3 numbering=sc option declared (cls option block; NS-path restore, §2.10) ==="

# ATDD-3.15-03: G3 — the cls exposes a numbering=sc option (restores the natural-science 1/1.1/1.1.1 path Story 3.13
#   deleted). Pre-impl: no \DeclareOption{numbering=sc} → RED. Post-impl: option declared (default hs) → GREEN.
#   Canonical: \DeclareOption{numbering=sc}{...}. Repoint if dev uses keyval/\newif — the sc-branch existence is the proof.
test_g3_numbering_sc_declared() {
  [[ -f "htuthesis.cls" ]] || return 1
  read_cls_stripped | grep -qE 'DeclareOption\{numbering=sc\}|numbering=sc|numbering\s*=\s*sc'
}
run_test "P0" "ATDD-3.15-03" "G3: numbering=sc option declared (NS-path restore; TC-E3-63, §2.10; RED pre-impl — 3.13 deleted NS)" test_g3_numbering_sc_declared

# ==========================================
# P1 — G5a appendix env body explicitly \xiaosi\songti (cls:956-968)
# ==========================================
echo "=== P1: G5a appendix env body explicit \xiaosi\songti (cls:956-968, §2.15) ==="

# ATDD-3.15-04: G5a — the appendix environment begin-clause explicitly sets body font \xiaosi\songti. Pre-impl:
#   cls:956-968 has aftername + centering but NO \xiaosi\songti (relies on implicit \normalsize). Spec §2.15 line 439:
#   "附录内容一般用小四号宋体字". RED pre: env body has no \xiaosi\songti. GREEN: present.
# NOTE: appendix does NOT render in main.pdf (main.tex has no \appendix; G5b wiring = Story 4.1). This source-grep is
#   the available G5a proof; the RENDERED appendix-body proof lands in 4.1. (Wrong-target-AC note: proxied by necessity.)
test_g5a_appendix_body_font() {
  [[ -f "htuthesis.cls" ]] || return 1
  python3 - <<'PY'
import re, sys
src = open("htuthesis.cls", encoding="utf-8").read()
lines = [ln for ln in src.splitlines() if not ln.lstrip().startswith("%")]
text = "\n".join(lines)
i = text.find(r"\renewenvironment{appendix}")
if i < 0:
    print("  (\\renewenvironment{appendix} not found — RED)"); sys.exit(1)
seg = text[i:i+700]  # the begin-clause window (cls:956-968 region)
has = (r"\xiaosi" in seg) and (("songti" in seg) or ("\\song" in seg))
print("  appendix env begin-clause has explicit \\xiaosi+\\songti: %s" % has)
sys.exit(0 if has else 1)
PY
}
run_test "P1" "ATDD-3.15-04" "G5a: appendix env body explicit \xiaosi\songti (cls:956-968; TC-E3-62, §2.15; RED pre-impl — implicit \\normalsize; rendered → 4.1)" test_g5a_appendix_body_font

# ==========================================
# P1 — G4 cover-date Chinese-numeral mechanism (cls:697 + data/cover.tex:29)
# ==========================================
echo "=== P1: G4 cover date Chinese-numeral mechanism (cls:697 / cover.tex; §1.1.1) ==="

# ATDD-3.15-04b: G4 — the cover date renders Chinese numerals via a CJK-numeral mechanism. Pre-impl: cls:697
#   {\sffamily\htu@heiti@latin\xiaosan\htu@cdate} + data/cover.tex \cdate{Arabic} → Arabic glyphs. GREEN: either
#   (a) cover.tex \cdate uses \CJKdigits/\CJKnumber (the commented cover.tex:29 pattern, uncommented), OR
#   (b) cls wraps \htu@cdate through \CJK@todaybig/\CJKdigits, OR (c) literal Chinese-numeral \cdate{二〇…}.
#   ⚠ DO NOT accept \CJK@todaybig naively = GREEN without checking it feeds the THESIS date (not compile-time \today):
#      \CJK@todaybig expands \the\year = compile date. Option (b) is correct only if \year/\month are the thesis values.
#      This grep proves the MECHANISM exists; the rendered-glyph proof (no ASCII year) is integration I08.
test_g4_cover_date_cn_mechanism() {
  [[ -f "htuthesis.cls" ]] || return 1
  [[ -f "data/cover.tex" ]] || return 1
  # (a) cover.tex ACTIVE (non-commented) \cdate with \CJKdigits/\CJKnumber/\CJK@todaybig
  local cover_active
  cover_active=$(grep -vE '^[[:space:]]*%' data/cover.tex | grep -cE '\\cdate.*\\CJK(digits|number|@todaybig)' || true)
  cover_active=$(echo "$cover_active" | tr -d '[:space:]' | head -1)
  # (b) cls cover-date SETTER (cls:602 \cdate{...} inside \htu@first@titlepage) uses a CJK-numeral macro.
  #   REPPOINTED (Story 3.15 G4 impl): probes the \cdate SETTER (cls:602), NOT the render node cls:697. Implemented
  #   mechanism = zhnumber package (\zhdigits year digit-form + \zhnumber month); \CJK@todaybig was dead code (uses
  #   undefined \CJKdigits/\CJKnumber, xeCJK doesn't provide them). Pre-impl: \cdate{\CJK@todaysmall@short} (Arabic).
  #   Authoritative rendered-glyph proof = integration ATDD-3.15-I08.
  local cls_node
  cls_node=$(grep -vE '^[[:space:]]*%' htuthesis.cls | grep -cE '\\cdate\{\\(zhdigits|zhnumber)' || true)
  cls_node=$(echo "$cls_node" | tr -d '[:space:]' | head -1)
  echo "  (cover.tex active CJK \\cdate: $cover_active; cls active CJK-numeral \\cdate setter: $cls_node)"
  [[ "$((cover_active + cls_node))" -ge 1 ]]
}
run_test "P1" "ATDD-3.15-04b" "G4: cover date CJK-numeral mechanism present (cls:697 / cover.tex:29; TC-E3-58, §1.1.1; RED pre-impl — Arabic; ⚠ \\CJK@todaybig compile-date trap — see story Dev Notes §G4)" test_g4_cover_date_cn_mechanism

# ==========================================
# GREEN guards — G3 must NOT delete HS default or break the Arabic counter lock
# ==========================================
echo "=== GREEN: G3 HS-default retained + \\thechapter Arabic lock (regression guards) ==="

# ATDD-3.15-05: GREEN guard — HS humanities numbering retained as default (ctex name={第,章} + number=\chinese{chapter}).
#   G3 restores NS as an OPT-IN option; it must NOT delete HS. Pre+post PASS.
test_g3_hs_default_retained() {
  [[ -f "htuthesis.cls" ]] || return 1
  read_cls_stripped | grep -qE 'name\s*=\s*\{\s*第\s*,\s*章\s*\}' && \
  read_cls_stripped | grep -qE 'number\s*=\s*\\chinese\{chapter\}'
}
run_test "P1" "ATDD-3.15-05" "GREEN: HS humanities numbering default retained (第一章; G3 must not delete HS; §2.10 HS path)" test_g3_hs_default_retained

# ATDD-3.15-06: GREEN guard — \thechapter Arabic defensive lock (cls:505) retained. G3 sc mode sets ctex number=
#   (display-only); it MUST NOT redefine \thechapter (else 图 一-1 / 图 A-1 counter disaster). Pre+post PASS.
test_thechapter_arabic_lock() {
  [[ -f "htuthesis.cls" ]] || return 1
  read_cls_stripped | grep -qE '\\renewcommand\{\\thechapter\}\{\\@arabic\\c@chapter\}'
}
run_test "P1" "ATDD-3.15-06" "GREEN: \\thechapter Arabic lock retained (cls:505; G3 sc must not break 图 1-1 counters; Story 3.13 AC-3a guardrail)" test_thechapter_arabic_lock

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
  echo "   RED drivers (FAIL pre-impl 6-gap state, PASS post-impl spec-compliant):"
  echo "      01 G1 TOC number-prefix \\rmfamily removed (cls:560, TC-E3-60, §2.6)"
  echo "      02 G6 heading format Latin-TNR guard (cls:463/475/484, TC-E3-61, §2.6/§2.10)"
  echo "      03 G3 numbering=sc option declared (NS restore, TC-E3-63, §2.10)"
  echo "      04 G5a appendix env body \\xiaosi\\songti (cls:956-968, TC-E3-62, §2.15)"
  echo "      04b G4 cover date CJK-numeral mechanism (cls:697/cover.tex, TC-E3-58, §1.1.1)"
  echo "   GREEN guards (PASS pre+post — HS default + \\thechapter Arabic lock; G3 must not regress):"
  echo "      05 HS humanities numbering default retained (§2.10 HS path)"
  echo "      06 \\thechapter Arabic lock cls:505 (Story 3.13 AC-3a; 图 1-1 counters)"
  echo ""
  echo "   These source-greps prove the WIRING; the fitz integration tests prove the RENDERED span. Together they"
  echo "   close the wrong-target-AC root cause (architecture silent-failure #13/#14; D-22). Line refs re-verified"
  echo "   vs HEAD 567e13a: G4 = cls:697 (not the audit's stale 602); G6 = cls:463/475/484 (cls:493 is \\htu@songtibold,"
  echo "   NOT a G6 target). Tests are read-only (no SUT mutation — Epic 1 retro)."
  echo "   ⚠ G4 \\CJK@todaybig compile-date trap: \\CJK@todaybig = \\the\\year = COMPILE date, not the thesis date."
  echo "      unit-04b proves a CJK-numeral MECHANISM exists; integration I08 proves the rendered glyphs are 二〇…"
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
