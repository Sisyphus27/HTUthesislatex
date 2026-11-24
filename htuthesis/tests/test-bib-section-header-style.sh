#!/usr/bin/env bash
# Check the rendered size, weight, indent and first-entry spacing of bibliography subgroup headings.
# Usage: bash tests/test-bib-section-header-style.sh --run
set -uo pipefail
case "${1:-}" in
  --help|-h) sed -n '2,3s/^# //p' "$0"; exit 0 ;;
  --run) ATDD_SKIP=0 ;;
esac
if [[ "${ATDD_SKIP:-1}" == 1 ]]; then
  printf '[SKIP] use --run to check the bibliography subgroup headings\n'
  exit 0
fi
cd "$(dirname "$0")/.." || exit 1
if [[ ! -f main.pdf ]]; then
  printf '[SKIP] main.pdf is missing. Build the sample before running this check.\n'
  exit 0
fi

python - <<'PY'
import re
import sys

import pymupdf

heading = re.compile(r"^[一二三四五六七八九十]+、(期刊论文|著作|论文集与文集|学位论文|报告|专利|国际与国家标准|报纸文章|电子资源|其他)$")
with pymupdf.open("main.pdf") as doc:
    outline = doc.get_toc()
    start = next((p for _, title, p in outline if title == "参考文献"), 0)
    if not start:
        sys.exit("[FAIL] bibliography chapter bookmark is missing")
    end = next((p for _, title, p in outline if p > start and title.startswith("附录")), len(doc) + 1)
    checked = 0
    for page in doc.pages(start - 1, end - 1):
        spans = [
            span for block in page.get_text("dict")["blocks"]
            for line in block.get("lines", []) for span in line["spans"]
        ]
        labels = [s for s in spans if re.fullmatch(r"\[1\]", s["text"].strip())]
        stroke = {
            "".join(chr(c[0]) for c in tr["chars"]).strip()
            for tr in page.get_texttrace() if tr["type"] == 1 and "SimSun" in tr["font"]
        }
        for span in spans:
            name = span["text"].strip()
            if not heading.fullmatch(name):
                continue
            x, y = span["bbox"][:2]
            gap = min((s["bbox"][1] - y for s in labels if s["bbox"][1] > y), default=float("inf"))
            if not (
                "SimSun" in span["font"] and abs(span["size"] - 12.0) < 0.25
                and name in stroke and abs(x - 25 * 72 / 25.4) <= 0.5 and 22 <= gap <= 29
            ):
                sys.exit(f"[FAIL] p{page.number + 1} {name}: {span['font']} {span['size']:.2f}bp, "
                         f"stroke={name in stroke}, x={x:.2f}bp, gap={gap:.2f}bp")
            print(f"[PASS] p{page.number + 1} {name}: 12bp bold SimSun, x={x:.2f}bp, entry gap={gap:.2f}bp")
            checked += 1
    if not checked:
        sys.exit("[FAIL] no bibliography subgroup headings found")
PY
