#!/usr/bin/env bash
# test-story-4.1-unit.sh — ATDD Unit (source-level) Tests for Story 4.1 (complete example thesis with sample content)
# TDD Phase: RED — the RED driver cluster is unit-01 (main.tex \appendix + \include{data/app0N} wiring — main.tex has
#             NO \appendix at baseline ed20363), unit-02 (appendix data figure/table/equation floats — app01-03 have
#             ZERO floats, so G5b counter 图A-1 cannot render), unit-03 (check-structure.sh required_files list missing
#             app01-03), unit-04 (data/chap03.tex:42 stale \ifzzu@bachelor demo command — bachelor removed Story 1.3),
#             unit-05 (ref/refs.bib 8× pages={N$\sim$M} — raw math renders ∼ not GB/T 7714 --). Post-impl (spec §2.15
#             appendix + §2.10 numbering + sample-content cleanup): all 5 closed at source. GREEN guard unit-06
#             (appendix env \xiaosi\songti mechanism retained — Story 3.15 G5a; 4.1 wiring must NOT remove it) PASS
#             pre+post.
#
# Usage: bash tests/test-story-4.1-unit.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 (unit-01 wiring + unit-02 floats — the appendix first-compile enablers) / P1 (unit-03/04/05 cleanup + guard)
# Linked ACs: AC-2 (appendix wired, §2.15), AC-3 (appendix floats → G5b counter 图A-1), AC-5 (stale sample cleanup),
#             AC-7 (data/ complete + check-structure guard)
# Linked Risk: R-23 (score 6 — appendix + sc first-compile paths; unit-01/02 are the wiring preconditions)
# TC coverage (wiring): TC-E4-02 (appendix body — unit-06 mechanism + int I04 render), TC-E4-03 (counter — unit-02 floats + int I05 render)
#
# NOTE: these source-greps prove the WIRING / SOURCE STATE; the fitz integration tests (test-story-4.1-integration.sh)
#   prove the RENDERED span (appendix body font, counter glyphs, full content). Every 4.1 RED driver probes the rendered
#   span at the integration layer — the wrong-target-AC root-cause discipline (Epic 3 retro Lesson 3; architecture
#   silent-failure #13/#14; TC-E4-36 suite audit). Unit tests here are the wiring/source preconditions.
#
# Truth source: 河南师范大学研究生学位论文格式要求.md §2.15 line 439 (appendix 小四宋体) + §2.10 line 235-237 (numbering)
#   + §2.11/2.12/2.13 (figure/table/equation counter form). spec PRIORITY (CLAUDE.md Decision 4, corrected 2026-06-17).
#
# Line refs verified vs HEAD ed20363: appendix env = cls:1014-1029 (\let\htu@appendix\appendix + \renewenvironment{appendix});
#   app01-03 data files exist but have only \chapter+\section* (zero floats); check-structure.sh required_files ends at
#   data/chap04.tex / data/resume.tex (app01-03 NOT listed); data/chap03.tex:42 = \ifzzu@bachelor.

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
echo "ATDD Unit Tests: Story 4.1 — complete example thesis with sample content (§2.15 appendix + §2.10 numbering)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# Shared helper: comment-stripped source read (prevents false-RED from commented-out lines — Epic 1 retro lesson).
read_main_stripped() {
  [[ -f "main.tex" ]] && grep -vE '^[[:space:]]*%' main.tex
}

# ==========================================
# P0 — AC-2/7: main.tex wires \appendix + \include{data/app0N} (the G5a/G5b first-compile enabler)
# ==========================================
echo "=== P0: main.tex \\appendix + appendix includes wired (AC-2/7, §2.15) ==="

# ATDD-4.1-01: main.tex must contain \appendix followed by \include{data/app01..03} in the backmatter (after
#   \makebibliography, before \include{data/ack}). Pre-impl (ed20363): main.tex backmatter has \makebibliography →
#   \include{ack} → \include{resume} → \makedeclaration, NO \appendix → the appendix env mechanism (cls:1015) is never
#   invoked → G5a body font + G5b counter unrenderable. RED pre: no \appendix in non-commented main.tex.
test_main_wires_appendix() {
  [[ -f "main.tex" ]] || return 1
  local body
  body=$(read_main_stripped)
  # \appendix command present (not inside a comment)
  echo "$body" | grep -qE '(^|[^a-zA-Z@])\\appendix([^a-zA-Z]|$)' || { echo "  (no \\appendix in main.tex — RED)"; return 1; }
  # at least one appendix data include (app01..03)
  echo "$body" | grep -qE '\\include\{data/app0[1-3]\}' || { echo "  (no \\include{data/app0N} — RED)"; return 1; }
  # ordering guard: \appendix must come AFTER \makebibliography (appendix is post-references backmatter, §2.15)
  local bib_line app_line
  bib_line=$(echo "$body" | grep -nE '\\makebibliography' | head -1 | cut -d: -f1)
  app_line=$(echo "$body" | grep -nE '(^|[^a-zA-Z@])\\appendix([^a-zA-Z]|$)' | head -1 | cut -d: -f1)
  if [[ -n "$bib_line" && -n "$app_line" ]]; then
    [[ "$app_line" -gt "$bib_line" ]] || { echo "  (\\appendix at line $app_line BEFORE \\makebibliography at $bib_line — wrong order; RED)"; return 1; }
  fi
  echo "  (\\appendix + \\include{data/app0N} present, after \\makebibliography — GREEN)"
  return 0
}
run_test "P0" "ATDD-4.1-01" "main.tex wires \\appendix + \\include{data/app0N} after \\makebibliography (AC-2/7, §2.15; *** RED DRIVER *** — no \\appendix at ed20363)" test_main_wires_appendix

# ==========================================
# P0 — AC-3: appendix data file contains ≥1 figure + ≥1 table + ≥1 equation (G5b counter 图A-1/表A-1/（A-1）)
# ==========================================
echo "=== P0: appendix data has figure + table + equation floats (AC-3, G5b counter, §2.11/2.12/2.13) ==="

# ATDD-4.1-02: at least one appendix data file (app01..03) must contain a figure env, a table env, and an equation —
#   so \thefigure/\thetable/\theequation render the A-1 form under \appendix (alphabetic \thechapter). Pre-impl
#   (ed20363): app01=表格附件(\chapter+\section*), app02=English prose, app03=Chinese prose — ALL ZERO floats
#   (deferred-work §2.6). RED pre: no figure/table/equation across app01-03.
test_appendix_has_floats() {
  [[ -d "data" ]] || return 1
  local fig tab eq
  fig=$(grep -lE '\\begin\{figure\}|\\includegraphics' data/app0[1-3].tex 2>/dev/null | wc -l | tr -d '[:space:]')
  tab=$(grep -lE '\\begin\{table\}' data/app0[1-3].tex 2>/dev/null | wc -l | tr -d '[:space:]')
  eq=$(grep -lE '\$\$|\\begin\{equation\}|\\begin\{align\}' data/app0[1-3].tex 2>/dev/null | wc -l | tr -d '[:space:]')
  echo "  appendix files with figure=$fig table=$tab equation=$eq (expect ≥1 each)"
  [[ "$fig" -ge 1 && "$tab" -ge 1 && "$eq" -ge 1 ]]
}
run_test "P0" "ATDD-4.1-02" "appendix data has figure + table + equation floats (AC-3, G5b counter; *** RED DRIVER *** — zero floats at ed20363)" test_appendix_has_floats

# ==========================================
# P1 — AC-7: check-structure.sh required_files includes app01-03
# ==========================================
echo "=== P1: check-structure.sh guards app01-03 existence (AC-7, data/ complete) ==="

# ATDD-4.1-03: tests/check-structure.sh required_files array must list data/app01.tex, app02.tex, app03.tex so the
#   structure gate catches a missing appendix file. Pre-impl (ed20363): required_files ends at data/chap04.tex +
#   data/resume.tex — app01-03 NOT guarded (they exist but invisibly to the structure check). RED pre: <3 app entries.
test_check_structure_lists_appendix() {
  [[ -f "tests/check-structure.sh" ]] || return 1
  local n
  n=$(grep -cE 'data/app0[1-3]\.tex' tests/check-structure.sh 2>/dev/null | tr -d '[:space:]')
  echo "  (app01-03 entries in required_files: $n [expect 3])"
  [[ "$n" -ge 3 ]]
}
run_test "P1" "ATDD-4.1-03" "check-structure.sh lists app01-03 in required_files (AC-7; *** RED DRIVER *** — absent at ed20363)" test_check_structure_lists_appendix

# ==========================================
# P1 — AC-5: no stale \ifzzu@bachelor in data/chap03.tex (bachelor removed Story 1.3)
# ==========================================
echo "=== P1: data/chap03.tex no stale \\ifzzu@bachelor (AC-5, sample cleanup, deferred §1.4) ==="

# ATDD-4.1-04: the chap03.tex sample code-block must not reference the removed \ifzzu@bachelor command (bachelor branch
#   deleted Story 1.3; deferred-work §1.4 line 60). Pre-impl (ed20363): chap03.tex:42 contains \ifzzu@bachelor in a demo
#   \begin{latex} block → stale command that no longer exists. RED pre: ≥1 occurrence.
test_no_stale_zzu_bachelor() {
  [[ -f "data/chap03.tex" ]] || return 1
  local n
  n=$(grep -cE '\\ifzzu@bachelor' data/chap03.tex 2>/dev/null | tr -d '[:space:]')
  echo "  (\\ifzzu@bachelor in chap03.tex: $n [expect 0])"
  [[ "$n" -eq 0 ]]
}
run_test "P1" "ATDD-4.1-04" "data/chap03.tex no stale \\ifzzu@bachelor (AC-5; *** RED DRIVER *** — present at chap03:42, ed20363)" test_no_stale_zzu_bachelor

# ==========================================
# P1 — AC-5: ref/refs.bib no $\sim$ in pages fields (GB/T 7714 en-dash)
# ==========================================
echo "=== P1: ref/refs.bib no \$\\sim\$ in pages (AC-5, GB/T 7714 -- form, deferred §3.12) ==="

# ATDD-4.1-05: refs.bib pages fields must use GB/T 7714 en-dash (--) not raw math $\sim$ (which renders ∼ via
#   LatinModernMath, impure AC-1 full entry). Pre-impl (ed20363): 8 entries use pages={N$\sim$M} (deferred-work §3.12).
#   RED pre: ≥1 $\sim$ in a pages= field.
test_no_sim_in_pages() {
  [[ -f "ref/refs.bib" ]] || return 1
  local n
  n=$(grep -cE 'pages\s*=\s*\{[^}]*\$\\sim\$' ref/refs.bib 2>/dev/null | tr -d '[:space:]')
  echo "  (pages={...\$\\sim\$...} entries: $n [expect 0])"
  [[ "$n" -eq 0 ]]
}
run_test "P1" "ATDD-4.1-05" "ref/refs.bib no \$\\sim\$ in pages fields (AC-5, GB/T 7714 --; *** RED DRIVER *** — 8 present at ed20363)" test_no_sim_in_pages

# ==========================================
# GREEN guard — AC-2: appendix env \xiaosi\songti mechanism retained (Story 3.15 G5a; 4.1 must NOT remove)
# ==========================================
echo "=== GREEN guard: appendix env \\xiaosi\\songti retained (AC-2, G5a mechanism, §2.15) ==="

# ATDD-4.1-06: the appendix environment begin-clause must STILL explicitly set \xiaosi\songti (Story 3.15 G5a delivered
#   this; 4.1 wiring must not remove it — the rendered proof is int I04). GREEN pre+post. RED = 4.1 accidentally dropped
#   the G5a font when addressing the font-restore (Task 1 must keep \xiaosi\songti in BEGIN; only the END/restore changes).
test_appendix_env_body_font_retained() {
  [[ -f "htuthesis.cls" ]] || return 1
  python - <<'PY'
import re, sys
src = open("htuthesis.cls", encoding="utf-8").read()
lines = [ln for ln in src.splitlines() if not ln.lstrip().startswith("%")]
text = "\n".join(lines)
i = text.find(r"\renewenvironment{appendix}")
if i < 0:
    print("  (\\renewenvironment{appendix} not found — RED)"); sys.exit(1)
seg = text[i:i+700]  # begin-clause window
has = (r"\xiaosi" in seg) and (("songti" in seg) or ("\\song" in seg))
print("  appendix env begin-clause retains \\xiaosi+\\songti: %s" % has)
sys.exit(0 if has else 1)
PY
}
run_test "P1" "ATDD-4.1-06" "appendix env \\xiaosi\\songti retained (AC-2, G5a mechanism; GREEN guard pre+post — 4.1 must not remove)" test_appendix_env_body_font_retained

echo ""
echo "=============================================="
echo "Summary: PASS=$PASS FAIL=$FAIL SKIP=$SKIP_COUNT"
echo "=============================================="
if [[ "$SKIP" == "1" ]]; then
  echo ""
  echo "   TDD RED phase — scaffolds inert (ATDD_SKIP=1). Activate with --run or ATDD_SKIP=0."
  echo "   RED drivers (FAIL pre-impl ed20363 state, PASS post-impl spec §2.15/§2.10 + sample cleanup):"
  echo "      01 main.tex \\appendix + \\include{data/app0N} wired (AC-2/7, §2.15)"
  echo "      02 appendix data figure+table+equation floats (AC-3, G5b counter, §2.11/2.12/2.13)"
  echo "      03 check-structure.sh lists app01-03 (AC-7)"
  echo "      04 chap03.tex no \\ifzzu@bachelor (AC-5, deferred §1.4)"
  echo "      05 refs.bib no \$\\sim\$ in pages (AC-5, GB/T 7714 --, deferred §3.12)"
  echo "   GREEN guard (PASS pre+post):"
  echo "      06 appendix env \\xiaosi\\songti retained (AC-2, G5a mechanism — 4.1 wiring must not remove)."
  echo ""
  echo "   ⚠ Dev order (R-23 mitigation): Task 1 (appendix env font-restore) BEFORE Task 2 (wiring). The G5a"
  echo "      \\xiaosi\\songti (unit-06 guard) stays in BEGIN; only the END/restore strategy changes (Task 1)."
  echo "   Source greps prove WIRING; fitz int tests prove RENDERING. Wrong-target-AC discipline (Epic 3 retro"
  echo "      Lesson 3): appendix body/counter proven via rendered span/regex, not \\the<dim>/\\the<counter> source."
  echo "   Tests are read-only (no SUT mutation — Epic 1 retro). Line refs verified vs HEAD ed20363."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
