#!/usr/bin/env bash
# test-story-3.5-unit.sh — ATDD Red-Phase Unit Tests for Story 3.5 (Table of contents formatting)
# TDD Phase: RED (source-level greps; the TOC \titlecontents wiring tests FAIL on pre-impl —
#            \titlecontents{chapter} before-arg is \sihao[1] (14pt 宋体, NOT \xiaosi[1] 12pt 黑体),
#            \titlecontents{subsection} is \wuhao[1] (10.5pt, NOT \xiaosi[1] 12pt),
#            the chapter leader has no \rmfamily page-number guard; the title/depth/indent/font-stack
#            guards pass — the TOC title + L2 section are already correct)
#
# Usage: bash tests/test-story-3.5-unit.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P1/P2 (R-17 = score 2 LOW; no P0 — TOC styling is cosmetic, no compilation blocker)
# Linked ACs: AC-2 (L1 chapter 小四号 黑体), AC-4 (L3 subsection 小四号),
#             AC-1 (title 目 录 verify), AC-5 (indent verify), AC-7 (depth verify),
#             AC-8 (regression — font stack, section/figure-table scope guards)
# Linked Risk: R-17 (score 2, LOW — TOC dot leaders + level fonts; cosmetic)
# TC coverage: TC-E3-24/25/26/27 (the P1/P2 TOC tests — behavior proofs live in the integration suite)
#
# NOTE: these are SOURCE-LEVEL greps — they prove the cls CONTAINS the TOC entry wiring (L1 黑体小四号,
#       L3 小四号, the L1 page-number \rmfamily guard) and the invariants are intact (title 目 录, depth,
#       font stack, L2 section unchanged, figure/table lists out-of-scope). The companion integration test
#       (test-story-3.5-integration.sh) proves the RENDERED TOC page via fitz (title font/size/centering,
#       L1 SimHei 小四号, L2 SimSun 小四号, indent deltas, dot leaders, L1 page-number TNR). Source-greps
#       prove the wiring; fitz proves the RENDERING (Story 2.5/2.6/3.1/3.2/3.9 lesson). Tests are
#       READ-ONLY — they MUST NOT modify the SUT (Epic 1/2 retro).
#
# ⚠️ Comment-inflation (Stories 1.4 / 3.2 / 3.9 / 3.3 / 3.4 lesson): if a [基础] comment literally quotes a
#    target string (e.g. "titlecontents chapter xiaosi sffamily"), the grep false-passes/false-fails. The dev
#    must keep [基础] comments paraphrased. The RED-phase run (bash ... --run on the pre-impl baseline acb4e5b)
#    confirms each scaffold actually fails pre-impl — the TDD RED guarantee.
#
# fitz calibration notes (verified pre-impl on main.pdf at baseline acb4e5b):
#   - TOC title "目录" renders SimHei 16.0pt centered (GREEN — via \htu@chapter* \sffamily\sanhao).
#   - L1 chapter entries (模板简介及安装/关于该模板的使用/常用排版示例/参考文献) render SimSun 14.0pt at x0≈92
#     (RED — should be SimHei 12.0pt per spec §2.6 + reference p10). 4 such entries detected.
#   - L2 section entries render SimSun 12.0pt at x0≈95 (GREEN — already correct).
#   - L3 subsection entries: \tocdepth=2 + sample \subsection* → no L3 row renders in main.pdf p11. The \wuhao
#     rule is verified at the SOURCE level (this suite) + a scratch depth-3 raise (documented in the story
#     Dev Notes "Verifying AC-4 when the sample has no L3 row") for the behavior proof.
#   - Page-number spans (20) all TimesNewRomanPSMT 12pt — GREEN pre-impl; the \rmfamily guard (Task 1.2)
#     keeps them TNR post-impl (a missing guard would regress them to LMSans via the L1 \sffamily).

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
echo "ATDD Unit Tests: Story 3.5 — Table of contents formatting"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P2 Tests — L1/L3 \titlecontents wiring (RED pre-impl)
# ==========================================
echo "=== P2: TOC L1 (黑体小四号) + L3 (小四号) \titlecontents wiring (RED pre-impl) ==="

# ATDD-3.5-01: \titlecontents{chapter} before-arg uses \xiaosi (12pt), NOT \sihao (14pt) (AC-2, TC-E3-25)
# Truth source: spec §2.6 "一级标题用小四号黑体字" + reference p10 (SimHei 12.00pt). Current cls:518 =
#   \titlecontents{chapter}[\z@]{\vspace{6bp}\sihao[1]} → 14pt. The chapter before-arg must read \xiaosi, not
#   \sihao. RED pre-impl (\sihao present in the chapter line). Post-impl (Task 1.1) → \xiaosi → GREEN.
#   NOTE: anchor to the chapter titlecontents line specifically (the section/subsection lines also exist);
#   grep the line beginning with \titlecontents{chapter} and assert it has xiaosi, not sihao.
test_chapter_titlecontents_xiaosi() {
  [[ -f "htuthesis.cls" ]] || return 1
  local line
  line=$(grep -E 'titlecontents\{chapter\}' htuthesis.cls 2>/dev/null | head -1)
  [[ -n "$line" ]] || return 1
  echo "  (chapter line: ${line:0:70})"
  # must contain xiaosi, must NOT contain sihao
  echo "$line" | grep -q 'xiaosi' && ! echo "$line" | grep -q 'sihao'
}
run_test "P2" "ATDD-3.5-01" "\titlecontents{chapter} before = \xiaosi (12pt) not \sihao (AC-2, TC-E3-25; RED — cls:518 has \sihao[1])" test_chapter_titlecontents_xiaosi

# ATDD-3.5-02: \titlecontents{chapter} before-arg has \sffamily for 黑体 (AC-2, TC-E3-25)
# Truth source: spec §2.6 黑体 + reference p10 SimHei. \sffamily→SimHei via 3.9 \setCJKsansfont (cls:102). The
#   chapter before-arg must issue \sffamily so the CJK entry renders 黑体. RED pre-impl (no \sffamily in the
#   chapter line → SimSun). Post-impl (Task 1.1) → \sffamily → GREEN.
test_chapter_titlecontents_sffamily() {
  [[ -f "htuthesis.cls" ]] || return 1
  local line
  line=$(grep -E 'titlecontents\{chapter\}' htuthesis.cls 2>/dev/null | head -1)
  [[ -n "$line" ]] || return 1
  echo "$line" | grep -q 'sffamily'
}
run_test "P2" "ATDD-3.5-02" "\titlecontents{chapter} before has \sffamily (黑体 via 3.9; AC-2, TC-E3-25; RED — no \sffamily pre-impl)" test_chapter_titlecontents_sffamily

# ATDD-3.5-03: \titlecontents{subsection} before-arg uses \xiaosi (12pt), NOT \wuhao (10.5pt) (AC-4, TC-E3-27)
# Truth source: spec §2.6 "其余用小四号宋体字" + reference p10 (SimSun 12.00pt). Current cls:524 =
#   \titlecontents{subsection}[4\ccwd]{\vspace{6bp}\wuhao[1]} → 10.5pt. The subsection before-arg must read
#   \xiaosi, not \wuhao. RED pre-impl (\wuhao present). Post-impl (Task 2.1) → \xiaosi → GREEN. (No L3 row
#   renders at \tocdepth=2 in the sample, so the behavior proof is the scratch depth-3 raise — see the
#   integration suite I11 + story Dev Notes Task 2.2; this source-grep is the standing guard.)
test_subsection_titlecontents_xiaosi() {
  [[ -f "htuthesis.cls" ]] || return 1
  local line
  line=$(grep -E 'titlecontents\{subsection\}' htuthesis.cls 2>/dev/null | head -1)
  [[ -n "$line" ]] || return 1
  echo "  (subsection line: ${line:0:70})"
  echo "$line" | grep -q 'xiaosi' && ! echo "$line" | grep -q 'wuhao'
}
run_test "P2" "ATDD-3.5-03" "\titlecontents{subsection} before = \xiaosi (12pt) not \wuhao (AC-4, TC-E3-27; RED — cls:524 has \wuhao[1])" test_subsection_titlecontents_xiaosi

# ATDD-3.5-04: \titlecontents{chapter} LEADER has \rmfamily page-number guard (AC-2, the Task 1.2 guard)
# Truth source: the L1 \sffamily (Task 1.1) propagates into the leader region → \contentspage (Latin digit)
#   would render LMSans. Task 1.2 restores \rmfamily before \contentspage so the page number stays TNR. The
#   chapter leader must contain \rmfamily ... \contentspage. RED pre-impl (no \rmfamily in the chapter leader;
#   current leader = \titlerule*{.}\xiaosi\contentspage). Post-impl (Task 1.2) → \rmfamily\contentspage → GREEN.
#   NOTE: grep the chapter titlecontents block — its leader is the 3rd argument line. Anchor: a line with
#   titlerule + contentspage that follows the chapter entry. Simpler: assert SOME leader line in the chapter
#   block has rrmfamily adjacent to contentspage. Use the full chapter-block grep.
test_chapter_leader_rmfaily_guard() {
  [[ -f "htuthesis.cls" ]] || return 1
  # Extract the chapter titlecontents block (from \titlecontents{chapter} to the next \titlecontents or section).
  # The leader arg contains \titlerule*{.} ... \contentspage. Assert rrmfamily appears between titlerule and contentspage.
  local block
  block=$(awk '/titlecontents\{chapter\}/{f=1} f{print} /titlecontents\{section\}/{if(f)exit}' htuthesis.cls 2>/dev/null)
  [[ -n "$block" ]] || return 1
  # Look for a leader line (has titlerule + contentspage) WITH rrmfamily
  echo "$block" | grep -E 'titlerule' | grep -q 'rmfamily'
}
run_test "P2" "ATDD-3.5-04" "\titlecontents{chapter} leader has \rmfamily page-number guard (AC-2 Task 1.2; RED — no \rmfamily pre-impl)" test_chapter_leader_rmfaily_guard

echo ""

# ==========================================
# P1 Tests — regression / invariant guards (GREEN pre- and post-impl)
# ==========================================
echo "=== P1: title 目 录 + depth + font stack + L2/L2-scope guards (GREEN invariants) ==="

# ATDD-3.5-05: regression — \contentsname "目 录" intact (AC-1, TC-E3-24)
# Story 3.5 must NOT change the title text ("目" + \ccwd space + "录" = spec §2.6 "两字间空一格"). GREEN pre/post.
test_contentsname_intact() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'contentsname=\{目\\hspace\{\\ccwd\} 录\}' htuthesis.cls
}
run_test "P1" "ATDD-3.5-05" "regression: \contentsname \"目 录\" intact (AC-1, TC-E3-24; GREEN — already correct)" test_contentsname_intact

# ATDD-3.5-06: regression — \htu@tocdepth{2} preserved (AC-7, TC-E3-27)
# Story 3.5 must NOT change the TOC depth (spec §1.1.4 "显示到三级标题" → tocdepth=2 = subsection). GREEN pre/post.
test_tocdepth_preserved() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -qE 'def\\htu@tocdepth\{2\}' htuthesis.def
}
run_test "P1" "ATDD-3.5-06" "regression: \htu@tocdepth{2} preserved (AC-7, TC-E3-27; GREEN)" test_tocdepth_preserved

# ATDD-3.5-07: regression — \setCJKsansfont{SimHei} preserved (Story 3.9, AC-8)
# 3.5 consumes 3.9's \sffamily→SimHei for the L1 TOC entries; the font stack must remain intact.
test_setcjksansfont_simhei_preserved() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'setCJKsansfont\{SimHei\}' htuthesis.cls
}
run_test "P1" "ATDD-3.5-07" "regression: \setCJKsansfont{SimHei} preserved (Story 3.9, AC-8)" test_setcjksansfont_simhei_preserved

# ATDD-3.5-08: regression — \setmainfont{Times New Roman} preserved (Story 3.9, AC-8)
# 3.5 consumes 3.9's \rmfamily→TNR for the L1 page-number guard (Task 1.2); must remain intact.
test_setmainfont_tnr_preserved() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'setmainfont\{Times New Roman\}' htuthesis.cls
}
run_test "P1" "ATDD-3.5-08" "regression: \setmainfont{Times New Roman} preserved (Story 3.9, AC-8)" test_setmainfont_tnr_preserved

echo ""

# ==========================================
# P2 Tests — scope / structural guards (GREEN pre- and post-impl)
# ==========================================
echo "=== P2: L2 section unchanged + figure/table lists out-of-scope + \tableofcontents intact ==="

# ATDD-3.5-09: regression — \titlecontents{section} unchanged (L2 宋体小四号 at 2\ccwd; AC-3, TC-E3-25)
# Story 3.5 must NOT change the L2 section entry (spec §2.6 "其余用小四号宋体字"; already correct). The section
#   before-arg must remain \xiaosi[1] at indent 2\ccwd. GREEN pre/post.
test_section_titlecontents_unchanged() {
  [[ -f "htuthesis.cls" ]] || return 1
  local line
  line=$(grep -E 'titlecontents\{section\}' htuthesis.cls 2>/dev/null | head -1)
  [[ -n "$line" ]] || return 1
  echo "$line" | grep -q '2\\ccwd' && echo "$line" | grep -q 'xiaosi'
}
run_test "P2" "ATDD-3.5-09" "regression: \titlecontents{section} L2 宋体小四号 2\ccwd unchanged (AC-3, TC-E3-25; GREEN)" test_section_titlecontents_unchanged

# ATDD-3.5-10: scope guard — \titlecontents{figure}/\titlecontents{table} UNCHANGED (out-of-scope; §1.1.5)
# Story 3.5 must NOT touch the figure/table LIST formatting (插图清单/表格清单 — spec §1.1.5, NOT §2.6/FR-17).
#   These stay on \wuhao[1.524]. GREEN pre/post — a scope-violation guard.
test_figuretable_lists_unchanged() {
  [[ -f "htuthesis.cls" ]] || return 1
  local fig table
  fig=$(grep -E 'titlecontents\{figure\}' htuthesis.cls 2>/dev/null | head -1)
  table=$(grep -E 'titlecontents\{table\}' htuthesis.cls 2>/dev/null | head -1)
  [[ -n "$fig" && -n "$table" ]] || return 1
  echo "$fig" | grep -q 'wuhao\[1.524\]' && echo "$table" | grep -q 'wuhao\[1.524\]'
}
run_test "P2" "ATDD-3.5-10" "scope guard: \titlecontents{figure/table} lists unchanged (§1.1.5 out-of-scope; GREEN)" test_figuretable_lists_unchanged

# ATDD-3.5-11: regression — \tableofcontents redefinition intact (AC-1 structural guard)
# Story 3.5 must NOT remove/rename \tableofcontents or break the \htu@chapter*[]{\contentsname} title mechanism.
#   GREEN pre/post — a structural invariant guard.
test_tableofcontents_intact() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'renewcommand\\tableofcontents' htuthesis.cls && \
  grep -qE 'htu@chapter\*\[\]\{\\contentsname\}' htuthesis.cls
}
run_test "P2" "ATDD-3.5-11" "regression: \tableofcontents + \htu@chapter*[]{\contentsname} intact (AC-1 structural guard; GREEN)" test_tableofcontents_intact

# ATDD-3.5-12: regression — \titlecontents indent per level preserved (AC-5, TC-E3-27)
# chapter [0] / section [2\ccwd] / subsection [4\ccwd] = one CJK char per level (≈24pt at 12pt; ref p10 delta).
#   GREEN pre/post — the indents already match the reference.
test_indent_per_level_preserved() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'titlecontents\{chapter\}\[\\z@' htuthesis.cls && \
  grep -qE 'titlecontents\{section\}\[2\\ccwd' htuthesis.cls && \
  grep -qE 'titlecontents\{subsection\}\[4\\ccwd' htuthesis.cls
}
run_test "P2" "ATDD-3.5-12" "regression: indent 0/2\ccwd/4\ccwd per level preserved (AC-5, TC-E3-27; GREEN)" test_indent_per_level_preserved

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
  echo "   RED (fail pre-impl): 3.5-01 (chapter \xiaosi not \sihao), 3.5-02 (chapter \sffamily for 黑体),"
  echo "      3.5-03 (subsection \xiaosi not \wuhao), 3.5-04 (chapter leader \rmfamily guard)."
  echo "   GREEN guards: 3.5-05 (contentsname 目 录), 3.5-06 (tocdepth 2), 3.5-07 (setCJKsansfont SimHei),"
  echo "      3.5-08 (setmainfont TNR), 3.5-09 (section L2 unchanged), 3.5-10 (figure/table lists unchanged),"
  echo "      3.5-11 (\tableofcontents intact), 3.5-12 (indent per level)."
  echo ""
  echo "   NOTE: source-greps prove the WIRING (L1 黑体小四号, L3 小四号, \rmfamily page-number guard); the"
  echo "         integration suite proves the RENDERED TOC page via fitz (title SimHei ~16pt centered,"
  echo "         L1 SimHei 小四号 [I05 — THE FIX proof], L2 SimSun 小四号, indent deltas, dot leaders,"
  echo "         L1 page-number TNR guard [I06 — catches a missing Task-1.2 \rmfamily]). R-17 = LOW risk"
  echo "         (cosmetic); no P0 tests. Tests are read-only — they do not modify the SUT."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
