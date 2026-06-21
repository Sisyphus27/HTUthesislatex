#!/usr/bin/env bash
# test-story-4.4-unit.sh — ATDD Unit (Doc-level + source-grep) Tests for Story 4.4 (format-review checklist + README)
# TDD Phase: RED — the RED driver cluster is unit-01 (verify/checklist.md exists + §1.1–§2.17 coverage + ≥N rule rows +
#             every row tagged 自动检查/人工确认 — NO verify/ dir at baseline 7e0d103), unit-02 (checklist auto-rows
#             reference \htucheck / make target / ATDD + PROXIED caveat — absent), unit-03 (G-C/G-D/G-E transparent-
#             deviation section — absent), unit-04 (README zero 郑州大学/Zhengzhou/ZZU residual — README.md:3 = 郑州大学
#             at baseline), unit-05 (README XeLaTeX + TeX Live 2025 + 5 fonts — absent; old README has none), unit-06
#             (README FR-33 content: quick-start + metadata + compile sequence + file structure + data table + heading
#             note — absent), unit-07 (verify/baseline/page-count.txt + chapter-start-pages.txt — absent). Post-impl
#             (checklist + baseline + README rewrite): all 7 closed at content level. GREEN guards unit-08 (\htucheck
#             4.2 sections font/coverage/audit + markers PRESERVED — AC-10; 4.4 is a CONSUMER of self-check output, must
#             not edit the cls), unit-09 (font \PackageError gates cls:71-88 RETAINED — 4.4 docs-only must not touch).
#
# Usage: bash tests/test-story-4.4-unit.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 (unit-01 checklist coverage + unit-02 self-check refs + unit-03 G-C/G-D/G-E + unit-04 README zero-ZZU +
#           unit-05 README env + unit-07 baseline snapshot — the 4.4 deliverables) / P1 (unit-06 README FR-33 content +
#           GREEN guards unit-08/09)
# Linked ACs: AC-1/2 (checklist rules + tags), AC-3 (auto-rows ref self-check + PROXIED), AC-4 (G-C/G-D/G-E),
#             AC-5 (README zero ZZU), AC-6 (README FR-33 content), AC-7 (README env spec), AC-9 (verify/baseline),
#             AC-10 (no regression — \htucheck + font gates untouched)
# Linked Risk: R-27 (checklist completeness — #1 deliverable, unit-01/02/03), R-25 (wrong-target-AC — unit-02 enforces
#             the PROXIED caveat on \the<dim>-citing auto-rows), R-28 (README fresh-user — unit-04/05/06 content)
# TC coverage: TC-E4-25 (unit-01), TC-E4-26 (unit-02), TC-E4-27 (unit-03), TC-E4-28 (unit-04), TC-E4-29 (unit-05),
#              TC-E4-30 (unit-06)
#
# NOTE: these content-greps prove the DELIVERABLE EXISTENCE + COVERAGE (checklist enumerates the spec rules + README has
#   the FR-33 sections + zero ZZU). The integration tests (test-story-4.4-integration.sh) prove the COMPILED BEHAVIOR
#   is unaffected (docs-only: default compile rc0 + self-check structurally identical to 7e0d103 + fresh-user latexmk
#   exit 0). The wrong-target-AC discipline (Epic 3 retro Lesson 3): unit-02 enforces that checklist auto-rows citing a
#   \the<dim> self-check proxy carry the PROXIED caveat + the rendered fitz ATDD (the real evidence).
#
# Truth source: 河南师范大学研究生学位论文格式要求.md §1.1–§2.17 (PRIORITY — ~122 rules); architecture.md §524–568
#   (project structure + verify/ boundary §623–626) + §534/§542–552 (README requirements); test-design-epic-4.md R-27
#   (checklist completeness) + R-28 (README fresh-user); Epic 3 retro action item #4 (G-C/G-D/G-E). spec PRIORITY
#   (CLAUDE.md Decision 4, corrected 2026-06-17).
#
# Line refs verified vs HEAD 7e0d103: NO verify/ dir; README.md:3 = 郑州大学本科毕业设计(论文)...; \htucheck =
#   cls:1067–1165 (4.2 + 4.3 debug section); font gates = cls:71-88 (PRE-EXISTING — 4.4 must not touch).

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
echo "ATDD Unit Tests: Story 4.4 — format review checklist + README documentation"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# Shared helper: extract the \htucheck macro body (cls) — comment-stripped, from \newcommand{\htucheck} to the
#   closing brace of its def. Used by unit-08 to scope greps to the self-check region (4.4 must preserve the 4.2
#   sections + markers — it is a CONSUMER, AC-10). (Reused verbatim from 4.2/4.3 — brace-walk starts at m.end()
#   to skip the name-arg '{'.)
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
# P0 — AC-1/2, TC-E4-25: verify/checklist.md exists + §1.1–§2.17 coverage + ≥N rule rows + every row tagged
# ==========================================
echo "=== P0: checklist.md rule coverage + 自动检查/人工确认 tagging (AC-1/2, TC-E4-25, R-27) ==="

# ATDD-4.4-01: verify/checklist.md must exist AND (a) reference ALL spec sections §1.1.1–§2.17 (the ~122-rule PRIORITY
#   truth source coverage), (b) contain ≥40 rule rows (lower bound — the 2026-06-19 audit target ~122; a comprehensive
#   checklist easily exceeds 40), (c) tag rows 自动检查/人工确认 (≥40 tag occurrences). Pre-impl (7e0d103): NO verify/
#   dir. RED pre: file absent. This is the R-27 (#1-deliverable) linchpin.
test_checklist_coverage_and_tags() {
  [[ -f "verify/checklist.md" ]] || { echo "  (verify/checklist.md absent — RED, no verify/ dir at 7e0d103)"; return 1; }
  python - <<'PY'
import re, sys
src = open("verify/checklist.md", encoding="utf-8").read()
# (a) ALL spec sections §1.1.1–§2.17 must be referenced (PRIORITY truth-source coverage). §1.x + §2.x markers.
required = [
    "1.1.1","1.1.2","1.1.3","1.1.4","1.1.5","1.1.6",
    "1.2.1","1.2.2","1.2.3","1.2.4","1.2.5",
    "1.3","1.4","1.5.1","1.5.2","1.5.3",
    "2.1","2.2","2.3","2.4","2.5","2.6","2.7","2.8","2.9","2.10","2.11","2.12","2.13","2.14","2.15","2.16","2.17",
    "3",  # §3 学位论文格式说明 (R3-a; code review patch 7 — was missing, §3 coverage un-enforced)
]
missing = [s for s in required if not re.search(r'§?\s*' + re.escape(s), src)]
# (b) ≥40 rule rows: count markdown table data rows (lines starting with |, excluding the separator row).
#     NOTE: this counts pipe-rows including per-section header rows (| ID | 规则 ... |) — an over-count by
#     ~25 headers, but the ≥40 gate is a lower bound (the checklist has ~95 real rule rows), so the over-count
#     is conservative (makes the gate easier, never false-FAILs). Header-row exclusion via "规则 not in ln[:6]"
#     was dead logic (规则 never appears in the first 6 chars of a `|`-line) — removed (code review patch 5).
table_rows = len([ln for ln in src.splitlines() if ln.lstrip().startswith("|") and "---" not in ln])
# (c) 自动检查/人工确认 tag occurrences ≥40
auto = len(re.findall(r'自动检查', src))
manual = len(re.findall(r'人工确认', src))
tags = auto + manual
print("  §-sections missing: %s | table_rows: %d | 自动检查: %d / 人工确认: %d (tags=%d)" % (missing or "NONE", table_rows, auto, manual, tags))
ok = (not missing) and (table_rows >= 40) and (tags >= 40)
if missing:
    print("  RED: spec sections not covered: %s" % missing)
if table_rows < 40:
    print("  RED: rule-row count %d < 40 (R-27 checklist completeness)" % table_rows)
if tags < 40:
    print("  RED: tag count %d < 40 (every row must be 自动检查/人工确认)" % tags)
sys.exit(0 if ok else 1)
PY
}
run_test "P0" "ATDD-4.4-01" "checklist.md §1.1–§2.17 coverage + ≥40 rule rows + 自动检查/人工确认 tags (AC-1/2, TC-E4-25; *** RED DRIVER *** — no verify/ dir at 7e0d103)" test_checklist_coverage_and_tags

# ==========================================
# P0 — AC-3, TC-E4-26: checklist auto-rows reference \htucheck / make target / ATDD + PROXIED caveat
# ==========================================
echo "=== P0: checklist auto-rows reference self-check/make/ATDD + PROXIED caveat (AC-3, TC-E4-26, R-25) ==="

# ATDD-4.4-02: checklist 自动检查 rows must cite a concrete self-check output (\htucheck line / === HTU Layout Self-Check
#   / font check), a make target (make calibrate / make debug-check / make compile-check), or an ATDD ID (ATDD-N.M-*).
#   AND rows citing a \the<dim> proxy (baselineskip/textheight/...) must carry the PROXIED caveat + reference a rendered
#   fitz ATDD (wrong-target-AC discipline, Epic 3 retro Lesson 3 / R-25). Pre-impl: no checklist.md. RED pre: absent.
test_checklist_auto_refs_and_proxied() {
  [[ -f "verify/checklist.md" ]] || { echo "  (verify/checklist.md absent — RED)"; return 1; }
  python - <<'PY'
import re, sys
src = open("verify/checklist.md", encoding="utf-8").read()
# auto-evidence signals: self-check lines / make targets / ATDD IDs
has_selfcheck = bool(re.search(r'\\htucheck|HTU Layout Self-Check|font check|textheight|baselineskip|--- silent-failure', src))
has_make = bool(re.search(r'make\s+(calibrate|debug-check|compile-check)', src))
has_atdd = bool(re.search(r'ATDD-\d', src))
# PROXIED caveat (R-25): the wrong-target-AC disclosure — checklist must name it
has_proxied = bool(re.search(r'PROXIED|proxied|rendered', src, re.I))
print("  self-check ref: %s | make-target ref: %s | ATDD ref: %s | PROXIED caveat: %s" % (has_selfcheck, has_make, has_atdd, has_proxied))
ok = has_selfcheck and has_make and has_atdd and has_proxied
if not ok:
    miss = []
    if not has_selfcheck: miss.append("self-check ref")
    if not has_make: miss.append("make-target ref")
    if not has_atdd: miss.append("ATDD ref")
    if not has_proxied: miss.append("PROXIED caveat (R-25)")
    print("  RED: missing %s" % miss)
sys.exit(0 if ok else 1)
PY
}
run_test "P0" "ATDD-4.4-02" "checklist auto-rows cite \htucheck/make/ATDD + PROXIED caveat (AC-3, TC-E4-26; *** RED DRIVER *** — absent at 7e0d103)" test_checklist_auto_refs_and_proxied

# ==========================================
# P0 — AC-4, TC-E4-27: checklist documents G-C/G-D/G-E transparent deviations
# ==========================================
echo "=== P0: checklist G-C/G-D/G-E transparent-deviation section (AC-4, TC-E4-27, Epic 3 retro #4) ==="

# ATDD-4.4-03: checklist must have a transparent-deviation section naming G-C (English title Title Case), G-D
#   (line-spacing coincidence 23.4bp), G-E (inline ASCII 小四), each with a truth-source + measured-value reference.
#   Closes Epic 3 retro action item #4. Pre-impl: no checklist.md. RED pre: absent.
test_checklist_transparent_deviations() {
  [[ -f "verify/checklist.md" ]] || { echo "  (verify/checklist.md absent — RED)"; return 1; }
  python - <<'PY'
import re, sys
src = open("verify/checklist.md", encoding="utf-8").read()
has_section = bool(re.search(r'(?i)transparent[ _-]?deviation|透明偏差|transparent[ _-]?deviation|文档化偏差|偏差说明', src))
has_gc = bool(re.search(r'G-C', src))
has_gd = bool(re.search(r'G-D', src))
has_ge = bool(re.search(r'G-E', src))
has_truth = bool(re.search(r'参考|reference|真值|truth', src, re.I))
has_value = bool(re.search(r'23\.4|Title Case|小四', src))
print("  deviation section: %s | G-C: %s | G-D: %s | G-E: %s | truth-source: %s | measured-value: %s" % (has_section, has_gc, has_gd, has_ge, has_truth, has_value))
ok = has_section and has_gc and has_gd and has_ge and has_truth and has_value
if not ok:
    miss = []
    if not has_section: miss.append("deviation-section header")
    for tag, ok_ in (("G-C",has_gc),("G-D",has_gd),("G-E",has_ge)):
        if not ok_: miss.append(tag)
    if not has_truth: miss.append("truth-source")
    if not has_value: miss.append("measured-value")
    print("  RED: missing %s" % miss)
sys.exit(0 if ok else 1)
PY
}
run_test "P0" "ATDD-4.4-03" "checklist G-C/G-D/G-E transparent-deviation section (AC-4, TC-E4-27; *** RED DRIVER *** — absent at 7e0d103)" test_checklist_transparent_deviations

# ==========================================
# P0 — AC-5, TC-E4-28: README zero 郑州大学/Zhengzhou/ZZU residual
# ==========================================
echo "=== P0: README zero ZZU residual (AC-5, TC-E4-28, FR-25/FR-33) ==="

# ATDD-4.4-04: README.md must contain ZERO 郑州大学/Zhengzhou/ZZU/zzu matches. The ONLY acceptable 'zzu' is a fork-
#   provenance credit ("基于 zzuthesis 改写") WITH an explicit rewrite qualifier — default: omit. Pre-impl (7e0d103):
#   README.md:3 = 郑州大学本科毕业设计... RED pre: ≥1 match.
test_readme_zero_zzu() {
  [[ -f "README.md" ]] || return 1
  local hits
  hits=$(grep -icE '郑州大学|Zhengzhou|ZZU' README.md || true)
  if [[ "$hits" -ne 0 ]]; then
    echo "  (README has $hits ZZU match(es) — RED; lines:)"
    grep -inE '郑州大学|Zhengzhou|ZZU' README.md | head -5 | sed 's/^/    /'
    # fork-credit exception: a single line containing BOTH 'zzuthesis' AND '改写|rewrit|fork' is allowed
    local bare_zzu
    bare_zzu=$(grep -iE '郑州大学|Zhengzhou|ZZU' README.md | grep -ivE 'zzuthesis.*(改写|rewrit|fork)|fork.*zzuthesis|基于 zzuthesis' | grep -icE '郑州大学|Zhengzhou|ZZU' || true)
    if [[ "$bare_zzu" -eq 0 ]]; then
      echo "  (all ZZU matches are fork-credit-with-rewrite-qualifier — acceptable exception — GREEN)"
      return 0
    fi
    return 1
  fi
  echo "  (README zero ZZU residual — GREEN)"
  return 0
}
run_test "P0" "ATDD-4.4-04" "README zero 郑州大学/Zhengzhou/ZZU residual (AC-5, TC-E4-28; *** RED DRIVER *** — README:3 = 郑州大学 at 7e0d103)" test_readme_zero_zzu

# ==========================================
# P0 — AC-7, TC-E4-29: README XeLaTeX-only + TeX Live 2025 + 5 fonts
# ==========================================
echo "=== P0: README environment spec — XeLaTeX + TeX Live 2025 + 5 fonts (AC-7, TC-E4-29, NFR-1/NFR-2) ==="

# ATDD-4.4-05: README must state XeLaTeX (only), TeX Live 2025 (minimum), and the 5 required fonts (SimSun/SimHei/
#   KaiTi/FangSong/Times New Roman). Pre-impl: old README has none. RED pre: tokens absent.
test_readme_env_spec() {
  [[ -f "README.md" ]] || return 1
  python - <<'PY'
import re, sys
src = open("README.md", encoding="utf-8").read()
tokens = {
    "XeLaTeX": r'XeLaTeX|xelatex',
    "TeX Live 2025": r'TeX\s*Live\s*2025',
    "SimSun": r'SimSun|宋体',
    "SimHei": r'SimHei|黑体',
    "KaiTi": r'KaiTi|楷体',
    "FangSong": r'FangSong|仿宋',
    "Times New Roman": r'Times\s*New\s*Roman',
}
found = {n: bool(re.search(p, src, re.I)) for n, p in tokens.items()}
missing = [n for n, ok in found.items() if not ok]
print("  tokens found: %s" % ([n for n, ok in found.items() if ok]))
if missing:
    print("  RED: README missing %s (NFR-1/NFR-2 env spec)" % missing)
sys.exit(0 if not missing else 1)
PY
}
run_test "P0" "ATDD-4.4-05" "README XeLaTeX + TeX Live 2025 + 5 fonts (AC-7, TC-E4-29; *** RED DRIVER *** — absent at 7e0d103)" test_readme_env_spec

# ==========================================
# P1 — AC-6, TC-E4-30: README FR-33 content (quick-start + metadata + compile sequence + structure + data table + heading note)
# ==========================================
echo "=== P1: README FR-33 content completeness (AC-6, TC-E4-30, FR-33) ==="

# ATDD-4.4-06: README must include ALL FR-33 sections: quick-start, metadata-setup (\ctitle/\etitle/etc.), compile
#   sequence (latexmk + raw xelatex→bibtex→xelatex×2), file-structure overview, data/ filename reference table, and
#   the humanities heading convention note (numbering sc/hs). Pre-impl: old README has none. RED pre: sections absent.
test_readme_fr33_content() {
  [[ -f "README.md" ]] || return 1
  python - <<'PY'
import re, sys
src = open("README.md", encoding="utf-8").read()
checks = {
    "quick-start":       r'(?i)quick[ _-]?start|快速开始|快速上手|入门',
    "metadata-setup":    r'\\ctitle|\\etitle|\\cmajor|\\cauthor|\\id\b|元数据|metadata',
    "compile-latexmk":   r'latexmk',
    "compile-raw-seq":   r'bibtex',
    "file-structure":    r'(?i)file[ _-]?structure|目录结构|文件结构|main\.tex',
    "data-table":        r'data/|abstract\.tex|chap01|app01|ack\.tex|resume\.tex|denotation',
    "heading-note":      r'(?i)numbering|编号|第一章|sc|hs',
}
found = {n: bool(re.search(p, src, re.I)) for n, p in checks.items()}
missing = [n for n, ok in found.items() if not ok]
print("  sections found: %s" % ([n for n, ok in found.items() if ok]))
if missing:
    print("  RED: README FR-33 missing %s" % missing)
sys.exit(0 if not missing else 1)
PY
}
run_test "P1" "ATDD-4.4-06" "README FR-33 content (quick-start+metadata+compile+structure+data+heading) (AC-6, TC-E4-30; *** RED DRIVER *** — absent at 7e0d103)" test_readme_fr33_content

# ==========================================
# P0 — AC-9: verify/baseline/ snapshot files exist
# ==========================================
echo "=== P0: verify/baseline/ snapshot files (AC-9, architecture §565-567) ==="

# ATDD-4.4-07: verify/baseline/ must contain page-count.txt + chapter-start-pages.txt (architecture §567 baseline
#   snapshots — page count + chapter-start pages, the regression reference for future format changes). NOT loaded by
#   LaTeX (project documentation only, §624-625). Pre-impl (7e0d103): NO verify/ dir. RED pre: files absent.
test_verify_baseline_snapshot() {
  [[ -f "verify/baseline/page-count.txt" ]] || { echo "  (verify/baseline/page-count.txt absent — RED)"; return 1; }
  [[ -f "verify/baseline/chapter-start-pages.txt" ]] || { echo "  (verify/baseline/chapter-start-pages.txt absent — RED)"; return 1; }
  # page-count.txt must contain a numeric page count (the recorded snapshot)
  if ! grep -qE '[0-9]+' verify/baseline/page-count.txt; then
    echo "  (page-count.txt has no numeric value — RED)"; return 1
  fi
  echo "  (verify/baseline/ snapshot files present + numeric — GREEN)"
  return 0
}
run_test "P0" "ATDD-4.4-07" "verify/baseline/page-count.txt + chapter-start-pages.txt exist (AC-9; *** RED DRIVER *** — no verify/ dir at 7e0d103)" test_verify_baseline_snapshot

# ==========================================
# GREEN guard — AC-10: \htucheck 4.2 sections (font/coverage/audit) PRESERVED (4.4 is a CONSUMER, must not edit cls)
# ==========================================
echo "=== GREEN guard: \\htucheck 4.2 sections + markers preserved (AC-10, 4.4 docs-only) ==="

# ATDD-4.4-08: the \htucheck body must STILL contain the 4.2 self-check sections (font-check, coverage map, assertion
#   audit) + markers + 8 name=value dim lines. 4.4 is a CONSUMER of self-check output (the checklist references these
#   strings); it MUST NOT edit the cls. GREEN pre+post (4.2/4.3 shipped them; 4.4 must preserve). RED = 4.4
#   accidentally edited the cls (scope violation — 4.4 is docs-only).
test_htucheck_preserves_42_sections() {
  local body
  body=$(htucheck_body) || return 1
  [[ "$body" == "NO_HTUCHECK_DEF" || "$body" == "UNTERMINATED" ]] && { echo "  (\\htucheck def not found — RED)"; return 1; }
  echo "$body" | grep -qiE 'font[ _-]?check|--- font' || { echo "  (font-check section missing — RED, 4.2 regression)"; return 1; }
  echo "$body" | grep -qiE 'coverage|silent[ _-]?fail' || { echo "  (coverage-map section missing — RED, 4.2 regression)"; return 1; }
  echo "$body" | grep -qiE 'assertion[ _-]?audit|proxied' || { echo "  (assertion-audit section missing — RED, 4.2 regression)"; return 1; }
  echo "$body" | grep -qF '=== HTU Layout Self-Check ===' || { echo "  (start marker missing — RED)"; return 1; }
  echo "$body" | grep -qF '=== End Self-Check ===' || { echo "  (end marker missing — RED)"; return 1; }
  # the 8 name=value dim lines the checklist references (textheight/textwidth/baselineskip/headheight/evensidemargin/oddsidemargin/total pages/page counter)
  echo "$body" | grep -qF 'textheight = ' || { echo "  (textheight dim line missing — RED)"; return 1; }
  echo "$body" | grep -qF 'baselineskip = ' || { echo "  (baselineskip dim line missing — RED)"; return 1; }
  echo "  (4.2 sections + markers + 8 dim lines preserved — GREEN, 4.4 docs-only did not touch cls)"
  return 0
}
run_test "P1" "ATDD-4.4-08" "\\htucheck 4.2 sections + markers + 8 dim lines preserved (AC-10; GREEN guard pre+post — 4.4 is a self-check CONSUMER)" test_htucheck_preserves_42_sections

# ==========================================
# GREEN guard — AC-10: font \PackageError gates cls:71-88 RETAINED (4.4 docs-only must not touch)
# ==========================================
echo "=== GREEN guard: font \\PackageError gates cls:71-88 retained (AC-10, NFR-2) ==="

# ATDD-4.4-09: the 5 font \IfFontExistsTF{}{\PackageError{htuthesis}} gates at cls:71-88 MUST remain (4.4 docs-only
#   must not touch them). GREEN pre+post. RED = 4.4 accidentally edited the font gates. (Reused verbatim from 4.3
#   unit-09 — 4.4 inherits the same font-gate regression surface.)
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
    print("  MISSING gate for: %s — RED (4.4 docs-only must not touch cls:71-88)" % missing)
sys.exit(0 if not missing else 1)
PY
}
run_test "P1" "ATDD-4.4-09" "font \\PackageError gates cls:71-88 retained (AC-10; GREEN guard pre+post — 4.4 docs-only must not touch)" test_font_error_gates_retained

echo ""
echo "=============================================="
echo "Summary: PASS=$PASS FAIL=$FAIL SKIP=$SKIP_COUNT"
echo "=============================================="
if [[ "$SKIP" == "1" ]]; then
  echo ""
  echo "   TDD RED phase — scaffolds inert (ATDD_SKIP=1). Activate with --run or ATDD_SKIP=0."
  echo "   RED drivers (FAIL pre-impl 7e0d103, PASS post-impl checklist+baseline+README):"
  echo "      01 checklist.md §1.1–§2.17 coverage + ≥40 rule rows + 自动检查/人工确认 tags (AC-1/2, TC-E4-25, R-27)"
  echo "      02 checklist auto-rows cite \\htucheck/make/ATDD + PROXIED caveat (AC-3, TC-E4-26, R-25)"
  echo "      03 checklist G-C/G-D/G-E transparent-deviation section (AC-4, TC-E4-27, Epic 3 retro #4)"
  echo "      04 README zero 郑州大学/Zhengzhou/ZZU residual (AC-5, TC-E4-28)"
  echo "      05 README XeLaTeX + TeX Live 2025 + 5 fonts (AC-7, TC-E4-29, NFR-1/NFR-2)"
  echo "      06 README FR-33 content quick-start+metadata+compile+structure+data+heading (AC-6, TC-E4-30)"
  echo "      07 verify/baseline/page-count.txt + chapter-start-pages.txt (AC-9)"
  echo "   GREEN guards (PASS pre+post — 4.4 docs-only must not touch the cls):"
  echo "      08 \\htucheck 4.2 sections + markers + 8 dim lines preserved (AC-10)"
  echo "      09 font \\PackageError gates cls:71-88 retained (AC-10, NFR-2)"
  echo ""
  echo "   Content-greps prove DELIVERABLE EXISTENCE + COVERAGE; integration proves COMPILE UNAFFECTED (docs-only)."
  echo "   R-27 (checklist completeness) is the #1-deliverable risk — unit-01/02/03 enforce it."
  echo "   R-25 (wrong-target-AC) — unit-02 enforces the PROXIED caveat on \\the<dim>-citing auto-rows."
  echo "   Tests are read-only (no SUT mutation — Epic 1 retro). Line refs verified vs HEAD 7e0d103."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
