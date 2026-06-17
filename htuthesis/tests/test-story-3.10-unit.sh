#!/usr/bin/env bash
# test-story-3.10-unit.sh — ATDD Red-Phase Unit Tests for Story 3.10 (cover metadata table framing)
# TDD Phase: RED (source-level greps; framed-table-wiring test FAILS on pre-impl;
#             font/label/scope/regression guards pass)
#
# Usage: bash tests/test-story-3.10-unit.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 tests are blocking
# Linked ACs: AC-1 (framed table wiring), AC-5 (font + labels preserved), AC-6 (regression)
# Linked Risk: R-9 (score 6, cover precision), R-6 (score 6, geometry coupling), R-3 (baselineskip)
# TC-E3-46 (cover metadata framed table) — source-level wiring guard
#
# NOTE: these are SOURCE-LEVEL greps — they prove the cls CONTAINS the framed-table wiring.
# The companion integration test (test-story-3.10-integration.sh) proves the RENDERED frame via
# fitz get_drawings (≥7 line segments). A source-grep that \draw/abular exists does NOT prove the
# frame RENDERS (a TikZ error could drop a rule); the fitz check is the real AC-2 proof.
# Tests are READ-ONLY — they MUST NOT modify the SUT (Epic 1/2 retro lesson).

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
echo "ATDD Unit Tests: Story 3.10 — Cover metadata table framing"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# Shared helper: extract the \htu@first@titlepage definition body (cls) for scoped greps.
# Robust extraction: from the '\newcommand{\htu@first@titlepage}{' line to the matching
# '\end{tikzpicture}%\n' close (cls:588-649). Falls back to whole-cls grep if extraction misses.
first_titlepage_body() {
  sed -n '/\\newcommand{\\htu@first@titlepage}{/,/\\end{tikzpicture}%/p' htuthesis.cls 2>/dev/null
}

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: framed-table wiring (RED pre-impl) ==="

# ATDD-3.10-01: framed-table wiring present in \htu@first@titlepage (AC-1, TC-E3-46)
# Mechanism-agnostic (Story Task 1.2 lets the dev pick):
#   Option A (RECOMMENDED) — TikZ \draw rules inside the existing tikzpicture overlay.
#   Option B — embedded \begin{tabular}{|p{...}|p{...}|} inside a \node.
# Pre-impl: the metadata block uses ONLY \htu@underline[25mm]{...} (3 bare underline lines) →
#   NO \draw AND NO \begin{tabular} in first_titlepage → 0 → RED.
# Post-impl: ≥1 of \draw (Option A) or \begin{tabular} (Option B) → GREEN.
test_framed_table_wiring() {
  [[ -f "htuthesis.cls" ]] || return 1
  local body
  body=$(first_titlepage_body)
  [[ -z "$body" ]] && { echo "  (could not extract \htu@first@titlepage body)"; return 1; }
  local draw_n tab_n
  draw_n=$(printf '%s\n' "$body" | grep -cE '\\draw\b|\\path\b.*draw|\\draw\[' 2>/dev/null || true)
  tab_n=$(printf '%s\n' "$body" | grep -cE '\\begin\{tabular\}' 2>/dev/null || true)
  draw_n=$(echo "$draw_n" | tr -d '[:space:]' | head -1)
  tab_n=$(echo "$tab_n" | tr -d '[:space:]' | head -1)
  echo "  (first_titlepage: \\draw lines=$draw_n, \\begin{tabular}=$tab_n; expect >=1 of either post-impl, 0 pre-impl)"
  [[ "$draw_n" -ge 1 || "$tab_n" -ge 1 ]]
}
run_test "P0" "ATDD-3.10-01" "framed-table wiring in \\htu@first@titlepage (AC-1, TC-E3-46; RED pre-impl)" test_framed_table_wiring

# ATDD-3.10-02: \fangsong\htu@fangsong@latin preserved in metadata cells (AC-5; GREEN guard)
# The cover-scoped \newfontfamily \htu@fangsong@latin (Story 3.1 code review) keeps ASCII digits/
# letters in FangSong for the span-level reference match (ATDD-3.1-I07). The reframe MUST NOT drop it.
# Pre-impl: present (Story 3.1) → GREEN guard. Post-impl: must stay present.
test_fangsong_latin_preserved() {
  [[ -f "htuthesis.cls" ]] || return 1
  local body
  body=$(first_titlepage_body)
  [[ -z "$body" ]] && { echo "  (could not extract \htu@first@titlepage body)"; return 1; }
  # \fangsong and \htu@fangsong@latin both expected on the metadata cells.
  printf '%s\n' "$body" | grep -q 'fangsong' && \
  printf '%s\n' "$body" | grep -q 'htu@fangsong@latin'
}
run_test "P0" "ATDD-3.10-02" "\\fangsong\\htu@fangsong@latin preserved in metadata cells (AC-5; GREEN guard)" test_fangsong_latin_preserved

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: labels preserved + scope boundary + regression ==="

# ATDD-3.10-03: metadata labels unchanged (AC-5; GREEN guard)
# Story 3.1 wired \htu@schoolcode@title{单位代码} etc. (cls:172-174). The reframe MUST NOT change
# label text. Pre-impl: present → GREEN guard.
test_metadata_labels() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'schoolcode@title\{单位代码\}' htuthesis.cls && \
  grep -qE 'id@title\{学号\}' htuthesis.cls && \
  grep -qE 'secretlevel@title\{分类号\}' htuthesis.cls
}
run_test "P1" "ATDD-3.10-03" "metadata labels 单位代码/学号/分类号 unchanged (AC-5; GREEN guard)" test_metadata_labels

# ATDD-3.10-04: \htu@abstractcover NOT reframed (scope boundary; Story 3.14 deletes it)
# \htu@abstractcover (cls:710-725) is a COPY of the 3-underline metadata block. Story 3.14 DELETES
# \htu@abstractcover (FR-12 removed). Reframing it now = wasted work + a 3.14 conflict.
# This GREEN guard asserts abstractcover still uses bare \htu@underline (the 3.10 scope boundary).
# After 3.14 deletes abstractcover, this test is repointed/retired (Decision 2 traceability).
test_abstractcover_not_reframed() {
  [[ -f "htuthesis.cls" ]] || return 1
  local abs_body
  abs_body=$(sed -n '/\\newcommand{\\htu@abstractcover}{/,/\\end{tikzpicture}/p' htuthesis.cls 2>/dev/null)
  if [[ -z "$abs_body" ]]; then
    # abstractcover already removed (Story 3.14 ran first) → scope boundary moot; PASS with note.
    echo "  (\htu@abstractcover not found — already removed by Story 3.14; scope boundary moot)"
    return 0
  fi
  # abstractcover present → assert it still uses \htu@underline (NOT reframed by 3.10).
  local draw_n
  draw_n=$(printf '%s\n' "$abs_body" | grep -cE '\\draw\b|\\begin\{tabular\}' 2>/dev/null || true)
  draw_n=$(echo "$draw_n" | tr -d '[:space:]' | head -1)
  echo "  (abstractcover \draw/tabular count: $draw_n; expect 0 — 3.10 reframes first_titlepage ONLY)"
  [[ "$draw_n" -eq 0 ]]
}
run_test "P1" "ATDD-3.10-04" "\\htu@abstractcover NOT reframed (scope boundary — Story 3.14 deletes it)" test_abstractcover_not_reframed

# ATDD-3.10-05: regression — \htu@body@baselineskip{18bp} in .def unchanged (R-3/R-18 pre-3.11)
# The cover table is page-1-only; it MUST NOT touch body baselineskip (Story 3.11 owns that).
test_body_baselineskip_18bp() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -q 'htu@body@baselineskip{18bp}' htuthesis.def
}
run_test "P1" "ATDD-3.10-05" "regression: \\htu@body@baselineskip{18bp} in .def unchanged (R-3)" test_body_baselineskip_18bp

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: regression — no \\setstretch (R-3 anti-pattern) ==="

# ATDD-3.10-06: regression — NO \setstretch in cls (R-3 anti-pattern; GREEN guard)
# \setstretch is the CJK line-spacing trap (Epic 2 R-3). Cover reframe must not introduce it.
test_no_setstretch() {
  [[ -f "htuthesis.cls" ]] || return 1
  local n
  n=$(grep -c 'setstretch' htuthesis.cls 2>/dev/null || true)
  n=$(echo "$n" | tr -d '[:space:]' | head -1)
  echo "  (setstretch matches: $n; expect 0)"
  [[ "$n" -eq 0 ]]
}
run_test "P2" "ATDD-3.10-06" "regression: NO \\setstretch in cls (R-3 anti-pattern)" test_no_setstretch

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
  echo "   RED (fail pre-impl): 3.10-01 (framed-table wiring — no \\draw/tabular in first_titlepage"
  echo "      pre-impl, only \\htu@underline)."
  echo "   GREEN guards: 3.10-02 (fangsong@latin), 3.10-03 (labels), 3.10-04 (abstractcover scope),"
  echo "      3.10-05 (baselineskip), 3.10-06 (no setstretch)."
  echo ""
  echo "   NOTE: source-greps prove wiring EXISTS; the integration test's fitz get_drawings check"
  echo "         (ATDD-3.10-15/16 — >=7 line segments + 4H×3V grid) proves the frame RENDERS —"
  echo "         the real AC-2 proof. Tests are read-only — they do not modify the SUT."
  echo "         ATDD-3.10-01 is mechanism-agnostic (TikZ \\draw OR tabular); the dev picks in Task 1.2."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
