#!/usr/bin/env bash
# test-story-3.4-unit.sh — ATDD Red-Phase Unit Tests for Story 3.4 (Chinese and English abstract formatting)
# TDD Phase: RED (source-level greps; the English-abstract wiring tests FAIL on pre-impl — \eabstractname is
#            "Abstract" not "ABSTRACT", no \rmfamily\bfseries title override, no 五号 English body scope,
#            \htu@ekeywords@separator is "; " not ", ", KEY WORDS label is \textbf-bold, \enskip present;
#            the Chinese-side + font-stack guards pass — the abstract formatting is mostly English-side work)
#
# Usage: bash tests/test-story-3.4-unit.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 tests are blocking
# Linked ACs: AC-4 (English title ABSTRACT TNR Bold), AC-5 (English body 五号 TNR ~23.4bp — R-14),
#             AC-6 (English keywords comma + non-bold label), AC-7 (\enskip), AC-1/AC-3 (Chinese verify),
#             AC-8 (regression — font stack, no \setstretch)
# Linked Risk: R-14 (score 6, English-abstract independent baselineskip — the dominant Epic-3 TECH risk)
# TC coverage: TC-E3-18/19/20/21/22/23 (the P0/P1 abstract tests — behavior proofs live in the integration suite)
#
# NOTE: these are SOURCE-LEVEL greps — they prove the cls CONTAINS the English-abstract wiring (uppercase
#       title, TNR-Bold title override, 五号 body scope, half-width-comma separator, non-bold label) and the
#       font stack is intact. The companion integration test (test-story-3.4-integration.sh) proves the
#       RENDERED abstract pages via fitz (title font/size/centering, body 五号 + ~23.4bp line-gap, keyword
#       separator, Chinese title/body/keywords). Source-greps prove the wiring; fitz proves the RENDERING
#       (Story 2.5/2.6/3.1/3.2/3.9 lesson). Tests are READ-ONLY — they MUST NOT modify the SUT (Epic 1/2 retro).
#
# ⚠️ Comment-inflation (Stories 1.4 / 3.2 / 3.9 / 3.3 lesson): if a [基础] comment literally quotes a target
#    string (e.g. "rmfamily bfseries", "KEY WORDS:\enskip"), the grep false-passes/false-fails. The dev must
#    keep [基础] comments paraphrased. The RED-phase run (bash ... --run on the pre-impl baseline 227362f)
#    confirms each scaffold actually fails pre-impl — the TDD RED guarantee.
#
# fitz calibration notes (verified pre-impl on main.pdf at baseline 227362f):
#   - Post-3.9, \rmfamily Latin = TNR; the English abstract BODY is already TNR (just at the wrong size 12pt
#     and wrong baselineskip 18bp, inheriting the body). The English TITLE "Abstract" routes through the
#     \sffamily chapter format → LMSans (the deferred-work \sffamily-Latin gap this story closes).
#   - So the RED signals here are WIRING (source) + the integration suite proves the rendered size/line-gap.

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
echo "ATDD Unit Tests: Story 3.4 — Chinese and English abstract formatting"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%) — English-abstract wiring (RED pre-impl)
# ==========================================
echo "=== P0: English title ABSTRACT TNR Bold + 五号 body scope (RED pre-impl) ==="

# ATDD-3.4-01: \eabstractname = ABSTRACT (uppercase) (AC-4, TC-E3-21)
# Truth source: spec §2.8 line 219 + reference thesis PDF page 6 (TimesNewRomanPS-BoldMT "ABSTRACT").
#   Current cls:195 = "Abstract" (mixed case). Uppercase "ABSTRACT" is absent pre-impl → RED.
#   Post-impl (Task 1.1) → GREEN. (Note: keep [基础] comments paraphrased — do not quote "ABSTRACT" verbatim
#   in a way a loose grep would match; this grep is anchored to the macro def.)
test_eabstractname_uppercase() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'newcommand\{?\\?eabstractname\}\{ABSTRACT\}' htuthesis.cls
}
run_test "P0" "ATDD-3.4-01" "\\eabstractname = ABSTRACT uppercase (AC-4, TC-E3-21; RED — cls:195 has \"Abstract\")" test_eabstractname_uppercase

# ATDD-3.4-02: English title rendered TNR Bold — \rmfamily\bfseries override on the eabstractname chapter call (AC-4)
# Truth source: spec §2.8 + reference p6 (TNR Bold). The title must override the \sffamily chapter format for its
#   Latin glyphs. Current cls:830 = "\htu@chapter*[]{\eabstractname}" (no font override → LMSans). Post-impl
#   (Task 1.2) = "\htu@chapter*[]{\rmfamily\bfseries\eabstractname}". The \rmfamily...eabstractname combo is
#   absent pre-impl → RED. (PRIMARY approach from Task 1.2 — the in-arg font switch, NOT a \ctexset override.)
test_english_title_tnr_bold_wired() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'rmfamily.{0,60}eabstractname' htuthesis.cls
}
run_test "P0" "ATDD-3.4-02" "English title TNR-Bold override (\\rmfamily\\bfseries on \\eabstractname call; AC-4; RED — cls:830 has no override)" test_english_title_tnr_bold_wired

# ATDD-3.4-03: English body 五号 scope present — \fontsize{10.5bp} (AC-5, R-14)
# Truth source: spec §2.8 line 221 + reference p6 (TNR 10.4pt ≈ 五号). The English body needs a 五号 scope
#   (currently inherits 12pt body). Task 2.1 sets it via \fontsize{10.5bp}{<baselineskip>}\selectfont.
#   \fontsize{10.5bp absent pre-impl → RED. Post-impl → GREEN. (五号 = 10.5bp.)
test_english_body_wuhao_scope() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'fontsize\{10\.5bp\}' htuthesis.cls
}
run_test "P0" "ATDD-3.4-03" "English body 五号 scope (\\fontsize{10.5bp}; AC-5/R-14; RED — absent pre-impl, body inherits 12pt)" test_english_body_wuhao_scope

echo ""

# ==========================================
# P1 Tests (>=95%) — keyword separator/label + \enskip + regression guards
# ==========================================
echo "=== P1: keyword separator + non-bold label + \\enskip + Chinese/font-stack guards ==="

# ATDD-3.4-04: \htu@ekeywords@separator = ", " (half-width comma) (AC-6, TC-E3-23)
# Truth source: spec §2.8 line 223 "半角逗号" + reference p9 "governance, Responsive". Current cls:197 = "; "
#   (semicolon). Half-width-comma separator absent pre-impl → RED. Post-impl (Task 3.1) → GREEN.
#   NOTE: the parser (cls:802 \htu@parse@keywords) splits the \ekeywords arg by comma (\@for) and rejoins with
#   this @separator, so the OUTPUT separator is whatever this macro is — changing it to ", " yields "a, b, c".
test_ekeywords_comma_separator() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'def\\htu@ekeywords@separator\{, \}' htuthesis.cls
}
run_test "P1" "ATDD-3.4-04" "\\htu@ekeywords@separator = \", \" half-width comma (AC-6, TC-E3-23; RED — cls:197 has \"; \")" test_ekeywords_comma_separator

# ATDD-3.4-05: English KEY WORDS label NON-bold — no \textbf before \htu@ekeywords@title (AC-6, user decision)
# Truth source: RESOLVED 2026-06-16 (user, reference wins) — spec §2.8 "加粗" vs reference p9 TimesNewRomanPSMT
#   (non-bold) → NON-bold. Current cls:834 = "\textbf\htu@ekeywords@title" (bold). \textbf adjacent to the
#   English keyword label = 1 pre-impl → RED. Post-impl (Task 3.3, drop \textbf) → 0 → GREEN.
#   NOTE: grep targets the ENGLISH label (ekeywords@title), NOT the Chinese one (ckeywords@title) — the Chinese
#   label keeps \textbf (→ SimHei, AC-3 unchanged).
test_ekeywords_label_nonbold() {
  [[ -f "htuthesis.cls" ]] || return 1
  local n
  n=$(grep -cF 'textbf\htu@ekeywords@title' htuthesis.cls 2>/dev/null || true)
  n=$(echo "$n" | tr -d '[:space:]' | head -1)
  echo "  ('textbf\htu@ekeywords@title' matches: $n; expect 0 post-impl, 1 pre-impl cls:834)"
  [[ "$n" -eq 0 ]]
}
run_test "P1" "ATDD-3.4-05" "English KEY WORDS label NON-bold (\\textbf dropped; AC-6, user decision; RED — cls:834 has \\textbf)" test_ekeywords_label_nonbold

# ATDD-3.4-06: \htu@ekeywords@title drops \enskip (AC-7, deferred-work §spec-defer)
# Truth source: reference p9 text extraction = "KEY WORDS:Digitalization" (no character between colon and the
#   first keyword); the current cls:202 = "KEY WORDS:\enskip" adds a half-em space. Task 3.2 removes \enskip
#   (unless a high-zoom visual check reveals a real gap — in which case REPOINT this test to a GREEN guard per
#   Decision 2; the empirical text extraction strongly supports removal).
test_ekeywords_no_enskip() {
  [[ -f "htuthesis.cls" ]] || return 1
  local n
  n=$(grep -cF 'KEY WORDS:\enskip' htuthesis.cls 2>/dev/null || true)
  n=$(echo "$n" | tr -d '[:space:]' | head -1)
  echo "  ('KEY WORDS:\enskip' matches: $n; expect 0 post-impl [drop \enskip], 1 pre-impl cls:202)"
  echo "  (AC-7 contingency: if a high-zoom visual shows a real gap, REPOINT to GREEN guard per Decision 2)"
  [[ "$n" -eq 0 ]]
}
run_test "P1" "ATDD-3.4-06" "\\htu@ekeywords@title drops \\enskip (AC-7; RED — cls:202 has \enskip; Decision-2 repoint if visual differs)" test_ekeywords_no_enskip

# ATDD-3.4-07: regression — \cabstractname "摘 要" intact (AC-1, TC-E3-18)
# Story 3.4 must NOT change the Chinese title text ("摘" + \ccwd space + "要" = spec §2.7 "空一格"). The macro
#   must still carry the one-CJK-width space. GREEN pre- and post-impl.
test_cabstractname_intact() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'newcommand\{?\\?cabstractname\}\{摘\\hspace\{\\ccwd\} 要\}' htuthesis.cls
}
run_test "P1" "ATDD-3.4-07" "regression: \\cabstractname \"摘 要\" intact (AC-1, TC-E3-18; GREEN — already correct)" test_cabstractname_intact

# ATDD-3.4-08: regression — \htu@ckeywords@separator = ； (full-width semicolon) intact (AC-3, TC-E3-20)
# Story 3.4 must NOT change the Chinese keyword separator (spec §2.7 "分号隔开"). GREEN pre- and post-impl.
test_ckeywords_separator_intact() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qF 'htu@ckeywords@separator{；}' htuthesis.cls
}
run_test "P1" "ATDD-3.4-08" "regression: \\htu@ckeywords@separator ； intact (AC-3, TC-E3-20; GREEN)" test_ckeywords_separator_intact

# ATDD-3.4-09: regression — \setmainfont{Times New Roman} preserved (Story 3.9, AC-8)
# 3.4 consumes 3.9's \rmfamily→TNR; the font stack must remain intact.
test_setmainfont_tnr_preserved() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'setmainfont\{Times New Roman\}' htuthesis.cls
}
run_test "P1" "ATDD-3.4-09" "regression: \\setmainfont{Times New Roman} preserved (Story 3.9, AC-8)" test_setmainfont_tnr_preserved

# ATDD-3.4-10: regression — \setCJKsansfont{SimHei} preserved (Story 3.9, AC-8)
# 3.4 consumes 3.9's \sffamily→SimHei (the Chinese title "摘 要" via \htu@chapter* renders SimHei); must remain.
test_setcjksansfont_simhei_preserved() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'setCJKsansfont\{SimHei\}' htuthesis.cls
}
run_test "P1" "ATDD-3.4-10" "regression: \\setCJKsansfont{SimHei} preserved (Story 3.9, AC-8)" test_setcjksansfont_simhei_preserved

# ATDD-3.4-11: regression — NO \setstretch in cls (R-3 anti-pattern, AC-5/AC-8)
# R-14 mitigation: the English-abstract baselineskip MUST be set via \fontsize/@setfontsize, NEVER \setstretch
#   (ctex applies a ~1.2× multiplier → 25.2bp trap). GREEN pre- and post-impl.
test_no_setstretch() {
  [[ -f "htuthesis.cls" ]] || return 1
  local n
  n=$(grep -c 'setstretch' htuthesis.cls 2>/dev/null || true)
  n=$(echo "$n" | tr -d '[:space:]' | head -1)
  echo "  (setstretch matches: $n; expect 0 — R-14 mandates \\fontsize, never \\setstretch)"
  [[ "$n" -eq 0 ]]
}
run_test "P1" "ATDD-3.4-11" "regression: NO \\setstretch in cls (R-3/R-14 anti-pattern, AC-5/AC-8; GREEN)" test_no_setstretch

echo ""

# ==========================================
# P2 Tests (Best-Effort) — structural guards
# ==========================================
echo "=== P2: \\htu@makeabstract + cabstract/eabstract envs intact (structural invariant) ==="

# ATDD-3.4-12: \htu@makeabstract + cabstract/eabstract environments intact (AC-8, structural guard)
# Story 3.4 rewrites the \htu@makeabstract INTERNALS (title override + body scope + keyword rendering) and the
#   keyword macros, but must NOT rename/remove \htu@makeabstract or the cabstract/eabstract environments (main.tex
#   + ATDD reference them). GREEN pre- and post-impl — a structural invariant guard.
test_makeabstract_envs_intact() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'newcommand\{?\\?htu@makeabstract\}' htuthesis.cls && \
  grep -qE 'newenvironment\{cabstract\}' htuthesis.cls && \
  grep -qE 'newenvironment\{eabstract\}' htuthesis.cls
}
run_test "P2" "ATDD-3.4-12" "\\htu@makeabstract + cabstract/eabstract envs intact (AC-8 structural guard; GREEN)" test_makeabstract_envs_intact

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
  echo "   RED (fail pre-impl): 3.4-01 (ABSTRACT uppercase), 3.4-02 (title TNR-Bold override),"
  echo "      3.4-03 (五号 body scope), 3.4-04 (comma separator), 3.4-05 (KEY WORDS non-bold),"
  echo "      3.4-06 (\enskip dropped)."
  echo "   GREEN guards: 3.4-07 (cabstractname 摘 要), 3.4-08 (ckeywords ；), 3.4-09 (setmainfont TNR),"
  echo "      3.4-10 (setCJKsansfont SimHei), 3.4-11 (no setstretch), 3.4-12 (makeabstract + envs intact)."
  echo ""
  echo "   NOTE: source-greps prove the WIRING (uppercase title, TNR-Bold override, 五号 scope, comma sep,"
  echo "         non-bold label, \enskip dropped); the integration suite proves the RENDERED pages via fitz"
  echo "         (title font/size/centering, body 五号 + ~23.4bp line-gap [R-14], keyword separator,"
  echo "         Chinese title/body/keywords). AC-9 cross-story: 3.4 fixes the English-title LMSans gap 3.9"
  echo "         deferred → ATDD-3.9-16 (English abstract 0 LMRoman) stays GREEN (the LMSans title→TNR Bold,"
  echo "         so 'other'/LMSans count drops to 0; 3.9-16's RED condition = LMRoman, unaffected)."
  echo "         Tests are read-only — they do not modify the SUT."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
