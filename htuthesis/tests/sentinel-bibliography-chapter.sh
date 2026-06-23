#!/usr/bin/env bash
# sentinel-bibliography-chapter.sh — ALWAYS-ON detection-layer sentinel for Story 5.2 (NFR-4 #15 / NFR-6 / R-35)
#
# PURPOSE: backstop Story 5.1's opt-in fixture ATDD with a check that runs on EVERY `make test`, so the Story 3.12
#   blind spot (参考文献 chapter vanishes when refs.bib lacks @article) can never silently recur. Story 5.1 shipped
#   the decouple (entry-point \htu@chapter*{\bibname} at cls:1022); this sentinel confirms the RENDERED OUTPUT of that
#   mechanism is present in main.pdf.
#
# *** RENDERED-SPAN ANCHORING (R-35 / TC-E5-14 — the non-negotiable design constraint) ***
#   The PASS/FAIL gate is a fitz rendered-span probe on the compiled main.pdf (SimHei 三号 [15.5,16.5] band, ≥1 hit =
#   PASS). It is NOT a proxied .bbl/.aux/source-grep check. A proxied check is the wrong-target-AC trap (Epic 3 retro
#   Lesson 3 / R-25): it can PASS while the rendered chapter is absent — the exact failure mode Epic 5 exists to
#   prevent. The band [15.5,16.5] isolates 三号 (16.0pt) and EXCLUDES 小三 (15.0pt) body section headings (chap03
#   "第六节 参考文献") — do NOT widen without re-verifying the RED phase (Story 5.1 detection-calibration note).
#
# MODES:
#   (default)        Probe main.pdf for 参考文献 chapter title. PASS (≥1 hit) / FAIL (0 hits). Graceful SKIP+warn if
#                    main.pdf absent (so `make test` on a clean tree is not broken). This is the always-on `make test` path.
#   --inject         (opt-in, heavy ~6min) TC-E5-11 RED-on-revert proof: temp-tree copy with Story 5.1's entry-point
#                    reverted → recompile → assert 0 参考文献 hits (the chapter vanished → sentinel would FAIL).
#                    Proves the sentinel is sensitive to the entry-point (catches the Story 3.12 blind spot). SUT untouched.
#   --fixture        (opt-in, AC-6 option c) compile the online-only fixture (tests/fixtures/refs-online-only.bib) in a
#                    temp-tree + probe → asserts the sentinel passes on the degenerate distribution too. If AC-6 option (b)
#                    is chosen (canonical-only make test + 5.1 ATDD owns fixture coverage), this mode is unused but retained.
#   --help           Show usage.
#
# `make test` wiring (Story 5.2 Task 3): Makefile `sentinel-check` target runs this script (default mode) after
#   compile-check (which builds main.pdf). Zero extra compile on the canonical path.
#
# Truth source: NFR-4 (silent-failure #15, architecture.md:179) + NFR-6 (参考文献 renders for ANY refs.bib distribution).
#   See Story 5.2 spec + test-design-epic-5.md (R-35 mitigation).

set -uo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DIR"

# --- mode flags ---
MODE="probe"      # default = always-on main.pdf probe
HELP=0
for arg in "$@"; do
  case "$arg" in
    --inject)  MODE="inject" ;;
    --fixture) MODE="fixture" ;;
    --help|-h) HELP=1 ;;
    *) echo "sentinel: unknown flag '$arg' (--help for usage)" >&2 ;;
  esac
done

if [[ "$HELP" == "1" ]]; then
  sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

PASS=0
FAIL=0
WARN=0
green()  { printf "\033[32m  [PASS] %s\033[0m\n" "$1"; }
red()    { printf "\033[31m  [FAIL] %s\033[0m\n" "$1"; }
yellow() { printf "\033[33m  [WARN] %s\033[0m\n" "$1"; }

# --- the fitz rendered-span probe (AC-1 / AC-5, the PASS/FAIL gate; reuses Story 5.1 I02 verbatim) ---
#   Args: $1 = path to main.pdf. Prints the hit count to stdout. Exit 0 always (caller interprets the count).
probe_refs_hits() {
  local pdf="$1"
  python - "$pdf" <<'PYEOF'
import fitz, sys
try:
    doc = fitz.open(sys.argv[1])
except Exception:
    print(-1); sys.exit(0)   # -1 = could not open (caller treats as "no usable PDF")
hits = 0
for page in doc:
    for block in page.get_text("dict")["blocks"]:
        for line in block.get("lines", []):
            for sp in line["spans"]:
                t = sp.get("text", ""); f = sp.get("font", ""); s = sp.get("size", 0.0)
                # SimHei 三号 (cls \sanhao=16bp → 16.0pt); band [15.5,16.5] excludes 小三=15.0 body section headings.
                if "参考文献" in t and "Hei" in f and 15.5 <= s <= 16.5:
                    hits += 1
print(hits)
PYEOF
}

echo "=============================================="
echo "Sentinel: 参考文献 chapter-presence (Story 5.2, NFR-4 #15 / NFR-6)"
echo "Mode: $MODE"
echo "=============================================="

if [[ "$MODE" == "probe" ]]; then
  # --- DEFAULT (always-on make test path): probe the canonical main.pdf ---
  if [[ ! -f main.pdf ]]; then
    yellow "main.pdf not found — run 'make thesis' first; sentinel skipped (no FAIL to keep make test usable on a clean tree)"
    echo "=============================="
    printf "Total: \033[32m0 PASS\033[0m  \033[31m0 FAIL\033[0m  \033[33m1 SKIP\033[0m  (main.pdf absent)\n"
    echo "=============================="
    exit 0   # graceful SKIP, not FAIL
  fi
  hits="$(probe_refs_hits main.pdf)"
  if [[ "$hits" == "-1" ]]; then
    red "main.pdf could not be opened by fitz — sentinel cannot verify (investigate)"
    exit 1
  fi
  printf "    (参考文献 SimHei 三号 span count = %s)\n" "$hits" >&2
  if [[ "$hits" -ge 1 ]]; then
    green "参考文献 chapter title present (≥1 rendered span) — NFR-6 holds"
    echo "=============================="
    printf "Total: \033[32m1 PASS\033[0m  \033[31m0 FAIL\033[0m\n"
    echo "=============================="
    exit 0
  else
    red "参考文献 chapter title VANISHED (0 rendered spans) — Story 3.12 blind spot RECURRED (FR-20/NFR-6 violation)"
    echo "  → check htuthesis.cls:1022 entry-point \\htu@chapter*{\\bibname} is present (Story 5.1 decouple)" >&2
    echo "=============================="
    printf "Total: \033[32m0 PASS\033[0m  \033[31m1 FAIL\033[0m\n"
    echo "=============================="
    exit 1
  fi

elif [[ "$MODE" == "inject" ]]; then
  # --- TC-E5-11 RED-on-revert proof: temp-tree copy, revert Story 5.1 entry-point, recompile, assert 0 hits ---
  #   Reuses Story 5.1 I06's harness (python precise-remove, NOT sed — R-26). SUT (canonical cls) is NEVER edited.
  echo "  [setup] temp-tree copy + revert entry-point + recompile — ~6 min..."
  tmpbuild="$(mktemp -d)"
  cp -r . "$tmpbuild"/ >/dev/null 2>&1
  # Swap the online-only fixture so the revert is proven on the degenerate distribution too (the real-thesis condition).
  if [[ -f tests/fixtures/refs-online-only.bib ]]; then
    cp tests/fixtures/refs-online-only.bib "$tmpbuild/ref/refs.bib"
  fi
  # Remove the entry-point from the TEMP cls only (revert the Story 5.1 decouple).
  python - "$tmpbuild/htuthesis.cls" <<'PYEOF'
import sys
p = sys.argv[1]
src = open(p, encoding="utf-8").read().splitlines(keepends=True)
out = []; in_makebib = False; removed = False
for ln in src:
    if '\\newcommand' in ln and '\\makebibliography' in ln:
        in_makebib = True
    # Plain string `in` checks (NOT regex — avoids re.error on Python 3.12+; Story 5.1 code review P1).
    # Skip % comment lines (the [基础] block mentions \htu@chapter*{\bibname} in prose; Story 5.1 code review P1-followup).
    if (in_makebib and not removed
            and '\\htu@chapter*{\\bibname}' in ln
            and '\\defbibheading' not in ln
            and not ln.lstrip().startswith('%')):
        removed = True; continue
    out.append(ln)
open(p, "w", encoding="utf-8").write("".join(out))
sys.exit(0 if removed else 2)
PYEOF
  pyrc=$?
  if [[ $pyrc -ne 0 ]]; then
    rm -rf "$tmpbuild"
    red "inject: could not locate entry-point to revert (rc=$pyrc) — inject misconfigured"
    exit 1
  fi
  ( cd "$tmpbuild" && latexmk -xelatex -file-line-error -halt-on-error -interaction=nonstopmode -g main >/dev/null 2>&1 )
  hits="$(probe_refs_hits "$tmpbuild/main.pdf")"
  rm -rf "$tmpbuild"
  printf "    (reverted-entry-point 参考文献 hits = %s; expect 0 = chapter vanished)\n" "$hits" >&2
  if [[ "$hits" == "0" ]]; then
    green "TC-E5-11 RED-on-revert: entry-point removed → 0 参考文献 hits → sentinel WOULD FAIL (detection works)"
    echo "=============================="
    printf "Total: \033[32m1 PASS\033[0m  \033[31m0 FAIL\033[0m  (inject proof)\n"
    echo "=============================="
    exit 0
  else
    red "TC-E5-11 inject: reverted entry-point still yields $hits hits — sentinel NOT sensitive to the entry-point (investigate)"
    exit 1
  fi

elif [[ "$MODE" == "fixture" ]]; then
  # --- AC-6 option (c): compile the online-only fixture in a temp-tree + probe (degenerate-distribution check) ---
  FIXTURE="tests/fixtures/refs-online-only.bib"
  if [[ ! -f "$FIXTURE" ]]; then
    red "fixture $FIXTURE not found (Story 5.1 fixture) — --fixture mode unavailable"
    exit 1
  fi
  echo "  [setup] temp-tree copy + online-only fixture + recompile — ~3 min..."
  tmpbuild="$(mktemp -d)"
  cp -r . "$tmpbuild"/ >/dev/null 2>&1
  cp "$FIXTURE" "$tmpbuild/ref/refs.bib"
  ( cd "$tmpbuild" && latexmk -xelatex -file-line-error -halt-on-error -interaction=nonstopmode -g main >/dev/null 2>&1 )
  rc=$?
  hits="$(probe_refs_hits "$tmpbuild/main.pdf")"
  rm -rf "$tmpbuild"
  if [[ $rc -ne 0 ]]; then
    red "fixture compile failed (rc=$rc) — cannot probe"
    exit 1
  fi
  printf "    (online-only fixture 参考文献 hits = %s; expect ≥1 = chapter renders on degenerate distribution)\n" "$hits" >&2
  if [[ "$hits" -ge 1 ]]; then
    green "AC-6 fixture: 参考文献 renders on online-only fixture (≥1 hit) — sentinel passes degenerate distribution"
    echo "=============================="
    printf "Total: \033[32m1 PASS\033[0m  \033[31m0 FAIL\033[0m  (fixture mode)\n"
    echo "=============================="
    exit 0
  else
    red "AC-6 fixture: 参考文献 VANISHED on online-only fixture — Story 5.1 decouple regressed (FR-20/NFR-6)"
    exit 1
  fi
fi

exit 0
