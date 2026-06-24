#!/usr/bin/env bash
# test-story-6.1-starred-chapter-header.sh — ATDD Integration Tests for Story 6.1
#   (Native \chapter* header-mark fallback — M6 / NFR-7 / FR-3 refined / R-40 / R-41 / R-45)
#
# TDD Phase: RED — the PRIMARY RED drivers are ATDD-6.1-I02 (绪论 odd-page header) and I09 (--inject
#   RED-on-pre-fix proof). Pre-impl (current canonical cls: NO M6 — native \chapter* does not set the running
#   mark): compiling tests/fixtures/chapter-star-fixture.tex → \frontmatter \tableofcontents sets a stale
#   \@mkboth{目录}{目录}, then \mainmatter \chapter*{绪论} (native, ctex \@schapter, NO \@mkboth) → \rightmark
#   freezes at "目录" → 绪论 odd-page header = "目录" (stale) — Bug 1, spec §2.5 line 193 violation.
#   Post-impl (Story 6.1 M6 wrapper): the starred branch appends \@mkboth{绪论}{绪论} → \rightmark = "绪论".
#
#   This is the C1 closure of the #16 coverage-hole silent failure (R-40): Epic 2/3 header ATDDs used
#   numbered \chapter{} exclusively, so the native \chapter* odd-page header path was NEVER asserted —
#   the wrong text "目录" rendered visibly (a human would catch it) but the automated suite was blind.
#   The dedicated \chapter* fixture exercises the path they missed. A green I02 here is template-hardening
#   evidence, not just "works on the representative sample".
#
# *** DETECTION CALIBRATION (empirically verified 2026-06-24 on the pre-fix cls — DO NOT regress) ***
#   1. HEADER BAND = y0 < 70 AND 五号 size [9.5, 11.5]. The header renders at y0≈63.1, size 10.5 (SimSun for
#      CJK mark, TNR for the Alph appendix letter). Body / chapter TITLE start at y0≈146+ (topmargin 3cm +
#      beforeskip) — well below the gate. The 16pt 三号 chapter title (绪论 / 示例章 / 示例附录) is excluded
#      by BOTH the y0 gate (title sits mid-page) AND the size gate (16 ∉ [9.5,11.5]).
#   2. CJK HEADER TEXT FRAGMENTS PER-CHARACTER into separate fitz spans: "目"+"录", "绪"+"论", "示"+"例"+"章".
#      A PER-SPAN substring match (`"绪论" in sp["text"]`) FALSE-REDS post-fix (no single span holds the full
#      2-char string). The probes MUST CONCAT all header-band spans on a page into one string, THEN substring-
#      match (the G-A content-normalized-concat pattern; deferred-work §3.6/5.4 R-39). Do NOT revert to
#      per-span matching without re-verifying the RED phase on the pre-fix cls (I09 --inject).
#   3. The fixture body uses \loop filler (25 paragraphs/chapter) so 绪论 AND 示例章 each span ≥2 pages —
#      this guarantees an ODD page for each (CO header = chapter mark) + an EVEN page (CE = thesis title).
#      Pre-fix verified layout (9pp): p0 目录(front,header-less) p1 blank(cleardoublepage) p2/p4 绪论-odd
#      (header=目录 stale) p3/p5 绪论-even(title) p6 示例章-odd(header=第一章示例章) p7 示例章-even(title)
#      p8 附录-odd(header=附录A示例附录).
#
# Usage:
#   bash tests/test-story-6.1-starred-chapter-header.sh [--run] [--inject]
#     --run     Remove SKIP marker (activate; green-phase verification). Default ATDD_SKIP=1 = RED scaffold inert.
#     --inject  (opt-in, implies --run) ALSO run the ATDD-6.1-I09 RED-on-pre-fix proof: temp-tree copy with
#               the M6 wrapper block reverted → recompile fixture → assert 0 "绪论"-in-header hits (stale mark
#               returns). Heavy (~1 extra compile); use to reproduce the pre-fix RED state AFTER the fix is
#               committed. SUT is never modified (temp copy).
#
# Priority: P0 (the C1 #16 closure: I02 RED driver + I09 inject proof + I01 compile gate + I04 numbered
#           delegation regression + I06 appendix delegation) + P1 (I03 even-page + I07 front-matter header-less
#           + I08 M6≠S2 no-floating-page)
# Linked ACs: AC-1/I02 (绪论 odd header), AC-2/I03 (even header = title), AC-3/I04 (numbered delegation),
#             AC-5/I06 (appendix), AC-6/I07 (front-matter header-less), AC-7/I08 (M6≠S2 no floating page),
#             AC-9/I09 (C1 RED-on-pre-fix), AC-11/I01 (compile gate)
# Linked Risk: R-40 (system-level, score 6 — native \chapter* header gap; this test IS its mitigation),
#              R-41 (score 6 — M6 wrapper regression; I04 numbered delegation + the concat/size/position gate),
#              R-45 (score 4 — M6≠S2 floating-empty-page hazard; I08 is the memory-hazard regression)
# TC coverage: TC-E6-01 (I02), TC-E6-02 (I03), TC-E6-03 (I04), TC-E6-05 (I06), TC-E6-06 (I07),
#              TC-E6-07 (I09 --inject), TC-E6-08 (I08), TC-E6-21 (I01). TC-E6-04 (\htu@chapter* no-double-mark)
#              = source-level U03 + full regression TC-E6-18 on main.pdf; TC-E6-18/19/20 = gate (unit + existing suites).
#
# SUT PROTECTION (Epic 4 retro Lesson: tests must NOT modify the SUT; use temp copies):
#   - The fixture is copied to the htuthesis/ ROOT (chapter-star-fixture.tex) for cls resolution, compiled,
#     and removed via trap (guaranteed even on error). The canonical data/chap01.tex is NEVER touched.
#   - The --inject proof copies the WHOLE htuthesis tree to a temp dir (mktemp -d); the live cls is never edited.
#   - fitz reads chapter-star-fixture.pdf read-only; greps read chapter-star-fixture.toc/.aux/.log read-only.
#
# Truth source: spec §2.5 line 193 (正文奇数页 = 一级标题, PRIORITY) + architecture.md §原生 \chapter* header-mark
#   兜底 (M6, Story 6.1, 2026-06-24) + brainstorming-session-2026-06-24-154931.md fitz table (p10-39 stale /
#   p40 refresh, v1.1.1 verified) + v1.1.1 cls:160-177 (the proven M6 reference). See Story 6.1 spec.

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

FIXTURE_SRC="tests/fixtures/chapter-star-fixture.tex"
FIXTURE_TEX="chapter-star-fixture.tex"     # copied to htuthesis/ root for cls resolution
FIXTURE_PDF="chapter-star-fixture.pdf"
FIXTURE_TOC="chapter-star-fixture.toc"
FIXTURE_LOG="chapter-star-fixture.log"

# --- Fixture compile harness: copy fixture → htuthesis/ root, latexmk -g (fresh), cleanup on exit. ---
cleanup_fixture() {
  # Remove the fixture + its build artifacts from the htuthesis/ root (cls resolution copy). NEVER touch
  # data/chap01.tex or the canonical main.* — the fixture is an additive test artifact only.
  rm -f "$FIXTURE_TEX" "$FIXTURE_PDF" "$FIXTURE_TOC" "$FIXTURE_LOG" \
        chapter-star-fixture.aux chapter-star-fixture.out chapter-star-fixture.xdv \
        chapter-star-fixture.fdb_latexmk chapter-star-fixture.fls chapter-star-fixture.bbl 2>/dev/null
}
trap cleanup_fixture EXIT

compile_fixture() {
  if [[ ! -f "$FIXTURE_SRC" ]]; then
    echo "  [ERROR] fixture $FIXTURE_SRC not found (see atdd-checklist-6-1-*.md)" >&2
    return 1
  fi
  cp "$FIXTURE_SRC" "$FIXTURE_TEX"
  # R-12: -g forces a fresh pass (.aux/.toc regeneration — the header-mark mechanism needs a fresh toc/mark state).
  latexmk -xelatex -file-line-error -halt-on-error -interaction=nonstopmode -g "$FIXTURE_TEX" >/tmp/atdd-6.1-compile.log 2>&1
  return $?
}

echo "=============================================="
echo "ATDD Integration Tests: Story 6.1 — Native \\chapter* header-mark fallback (M6, NFR-7 / FR-3 / #16 closure)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped — run with --run post-impl)" || echo "ACTIVE")   Inject: $([ "$INJECT" == "1" ] && echo "ON (--inject)" || echo "off")"
echo "=============================================="
echo ""

# Compile the fixture ONCE (shared by I01-I08). Skipped entirely in RED-scaffold mode.
COMPILE_OK=0
if [[ "$SKIP" != "1" ]]; then
  echo "  [setup] compiling chapter-star-fixture (latexmk -xelatex -g) — ~3 min..."
  if compile_fixture; then
    COMPILE_OK=1
    echo "  [setup] fixture compiled → $FIXTURE_PDF + $FIXTURE_TOC regenerated"
  else
    echo "  [setup] FAILED: fixture did not compile (see /tmp/atdd-6.1-compile.log)" >&2
    COMPILE_OK=0
  fi
fi

# ---------------------------------------------------------------------------
# Shared fitz header probe (python). Reads chapter-star-fixture.pdf; for each page, CONCATs all header-band
# spans (y0<70 + 五号 size [9.5,11.5]) into one string, then reports counts. CJK header text fragments
# per-character (目+录, 绪+论) — per-page concat is MANDATORY (per-span match false-reds). Arg $1 = pdf path;
# prints "key=value" lines the bash tests parse.
probe_headers() {
  local pdf="$1"
  python - "$pdf" <<'PYEOF'
import fitz, sys
doc = fitz.open(sys.argv[1])
def hdr(p):
    return "".join(sp.get("text","") for b in p.get_text("dict")["blocks"]
                   for l in b.get("lines",[]) for sp in l["spans"]
                   if sp["bbox"][1] < 70 and 9.5 <= sp.get("size",0.0) <= 11.5)
def alltext(p):
    return "".join(sp.get("text","") for b in p.get_text("dict")["blocks"]
                   for l in b.get("lines",[]) for sp in l["spans"])
xulun=title=shili=0; blank=0; front_empty=0; first_main=""
for i,p in enumerate(doc):
    h=hdr(p); a=alltext(p)
    if "绪论" in h: xulun+=1
    if "测试论文标题" in h: title+=1
    if "示例章" in h: shili+=1
    if not a.strip(): blank+=1
    elif h.strip()=="" : front_empty+=1     # page with body but no header (front-matter header-less)
    if h.strip() and not first_main: first_main=h.strip()
print(f"xulun={xulun}")
print(f"title={title}")
print(f"shili={shili}")
print(f"blank={blank}")
print(f"front_empty={front_empty}")
print(f"first_main={first_main}")
PYEOF
}

# ---------------------------------------------------------------------------
# ATDD-6.1-I01 (P0, gate, TC-E6-21, AC-11): fixture compiles exit 0 + ≤3 warnings (NFR-1).
#   Pre-impl AND post-impl the fixture compiles (Bug 1 is a RENDERING gap, not a compile error) — GREEN guard.
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

# ATDD-6.1-I02 (P0, *** RED DRIVER ***, TC-E6-01, AC-1, R-40/R-41): 绪论 ODD-page header = "绪论"
#   (NOT stale "目录"). CONCAT-per-page (CJK fragments per-char). Pre-impl: xulun=0 (stale 目录) → RED.
#   Post-impl: xulun≥1 (绪论 odd pages) → GREEN.
test_i02_xulun_odd_header() {
  [[ "$COMPILE_OK" == "1" ]] || return 1
  local xulun
  xulun=$(probe_headers "$FIXTURE_PDF" | awk -F= '/^xulun=/{print $2}')
  printf "    (绪论-in-header pages=%s; expect 0 pre-fix, ≥1 post-fix)\n" "$xulun" >&2
  [[ "${xulun:-0}" -ge 1 ]]
}

# ATDD-6.1-I03 (P1, TC-E6-02, AC-2): 绪论/示例章 EVEN-page header = thesis title (\ctitle "测试论文标题").
#   CE header (cls:363) independent of M6 → unchanged pre/post. GREEN guard.
test_i03_even_header_title() {
  [[ "$COMPILE_OK" == "1" ]] || return 1
  local title
  title=$(probe_headers "$FIXTURE_PDF" | awk -F= '/^title=/{print $2}')
  printf "    (title-in-header pages=%s; expect ≥1)\n" "$title" >&2
  [[ "${title:-0}" -ge 1 ]]
}

# ATDD-6.1-I04 (P0, TC-E6-03, AC-3, R-41): numbered \chapter{示例章} delegation regression.
#   M6 numbered branch delegates to \htu@orig@chapter UNCHANGED → the numbered chapter's ODD page shows its
#   CO header (第一章示例章). Asserts (a) 示例章 in a header (concat), (b) .toc chapter entry present.
#   GREEN pre/post (delegation must not change anything).
test_i04_numbered_delegation() {
  [[ "$COMPILE_OK" == "1" ]] || return 1
  [[ -f "$FIXTURE_TOC" ]] || return 1
  local shili
  shili=$(probe_headers "$FIXTURE_PDF" | awk -F= '/^shili=/{print $2}')
  printf "    (示例章-in-header pages=%s; toc entry present=%s)\n" "$shili" "$([ -n "$(grep '示例章' "$FIXTURE_TOC")" ] && echo yes || echo no)" >&2
  [[ "${shili:-0}" -ge 1 ]] || return 1
  grep -q '示例章' "$FIXTURE_TOC"
}

# ATDD-6.1-I06 (P0, TC-E6-05, AC-5, R-41): appendix \chapter{示例附录} under \appendix unaffected.
#   Numbered branch (no star) → delegated → \thechapter=\@Alph (A) + .toc entry "附录 A 示例附录".
#   Compile-clean structural guard; precise A/B/C on 3 appendices = TC-E6-18 (main.pdf full regression). GREEN pre/post.
test_i06_appendix_delegation() {
  [[ "$COMPILE_OK" == "1" ]] || return 1
  [[ -f "$FIXTURE_TOC" ]] || return 1
  grep -q '示例附录' "$FIXTURE_TOC"
}

# ATDD-6.1-I07 (P1, TC-E6-06, AC-6): front matter (目录 page) remains HEADER-LESS.
#   \if@mainmatter suppression (cls:361-373) unchanged by M6 → front-matter pages have NO header-band span
#   (the 目录 title sits at y0≈146, below the y0<70 header zone). front_empty≥1 (the 目录 page is header-less).
#   GREEN pre/post.
test_i07_frontmatter_headerless() {
  [[ "$COMPILE_OK" == "1" ]] || return 1
  local fe
  fe=$(probe_headers "$FIXTURE_PDF" | awk -F= '/^front_empty=/{print $2}')
  printf "    (front-matter header-less pages=%s; expect ≥1)\n" "$fe" >&2
  [[ "${fe:-0}" -ge 1 ]]
}

# ATDD-6.1-I08 (P1, TC-E6-08, AC-7, R-45): M6 ≠ rejected S2 — NO floating empty-mark page.
#   Memory mainmatter-mark-clear-breaks-chapter-firstpage: S2 (\mainmatter adds \markboth{}{} clear) died
#   because an EMPTY mark floated to the chapter first page → header empty. M6 adds a REAL mark → no float.
#   Asserts: (a) blank pages ≤ 1 (only the legitimate \mainmatter \cleardoublepage blank; no extra float),
#   (b) the first mainmatter page's header is NON-empty (a real mark — "目录" pre-fix / "绪论" post-fix).
#   GREEN pre/post (neither S2-clear nor float). An S2 recurrence → extra blank OR empty first-main header.
test_i08_no_floating_empty_page() {
  [[ "$COMPILE_OK" == "1" ]] || return 1
  local blank first_main
  blank=$(probe_headers "$FIXTURE_PDF" | awk -F= '/^blank=/{print $2}')
  first_main=$(probe_headers "$FIXTURE_PDF" | awk -F= '/^first_main=/{print $2}')
  printf "    (blank=%s [≤1 legitimate cleardoublepage]; first_mainmatter_header=%s [non-empty])\n" "$blank" "$first_main" >&2
  [[ "${blank:-99}" -le 1 && -n "$first_main" ]]
}

echo "--- green-phase assertions (I02 is the RED driver; I09 --inject is the RED proof; I01/I03/I04/I06/I07/I08 are guards) ---"
run_test P0 ATDD-6.1-I01 "fixture compiles exit 0 + ≤3 warnings (AC-11, NFR-1 gate, TC-E6-21)" test_i01_compile_ok
run_test P0 ATDD-6.1-I02 "绪论 odd-page header = 绪论 (concat-per-page, y0<70+五号; TC-E6-01, RED driver)" test_i02_xulun_odd_header
run_test P1 ATDD-6.1-I03 "even-page header = thesis title (TC-E6-02, GREEN guard)" test_i03_even_header_title
run_test P0 ATDD-6.1-I04 "numbered \\chapter{示例章} delegation: CO header + .toc unchanged (TC-E6-03, R-41)" test_i04_numbered_delegation
run_test P0 ATDD-6.1-I06 "appendix \\chapter{示例附录} under \\appendix unaffected (TC-E6-05, R-41)" test_i06_appendix_delegation
run_test P1 ATDD-6.1-I07 "front matter (目录 page) header-less (TC-E6-06, GREEN guard)" test_i07_frontmatter_headerless
run_test P1 ATDD-6.1-I08 "M6≠S2: no floating empty-mark page at \\mainmatter (TC-E6-08, R-45 memory hazard)" test_i08_no_floating_empty_page

# ---------------------------------------------------------------------------
# ATDD-6.1-I09 (P0, *** RED PROOF ***, TC-E6-07, AC-9, R-40/R-42) — RED-on-pre-fix proof (opt-in --inject).
#   Reproduces the pre-fix failing state on a TEMP-TREE COPY (live SUT untouched): copy the htuthesis tree,
#   copy the fixture to the temp root, REMOVE the M6 block from the temp cls (python — precise: the
#   \NewCommandCopy + \RenewDocumentCommand{\chapter}{...} block, NOT the [基础] comment), recompile the
#   fixture in the temp tree, assert 0 "绪论"-in-header hits (stale "目录" returns = RED). Proves the fixture
#   exercises the failing path (the #16 coverage hole), not a representative-sample artifact.
if [[ "$INJECT" == "1" ]]; then
  echo ""
  echo "--- ATDD-6.1-I09 RED-on-pre-fix proof (--inject; temp-tree copy, SUT untouched) ---"

  test_i09_inject_red_on_prefix() {
    local tmpbuild; tmpbuild="$(mktemp -d)"
    cp -r . "$tmpbuild"/ >/dev/null 2>&1
    cp "$FIXTURE_SRC" "$tmpbuild/$FIXTURE_TEX"
    # Remove the M6 block from the TEMP cls only (revert the wrapper). Python is precise where sed is brittle
    # (R-26): drop \NewCommandCopy{\htu@orig@chapter}{\chapter} + the \RenewDocumentCommand{\chapter}{s o m}{...}
    # block through its closing standalone }. Comment-safe (skips % lines on the NewCommandCopy start match).
    python - "$tmpbuild/htuthesis.cls" <<'PYEOF'
import sys
p = sys.argv[1]
src = open(p, encoding="utf-8").read().splitlines(keepends=True)
out = []; skip = False; renew_open = False; removed = False
for ln in src:
    if (not skip and '\\NewCommandCopy{\\htu@orig@chapter}{\\chapter}' in ln
            and not ln.lstrip().startswith('%')):
        skip = True; removed = True; continue
    if skip:
        if '\\RenewDocumentCommand{\\chapter}' in ln:
            renew_open = True; continue
        if renew_open and ln.strip() == '}':
            skip = False; renew_open = False; continue
        continue  # drop body lines of the wrapper
    out.append(ln)
open(p, "w", encoding="utf-8").write("".join(out))
sys.exit(0 if removed else 2)
PYEOF
    local pyrc=$?
    if [[ $pyrc -ne 0 ]]; then
      rm -rf "$tmpbuild"
      echo "    [inject] could not locate M6 block to revert (rc=$pyrc) — inject misconfigured" >&2
      return 1
    fi
    ( cd "$tmpbuild" && latexmk -xelatex -file-line-error -halt-on-error -interaction=nonstopmode -g "$FIXTURE_TEX" >/dev/null 2>&1 )
    local xulun
    xulun=$(probe_headers "$tmpbuild/$FIXTURE_PDF" | awk -F= '/^xulun=/{print $2}')
    rm -rf "$tmpbuild"
    printf "    (reverted-M6 绪论-in-header=%s; expect 0 = stale 目录 returns = RED)\n" "${xulun:--1}" >&2
    [[ "$xulun" == "0" ]]
  }

  run_test P0 ATDD-6.1-I09 "TC-E6-07 RED-on-pre-fix: reverted M6 → 0 绪论-in-header hits (stale 目录 returns; temp-tree, SUT untouched)" test_i09_inject_red_on_prefix
fi

echo ""
echo "=============================="
printf "Total: \033[32m%d PASS\033[0m  \033[31m%d FAIL\033[0m  \033[33m%d SKIP\033[0m\n" "$PASS" "$FAIL" "$SKIP_COUNT"
echo "=============================="

[[ "$SKIP" == "1" ]] && exit 0
[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
