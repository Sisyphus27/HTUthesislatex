#!/usr/bin/env bash
# test-story-3.8-unit.sh — ATDD Unit Tests for Story 3.8 (Free-form back matter — acknowledgement, papers, footnotes)
# TDD Phase: MIXED — ONE RED driver (footnote per-page reset, R-16) + 3 DECISION-PENDING diagnostics (ack body face,
#             papers title text, papers entry format) + GREEN guards. The ack + papers MACHINERY is INHERITED intact
#             from the original zzuthesis (ack env cls:881-885, resume env cls:941-942); the titles render correctly
#             via \htu@chapter* (致谢 title SimHei 三号 centered confirmed main.pdf p47; papers title SimHei 三号 centered
#             p49). The ONE unambiguous divergence from spec: footnote NUMBERING is per-CHAPTER (ctexbook/book default,
#             \@addtoreset{footnote}{chapter}) but spec §1.2.4 line 109 + the reference PDF require per-PAGE reset —
#             ATDD-3.8-05 is the RED driver (asserts the per-page wiring). The face/title-text/entry-format divergences
#             are DECISION-PENDING (diagnostics; spec governs where the reference is silent — the reference has NO
#             致谢/攻读 anchor). The companion integration suite proves the RENDERED ack/papers/footnotes via fitz.
#
# Usage: bash tests/test-story-3.8-unit.sh [--run]
#   --run    Remove SKIP marker (for green-phase verification)
#
# Priority: P1/P2 (architecture.md:41 = 后置内容 MEDIUM; footnote per-page reset = R-16 score 4). No P0 — compilation
#           passes pre-impl, ack/papers render.
# Linked ACs: AC-1 (致谢 title \htu@chapter*{\htu@ackname}), AC-2 (ack env body face — DECISION-PENDING),
#             AC-3 (papers title text \htu@resume@title — DECISION-PENDING), AC-4 (resume entries — DECISION-PENDING),
#             AC-5 (footnote per-page reset — RED driver; + \footnotesize 小五号), AC-6/7/8 (regression)
# Linked Risk: R-16 (score 4 — footnote per-page reset; ATDD-3.8-05 RED driver), R-12 (score 4 — counter change needs
#              `latexmk -g`; integration I01 runs -g)
# TC coverage: TC-E3-38/39/40/41 (behavior proofs in integration); unit = WIRING guards + the per-page-reset wiring RED driver
#
# NOTE: these are SOURCE-LEVEL greps — they prove the cls CONTAINS the ack/papers/footnote wiring and the invariants
#       are intact. The companion integration test proves the RENDERED ack/papers/footnotes via fitz (致谢 title SimHei
#       三号 centered, papers title, footnote SimSun 9pt, footnote per-page reset). Source-greps prove the wiring;
#       fitz proves the RENDERING (Story 2.5/2.6/3.1-3.7 lesson). Tests are READ-ONLY — MUST NOT modify the SUT
#       (Epic 1/2 retro).
#
# ⚠️ RED driver: ATDD-3.8-05 — the footnote per-page reset. Current cls has NO `\@addtoreset{footnote}{page}` and NO
#    `footmisc` → ctexbook default = per-CHAPTER reset (book class \@addtoreset{footnote}{chapter}). Spec §1.2.4
#    line 109 "每页重新编号" + reference PDF (p15=[3],p18=[1],p19=[2],p20=[1] → per-PAGE) require per-page. This
#    test FAILS pre-impl (no per-page wiring) and PASSES post-impl (the AC-5 fix wires it). The behavior proof is I08.
# ⚠️ DECISION-PENDING: ATDD-3.8-03 (ack body face — fangsong vs songti), ATDD-3.8-04 (papers title text — 个人简历 vs
#    攻读学位), ATDD-3.8-10 (papers entry format — enumerate vs references-style). Spec §2.16/§2.17 governs (reference
#    SILENT); dev-story surfaces to Zy. These are value-agnostic diagnostics here (exit 0, report current); PROMOTED
#    to assertions post-decision (mirror Story 3.7 ATDD-3.7-05/I05/I11).

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
echo "ATDD Unit Tests: Story 3.8 — Free-form back matter (acknowledgement, papers, footnotes)"
echo "TDD Phase: $([ "$SKIP" == "1" ] && echo "RED (skipped)" || echo "ACTIVE")"
echo "=============================================="
echo ""

# ==========================================
# P1 Tests — ack + papers + footnote WIRING
# ==========================================
echo "=== P1: ack/papers/footnote wiring (致谢 title + papers title + footnote size = GREEN; per-page reset = RED) ==="

# ATDD-3.8-01: \htu@chapter*{\htu@ackname} — 致谢 title via the chapter mechanism (AC-1 wiring, TC-E3-38)
# Truth source: spec §2.16 "「致谢」用三号黑体字，居中" + main.pdf p47 (致/谢 SimHei 16pt centered pair). The ack env
#   must render the title via \htu@chapter*{\htu@ackname} (→ \clearpage new-page + chapter format \sffamily\sanhao
#   = 三号黑体居中). GREEN pre/post (inherited zzuthesis).
test_ack_title_chapter() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'htu@chapter\*\{\\htu@ackname\}' htuthesis.cls
}
run_test "P1" "ATDD-3.8-01" "\\htu@chapter*{\\htu@ackname} 致谢 title (AC-1 wiring, TC-E3-38; GREEN — inherited)" test_ack_title_chapter

# ATDD-3.8-02: \htu@ackname = "致\hspace{\ccwd} 谢" (AC-1 — 致谢 with one-space gap per §2.16 "两字间空一格")
# The ack name must render 致 + space + 谢. GREEN pre/post.
test_ackname_zhixie() {
  [[ -f "htuthesis.cls" ]] || return 1
  # cls:210 \newcommand{\htu@ackname}{致\hspace{\ccwd} 谢} — value-brace after the closing arg-brace.
  grep -qE 'htu@ackname\}\{致\\hspace\{\\ccwd\}\s*谢\}' htuthesis.cls
}
run_test "P1" "ATDD-3.8-02" "\\htu@ackname=致\\hspace{\\ccwd} 谢 (AC-1; §2.16 两字间空一格; GREEN)" test_ackname_zhixie

# ATDD-3.8-03: ack env body face (AC-2 — DECISION-PENDING DIAGNOSTIC)
# CURRENT: ack env sets \fangsong\xiaosi[1.524] (cls:884) → 仿宋小四; spec §2.16 line 445 mandates 小四号宋体 (宋体).
#   DECISION-PENDING (the live Decision-4 case): Option A (songti, spec) vs Option B (keep fangsong). Reference is
#   SILENT (no 致谢 anchor) → spec text governs. This is VALUE-AGNOSTIC here (reports the current face, exits 0); the
#   dev-story surfaces the decision to Zy; PROMOTED to a face assertion post-decision (mirror 3.7-05). The behavior
#   proof + face verdict is the integration I05.
test_ack_body_face_diagnostic() {
  [[ -f "htuthesis.cls" ]] || return 1
  # AC-2 Option A RESOLVED 2026-06-16: ack body = 宋体 (\songti\xiaosi); \fangsong removed.
  # The active cmd \fangsong\xiaosi must be gone; the [基础] comment says "用 \fangsong（" (Chinese paren, not \fangsong\xiaosi)
  # so this grep won't false-match the comment. PROMOTED from value-agnostic diagnostic to assert Option A.
  if grep -qE 'fangsong\\xiaosi' htuthesis.cls; then
    echo "  (ack body STILL \\fangsong\\xiaosi — RED; AC-2 Option A requires \\songti\\xiaosi per spec §2.16)"; return 1
  fi
  grep -qE 'songti\\xiaosi' htuthesis.cls && \
    echo "  (ack body = \\songti\\xiaosi → 宋体 per spec §2.16; AC-2 Option A resolved 2026-06-16)"
}
run_test "P1" "ATDD-3.8-03" "ack body face = songti (AC-2 Option A resolved; PROMOTED from diagnostic)" test_ack_body_face_diagnostic

# ATDD-3.8-04: \htu@resume@title DECLARED + text DIAGNOSTIC (AC-3 — title wiring GREEN; title text DECISION-PENDING)
# The resume env title must be wired (\htu@resume@title). GREEN pre/post. The title TEXT is DECISION-PENDING: current
#   "个人简历、在学期间发表的学术论文与研究成果" (cls:211) vs spec §2.17 "攻读学位期间发表的学术论文目录". Reference
#   SILENT → spec governs. Value-agnostic text report here; PROMOTED post-decision. Behavior proof = integration I06.
test_resume_title_wiring() {
  [[ -f "htuthesis.cls" ]] || return 1
  local line
  line=$(grep -E 'newcommand\{\\htu@resume@title\}\{[^}]+\}' htuthesis.cls | head -1)
  if [[ -n "$line" ]]; then
    # extract the title text between the value braces ({...} after resume@title})
    local txt
    txt=$(printf '%s' "$line" | grep -oE 'resume@title\}\{[^}]+\}' | sed 's/^[^{]*{//; s/}$//')
    echo "  (resume title = '$txt')"
    # AC-3 Option A1 RESOLVED 2026-06-16: title text = 攻读学位期间发表的学术论文目录 (spec §2.17). PROMOTED to assert.
    if [[ "$txt" == *"攻读学位"* ]]; then return 0; fi
    echo "  (title text lacks 攻读学位 — RED; AC-3 Option A1 requires spec §2.17 title text)"; return 1
  fi
  return 1
}
run_test "P1" "ATDD-3.8-04" "\\htu@resume@title = 攻读学位 (AC-3 Option A1 resolved; PROMOTED from diagnostic)" test_resume_title_wiring

# ATDD-3.8-05: footnote PER-PAGE RESET wiring — *** THE RED DRIVER *** (AC-5, R-16, TC-E3-41)
# Truth source: spec §1.2.4 line 109 "每页重新编号" + reference PDF (p15=[3],p18=[1],p19=[2],p20=[1] → per-PAGE reset).
#   Current cls has NEITHER `\@addtoreset{footnote}{page}` NOR `footmisc[perpage]` → ctexbook/book default = per-CHAPTER
#   reset (book class \@addtoreset{footnote}{chapter}); main.pdf confirms orphan [2] markers on p19/p47 (a page showing
#   footnote "2" without "1" = per-chapter, impossible under per-page). This test FAILS pre-impl (no per-page wiring)
#   and PASSES post-impl (AC-5 wires \@addtoreset{footnote}{page} Option A OR footmisc Option B). The behavior proof is I08.
test_footnote_perpage_wiring() {
  [[ -f "htuthesis.cls" ]] || return 1
  # Option A: \@addtoreset{footnote}{page} (package-free). LaTeX footnote counter = footnote (\c@footnote).
  #   Option B: footmisc[perpage]. Either satisfies AC-5.
  grep -qE 'addtoreset\{footnote\}\{page\}' htuthesis.cls && return 0
  grep -qE 'usepackage(\[[^]]*perpage[^]]*\])?\{footmisc\}' htuthesis.cls && return 0
  echo "  (NO per-page footnote reset wiring — ctexbook default per-CHAPTER; spec §1.2.4 requires per-PAGE; RED pre-impl)"
  return 1
}
run_test "P1" "ATDD-3.8-05" "footnote per-page reset wiring (\\@addtoreset{footnote}{page} OR footmisc) (AC-5, R-16, TC-E3-41; *** RED DRIVER ***)" test_footnote_perpage_wiring

# ATDD-3.8-06: \renewcommand\footnotesize{...\xiaowu...} — footnote body = 小五号 (9pt) (AC-5 size wiring, TC-E3-40)
# Truth source: spec §1.2.4 line 197 "脚注用小五号宋体字". The footnote body size must be \xiaowu (9pt). GREEN pre/post
#   (inherited zzuthesis; the CJK FACE inherits SimSun). main.pdf p47: footnote SimSun 9.0pt confirmed.
test_footnote_size_xiaowu() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'renewcommand\\footnotesize\{[^}]*\\xiaowu' htuthesis.cls
}
run_test "P1" "ATDD-3.8-06" "\\renewcommand\\footnotesize{...\\xiaowu...} 小五号 9pt (AC-5 size, TC-E3-40; GREEN)" test_footnote_size_xiaowu

echo ""

# ==========================================
# P2 Tests — compile/regression + scope guards + diagnostics
# ==========================================
echo "=== P2: footnote linespread + resume wiring + compile + regression + scope guards ==="

# ATDD-3.8-07: \htu@footnote@linespread externalized in .def (AC-2/AC-5 — footnote line spacing tunable)
# The footnote line-spread factor must be in htuthesis.def (user-tunable). GREEN pre/post. def:163 = 1.5.
test_footnote_linespread_def() {
  [[ -f "htuthesis.def" ]] || return 1
  grep -qE 'def\\htu@footnote@linespread' htuthesis.def
}
run_test "P2" "ATDD-3.8-07" "\\htu@footnote@linespread in .def (AC-2/5; GREEN — def:163)" test_footnote_linespread_def

# ATDD-3.8-08: regression — \setmainfont{Times New Roman} preserved (Story 3.9, AC-7/AC-8)
# 3.8 consumes 3.9's \rmfamily→TNR so footnote Latin markers/digits render TNR (NOT Latin Modern). Must remain intact.
test_setmainfont_tnr_preserved() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'setmainfont\{Times New Roman\}' htuthesis.cls
}
run_test "P2" "ATDD-3.8-08" "regression: \\setmainfont{Times New Roman} preserved (Story 3.9, AC-7/8)" test_setmainfont_tnr_preserved

# ATDD-3.8-09: regression — \xiaowu / \xiaosi / \sanhao size macros intact (AC-7 — ack/papers/footnote depend on them)
# ack body = \xiaosi (小四 12pt), papers body = \wuhao, footnote = \xiaowu (小五 9pt), titles = \sanhao (三号 16pt).
#   The size macros (Story 2.5) must remain. GREEN pre/post.
test_size_macros_intact() {
  [[ -f "htuthesis.cls" ]] || return 1
  grep -qE 'htu@def@fontsize\{xiaowu\}' htuthesis.cls && \
  grep -qE 'htu@def@fontsize\{xiaosi\}' htuthesis.cls && \
  grep -qE 'htu@def@fontsize\{sanhao\}\{16bp\}' htuthesis.cls
}
run_test "P2" "ATDD-3.8-09" "regression: \\xiaowu/\\xiaosi/\\sanhao size macros intact (AC-7; GREEN)" test_size_macros_intact

# ATDD-3.8-10: resume env + \resumeitem wiring intact + entry-format DIAGNOSTIC (AC-4)
# The resume env (\htu@chapter*{#1}\wuhao) + \resumeitem (\sihao\sffamily sub-headers) must remain. GREEN pre/post.
#   The ENTRY FORMAT is DECISION-PENDING: current data/resume.tex uses \begin{enumerate}[{[}1{]}] vs spec §2.17 "书写格式
#   同参考文献" (3.7 thebibliography reversed-hanging Option B). Value-agnostic here; PROMOTED post-decision.
test_resume_env_resumeitem() {
  [[ -f "htuthesis.cls" ]] || return 1
  if grep -qE 'newenvironment\{resume\}' htuthesis.cls && grep -qE 'newcommand\{\\resumeitem\}' htuthesis.cls; then
    echo "  (resume env + \\resumeitem wiring intact; entry format DECISION-PENDING: enumerate vs references-style per §2.17)"
    return 0
  fi
  return 1
}
run_test "P2" "ATDD-3.8-10" "resume env + \\resumeitem wiring (AC-4; entry format DECISION-PENDING)" test_resume_env_resumeitem

# ATDD-3.8-11: main.tex \include{data/ack} + \include{data/resume} wired (AC-1/AC-3 compile wiring)
# The ack + papers must be wired in main.tex back matter. GREEN pre/post.
test_ack_resume_included() {
  [[ -f "main.tex" ]] || return 1
  grep -qE '\\include\{data/ack\}' main.tex && \
  grep -qE '\\include\{data/resume\}' main.tex
}
run_test "P2" "ATDD-3.8-11" "main.tex \\include{data/ack} + \\include{data/resume} (AC-1/3; GREEN)" test_ack_resume_included

# ATDD-3.8-12: scope guard — \fangsong referenced (ack env uses it) + \sihao size macro intact (AC-2/AC-4)
# \fangsong is a ctex builtin CJK family (used in the ack env cls:884); \songti likewise (Option A target). The ack env
#   must reference a CJK face macro + \sihao (resumeitem sub-headers) must remain so the AC-2/AC-4 decisions apply.
#   GREEN pre/post.
test_face_macros_intact() {
  [[ -f "htuthesis.cls" ]] || return 1
  # \fangsong OR \songti referenced in cls (the ack env body face) + \sihao size macro intact.
  ( grep -qE '\\fangsong' htuthesis.cls || grep -qE '\\songti' htuthesis.cls ) && \
  grep -qE 'htu@def@fontsize\{sihao\}' htuthesis.cls
}
run_test "P2" "ATDD-3.8-12" "scope guard: \\fangsong/\\songti + \\sihao face macros intact (AC-2/4; GREEN)" test_face_macros_intact

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
  echo "   RED driver: ATDD-3.8-05 — footnote per-page reset wiring (R-16). Current cls has NO"
  echo "      \@addtoreset{footnote}{page} / footmisc → ctexbook default per-CHAPTER; spec §1.2.4 line 109 + reference"
  echo "      PDF require per-PAGE. FAILS pre-impl; PASSES post-impl (the AC-5 fix)."
  echo "   GREEN guards (lock-in):"
  echo "      3.8-01 (\\htu@chapter*{\\htu@ackname} title), 3.8-02 (\\htu@ackname 致 谢),"
  echo "      3.8-06 (\\footnotesize \\xiaowu 9pt), 3.8-07 (footnote linespread .def), 3.8-08 (TNR 3.9),"
  echo "      3.8-09 (size macros), 3.8-11 (ack+resume \\include), 3.8-12 (face macros)."
  echo "   DECISION-PENDING diagnostics (value-agnostic; PROMOTED post-decision):"
  echo "      3.8-03 (ack body face — fangsong vs songti), 3.8-04 (papers title text — 个人简历 vs 攻读学位),"
  echo "      3.8-10 (papers entry format — enumerate vs references-style)."
  echo ""
  echo "   NOTE: spec §2.16/§2.17 govern AC-2/3/4 (reference PDF is SILENT on 致谢/攻读 titles → spec text is the"
  echo "         tiebreaker, mirror of 3.6 AC-6 / 3.7 AC-2). AC-5 (footnote per-page reset) is reference-CONFIRMED"
  echo "         (p15-34 markers restart each page). Source-greps prove the WIRING; the integration suite proves the"
  echo "         RENDERED ack/papers/footnotes via fitz. architecture.md:41 = MEDIUM; R-16 = 4. Tests are read-only."
fi

if [[ "$SKIP" != "1" ]] && [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
