#!/usr/bin/env bash
# test-story-3.3-unit.sh — ATDD Red-Phase Unit Tests for Story 3.3 (originality declaration)
# TDD Phase: RED (source-level greps; R-15 verbatim titles/bodies + signature macros + TOC name +
#            makedeclaration-command tests FAIL on pre-impl; old-ZZU-text-removed + regression guards pass)
#
# Usage: bash tests/test-story-3.3-unit.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 tests are blocking
# Linked ACs: AC-1 (verbatim text — R-15), AC-2 (titles 独创性声明 / 关于论文使用授权的说明),
#             AC-3 (作者签名 / 导师签名 signature macros), AC-4 (\makedeclaration command), AC-6 (TOC name)
# Linked Risk: R-15 (score 6, declaration verbatim fidelity — the dominant Epic-3 DATA risk)
#
# NOTE: these are SOURCE-LEVEL greps — they prove the cls CONTAINS the right verbatim definitions and
#       the old ZZU/generic text is GONE. The companion integration test (test-story-3.3-integration.sh)
#       proves the RENDERED declaration page via fitz (verbatim phrases on the page, signatures rendered,
#       page number continuous, TOC entry, header). Source-greps prove the macros/text are DEFINED; fitz
#       proves they RENDER correctly (Story 2.5/2.6/3.1/3.2/3.9 lesson). Tests are READ-ONLY — they MUST
#       NOT modify the SUT (Epic 1/2 retro lesson).
#
# ⚠️ Comment-inflation (Stories 1.4 / 3.9 / 3.2 lesson): if a [基础] comment literally quotes a target
#    string, the grep false-passes/false-fails. The dev must keep [基础] comments paraphrased (no literal
#    fixture text). The RED-phase run (bash ... --run on the pre-impl baseline) confirms each scaffold
#    actually fails pre-impl — the TDD RED guarantee.

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
echo "ATDD Unit Tests: Story 3.3 — Originality declaration"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%) — R-15 verbatim text
# ==========================================
echo "=== P0: R-15 verbatim declaration titles + bodies (RED pre-impl — cls carries ZZU/generic text) ==="

# ATDD-3.3-01: \htu@declarename = 独创性声明 (AC-2, R-15, TC-E3-14)
# Truth source: .doc 独创性声明和关于论文使用授权的说明.doc + spec §1.5.3/§1.1.4 = "独创性声明".
#   Current cls:738 = "学位论文原创性声明" (ZZU text). "独创性声明" is NOT a substring of "学位论文原创性声明"
#   (原创性 vs 独创性), so this grep = 0 pre-impl → RED. Post-impl (Task 1.1) → 1 → GREEN.
test_declarename_duchuang() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '独创性声明' htuthesis.cls
}
run_test "P0" "ATDD-3.3-01" "\\htu@declarename verbatim 独创性声明 present (AC-2, R-15; RED — cls:738 has 学位论文原创性声明)" test_declarename_duchuang

# ATDD-3.3-02: \htu@authtitle = 关于论文使用授权的说明 (AC-2, R-15, TC-E3-14)
# Truth source: .doc + spec §1.5.3 = "关于论文使用授权的说明". Current cls:739 = "学位论文使用授权声明".
#   Not a substring → grep = 0 pre-impl → RED. Post-impl (Task 1.2) → GREEN.
test_authtitle_guanyu() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '关于论文使用授权的说明' htuthesis.cls
}
run_test "P0" "ATDD-3.3-02" "\\htu@authtitle verbatim 关于论文使用授权的说明 present (AC-2, R-15; RED — cls:739 has 学位论文使用授权声明)" test_authtitle_guanyu

# ATDD-3.3-03: verbatim 独创性声明 body phrase present (AC-1, R-15, TC-E3-14)
# Truth source: .doc body 1 = "本人郑重声明：所呈交的学位论文是我个人在导师指导下进行的研究工作及取得的研究成果…".
#   Current cls:742 ZZU body = "本人郑重声明：所呈交的学位论文，是本人在导师的指导下，独立进行研究…".
#   The distinctive .doc phrase "是我个人在导师指导下进行的研究工作" is absent pre-impl → RED.
#   Post-impl (Task 1.3) → GREEN.
test_declarebody_verb1() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '是我个人在导师指导下进行的研究工作' htuthesis.cls
}
run_test "P0" "ATDD-3.3-03" "verbatim 独创性声明 body phrase 是我个人在导师指导下进行的研究工作 (AC-1, R-15; RED pre-impl)" test_declarebody_verb1

# ATDD-3.3-04: verbatim 关于论文使用授权的说明 body phrase present (AC-1, R-15, TC-E3-14)
# Truth source: .doc body 2 = "本人完全了解河南师范大学有关保留、使用学位论文的规定…".
#   Current cls:748 ZZU body = "本人在导师指导下完成的论文及相关的职务作品，知识产权归属…".
#   The distinctive .doc phrase "本人完全了解河南师范大学有关保留" is absent pre-impl → RED.
#   Post-impl (Task 1.4) → GREEN.
test_authbody_verb2() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '本人完全了解河南师范大学有关保留' htuthesis.cls
}
run_test "P0" "ATDD-3.3-04" "verbatim 授权说明 body phrase 本人完全了解河南师范大学有关保留 (AC-1, R-15; RED pre-impl)" test_authbody_verb2

echo ""

# ==========================================
# P1 Tests (>=95%) — signature macros + TOC name + makedeclaration + old-text removal
# ==========================================
echo "=== P1: signature macros + TOC name + \\makedeclaration + old-text removed + regression guards ==="

# ATDD-3.3-05: \htu@supervisorsigtitle macro defined = 导师签名 (AC-3, TC-E3-16)
# Truth source: .doc declaration 2 signature line = "作者签名：___ 导师签名：___ 日期：". The supervisor
#   signature (导师签名) is REQUIRED by FR-14/spec §1.5.3 ("研究生本人和导师的手写签名"). Current cls has
#   only \htu@authorsig ("学位论文作者：") — NO supervisor signature macro → RED. Post-impl (Task 1.5) → GREEN.
test_supervisorsigtitle_defined() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'newcommand\{?\\?htu@supervisorsigtitle\}' htuthesis.cls
}
run_test "P1" "ATDD-3.3-05" "\\htu@supervisorsigtitle macro defined (导师签名; AC-3/FR-14; RED — absent pre-impl)" test_supervisorsigtitle_defined

# ATDD-3.3-06: \htu@declaretocname macro defined = 独创性声明和关于论文使用授权的说明 (AC-6, spec §1.1.4)
# Truth source: spec §1.1.4 — the TOC contains "独创性声明和关于论文使用授权的说明" (the combined name as ONE entry).
#   Implemented via \htu@chapter*[\htu@declaretocname]{...}. Currently absent → RED. Post-impl (Task 2.1) → GREEN.
test_declaretocname_defined() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'newcommand\{?\\?htu@declaretocname\}' htuthesis.cls
}
run_test "P1" "ATDD-3.3-06" "\\htu@declaretocname macro defined (combined TOC name; AC-6/§1.1.4; RED — absent pre-impl)" test_declaretocname_defined

# ATDD-3.3-07: \makedeclaration user command defined (AC-4)
# Truth source: the declaration invocation point mirrors \makecover (Layer-1 main.tex). Currently absent
#   (3.2 removed the front-matter call; no back-matter command exists yet) → RED. Post-impl (Task 3.1) → GREEN.
test_makedeclaration_defined() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'newcommand\{?\\?makedeclaration\}' htuthesis.cls
}
run_test "P1" "ATDD-3.3-07" "\\makedeclaration user command defined (AC-4; RED — absent pre-impl, declaration unrendered)" test_makedeclaration_defined

# ATDD-3.3-08: OLD ZZU 独创性声明 body phrase removed (R-15 anti-fixture, AC-1)
# Truth source: the current cls:742 body carries the ZZU phrase "独立进行研究所取得的成果" — NOT in the .doc.
#   Story 3.3 replaces the body verbatim (Task 1.3). Pre-impl: 1 match → RED. Post-impl: 0 → GREEN.
#   Distinctive body text (unlikely to be quoted verbatim in a paraphrased [基础] comment).
test_old_declarebody_removed() {
  [[ -f "htuthesis.cls" ]] || return 1
  local n
  n=$(grep -c '独立进行研究所取得的成果' htuthesis.cls 2>/dev/null || true)
  n=$(echo "$n" | tr -d '[:space:]' | head -1)
  echo "  ('独立进行研究所取得的成果' matches: $n; expect 0 post-impl, 1 pre-impl cls:742)"
  [[ "$n" -eq 0 ]]
}
run_test "P1" "ATDD-3.3-08" "old ZZU body phrase 独立进行研究所取得的成果 removed (R-15 anti-fixture; RED — 1 pre-impl)" test_old_declarebody_removed

# ATDD-3.3-09: OLD ZZU signature label 学位论文作者 removed (R-15 anti-fixture, AC-3)
# Truth source: current cls:740 \htu@authorsig = "学位论文作者：" — the .doc uses "作者签名：". Story 3.3
#   replaces the label (Task 1.5). Pre-impl: present → RED. Post-impl: 0 → GREEN.
test_old_siglabel_removed() {
  [[ -f "htuthesis.cls" ]] || return 1
  local n
  n=$(grep -c '学位论文作者' htuthesis.cls 2>/dev/null || true)
  n=$(echo "$n" | tr -d '[:space:]' | head -1)
  echo "  ('学位论文作者' matches: $n; expect 0 post-impl, 1 pre-impl cls:740)"
  [[ "$n" -eq 0 ]]
}
run_test "P1" "ATDD-3.3-09" "old ZZU signature label 学位论文作者 removed (R-15 anti-fixture; RED — 1 pre-impl cls:740)" test_old_siglabel_removed

# ATDD-3.3-10: regression — \htu@first@titlepage intact (Story 3.1 doctoral cover untouched, AC-8)
# Story 3.3 must NOT rewrite the doctoral cover (3.1 scope). The macro must still be defined.
test_first_titlepage_intact() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'newcommand\{?\\?htu@first@titlepage\}' htuthesis.cls
}
run_test "P1" "ATDD-3.3-10" "regression: \\htu@first@titlepage intact (Story 3.1 doctoral cover untouched, AC-8)" test_first_titlepage_intact

# ATDD-3.3-11: regression — \htu@abstractcover preserved (Story 3.2, AC-8)
# Story 3.3 must NOT touch the abstract cover (3.2 scope). The macro must still be defined.
test_abstractcover_intact() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'newcommand\{?\\?htu@abstractcover\}' htuthesis.cls
}
run_test "P1" "ATDD-3.3-11" "regression: \\htu@abstractcover intact (Story 3.2 abstract cover untouched, AC-8)" test_abstractcover_intact

# ATDD-3.3-12: regression — \setmainfont{Times New Roman} preserved (Story 3.9, AC-8)
# The declaration is pure CJK (no Latin-font impact), but 3.9's font stack must remain intact.
test_setmainfont_tnr_preserved() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'setmainfont\{Times New Roman\}' htuthesis.cls
}
run_test "P1" "ATDD-3.3-12" "regression: \\setmainfont{Times New Roman} preserved (Story 3.9, AC-8)" test_setmainfont_tnr_preserved

# ATDD-3.3-13: regression — NO \setstretch in cls (R-3 anti-pattern, AC-8)
test_no_setstretch() {
  [[ -f "htuthesis.cls" ]] || return 1
  local n
  n=$(grep -c 'setstretch' htuthesis.cls 2>/dev/null || true)
  n=$(echo "$n" | tr -d '[:space:]' | head -1)
  echo "  (setstretch matches: $n; expect 0)"
  [[ "$n" -eq 0 ]]
}
run_test "P1" "ATDD-3.3-13" "regression: NO \\setstretch in cls (R-3 anti-pattern, AC-8)" test_no_setstretch

echo ""

# ==========================================
# P2 Tests (Best-Effort) — cross-story structural guard
# ==========================================
echo "=== P2: \\htu@authorization@mk remains defined (Task-8.2 guard; Story 3.2 deferred [Epic 4 — test-hardening]) ==="

# ATDD-3.3-14: \htu@authorization@mk remains \newcommand-defined (AC-9, Decision 2, deferred-work §3-2-review)
# Truth source: Story 3.2 review flagged that ATDD-3.2-11 checked absence-from-\makecover but NOT that the
#   macro stays defined — if a refactor deletes the "unused-looking" macro, 3.3 silently breaks. This guard
#   (folded into 3.3 per deferred-work) asserts the macro REMAINS defined. GREEN pre- and post-impl.
#   NOTE: this is a GUARD, not a RED scaffold — it protects the structural invariant the declaration relies on.
test_authorization_mk_still_defined() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'newcommand\{\\htu@authorization@mk\}' htuthesis.cls
}
run_test "P2" "ATDD-3.3-14" "\\htu@authorization@mk remains \\newcommand-defined (Task-8.2 guard, Decision 2; GREEN — structural invariant)" test_authorization_mk_still_defined

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
  echo "   RED (fail pre-impl): 3.3-01 (独创性声明), 3.3-02 (关于论文使用授权的说明),"
  echo "      3.3-03 (body1 是我个人), 3.3-04 (body2 本人完全了解), 3.3-05 (导师签名 macro),"
  echo "      3.3-06 (declaretocname), 3.3-07 (makedeclaration), 3.3-08 (old 独立进行 removed),"
  echo "      3.3-09 (old 学位论文作者 removed)."
  echo "   GREEN guards: 3.3-10 (first@titlepage), 3.3-11 (abstractcover), 3.3-12 (setmainfont TNR),"
  echo "      3.3-13 (no setstretch), 3.3-14 (authorization@mk still defined)."
  echo ""
  echo "   NOTE: source-greps prove the verbatim text/macros are DEFINED and old ZZU text is GONE;"
  echo "         the integration test's fitz checks (I04 verbatim on page, I05 signatures, I06 position,"
  echo "         I07 page-number continuous, I08 TOC entry, I09 header) prove the RENDERED declaration."
  echo "         AC-9 cross-story: ATDD-3.2-11 (declaration not in \\makecover) flips RED when 3.3 re-adds"
  echo "         the back-matter call — dev-story repoints it (Task 8.1, Decision 2). Tests are read-only."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
