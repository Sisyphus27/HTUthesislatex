#!/usr/bin/env bash
# test-story-3.10-integration.sh — ATDD Red-Phase Integration Tests for Story 3.10
# (cover metadata table framing)
# TDD Phase: RED (frame-presence get_drawings behavior tests FAIL on pre-impl;
#             compile + self-check regression guards pass)
#
# Usage: bash tests/test-story-3.10-integration.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 tests are blocking
# Linked ACs: AC-1 (bordered 4H×3V table), AC-2 (fitz get_drawings ≥7 segments — the AC-2 PRIMARY PROOF),
#             AC-3 (label ~24mm + value ~28mm columns), AC-5 (FangSong + text preserved), AC-6 (regression)
# Linked Risk: R-9 (score 6, cover precision — block must stay top-left ±3mm), R-6 (score 6, geometry
#              coupling — MUST NOT reintroduce \parbox/\textwidth coupling), R-1/R-3 (regression),
#              R-12 (.aux staleness — latexmk -g mandatory)
# TC-E3-46 (cover metadata framed table — get_drawings ≥7 line segments)
#
# NOTE: source-greps (unit) prove the frame is WIRED; these tests prove the frame RENDERS:
#   - ATDD-3.10-15: BEHAVIOR — ≥7 line segments in the cover top-left metadata region (y<50mm).
#       Pre-impl = 3 bare \htu@underline strokes → RED. Reference PDF page 2 = exactly 7 → GREEN post-impl.
#   - ATDD-3.10-16: BEHAVIOR — ≥4 horizontal + ≥3 vertical rules forming the 4H×3V grid (AC-1/AC-3).
#       Classifies the 7 reference segments: 4H at y≈20/29/38/47mm + 3V at x≈21/46/74mm.
#   A source-grep that \draw exists does NOT prove the frame renders (a TikZ error could drop a rule).
#   These fitz behavior tests are the real AC-2 proof (Story 2.5/2.6/3.9 behavior-test lesson).
#
# fitz calibration notes (verified pre-impl on main.pdf + reference PDF 2026-06-17):
#   - The doctoral cover is page 0 (physical 1) of main.pdf; found by signature "博士学位论文" + "10476".
#   - Pre-impl metadata region (y<50mm): 3 drawing rects-strokes = the 3 \htu@underline lines
#       (y=27.0/36.1/45.0mm, x≈37-70mm) → 3 < 7 → ATDD-3.10-15 RED.
#   - Reference PDF page 2 metadata region: 7 segments —
#       4H: y=20.5/29.5/38.4/47.4mm (x 21.3→74.3); 3V: x=21.4/45.7/74.3mm (y 20.4→47.5).
#       Label col 21.4→45.7mm (24.3mm) + Value col 45.7→74.3mm (28.6mm).
#   - Story 3.1 already placed the text at reference-matching coords (单位代码 x=23.3 y=22.8mm); ONLY the
#       7 border rules are missing → pure frame-ADD → ATDD-3.1-I06 (±3mm) + ATDD-3.1-I07 (FangSong)
#       cross-story tests should stay GREEN automatically (Decision 2 watch).

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
echo "ATDD Integration Tests: Story 3.10 — Cover metadata table framing"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# Shared Python header: opens main.pdf, finds the cover page, defines the metadata-region helper.
# Reference baseline (reference thesis 2107084001 page 2) embedded for the geometry cross-check.
PY_HEAD='
import fitz, sys, re
doc = fitz.open("main.pdf")
def mm(v): return v / 72.0 * 25.4
# Find the doctoral cover page: signature "博士学位论文" + "10476" (present pre- AND post-impl).
cover = None
for i in range(min(5, doc.page_count)):
    t = doc[i].get_text()
    if "博士学位论文" in t and "10476" in t:
        cover = i; break
if cover is None:
    print("  (doctoral cover page not found: no page with 博士学位论文 + 10476)"); sys.exit(2)
pg = doc[cover]; W = pg.rect.width; H = pg.rect.height
# Metadata region = top-left, y < 55mm (reference table spans y 20.4→47.5mm; margin for ±3mm drift).
META_TOP = 55.0 / 25.4 * 72.0
# Table bbox expectation (reference ±3mm tolerance): x 18→78mm, y 18→49mm.
TBL_X0, TBL_X1 = 18.0 / 25.4 * 72.0, 78.0 / 25.4 * 72.0
TBL_Y0, TBL_Y1 = 18.0 / 25.4 * 72.0, 49.0 / 25.4 * 72.0
def meta_drawings():
    # Drawing dicts whose rect intersects the metadata top region (y1 < META_TOP).
    out = []
    for d in pg.get_drawings():
        r = d["rect"]
        if r.y1 < META_TOP:
            out.append(d)
    return out
def segment_orientation(d):
    # Classify a near-degenerate drawing rect as 'h' (horizontal line), 'v' (vertical line),
    # or 'other' (rect/curve/filled). The underline macro + TikZ draw-line register as
    # near-zero-height (h) or near-zero-width (v) rects in fitz get_drawings.
    r = d["rect"]
    dx = abs(r.x1 - r.x0); dy = abs(r.y1 - r.y0)
    # Threshold: a line is < ~2pt thick in one dimension (0.7mm). Tolerate anti-aliasing.
    TH = 2.0
    if dy <= TH and dx > TH: return "h"
    if dx <= TH and dy > TH: return "v"
    return "other"
'

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Compile + Frame Behavior (AC-2 primary proof) ==="

# ATDD-3.10-08: latexmk -xelatex -g main.tex exit code 0 (AC-6; R-12 full recompile mandatory)
# The frame adds vector strokes → -g (force) avoids a stale overlay showing old underlines.
test_full_compile() {
  [[ -f "htuthesis.cls" ]] || return 1
  latexmk -xelatex -g -interaction=nonstopmode main.tex > /dev/null 2>&1
  return $?
}
run_test "P0" "ATDD-3.10-08" "latexmk -xelatex main.tex exit code 0 (AC-6, R-12 full recompile)" test_full_compile

# ATDD-3.10-09: zero compilation errors in main.log (AC-6)
test_no_errors() {
  if [[ -f "main.log" ]]; then
    local error_count
    error_count=$(grep -c '^!' main.log 2>/dev/null || true)
    error_count=$(echo "$error_count" | tr -d '[:space:]' | head -1)
    [[ "$error_count" -eq 0 ]]
  else
    return 1
  fi
}
run_test "P0" "ATDD-3.10-09" "zero compilation errors in main.log (AC-6)" test_no_errors

# ATDD-3.10-10: warning count <= 3 (AC-6; baseline = 1 benign xeCJK warning after Story 3.9)
test_warning_count() {
  if [[ -f "main.log" ]]; then
    local warning_count
    warning_count=$(grep -c 'Warning' main.log 2>/dev/null || true)
    warning_count=$(echo "$warning_count" | tr -d '[:space:]' | head -1)
    echo "  (Found $warning_count warnings, limit: 3)"
    [[ "$warning_count" -le 3 ]]
  else
    return 1
  fi
}
run_test "P0" "ATDD-3.10-10" "warning count <= 3 (AC-6, NFR <=3 new vs baseline=1)" test_warning_count

# ATDD-3.10-15: BEHAVIOR — >=7 line segments in the cover metadata region (AC-2, TC-E3-46)
# THE AC-2 PRIMARY PROOF. fitz get_drawings on the cover top-left region (y<55mm).
# Pre-impl: 3 bare \htu@underline strokes → 3 < 7 → RED.
# Reference PDF page 2: exactly 7 segments (4H + 3V). Post-impl: >=7 → GREEN.
# The floor (7) = the reference's exact count = a real bordered 3×2 table (4 horizontal rules +
# 3 vertical rules). 3 underlines cannot reach 7 → genuinely RED pre-impl.
test_frame_segments_ge7() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
ds = meta_drawings()
n = len(ds)
print(\"  cover=p\" + str(cover+1) + \", metadata-region drawing segments=\" + str(n) + \" (target >=7; ref page2=7; pre-impl=3)\")
sys.exit(0 if n >= 7 else 1)
"
}
run_test "P0" "ATDD-3.10-15" "BEHAVIOR: >=7 line segments in cover metadata region (AC-2, TC-E3-46)" test_frame_segments_ge7

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: 4H×3V grid geometry + regression + FangSong preserve ==="

# ATDD-3.10-16: BEHAVIOR — >=4 horizontal + >=3 vertical rules forming the 4H×3V grid (AC-1, AC-3)
# Stronger geometry check than 3.10-15: classifies the segments by orientation.
# Reference: 4H at y=20.5/29.5/38.4/47.4mm + 3V at x=21.4/45.7/74.3mm.
# Pre-impl: 3 \htu@underline strokes are all horizontal → H=3, V=0 → V<3 → RED.
# Post-impl: H>=4 AND V>=3 → GREEN.
test_frame_grid_4h3v() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
ds = meta_drawings()
h = sum(1 for d in ds if segment_orientation(d) == \"h\")
v = sum(1 for d in ds if segment_orientation(d) == \"v\")
oth = sum(1 for d in ds if segment_orientation(d) == \"other\")
print(\"  cover=p\" + str(cover+1) + \" grid: horizontal=\" + str(h) + \" vertical=\" + str(v) + \" other=\" + str(oth) + \" (target H>=4, V>=3; ref 4H+3V)\")
sys.exit(0 if (h >= 4 and v >= 3) else 1)
"
}
run_test "P1" "ATDD-3.10-16" "BEHAVIOR: >=4 horizontal + >=3 vertical rules (4H×3V grid, AC-1/AC-3)" test_frame_grid_4h3v

# ATDD-3.10-11: self-check textheight ~688pt unchanged (AC-6, R-1; GREEN guard)
# Cover reframe must NOT alter geometry (cover positions are paper-relative via TikZ overlay).
test_textheight_unchanged() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local th
  th=$(grep 'textheight = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$th" ]]; then echo "  (textheight not found in self-check)"; return 1; fi
  echo "  (textheight: ${th}pt [expect ~688.56])"
  echo "$th" | awk '{if ($1 >= 686 && $1 <= 690) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.10-11" "self-check textheight unchanged ~688pt (AC-6, R-1)" test_textheight_unchanged

# ATDD-3.10-12: self-check baselineskip ≈ 23.4bp (AC-6, R-3; REPOINTED by Story 3.11: was 18bp, now 23.4bp)
# Cover table is page-1-only; MUST NOT touch body baselineskip (Story 3.11 owns the 18→23.4 recalibration).
test_baselineskip_18bp() {
  if [[ ! -f "main.log" ]]; then return 1; fi
  local bs
  bs=$(grep 'baselineskip = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | sed 's/pt.*//')
  if [[ -z "$bs" ]]; then echo "  (baselineskip not found in self-check)"; return 1; fi
  echo "  (baselineskip: ${bs}pt, expect ~23.49 [23.4bp, repointed by Story 3.11; NOT 21.6 = R-3 trap])"
  echo "$bs" | awk '{if ($1 >= 22.5 && $1 <= 24.5) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.10-12" "self-check baselineskip ~23.4bp (REPOINTED by Story 3.11; AC-6, R-3; cover reframe must not touch it)" test_baselineskip_18bp

# ATDD-3.10-13: main.pdf exists + total pages ~50 ±5 unchanged (AC-6; GREEN guard)
# The cover table is a page-1 visual reframe — zero pagination effect expected.
test_pdf_and_pages() {
  if [[ ! -f "main.pdf" ]] || [[ ! -s "main.pdf" ]]; then return 1; fi
  if [[ ! -f "main.log" ]]; then return 1; fi
  local total_pages
  total_pages=$(grep 'total pages = ' main.log 2>/dev/null | head -1 | sed 's/.*= //' | tr -d '[:space:]')
  if [[ -z "$total_pages" ]]; then echo "  (page count not found)"; return 1; fi
  echo "  (pages: $total_pages, expected ~49-50 ±5 [cover frame = no pagination shift])"
  echo "$total_pages" | awk '{if ($1 >= 44 && $1 <= 55) exit 0; else exit 1}'
}
run_test "P1" "ATDD-3.10-13" "main.pdf exists + total pages ~49-50 ±5 (AC-6; frame = no pagination shift)" test_pdf_and_pages

# ATDD-3.10-17: BEHAVIOR — metadata font FangSong + text presence preserved (AC-5; cross-story guard)
# The reframe MUST NOT drop \fangsong\htu@fangsong@latin (the cover-scoped Latin family, Story 3.1
# code review) or the label text. Anchors: the "10476" block (present pre- AND post-impl) + labels.
# GREEN guard pre-impl (Story 3.1 wired it). This is the cross-story ATDD-3.1-I07 mirror — if it
# fails post-impl, the reframe dropped the font family (regression, NOT a Decision-2 override).
test_metadata_fangsong_preserved() {
  if [[ ! -f "main.pdf" ]]; then return 1; fi
  python -c "$PY_HEAD
# Find the metadata text blocks on the cover: label + value per row.
t = pg.get_text()
for kw in [\"单位代码\", \"学号\", \"分类号\"]:
    if kw not in t:
        print(\"  metadata label MISSING: \" + kw); sys.exit(1)
# Font check on the block containing the schoolcode value 10476 (CJK + ASCII FangSong).
hit = None
for b in pg.get_text(\"dict\").get(\"blocks\", []):
    if b.get(\"type\", 0) != 0: continue
    spans = [sp for ln in b.get(\"lines\", []) for sp in ln.get(\"spans\", [])]
    txt = \"\".join(sp[\"text\"] for sp in spans)
    if \"10476\" in txt:
        hit = spans; break
if hit is None:
    print(\"  (10476 metadata block not found)\"); sys.exit(1)
fonts = \",\".join(sorted(set(sp[\"font\"] for sp in hit)))
fangsong_ok = any((\"FangSong\" in sp[\"font\"] or \"仿宋\" in sp[\"font\"] or \"Fang\" in sp[\"font\"]) for sp in hit)
print(\"  metadata 10476-block fonts=[%s] fangsong_ok=%s\" % (fonts, fangsong_ok))
sys.exit(0 if fangsong_ok else 1)
"
}
run_test "P1" "ATDD-3.10-17" "BEHAVIOR: metadata font FangSong + labels preserved (AC-5; cross-story guard)" test_metadata_fangsong_preserved

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
  echo "   RED (fail pre-impl): 3.10-15 (>=7 segments; pre-impl=3 underlines < 7),"
  echo "      3.10-16 (4H+3V grid; pre-impl H=3 V=0)."
  echo "   GREEN guards: 3.10-08/09/10 (compile), 3.10-11/12/13 (self-check geometry/pages),"
  echo "      3.10-17 (FangSong + labels preserved)."
  echo ""
  echo "   NOTE: the fitz get_drawings behavior test (3.10-15/16) is the AC-2 real proof —"
  echo "         source-greps cannot prove the frame renders (a TikZ error could drop a rule)."
  echo "         R-9/R-12: latexmk -g mandatory; cover table is page-1-only (no pagination shift)."
  echo "         Decision 2: if the cross-story ATDD-3.1-I06 (±3mm) / ATDD-3.1-I07 (FangSong) fail"
  echo "         post-impl, classify + repoint transparently — do NOT silently delete."
  echo "         Tests are read-only — they do not modify the SUT."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
