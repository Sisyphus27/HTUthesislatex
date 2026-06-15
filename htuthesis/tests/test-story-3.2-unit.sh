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

# ATDD-3.2-01: \htu@abstractcover macro defined (AC-5, TC-E3-10/13)
# Truth source: .doc 博士学位论文摘要封面 (FR-12 HTU-unique abstract cover — currently ABSENT from cls).
# Pre-impl: \htu@abstractcover is not defined anywhere in the cls → RED.
# Post-impl (Task 2.1): \newcommand{\htu@abstractcover}{...} added → GREEN.
# Note: structure depends on Task-0.2 decision (default = .doc metadata cover). The MACRO must exist
# regardless of which structure Zy picks; this guard is decision-agnostic.
test_abstractcover_macro_defined() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'newcommand\{?\\?htu@abstractcover\}' htuthesis.cls
}
run_test "P0" "ATDD-3.2-01" "\\htu@abstractcover macro defined (AC-5; RED — absent pre-impl, FR-12 page missing)" test_abstractcover_macro_defined

# ATDD-3.2-02: \makecover calls \htu@abstractcover AFTER \htu@engcover (AC-1, TC-E3-10)
# Truth source: epic AC order doctoral-cover → english-title → abstract-cover → chinese-abstract.
# Pre-impl \makecover (cls:701-716): calls first@titlepage → engcover → authorization@mk (NO abstractcover) → RED.
# Post-impl (Task 3.1): abstractcover inserted after engcover → GREEN.
# Detection: \htu@abstractcover must appear, AND its line number must be > \htu@engcover's within \makecover.
test_makecover_calls_abstractcover() {
  [[ -f "htuthesis.cls" ]] || return 1
  # Both calls must exist as bare invocations (not inside newcommand defs).
  grep -q 'htu@abstractcover' htuthesis.cls || return 1
  grep -q 'htu@engcover' htuthesis.cls || return 1
  # Line numbers: abstractcover invocation must come after engcover invocation.
  local eng_line ac_line
  eng_line=$(grep -nE '^[[:space:]]*\\htu@engcover[[:space:]]*$|\\htu@engcover[[:space:]]*(\\cleardoublepage|%|$)' htuthesis.cls | head -1 | cut -d: -f1)
  ac_line=$(grep -nE '^[[:space:]]*\\htu@abstractcover[[:space:]]*$|\\htu@abstractcover[[:space:]]*(\\cleardoublepage|%|$)' htuthesis.cls | head -1 | cut -d: -f1)
  [[ -n "$eng_line" && -n "$ac_line" ]] || return 1
  echo "  (engcover call line=$eng_line, abstractcover call line=$ac_line; expect abstractcover AFTER engcover)"
  [[ "$ac_line" -gt "$eng_line" ]]
}
run_test "P0" "ATDD-3.2-02" "\\makecover calls \\htu@abstractcover after \\htu@engcover (AC-1, TC-E3-10; RED pre-impl)" test_makecover_calls_abstractcover

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

# ATDD-3.2-11: \htu@authorization@mk removed from \makecover front matter (AC-10, FR-14)
# Truth source: FR-14 — declaration is "positioned in the ending section (after appendices)" → NOT front matter.
#   Recommended default (Task-0.3 consult Zy): remove \htu@authorization@mk from \makecover now (3.3 re-adds in back matter).
# Detection (robust, no block extraction): count BARE CALLS of \htu@authorization@mk = total mentions minus
#   the \newcommand definition. Pre-impl: total=2 (def cls:675 + call cls:711), defs=1 → calls=1 → RED.
#   Post-impl (default): total=1 (def only), defs=1 → calls=0 → GREEN.
#   If Zy chooses to KEEP it in \makecover (Task-0.3 option b), this stays RED → repoint (Decision 2).
test_authorization_out_of_makecover() {
  [[ -f "htuthesis.cls" ]] || return 1
  local total defs calls
  total=$(grep -c 'htu@authorization@mk' htuthesis.cls 2>/dev/null || true)
  defs=$(grep -c 'newcommand{\\htu@authorization@mk}' htuthesis.cls 2>/dev/null || true)
  total=$(echo "$total" | tr -d '[:space:]' | head -1)
  defs=$(echo "$defs" | tr -d '[:space:]' | head -1)
  calls=$((total - defs))
  echo "  (authorization@mk total=$total defs=$defs bare-calls=$calls; expect 0 calls post-impl [removed from \\makecover])"
  [[ "$calls" -eq 0 ]]
}
run_test "P2" "ATDD-3.2-11" "\\htu@authorization@mk removed from \\makecover (AC-10/FR-14; RED pre-impl — Task-0.3 dependent, repoint if Zy keeps it)" test_authorization_out_of_makecover

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
  echo "      3.2-06 (old 'degree of Doctor' removed), 3.2-11 (authorization out of makecover)."
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
