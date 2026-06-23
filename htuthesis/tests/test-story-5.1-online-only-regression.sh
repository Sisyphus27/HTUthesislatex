#!/usr/bin/env bash
# test-story-5.1-online-only-regression.sh — ATDD Integration Tests for Story 5.1 (Bibliography chapter
#   heading decoupling — NFR-6 / R-31 / R-33)
#
# TDD Phase: RED — the PRIMARY RED drivers are ATDD-5.1-I02/I03/I04. Pre-impl (current cls: the heading is
#   coupled to the type=article section): compiling the online-only fixture (tests/fixtures/refs-online-only.bib —
#   0 @article) → the article section is EMPTY → biblatex skips the heading → the "参考文献" chapter title NEVER
#   renders + NEVER enters main.toc at CHAPTER level (the real-thesis bug). Post-impl (Story 5.1 entry-point
#   \htu@chapter*{\bibname} + all sections htu-refs-sub): the chapter title renders unconditionally.
#
#   This is the C1 closure of the Story 3.12 sample-data-masked blind spot (R-33): the 13-entry representative
#   sample covered all 6 biblatex types so the empty-article path never fired. The fixture (0 @article) forces
#   the failing path. A green test here is robustness evidence, not just "works on the sample".
#
# *** DETECTION CALIBRATION (the subtle trap that caused an initial false-green) ***
#   The bibliography chapter title is 三号 SimHei (cls `\sanhao`=16bp → renders 16.0pt; band [15.5, 16.5]).
#   Body SECTION headings (e.g. chap03 "第六节 参考文献", "创建参考文献") are 小三 SimHei = 15.0pt. A naive band
#   [15.0, 17.0] catches the chap03 section headings → FALSE GREEN (test passes pre-fix). The band MUST be
#   [15.5, 16.5] to isolate 三号 (16.0) and exclude 小三 (15.0). Likewise the main.toc check must require a CHAPTER-level entry
#   (\contentsline {chapter}) — chap03's section produces a \contentsline {section} that a naive '参考文献' grep
#   would match. Do NOT widen the band or loosen the toc grep without re-verifying the RED phase on the pre-fix cls.
#
# Usage:
#   bash tests/test-story-5.1-online-only-regression.sh [--run] [--inject]
#     --run     Remove SKIP marker (activate; green-phase verification). Default ATDD_SKIP=1 = RED scaffold inert.
#     --inject  (opt-in, implies --run) ALSO run the TC-E5-05 RED-on-pre-fix proof: temp-tree copy with the
#               entry-point reverted → recompile → assert 0 "参考文献" hits. Heavy (~1 extra compile); use to
#               reproduce the pre-fix RED state AFTER the fix is committed. SUT is never modified (temp copy).
#
# Priority: P0 (the C1 blind-spot closure) + P1 (title font + warning gate)
# Linked ACs: AC-1 (online-only fixture → 参考文献 renders), AC-2 (chapter-level entry in main.toc),
#             AC-3 (span count = exactly 1), AC-5 (C1 RED-on-pre-fix / GREEN-on-post-fix), AC-7 (compile gate),
#             AC-11 (empty-section warnings), AC-12 (bash -n clean)
# Linked Risk: R-31 (system-level, score 6 — this test IS its mitigation), R-32 (span count = 1, no double-title),
#              R-33 (score 6 — the meta-testing risk; the degenerate fixture), R-34 (empty-section warning gate)
# TC coverage: TC-E5-01 (I02), TC-E5-02 (I03), TC-E5-03 (I04), TC-E5-05 (--inject I06), TC-E5-08 (I05),
#              TC-E5-10 (I07). TC-E5-06/07 (C2 regression + F2 Latin) = existing Story 3.7/3.12/3.13 suites
#              on the canonical 13-entry sample; TC-E5-09 = full Epic 1–4 regression (gate); TC-E5-22 = dual-dir diff.
#
# SUT PROTECTION (Epic 4 retro Lesson: tests must NOT modify the SUT; use temp copies):
#   - The fixture compile SWAPS ref/refs.bib → fixture, then RESTORES via trap (guaranteed even on error).
#   - The --inject proof copies the WHOLE tree to a temp dir (mktemp -d); the live cls/refs.bib are never edited.
#   - fitz reads main.pdf read-only; greps read main.toc/main.log read-only.
#
# Truth source: NFR-6 (参考文献 chapter + TOC entry SHALL render regardless of refs.bib type distribution) +
#   architecture.md:123-127 (§参考文献章标题与分节数据分布解耦) + :179 (silent-failure #15). spec §2.14 PRIORITY.
#   See Story 5.1 spec + _bmad-output/problem-solution-2026-06-22.md (the real-thesis reproduction).

set -uo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DIR"

# --- TDD Red Phase Control ---
SKIP="${ATDD_SKIP:-1}"
INJECT=0
for arg in "$@"; do
  case "$arg" in
    --run) SKIP=0 ;;
    --inject) SKIP=0; INJECT=1 ;;
  esac
done

PASS=0
FAIL=0
SKIP_COUNT=0

green()  { printf "\033[32m  [PASS] %s\033[0m\n" "$1"; }
red()    { printf "\033[31m  [FAIL] %s\033[0m\n" "$1"; }
yellow() { printf "\033[33m  [SKIP] %s\033[0m\n" "$1"; }

run_test() {
  local priority="$1" test_id="$2" description="$3"
  if [[ "$SKIP" == "1" ]]; then
    yellow "[$priority] $test_id: $description"
    ((SKIP_COUNT++))
    return 0
  fi
  shift 3
  "$@"
  if [[ $? -eq 0 ]]; then green "[$priority] $test_id: $description"; ((PASS++)); else red "[$priority] $test_id: $description"; ((FAIL++)); fi
}

FIXTURE="tests/fixtures/refs-online-only.bib"
REFS_BIB="ref/refs.bib"
REFS_BAK=".atdd-5.1-refs.bak"

# --- Fixture compile harness: swap refs.bib → fixture, latexmk -g (fresh .bbl/.toc), restore on exit. ---
compile_fixture() {
  if [[ ! -f "$FIXTURE" ]]; then
    echo "  [ERROR] fixture $FIXTURE not found (see atdd-checklist-5-1-*.md)" >&2
    return 1
  fi
  cp "$REFS_BIB" "$REFS_BAK"
  cp "$FIXTURE" "$REFS_BIB"
  # R-12: -g forces a fresh biber pass + .aux/.bbl/.bcf/.toc regeneration (heading-mechanism change needs a fresh TOC).
  latexmk -xelatex -file-line-error -halt-on-error -interaction=nonstopmode -g main >/tmp/atdd-5.1-compile.log 2>&1
  return $?
}

restore_refs() {
  if [[ -f "$REFS_BAK" ]]; then
    cp "$REFS_BAK" "$REFS_BIB"
    rm -f "$REFS_BAK"
  fi
}
trap restore_refs EXIT

echo "=============================================="
echo "ATDD Integration Tests: Story 5.1 — Bibliography chapter heading decoupling (online-only fixture, NFR-6)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped — run with --run post-impl)" || echo "ACTIVE")   Inject: $([ "$INJECT" == "1" ] && echo "ON (--inject)" || echo "off")"
echo "=============================================="
echo ""

# Compile the fixture ONCE (shared by I01-I07). Skipped entirely in RED-scaffold mode.
COMPILE_OK=0
if [[ "$SKIP" != "1" ]]; then
  echo "  [setup] compiling online-only fixture (latexmk -xelatex -g) — ~3 min..."
  if compile_fixture; then
    COMPILE_OK=1
    echo "  [setup] fixture compiled → main.pdf + main.toc + main.bbl regenerated"
  else
    echo "  [setup] FAILED: online-only fixture did not compile (see /tmp/atdd-5.1-compile.log)" >&2
    COMPILE_OK=0
  fi
fi

# ---------------------------------------------------------------------------
# ATDD-5.1-I01 (P0, gate, AC-7): online-only fixture compiles exit 0 (NFR-1).
#   Pre-impl AND post-impl the fixture compiles (the bug is a RENDERING gap, not a compile error) — GREEN guard.
test_i01_compile_ok() {
  [[ "$COMPILE_OK" == "1" ]]
}

# ATDD-5.1-I02 (P0, *** RED DRIVER ***, TC-E5-01, AC-1, R-31/R-33): "参考文献" CHAPTER TITLE renders — ≥1 SimHei
#   三号 span. Band [15.5, 16.5] isolates 三号 (ctex 15.75pt) and EXCLUDES 小三 (15.0pt) body section headings
#   (chap03 "第六节 参考文献") — see DETECTION CALIBRATION above. Pre-impl: 0 (chapter vanished) → RED. Post: ≥1 → GREEN.
test_i02_refs_renders() {
  [[ "$COMPILE_OK" == "1" ]] || return 1
  python - <<'PYEOF'
import fitz, sys
doc = fitz.open("main.pdf")
hits = 0
for page in doc:
    for block in page.get_text("dict")["blocks"]:
        for line in block.get("lines", []):
            for sp in line["spans"]:
                t = sp.get("text", ""); f = sp.get("font", ""); s = sp.get("size", 0.0)
                if "参考文献" in t and "Hei" in f and 15.5 <= s <= 16.5:
                    hits += 1
sys.exit(0 if hits >= 1 else 1)
PYEOF
}

# ATDD-5.1-I03 (P0, *** RED DRIVER ***, TC-E5-02, AC-2, R-31): "参考文献" enters main.toc at CHAPTER level.
#   Requires \contentsline {chapter} (NOT \contentsline {section}, which chap03's "第六节 参考文献" produces).
#   Pre-impl: the chapter never entered the TOC (heading skipped) → RED. Post-impl: \addcontentsline{toc}{chapter} → GREEN.
test_i03_refs_chapter_in_toc() {
  [[ "$COMPILE_OK" == "1" ]] || return 1
  [[ -f main.toc ]] || return 1
  # Chapter-level entry only — excludes chap03's section-level \contentsline {section}.
  grep -E '\\contentsline \{chapter\}' main.toc | grep -q '参考文献'
}

# ATDD-5.1-I04 (P0, *** RED DRIVER ***, TC-E5-03, AC-3, R-32): "参考文献" chapter-title span count = EXACTLY 1
#   (no double-title from entry-point emit + residual htu-refs heading). Same SimHei [15.5, 16.5] band as I02.
#   Pre-impl: 0 (≠1) → RED. Post-impl: 1 → GREEN. A post-impl regression emitting the title twice → 2 (≠1) → RED.
test_i04_refs_count_one() {
  [[ "$COMPILE_OK" == "1" ]] || return 1
  local n
  n=$(python - <<'PYEOF'
import fitz
doc = fitz.open("main.pdf")
hits = 0
for page in doc:
    for block in page.get_text("dict")["blocks"]:
        for line in block.get("lines", []):
            for sp in line["spans"]:
                t = sp.get("text", ""); f = sp.get("font", ""); s = sp.get("size", 0.0)
                if "参考文献" in t and "Hei" in f and 15.5 <= s <= 16.5:
                    hits += 1
print(hits)
PYEOF
)
  [[ "$n" == "1" ]]
}

# ATDD-5.1-I05 (P1, TC-E5-08, R-31): the rendered "参考文献" title is SimHei 三号 (FR-20 / spec §2.14). Verifies the
#   entry-point \htu@chapter*{\bibname} inherits the 三号黑体 chapter format (cls:500), not a font regression.
#   GREEN guard post-impl (the title is correct by \htu@chapter* semantics; this confirms it).
test_i05_title_font_sanhao_heiti() {
  [[ "$COMPILE_OK" == "1" ]] || return 1
  python - <<'PYEOF'
import fitz, sys
doc = fitz.open("main.pdf")
for page in doc:
    for block in page.get_text("dict")["blocks"]:
        for line in block.get("lines", []):
            for sp in line["spans"]:
                t = sp.get("text", ""); f = sp.get("font", ""); s = sp.get("size", 0.0)
                if t.strip() == "参考文献" and "Hei" in f and 15.5 <= s <= 16.5:
                    sys.exit(0)
sys.exit(1)
PYEOF
}

# ATDD-5.1-I07 (P1, TC-E5-10, AC-11, R-34): empty-section warning gate. The fixture leaves the article section
#   empty → biblatex "Empty bibliography" warning. NFR-1 ≤3-warning gate holds IF Story 5.1 suppresses empty
#   sections (Task 2.4 option a, RECOMMENDED). If the dev chose option (b) re-baseline+document, REPOINT this
#   assertion (Decision 2) with a traceability note + raise the threshold.
test_i07_warning_gate() {
  [[ "$COMPILE_OK" == "1" ]] || return 1
  [[ -f main.log ]] || return 1
  local w
  w=$(grep -cE 'Empty bibliography' main.log 2>/dev/null || true)
  printf "    (main.log warning count = %s)\n" "$w" >&2
  [[ "$w" -le 3 ]]
}

echo "--- green-phase assertions (I02-I04 are the RED drivers; I01/I05/I07 are guards) ---"
run_test P0 ATDD-5.1-I01 "online-only fixture compiles exit 0 (AC-7, NFR-1 gate)" test_i01_compile_ok
run_test P0 ATDD-5.1-I02 "参考文献 chapter title renders (≥1 SimHei 三号 span, TC-E5-01, RED driver)" test_i02_refs_renders
run_test P0 ATDD-5.1-I03 "参考文献 as chapter-level entry in main.toc (TC-E5-02, RED driver)" test_i03_refs_chapter_in_toc
run_test P0 ATDD-5.1-I04 "参考文献 chapter-title span count = exactly 1 (TC-E5-03, RED driver)" test_i04_refs_count_one
run_test P1 ATDD-5.1-I05 "参考文献 title = SimHei 三号 (TC-E5-08, GREEN guard)" test_i05_title_font_sanhao_heiti
run_test P1 ATDD-5.1-I07 "empty-section warning count ≤3 (TC-E5-10, R-34 — suppress path; repoint if re-baseline)" test_i07_warning_gate

# ---------------------------------------------------------------------------
# TC-E5-05 (P0, AC-5, R-33) — RED-on-pre-fix proof (opt-in --inject).
#   Reproduces the pre-fix failing state on a TEMP-TREE COPY (live SUT untouched): copy the htuthesis tree,
#   swap the fixture, REMOVE the entry-point from the temp cls (python — precise: only the \makebibliography
#   emit, not the \defbibheading{htu-refs} def), recompile, assert 0 "参考文献" hits (RED). Proves the fixture
#   exercises the failing path (not another representative sample).
if [[ "$INJECT" == "1" ]]; then
  echo ""
  echo "--- TC-E5-05 RED-on-pre-fix proof (--inject; temp-tree copy, SUT untouched) ---"

  test_i06_inject_red_on_prefix() {
    local tmpbuild; tmpbuild="$(mktemp -d)"
    mkdir -p "$tmpbuild"
    cp -r . "$tmpbuild"/ >/dev/null 2>&1
    cp "$FIXTURE" "$tmpbuild/$REFS_BIB"
    # Remove the entry-point from the TEMP cls only (revert the decouple). Python is precise where sed is
    # brittle (R-26): drop the first \htu@chapter*{\bibname} occurrence inside \makebibliography (NOT the def).
    python - "$tmpbuild/htuthesis.cls" <<'PYEOF'
import sys
p = sys.argv[1]
src = open(p, encoding="utf-8").read().splitlines(keepends=True)
out = []; in_makebib = False; removed = False
for ln in src:
    # Plain string `in` checks (NOT regex) — avoids re.error bad-escape on Python 3.12+ (code review 2026-06-23 P1).
    if '\\newcommand' in ln and '\\makebibliography' in ln:
        in_makebib = True
    # Skip % comment lines — the [基础] comment block mentions \htu@chapter*{\bibname} in PROSE; without this
    # guard the `in` match hits the comment line (which precedes the command) and removes the WRONG line,
    # leaving the real entry-point intact (code review 2026-06-23 P1-followup).
    if (in_makebib and not removed
            and '\\htu@chapter*{\\bibname}' in ln
            and '\\defbibheading' not in ln
            and not ln.lstrip().startswith('%')):
        removed = True; continue
    out.append(ln)
open(p, "w", encoding="utf-8").write("".join(out))
sys.exit(0 if removed else 2)
PYEOF
    local pyrc=$?
    if [[ $pyrc -ne 0 ]]; then
      rm -rf "$tmpbuild"
      echo "    [inject] could not locate entry-point to revert (rc=$pyrc) — inject misconfigured" >&2
      return 1
    fi
    ( cd "$tmpbuild" && latexmk -xelatex -file-line-error -halt-on-error -interaction=nonstopmode -g main >/dev/null 2>&1 )
    local hits
    hits=$(python - "$tmpbuild/main.pdf" <<'PYEOF'
import fitz, sys
try:
    doc = fitz.open(sys.argv[1])
except Exception:
    print(-1); sys.exit(0)
h = 0
for page in doc:
    for block in page.get_text("dict")["blocks"]:
        for line in block.get("lines", []):
            for sp in line["spans"]:
                t = sp.get("text",""); f = sp.get("font",""); s = sp.get("size",0.0)
                if "参考文献" in t and "Hei" in f and 15.5 <= s <= 16.5:
                    h += 1
print(h)
PYEOF
)
    rm -rf "$tmpbuild"
    [[ "$hits" == "0" ]]
  }

  run_test P0 ATDD-5.1-I06 "TC-E5-05 RED-on-pre-fix: reverted entry-point → 0 参考文献 hits (temp-tree, SUT untouched)" test_i06_inject_red_on_prefix
fi

echo ""
echo "=============================="
printf "Total: \033[32m%d PASS\033[0m  \033[31m%d FAIL\033[0m  \033[33m%d SKIP\033[0m\n" "$PASS" "$FAIL" "$SKIP_COUNT"
echo "=============================="

[[ "$SKIP" == "1" ]] && exit 0
[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
