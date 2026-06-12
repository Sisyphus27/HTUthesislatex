#!/usr/bin/env bash
# test-story-1.2-unit.sh — ATDD Red-Phase Unit Tests for Story 1.2
# TDD Phase: RED (all tests expected to FAIL before implementation)
#
# Usage: bash tests/test-story-1.2-unit.sh [--run]
#   --run    Remove SKIP markers (for green-phase verification)
#
# Priority: P0 tests are blocking; P1/P2 are best-effort
# Linked Risk: E1-R4 (Parameter externalization breaks cls references, Score 4)

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
echo "ATDD Unit Tests: Story 1.2 — Externalize format parameters"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests (Must Pass — 100%)
# ==========================================
echo "=== P0: File and Structure Tests ==="

# ATDD-1.2-01: htuthesis.def exists and is non-empty (AC-1)
test_def_exists() {
  [[ -f "htuthesis.def" ]] && [[ -s "htuthesis.def" ]]
}
run_test "P0" "ATDD-1.2-01" "htuthesis.def exists and is non-empty" test_def_exists

# ATDD-1.2-02: \input{htuthesis.def} present in cls (AC-2)
test_input_def_in_cls() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -q 'input{htuthesis.def}' htuthesis.cls 2>/dev/null
}
run_test "P0" "ATDD-1.2-02" "cls contains \\input{htuthesis.def}" test_input_def_in_cls

# ATDD-1.2-03: Load position after all \RequirePackage (AC-2)
test_def_load_position() {
  [[ -f "htuthesis.cls" ]] || return 1
  # Find line number of \input{htuthesis.def}
  local input_line
  input_line=$(grep -n 'input{htuthesis.def}' htuthesis.cls 2>/dev/null | head -1 | cut -d: -f1)
  [[ -n "$input_line" ]] || return 1
  # Find last \RequirePackage line
  local last_require
  last_require=$(grep -n 'RequirePackage' htuthesis.cls 2>/dev/null | tail -1 | cut -d: -f1)
  [[ -n "$last_require" ]] || return 1
  # input_line must be > last_require (loaded after all packages)
  [[ "$input_line" -gt "$last_require" ]]
  echo "  (\\input at line $input_line, last RequirePackage at line $last_require)"
}
run_test "P0" "ATDD-1.2-03" "def loaded after all RequirePackage calls" test_def_load_position

# ATDD-1.2-04: No hardcoded format values in cls (AC-3)
# Excludes: font size definition block (lines 183-203), structural options,
#           cover section (lines 499-708), identity strings (Story 1.4 scope)
test_no_hardcoded_format_values() {
  [[ -f "htuthesis.cls" ]] || return 1
  # Check geometry lines for hardcoded values (should use \htu@leftmargin etc.)
  local geo_hardcoded
  # geometry{left= and geometry{top= should NOT have raw mm values
  geo_hardcoded=$(grep -n 'geometry{.*left=[0-9]' htuthesis.cls 2>/dev/null | grep -v 'htu@' | wc -l)
  geo_hardcoded=$(echo "$geo_hardcoded" | tr -d '[:space:]')
  [[ "$geo_hardcoded" -eq 0 ]] || { echo "  (Found $geo_hardcoded hardcoded geometry values)"; return 1; }

  # Check \normalsize redefinition for hardcoded fontsize/baselineskip
  local font_hardcoded
  font_hardcoded=$(grep -n 'setfontsize.*normalsize.*[0-9]bp' htuthesis.cls 2>/dev/null | grep -v 'htu@' | wc -l)
  font_hardcoded=$(echo "$font_hardcoded" | tr -d '[:space:]')
  [[ "$font_hardcoded" -eq 0 ]] || { echo "  (Found $font_hardcoded hardcoded fontsize values)"; return 1; }
}
run_test "P0" "ATDD-1.2-04" "No hardcoded format values in cls geometry/fontsize" test_no_hardcoded_format_values

echo ""

# ==========================================
# P1 Tests (>=95%)
# ==========================================
echo "=== P1: Parameter Completeness ==="

# ATDD-1.2-05: .def defines expected \htu@* macros (AC-3)
# Must have at least the 16 user-zone + 17 advanced-zone = 33 parameters
test_def_macro_count() {
  [[ -f "htuthesis.def" ]] || return 1
  local count
  count=$(grep -c '\\def\\htu@' htuthesis.def 2>/dev/null || true)
  count=$(echo "$count" | tr -d '[:space:]' | head -1)
  echo "  (Found $count \\htu@* macros in .def)"
  [[ "$count" -ge 30 ]]  # Allow slight variance but expect ~33
}
run_test "P1" "ATDD-1.2-05" "htuthesis.def defines >= 30 \\htu@* macros" test_def_macro_count

# ATDD-1.2-06: cls references the key \htu@* variables (AC-3)
test_cls_variable_refs() {
  [[ -f "htuthesis.cls" ]] || return 1
  # Check for key variable references in cls
  local refs_found=0
  local refs_total=4

  grep -q 'htu@leftmargin' htuthesis.cls 2>/dev/null && ((refs_found++))
  grep -q 'htu@topmargin' htuthesis.cls 2>/dev/null && ((refs_found++))
  grep -q 'htu@body@fontsize' htuthesis.cls 2>/dev/null && ((refs_found++))
  grep -q 'htu@body@baselineskip' htuthesis.cls 2>/dev/null && ((refs_found++))

  echo "  (Found $refs_found/$refs_total key variable refs in cls)"
  [[ "$refs_found" -ge "$refs_total" ]]
}
run_test "P1" "ATDD-1.2-06" "cls references key \\htu@* variables" test_cls_variable_refs

echo ""

# ==========================================
# P2 Tests (Best-Effort)
# ==========================================
echo "=== P2: Documentation Quality ==="

# ATDD-1.2-08: .def has user-zone / advanced-zone boundary comments (AC-5)
test_zone_comments() {
  [[ -f "htuthesis.def" ]] || return 1
  # Check for user-zone marker (Chinese or English)
  grep -q '用户区\|User Zone' htuthesis.def 2>/dev/null || return 1
  # Check for advanced-zone marker
  grep -q '高级区\|Advanced Zone' htuthesis.def 2>/dev/null || return 1
}
run_test "P2" "ATDD-1.2-08" "htuthesis.def has user-zone and advanced-zone comments" test_zone_comments

# ATDD-1.2-09: Parameters have truth-source annotations (AC-6)
test_truth_source_annotations() {
  [[ -f "htuthesis.def" ]] || return 1
  # Check for truth-source patterns: [基础], [派生], 真值来源, or zzuthesis
  local annotated
  annotated=$(grep -cE '\[基础\]|\[派生\]|真值来源|zzuthesis' htuthesis.def 2>/dev/null || true)
  annotated=$(echo "$annotated" | tr -d '[:space:]' | head -1)
  echo "  (Found $annotated truth-source annotations)"
  [[ "$annotated" -ge 10 ]]  # At least 10 parameters annotated
}
run_test "P2" "ATDD-1.2-09" "htuthesis.def has truth-source annotations (>= 10)" test_truth_source_annotations

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
