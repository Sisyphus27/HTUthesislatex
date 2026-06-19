#!/usr/bin/env bash
# test-story-3.2-unit.sh — ATDD Red-Phase Unit Tests for Story 3.2 (abstract cover + English title page)
# TDD Phase: RED (source-level greps; abstract-cover-macro / makecover-order / degree-statement /
#            parbox-elimination / edegree-macro tests FAIL on pre-impl; regression guards pass)
#
# Usage: bash tests/test-story-3.2-unit.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 tests are blocking
# Linked ACs: AC-1 (makecover order), AC-2 (English title degree statement), AC-3 (\edegree macro),
#             AC-5 (\htu@abstractcover macro), AC-7 (no \paperwidth-7.2cm), AC-10 (declaration position)
# Linked Risk: R-6 (score 6, English-cover \parbox coupling), R-1/R-3 (regression guards)
#
# NOTE: these are SOURCE-LEVEL greps — they prove the cls/def CONTAIN the right definitions.
# The companion integration test (test-story-3.2-integration.sh) proves the RENDERED pages via
# fitz (page ordering, TNR fonts, no-page-number VISUAL SIGNATURE, element presence). Source-greps
# prove the macros/text are DEFINED; fitz proves they RENDER correctly (Story 2.5/2.6/3.1/3.9 lesson).
# Tests are READ-ONLY — they MUST NOT modify the SUT (Epic 1/2 retro lesson).

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
echo "ATDD Unit Tests: Story 3.2 — Abstract cover page and English title page"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: abstract-cover macro + makecover order + degree statement + R-6 parbox (RED pre-impl) ==="

# ATDD-3.2-01: \htu@abstractcover macro ABSENT (REPPOINTED by Story 3.14, Decision 2; AC-5 reframe, TC-E3-10/13)
# REPPOINTED 2026-06-19 (Story 3.14): was "\htu@abstractcover macro defined" (3.2 added it under FR-12 HTU-unique
#   abstract-cover assumption). Story 3.14 DELETED it — spec §1.1 line 5 前置部分枚举（封面、扉页、摘要、ABSTRACT、
#   目录…）has NO 摘要封面; reference PDF pp.1-12 has none (p3 English → p4 Chinese contiguous). FR-12 RETIRED.
#   This guard now asserts the NEW spec-correct reality (ABSENT) — NOT weakened; reversed to match spec-priority.
#   Mirrors Story 3.14 ATDD-3.14-01 (the authoritative abstractcover-absent guard).
test_abstractcover_macro_absent() {
  [[ -f "htuthesis.cls" ]] || return 1
  ! grep -vE '^\s*%' htuthesis.cls | grep -q 'htu@abstractcover'
}
run_test "P0" "ATDD-3.2-01" "\\htu@abstractcover macro ABSENT (REPPOINTED by Story 3.14: was defined; now deleted per spec §1.1 line 5, FR-12 retired)" test_abstractcover_macro_absent

# ATDD-3.2-02: \makecover does NOT call \htu@abstractcover (REPPOINTED by Story 3.14, Decision 2; AC-1 reframe, TC-E3-10)
# REPPOINTED 2026-06-19 (Story 3.14): was "\makecover calls \htu@abstractcover after \htu@engcover" (3.2 order
#   doctoral→english→abstractcover→chinese). Story 3.14 removed the abstractcover call + its dead \cleardoublepage
#   separator (spec §1.1 line 5). New order: doctoral→english→chinese (contiguous, matches reference PDF pp.1-12).
#   This guard now asserts engcover is the LAST cover in \makecover AND abstractcover is NOT called.
test_makecover_no_abstractcover() {
  [[ -f "htuthesis.cls" ]] || return 1
  # engcover still called; abstractcover NOT called (both def + call gone from non-comment lines).
  grep -vE '^\s*%' htuthesis.cls | grep -q 'htu@engcover' || return 1
  ! grep -vE '^\s*%' htuthesis.cls | grep -q 'htu@abstractcover'
}
run_test "P0" "ATDD-3.2-02" "\\makecover: engcover last cover, NO \\htu@abstractcover call (REPPOINTED by Story 3.14: spec §1.1 line 5; order doctoral→english→chinese)" test_makecover_no_abstractcover

# ATDD-3.2-03: English title degree-statement text present (AC-2, TC-E3-11/12)
# Truth source: .doc 扉页 + reference PDF page 3 — "the Graduate School of Henan Normal University",
#   "in Partial Fulfillment of the Requirements", "for the Degree of" (NOT the current "for the degree of Doctor").
# Pre-impl \htu@engcover (cls:635-637): "A dissertation submitted to \htu@schoolname@en for the degree of Doctor"
#   → NONE of the 3 target phrases present → RED.
# Post-impl (Task 1.3): the 5-line degree statement renders all 3 phrases → GREEN.
test_english_degree_statement() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q 'Graduate School of Henan Normal University' htuthesis.cls && \
  grep -q 'Partial Fulfillment' htuthesis.cls && \
  grep -q 'Requirements' htuthesis.cls
}
run_test "P0" "ATDD-3.2-03" "English title degree-statement text present (Graduate School/Partial Fulfillment/Requirements) (AC-2; RED pre-impl)" test_english_degree_statement

# ATDD-3.2-04: NO \paperwidth-7.2cm hardcoded \parbox in cls (AC-7, R-6 — inherited Story 2.1 debt)
# Truth source: deferred-work §2.1 [Epic 3 / Story 3.2] — the English-cover \parbox{...}{\paperwidth-7.2cm}
#   doesn't track the post-includeheadfoot text-area change (146→160mm). Story 3.2 eliminates it.
# Pre-impl (cls:632/640/646): 3 occurrences → RED. Post-impl (Task 1.5): TikZ overlay has no \parbox → 0 → GREEN.
test_no_paperwidth_parbox() {
  [[ -f "htuthesis.cls" ]] || return 1
  local n
  n=$(grep -cE 'paperwidth-7\.2cm|paperwidth - 7\.2cm|paperwidth-7\.2' htuthesis.cls 2>/dev/null || true)
  n=$(echo "$n" | tr -d '[:space:]' | head -1)
  echo "  (\\paperwidth-7.2cm matches: $n; expect 0 post-impl, 3 pre-impl)"
  [[ "$n" -eq 0 ]]
}
run_test "P0" "ATDD-3.2-04" "NO \\paperwidth-7.2cm hardcoded \\parbox in cls (AC-7, R-6; RED — 3 pre-impl)" test_no_paperwidth_parbox

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: \\edegree macro + old-text removal + regression guards ==="

# ATDD-3.2-05: \edegree macro defined via \htu@def@term (AC-3, TC-E3-12)
# Truth source: .doc 扉页 "for the Degree of [degree]" — the degree is content-dependent (reference shows
#   "Doctor of LAW" for 法学博士); requires a NEW user macro \edegree. Degree translations from the
#   degree-translation .doc (法学→Doctor of Law, 理学→Doctor of Science, etc.).
# Pre-impl: \edegree not defined (cls:550-555 block has etitle/eauthor/.../edate but no edegree) → RED.
# Post-impl (Task 4.1): \htu@def@term{edegree} added → GREEN.
test_edegree_macro_defined() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q 'def@term{edegree}' htuthesis.cls
}
run_test "P1" "ATDD-3.2-05" "\\edegree macro defined via \\htu@def@term (AC-3; RED — absent pre-impl)" test_edegree_macro_defined

# ATDD-3.2-06: old hardcoded "for the degree of Doctor" removed (AC-2/AC-3)
# Truth source: the current engcover hardcodes "for the degree of Doctor" (cls:637) — wrong (degree must be
#   the user's \edegree, and the statement must be the 5-line .doc form). Story 3.2 removes this literal.
# Pre-impl: "degree of Doctor" (lowercase d + Doctor) present → RED. Post-impl: replaced by "Degree of \htu@edegree" → 0 → GREEN.
# Case-sensitive: matches the OLD "degree of Doctor"; the NEW "Degree of" (capital D) does not match.
test_old_degree_text_removed() {
  [[ -f "htuthesis.cls" ]] || return 1
  local n
  n=$(grep -c 'degree of Doctor' htuthesis.cls 2>/dev/null || true)
  n=$(echo "$n" | tr -d '[:space:]' | head -1)
  echo "  ('degree of Doctor' matches: $n; expect 0 post-impl, 1 pre-impl)"
  [[ "$n" -eq 0 ]]
}
run_test "P1" "ATDD-3.2-06" "old hardcoded 'degree of Doctor' removed (AC-2/AC-3; RED — present pre-impl cls:637)" test_old_degree_text_removed

# ATDD-3.2-07: regression — \htu@fangsong@latin + \htu@heiti@latin preserved (Story 3.1, AC-9)
# The abstract cover (Task 2.2) reuses Story 3.1's ASCII-in-CJK-font switches. Must remain defined.
test_latin_switches_preserved() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q 'newfontfamily\\htu@fangsong@latin{FangSong}' htuthesis.cls && \
  grep -q 'newfontfamily\\htu@heiti@latin{SimHei}' htuthesis.cls
}
run_test "P1" "ATDD-3.2-07" "regression: \\htu@fangsong@latin/\\htu@heiti@latin preserved (Story 3.1, AC-9)" test_latin_switches_preserved

# ATDD-3.2-08: regression — \htu@first@titlepage intact (Story 3.1 doctoral cover untouched, AC-9)
# Story 3.2 must NOT rewrite the doctoral cover (3.1 scope). The macro must still be defined.
test_first_titlepage_intact() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'newcommand\{?\\?htu@first@titlepage\}' htuthesis.cls
}
run_test "P1" "ATDD-3.2-08" "regression: \\htu@first@titlepage intact (Story 3.1 doctoral cover untouched, AC-9)" test_first_titlepage_intact

# ATDD-3.2-09: regression — NO \setstretch in cls (R-3 anti-pattern, AC-9)
test_no_setstretch() {
  [[ -f "htuthesis.cls" ]] || return 1
  local n
  n=$(grep -c 'setstretch' htuthesis.cls 2>/dev/null || true)
  n=$(echo "$n" | tr -d '[:space:]' | head -1)
  echo "  (setstretch matches: $n; expect 0)"
  [[ "$n" -eq 0 ]]
}
run_test "P1" "ATDD-3.2-09" "regression: NO \\setstretch in cls (R-3 anti-pattern, AC-9)" test_no_setstretch

# ATDD-3.2-10: regression — \setmainfont{Times New Roman} preserved (Story 3.9, AC-2/AC-9)
# The English title page relies on \rmfamily=TNR (3.9). Story 3.2 must NOT remove/override it.
test_setmainfont_tnr_preserved() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'setmainfont\{Times New Roman\}' htuthesis.cls
}
run_test "P1" "ATDD-3.2-10" "regression: \\setmainfont{Times New Roman} preserved (Story 3.9, AC-2)" test_setmainfont_tnr_preserved

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: declaration position (AC-10, Task-0.3 dependent) ==="

# ATDD-3.2-11: \htu@authorization@mk NOT called within \makecover front matter (AC-10, FR-14)
# Truth source: FR-14 — declaration is "positioned in the ending section (after appendices)" → NOT front matter.
# REPPOINTED 2026-06-15 (Story 3.3, Decision 2): the original assertion (global bare-call count = 0) is obsoleted —
#   Story 3.3 re-added the declaration in BACK MATTER via \makedeclaration → \htu@authorization@mk, so the macro
#   is now legitimately called (bare-calls=1), but NOT inside \makecover. The INTENT (declaration not in front
#   matter) remains valid and is satisfied by 3.3. Detection: extract the \makecover block and assert it does NOT
#   call authorization@mk.
# FIXED 2026-06-15 (code-review CRITICAL): the first repoint used `awk '/newcommand\{\\makecover\}/...'` but gawk
#   warns "\m is not a known regexp operator" and drops the backslash → the regex never matched → body empty →
#   the guard passed VACUOUSLY (could not detect a regression). Now uses `grep -nF` (fixed-string, no regex) to
#   find the \makecover def line, then awk from that line to the next col-0 '}' (makecover's close is at col-0;
#   verified). Empirically verified: catches an injected \htu@authorization@mk inside \makecover.
test_authorization_out_of_makecover() {
  [[ -f "htuthesis.cls" ]] || return 1
  local start body end
  start=$(grep -nF 'newcommand{\makecover}' htuthesis.cls | head -1 | cut -d: -f1)
  [[ -n "$start" ]] || { echo "  (\\makecover def not found)"; return 1; }
  body=$(awk -v s="$start" 'NR>=s{print} NR>=s && /^}/{exit}' htuthesis.cls)
  end=$((start + $(printf '%s\n' "$body" | wc -l) - 1))
  if printf '%s\n' "$body" | grep -q 'htu@authorization@mk'; then
    echo "  (authorization@mk found INSIDE \\makecover block (cls lines $start-$end) — declaration wrongly in front matter)"
    return 1
  fi
  echo "  (authorization@mk NOT in \\makecover block (cls lines $start-$end) — declaration correctly in back matter via \\makedeclaration)"
  return 0
}
run_test "P2" "ATDD-3.2-11" "\\htu@authorization@mk NOT called within \\makecover (AC-10/FR-14; REPPOINTED 3.3/Decision 2 — back-matter call legit; awk-regex fixed code-review)" test_authorization_out_of_makecover

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
  echo "   RED (fail pre-impl): 3.2-01 (abstractcover macro), 3.2-02 (makecover order),"
  echo "      3.2-03 (degree statement), 3.2-04 (no paperwidth-7.2cm parbox), 3.2-05 (edegree macro),"
  echo "      3.2-06 (old 'degree of Doctor' removed). (3.2-11 REPPOINTED by 3.3/Decision 2 — makecover-block-scoped guard.)"
  echo "   GREEN guards: 3.2-07 (latin switches), 3.2-08 (first@titlepage intact), 3.2-09 (no setstretch),"
  echo "      3.2-10 (setmainfont TNR)."
  echo ""
  echo "   NOTE: source-greps prove macros/text/structure are DEFINED; the integration test's fitz checks"
  echo "         (I04 page ordering, I05 all-TNR, I06 no-page-number VISUAL SIGNATURE, I07-I09 elements)"
  echo "         prove the pages RENDER correctly — the real AC proof. Tests are read-only (no SUT mutation)."
  echo "         AC-10/3.2-11 follows the Task-0.3 recommended default; repoint if Zy keeps declaration in makecover."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
