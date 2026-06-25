#!/usr/bin/env bash
# test-story-6.2-footnote-atomicity.sh — ATDD Integration Tests for Story 6.2
#   (Footnote atomicity M1 + URL/DOI line-break xurl / NFR-7 / FR-24 refined / R-43 / R-44)
#
# TDD Phase: RED — the PRIMARY RED driver is ATDD-6.2-I02 (the runtime \interfootnotelinepenalty value).
#   Pre-impl (current canonical cls: NO M1): the fixture's PENALTYVALUE= marker prints the LaTeX/footmisc
#   default 100 (splits allowed under pressure — the Bug 2 condition). Post-impl (Story 6.2 M1): the cls
#   sets \interfootnotelinepenalty=10000 AFTER footmisc → the marker prints 10000 (atomicity enforced).
#   This penalty-value probe is the RELIABLE behavioral RED: it distinguishes pre/post-fix REGARDLESS of
#   page content, decoupled from the content-density-dependent split reproduction (R-43).
#
#   Why penalty-value (not orphan-split) as the PRIMARY RED: at the default penalty=100, LaTeX's page
#   builder STRONGLY prefers whole-footnote placement; a minimal standalone fixture cannot reliably
#   reproduce the v1.1.1 p19|p20 split (empirically verified 2026-06-24: even 3 consecutive long footnotes
#   fit whole on one page). The split manifests in DENSE real-thesis content. The penalty-value probe
#   directly proves M1's RUNTIME mechanism (and that M1 is placed AFTER footmisc — a wrong placement yields
#   100 even post-fix). The orphan-split test (I06) ships as a post-fix regression guard (R-43-calibration-
#   dependent; GREEN pre AND post in the minimal fixture).
#
# Usage:
#   bash tests/test-story-6.2-footnote-atomicity.sh [--run] [--inject]
#     --run     Remove SKIP marker (activate; green-phase verification). Default ATDD_SKIP=1 = RED scaffold inert.
#     --inject  (opt-in, implies --run) ALSO run the ATDD-6.2-I07 RED-on-pre-fix proof: temp-tree copy with
#               the M1 line removed → recompile fixture → assert PENALTYVALUE reverts to 100 (reliable) +
#               report any orphan split. Heavy (~1 extra compile). SUT never modified.
#
# Priority: P0 (I02 penalty-value RED driver [PRIMARY reliable] + I07 inject proof + I01 compile gate
#           + I03 perpage reset + I04 [N] marker + I06 orphan-atomicity GUARD) + P1 (I05 xurl harmless)
# NOTE: I06 is a POST-FIX REGRESSION GUARD, NOT a RED driver. The fixture's early short footnote (required
#   for I03 perpage ≥2 reset) shifts pagination such that the 3 clustered long footnotes no longer split even
#   pre-fix (R-43: minimal-fixture split reproduction is incompatible with the I03≥2 perpage-spread requirement).
#   I02 (penalty=10000) is the PRIMARY reliable RED — content-independent, always discriminates pre/post.
#   I06 asserts orphan=0 post-fix (no spurious orphan); it does NOT reproduce the Bug-2 split in this fixture.
# Linked ACs: AC-1/I02 (M1 sets penalty=10000), AC-2/I03 (perpage reset), AC-3/I04 ([N] marker),
#             AC-4/I05 (xurl cosmetic), AC-6/I06 (atomicity guard), AC-9/I07 (C1 RED-on-pre-fix), AC-7/I01 (compile gate)
# Linked Risk: R-43 (score 4 — M1 footnote atomicity; I02 penalty-value is the reliable mitigation proof),
#              R-44 (score 4 — xurl; I05)
# TC coverage: TC-E6-09 (I02 penalty-value + I06 orphan guard), TC-E6-10 (I03), TC-E6-11 (I04), TC-E6-12 (I05),
#              TC-E6-22 (I06), TC-E6-14 (I07). TC-E6-13 (xurl order) = unit U02; TC-E6-18/19/20 = gate.
#
# SUT PROTECTION (Epic 4 retro Lesson: tests must NOT modify the SUT; use temp copies):
#   - The fixture is copied to the htuthesis/ ROOT (long-doi-footnote.tex) for cls + ref/refs.bib resolution,
#     compiled, and removed via trap (guaranteed even on error). The canonical data/chap01.tex is NEVER touched.
#   - The --inject proof copies the WHOLE htuthesis tree to a temp dir (mktemp -d); the live cls is never edited.
#   - fitz reads long-doi-footnote.pdf read-only; greps read long-doi-footnote.log read-only.
#
# Truth source: spec §2.5 line 197「脚注小五号宋体」(silent on cross-page → mechanism fix, PRIORITY) +
#   architecture.md §脚注原子化 + URL/DOI 换行美化 (Story 6.2, 2026-06-24) + brainstorming-session-2026-06-24-154931.md
#   Bug 2 (penalty default allows split; M1=10000 forbids it; v1.1.1 fitz: p20 [1] ACEMOGLU complete post-M1) +
#   v1.1.1 cls:431-437 (M1) + cls:151-155 (xurl). See Story 6.2 spec.

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
    ((SKIP_COUNT++)) || true
    return 0
  fi
  shift 3
  "$@"
  if [[ $? -eq 0 ]]; then green "[$priority] $test_id: $description"; ((PASS++)) || true; else red "[$priority] $test_id: $description"; ((FAIL++)) || true; fi
}

FIXTURE_SRC="tests/fixtures/long-doi-footnote.tex"
FIXTURE_TEX="long-doi-footnote.tex"          # copied to htuthesis/ root for cls + ref/refs.bib resolution
FIXTURE_PDF="long-doi-footnote.pdf"
FIXTURE_LOG="long-doi-footnote.log"
TMPBUILD=""                                   # global: the --inject temp-tree path (review fix F14 — EXIT-trap coverage)

# --- Fixture compile harness: copy fixture → htuthesis/ root, latexmk -g (fresh), cleanup on exit. ---
cleanup_fixture() {
  # Remove the fixture + its build artifacts from the htuthesis/ root (cls resolution copy). NEVER touch
  # data/chap01.tex or the canonical main.* — the fixture is an additive test artifact only.
  rm -f "$FIXTURE_TEX" "$FIXTURE_PDF" "$FIXTURE_LOG" \
        long-doi-footnote.aux long-doi-footnote.out long-doi-footnote.xdv long-doi-footnote.toc \
        long-doi-footnote.fdb_latexmk long-doi-footnote.fls long-doi-footnote.bbl long-doi-footnote.run.xml 2>/dev/null
  # Also remove the --inject temp tree if one is outstanding (review fix F14): covers the case where the
  # inject latexmk is killed mid-run (Ctrl-C/OOM/timeout) — the explicit rm in test_i07 would be skipped,
  # leaking the temp tree in $TMPDIR. The EXIT trap fires here regardless.
  [[ -n "$TMPBUILD" ]] && rm -rf "$TMPBUILD" 2>/dev/null
}
trap cleanup_fixture EXIT

compile_fixture() {
  if [[ ! -f "$FIXTURE_SRC" ]]; then
    echo "  [ERROR] fixture $FIXTURE_SRC not found (see atdd-checklist-6-2-*.md)" >&2
    return 1
  fi
  cp "$FIXTURE_SRC" "$FIXTURE_TEX"
  # R-12: -g forces a fresh pass (.aux/.bbl regeneration — the footnote mechanism + biblatex need a fresh state).
  latexmk -xelatex -file-line-error -halt-on-error -interaction=nonstopmode -g "$FIXTURE_TEX" >/tmp/atdd-6.2-compile.log 2>&1
  return $?
}

echo "=============================================="
echo "ATDD Integration Tests: Story 6.2 — Footnote atomicity (M1) + URL/DOI line-break (xurl, NFR-7 / FR-24)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped — run with --run post-impl)" || echo "ACTIVE")   Inject: $([ "$INJECT" == "1" ] && echo "ON (--inject)" || echo "off")"
echo "=============================================="
echo ""

# Compile the fixture ONCE (shared by I01-I06). Skipped entirely in RED-scaffold mode.
COMPILE_OK=0
if [[ "$SKIP" != "1" ]]; then
  echo "  [setup] compiling long-doi-footnote (latexmk -xelatex -g) — ~3 min..."
  if compile_fixture; then
    COMPILE_OK=1
    echo "  [setup] fixture compiled → $FIXTURE_PDF"
  else
    echo "  [setup] FAILED: fixture did not compile (see /tmp/atdd-6.2-compile.log)" >&2
    COMPILE_OK=0
  fi
fi

# ---------------------------------------------------------------------------
# Penalty-value probe (PRIMARY). The fixture typesets "PENALTYVALUE=\the\interfootnotelinepenalty ENDVALUE";
# fitz extracts the integer between the markers. This is the runtime penalty value — 100 pre-M1 (default),
# 10000 post-M1. Reliable RED decoupled from content-density (R-43). Heredoc per Epic 4 retro F1.
probe_penalty() {
  local pdf="$1"
  python - "$pdf" <<'PYEOF'
import fitz, sys, re
doc = fitz.open(sys.argv[1])
text = "".join(p.get_text() for p in doc)
m = re.search(r"PENALTYVALUE=\s*(\d+)\s*ENDVALUE", text)
print(f"penalty={m.group(1) if m else 'NA'}")
PYEOF
}

# ---------------------------------------------------------------------------
# Footnote-band probe (SECONDARY — orphan-atomicity guard). For each page, scans the footnote band
# (y ∈ [H*0.62, H*0.96], size 5-9.5, non-Math) for [N] markers + body, reports:
#   orphan        = pages with footnote-band BODY but NO [N] marker (split continuation — R-43-calibration-dependent)
#   reset         = pages whose marker list contains 1 (footmisc perpage reset — §1.2.4 line 109)
#   marker_pages  = pages with ≥1 [N] marker
#   total_markers = count of [N] marker spans across all pages
#   bare          = count of footnote-band bare-digit spans (NO brackets — a Story 5.4 regression signal)
probe_footnotes() {
  local pdf="$1"
  python - "$pdf" <<'PYEOF'
import fitz, sys, re
doc = fitz.open(sys.argv[1])
H = doc[0].rect.height if doc.page_count else 0.0
marker_re = re.compile(r"^\[(\d+)\]")
def band(p):
    out = []
    for b in p.get_text("dict").get("blocks", []):
        if b.get("type", 0) != 0: continue
        for ln in b.get("lines", []):
            for sp in ln.get("spans", []):
                t = sp["text"].strip(); y0 = sp["bbox"][1]
                if H*0.62 <= y0 <= H*0.96 and 5.0 <= sp.get("size", 0.0) <= 9.5 and "Math" not in sp["font"]:
                    out.append(t)
    return out
orphan = reset = marker_pages = total_markers = bare = 0
for i in range(doc.page_count):
    spans = band(doc[i])
    markers = [int(m.group(1)) for s in spans for m in [marker_re.match(s)] if m]
    bodies = [s for s in spans if not marker_re.match(s) and len(s) >= 3]
    has_marker = len(markers) > 0
    has_body = len(bodies) > 0
    if has_marker: marker_pages += 1
    if 1 in markers: reset += 1
    if has_body and not has_marker: orphan += 1
    for s in spans:
        if marker_re.match(s): total_markers += 1
        elif re.fullmatch(r"\d+", s): bare += 1   # bare digit (no brackets) = Story 5.4 marker regression
print(f"orphan={orphan}")
print(f"reset={reset}")
print(f"marker_pages={marker_pages}")
print(f"total_markers={total_markers}")
print(f"bare={bare}")
PYEOF
}

# ---------------------------------------------------------------------------
# ATDD-6.2-I01 (P0, gate, TC-E6-21, AC-7): fixture compiles exit 0 + ≤3 warnings (NFR-1).
#   Pre-impl AND post-impl the fixture compiles (Bug 2 is a RENDERING gap, not a compile error) — GREEN guard.
#   error-grep widened per R-26 sweep — bare ^! misses non-bang TeX errors.
test_i01_compile_ok() {
  [[ "$COMPILE_OK" == "1" ]] || return 1
  [[ -f "$FIXTURE_LOG" ]] || return 1
  local err warn
  err=$(grep -cE 'LaTeX Error:|Fatal error|Emergency stop' "$FIXTURE_LOG" 2>/dev/null || true)
  warn=$(grep -cE 'Warning:' "$FIXTURE_LOG" 2>/dev/null || true)
  printf "    (errors=%s, warnings=%s)\n" "$err" "$warn" >&2
  [[ "$err" -eq 0 && "$warn" -le 3 ]]
}

# ATDD-6.2-I02 (P0, *** RED DRIVER *** [reliable], TC-E6-09, AC-1, R-43): runtime penalty == 10000.
#   The fixture's PENALTYVALUE= marker prints \the\interfootnotelinepenalty. Pre-M1: 100 (default, splits
#   allowed). Post-M1: 10000 (atomicity). This is the RELIABLE behavioral RED (decoupled from the
#   content-density-dependent orphan split — see R-43 in the fixture comment). Also confirms M1 placement
#   AFTER footmisc (footmisc would reset to 100 otherwise → 100 even post-fix = the placement proof).
test_i02_penalty_value() {
  [[ "$COMPILE_OK" == "1" ]] || return 1
  local pen
  pen=$(probe_penalty "$FIXTURE_PDF" | awk -F= '/^penalty=/{print $2}')
  printf "    (runtime interfootnotelinepenalty=%s; expect 100 pre-fix, 10000 post-fix)\n" "$pen" >&2
  [[ "$pen" == "10000" ]]
}

# ATDD-6.2-I03 (P0, TC-E6-10, AC-2): footmisc [perpage] reset preserved — [1] recurs on ≥2 body pages.
#   M1 changes the line-break PENALTY, not the per-page counter reset (§1.2.4 line 109). GREEN pre/post.
#   The fixture places an early short footnote (one [1] page) + 3 clustered long footnotes on a LATER page
#   (another [1] via perpage reset) → ≥2 distinct pages each carry [1]. AC#2/TC-E6-10 spec-match (≥2, not ≥1).
test_i03_perpage_reset() {
  [[ "$COMPILE_OK" == "1" ]] || return 1
  local reset
  reset=$(probe_footnotes "$FIXTURE_PDF" | awk -F= '/^reset=/{print $2}')
  printf "    (pages with [1] marker=%s; expect ≥2 = perpage reset recurs across pages)\n" "$reset" >&2
  [[ "${reset:-0}" -ge 2 ]]
}

# ATDD-6.2-I04 (P0, TC-E6-11, AC-3): Story 5.4 [N] bracketed marker preserved (M1 ≠ \thefootnote).
#   Every footnote-band marker is bracketed [\d+]; NO bare digits (a bare digit = 5.4 regression).
#   total_markers≥1 (some footnotes exist) + bare=0 (all bracketed). GREEN pre/post.
test_i04_marker_bracketed() {
  [[ "$COMPILE_OK" == "1" ]] || return 1
  local total bare
  total=$(probe_footnotes "$FIXTURE_PDF" | awk -F= '/^total_markers=/{print $2}')
  bare=$(probe_footnotes "$FIXTURE_PDF" | awk -F= '/^bare=/{print $2}')
  printf "    (total [N] markers=%s, bare-digit spans=%s; expect total≥1, bare=0)\n" "$total" "$bare" >&2
  [[ "${total:-0}" -ge 1 && "${bare:-99}" -eq 0 ]]
}

# ATDD-6.2-I05 (P1, TC-E6-12, AC-4): xurl loaded + HARMLESS (residual cosmetic, NOT the leak fix).
#   Asserts the compile log has NO xurl error (load-order OK, no hyperref/biblatex clash) — compile hygiene is
#   the primary xurl defense. Does NOT assert the specific DOI break moved (the brainstorming found xurl does
#   NOT change the 10.1086/432166 break — DOI renders via \nolinkurl as plain TNR). GREEN pre/post.
test_i05_xurl_harmless() {
  [[ "$COMPILE_OK" == "1" ]] || return 1
  [[ -f "$FIXTURE_LOG" ]] || return 1
  local xerr
  xerr=$(grep -cE 'xurl.*Error|xurl.*undefined|! LaTeX Error.*xurl' "$FIXTURE_LOG" 2>/dev/null || true)
  printf "    (xurl errors=%s; expect 0)\n" "$xerr" >&2
  [[ "${xerr:-99}" -eq 0 ]]
}

# ATDD-6.2-I06 (P0, GUARD [not RED], TC-E6-22/TC-E6-09, AC-6): orphan-atomicity — 0 orphan pages post-fix.
#   Asserts no spurious orphan continuation page appears post-M1. This is a POST-FIX REGRESSION GUARD, NOT a
#   RED driver: the fixture's early short footnote (needed for I03 perpage ≥2) shifts pagination so the 3
#   clustered long footnotes no longer split even pre-fix (R-43 — minimal-fixture split reproduction is
#   incompatible with the I03≥2 perpage-spread requirement; empirically orphan=0 pre AND post). The PRIMARY
#   reliable RED is I02 (penalty 100→10000, content-independent). I06 catches a spurious-orphan regression
#   post-fix; it does not prove the Bug-2 split is fixed (I02 does, via the penalty mechanism).
test_i06_orphan_atomicity() {
  [[ "$COMPILE_OK" == "1" ]] || return 1
  local orphan
  orphan=$(probe_footnotes "$FIXTURE_PDF" | awk -F= '/^orphan=/{print $2}')
  printf "    (orphan continuation pages=%s; expect 0 [post-fix regression guard; R-43: minimal fixture may be 0 pre AND post])\n" "$orphan" >&2
  [[ "${orphan:-99}" -eq 0 ]]
}

echo "--- green-phase assertions (I02 penalty-value is the PRIMARY reliable RED driver; I07 --inject is the RED proof; I01/I03/I04/I05/I06 are guards) ---"
run_test P0 ATDD-6.2-I01 "fixture compiles exit 0 + ≤3 warnings (AC-7, NFR-1 gate, TC-E6-21)" test_i01_compile_ok
run_test P0 ATDD-6.2-I02 "runtime interfootnotelinepenalty == 10000 (AC-1, TC-E6-09, RELIABLE RED driver)" test_i02_penalty_value
run_test P0 ATDD-6.2-I03 "footmisc [perpage] reset: ≥2 pages with [1] (TC-E6-10, GREEN guard)" test_i03_perpage_reset
run_test P0 ATDD-6.2-I04 "Story 5.4 [N] bracketed marker preserved, 0 bare digits (TC-E6-11, GREEN guard)" test_i04_marker_bracketed
run_test P1 ATDD-6.2-I05 "xurl loaded + harmless: 0 xurl errors in log (TC-E6-12, R-44)" test_i05_xurl_harmless
run_test P0 ATDD-6.2-I06 "orphan-atomicity guard: 0 orphan pages post-fix (TC-E6-22; R-43 — PRIMARY reliable RED is I02)" test_i06_orphan_atomicity

# ---------------------------------------------------------------------------
# ATDD-6.2-I07 (P0, *** RED PROOF ***, TC-E6-14, AC-9, R-43) — RED-on-pre-fix proof (opt-in --inject).
#   Reproduces the pre-fix failing state on a TEMP-TREE COPY (live SUT untouched): copy the htuthesis tree,
#   copy the fixture to the temp root, REMOVE the M1 line from the temp cls (python — precise: the
#   \interfootnotelinepenalty=10000 non-comment line only, NOT the [基础] comment), recompile the fixture in
#   the temp tree, assert PENALTYVALUE reverts to 100 (M1 removed → penalty back to default). Reliable proof
#   the fixture exercises M1's mechanism (the penalty changes when M1 is reverted). Reports any orphan split
#   too (R-43 — informational; minimal fixture may not split).
if [[ "$INJECT" == "1" ]]; then
  echo ""
  echo "--- ATDD-6.2-I07 RED-on-pre-fix proof (--inject; temp-tree copy, SUT untouched) ---"

  test_i07_inject_red_on_prefix() {
    TMPBUILD="$(mktemp -d)"                   # global (not local) so the EXIT trap can clean it (review fix F14)
    cp -r . "$TMPBUILD"/ >/dev/null 2>&1
    cp "$FIXTURE_SRC" "$TMPBUILD/$FIXTURE_TEX"
    # Remove the M1 line from the TEMP cls only (revert the penalty). Python is precise where sed is brittle
    # (R-26): drop ONLY the non-comment \interfootnotelinepenalty=10000 line (keep the [基础] comment).
    python - "$TMPBUILD/htuthesis.cls" <<'PYEOF'
import sys
p = sys.argv[1]
src = open(p, encoding="utf-8").read().splitlines(keepends=True)
out = []; removed = 0
for ln in src:
    if (not ln.lstrip().startswith('%')) and 'interfootnotelinepenalty=10000' in ln:
        removed += 1; continue    # drop the M1 penalty line
    out.append(ln)
open(p, "w", encoding="utf-8").write("".join(out))
sys.exit(0 if removed >= 1 else 2)
PYEOF
    local pyrc=$?
    if [[ $pyrc -ne 0 ]]; then
      rm -rf "$TMPBUILD"
      echo "    [inject] could not locate the M1 line to revert (rc=$pyrc) — inject misconfigured" >&2
      return 1
    fi
    ( cd "$TMPBUILD" && latexmk -xelatex -file-line-error -halt-on-error -interaction=nonstopmode -g "$FIXTURE_TEX" >/dev/null 2>&1 )
    local pen orphan
    pen=$(probe_penalty "$TMPBUILD/$FIXTURE_PDF" | awk -F= '/^penalty=/{print $2}')
    orphan=$(probe_footnotes "$TMPBUILD/$FIXTURE_PDF" | awk -F= '/^orphan=/{print $2}')
    rm -rf "$TMPBUILD"
    printf "    (reverted-M1 penalty=%s, orphan=%s; expect penalty=100 = M1 reverted = RED)\n" "$pen" "${orphan:-NA}" >&2
    [[ "$pen" == "100" ]]
  }

  run_test P0 ATDD-6.2-I07 "TC-E6-14 RED-on-pre-fix: reverted M1 → penalty reverts to 100 (temp-tree, SUT untouched)" test_i07_inject_red_on_prefix
fi

echo ""
echo "=============================="
printf "Total: \033[32m%d PASS\033[0m  \033[31m%d FAIL\033[0m  \033[33m%d SKIP\033[0m\n" "$PASS" "$FAIL" "$SKIP_COUNT"
echo "=============================="

[[ "$SKIP" == "1" ]] && exit 0
[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
