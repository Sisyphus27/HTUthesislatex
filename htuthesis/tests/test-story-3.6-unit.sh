#!/usr/bin/env bash
# test-story-3.6-unit.sh — ATDD Unit Tests for Story 3.6 (Figure, table, and equation formatting)
# TDD Phase: GREEN-GUARD (NO RED drivers — the caption/equation/subfigure machinery is INHERITED intact
#            from the original zzuthesis and ALREADY matches HTU spec §2.11/§2.12/§2.13 on every dimension
#            except the AC-3 separator character, which is DECISION-PENDING (spec "空半格" space vs reference
#            "：" colon vs current `\hspace{\ccwd}` space). These source-level greps prove the WIRING is present
#            and the invariants intact; they LOCK IN the correct inherited behavior so future stories (3.7/3.8/
#            Epic 4) cannot silently regress it. The companion integration suite proves the RENDERED captions/
#            equation via fitz.
#
# Usage: bash tests/test-story-3.6-unit.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P1/P2 (architecture.md:40 = 图表公式 LOW risk; no P0 — caption/equation formatting is cosmetic,
#           compilation passes pre-impl)
# Linked ACs: AC-1 (figure caption below 五号宋体 wiring), AC-2 (table caption above wiring),
#             AC-4 (subfigure (a)(b)(c) wiring), AC-5 (equation hyphen numbering — 2.6, consumed not re-defined),
#             AC-6 (caption 五号 font wiring), AC-3 (separator DECLARED — value-agnostic, decision-pending),
#             AC-7/AC-8 (regression — font stack, LOF/LOT scope, float params, counter separator intact)
# Linked Risk: R-12 (score 4 — caption/numbering change requires `latexmk -g`; only relevant IF AC-3 edits)
# TC coverage: TC-E3-28/29/30/31/32 (the behavior proofs live in the integration suite; these are wiring guards)
#
# NOTE: these are SOURCE-LEVEL greps — they prove the cls CONTAINS the caption/equation/subfigure wiring
#       (figureposition=bottom, tableposition=top, font=htu=\wuhao, thesubfigure=(\alph), theequation hyphen,
#       DeclareCaptionLabelSeparator declared) and the invariants are intact (3.9 font stack, LOF/LOT lists
#       out-of-scope, float params in def, 2.6 counter separator). The companion integration test proves the
#       RENDERED caption/equation via fitz (caption position y-ordering, SimSun 五号, equation right-align x1≈524,
#       subfigure (a)(b)). Source-greps prove the wiring; fitz proves the RENDERING (Story 2.5/2.6/3.1-3.5 lesson).
#       Tests are READ-ONLY — they MUST NOT modify the SUT (Epic 1/2 retro).
#
# ⚠️ AC-3 DECISION RESOLVED 2026-06-16: Zy chose Option A — caption separator = fullwidth colon "：" (U+FF1A),
#    following the reference PDF per CLAUDE.md Decision 4 (reference wins on visual detail; deviates from spec
#    §2.11/§2.12 "空半格" text — transparent deviation, Zy-approved). ATDD-3.6-07 asserts the cls declares {：}
#    (tightened from the value-agnostic guard); the behavior proof is ATDD-3.6-I12 (body captions render the colon).
#
# fitz calibration notes (verified pre-impl on main.pdf at baseline 6f73848):
#   - Figure caption "图 4-1 打高尔夫球的人" (p33): 图=SimSun 10.5, 4-1=TNR 10.5, title=SimSun 10.5; BELOW figure;
#     ~centered; separator gap "4-1"→title ≈ 11pt = `\hspace{\ccwd}` space. GREEN.
#   - Subfigure labels "(a) 清明" / "(b) 反复" (p36, fig 4-5): (a)/(b)=TNR 10.5, sub-title=SimSun 10.5. GREEN.
#   - Equation numbers "(4-1)".."(4-8)" (p40-42): TNR 12pt, x0≈500/x1≈524.4 (right text-edge). GREEN.
#   - Caption number font = TimesNewRomanPSMT (via 3.9 \setmainfont{TNR}); reference uses Calibri (Word artifact,
#     NOT a spec requirement — do not chase).

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
echo "ATDD Unit Tests: Story 3.6 — Figure, table, and equation formatting"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P1 Tests — caption/equation/subfigure WIRING (GREEN invariants — inherited zzuthesis config)
# ==========================================
echo "=== P1: caption/equation/subfigure wiring (GREEN — inherited config already matches spec) ==="

# ATDD-3.6-01: \captionsetup figureposition=bottom (AC-1 wiring, TC-E3-28)
# Truth source: spec §2.11 "图的编号及图题应在图的下方" + reference p95/p138 (caption below figure). The caption
#   block must set figureposition=bottom. GREEN pre/post (inherited zzuthesis; 3.6 does NOT change position).
test_captionsetup_figureposition_bottom() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'figureposition\s*=\s*bottom' htuthesis.cls
}
run_test "P1" "ATDD-3.6-01" "\\captionsetup figureposition=bottom (AC-1 wiring, TC-E3-28; GREEN — inherited)" test_captionsetup_figureposition_bottom

# ATDD-3.6-02: \captionsetup tableposition=top (AC-2 wiring, TC-E3-29)
# Truth source: spec §2.12 "表的编号及标表题置于表格上方" + reference p58/p140 (caption above table). The caption
#   block must set tableposition=top. GREEN pre/post (inherited zzuthesis).
test_captionsetup_tableposition_top() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'tableposition\s*=\s*top' htuthesis.cls
}
run_test "P1" "ATDD-3.6-02" "\\captionsetup tableposition=top (AC-2 wiring, TC-E3-29; GREEN — inherited)" test_captionsetup_tableposition_top

# ATDD-3.6-03: \DeclareCaptionFont{htu}{\wuhao...} — caption font = 五号 (AC-1/2/6 wiring, TC-E3-30)
# Truth source: spec §2.11/§2.12 "用五号宋体字". The caption font macro must set \wuhao (10.5pt). GREEN pre/post.
#   (The CJK FACE inherits the document default SimSun — verified in the integration suite I11; the macro sets
#   SIZE only, which is correct.)
test_caption_font_wuhao() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'DeclareCaptionFont\{htu\}\{\\wuhao' htuthesis.cls
}
run_test "P1" "ATDD-3.6-03" "\\DeclareCaptionFont{htu} uses \\wuhao (五号; AC-1/2/6 wiring, TC-E3-30; GREEN)" test_caption_font_wuhao

# ATDD-3.6-04: \captionsetup font=htu (the caption font is wired into captionsetup; AC-1/2/6)
# The captionsetup block must reference font=htu (the \wuhao font declared in 3.6-03). GREEN pre/post.
test_captionsetup_font_htu() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'font\s*=\s*htu' htuthesis.cls
}
run_test "P1" "ATDD-3.6-04" "\\captionsetup font=htu wired (AC-1/2/6; GREEN)" test_captionsetup_font_htu

# ATDD-3.6-05: \thesubfigure = (\alph{subfigure}) — subfigure labels (a)(b)(c) (AC-4 wiring, TC-E3-32)
# Truth source: spec §2.11 "用（a），（b），（c）按顺序编排". The subfigure counter must render as (a)(b)(c).
#   GREEN pre/post (inherited zzuthesis; 3.6 does NOT change it). Verified rendered in integration I09.
test_thesubfigure_alph() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'renewcommand\{?\\thesubfigure\}?\{\(\\alph\{subfigure\}\)\}' htuthesis.cls
}
run_test "P1" "ATDD-3.6-05" "\\thesubfigure=(\\alph{subfigure}) → (a)(b)(c) (AC-4 wiring, TC-E3-32; GREEN)" test_thesubfigure_alph

# ATDD-3.6-06: \theequation uses \htu@counter@separator (hyphen, AC-5 — 2.6 wiring, consumed not re-defined)
# Truth source: spec §2.13 "(1-1)" + architecture.md:87 "编号分隔符必须用短横线 `-`". The equation counter must
#   use \htu@counter@separator (the hyphen wired in Story 2.6). 3.6 CONSUMES 2.6's numbering; it must NOT have
#   re-defined or removed the separator. GREEN pre/post.
#   NOTE: \renewcommand\theequation{...} spans 2 lines (cls:398-399); join newlines before matching (the col-0 /
#   line-grep brittleness flagged for 2.2-2.6/3.2 deferred-work — tr-join sidesteps it).
test_theequation_separator() {
  [[ -f "htuthesis.cls" ]] || return 1
  local joined
  joined=$(tr '\n' ' ' < htuthesis.cls)
  grep -qE 'renewcommand.theequation.{0,140}htu@counter@separator' <<<"$joined"
}
run_test "P1" "ATDD-3.6-06" "\\theequation uses \\htu@counter@separator hyphen (AC-5; 2.6 wiring intact; GREEN)" test_theequation_separator

echo ""

# ==========================================
# P2 Tests — AC-3 separator DECLARED (value-agnostic, DECISION-PENDING) + scope/regression guards
# ==========================================
echo "=== P2: AC-3 separator declared (decision-pending) + scope/regression guards ==="

# ATDD-3.6-07: \DeclareCaptionLabelSeparator{htu}{\hspace{0.5\ccwd}} — caption separator = half-space (REPOINTED, TC-E3-30)
# REPOINTED by Story 3.13: was fullwidth colon {：} (AC-3 Option A, Zy 2026-06-16 reference-wins per Decision 4 v1);
#   now half-space \hspace{0.5\ccwd} (spec §2.11/§2.12 「编号和图题间空半格」PRIORITY, CLAUDE.md Decision 4 修正
#   2026-06-17, sprint-change-proposal-2026-06-17 gap 1a). The reference PDF's fullwidth colon is a Word-artifact
#   deviation, overridden by spec. Behavior proof: test-story-3.13-integration.sh I08 (0 fullwidth ： post-impl).
test_caption_labelsep_colon() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'DeclareCaptionLabelSeparator\{htu\}\{\\hspace\{0\.5\\ccwd\}\}' htuthesis.cls
}
run_test "P1" "ATDD-3.6-07" "\\DeclareCaptionLabelSeparator{htu}{\\hspace{0.5\\ccwd}} half-space (REPOINTED by 3.13: spec §2.11/2.12 空半格; was {：} reference-wins)" test_caption_labelsep_colon

# ATDD-3.6-08: regression — \setmainfont{Times New Roman} preserved (Story 3.9, AC-7/AC-8)
# 3.6 consumes 3.9's \rmfamily→TNR so caption Latin digits/parens render TNR (NOT Latin Modern). Must remain intact.
test_setmainfont_tnr_preserved() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'setmainfont\{Times New Roman\}' htuthesis.cls
}
run_test "P2" "ATDD-3.6-08" "regression: \\setmainfont{Times New Roman} preserved (Story 3.9, AC-7/8)" test_setmainfont_tnr_preserved

# ATDD-3.6-09: scope guard — \titlecontents{figure}/\titlecontents{table} UNCHANGED (out-of-scope; §1.1.5)
# Story 3.6 must NOT touch the figure/table LIST formatting (插图清单/表格清单 — spec §1.1.5, NOT §2.11/§2.12/FR-18).
#   These stay on \wuhao[1.524] (exactly as Story 3.5 declared). GREEN pre/post — a scope-violation guard.
test_figuretable_lists_unchanged() {
  [[ -f "htuthesis.cls" ]] || return 1
  local fig table
  fig=$(grep -E 'titlecontents\{figure\}' htuthesis.cls 2>/dev/null | head -1)
  table=$(grep -E 'titlecontents\{table\}' htuthesis.cls 2>/dev/null | head -1)
  [[ -n "$fig" && -n "$table" ]] || return 1
  echo "$fig" | grep -q 'wuhao\[1.524\]' && echo "$table" | grep -q 'wuhao\[1.524\]'
}
run_test "P2" "ATDD-3.6-09" "scope guard: \\titlecontents{figure/table} lists unchanged (§1.1.5 out-of-scope; GREEN)" test_figuretable_lists_unchanged

# ATDD-3.6-10: regression — \renewcommand{\thesubtable}{(\alph{subtable})} preserved (AC-4 sibling)
# The subtable counter (sibling of thesubfigure) must remain (a)(b)(c). GREEN pre/post.
test_thesubtable_alph() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'renewcommand\{?\\thesubtable\}?\{\(\\alph\{subtable\}\)\}' htuthesis.cls
}
run_test "P2" "ATDD-3.6-10" "regression: \\thesubtable=(\\alph{subtable}) preserved (AC-4 sibling; GREEN)" test_thesubtable_alph

# ATDD-3.6-11: regression — caption float params externalized in .def (AC-7 — not tunable knobs, stay in def)
# The caption above/below skip params must remain in htuthesis.def (externalized in Story 1.2). GREEN pre/post.
test_caption_params_in_def() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -qE 'def\\htu@caption@figure@aboveskip' htuthesis.def && \
  grep -qE 'def\\htu@caption@figure@belowskip' htuthesis.def && \
  grep -qE 'def\\htu@caption@table@aboveskip' htuthesis.def && \
  grep -qE 'def\\htu@caption@sub@skip' htuthesis.def
}
run_test "P2" "ATDD-3.6-11" "regression: caption float params in .def (AC-7; GREEN — externalized in 1.2)" test_caption_params_in_def

# ATDD-3.6-12: scope guard — \thefigure/\thetable use \htu@counter@separator (2.6 intact, 3.6 does NOT touch)
# 3.6 owns caption PRESENTATION, not the NUMBER FORMAT. The figure/table counters must still use the 2.6 hyphen
#   separator (3.6 must not have re-defined them). GREEN pre/post — a scope-violation guard (mirrors ATDD-3.6-06
#   for the figure/table counters). NOTE: each \renewcommand block spans 2 lines (cls:400-403); join newlines.
test_thefigure_thetable_separator() {
  [[ -f "htuthesis.cls" ]] || return 1
  local joined
  joined=$(tr '\n' ' ' < htuthesis.cls)
  grep -qE 'renewcommand.thefigure.{0,140}htu@counter@separator' <<<"$joined" && \
  grep -qE 'renewcommand.thetable.{0,140}htu@counter@separator' <<<"$joined"
}
run_test "P2" "ATDD-3.6-12" "scope guard: \\thefigure/\\thetable hyphen separator intact (2.6; 3.6 does not touch; GREEN)" test_thefigure_thetable_separator

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
  echo "   RED drivers: NONE — Story 3.6 is VERIFY-GREEN (caption/equation/subfigure config inherited intact"
  echo "      from zzuthesis, already matches spec §2.11/§2.12/§2.13). AC-3 separator RESOLVED 2026-06-16 to"
  echo "      Option A (fullwidth colon, reference PDF per Decision 4); 3.6-07 asserts {：}, behavior proof is I12."
  echo "   GREEN guards (lock-in): 3.6-01 (figureposition=bottom), 3.6-02 (tableposition=top),"
  echo "      3.6-03 (caption font \\wuhao 五号), 3.6-04 (font=htu wired), 3.6-05 (\\thesubfigure (a)(b)(c)),"
  echo "      3.6-06 (\\theequation hyphen), 3.6-07 (separator {：} colon — AC-3 Option A), 3.6-08 (TNR preserved),"
  echo "      3.6-09 (LOF/LOT lists unchanged), 3.6-10 (\\thesubtable), 3.6-11 (caption params in .def),"
  echo "      3.6-12 (\\thefigure/\\thetable hyphen intact)."
  echo ""
  echo "   NOTE: source-greps prove the WIRING; the integration suite proves the RENDERED captions/equation via"
  echo "         fitz (figure caption BELOW figure, table caption ABOVE table, SimSun 五号, equation right-align"
  echo "         x1≈524, subfigure (a)(b), caption-number TNR, caption-title SimSun). architecture.md:40 = LOW risk."
  echo "         Tests are read-only — they do not modify the SUT."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
