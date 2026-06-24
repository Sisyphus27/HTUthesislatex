#!/usr/bin/env bash
# check-structure.sh — LaTeX thesis structure validation
# Usage: ./tests/check-structure.sh [project-dir]
set -uo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DIR"

PASS=0
FAIL=0
WARN=0

green()  { printf "\033[32m  [PASS] %s\033[0m\n" "$1"; }
red()    { printf "\033[31m  [FAIL] %s\033[0m\n" "$1"; }
yellow() { printf "\033[33m  [WARN] %s\033[0m\n" "$1"; }

# --- 1. Required files ---
echo "=== Required Files ==="
required_files=(
  "main.tex"
  "data/cover.tex"
  "data/abstract.tex"
  "data/chap01.tex"
  "data/chap02.tex"
  "data/chap03.tex"
  "data/chap04.tex"
  "data/app01.tex"
  "data/app02.tex"
  "data/app03.tex"
  "data/ack.tex"
  "data/resume.tex"
  "ref/refs.bib"
)
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
chap_count=$(ls data/chap*.tex 2>/dev/null | wc -l)
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
tex_files="main.tex data/*.tex"
missing_figs=0
# Extract \includegraphics references
fig_refs=$(grep -hro '\\includegraphics[^{]*{[^}]*}' $tex_files 2>/dev/null | \
  sed 's/.*{//' | sed 's/}//' | sort -u)
for fig in $fig_refs; do
  [ -z "$fig" ] && continue
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
if [ -f "ref/refs.bib" ]; then
  # Extract all cite keys from tex files
  cite_keys=$(grep -rho '\\cite[tp]*\*\{[^}]*\}' $tex_files 2>/dev/null | \
    sed 's/.*{//;s/}//' | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sort -u)

  bib_keys=$(grep -o '@[a-zA-Z]*{[^,]*' "ref/refs.bib" 2>/dev/null | \
    sed 's/.*{//;s/^[[:space:]]*//;s/[[:space:]]*$//' | sort -u)

  missing_cites=0
  for key in $cite_keys; do
    [ -z "$key" ] && continue
    if ! echo "$bib_keys" | grep -qx "$key"; then
      red "Cite key not in bib: $key"
      ((missing_cites++))
    fi
  done

  if [ "$missing_cites" -eq 0 ]; then
    green "All cite keys found in refs.bib"
    ((PASS++)) || true
  else
    red "$missing_cites cite key(s) missing from refs.bib"
    ((FAIL++))
  fi
else
  red "refs.bib not found, skipping bibliography check"
  ((FAIL++))
fi

# --- 5. Build product ---
echo ""
echo "=== Build Product ==="
if [ -f "main.pdf" ]; then
  size=$(stat --printf="%s" "main.pdf" 2>/dev/null || stat -f%z "main.pdf" 2>/dev/null)
  if [ "$size" -gt 0 ]; then
    green "main.pdf exists ($(echo "scale=1; $size/1024" | bc 2>/dev/null || echo "$size") bytes)"
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
for f in main.tex data/*.tex; do
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
