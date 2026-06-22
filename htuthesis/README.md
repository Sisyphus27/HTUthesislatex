# htuthesis — 河南师范大学博士学位论文 LaTeX 模板

河南师范大学（HTU）博士学位论文 LaTeX 模板。按《河南师范大学研究生学位论文格式要求》（spec）实现，仅支持博士（doctor）学位、XeLaTeX 引擎、TeX Live 2025。

> 格式审查对照清单（#1 交付物）见 [`verify/checklist.md`](verify/checklist.md)——逐条映射 spec 规则到本模板实现，标注「自动检查/人工确认」。

---

## 1. 快速开始 (Quick Start)

```bash
# 1. 克隆仓库
git clone <repo-url> && cd htuthesis

# 2. 确认环境：TeX Live 2025 + 5 字体（SimSun/SimHei/KaiTi/FangSong/Times New Roman）
xelatex --version    # 须 XeLaTeX

# 3. 编辑封面元数据（论文题目/作者/专业/学号/日期）
#    打开 data/cover.tex，修改 \ctitle \etitle \cmajor ... 等命令

# 4. 编译
latexmk -xelatex main

# 5. 打开 PDF
main.pdf
```

> Windows 无 `latexmk`？用 TeX Live 自带的 `latexmk`（推荐）或直接见 [§5 编译](#5-编译-compilation) 的原始命令序列。

---

## 2. 环境要求 (Requirements)

- **引擎：XeLaTeX ONLY。** pdflatex / lualatex 不支持（CJK 字体 + spec 排版要求）。NFR-1。
- **TeX Live 2025 最低**（含 xelatex、latexmk、biber、ctex、fancyhdr、geometry、caption、hyperref、biblatex/biblatex-gb7714-2015、tikz、zhnumber）。
- **5 个必需字体：**
  - `SimSun`（宋体，正文）
  - `SimHei`（黑体，标题）
  - `KaiTi`（楷体）
  - `FangSong`（仿宋）
  - `Times New Roman`（Latin 正文/标题 Latin）
- 缺任一字体会 `\PackageError` 终止编译（cls:78–97 `\IfFontExistsTF` gate；NFR-2）。Windows 自带；Linux 须安装（fontconfig）或置于 `~/fonts`。

---

## 3. 元数据设置 (Metadata Setup)

封面与扉页的论文信息在 [`data/cover.tex`](data/cover.tex) 中设置：

| 命令 | 含义 | 示例 |
|------|------|------|
| `\schoolcode{...}` | 单位代码 | `\schoolcode{10476}` |
| `\id{...}` | 学号（~10 位） | `\id{2024000001}` |
| `\secretlevel{...}` | 分类号（《中图法》第五版） | `\secretlevel{D669.3}` |
| `\ctitle{...}` | 中文题目（≤20 字） | `\ctitle{河南师范大学学位论文 \LaTeX\ 模板使用示例}` |
| `\csubject{...}` | 中文学科门类 | `\csubject{政治学}` |
| `\cmajor{...}` | 中文学科专业 | `\cmajor{政治学理论}` |
| `\researchdirection{...}` | 研究方向 | `\researchdirection{社区治理}` |
| `\degreecategory{...}` | 申请学位类别 | `\degreecategory{法学博士}` |
| `\cauthor{...}` | 中文作者 | `\cauthor{赵钱孙}` |
| `\csupervisor{...}` | 中文指导教师 | `\csupervisor{吴郑王}` |
| `\protitle{...}` | 指导教师职称 | `\protitle{教授}` |
| `\cdate{...}` | 中文日期（默认 `\CJK@todaybig`「二〇…年…月」） | `\cdate{二〇二五年五月}` |
| `\etitle{...}` | 英文题目（Title Case） | `\etitle{An Introduction to ... University}` |
| `\edegree{...}` | 英文学位类别 | `\edegree{Doctor of Law}` |
| `\emajor{...}` | 英文学科专业 | `\emajor{Materials Science and Engineering}` |
| `\edepartment{...}` | 英文院系 | `\edepartment{School of Materials Science and Engineering}` |
| `\eauthor{...}` | 英文作者 | `\eauthor{Zhao Qiansun}` |
| `\esupervisor{...}` | 英文指导教师 | `\esupervisor{Prof. Wu Zhengwang}` |

> `\stuno`（本科用，博士封面不渲染）与 `\edate`（英文日期自动生成）为可选/自动，通常无需手动设置。完整字段见 [`data/cover.tex`](data/cover.tex) 注释。

---

## 4. 文件结构 (File Structure)

```
htuthesis/
├── main.tex                    # 论文入口 — 元数据 + 章节引用
├── htuthesis.cls               # 排版引擎（勿改）
├── htuthesis.def               # 学校格式参数（用户区/高级区分界注释，可调）
├── htuthesis.bst               # 参考文献样式（GB/T 7714-2015）
├── Makefile                    # 编译 + clean + check + calibrate + debug-check 目标
├── README.md                   # 本文件
│
├── data/                       # 论文内容（用户写作区）
├── figures/                    # 图片 + HTU 校徽 (htu-logo.pdf / htu-text-logo.pdf)
├── ref/                        # 参考文献 (refs.bib)
├── tools/                      # 开发辅助（不参与正式编译）
│   └── calibrate.tex           # TikZ 物理边距标尺
└── verify/                     # 验证产物
    ├── checklist.md            # 格式审查对照清单（#1 交付物）
    └── baseline/               # 结构基线快照（页数、章节起始页）
```

### `data/` 文件名对照表

| 文件 | 内容 |
|------|------|
| `data/cover.tex` | 封面元数据（题目/作者/专业/学号/日期） |
| `data/abstract.tex` | 中文摘要 + 英文 ABSTRACT（含关键词） |
| `data/chap01.tex` … `chap04.tex` | 正文第一章 … 第四章 |
| `data/app01.tex` … `app03.tex` | 附录 A … 附录 C |
| `data/ack.tex` | 致谢 |
| `data/resume.tex` | 攻读学位期间发表的学术论文目录 |
| `data/denotation.tex` | 主要符号表（如使用） |

---

## 5. 编译 (Compilation)

### 推荐：latexmk（自动多遍）

```bash
latexmk -xelatex main          # 自动 xelatex + biber + xelatex×N，生成 main.pdf
```

### 原始序列（`refs.bib` 改动后或无 latexmk 时）

> ⚠ 本模板用 **biber**（非 bibtex）处理后端（cls biblatex `backend=biber`）。`bibtex main` 不生效。

```bash
xelatex main                   # 第 1 遍（生成 .aux/.bcf）
biber main                     # 处理参考文献（生成 .bbl；须用 biber 非 bibtex）
xelatex main                   # 第 2 遍（应用 .bbl）
xelatex main                   # 第 3 遍（解析交叉引用）
```

### Make 目标

```bash
make              # = make thesis && make a3cover（默认）
make thesis       # 仅 main.pdf
make a3cover      # A3 封面 a3cover.pdf
make clean        # 清理中间文件
make test         # compile-check + lint-check + structure-check
make calibrate    # 生成 tools/calibrate.pdf（物理边距标尺，overlay 比对）
make debug-check  # NFR-5：6 类 LaTeX warning 视为 error（干净树 exit 0）
```

> `make calibrate` / `make debug-check` 为可选开发工具，不在默认 `make`/`make test` 中。

### 文献管理（Zotero + Better BibTeX）

本模板后端 = **biblatex + biber + gb7714-2015**（cls:139），读取标准 `.bib` 文件。推荐用 Zotero + [Better BibTeX](https://retorque.re/zotero-better-bibtex/) 插件管理文献：

1. **Zotero 导出**：选 *Better BibLaTeX* 格式（或 *Better BibTeX* 亦可——前者用 biblatex 原生 `date` 字段更优）→ 导出为 `ref/refs.bib`（覆盖现有示例）。Better BibTeX 额外字段（`file`/`abstract`/`keywords`）biber 默认忽略，无害；可在导出选项取消以瘦身。
2. **自动同步**：Better BibTeX 的 *auto-export* / *keep updated* 可在 Zotero 库变动时自动重写 `ref/refs.bib`。
3. **引用键**：Better BibTeX 自动生成的 citekey（如 `chen2001`、`nadkarni1992`）直接用于正文。
4. **正文引用**：本模板是 **脚注式**（§2.14 case-2 + §1.2.4 每页脚注）——正文用 `\footfullcite{citekey}` 插入完整 GB/T 7714 条目脚注；文末参考文献表由 `\makebibliography` 按文献类型自动分节（一、期刊论文 / 二、专著 / …）。
5. **中文条目**：`陈建军 and 车建文` 形式直接支持；gb7714-2015 正确处理中英混排 + `langid={chinese}`。
6. **页码连字符**：`pages = {223--234}` 用 en-dash `--`（GB/T 7714），不要用 `$\sim$`。

改完 `.bib` 后必须重跑 biber（`latexmk -xelatex main` 自动多遍；或手跑上面的 *原始序列*）。

---

## 6. 标题编号惯例 (Heading Numbering)

spec §2.10 支持两种编号方式，经 `\documentclass` 选项切换：

```latex
\documentclass[doctor]{htuthesis}                 % 默认 hs：人文社科
\documentclass[doctor,numbering=sc]{htuthesis}    % sc：自然科学
```

| 模式 | 一级 | 二级 | 三级 | 四级 |
|------|------|------|------|------|
| `hs`（默认，人文社科） | 第一章 | 第一节 | 一、 | （1） |
| `sc`（自然科学） | 1 | 1.1 | 1.1.1 | （1） |

- hs：一二级居中，三级及以下居左空两格。
- sc：一至三级居左顶格。
- 标题字号（两模式共用）：一级三号黑体、二级小三号黑体、三级四号黑体、四级小四号宋体加粗。

---

## 7. 验证 (Verification)

- **格式审查清单：** [`verify/checklist.md`](verify/checklist.md)——逐条映射 spec §1.1–§2.17 规则到实现，标注「自动检查/人工确认」。
- **自检报告：** 每次编译 `main.log` 末尾自动输出 `=== HTU Layout Self-Check ===` … `=== End Self-Check ===` 块（页边距/行距/字体/14 项静默失败断言）。
- **物理边距：** `make calibrate` 生成标尺 PDF，打印后 overlay 比对 `main.pdf`。
- **编译健康：** `make compile-check`（rc=0）、`make structure-check`（目录健全）。
- **基线快照：** [`verify/baseline/`](verify/baseline/)（页数 + 章节起始页，未来格式改动的回归参照）。

> **Windows 无 `make`？** 上述 `make` 目标可用原始命令替代：编译健康 = `latexmk -xelatex main`（rc=0）；物理边距 = `cd tools && xelatex calibrate.tex`；结构检查 = `bash tests/check-structure.sh`。（`latexmk` 自动跑 biber，无需手操。）

---

## 参考

- spec 真值源：`河南师范大学研究生学位论文格式要求.md`（仓库根）
- 格式校准记录：`htuthesis.def` `[基础]` 注释（每参数标注真值源）
- 真值源层次：spec 优先；参考论文 PDF 仅 spec 沉默时辅助（见 `CLAUDE.md`）。
