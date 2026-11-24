#!/usr/bin/env bash
# Verify the rendered 16bp SimHei 参考文献 chapter heading in main.pdf.
# Usage: sentinel-bibliography-chapter.sh [--inject | --fixture]
# --fixture checks the template with no journal entries.
# --inject removes the chapter heading in that fixture and checks that the probe detects its absence.
# Exit 0: check passed. Exit 1: heading presence differs from the expectation. Exit 2: could not run the check.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 2

mode="${1:-probe}"
case "$mode" in
  -h|--help) sed -n '2,6s/^# //p' tests/sentinel-bibliography-chapter.sh; exit 0 ;;
  probe|--inject|--fixture) ;;
  *) printf 'Usage: %s [--inject | --fixture]\n' "$0" >&2; exit 2 ;;
esac

probe_refs_hits() {
  python - "$1" <<'PY'
import sys

try:
    import pymupdf

    with pymupdf.open(sys.argv[1]) as doc:
        hits = sum(
            "参考文献" in span["text"] and "Hei" in span["font"] and 15.5 <= span["size"] <= 16.5
            for page in doc
            for block in page.get_text("dict")["blocks"]
            for line in block.get("lines", [])
            for span in line["spans"]
        )
except Exception as exc:
    print(f"PyMuPDF probe failed for {sys.argv[1]}: {exc}", file=sys.stderr)
    sys.exit(2)

print(hits)
sys.exit(0 if hits else 1)
PY
}

pdf=main.pdf
if [[ "$mode" != probe ]]; then
  tmpbuild="$(mktemp -d)" || exit 2
  trap 'rm -rf -- "$tmpbuild"' EXIT
  cp -r main.tex htuthesis.cls htuthesis.def docutils.sty data figures ref "$tmpbuild/" || exit 2
  cp tests/fixtures/refs-online-only.bib "$tmpbuild/ref/refs.bib" || exit 2

  if [[ "$mode" == --inject ]]; then
    python - "$tmpbuild/htuthesis.cls" <<'PY' || exit 2
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
source, count = re.subn(r"(?m)^  \\htu@chapter\*\{\\bibname\}%?\s*$",
                       "", path.read_text(encoding="utf-8"))
if count != 1:
    sys.exit(f"Expected one bibliography chapter call, found {count}")
path.write_text(source, encoding="utf-8")
PY
  fi
  if ! (cd "$tmpbuild" && latexmk -xelatex -g -file-line-error -halt-on-error -interaction=nonstopmode main.tex > build.log 2>&1); then
    tail -n 25 "$tmpbuild/build.log" >&2
    printf '[FAIL] %s: fixture compilation failed\n' "$mode" >&2
    exit 2
  fi
  pdf="$tmpbuild/main.pdf"
fi

hits="$(probe_refs_hits "$pdf")"
status=$?
case "$status" in
  0) [[ "$hits" =~ ^[1-9][0-9]*$ ]] || status=2 ;;
  1) [[ "$hits" == 0 ]] || status=2 ;;
  *) status=2 ;;
esac
if [[ "$status" == 2 ]]; then
  printf '[FAIL] %s: could not verify the bibliography chapter\n' "$mode" >&2
  exit 2
fi
if [[ "$mode" == --inject ]]; then
  if [[ "$status" == 1 ]]; then
    printf '[PASS] %s: removing the chapter heading gives 0 hits\n' "$mode"
    exit 0
  fi
  printf '[FAIL] %s: heading still present (%s hits)\n' "$mode" "$hits" >&2
  exit 1
fi
if [[ "$status" == 1 ]]; then
  printf '[FAIL] %s: bibliography chapter heading missing\n' "$mode" >&2
  exit 1
fi
printf '[PASS] %s: bibliography chapter heading present (%s hits)\n' "$mode" "$hits"
