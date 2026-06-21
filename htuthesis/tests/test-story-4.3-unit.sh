#!/usr/bin/env bash
# test-story-4.3-unit.sh — ATDD Unit (source-level) Tests for Story 4.3 (debug mode and calibration tool)
# TDD Phase: RED — the RED driver cluster is unit-01 (\newif\ifhtu@debug switch + \DeclareOption{debug} option —
#             ABSENT at baseline 23696b0; cls:20-35 option block has only doctor/openright/numbering switches), unit-02
#             (a \ifhtu@debug-gated --- debug diagnostics --- section in \htucheck — absent; the 4.2 self-check body
#             has no \ifhtu@debug block), unit-03 (tools/calibrate.tex exists + standalone — NO tools/ dir at baseline),
#             unit-04 (calibrate.tex uses \InputIfFileExists — absent), unit-05 (Makefile `calibrate` phony target —
#             absent; Makefile has only thesis/a3cover/clean/test), unit-06 (Makefile `debug-check` phony target —
#             absent), unit-07 (NFR-5 6-warning watch-list — absent in cls + Makefile, TC-E4-24). Post-impl (debug option
#             + switch + gated debug section + tools/calibrate.tex + Makefile targets + watch-list): all 7 closed at
#             source. GREEN guards unit-08 (4.2 self-check sections font/coverage/audit PRESERVED in \htucheck body —
#             AC-8 regression guard; [debug] gating must not move them), unit-09 (font \PackageError gates cls:71-88
#             RETAINED — 4.3 must not touch them).
#
# Usage: bash tests/test-story-4.3-unit.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 (unit-01 debug switch + unit-02 debug section + unit-03 calibrate standalone + unit-05 Makefile calibrate
#           + unit-06 Makefile debug-check — the debug/calibrate pillars) / P1 (unit-04 InputIfFileExists + unit-07 NFR-5
#           watch-list + GREEN guards unit-08/09)
# Linked ACs: AC-1 (debug option), AC-2 (\ifhtu@debug gates verbosity), AC-3 (calibrate standalone rulers), AC-4
#             (calibrate independent), AC-5 (\InputIfFileExists), AC-6 (NFR-5 6 warnings), AC-7 (Makefile targets),
#             AC-8 (no regression — 4.2 sections preserved)
# Linked Risk: R-29 (calibrate accuracy + independence — unit-03/04), R-25 (wrong-target-AC — unit-08 preserves the
#             4.2 assertion-audit; the NEW debug section reports, does not assert)
# TC coverage: TC-E4-19 (debug mode — unit-01/02), TC-E4-20 (calibrate standalone — unit-03), TC-E4-22 (InputIfFileExists
#             — unit-04 source half), TC-E4-24 (6 NFR-5 warnings — unit-07 source half)
#
# NOTE: these source-greps prove the DEBUG+CALIBRATE SOURCE STATE (switch wired, debug section gated, calibrate.tex
#   present + standalone, Makefile targets present, watch-list configured); the integration tests (test-story-4.3-
#   integration.sh) prove the COMPILED BEHAVIOR (.log debug section, calibrate.pdf rulers/dims, make debug-check exit).
#   The wrong-target-AC discipline (Epic 3 retro Lesson 3): the NEW debug section REPORTS dims (does not ASSERT them as
#   spec-compliance evidence); calibrate accuracy is cross-checked by fitz vs \htucheck (integration I07), not a
#   self-check proxy. Source greps here prove WIRING; integration proves MECHANISM.
#
# Truth source: architecture.md §342 (debug mode decision 4b) + §343 (calibration tool decision 4c) + §449-452
#   (\ifhtu@debug code style) + §618-621 (tools/ boundary + \InputIfFileExists); NFR-5 (6 LaTeX warnings as errors);
#   test-design-epic-4.md R-29 (calibrate accuracy + independence) + TC-E4-19..24. spec PRIORITY (CLAUDE.md Decision 4).
#
# Line refs verified vs HEAD 23696b0: option block = cls:20-35 (doctor/openright/numbering switches, NO \ifhtu@debug);
#   \htucheck def = cls:1060-1130 (4.2 tiered self-check, NO \ifhtu@debug-gated section); font gates = cls:71-88
#   (\IfFontExistsTF{<font>}{}{\PackageError{...}} ×5, PRE-EXISTING — 4.3 must not touch); tools/ dir = ABSENT.

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
echo "ATDD Unit Tests: Story 4.3 — debug mode and calibration tool ([debug] option + calibrate.tex + Makefile)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# Shared helper: extract the \htucheck macro body (cls) — comment-stripped, from \newcommand{\htucheck} to the
#   closing brace of its def. Used by unit-02/08 to scope greps to the self-check region. (Reused verbatim from 4.2;
#   brace-walk starts at m.end() not m.start() to skip the name-arg '{' — Story 4.2 review patch P3.)
htucheck_body() {
  [[ -f "htuthesis.cls" ]] || return 1
  python - "$@" <<'PY'
import re, sys
src = open("htuthesis.cls", encoding="utf-8").read()
lines = [ln for ln in src.splitlines() if not ln.lstrip().startswith("%")]
text = "\n".join(lines)
m = re.search(r'\\newcommand\{\\htucheck\}', text)
if not m:
    print("NO_HTUCHECK_DEF")
    sys.exit(0)
rest = text[m.end():]
ib = rest.find("{")
if ib < 0:
    print("NO_BODY_BRACE")
    sys.exit(0)
i = m.end() + ib
depth = 0
start = i
for j in range(i, len(text)):
    c = text[j]
    if c == "{": depth += 1
    elif c == "}":
        depth -= 1
        if depth == 0:
            sys.stdout.write(text[start:j+1])
            sys.exit(0)
print("UNTERMINATED")
PY
}

# ==========================================
# P0 — AC-1: \newif\ifhtu@debug switch + \DeclareOption{debug} option present in cls option block
# ==========================================
echo "=== P0: [debug] cls option + \\ifhtu@debug switch (AC-1, architecture §342, §368 step 9) ==="

# ATDD-4.3-01: the cls option block (cls:20-35) must declare a `debug` option + the \ifhtu@debug boolean switch it sets.
#   Pre-impl (23696b0): only doctor/openright/numbering switches exist (grep confirms). RED pre: no \newif\ifhtu@debug,
#   no \DeclareOption{debug}. This is the precondition for AC-1/2 ([debug] activates verbose output via \ifhtu@debug).
test_debug_option_and_switch() {
  [[ -f "htuthesis.cls" ]] || return 1
  python - <<'PY'
import re, sys
src = open("htuthesis.cls", encoding="utf-8").read()
lines = [ln for ln in src.splitlines() if not ln.lstrip().startswith("%")]
text = "\n".join(lines)
has_switch = bool(re.search(r'\\newif\s*\\ifhtu@debug', text))
has_option = bool(re.search(r'\\DeclareOption\s*\{\s*debug\s*\}\s*\{\s*\\htu@debugtrue\s*\}', text))
print("  \\newif\\ifhtu@debug switch: %s | \\DeclareOption{debug}: %s" % (has_switch, has_option))
sys.exit(0 if (has_switch and has_option) else 1)
PY
}
run_test "P0" "ATDD-4.3-01" "[debug] option + \\ifhtu@debug switch declared (AC-1; *** RED DRIVER *** — absent at 23696b0 cls:20-35)" test_debug_option_and_switch

# ==========================================
# P0 — AC-1/2: \htucheck has a \ifhtu@debug-gated --- debug diagnostics --- section
# ==========================================
echo "=== P0: \\htucheck \\ifhtu@debug-gated debug-diagnostics section (AC-1/2, architecture §342/§449-452) ==="

# ATDD-4.3-02: the \htucheck macro body must contain a debug-diagnostics section wrapped in \ifhtu@debug ... \fi (the
#   verbose output AC-1 activates under [debug]). Pre-impl (23696b0): \htucheck body has no \ifhtu@debug token (the 4.2
#   self-check runs unconditionally). RED pre: no \ifhtu@debug in body, no debug-diagnostics marker.
#   The section is ADDITIVE (AC-8) — the 4.2 sections stay always-on; only the NEW debug block is gated.
test_htucheck_has_debug_section() {
  local body
  body=$(htucheck_body) || return 1
  [[ "$body" == "NO_HTUCHECK_DEF" || "$body" == "UNTERMINATED" ]] && { echo "  (\\htucheck def not found/unterminated — RED)"; return 1; }
  echo "$body" | grep -qE '\\ifhtu@debug' || { echo "  (no \\ifhtu@debug in \\htucheck body — RED)"; return 1; }
  # a debug-diagnostics marker inside the gated block
  echo "$body" | grep -qiE 'debug[ _-]?diagnostic|debug[ _-]?mode|NFR-5|warning[ _-]?watch|watch[ _-]?list' || {
    echo "  (\\ifhtu@debug present but no debug-diagnostics/watch-list marker — RED)"; return 1; }
  echo "  (\\ifhtu@debug-gated debug-diagnostics section present in \\htucheck — GREEN)"
  return 0
}
run_test "P0" "ATDD-4.3-02" "\\htucheck \\ifhtu@debug-gated debug-diagnostics section (AC-1/2; *** RED DRIVER *** — absent at 23696b0)" test_htucheck_has_debug_section

# ==========================================
# P0 — AC-3/4, TC-E4-20: tools/calibrate.tex exists + standalone (does NOT load htuthesis.cls)
# ==========================================
echo "=== P0: tools/calibrate.tex exists + standalone (AC-3/4, TC-E4-20, architecture §343/§618-620) ==="

# ATDD-4.3-03: tools/calibrate.tex must exist AND be standalone — its \documentclass must NOT be htuthesis (independence
#   AC-4; architecture §343 "independent from main template"). Pre-impl (23696b0): NO tools/ dir. RED pre: file absent.
#   The standalone-ness check (not \documentclass{htuthesis}) guards R-29 (calibrate independence).
test_calibrate_tex_exists_standalone() {
  [[ -f "tools/calibrate.tex" ]] || { echo "  (tools/calibrate.tex absent — RED, no tools/ dir at 23696b0)"; return 1; }
  # standalone: \documentclass is NOT htuthesis (loads article/standalone/minimal, etc.)
  python - <<'PY'
import re, sys
src = open("tools/calibrate.tex", encoding="utf-8").read()
m = re.search(r'\\documentclass(?:\s*\[[^\]]*\])?\s*\{([^}]*)\}', src)
if not m:
    print("  (no \\documentclass in calibrate.tex — RED)"); sys.exit(1)
cls = m.group(1).strip()
independent = cls.lower() not in ("htuthesis",)
# tikz required for rulers (AC-3 TikZ rulers)
has_tikz = bool(re.search(r'\\usepackage\s*(\[[^\]]*\])?\s*\{tikz\}|\\usetikzlibrary', src))
print("  calibrate \\documentclass{%s} | standalone(not htuthesis): %s | tikz loaded: %s" % (cls, independent, has_tikz))
sys.exit(0 if (independent and has_tikz) else 1)
PY
}
run_test "P0" "ATDD-4.3-03" "tools/calibrate.tex exists + standalone (not \\documentclass{htuthesis}) + tikz (AC-3/4, TC-E4-20; *** RED DRIVER *** — no tools/ dir at 23696b0)" test_calibrate_tex_exists_standalone

# ==========================================
# P1 — AC-5, TC-E4-22 (source half): calibrate.tex uses \InputIfFileExists
# ==========================================
echo "=== P1: calibrate.tex uses \\InputIfFileExists (AC-5, TC-E4-22, architecture §621) ==="

# ATDD-4.3-04: tools/calibrate.tex must use \InputIfFileExists{<file>}{<true>}{<false>} for path resilience (a missing
#   optional include degrades gracefully). Pre-impl (23696b0): no file. RED pre: absent.
test_calibrate_uses_inputifexists() {
  [[ -f "tools/calibrate.tex" ]] || { echo "  (tools/calibrate.tex absent — RED)"; return 1; }
  grep -qE '\\InputIfFileExists' tools/calibrate.tex || { echo "  (no \\InputIfFileExists in calibrate.tex — RED)"; return 1; }
  echo "  (\\InputIfFileExists present in calibrate.tex — GREEN)"
  return 0
}
run_test "P1" "ATDD-4.3-04" "calibrate.tex uses \\InputIfFileExists (AC-5, TC-E4-22; *** RED DRIVER *** — absent at 23696b0)" test_calibrate_uses_inputifexists

# ==========================================
# P0 — AC-7: Makefile `calibrate` phony target present
# ==========================================
echo "=== P0: Makefile 'calibrate' phony target (AC-7, architecture §532) ==="

# ATDD-4.3-05: the Makefile must have a `calibrate` target that compiles tools/calibrate.tex standalone (NOT part of
#   the default all/thesis/test). Pre-impl (23696b0): Makefile has only thesis/a3cover/clean/test/compile-check/lint/
#   structure targets. RED pre: no `calibrate:` rule.
test_makefile_calibrate_target() {
  [[ -f "Makefile" ]] || return 1
  grep -qE '^[[:space:]]*calibrate[[:space:]]*:' Makefile || { echo "  (no 'calibrate:' target in Makefile — RED)"; return 1; }
  # it must NOT be wired into the default all/thesis/test (independence AC-4)
  if grep -Eq '^all[[:space:]]*:.*calibrate' Makefile; then
    echo "  (calibrate wired into default 'all' — violates independence AC-4 — RED)"; return 1
  fi
  echo "  ('calibrate' target present, not in default 'all' — GREEN)"
  return 0
}
run_test "P0" "ATDD-4.3-05" "Makefile 'calibrate' phony target present + not in default all (AC-7; *** RED DRIVER *** — absent at 23696b0)" test_makefile_calibrate_target

# ==========================================
# P0 — AC-6/7: Makefile `debug-check` phony target present
# ==========================================
echo "=== P0: Makefile 'debug-check' phony target (AC-6/7, NFR-5) ==="

# ATDD-4.3-06: the Makefile must have a `debug-check` target — the NFR-5 harness (sed-copy [doctor,debug] + compile +
#   6-warning grep; warnings treated as errors during development). Pre-impl (23696b0): absent. RED pre: no target.
test_makefile_debug_check_target() {
  [[ -f "Makefile" ]] || return 1
  grep -qE '^[[:space:]]*debug-check[[:space:]]*:' Makefile || { echo "  (no 'debug-check:' target in Makefile — RED)"; return 1; }
  if grep -Eq '^all[[:space:]]*:.*debug-check' Makefile; then
    echo "  (debug-check wired into default 'all' — should be opt-in dev tool — RED)"; return 1
  fi
  echo "  ('debug-check' target present, opt-in — GREEN)"
  return 0
}
run_test "P0" "ATDD-4.3-06" "Makefile 'debug-check' phony target present + opt-in (AC-6/7, NFR-5; *** RED DRIVER *** — absent at 23696b0)" test_makefile_debug_check_target

# ==========================================
# P1 — AC-6, TC-E4-24: NFR-5 6-warning watch-list present (cls debug section OR Makefile debug-check)
# ==========================================
echo "=== P1: NFR-5 6-warning watch-list configured (AC-6, TC-E4-24, NFR-5) ==="

# ATDD-4.3-07: the 6 NFR-5 LaTeX warning signatures must appear in a watch-list — either the cls \ifhtu@debug debug
#   section OR the Makefile debug-check target (single source of truth either way). The 6 (per NFR-5 + Story 4.3 Dev
#   Notes §nfr5-warnings-as-errors-design): overfull hbox, geometry overspec, fancyhdr headheight, natbib undefined
#   citation, hyperref token, caption option reset. Pre-impl (23696b0): none of these in a watch-list context.
#   RED pre: <6 of the signatures present.
test_nfr5_watchlist() {
  python - <<'PY'
import re, sys
# gather the watch-list corpus: cls \htucheck debug region + Makefile debug-check region
corpus = []
for path in ("htuthesis.cls", "Makefile"):
    try:
        corpus.append((path, open(path, encoding="utf-8").read()))
    except OSError:
        pass
# the 6 NFR-5 signatures (loose but anchored to each warning class — avoids bare 'Warning' false-match)
sigs = {
    "overfull hbox":      r'Overfull\s+\\hbox',
    "geometry overspec":  r'(geometry|Gm@warning).{0,40}(Over-specification|overspec)',
    "fancyhdr headheight":r'(fancyhdr|headheight).{0,40}(too low|headheight\s+is)',
    "natbib undefined":   r'(natbib|biblatex).{0,40}(undefined|Citation)',
    "hyperref token":     r'(hyperref|Token).{0,40}(not allowed|PDF string)',
    "caption option":     r'caption.{0,40}(option|reset|Warning)',
}
joined = "\n".join(c for _, c in corpus)
found = [name for name, pat in sigs.items() if re.search(pat, joined, re.I)]
missing = [name for name in sigs if name not in found]
print("  NFR-5 signatures found: %d/6 (%s)" % (len(found), found))
if missing:
    print("  MISSING: %s — RED" % missing)
sys.exit(0 if not missing else 1)
PY
}
run_test "P1" "ATDD-4.3-07" "NFR-5 6-warning watch-list configured in cls/Makefile (AC-6, TC-E4-24; *** RED DRIVER *** — absent at 23696b0)" test_nfr5_watchlist

# ==========================================
# GREEN guard — AC-8: 4.2 self-check sections (font/coverage/audit) PRESERVED in \htucheck body (regression guard)
# ==========================================
echo "=== GREEN guard: 4.2 sections (font/coverage/audit) preserved in \\htucheck body (AC-8) ==="

# ATDD-4.3-08: the \htucheck body must STILL contain the 4.2 self-check sections — font-check, coverage map, assertion
#   audit. 4.3 adds a \ifhtu@debug-gated debug section but MUST NOT move the 4.2 sections behind [debug] (AC-8: default
#   compile output unchanged; Story 4.2 ATDDs I02/I06/I07 grep these on a default compile). GREEN pre+post (4.2 shipped
#   them; 4.3 must preserve). RED = 4.3 gated/removed a 4.2 section.
test_htucheck_preserves_42_sections() {
  local body
  body=$(htucheck_body) || return 1
  [[ "$body" == "NO_HTUCHECK_DEF" || "$body" == "UNTERMINATED" ]] && { echo "  (\\htucheck def not found — RED)"; return 1; }
  echo "$body" | grep -qiE 'font[ _-]?check|--- font' || { echo "  (font-check section missing — RED, 4.2 regression)"; return 1; }
  echo "$body" | grep -qiE 'coverage|silent[ _-]?fail' || { echo "  (coverage-map section missing — RED, 4.2 regression)"; return 1; }
  echo "$body" | grep -qiE 'assertion[ _-]?audit|proxied' || { echo "  (assertion-audit section missing — RED, 4.2 regression)"; return 1; }
  # markers + name=value prefix preserved (Epic 2-3 ATDD greps + 4.4 checklist depend)
  echo "$body" | grep -qF '=== HTU Layout Self-Check ===' || { echo "  (start marker missing — RED)"; return 1; }
  echo "$body" | grep -qF '=== End Self-Check ===' || { echo "  (end marker missing — RED)"; return 1; }
  echo "  (4.2 sections + markers preserved in \\htucheck body — GREEN)"
  return 0
}
run_test "P1" "ATDD-4.3-08" "4.2 self-check sections (font/coverage/audit + markers) preserved (AC-8; GREEN guard pre+post — [debug] gating must not move 4.2 sections)" test_htucheck_preserves_42_sections

# ==========================================
# GREEN guard — font \PackageError gates cls:71-88 RETAINED (4.3 must not touch)
# ==========================================
echo "=== GREEN guard: font \\PackageError gates cls:71-88 retained (AC-3, NFR-2) ==="

# ATDD-4.3-09: the 5 font \IfFontExistsTF{}{\PackageError{htuthesis}} gates at cls:71-88 MUST remain (4.3 adds no font
#   logic; must not touch these). GREEN pre+post. RED = 4.3 accidentally removed/duplicated the font gates.
#   (Reused verbatim from 4.2 unit-07 — 4.3 inherits the same font-gate regression surface.)
test_font_error_gates_retained() {
  [[ -f "htuthesis.cls" ]] || return 1
  python - <<'PY'
import re, sys
src = open("htuthesis.cls", encoding="utf-8").read()
fonts = ["SimSun", "SimHei", "KaiTi", "FangSong", "Times New Roman"]
missing = []
for f in fonts:
    pat = r'\\IfFontExistsTF\{' + re.escape(f) + r'\}.*?\\PackageError\{htuthesis\}'
    if not re.search(pat, src, re.DOTALL):
        missing.append(f)
print("  font \\PackageError gates present for: %s" % ([f for f in fonts if f not in missing]))
if missing:
    print("  MISSING gate for: %s — RED" % missing)
sys.exit(0 if not missing else 1)
PY
}
run_test "P1" "ATDD-4.3-09" "font \\PackageError gates cls:71-88 retained (AC-3; GREEN guard pre+post — 4.3 must not touch)" test_font_error_gates_retained

echo ""
echo "=============================================="
echo "Summary: PASS=$PASS FAIL=$FAIL SKIP=$SKIP_COUNT"
echo "=============================================="
if [[ "$SKIP" == "1" ]]; then
  echo ""
  echo "   TDD RED phase — scaffolds inert (ATDD_SKIP=1). Activate with --run or ATDD_SKIP=0."
  echo "   RED drivers (FAIL pre-impl 23696b0, PASS post-impl debug+calibrate):"
  echo "      01 [debug] option + \\ifhtu@debug switch (AC-1, architecture §342)"
  echo "      02 \\htucheck \\ifhtu@debug-gated debug-diagnostics section (AC-1/2, §449-452)"
  echo "      03 tools/calibrate.tex exists + standalone + tikz (AC-3/4, TC-E4-20)"
  echo "      04 calibrate.tex uses \\InputIfFileExists (AC-5, TC-E4-22)"
  echo "      05 Makefile 'calibrate' phony target (AC-7)"
  echo "      06 Makefile 'debug-check' phony target (AC-6/7, NFR-5)"
  echo "      07 NFR-5 6-warning watch-list configured (AC-6, TC-E4-24)"
  echo "   GREEN guards (PASS pre+post):"
  echo "      08 4.2 self-check sections (font/coverage/audit + markers) preserved (AC-8 — [debug] gating additive)"
  echo "      09 font \\PackageError gates cls:71-88 retained (AC-3 — 4.3 must not touch)"
  echo ""
  echo "   Source greps prove WIRING; integration proves MECHANISM (.log debug section, calibrate.pdf, make debug-check)."
  echo "   AC-8 is the linchpin: [debug] ADDS verbose output; it does NOT SUPPRESS the 4.2 baseline (22 ATDD consumers"
  echo "      + Story 4.2 I02/I06/I07 depend on the default-compile self-check). unit-08 + integration I02 enforce it."
  echo "   Tests are read-only (no SUT mutation — Epic 1 retro). Line refs verified vs HEAD 23696b0."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
