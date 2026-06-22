#!/usr/bin/env bash
# test-story-3.14-unit.sh — ATDD Unit Tests for Story 3.14 (structural cleanup — abstract cover + blank pages)
# TDD Phase: RED — RED drivers assert the 2 structural corrections' WIRING (FAIL pre-impl, PASS post-impl).
#             Pre-impl state (baseline commit b348f30, post-Story 3.13 review = the over-shoot): \htu@abstractcover
#             macro DEFINED (cls:752) + INVOKED in \makecover (cls:853) + a dead \cleardoublepage separator (cls:852);
#             9 \cleardoublepage COMMAND-CALL sites (cls:135 frontmatter, 141 mainmatter, 147 backmatter, 519 chapter*,
#             850 makecover, 852 makecover, 895 makeabstract, 927 denotation, 946 ack) + 1 \def\cleardoublepage mechanism
#             (cls:290, ThuThesis port). Post-impl (spec §1.1 line 5 + §2.4 line 187-189, PRIORITY): abstractcover
#             DELETED; \cleardoublepage→\clearpage everywhere EXCEPT the 2 recto-keepers (cls:141 mainmatter = 绪论/Arabic
#             start, cls:895 makeabstract = Chinese-abstract/Roman start); the cls:290 \def mechanism RETAINED.
#             The 3 RED drivers FAIL pre-impl; 4 GREEN guards (2 keepers / \def mechanism / doctoral+engcover intact)
#             PASS pre+post.
#
# Usage: bash tests/test-story-3.14-unit.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 (AC-1 abstractcover absent + AC-2 cleardoublepage-count linchpin + AC-2 frontmatter converted) +
#           P1 (AC-2 keepers retained GREEN + \def mechanism + AC-1 boundary)
# Linked ACs: AC-1 (delete \htu@abstractcover), AC-2 (\cleardoublepage→\clearpage except 2 keepers),
#             AC-3/AC-4/AC-5 (verify-only / regression — covered in integration)
# Linked Risk: R-20 (score 4 — structural continuity), R-keeper-mechanism (3 — 2 keepers held),
#              R-cross-story (3 — Decision-2 repoints of 3.2/3.3/3.10/1.5)
# TC coverage: TC-E3-57 (cleardoublepage→clearpage except 2 keepers source grep — 02/03 + 04/05/06);
#              TC-E3-55 (abstract-cover absent — 01; rendered proof = integration I04)
#
# NOTE: source-greps prove the WIRING (abstractcover macro+call gone; cleardoublepage call-count == 2 keepers).
#   The fitz behavior tests (test-story-3.14-integration.sh) prove the RENDERED abstract-cover page ABSENT (I04) +
#   blank pages ≤2 (I05) + blank-page no-header/number visual signature (I06, Decision 1). A source-grep alone does
#   NOT prove the surviving blanks stay header-less (Decision 1) — I06 (get_drawings + footer-band spans) is the proof.
#   The GREEN guards 04/05/06 lock-in the by-construction-correct mechanisms (2 keepers / \def mechanism / boundary).
#
# Truth source: 河南师范大学研究生学位论文格式要求.md §1.1 line 5 (前置部分 enumeration — 封面、扉页、摘要、ABSTRACT、
#   目录 — NO 摘要封面) + §2.4 line 187 (扉页独立页；摘要/ABSTRACT/目录/章首页另起一页) + §2.4 line 189 (所有起始页码页
#   共 2 个起始页必须为右页). spec is PRIORITY (CLAUDE.md Decision 4, corrected 2026-06-17). Reference PDF (参考博士论文-
#   参考博士论文-政治与公共管理学院.pdf pp.1-12, direct fitz read 2026-06-19) AGREES — no abstract-cover page (p3 English title
#   → p4 Chinese abstract contiguous), 0 blanks in front matter. See sprint-change-proposal-2026-06-17.md gap rows.

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
echo "ATDD Unit Tests: Story 3.14 — structural cleanup (abstract cover + blank pages; §1.1 + §2.4)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests — AC-1 abstractcover absent + AC-2 cleardoublepage-count linchpin + AC-2 frontmatter converted
# ==========================================
echo "=== P0: AC-1 abstractcover absent + AC-2 cleardoublepage count==2 (linchpin) + frontmatter converted (RED drivers) ==="

# ATDD-3.14-01: \htu@abstractcover ABSENT from cls (non-comment) (AC-1 §1.1 line 5, FR-12 removed) — RED driver
# Pre-impl: def (cls:752 \newcommand{\htu@abstractcover}) + call (cls:853) both present → FAIL.
# Post-impl: macro deleted + call removed → the string is absent from all non-comment lines → PASS.
# (Comment-exclusion per ATDD-2.6-10 discipline; the cls:638 forward-ref comment is resolved/removed by the dev —
#  if a traceability comment remains it is non-functional and excluded by grep -v.)
test_abstractcover_absent() {
  [[ -f "htuthesis.cls" ]] || return 1
  ! grep -vE '^\s*%' htuthesis.cls | grep -q 'htu@abstractcover'
}
run_test "P0" "ATDD-3.14-01" "\\htu@abstractcover ABSENT from cls (macro + call deleted) (AC-1 §1.1 line 5, FR-12 removed; RED — pre-impl defined+called)" test_abstractcover_absent

# ATDD-3.14-02: \cleardoublepage COMMAND-CALL count == 2 keepers (AC-2 §2.4 line 189 linchpin) — RED driver
# Counts non-comment lines containing 'cleardoublepage', MINUS the \def\cleardoublepage mechanism line (cls:290).
# Pre-impl: 9 command-call sites (135/141/147/519/850/852/895/927/946) + 1 \def line → calls=9 → FAIL.
# Post-impl: 2 keepers (141 mainmatter + 895 makeabstract) + 1 \def line → calls=2 → PASS.
# (cls:852 removed by AC-1; cls:135/147/519/850/927/946 converted to \clearpage — drop out of the count.)
test_cleardoublepage_count_2() {
  [[ -f "htuthesis.cls" ]] || return 1
  local total defs calls
  total=$(grep -vE '^\s*%' htuthesis.cls | grep -c 'cleardoublepage')
  defs=$(grep -vE '^\s*%' htuthesis.cls | grep -c '\\def\\cleardoublepage')
  calls=$((total - defs))
  echo "  (cleardoublepage: total_lines=$total, \\def mechanism=$defs, command-calls=$calls [expect 2 post-impl])"
  [[ "$calls" -eq 2 ]]
}
run_test "P0" "ATDD-3.14-02" "\\cleardoublepage command-call count == 2 keepers (mainmatter + makeabstract) (AC-2 §2.4 line 189 linchpin; RED — pre-impl 9 calls)" test_cleardoublepage_count_2

# ATDD-3.14-03: \frontmatter converted to \clearpage (NOT \cleardoublepage) (AC-2) — RED driver
# Pre-impl: \renewcommand\frontmatter{ \cleardoublepage ...} (cls:135) → the block contains cleardoublepage → FAIL.
# Post-impl: \clearpage → block has NO cleardoublepage → PASS. (clearpage is NOT a substring of cleardoublepage in this
#   direction — the converted line '  \clearpage' does not contain 'cleardoublepage'.)
test_frontmatter_converted() {
  [[ -f "htuthesis.cls" ]] || return 1
  local fm
  fm=$(grep -vE '^\s*%' htuthesis.cls | grep -A3 '\\renewcommand\\frontmatter')
  if echo "$fm" | grep -q 'cleardoublepage'; then
    echo "  (frontmatter block still has \\cleardoublepage — not yet converted to \\clearpage)"
    return 1
  fi
  return 0
}
run_test "P0" "ATDD-3.14-03" "\\frontmatter converted to \\clearpage (NOT \\cleardoublepage) (AC-2; RED — pre-impl cls:135 cleardoublepage)" test_frontmatter_converted

echo ""

# ==========================================
# P1 Tests — GREEN guards (AC-2 keepers retained / \def mechanism / AC-1 boundary)
# ==========================================
echo "=== P1: GREEN guards (AC-2 mainmatter+makeabstract keepers / \\def mechanism / AC-1 doctoral+engcover intact) ==="

# ATDD-3.14-04: \mainmatter RETAINS \cleardoublepage (AC-2 keeper — 绪论/Arabic start, §2.4 line 189) — GREEN guard
# The 绪论/Arabic recto-keeper (cls:141) MUST stay \cleardoublepage (forces chap01 first page onto a right page).
# GREEN pre+post (keeper never changed). RED = the keeper was accidentally converted → 绪论 lands verso → §2.4 violation.
test_mainmatter_keeper_retained() {
  [[ -f "htuthesis.cls" ]] || return 1
  local mm
  mm=$(grep -vE '^\s*%' htuthesis.cls | grep -A3 '\\renewcommand\\mainmatter')
  echo "$mm" | grep -q 'cleardoublepage'
}
run_test "P1" "ATDD-3.14-04" "\\mainmatter RETAINS \\cleardoublepage (绪论/Arabic keeper §2.4 line 189; GREEN — guardrail; RED = verso 绪论)" test_mainmatter_keeper_retained

# ATDD-3.14-05: \htu@makeabstract RETAINS \cleardoublepage (AC-2 keeper — Chinese-abstract/Roman start) — GREEN guard
# The Chinese-abstract/Roman recto-keeper (cls:895) MUST stay \cleardoublepage (the opening of \htu@makeabstract).
# GREEN pre+post. This is the linchpin: once \htu@chapter* (cls:519) converts to \clearpage, the Chinese-abstract recto
#   is preserved ONLY by this cls:895 keeper — if it is removed, the Roman start lands verso (R-keeper-mechanism).
test_makeabstract_keeper_retained() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -vE '^\s*%' htuthesis.cls | grep -A2 'newcommand.*htu@makeabstract' | grep -q 'cleardoublepage'
}
run_test "P1" "ATDD-3.14-05" "\\htu@makeabstract RETAINS \\cleardoublepage (Chinese-abstract/Roman keeper §2.4 line 189; GREEN — linchpin; RED = verso 摘要)" test_makeabstract_keeper_retained

# ATDD-3.14-06: \def\cleardoublepage ThuThesis mechanism RETAINED (AC-2 guardrail, FR-2 + silent-failure-#6) — GREEN guard
# The ThuThesis-ported \def\cleardoublepage{ \clearpage ... \thispagestyle{empty} ... } (cls:290-300) is the empty-blank-
#   page-style mechanism (FR-2; architecture.md silent-failure-#6). AC-2 converts CALL SITES to \clearpage; this \def
#   stays so the 2 keepers' blanks render header-less. GREEN pre+post. RED = mechanism deleted → blank-page header leak.
test_cleardoublepage_def_mechanism() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -vE '^\s*%' htuthesis.cls | grep -q '\\def\\cleardoublepage'
}
run_test "P1" "ATDD-3.14-06" "\\def\\cleardoublepage ThuThesis empty-blank mechanism RETAINED (FR-2 + silent-failure-#6; GREEN — guardrail)" test_cleardoublepage_def_mechanism

# ATDD-3.14-07: doctoral cover + English title page macros INTACT (AC-1 boundary) — GREEN guard
# AC-1 deletes ONLY \htu@abstractcover (between the doctoral cover and English title). The doctoral cover
#   (\htu@first@titlepage) and English title (\htu@engcover) MUST remain defined + invoked. GREEN pre+post.
#   RED = AC-1 over-reached (deleted the wrong cover).
test_doctoral_and_engcover_intact() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -vE '^\s*%' htuthesis.cls | grep -q 'newcommand.*htu@engcover' && \
  grep -vE '^\s*%' htuthesis.cls | grep -q 'htu@first@titlepage'
}
run_test "P1" "ATDD-3.14-07" "doctoral cover \\htu@first@titlepage + English title \\htu@engcover INTACT (AC-1 boundary; GREEN — only abstractcover deleted)" test_doctoral_and_engcover_intact

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
  echo "   RED drivers (FAIL pre-impl over-shoot, PASS post-impl spec §1.1/§2.4):"
  echo "      3.14-01 \\htu@abstractcover ABSENT from cls (AC-1 §1.1 line 5, FR-12 removed)"
  echo "      3.14-02 \\cleardoublepage command-call count == 2 keepers (AC-2 §2.4 line 189 linchpin)"
  echo "      3.14-03 \\frontmatter converted to \\clearpage (AC-2)"
  echo "   GREEN guards (PASS pre+post — keeper / mechanism / boundary lock-in):"
  echo "      3.14-04 \\mainmatter retains \\cleardoublepage (绪论/Arabic keeper §2.4 line 189)"
  echo "      3.14-05 \\htu@makeabstract retains \\cleardoublepage (Chinese-abstract/Roman keeper — linchpin)"
  echo "      3.14-06 \\def\\cleardoublepage ThuThesis empty-blank mechanism retained (FR-2 + silent-failure-#6)"
  echo "      3.14-07 doctoral cover + English title intact (AC-1 boundary — only abstractcover deleted)"
  echo ""
  echo "   Pre-impl baseline (commit b348f30, post-Story 3.13 review = over-shoot): \\htu@abstractcover DEFINED"
  echo "      (cls:752) + INVOKED (cls:853); 9 \\cleardoublepage command-call sites. The 3 RED drivers FAIL pre-impl."
  echo "      Post-impl (spec §1.1 line 5 + §2.4 line 187-189 PRIORITY) → GREEN."
  echo "   NOTE: these source-greps prove the WIRING. The fitz behavior tests (test-story-3.14-integration.sh) prove the"
  echo "      RENDERED abstract-cover page ABSENT (I04) + blank pages ≤2 (I05) + blank-page no-header/number visual"
  echo "      signature (I06, Decision 1). spec §1.1 line 5 (无摘要封面) + §2.4 line 189 (共 2 个起始页必须为右页)."
  echo "      R-20 = 4 (structural continuity); R-keeper-mechanism = 3 (2 keepers held). Reference PDF AGREES"
  echo "      (pp.1-12 direct fitz read 2026-06-19: p3 English → p4 Chinese contiguous, 0 blanks). Tests are read-only."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
