#!/usr/bin/env bash
# test-story-3.7-unit.sh — ATDD Unit Tests for Story 3.7 (Structured back matter — references, appendix)
# TDD Phase: GREEN-GUARD (NO RED drivers — the references + appendix machinery is INHERITED intact from the
#            original zzuthesis and the references ALREADY RENDER correctly on the baseline (main.pdf p44: title
#            "参考文献" SimHei 三号 centered, entries [N] TNR + SimSun 五号 hanging indent). The appendix does NOT
#            render in main.pdf (main.tex has no \appendix) → appendix ACs are SOURCE-LEVEL guards; rendered
#            appendix verification is DEFERRED to Epic 4 Story 4.1 (sample-content scope, per deferred-work.md).
#            These source-level greps prove the WIRING is present and the invariants intact; they LOCK IN the
#            correct inherited behavior so future stories (3.8/Epic 4) cannot silently regress it. The companion
#            integration suite proves the RENDERED references via fitz.
#
# Usage: bash tests/test-story-3.7-unit.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P1/P2 (architecture.md:41 = 后置内容 MEDIUM; references LOW via :687 gbt7714 compatibility;
#           appendix rendered-verification structurally impossible without sample floats → 4.1. No P0 —
#           compilation passes pre-impl, references already render.)
# Linked ACs: AC-1 (references title \htu@chapter*{\bibname}), AC-2 (thebibliography \wuhao + [N] \list),
#             AC-4/AC-6 (appendix env + \@chapapp + counter wiring — source-level; rendered deferred to 4.1),
#             AC-7/AC-8 (regression — TNR font stack, size macros, bibstyle + bibliography in main.tex intact)
# Linked Risk: R-12 (score 4 — bibliography/counter change requires `latexmk -g` bibtex cycle; the integration
#              suite runs -g; only relevant IF AC-2 edits the \list dims)
# TC coverage: TC-E3-33/34 (behavior proofs in integration); TC-E3-35/36 (source-level — appendix doesn't render)
#
# NOTE: these are SOURCE-LEVEL greps — they prove the cls CONTAINS the references/appendix wiring
#       (\htu@chapter*{\bibname} title, \wuhao[1.524] body, \@biblabel [N] list, \renewenvironment{appendix},
#       \@chapapp{附录~A}, \thechapter\htu@counter@separator counters) and the invariants are intact (3.9 TNR
#       font stack, size macros, bibstyle + \bibliography in main.tex). The companion integration test proves
#       the RENDERED references via fitz (title SimHei 三号 centered, entries SimSun 五号 [N] hanging indent,
#       Arabic page numbering). Source-greps prove the wiring; fitz proves the RENDERING (Story 2.5/2.6/3.1-3.6
#       lesson). Tests are READ-ONLY — they MUST NOT modify the SUT (Epic 1/2 retro).
#
# ⚠️ AC-2 DECISION-PENDING: the references hanging-indent STYLE — reference PDF p227 is REVERSED ([N] indented
#    x0≈111, body at margin x0≈90) vs current STANDARD ([N] flush-left x0≈70.9, body indented x0≈101). Spec §2.14
#    "序号左顶格" (number flush-left) supports the CURRENT standard style. ATDD-3.7-05 is value-agnostic (the \list
#    dims DECLARED) pending Zy's decision; the behavior proof + style verdict is the integration suite I05/I11.
# ⚠️ AC-4/AC-6 appendix-scope: appendix does NOT render (main.tex has no \appendix). ATDD-3.7-06/07/09 are
#    SOURCE-LEVEL guards (rendered appendix verification DEFERRED to Epic 4.1 per deferred-work.md).

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
echo "ATDD Unit Tests: Story 3.7 — Structured back matter (references, appendix)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P1 Tests — references WIRING (GREEN invariants — inherited zzuthesis config)
# ==========================================
echo "=== P1: references wiring (GREEN — inherited config already matches spec §2.14) ==="

# ATDD-3.7-01: \htu@chapter*{\bibname} — references title via the chapter mechanism (AC-1 wiring, TC-E3-33)
# Truth source: spec §2.14 "'参考文献'用三号黑体字，居中" + reference p227 (title SimHei 15.95 centered). The
#   thebibliography env must render the title via \htu@chapter*{\bibname} (→ \clearpage new-page + chapter
#   format \sffamily\sanhao = 三号黑体居中). GREEN pre/post (inherited zzuthesis).
test_refs_title_chapter() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'htu@chapter\*\{\\bibname\}' htuthesis.cls
}
run_test "P1" "ATDD-3.7-01" "\\htu@chapter*{\\bibname} references title (AC-1 wiring, TC-E3-33; GREEN — inherited)" test_refs_title_chapter

# ATDD-3.7-02: \bibname = 参考文献 (AC-1 — the bib title string)
# The bib name must be 参考文献 (the §2.14 title). GREEN pre/post.
test_bibname_cankao() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'bibname=\{参考文献\}' htuthesis.cls
}
run_test "P1" "ATDD-3.7-02" "\\bibname=参考文献 (AC-1; GREEN)" test_bibname_cankao

# ATDD-3.7-03: \wuhao[1.524] in thebibliography — references body = 五号宋体 (AC-2 wiring, TC-E3-34)
# Truth source: spec §2.14 "参考文献的内容使用五号宋体字". The thebibliography env must set \wuhao (10.5pt). The CJK
#   FACE inherits the document default SimSun. GREEN pre/post (inherited zzuthesis).
test_refs_body_wuhao() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'wuhao\[1\.524\]' htuthesis.cls
}
run_test "P1" "ATDD-3.7-03" "thebibliography \\wuhao[1.524] 五号宋体 (AC-2 wiring, TC-E3-34; GREEN)" test_refs_body_wuhao

# ATDD-3.7-04: end-list [N] numbering wiring (AC-2, TC-E3-34) — REPOINTED by Story 3.12 (2026-06-17)
# REPOINTED by Story 3.12: was "thebibliography \list{\@biblabel} → [N]" (natbib); now Option A biblatex
#   (Zy 2026-06-17) — \printbibliography (gb7714-2015 numeric style produces [N] numbering). thebibliography
#   env removed. §2.14 case-2, gap M1. Decision 2. Behavior proof = integration I07/I08.
test_refs_biblabel_list() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'printbibliography\[type=' htuthesis.cls && \
  grep -qE 'style=gb7714-2015' htuthesis.cls
}
run_test "P1" "ATDD-3.7-04" "end-list [N] via biblatex \\printbibliography (REPOINTED by 3.12 — was thebibliography \\@biblabel)" test_refs_biblabel_list

# ATDD-3.7-05: end-list heading wiring (AC-2, TC-E3-34) — REPOINTED by Story 3.12 (2026-06-17)
# REPOINTED by Story 3.12: was "thebibliography \list reversed-hanging dims (3.7 Option B)"; now Option A
#   biblatex \printbibliography (the thebibliography \list removed). The end-list HANGING DIRECTION
#   (§2.14 序号左顶格 standard vs 3.7 reverse) is REWORK scope of Story 3.13 — not asserted here.
#   §2.14 case-2, gap M1. Decision 2 cross-story override. (Behavior = integration I07 end-list present.)
test_refs_list_reversed_dims() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'defbibheading\{htu-refs' htuthesis.cls
}
run_test "P1" "ATDD-3.7-05" "end-list via biblatex defbibheading (REPOINTED by 3.12 — was thebibliography reversed-hanging; direction→3.13)" test_refs_list_reversed_dims

echo ""

# ==========================================
# P1 Tests — appendix WIRING (SOURCE-LEVEL — appendix does NOT render; rendered deferred to Epic 4.1)
# ==========================================
echo "=== P1: appendix wiring (SOURCE-LEVEL — appendix doesn't render; TC-E3-35/36 rendered → Epic 4.1) ==="

# ATDD-3.7-06: \renewenvironment{appendix} intact (AC-4 wiring, TC-E3-35 source guard)
# Truth source: spec §2.15 "附录A、附录B…" + reference p251 ("附录"+"A"+title SimHei 三号 centered). The appendix
#   env must be the inherited zzuthesis wrapper (\let\htu@appendix\appendix + \renewenvironment{appendix}). GREEN
#   pre/post. The appendix does NOT render in main.pdf (no \appendix in main.tex) → rendered title verification
#   DEFERRED to Epic 4 Story 4.1; this is a source-level wiring guard.
test_appendix_env_intact() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'renewenvironment\{appendix\}' htuthesis.cls
}
run_test "P1" "ATDD-3.7-06" "\\renewenvironment{appendix} intact (AC-4, TC-E3-35 source guard; rendered → Epic 4.1)" test_appendix_env_intact

# ATDD-3.7-07: \gdef\@chapapp{\appendixname~\thechapter} — "附录 A" chapter prefix (AC-4 wiring)
# The appendix env must \gdef \@chapapp to "附录~A" (\appendixname~\thechapter) so a \chapter inside appendix
#   renders "附录 A 标题". GREEN pre/post. (Rendered verification deferred to 4.1 — appendix doesn't render.)
test_appendix_chapapp() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'gdef\\@chapapp\{\\appendixname~\\thechapter\}' htuthesis.cls
}
run_test "P1" "ATDD-3.7-07" "\\gdef\\@chapapp{\\appendixname~\\thechapter} → 附录A (AC-4; rendered → Epic 4.1)" test_appendix_chapapp

# ATDD-3.7-08: \appendixname = 附录 (AC-4 — the appendix name string)
# The appendix name must be 附录. GREEN pre/post.
test_appendixname_fulu() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'appendixname=\{附录\}' htuthesis.cls
}
run_test "P1" "ATDD-3.7-08" "\\appendixname=附录 (AC-4; GREEN)" test_appendixname_fulu

# ATDD-3.7-09: \thefigure/\thetable/\theequation use \thechapter\htu@counter@separator (AC-6, TC-E3-36 source guard)
# Truth source: spec §2.11/§2.12/§2.13 appendix counters "图A-1"/"表A-1"/"(A-1)". The global counters (Story 2.6)
#   emit \thechapter\htu@counter@separator\@arabic\c@<X>; \appendix makes \thechapter alphabetic → "A-1" by
#   construction. GREEN pre/post (2.6 wiring intact; 3.7 does NOT redefine). NOTE: each \renewcommand spans 2
#   lines (cls:398-403); join newlines before matching (tr-join sidesteps the col-0 / line-grep brittleness flagged
#   for 2.2-2.6/3.2/3.5/3.6 deferred-work). The appendix does NOT render → rendered counter verification DEFERRED
#   to Epic 4.1 (per deferred-work.md "A-1 unverifiable rendered"); this is a source-level construction proof.
test_appendix_counters() {
  [[ -f "htuthesis.cls" ]] || return 1
  local joined
  joined=$(tr '\n' ' ' < htuthesis.cls)
  grep -qE 'renewcommand.theequation.{0,140}thechapter.{0,40}htu@counter@separator' <<<"$joined" && \
  grep -qE 'renewcommand.thefigure.{0,140}thechapter.{0,40}htu@counter@separator' <<<"$joined" && \
  grep -qE 'renewcommand.thetable.{0,140}thechapter.{0,40}htu@counter@separator' <<<"$joined"
}
run_test "P1" "ATDD-3.7-09" "\\theequation/figure/table use \\thechapter+separator → A-1 (AC-6, TC-E3-36 source guard; rendered → Epic 4.1)" test_appendix_counters

echo ""

# ==========================================
# P2 Tests — compile/regression + scope guards
# ==========================================
echo "=== P2: compile wiring (bibstyle + \bibliography) + regression + scope guards ==="

# ATDD-3.7-10: bibliography compile wiring (AC-2) — REPOINTED by Story 3.12 (2026-06-17)
# REPOINTED by Story 3.12: was "\bibliographystyle{htuthesis} + \bibliography{ref/refs} + htuthesis.bst";
#   now Option A biblatex — main.tex \makebibliography + cls \addbibresource{ref/refs.bib} + biblatex-gb7714-2015.
#   htuthesis.bst SUPERSEDED (kept as fallback). §2.14 case-2, gap M1. Decision 2.
test_bibliography_wired() {
  [[ -f "main.tex" ]] || return 1
  grep -q 'makebibliography' main.tex && \
  grep -qE 'addbibresource\{ref/refs\.bib\}' htuthesis.cls
}
run_test "P2" "ATDD-3.7-10" "bibliography wiring (\\makebibliography + \\addbibresource; REPOINTED by 3.12 — was natbib \\bibliography)" test_bibliography_wired

# ATDD-3.7-11: regression — \setmainfont{Times New Roman} preserved (Story 3.9, AC-7/AC-8)
# 3.7 consumes 3.9's \rmfamily→TNR so references Latin digits/punct ("[J].", ",", page-range) render TNR (NOT
#   Latin Modern). Must remain intact.
test_setmainfont_tnr_preserved() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'setmainfont\{Times New Roman\}' htuthesis.cls
}
run_test "P2" "ATDD-3.7-11" "regression: \\setmainfont{Times New Roman} preserved (Story 3.9, AC-7/8)" test_setmainfont_tnr_preserved

# ATDD-3.7-12: regression — \sanhao / \wuhao / \xiaosi size macros intact (AC-7 — references/appendix depend on them)
# references title = \sanhao (三号 16pt), body = \wuhao (五号 10.5pt), appendix body = \xiaosi (小四 12pt). The size
#   macros (defined in cls from Story 2.5) must remain. GREEN pre/post.
test_size_macros_intact() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'htu@def@fontsize\{sanhao\}\{16bp\}' htuthesis.cls && \
  grep -qE 'htu@def@fontsize\{wuhao\}' htuthesis.cls && \
  grep -qE 'htu@def@fontsize\{xiaosi\}' htuthesis.cls
}
run_test "P2" "ATDD-3.7-12" "regression: \\sanhao/\\wuhao/\\xiaosi size macros intact (AC-7; GREEN)" test_size_macros_intact

# ATDD-3.7-13: scope guard — \htu@counter@separator{-} (hyphen) preserved (Story 2.6; appendix A-1 depends on it)
# The appendix "A-1" counter form depends on the global hyphen separator wired in Story 2.6. 3.7 must NOT change
#   it. GREEN pre/post — a scope-violation guard (3.7 consumes 2.6's separator, does not redefine it).
test_counter_separator_hyphen() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -qE 'def\\htu@counter@separator\{-\}' htuthesis.def
}
run_test "P2" "ATDD-3.7-13" "scope guard: \\htu@counter@separator{-} hyphen intact (2.6; appendix A-1; GREEN)" test_counter_separator_hyphen

# ATDD-3.7-14: scope guard — \appendix primitive let-bound (not removed/double-defined) (AC-4)
# The appendix env does \let\htu@appendix\appendix then \renewenvironment{appendix}{\htu@appendix...}. The \let
#   must remain (so the appendix env still calls the real \appendix primitive → alphabetic \thechapter). GREEN
#   pre/post — guards against a future edit that removes the \let and breaks appendix chapter lettering.
test_appendix_let_primitive() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'let\\htu@appendix\\appendix' htuthesis.cls
}
run_test "P2" "ATDD-3.7-14" "scope guard: \\let\\htu@appendix\\appendix primitive bound (AC-4; GREEN)" test_appendix_let_primitive

# ATDD-3.7-15: bibliography backend (AC-2) — REPOINTED by Story 3.12 (2026-06-17)
# REPOINTED by Story 3.12: was "natbib [numbers,super,sort&compress] + \bibpunct intact"; now Option A biblatex
#   (Zy 2026-06-17) — natbib REMOVED, \bibpunct REMOVED. §2.14 case-2, gap M1. Decision 2 cross-story override.
test_natbib_config() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'RequirePackage\[backend=biber[^]]*\]\{biblatex\}' htuthesis.cls && \
  ! grep -vE '^\s*%' htuthesis.cls | grep -qE 'RequirePackage(\[[^]]*\])?\{natbib\}'
}
run_test "P2" "ATDD-3.7-15" "bibliography backend = biblatex (natbib removed; REPOINTED by 3.12 — was natbib+\\bibpunct)" test_natbib_config

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
  echo "      already renders on main.pdf p44: title SimHei 三号 centered, entries [N] TNR + SimSun 五号 hanging"
  echo "      indent; appendix machinery correct by construction, rendered deferred to Epic 4.1)."
  echo "   GREEN guards (lock-in):"
  echo "      references: 3.7-01 (\\htu@chapter*{\\bibname} title), 3.7-02 (\\bibname=参考文献),"
  echo "         3.7-03 (\\wuhao 五号 body), 3.7-04 (\\@biblabel [N] list), 3.7-05 (\\list reversed hanging — Option B)."
  echo "      appendix (source-level; rendered → Epic 4.1): 3.7-06 (\\renewenvironment{appendix}),"
  echo "         3.7-07 (\\@chapapp{附录~A}), 3.7-08 (\\appendixname=附录), 3.7-09 (\\thechapter+separator → A-1)."
  echo "      compile/regression: 3.7-10 (bibstyle+\\bibliography+bst), 3.7-11 (TNR 3.9), 3.7-12 (size macros),"
  echo "         3.7-13 (hyphen separator 2.6), 3.7-14 (\\let appendix primitive), 3.7-15 (natbib config)."
  echo ""
  echo "   NOTE: AC-2 hanging-indent RESOLVED 2026-06-16 to Option B (reference PDF p227 REVERSED per Decision 4;"
  echo "         Zy-approved transparent deviation from spec §2.14 '序号左顶格'). 3.7-05 asserts the reversed config;"
  echo "         AC-4/AC-6 appendix rendered verification DEFERRED to Epic 4.1 (appendix doesn't render in main.pdf;"
  echo "         data/app0{1,2,3}.tex have no floats → no 图A-1/表A-1 to verify; per deferred-work.md tag)."
  echo "         Source-greps prove the WIRING; the integration suite proves the RENDERED references via fitz."
  echo "         architecture.md:41 = MEDIUM; references LOW (gbt7714 :687). Tests are read-only (no SUT mutation)."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
