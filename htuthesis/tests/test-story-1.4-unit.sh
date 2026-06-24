#!/usr/bin/env bash
# test-story-1.4-unit.sh — ATDD Red-Phase Unit Tests for Story 1.4
# TDD Phase: RED (all tests expected to FAIL before implementation)
#
# Usage: bash tests/test-story-1.4-unit.sh [--run]
#   --run    Remove SKIP markers (for green-phase verification)
#
# Priority: P0 tests are blocking; P1/P2 are best-effort
# Linked Risks: E1-R3 (Font detection not implemented, Score 6)
#               E1-R5 (ZZU identity residual, Score 4)
#               E1-R6 (Logo file quality, Score 4)

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
echo "ATDD Unit Tests: Story 1.4 — Replace ZZU identity with HTU identity"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: Identity Cleanup & Font Detection ==="

# ATDD-1.4-01: Zero ZZU references in cls/def/main.tex (AC-1, TC-1.4-UNIT-01)
test_zero_zzu_identity() {
  local count
  count=$(grep -ri '郑州大学\|Zhengzhou\|ZZU\|zzu' htuthesis.cls htuthesis.def main.tex 2>/dev/null \
    | grep -v 'zzuthesis.*原始\|zzuthesis.*真值来源\|zzuthesis.*provenance\|zzuthesis.*来源' \
    | wc -l)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  echo "  (Found $count ZZU identity matches in cls/def/main.tex)"
  [[ "$count" -eq 0 ]]
}
run_test "P0" "ATDD-1.4-01" "Zero ZZU references in cls/def/main.tex (AC-1)" test_zero_zzu_identity

# ATDD-1.4-02: Old ZZU logo files do NOT exist (AC-4)
test_old_logos_deleted() {
  local found=0
  for f in figures/zzu.pdf figures/zzu.tex figures/zzubachelor.pdf figures/zzubachelor.tex figures/zzulogo.pdf; do
    if [[ -f "$f" ]]; then
      echo "  (Found residual file: $f)"
      ((found++))
    fi
  done
  echo "  (Found $found old ZZU logo files)"
  [[ "$found" -eq 0 ]]
}
run_test "P0" "ATDD-1.4-02" "Old ZZU logo files deleted (AC-4)" test_old_logos_deleted

# ATDD-1.4-03: Font detection — 5 IfFontExistsTF checks in cls (AC-5, E1-R3)
test_font_detection_count() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep -c 'IfFontExistsTF' htuthesis.cls 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  echo "  (Found $count IfFontExistsTF checks)"
  [[ "$count" -ge 5 ]]
}
run_test "P0" "ATDD-1.4-03" "5 IfFontExistsTF font checks in cls (AC-5)" test_font_detection_count

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Identity Parameters ==="

# ATDD-1.4-07: University code = 10476 in cover.tex (AC-2, TC-1.4-UNIT-02)
test_school_code_htu() {
  [[ -f "data/cover.tex" ]] || return 1
  grep -q '10476' data/cover.tex 2>/dev/null
}
run_test "P1" "ATDD-1.4-07" "University code 10476 in cover.tex (AC-2)" test_school_code_htu

# ATDD-1.4-08: PackageError format in font checks (AC-5, TC-1.4-UNIT-03)
test_font_package_error() {
  [[ -f "htuthesis.cls" ]] || return 1
  local count
  count=$(grep -c 'PackageError{htuthesis}' htuthesis.cls 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  echo "  (Found $count PackageError{htuthesis} calls)"
  [[ "$count" -ge 5 ]]
}
run_test "P1" "ATDD-1.4-08" "PackageError format in font checks (AC-5)" test_font_package_error

# ATDD-1.4-10: School name is 河南师范大学 in cls or def (AC-1)
# Per architecture three-layer design: name defined in .def, consumed by .cls
test_school_name_htu() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q '河南师范大学' htuthesis.cls htuthesis.def 2>/dev/null
}
run_test "P1" "ATDD-1.4-10" "School name = 河南师范大学 in cls or def (AC-1)" test_school_name_htu

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: Logo References & Parameters ==="

# ATDD-1.4-12: cls references htu-text-logo (AC-3) — REPOINTED 2026-06-15 (Story 3.1, Decision 2)
# SUPERSEDED traceability: Story 1.4 originally asserted BOTH htu-logo (corner) AND htu-text-logo (centered)
# are referenced. Story 3.1 AC-2 (doctoral cover rewrite, reference PDF page 2 + .doc blank form) intentionally
# REMOVED the corner htu-logo — the HTU reference cover has NO corner logo, only the centered calligraphic
# name (htu-text-logo). The htu-logo FILE still exists in figures/ (not deleted; may be used elsewhere),
# it is just no longer rendered on the doctoral cover. This assertion is repointed to guard the cover's
# ACTUAL logo (htu-text-logo) per Story 3.1's reference-anchored reality. Cross-story override per Epic 2
# retro Decision 2 (same pattern as Story 3.9 classify_font / retired ATDD-1.1-08, 1.5-05).
test_htu_logo_refs() {
  [[ -f "htuthesis.cls" ]] || return 1
  local text_logo_ref
  # grep CODE lines only (exclude comments) — mirrors the ATDD-3.9-02 fix (commit 004e20e): prevents
  # a future [基础] comment mentioning "htu-text-logo" from inflating the count and false-passing if the
  # real \includegraphics were ever removed.
  text_logo_ref=$(grep -v '^[[:space:]]*%' htuthesis.cls | grep -c 'htu-text-logo' 2>/dev/null || true)
  text_logo_ref=$(echo "$text_logo_ref" | tr -d '[:space:]' | head -1)
  echo "  (htu-text-logo CODE refs: $text_logo_ref; htu-logo corner refs intentionally 0 per Story 3.1 AC-2)"
  [[ "$text_logo_ref" -ge 1 ]]
}
run_test "P2" "ATDD-1.4-12" "cls references htu-text-logo (AC-3; REPOINTED Story 3.1 — corner htu-logo removed per reference)" test_htu_logo_refs

# ATDD-1.4-13: .def has identity parameters in user zone (AC-1)
test_def_identity_params() {
  [[ -f "htuthesis.def" ]] || return 1
  local schoolname schoolname_en schoolcode
  schoolname=$(grep -c 'htu@schoolname{河南师范大学}' htuthesis.def 2>/dev/null || true)
  schoolname_en=$(grep -c 'htu@schoolname@en{Henan Normal University}' htuthesis.def 2>/dev/null || true)
  schoolcode=$(grep -c 'htu@schoolcode@value{10476}' htuthesis.def 2>/dev/null || true)
  echo "  (schoolname: $schoolname, schoolname_en: $schoolname_en, schoolcode: $schoolcode)"
  [[ "$schoolname" -ge 1 ]]
}
run_test "P2" "ATDD-1.4-13" ".def has identity parameters (AC-1)" test_def_identity_params

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
  echo "   Tests are expected to FAIL until implementation is complete"
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
