#!/usr/bin/env bash
# test-story-4.2-unit.sh — ATDD Unit (source-level) Tests for Story 4.2 (full self-check infrastructure)
# TDD Phase: RED — the RED driver cluster is unit-01 (self-check WARNING tier \PackageWarning — cls:1048-1059
#             \htucheck has ZERO \PackageWarning calls at baseline 12a7445), unit-02 (self-check ERROR structural tier
#             — no \PackageError inside \htucheck/\AtEndDocument self-check region; evensidemargin-twoside + empty-title
#             guards absent), unit-03 (font-check block — no per-font found/missing section), unit-04 (14-item silent-
#             failure coverage map — absent), unit-05 (wrong-target-AC assertion-audit meta-line — absent, Epic 3 retro
#             action item #3). Post-impl (tiered WARNING/ERROR + font block + coverage map + audit): all 5 closed at
#             source. GREEN guards unit-06 (=== markers + name=value prefix PRESERVED — Epic 2-3 ATDD greps depend on
#             them, AC-8 regression guard), unit-07 (font \PackageError gates cls:71-88 RETAINED — 4.2 verifies not
#             rebuilds, Task 3.1), unit-08 (no silent-guard {} swallowing the self-check ERROR — TC-E4-18, R-24).
#
# Usage: bash tests/test-story-4.2-unit.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 (unit-01 WARNING tier + unit-02 ERROR tier + unit-03 font block + unit-04 coverage map — the four
#           self-check pillars) / P1 (unit-05 audit + GREEN guards unit-06/07/08)
# Linked ACs: AC-1 (structured report), AC-2 (WARNING tier), AC-3 (ERROR tier), AC-5 (font block), AC-6 (14 coverage),
#             AC-7 (assertion audit), AC-8 (no regression — markers/prefix/font-gates preserved)
# Linked Risk: R-24 (ERROR-halt mechanism — unit-02/07/08), R-25 (wrong-target-AC — unit-05 audit)
# TC coverage: TC-E4-16 (font block — unit-03), TC-E4-17 (assertion audit — unit-05), TC-E4-18 (no silent-guard — unit-08)
#
# NOTE: these source-greps prove the SELF-CHECK SOURCE STATE (tiers wired, font block present, coverage mapped, audit
#   emitted); the integration tests (test-story-4.2-integration.sh) prove the COMPILED BEHAVIOR (.log output, inject-
#   tests WARNING-non-fatal + ERROR-halt). The wrong-target-AC discipline (Epic 3 retro Lesson 3) lives at the audit
#   layer (unit-05): the self-check MUST NOT assert a rendered property via a \the<dim> proxy; rendered items are mapped
#   to fitz ATDDs. Source greps here prove the WIRING; integration inject-tests prove the MECHANISM fires.
#
# Truth source: architecture.md §Self-check WARNING vs ERROR boundary (§345-355) + §enhanced twoside checks (§480) +
#   §扩展静默失败清单 14项 (§155-174); test-design-epic-4.md Appendix §Empirical Evidence (ERROR=\PackageError halts,
#   WARNING=\PackageWarning non-fatal, 2026-06-20 probe). spec PRIORITY (CLAUDE.md Decision 4, corrected 2026-06-17).
#
# Line refs verified vs HEAD 12a7445: \htucheck def = cls:1048-1059 (8 raw \typeout dims, ZERO \PackageWarning/
#   \PackageError); font gates = cls:71-88 (\IfFontExistsTF{<font>}{}{\PackageError{...}} ×5, PRE-EXISTING — 4.2
#   verifies not rebuilds); \AtEndDocument{\htucheck} = cls:1060-1062.

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
    ((PASS++)) || true
  else
    red "[$priority] $test_id: $description"
    ((FAIL++))
  fi
}

echo "=============================================="
echo "ATDD Unit Tests: Story 4.2 — full self-check infrastructure (WARNING/ERROR tiers + 14 coverage)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# Shared helper: extract the \htucheck macro body (cls) — comment-stripped, from \newcommand{\htucheck} to the
#   closing brace of its def. Used by unit-01..05 to scope greps to the self-check region (not the cls font gates).
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
# m matches '\newcommand{\htucheck}' (ends at the '}' closing the NAME arg). The BODY opener is the NEXT '{'
#   after m.end() (skip any optional [N] arg — current \htucheck takes none). m.start() would wrongly land on the
#   name-arg '{' and truncate the body to '{\htucheck}'.
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
# P0 — AC-2: self-check WARNING tier (\PackageWarning) present in \htucheck body
# ==========================================
echo "=== P0: \\htucheck WARNING tier (\\PackageWarning, AC-2, architecture §345-353) ==="

# ATDD-4.2-01: the \htucheck macro body must contain at least one \PackageWarning{htuthesis}{...} call — the non-fatal
#   WARNING tier (margin >1mm drift, baselineskip drift, page count=0, cover≠1, body-first≠1). Pre-impl (12a7445):
#   cls:1048-1059 has ZERO \PackageWarning (only raw \typeout dims). RED pre: no \PackageWarning in body.
#   WARNING=\PackageWarning is the ONLY non-fatal mechanism (exit 0 + pdf YES, test-design-epic-4 Appendix empirical).
test_htucheck_has_warning_tier() {
  local body
  body=$(htucheck_body) || return 1
  [[ "$body" == "NO_HTUCHECK_DEF" || "$body" == "UNTERMINATED" ]] && { echo "  (\\htucheck def not found/unterminated — RED)"; return 1; }
  echo "$body" | grep -qE '\\PackageWarning\b' || { echo "  (no \\PackageWarning in \\htucheck body — RED)"; return 1; }
  # scoped to htuthesis (not a third-party package warning)
  echo "$body" | grep -qE '\\PackageWarning\{htuthesis\}' || { echo "  (\\PackageWarning not scoped to {htuthesis} — RED)"; return 1; }
  echo "  (\\PackageWarning{htuthesis} tier present in \\htucheck — GREEN)"
  return 0
}
run_test "P0" "ATDD-4.2-01" "\\htucheck WARNING tier \\PackageWarning{htuthesis} present (AC-2; *** RED DRIVER *** — zero \\PackageWarning at 12a7445 cls:1048-1059)" test_htucheck_has_warning_tier

# ==========================================
# P0 — AC-3: self-check ERROR structural tier (\PackageError in self-check region OR new structural guards)
# ==========================================
echo "=== P0: self-check ERROR structural tier (\\PackageError, AC-3, architecture §480 + deferred §3.2) ==="

# ATDD-4.2-02: Story 4.2 must ADD structural ERRORs via \PackageError{htuthesis}: (a) evensidemargin unset in twoside
#   (architecture §480 enhanced check), AND/OR (b) empty \ctitle/\etitle guard (deferred-work §3.2). These are NEW
#   (distinct from the pre-existing font gates cls:71-88 which fire at class-load, not in \htucheck). Pre-impl
#   (12a7445): the \htucheck body has ZERO \PackageError; cls has no evensidemargin-twoside or empty-title guard.
#   RED pre: no new structural \PackageError beyond cls:71-88 font gates.
#   Proof target: a \PackageError in the \htucheck body OR a new guard referencing \htu@ctitle/\htu@etitle/evensidemargin.
test_htucheck_has_error_structural_tier() {
  [[ -f "htuthesis.cls" ]] || return 1
  python - <<'PY'
import re, sys
src = open("htuthesis.cls", encoding="utf-8").read()
lines = [ln for ln in src.splitlines() if not ln.lstrip().startswith("%")]
text = "\n".join(lines)
# (a) \PackageError inside \htucheck body
def body_of(marker):
    m = re.search(marker, text)
    if not m: return ""
    # m matches e.g. '\newcommand{\htucheck}' (ends at the '}' closing the NAME arg). The BODY opener is the
    # NEXT '{' after m.end() -- m.start() would land on the name-arg '{' and truncate the body (the same bug
    # htucheck_body fixes). Story 4.2 review patch P3.
    rest = text[m.end():]
    ib = rest.find("{")
    if ib < 0: return ""
    i = m.end() + ib; depth = 0
    for j in range(i, len(text)):
        if text[j] == "{": depth += 1
        elif text[j] == "}":
            depth -= 1
            if depth == 0: return text[i:j+1]
    return ""
hc = body_of(r'\\newcommand\{\\htucheck\}')
err_in_hc = (r"\PackageError" in hc) and ("htuthesis" in hc)
# (b) new structural guards anywhere in cls (evensidemargin-twoside OR empty-title)
structural = bool(re.search(r'\\PackageError\{htuthesis\}[^}]*(evensidemargin|twoside)', text)) or \
             bool(re.search(r'\\PackageError\{htuthesis\}[^}]*(\\htu@ctitle|\\htu@etitle|title)', text, re.I)) or \
             bool(re.search(r'(\\ifx\\htu@ctitle\\empty|\\ifx\\htu@etitle\\empty|\\@empty\\htu@ctitle)', text))
ok = err_in_hc or structural
print("  \\PackageError in \\htucheck body: %s | new structural guard (evensidemargin/title): %s" % (err_in_hc, structural))
sys.exit(0 if ok else 1)
PY
}
run_test "P0" "ATDD-4.2-02" "self-check ERROR structural tier \\PackageError{htuthesis} (AC-3; *** RED DRIVER *** — no new structural ERROR at 12a7445, font gates cls:71-88 are pre-existing not self-check)" test_htucheck_has_error_structural_tier

# ==========================================
# P0 — AC-5: font-check block present in \htucheck (5 fonts found/missing)
# ==========================================
echo "=== P0: \\htucheck font-check block (AC-5, NFR-2, architecture §font block) ==="

# ATDD-4.2-03: the \htucheck body must include a font-check section reporting each of the 5 required fonts (SimSun,
#   SimHei, KaiTi, FangSong, Times New Roman) as found/missing. Pre-impl (12a7445): no font-check block — cls:1048-1059
#   only emits 8 raw dims. RED pre: no 'font check' marker / no per-font found|missing in body.
test_htucheck_has_font_block() {
  local body
  body=$(htucheck_body) || return 1
  [[ "$body" == "NO_HTUCHECK_DEF" || "$body" == "UNTERMINATED" ]] && { echo "  (\\htucheck def not found — RED)"; return 1; }
  # font-check section marker OR per-font found/missing lines
  echo "$body" | grep -qiE 'font[ _-]?check' || {
    # fallback: look for per-font found/missing enumeration
    echo "$body" | grep -qiE '(found|missing)\s*\[?(PASS|ERROR)' || { echo "  (no font-check block — RED)"; return 1; }
  }
  # at least 3 of the 5 font names referenced (tolerant of 3 vs 5 — the block exists; integration I06 asserts all 5)
  local n
  n=$(echo "$body" | grep -ciE 'SimSun|SimHei|KaiTi|FangSong|Times New Roman')
  echo "  (font-check block present; font-name refs in body: $n [expect ≥3])"
  [[ "$n" -ge 3 ]]
}
run_test "P0" "ATDD-4.2-03" "\\htucheck font-check block (AC-5, NFR-2; *** RED DRIVER *** — absent at 12a7445 cls:1048-1059)" test_htucheck_has_font_block

# ==========================================
# P0 — AC-6: 14-item silent-failure coverage map present in \htucheck
# ==========================================
echo "=== P0: \\htucheck 14-item silent-failure coverage map (AC-6, NFR-4, architecture §155-174) ==="

# ATDD-4.2-04: the \htucheck body (or its output) must include a coverage map / section referencing the 14 silent-failure
#   items — each either asserted (compile-time-observable) or mapped to its fitz ATDD (rendered). Pre-impl (12a7445):
#   no coverage map. RED pre: no 'coverage' / 'silent' marker, and <3 ATDD cross-refs in body.
#   The map may be output via \typeout (covered at integration I07) OR a cls comment block — this unit test checks the
#   body+immediate-following comment region for the coverage artifact.
test_htucheck_has_coverage_map() {
  [[ -f "htuthesis.cls" ]] || return 1
  python - <<'PY'
import re, sys
src = open("htuthesis.cls", encoding="utf-8").read()
# scope: \htucheck region + trailing 40 lines (comment block may follow the def)
m = re.search(r'\\newcommand\{\\htucheck\}', src)
if not m:
    print("  (\\htucheck def not found — RED)"); sys.exit(1)
seg = src[m.start(): m.start()+4000]
has_cov = bool(re.search(r'coverage|silent[ _-]?fail|14\s*(item|项|silent)|扩展静默', seg, re.I))
# ATDD cross-references (rendered items mapped to fitz ATDDs) — tolerant: ≥2 refs
refs = len(re.findall(r'ATDD-[\d.]+|TC-E4-\d+|see\s+ATDD|rendered', seg, re.I))
print("  coverage marker: %s | ATDD/rendered refs in \\htucheck region: %s [expect ≥2]" % (has_cov, refs))
sys.exit(0 if (has_cov or refs >= 2) else 1)
PY
}
run_test "P0" "ATDD-4.2-04" "\\htucheck 14-item coverage map (AC-6, NFR-4; *** RED DRIVER *** — absent at 12a7445)" test_htucheck_has_coverage_map

# ==========================================
# P1 — AC-7: wrong-target-AC assertion-audit meta-line (Epic 3 retro action item #3, R-25)
# ==========================================
echo "=== P1: \\htucheck assertion-audit meta-line (AC-7, R-25, Epic 3 retro action #3) ==="

# ATDD-4.2-05: the \htucheck output must include an assertion-audit meta-line flagging which assertions are PROXIED
#   (read an internal \the<dim> for a spec-rendered property) vs rendered-direct. This is the codification of Epic 3
#   retro Lesson 3 / action item #3 at the self-check layer (R-25: a green self-check ≠ spec compliance for rendered
#   properties). Pre-impl (12a7445): no audit line. RED pre: no 'audit'/'proxied' marker.
test_htucheck_has_assertion_audit() {
  [[ -f "htuthesis.cls" ]] || return 1
  python - <<'PY'
import re, sys
src = open("htuthesis.cls", encoding="utf-8")
text = src.read()
m = re.search(r'\\newcommand\{\\htucheck\}', text)
if not m:
    print("  (\\htucheck def not found — RED)"); sys.exit(1)
seg = text[m.start(): m.start()+4000]
has = bool(re.search(r'assertion[ _-]?audit|proxied|rendered[ _-]?guard|wrong[ _-]?target', seg, re.I))
print("  assertion-audit / proxied marker in \\htucheck region: %s" % has)
sys.exit(0 if has else 1)
PY
}
run_test "P1" "ATDD-4.2-05" "\\htucheck assertion-audit meta-line (AC-7, R-25; *** RED DRIVER *** — absent at 12a7445, Epic 3 retro action #3)" test_htucheck_has_assertion_audit

# ==========================================
# GREEN guard — AC-8: === markers + name=value prefix PRESERVED (Epic 2-3 ATDD greps depend on them)
# ==========================================
echo "=== GREEN guard: === markers + name=value prefix preserved (AC-8, regression guard) ==="

# ATDD-4.2-06: the \htucheck body must STILL emit '=== HTU Layout Self-Check ===' / '=== End Self-Check ===' markers AND
#   the raw 'name = \the<dim>' lines (textheight/baselineskip/etc.) — these are depended on by Epic 2-3 integration
#   ATDDs (deferred-work §3.5 I12/I13/I14, §3.6 I13/I14/I15) + Story 4.4 checklist traceability. 4.2 appends verdict
#   text but MUST NOT change the prefix. GREEN pre+post (4.1 preserved them; 4.2 must too). RED = 4.2 broke the format.
test_htucheck_markers_and_prefix_preserved() {
  local body
  body=$(htucheck_body) || return 1
  [[ "$body" == "NO_HTUCHECK_DEF" || "$body" == "UNTERMINATED" ]] && { echo "  (\\htucheck def not found — RED)"; return 1; }
  echo "$body" | grep -qF '=== HTU Layout Self-Check ===' || { echo "  (start marker missing — RED)"; return 1; }
  echo "$body" | grep -qF '=== End Self-Check ===' || { echo "  (end marker missing — RED)"; return 1; }
  echo "$body" | grep -qE 'textheight\s*=\s*\\the\\textheight' || { echo "  (textheight = \\the\\textheight prefix missing — RED)"; return 1; }
  echo "$body" | grep -qE 'baselineskip\s*=\s*\\the\\baselineskip' || { echo "  (baselineskip prefix missing — RED)"; return 1; }
  echo "  (markers + name=value prefixes preserved — GREEN)"
  return 0
}
run_test "P1" "ATDD-4.2-06" "=== markers + name=value prefix preserved (AC-8; GREEN guard pre+post — Epic 2-3 ATDD greps + 4.4 checklist depend on them)" test_htucheck_markers_and_prefix_preserved

# ==========================================
# GREEN guard — AC-3: font \PackageError gates cls:71-88 RETAINED (4.2 verifies not rebuilds, Task 3.1)
# ==========================================
echo "=== GREEN guard: font \\PackageError gates cls:71-88 retained (AC-3, Task 3.1, NFR-2) ==="

# ATDD-4.2-07: the 5 font \IfFontExistsTF{}{\PackageError{htuthesis}} gates at cls:71-88 MUST remain (4.2 verifies +
#   documents them, does NOT rebuild — Story 4.2 Dev Notes §font-gate-already-exists). GREEN pre+post. RED = 4.2
#   accidentally removed/duplicated the font gates.
test_font_error_gates_retained() {
  [[ -f "htuthesis.cls" ]] || return 1
  python - <<'PY'
import re, sys
src = open("htuthesis.cls", encoding="utf-8").read()
fonts = ["SimSun", "SimHei", "KaiTi", "FangSong", "Times New Roman"]
missing = []
for f in fonts:
    # \IfFontExistsTF{<font>} ... \PackageError{htuthesis}  (gate present)
    pat = r'\\IfFontExistsTF\{' + re.escape(f) + r'\}.*?\\PackageError\{htuthesis\}'
    if not re.search(pat, src, re.DOTALL):
        missing.append(f)
print("  font \\PackageError gates present for: %s" % ([f for f in fonts if f not in missing]))
if missing:
    print("  MISSING gate for: %s — RED" % missing)
sys.exit(0 if not missing else 1)
PY
}
run_test "P1" "ATDD-4.2-07" "font \\PackageError gates cls:71-88 retained (AC-3, Task 3.1; GREEN guard pre+post — 4.2 verifies not rebuilds)" test_font_error_gates_retained

# ==========================================
# GREEN guard — TC-E4-18 / R-24: no silent-guard {} swallowing the self-check \PackageError
# ==========================================
echo "=== GREEN guard: no silent-guard {} swallowing self-check ERROR (TC-E4-18, R-24) ==="

# ATDD-4.2-08: IF the self-check region emits a \PackageError{htuthesis}, it must NOT be wrapped in an empty false-
#   branch {} that would swallow it (the §3.9 \IfFontExistsTF{}{} silent-skip pattern — the real §3.9 failure was an
#   empty false-branch firing NO error). Pre-impl (12a7445): no self-check \PackageError → vacuously PASS (nothing to
#   guard). Post-impl: \PackageError present + not inside \IfX..{}{<empty>} → PASS. GREEN guard both phases.
#   This is the source-grep half of TC-E4-18 (integration I04 is the inject proof the path fires).
test_no_silent_guard_swallows_error() {
  [[ -f "htuthesis.cls" ]] || return 1
  python - <<'PY'
import re, sys
src = open("htuthesis.cls", encoding="utf-8").read()
lines = [ln for ln in src.splitlines() if not ln.lstrip().startswith("%")]
text = "\n".join(lines)
# Story 4.2 review patch P1: the original first loop here was DEAD CODE -- both `if re.search` branches ended in
#   `pass` and never appended to `violations`, AND distinguishing a silent-guard `{}` from the `\PackageError` help
#   arg `{}` (every \PackageError{htuthesis}{msg}{help} ends with an empty `{}` help arg) is not regex-reliable on
#   TeX. The HONEST check this test can perform: no `\PackageError{htuthesis}` is wrapped in an UNREACHABLE branch
#   (\iffalse / \unlessif / \ifvoid) that would swallow it. The authoritative proof that the ERROR path FIRES is the
#   integration inject-test ATDD-4.2-I04 (forced \PackageError -> rc=12 + no PDF); this unit guard is a narrower
#   source-level backstop only.
violations = []
for m in re.finditer(r'\\PackageError\{htuthesis\}', text):
    window = text[max(0, m.start()-200): m.start()+80]
    # \PackageError unreachable: preceded by \iffalse / \unlessif ... \fi (never fires)
    if re.search(r'\\(iffalse|unlessif)\b', window) and window.find('\\iffalse') < window.find('\\PackageError'):
        violations.append(m.start())
print("  self-check \\PackageError calls: %d | unreachable-swallow violations: %d" % (len(list(re.finditer(r'\\PackageError\{htuthesis\}', text))), len(violations)))
sys.exit(0 if not violations else 1)
PY
}
run_test "P1" "ATDD-4.2-08" "no silent-guard {} swallows self-check \\PackageError (TC-E4-18, R-24; GREEN guard — pre-impl vacuous, post-impl ERROR not guarded)" test_no_silent_guard_swallows_error

echo ""
echo "=============================================="
echo "Summary: PASS=$PASS FAIL=$FAIL SKIP=$SKIP_COUNT"
echo "=============================================="
if [[ "$SKIP" == "1" ]]; then
  echo ""
  echo "   TDD RED phase — scaffolds inert (ATDD_SKIP=1). Activate with --run or ATDD_SKIP=0."
  echo "   RED drivers (FAIL pre-impl 12a7445, PASS post-impl tiered self-check):"
  echo "      01 \\htucheck WARNING tier \\PackageWarning{htuthesis} (AC-2, architecture §345-353)"
  echo "      02 self-check ERROR structural tier \\PackageError (AC-3, evensidemargin-twoside §480 + empty-title §3.2)"
  echo "      03 \\htucheck font-check block 5 fonts (AC-5, NFR-2)"
  echo "      04 \\htucheck 14-item silent-failure coverage map (AC-6, NFR-4, architecture §155-174)"
  echo "      05 \\htucheck assertion-audit meta-line (AC-7, R-25, Epic 3 retro action #3)"
  echo "   GREEN guards (PASS pre+post):"
  echo "      06 === markers + name=value prefix preserved (AC-8 — Epic 2-3 ATDD greps + 4.4 checklist depend)"
  echo "      07 font \\PackageError gates cls:71-88 retained (AC-3 Task 3.1 — 4.2 verifies not rebuilds)"
  echo "      08 no silent-guard {} swallows self-check ERROR (TC-E4-18, R-24)"
  echo ""
  echo "   Source greps prove WIRING; integration inject-tests prove MECHANISM (WARNING non-fatal, ERROR halts)."
  echo "   Wrong-target-AC discipline (unit-05 audit): self-check asserts compile-time-observable only; rendered"
  echo "      properties mapped to fitz ATDDs — a green self-check ≠ spec compliance for rendered properties (R-25)."
  echo "   Tests are read-only (no SUT mutation — Epic 1 retro). Line refs verified vs HEAD 12a7445."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
