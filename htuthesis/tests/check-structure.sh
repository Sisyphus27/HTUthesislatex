#!/usr/bin/env bash
# check-structure.sh — LaTeX thesis structure validation
# Usage: ./tests/check-structure.sh [project-dir]
set -uo pipefail

DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$DIR" || exit 1

PASS=0
FAIL=0
WARN=0

green()  { printf "\033[32m  [PASS] %s\033[0m\n" "$1"; }
red()    { printf "\033[31m  [FAIL] %s\033[0m\n" "$1"; }
yellow() { printf "\033[33m  [WARN] %s\033[0m\n" "$1"; }

# --- 1. Required files ---
echo "=== Required Files ==="
mapfile -t includes < <(
  sed 's/%.*//' main.tex | grep -oE '\\(input|include)\{[^}]+\}' |
    sed -E 's/^[^{]*\{//; s/\}$//' | sort -u
)
tex_files=(main.tex)
for f in "${includes[@]}"; do
  tex_files+=("${f%.tex}.tex")
done
required_files=("${tex_files[@]}" ref/refs.bib)
for f in "${required_files[@]}"; do
  if [ -f "$f" ]; then
    green "$f exists"
    ((PASS++)) || true
  else
    red "$f MISSING"
    ((FAIL++))
  fi
done

# --- 2. Chapter count ---
echo ""
echo "=== Chapter Count ==="
chap_count=0
for f in "${tex_files[@]}"; do
  if [[ "$f" == data/chap*.tex && -f "$f" ]]; then
    ((chap_count++))
  fi
done
if [ "$chap_count" -ge 4 ]; then
  green "Found $chap_count chapter files (>= 4)"
  ((PASS++)) || true
else
  red "Only $chap_count chapter files (need >= 4)"
  ((FAIL++))
fi

# --- 3. Figure references ---
echo ""
echo "=== Figure References ==="
missing_figs=0
mapfile -t fig_refs < <(
  sed 's/%.*//' "${tex_files[@]}" | grep -oE '\\includegraphics(\[[^]]*\])?\{[^}]+\}' |
    sed -E 's/^[^{]*\{//; s/\}$//' | sort -u
)
for fig in "${fig_refs[@]}"; do
  found=false
  for ext in "" ".pdf" ".png" ".jpg" ".eps"; do
    if [ -f "figures/${fig}${ext}" ]; then
      found=true
      break
    fi
  done
  if [ "$found" = false ]; then
    red "Missing figure: figures/$fig"
    missing_figs=$((missing_figs + 1))
  fi
done
if [ "$missing_figs" -eq 0 ]; then
  green "All referenced figures exist"
  PASS=$((PASS + 1))
else
  red "$missing_figs referenced figure(s) missing"
  FAIL=$((FAIL + 1))
fi

# --- 4. Bibliography references ---
echo ""
echo "=== Bibliography References ==="
if python - <<'PY'
from pathlib import Path
import re
import sys
from xml.etree import ElementTree

try:
    control = ElementTree.parse("main.bcf")
    bib = Path("main.bbl").read_text(encoding="utf-8")
except (OSError, ElementTree.ParseError) as exc:
    sys.exit(f"Cannot read Biber outputs (build main.pdf first): {exc}")

cited = {node.text for node in control.findall(".//{*}citekey") if node.text}
available = set(re.findall(r"^\s*\\(?:entry|keyalias)\{([^{}]+)\}", bib, re.M))
missing = sorted(cited - available - {"*"})
if missing:
    sys.exit("Unresolved cite keys in main.bbl: " + ", ".join(missing))
PY
then
  green "All explicit main.bcf cite keys found in main.bbl"
  ((PASS++)) || true
else
  red "Bibliography reference check failed"
  ((FAIL++))
fi

# --- 5. Build product ---
echo ""
echo "=== Build Product ==="
if [ -f "main.pdf" ]; then
  size=$(stat --printf="%s" "main.pdf" 2>/dev/null || stat -f%z "main.pdf" 2>/dev/null)
  if [ "$size" -gt 0 ]; then
    green "main.pdf exists ($size bytes)"
    ((PASS++)) || true
  else
    red "main.pdf is empty"
    ((FAIL++))
  fi
else
  yellow "main.pdf not found (run 'make thesis' first)"
  ((WARN++))
fi

# --- 6. Encoding check (UTF-8) ---
echo ""
echo "=== File Encoding ==="
bad_encoding=false
for f in "${tex_files[@]}"; do
  if [ -f "$f" ]; then
    if file "$f" | grep -qi "utf-8\|ascii\|text"; then
      : # ok
    else
      red "$f is not UTF-8 encoded"
      bad_encoding=true
      ((FAIL++))
    fi
  fi
done
if [ "$bad_encoding" = false ]; then
  green "All .tex files are UTF-8 / ASCII"
  ((PASS++)) || true
fi

# --- Summary ---
echo ""
echo "=============================="
printf "Total: \033[32m%d PASS\033[0m  \033[31m%d FAIL\033[0m  \033[33m%d WARN\033[0m\n" "$PASS" "$FAIL" "$WARN"
echo "=============================="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
