#!/usr/bin/env bash
# test-story-3.13-unit.sh — ATDD Unit Tests for Story 3.13 (spec-priority correction pack — §2.8/2.10/2.11-2.12/2.14/2.15)
# TDD Phase: RED — RED drivers assert the 5 spec-priority corrections' WIRING (FAIL pre-impl, PASS post-impl).
#             Pre-impl state (baseline commit 6a3b2cf, post-Story 3.12 = the reference-wins hierarchy): heading
#             Arabic numbering (name=\relax, cls:454) + caption fullwidth colon ： (cls:388, Story 3.6) + KEY WORDS
#             non-bold (cls:895, Story 3.4) + refs hanging-direction NEUTRAL placeholder (cls:937 "Story 3.13 范围")
#             + chapter aftername=\hskip\ccwd half-space (cls:451, natural-science spacing). Post-impl (spec-priority,
#             CLAUDE.md Decision 4 corrected 2026-06-17): humanities numbering (第一章/第一节/一、) + caption half-space
#             (\hspace{0.5\ccwd}) + KEY WORDS bold (\bfseries) + refs standard hanging (序号左顶格) + aftername no-space.
#             The 7 RED drivers FAIL pre-impl; 3 GREEN guards (appendix centered / \thechapter-not-Chinese / float
#             counter Arabic) PASS pre+post — the AC-3a linchpin guards.
#
# Usage: bash tests/test-story-3.13-unit.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P0 (AC-3 chapter humanities + AC-4 caption half-space + AC-5 KEY WORDS bold — the core wiring) +
#           P1 (AC-3 section/subsection humanities + aftername no-space + AC-1 refs-hanging comment resolved +
#                AC-2/AC-3a GREEN guards)
# Linked ACs: AC-1 (refs standard hanging), AC-2 (appendix centered), AC-3 (humanities numbering 第一章/第一节/一、),
#             AC-3a (float counter stays Arabic — \thechapter NOT redefined), AC-4 (caption half-space), AC-5 (KEY WORDS bold)
# Linked Risk: R-13-new (score 4 — Chinese display × Arabic float counter; AC-3a guards 09/10), R-12 (score 4 — -g recompile),
#              R-cross-story (3 — ATDD repoint of 3.4/3.6/3.7/3.12/2.5/2.6)
# TC coverage: TC-E3-51 (refs hanging), TC-E3-52 (appendix centered source-level), TC-E3-53 (humanities numbering),
#              TC-E3-54 (caption half-space), TC-E3-23 rework (KEY WORDS bold)
#
# NOTE: source-greps prove the WIRING (ctex humanities config, caption \hspace{0.5\ccwd}, \bfseries label, aftername
#   no-space, refs-hanging resolved). The fitz behavior tests (test-story-3.13-integration.sh) prove the RENDERED
#   humanities headings + caption half-space + bold KEY WORDS + standard-hanging refs + figures-still-图1-1. A
#   source-grep alone does NOT prove \thechapter stayed Arabic (Decision 1) — the AC-3a guards 09/10 + integration I05
#   are the proof. The GREEN guards 08/09/10 lock-in the by-construction-correct mechanisms (appendix centered,
#   \thechapter Arabic, float counter Arabic) so a regression is caught.
#
# Truth source: 河南师范大学研究生学位论文格式要求.md §2.8 line 223 (KEY WORDS 加粗) + §2.10 line 239-243 (humanities
#   numbering + 不空格) + §2.11 line 253 / §2.12 line 269 (空半格) + §2.14 line 293 (序号左顶格) + §2.15 line 437
#   (appendix centered). spec is PRIORITY (CLAUDE.md Decision 4, corrected 2026-06-17). Reference PDF deviates on 4
#   of 5 (reverse-hanging refs p227, left-aligned appendix, non-bold KEY WORDS p9, fullwidth-colon captions) — all
#   OVERRIDDEN by spec; AGREES on 1 (humanities numbering). See sprint-change-proposal-2026-06-17.md gaps M2/M3/M4/1a/1b.

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

# --- Story 3.15 Red-Phase Gate (wrong-target-AC refactor — G1–G6) ---
# These unit source-greps prove the WIRING the integration fitz tests render (G3 numbering= option declaration).
# Isolated from the global SKIP so the existing baseline is preserved while Story 3.15 code is pending (backlog).
# Activate: ATDD_315_SKIP=0 bash tests/test-story-3.13-unit.sh --run
SKIP_315="${ATDD_315_SKIP:-1}"
run_test_315() {
  local priority="$1"; local test_id="$2"; local description="$3"
  if [[ "$SKIP_315" == "1" ]]; then
    yellow "[$priority] $test_id: $description  [Story 3.15 RED-phase]"
    ((SKIP_COUNT++)); return 0
  fi
  shift 3; "$@"
  if [[ $? -eq 0 ]]; then green "[$priority] $test_id: $description"; ((PASS++)) || true
  else red "[$priority] $test_id: $description"; ((FAIL++)); fi
}

echo "=============================================="
echo "ATDD Unit Tests: Story 3.13 — spec-priority correction pack (§2.8/2.10/2.11-2.12/2.14/2.15)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P0 Tests — core wiring RED drivers (AC-3 chapter humanities + AC-4 caption half-space + AC-5 KEY WORDS bold)
# ==========================================
echo "=== P0: AC-3 chapter humanities + AC-4 caption half-space + AC-5 KEY WORDS bold (RED drivers) ==="

# ATDD-3.13-01: chapter humanities numbering (AC-3 §2.10) — RED driver
# Pre-impl: cls chapter block has name=\relax (cls:454), no number= key → Arabic "1". → FAIL.
# Post-impl: name={第,章} + number=\chinese{chapter} → "第一章" → PASS. Require BOTH the Chinese name + the \chinese number.
test_chapter_humanities() {
  [[ -f "htuthesis.cls" ]] || return 1
  # number=\chinese{chapter} (Chinese display number) AND a 第…章 name prefix/suffix
  grep -vE '^\s*%' htuthesis.cls | grep -qE 'number=\\chinese\{chapter\}' && \
  grep -vE '^\s*%' htuthesis.cls | grep -qE 'name=\{第,章\}|name=\{第，章\}'
}
run_test "P0" "ATDD-3.13-01" "chapter humanities numbering name={第,章} + number=\\chinese{chapter} (AC-3 §2.10; RED — pre-impl name=\\relax Arabic)" test_chapter_humanities

# ATDD-3.13-02: caption separator = half-space (NOT fullwidth colon) (AC-4 §2.11/§2.12) — RED driver
# Pre-impl: cls:388 \DeclareCaptionLabelSeparator{htu}{：} (fullwidth colon U+FF1A, Story 3.6) → FAIL.
# Post-impl: {htu}{\hspace{0.5\ccwd}} (half-grid) → PASS. Assert the colon gone + half-space present.
test_caption_halfspace() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -vE '^\s*%' htuthesis.cls | grep -qE 'DeclareCaptionLabelSeparator\{htu\}\{[^}]*hspace\{0\.5\\ccwd\}[^}]*\}' && \
  ! grep -vE '^\s*%' htuthesis.cls | grep -qE 'DeclareCaptionLabelSeparator\{htu\}\{：\}'
}
run_test "P0" "ATDD-3.13-02" "caption separator = \\hspace{0.5\\ccwd} (NOT fullwidth ：) (AC-4 §2.11/2.12; RED — pre-impl ：)" test_caption_halfspace

# ATDD-3.13-03: KEY WORDS label bold (AC-5 §2.8) — RED driver
# Pre-impl: cls:895 \htu@put@keywords{\htu@ekeywords@title}{...} (no \bfseries, Story 3.4 non-bold) → FAIL.
# Post-impl: \htu@put@keywords{\bfseries\htu@ekeywords@title}{...} (label bold) → PASS.
test_keywords_bold() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -vE '^\s*%' htuthesis.cls | grep -qE '\\htu@put@keywords\{\\bfseries\\htu@ekeywords@title\}'
}
run_test "P0" "ATDD-3.13-03" "KEY WORDS label bold (\\bfseries\\htu@ekeywords@title) (AC-5 §2.8; RED — pre-impl non-bold)" test_keywords_bold

echo ""

# ==========================================
# P1 Tests — AC-3 section/subsection humanities + aftername no-space (RED drivers)
# ==========================================
echo "=== P1: AC-3 section/subsection humanities + aftername no-space (RED drivers) ==="

# ATDD-3.13-04: section humanities numbering (AC-3 §2.10) — RED driver
# Pre-impl: cls section block name=\relax → "1.1". Post-impl: name={第,节} + number=\chinese{section} → "第一节".
test_section_humanities() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -vE '^\s*%' htuthesis.cls | grep -qE 'number=\\chinese\{section\}' && \
  grep -vE '^\s*%' htuthesis.cls | grep -qE 'name=\{第,节\}|name=\{第，节\}'
}
run_test "P1" "ATDD-3.13-04" "section humanities numbering name={第,节} + number=\\chinese{section} (AC-3; RED — pre-impl Arabic)" test_section_humanities

# ATDD-3.13-05: subsection humanities numbering (一、) (AC-3 §2.10) — RED driver
# Pre-impl: cls subsection name=\relax → "1.1.1". Post-impl: name={,、} + number=\chinese{subsection} → "一、".
test_subsection_humanities() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -vE '^\s*%' htuthesis.cls | grep -qE 'number=\\chinese\{subsection\}' && \
  grep -vE '^\s*%' htuthesis.cls | grep -qE 'name=\{,、\}|name=\{，、\}'
}
run_test "P1" "ATDD-3.13-05" "subsection humanities numbering name={,、} + number=\\chinese{subsection} (AC-3; RED — pre-impl Arabic)" test_subsection_humanities

# ATDD-3.13-06: chapter aftername NO half-space (AC-3 §2.10 humanities 不空格) — RED driver
# Pre-impl: cls:451 aftername=\hskip\ccwd (half-space, natural-science spacing) → FAIL (asserting absent).
# Post-impl: aftername={} (or removed) — humanities 不空格 → PASS. (\hskip\ccwd is unique to the chapter aftername line.)
test_aftername_nospace() {
  [[ -f "htuthesis.cls" ]] || return 1
  ! grep -vE '^\s*%' htuthesis.cls | grep -qE 'aftername=\\hskip\\ccwd'
}
run_test "P1" "ATDD-3.13-06" "chapter aftername NO half-space (humanities 不空格) (AC-3 §2.10; RED — pre-impl aftername=\\hskip\\ccwd)" test_aftername_nospace

# ATDD-3.13-07: refs hanging-direction resolved (AC-1 §2.14 序号左顶格) — RED driver
# Pre-impl: cls 参考文献环境 comment tags "(悬挂方向 = Story 3.13 范围)" = DEFERRED/NEUTRAL placeholder. → FAIL.
# Post-impl: either an explicit \setlength{\bibhang} (standard hanging) is set, OR the deferral marker is resolved.
# (Honest "verify-only" framing per story R-new: gb7714-2015 default may already be standard 序号左顶格; if so the
#  dev just resolves the comment. Covers both the explicit-\bibhang path and the confirm-default path.)
test_refs_hanging_resolved() {
  [[ -f "htuthesis.cls" ]] || return 1
  # Path A: explicit \bibhang standard-hanging config set → resolved.
  if grep -vE '^\s*%' htuthesis.cls | grep -qE '\\setlength\{\\bibhang\}'; then
    return 0
  fi
  # Path B: deferral marker removed (resolved). Pre-impl cls 参考文献环境 comment has "(悬挂方向 = Story 3.13 范围)".
  #   Post-impl resolves it → marker gone. Assert the hanging-direction deferral tag is NO LONGER present.
  ! grep -qE '悬挂方向.{0,8}(=|为).{0,8}(Story )?3\.13' htuthesis.cls
}
run_test "P1" "ATDD-3.13-07" "refs hanging-direction resolved (序号左顶格 standard; \\bibhang OR deferral-marker-gone) (AC-1 §2.14; RED — pre-impl neutral placeholder)" test_refs_hanging_resolved

echo ""

# ==========================================
# P1 Tests — GREEN guards (AC-2 appendix centered / AC-3a \thechapter-not-Chinese / float counter Arabic)
# ==========================================
echo "=== P1: GREEN guards (AC-2 appendix centered / AC-3a \\thechapter-not-Chinese / float counter Arabic) ==="

# ATDD-3.13-08: appendix centered mechanism intact (AC-2 §2.15) — GREEN guard
# The appendix chapter inherits the ctex chapter centered format (format+=\centering in backmatter cls:148) + the
#   appendix env (cls:986). Already correct by construction. GREEN pre+post (regression watch).
test_appendix_centered_mechanism() {
  [[ -f "htuthesis.cls" ]] || return 1
  # chapter centered (format+=\centering OR chapter format has \centering) AND appendix env present
  grep -vE '^\s*%' htuthesis.cls | grep -qE 'chapter/format\+=\\centering|chapter=\{[^}]*\\centering' && \
  grep -vE '^\s*%' htuthesis.cls | grep -qE '\\renewenvironment\{appendix\}'
}
run_test "P1" "ATDD-3.13-08" "appendix centered mechanism intact (AC-2 §2.15; GREEN — by construction; rendered=4.1)" test_appendix_centered_mechanism

# ATDD-3.13-09: \thechapter NOT redefined to Chinese (AC-3a linchpin) — GREEN guard
# The AC-3a guardrail: the dev uses ctex number= DISPLAY key only; \thechapter stays \arabic{chapter}. If the dev
#   mistakenly does \renewcommand{\thechapter}{\chinese{chapter}}, floats break to 图 一-1 → this guard catches it.
#   Pre+post GREEN (guardrail holds). RED = the disaster happened.
test_thechapter_not_chinese() {
  [[ -f "htuthesis.cls" ]] || return 1
  ! grep -vE '^\s*%' htuthesis.cls | grep -qE '\\renewcommand\s*\{?\\thechapter\}?\s*\{[^}]*\\chinese'
}
run_test "P1" "ATDD-3.13-09" "\\thechapter NOT redefined to Chinese (AC-3a linchpin guard; GREEN — guardrail holds; RED = floats broke to 图 一-1)" test_thechapter_not_chinese

# ATDD-3.13-10: float counter Arabic mechanism intact (AC-3a) — GREEN guard
# \thefigure/\thetable/\theequation use \thechapter + \@arabic\c@<X> + \htu@counter@separator (cls:413-418). The
#   humanities switch must NOT touch these. GREEN pre+post. Match the 3 components separately (the cls line has
#   \thechapter\htu@counter@separator\fi\@arabic\c@figure — the \fi sits between separator and \@arabic).
test_float_counter_arabic() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -vE '^\s*%' htuthesis.cls | grep -qE 'renewcommand\\thefigure' && \
  grep -vE '^\s*%' htuthesis.cls | grep -qE '\\thechapter\\htu@counter@separator' && \
  grep -vE '^\s*%' htuthesis.cls | grep -qE '\\@arabic\\c@figure'
}
run_test "P1" "ATDD-3.13-10" "float counter \\thefigure = \\thechapter-\\@arabic (AC-3a; GREEN — mechanism intact; figures stay 图 1-1)" test_float_counter_arabic

echo ""

# ==========================================
# Story 3.15 Red-Phase — G3 numbering=sc option declaration (§2.10, TC-E3-63 wiring)
# ==========================================
echo "=== Story 3.15 RED: G3 numbering=sc option declared (NS-path restore, §2.10; RED pre-impl — 3.13 deleted NS) ==="

# ATDD-3.13-11 (Story 3.15): SOURCE-LEVEL — numbering=sc option declared (G3 NS-path restore, TC-E3-63 wiring)
# WRONG-TARGET-AC complement: integration I14 proves numbering=sc RENDERS NS chapter 1/2; this unit grep proves the
#   OPTION IS DECLARED (the wiring). Spec §2.10 line 235 lists natural-science "1、1.1、1.1.1" as the PRIMARY path;
#   Story 3.13 DELETED it (cls:447-498 "NS deleted"); G3 restores it as a `numbering=sc|hs` cls option (default hs).
#   Pre-impl: no \DeclareOption{numbering=sc} → RED. Post-impl: option declared → GREEN.
#   (Canonical form: \DeclareOption{numbering=sc}{...}. Dev may also declare numbering=hs + set a default; the sc
#   declaration is the G3 NS-restore proof. Repoint if the dev uses a different option mechanism — keyval/\newif.)
test_numbering_sc_option_declared() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -vE '^\s*%' htuthesis.cls | grep -qE 'DeclareOption\{numbering=sc\}'
}
run_test_315 "P1" "ATDD-3.13-11" "SOURCE-LEVEL: numbering=sc option declared (G3 NS-path restore, TC-E3-63 wiring, §2.10; RED pre-impl — 3.13 deleted NS)" test_numbering_sc_option_declared

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
  echo "   RED drivers (FAIL pre-impl reference-wins, PASS post-impl spec-priority):"
  echo "      3.13-01 chapter humanities name={第,章} number=\\chinese{chapter} (AC-3 §2.10)"
  echo "      3.13-02 caption separator \\hspace{0.5\\ccwd} NOT ： (AC-4 §2.11/2.12)"
  echo "      3.13-03 KEY WORDS label bold \\bfseries (AC-5 §2.8)"
  echo "      3.13-04 section humanities name={第,节} (AC-3)"
  echo "      3.13-05 subsection humanities name={,、} (AC-3)"
  echo "      3.13-06 chapter aftername NO half-space (AC-3 humanities 不空格)"
  echo "      3.13-07 refs hanging-direction resolved 序号左顶格 (AC-1 §2.14)"
  echo "   GREEN guards (PASS pre+post — by-construction mechanism lock-in / AC-3a linchpin):"
  echo "      3.13-08 appendix centered mechanism (AC-2 §2.15)"
  echo "      3.13-09 \\thechapter NOT Chinese (AC-3a linchpin — RED = floats broke to 图 一-1)"
  echo "      3.13-10 float counter \\thefigure Arabic mechanism (AC-3a)"
  echo ""
  echo "   Pre-impl baseline (commit 6a3b2cf, post-Story 3.12 = reference-wins): Arabic heading numbering (name=\\relax"
  echo "      cls:454) + caption ： (cls:388 Story 3.6) + KEY WORDS non-bold (cls:895 Story 3.4) + aftername=\\hskip\\ccwd"
  echo "      (cls:451) + refs-hanging NEUTRAL placeholder (cls:937 'Story 3.13 范围'). NONE of the spec-priority wiring"
  echo "      exists → all 7 RED drivers FAIL pre-impl. Post-impl (spec-priority, CLAUDE.md 2026-06-17) → GREEN."
  echo "   NOTE: these source-greps prove the WIRING. The fitz behavior tests (test-story-3.13-integration.sh) prove the"
  echo "      RENDERED humanities headings + caption half-space + bold KEY WORDS + standard-hanging refs + figures-still-"
  echo "      图1-1 (the AC-3a rendered proof, Decision 1)."
  echo "      spec §2.8 line 223 (KEY WORDS 加粗) + §2.10 (humanities) + §2.11/2.12 (空半格) + §2.14 line 293 (序号左顶格)"
  echo "      + §2.15 line 437 (appendix centered). R-13-new = 4 (AC-3a); R-12 = 4 (-g recompile)."
  echo "      Reference PDF deviates on 4 of 5 — all OVERRIDDEN by spec (PRIORITY). Tests are read-only (no SUT mutation)."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
