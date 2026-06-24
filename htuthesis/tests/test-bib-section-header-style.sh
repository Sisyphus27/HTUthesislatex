#!/usr/bin/env bash
# test-bib-section-header-style.sh — 参考文献 type-section 子标题样式守卫
# Epic 5 复盘修复（2026-06-24，Zy 裁决）。守卫 \defbibheading{htu-refs-sub}（cls:1025）四维：
#   ① 字体=SimSun（非 SimHei）——\htu@songtibold 生效、未退回 ctex 默认 CJK 粗体映射
#   ② 粗体——墨度比 vs 同号 SimSun-12pt 正文 >=1.10（revert \songti → ~0.8-1.0 FAIL）
#   ③ 顶格 flush-left——x0<80（\noindent 生效；revert 吃 \parindent → x0=94.9 FAIL）
#   ④ 标题→首条目间距 22-29pt（\vspace{-0.2\baselineskip} 生效；revert 0.3 → 37pt FAIL）
# 真值源：spec §2.14 对分节标题格式沉默→参考 PDF p228-249（flush-left SimSun 12pt）辅助 + Zy 加粗裁决。
# 用法：bash tests/test-bib-section-header-style.sh --run（默认 ATDD_SKIP=1 空置；main.pdf 缺失则 SKIP+warn）。
set -uo pipefail
SKIP="${ATDD_SKIP:-1}"
for a in "$@"; do [ "$a" = "--run" ] && SKIP=0; [ "$a" = "--help" ] && { sed -n '2,12p' "$0"; exit 0; }; done
DIR="$(cd "$(dirname "$0")/.." && pwd)"; cd "$DIR"

green(){ printf "\033[32m[PASS]\033[0m %s\n" "$1"; }
red(){ printf "\033[31m[FAIL]\033[0m %s\n" "$1"; }
yellow(){ printf "\033[33m[SKIP]\033[0m %s\n" "$1"; }

[ "$SKIP" = "1" ] && { yellow "test-bib-section-header-style（设 ATDD_SKIP=0 或 --run 启用）"; exit 0; }
[ ! -f main.pdf ] && { yellow "main.pdf 不存在——先 latexmk -xelatex main.tex；守卫跳过"; exit 0; }

OUT="$(python - <<'PYEOF'
import fitz, statistics
doc = fitz.open("main.pdf")
terms = ("一、期刊论文","二、著作","三、论文集","四、学位论文","五、专利","六、电子资源","七、其他")
CJK = lambda c: "一" <= c <= "鿿"
def ink(page, bbox, zoom=4):
    pm = page.get_pixmap(matrix=fitz.Matrix(zoom, zoom), clip=fitz.Rect(bbox), colorspace=fitz.csGRAY)
    px = pm.samples; n = pm.width * pm.height
    return sum(1 for i in range(n) if px[i*pm.n] < 128) / n
hdrs = []
for pi in range(doc.page_count):
    page = doc[pi]
    for b in page.get_text("dict")["blocks"]:
        for l in b.get("lines", []):
            for sp in l["spans"]:
                ts = sp.get("text", "").strip()
                if any(ts.startswith(t) for t in terms) and abs(sp["size"] - 12.0) < 0.6:
                    hdrs.append((pi, page, sp, ts))
reg = []
for pi in range(4, 39):
    for b in doc[pi].get_text("dict")["blocks"]:
        for l in b.get("lines", []):
            for sp in l["spans"]:
                t = sp.get("text", "").strip()
                if sp.get("font") == "SimSun" and abs(sp["size"] - 12.0) < 0.35 and len(t) >= 4 and any(CJK(c) for c in t):
                    bb = sp["bbox"]
                    if 100 < bb[1] < 760 and bb[0] < 120:
                        reg.append(ink(doc[pi], bb))
    if len(reg) >= 25: break
reg_med = statistics.median(reg) if reg else 0.0001
fonts = set(sp["font"] for _, _, sp, _ in hdrs)
font_repr = "/".join(sorted(fonts)) if fonts else "NONE"
font_ok = "1" if fonts and all("SimSun" in f for f in fonts) else "0"
x0_med = statistics.median([sp["bbox"][0] for _, _, sp, _ in hdrs]) if hdrs else 0
x0_ok = "1" if x0_med < 80 else "0"
gaps = []
for pi, page, sp, ts in hdrs[:6]:
    hy = sp["bbox"][1]
    below = sorted(s["bbox"][1] for b in page.get_text("dict")["blocks"] for l in b.get("lines", []) for s in l["spans"] if s["bbox"][1] > hy + 2 and abs(s["size"] - 10.5) < 0.3 and s["bbox"][0] < 80)
    if below: gaps.append(below[0] - hy)
gap_med = statistics.median(gaps) if gaps else 0
gap_ok = "1" if 22 <= gap_med <= 29 else "0"
hdr_ink = statistics.median([ink(p, sp["bbox"]) for _, p, sp, _ in hdrs]) if hdrs else 0
ratio = hdr_ink / reg_med if reg_med else 0
bold_ok = "1" if ratio >= 1.10 else "0"
print(f"{font_repr},{font_ok},{x0_med:.1f},{x0_ok},{gap_med:.1f},{gap_ok},{ratio:.2f},{bold_ok}")
doc.close()
PYEOF
)"
IFS=',' read -r FONT OK_FONT X0 OK_FLUSH GAP OK_GAP RATIO OK_BOLD <<< "${OUT}"
FAIL=0
t(){ if [ "$2" = "1" ]; then green "$1 — $3"; else red "$1 — $3"; FAIL=$((FAIL+1)); fi; }
t "① 字体=SimSun(非 SimHei)"       "${OK_FONT:-0}"  "font=${FONT:-NONE}"
t "② 顶格 flush-left"              "${OK_FLUSH:-0}" "x0=${X0:-?} (<80; 条目边界 70.9)"
t "③ 标题→首条目间距~24pt"          "${OK_GAP:-0}"   "GAP=${GAP:-?}pt ([22,29]; 参考 24.1)"
t "④ 粗体(墨度比 vs 同号正文)"      "${OK_BOLD:-0}"  "ratio=${RATIO:-?} (>=1.10; revert→~0.9)"
echo "---"
if [ "$FAIL" = "0" ]; then green "bib section-header style 守卫 4/4 PASS"; exit 0
else red "bib section-header style 守卫 $FAIL FAIL"; exit 1; fi
