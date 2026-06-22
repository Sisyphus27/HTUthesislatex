# htuthesis 详细使用指南

> 本文档是 `README.md`（快速开始）的完整参考版。README 教你「5 分钟出 PDF」；本文教你「彻底用对、调对、排错」。
>
> 真值源层次（CLAUDE.md）：① `河南师范大学研究生学位论文格式要求.md`（spec，**优先**）② 参考论文 PDF（辅助）③ `htuthesis.def` 的 `[基础]` 注释（实现记录）。三者冲突时以 spec 为准。

---

## 目录

1. [概述](#1-概述)
2. [文档类选项](#2-文档类选项)
3. [用户命令完整参考](#3-用户命令完整参考)
4. [环境完整参考](#4-环境完整参考)
5. [文件结构详解](#5-文件结构详解)
6. [编译工作流](#6-编译工作流)
7. [可调参数（htuthesis.def）](#7-可调参数htuthesisdef)
8. [自检与验证基础设施](#8-自检与验证基础设施)
9. [关键机制深解](#9-关键机制深解)
10. [常见任务速查](#10-常见任务速查)
11. [故障排查](#11-故障排查)
12. [FAQ](#12-faq)
13. [依赖清单](#13-依赖清单)
14. [测试套件](#14-测试套件)

---

## 1. 概述

**htuthesis** 是河南师范大学（HTU）**博士学位论文** LaTeX 模板。源自 ThuThesis（清华），按 HTU 研究生院格式要求改写。

| 属性 | 值 |
|------|-----|
| 支持学位 | **博士（doctor）**——本科/硕士选项已移除，传入即 `\ClassError` |
| 引擎 | **XeLaTeX 唯一**（cls:55-59 硬门；pdflatex/lualatex 不支持） |
| TeX 发行版 | TeX Live 2025 起 |
| 基类 | `ctexbook`（cls:50-54，`zihao=-4, a4paper, twoside, UTF8, scheme=plain`） |
| 文献后端 | **biblatex + biber + gb7714-2015**（非 bibtex） |
| 必需字体 | SimSun / SimHei / KaiTi / FangSong / Times New Roman（缺一即 halt，cls:78-97） |
| 版本 | `\version` = `1.0.0`（cls:16） |

**核心文件 2 个**：`htuthesis.cls`（排版引擎，勿改）+ `htuthesis.def`（可调参数，全部带 `[基础]` 真值源注释）。

---

## 2. 文档类选项

`\documentclass[<options>]{htuthesis}`（声明于 cls:20-42，cls:46 处理）：

| 选项 | 默认 | 作用 | spec |
|------|------|------|------|
| `doctor` | **开** | 博士模式（唯一支持的学位） | — |
| `bachelor` / `master` | — | **硬报错**——已移除，模板仅支持博士 | — |
| `numbering=hs` | **默认** | 人文社科编号：`第一章/第一节/一、/（1）`，L1-L2 居中、L3+ 左缩进 2\ccwd，编号名后不空格 | §2.10 HS |
| `numbering=sc` | 关 | 自然科学编号：`1/1.1/1.1.1/（1）`，全部顶格，编号名后空半格 | §2.10 NS |
| `openany` | **默认** | 章节可在任意页起始 | — |
| `openright` | 关 | 章节起始右页（奇数页） | §2.4 仅 2 起始页须右页 |
| `debug` | 关 | 激活 `\ifhtu@debug` → `\htucheck` 追加 `--- debug diagnostics ---` 段（baseline 对比 + NFR-5 监视列表）。**ADD-only**：默认自检输出不变 | NFR-5 |
| 其他 | — | 透传给 `ctexbook` 基类 | — |

**main.tex 用法**：`\documentclass[doctor]{htuthesis}`（默认 hs + openany，匹配参考论文「政治与公共管理学院」）。

**切换自然科学编号**：`\documentclass[doctor,numbering=sc]{htuthesis}`。

---

## 3. 用户命令完整参考

### 3.1 封面元数据命令（在 `data/cover.tex` 设置）

全部由 `\htu@def@term` 生成器定义（cls:640-681），存入内部 `\htu@foo`。

| 命令 | 含义 | 必需？ | 默认/示例 |
|------|------|--------|-----------|
| `\schoolcode{...}` | 单位代码 | — | `10476`（.def:23） |
| `\id{...}` | 学号（~10 位） | 是 | `2024000001` |
| `\secretlevel{...}` | 分类号（中图法） | 是 | ⚠ 命令是 `\secretlevel`，**非** `\classification` |
| `\ctitle{...}` | 中文题目（≤20 字） | **是**（空则 `\makecover` halt，cls:862） | — |
| `\cauthor{...}` | 中文作者 | 是 | — |
| `\csubject{...}` | 中文学科门类 | 是 | `政治学` |
| `\cmajor{...}` | 中文学科专业 | 是 | `政治学理论` |
| `\researchdirection{...}` | 研究方向 | 是 | — |
| `\degreecategory{...}` | 申请学位类别 | 是 | `法学博士` |
| `\csupervisor{...}` | 中文指导教师 | 是 | — |
| `\protitle{...}` | 指导教师职称 | — | `教授`（博士封面不渲染，保留） |
| `\stuno{...}` | 本科学号 | — | 博士封面不渲染，保留无害 |
| `\cdate{...}` | 中文日期 | — | **自动**：`\zhdigits{\the\year} 年 \zhnumber{\the\month} 月` = 编译日中文（cls:674）。需显式提交日时：`\cdate{二〇二五年五月}` |
| `\etitle{...}` | 英文题目（Title Case） | **是**（空则 halt，cls:863） | — |
| `\eauthor{...}` | 英文作者 | 是 | — |
| `\esupervisor{...}` | 英文指导教师 | 是 | `Prof. Wu Zhengwang` |
| `\edegree{...}` | 英文学位类别 | — | `Doctor of Philosophy in Science`（cls:681）。法学博士：`\edegree{Doctor of Law}` |
| `\emajor{...}` / `\edepartment{...}` | 英文专业/院系 | — | ⚠ **当前英文封面不渲染**（cls:785 AC-4：参考论文 + .doc 均无此两行） |
| `\edate{...}` | 英文日期 | — | **自动**：`Month, Year`（cls:675-677） |

### 3.2 前置/主体/后置命令

| 命令 | 位置 | 作用 |
|------|------|------|
| `\makecover` | frontmatter 起 | 生成封面 + 英文扉页 + 摘要。`\ctitle`/`\etitle` 空即 halt |
| `\frontmatter` | 摘要前 | 罗马页码、`\pagestyle{htu@plain}`、hs 模式章标题居中 |
| `\tableofcontents` | 摘要后 | 生成目录（`目 录`，cls:613-615） |
| `\listoffigures` / `\listoftables` | 目录后 | 插图清单 / 表格清单 |
| `\mainmatter` | 正文前 | 阿拉伯页码、`\pagestyle{htu@headings}`、`\cleardoublepage` |
| `\backmatter` | 参考文献前 | 标记 `\@mainmattertrue`，不改页码 |
| `\appendix` | 附录前 | 切换附录字母编号（A/B...）。**命令式**，非 `\begin{appendix}`（见 §9.4） |
| `\makebibliography` | 参考文献处 | 按文献类型分节生成文末表（见 §9.3） |
| `\makedeclaration` | 文末 | 生成独创性声明 + 授权说明（cls:881-882） |

### 3.3 摘要与关键词

| 命令/环境 | 用法 | 说明 |
|-----------|------|------|
| `cabstract` 环境 | `\begin{cabstract}...\end{cabstract}` | 中文摘要正文（`abstract.tex:8`） |
| `eabstract` 环境 | `\begin{eabstract}...\end{eabstract}` | 英文摘要正文 |
| `\ckeywords{k1, k2, ...}` | 逗号分隔 | 中文关键词，输出重连为全角分号 `；`（cls:221）。标签 `关键词：` 黑体 |
| `\ekeywords{k1, k2, ...}` | 逗号分隔 | 英文关键词，输出重连为 `, `（cls:224）。标签 `KEY WORDS:` 加粗 |

### 3.4 正文命令

| 命令 | 作用 |
|------|------|
| `\chapter{}` / `\section{}` / `\subsection{}` / `\subsubsection{}` | 标准 ctex 标题，按 §2.10 格式化（见 §2 编号模式） |
| `\cite{key}` / `\parencite{key}` | **case-1 正文引文**：渲染 `[N]` 方括号编号（一般学科默认，GB/T 7714 顺序编码制）。上标式用 `\supercite{key}` |
| `\footfullcite{key}` | **case-2 正文引文**：完整 GB/T 7714 条目作每页脚注（政治学等页下注学科）。小五号宋体 |
| `\footfullcite[][26]{ding2001}` | case-2 带页号 `26`（可选参数） |
| `\eqref{label}` | 公式交叉引用，渲染全角括号 `（1-1）`（cls:452 `\tagform@`） |
| `\ref{label}` | 通用交叉引用。章引用渲染中文（`一/二`）；图表渲染阿拉伯（`图 1-1`）——双轨符合 HS 惯例 |
| `\includegraphics[opts]{name}` | 插图。搜索路径 `{figures/}`，扩展名 `.pdf,.eps,.png,.jpg,.jpeg` |
| `\caption{}` / `\label{}` | 浮动体题注。标签分隔符 = `\hspace{0.5\ccwd}`（空半格，cls:420） |
| `\Xhline{width}` | 表格可控粗细横线（cls:439-441，替代 `\hline`） |

### 3.5 数学/定理命令（cls:458-480）

定理风格 `\newtheoremstyle{theorem}`：正文 `\rmfamily`，标签 `\sffamily\htu@tnr`（黑体+TNR），分隔符 `：`。

| 环境 | 编号方式 | 显示名 |
|------|----------|--------|
| `definition` | 按章 `[chapter]` | 定义 |
| `theorem` | 按章 | 定理 |
| `lemma` | 共享 theorem 计数 | 引理 |
| `corollary` | 共享 theorem 计数 | 推论 |
| `proof` | 不编号，QED | 证明（默认 `\proofname`；`\begin{proof}[自定义标题]` 可覆盖） |

用法：`\begin{theorem}...\end{theorem}`。示例见 `data/chap04.tex`。

### 3.6 字号命令（cls:243-263）

`\cmd[linespread]` 形式，默认 linespread=1.3：

`\chuhao`(42) `\xiaochu`(36) `\yihao`(26) `\xiaoyi`(24) `\erhao`(22) `\xiaoer`(18) `\sanhao`(16) `\xiaosan`(15) `\sihao`(14) `\banxiaosi`(13) `\xiaosi`(12) `\dawu`(11) `\wuhao`(10.5) `\xiaowu`(9) `\liuhao`(7.5) `\xiaoliu`(6.5) `\qihao`(5.5) `\bahao`(5)（单位 bp）。

例：`\xiaosi[1.5]` = 小四 + 1.5 倍行距。

### 3.7 ctex 标准字体族

`\songti`（宋体/SimSun，正文默认）`\heiti`（黑体/SimHei）`\fangsong`（仿宋/FangSong）`\kaishu`（楷体/KaiTi）。

### 3.8 自检/调试命令

| 命令 | 作用 |
|------|------|
| `\htucheck` | 自检块（cls:1067-1165），`\AtEndDocument` 自动运行；亦可手写调用 |
| `\version` | → `1.0.0` |
| `\htuthesis` | → `HtuThesis` |

---

## 4. 环境完整参考

| 环境 | 定义 | 用法/行为 |
|------|------|-----------|
| `cabstract` | cls:891 | `\begin{cabstract}...\end{cabstract}` 收集中文摘要正文 |
| `eabstract` | cls:893 | 收集英文摘要正文 |
| `denotation` | cls:949-964 | 主要符号对照表。可选参数 = 标签列宽（默认 2.5cm）。`\begin{denotation}[1.5cm] \item[E] 能量 \end{denotation}`。宋体五号 16bp |
| `ack` | cls:968-975 | 致谢。正文 `\songti\xiaosi[1.524]`。标题 `致 谢` 三号黑体居中 |
| `resume` | cls:1059-1060 | 攻读学位期间发表论文目录。可选参数 = 标题。正文 `\wuhao[1.524]` |
| `appendix` | cls:1034-1055 | **命令式**：`\appendix` 非 `\begin{appendix}`（见 §9.4）。切字母编号，局部 `\xiaosi\songti` |
| `proof` | cls:468-475 | 数学证明，QED。`\begin{proof}[标题]` |
| `theorem`/`definition`/`lemma`/`corollary` | cls:477-480 | amsthm 定理族 |
| 标准 | — | `figure`/`table`/`tabular`/`tabularx`/`longtable`/`equation`/`align`/`gather`/`multline`/`itemize`/`enumerate`（L1/L2/L3 标签自定 cls:384-388）/`description`/`minipage`/`titlepage` |
| `latex`/`shell` | docutils.sty:65-66 | 代码展示（listings），仅示例文档用 |

**新列类型**：`Z`（cls:438）= `>{\centering\arraybackslash}X`，tabularx 居中自适应列。

---

## 5. 文件结构详解

| 路径 | 用途 | 用户改？ |
|------|------|----------|
| `main.tex` | 入口：documentclass、`\graphicspath`、front/main/backmatter、`\include` 顺序 | **是**（结构调整：增删章） |
| `htuthesis.cls` | 文档类（~1176 行）：选项、宏包、字体、几何、标题、封面、文献、附录、自检 | **否**（排版引擎） |
| `htuthesis.def` | 外置参数（带 `[基础]` 真值源注释）。User Zone（边距/字体/间距）+ Advanced Zone（浮动/题注） | **调格式时改** |
| `htuthesis.bst` | GB/T 7714-2015 BibTeX 样式 | 否 |
| `Makefile` | 构建目标 | 否（除非加目标） |
| `docutils.sty` | 示例文档辅助包（listings 风格、`latex`/`shell` 环境、`\BibTeX`/`\TeXLive` logo） | 否 |
| `README.md` | 快速开始 | 否 |
| **data/** | **用户写作区** | |
| `data/cover.tex` | 封面元数据（`\ctitle` 等） | **是**（首改文件） |
| `data/abstract.tex` | `cabstract`+`eabstract`+关键词 | 是 |
| `data/chap01.tex` | 第 1 章示例（TeX/LaTeX 概述）。演示 `\footfullcite[][26]{ding2001}` | 是（替换为自己的） |
| `data/chap02.tex` | 第 2 章示例（模板简介）。演示 longtable、`\htuthesis` 宏 | 是 |
| `data/chap03.tex` | 第 3 章示例（使用说明）。演示 `\lstinputlisting`、选项/命令文档 | 是 |
| `data/chap04.tex` | 第 4 章示例（排版示例）。演示图、subcaptionbox、表、数学、定理 | 是 |
| `data/app01.tex` | 附录 A（表格附件）。演示附录浮动体编号 `图 A-1`/`表 A-1`/`（A-1）` | 是 |
| `data/app02.tex` | 附录 B（英文） | 是 |
| `data/app03.tex` | 附录 C（app02 中文译） | 是 |
| `data/ack.tex` | 致谢示例。末尾有作者姓名+日期占位（ack.tex:43-45） | 是 |
| `data/resume.tex` | 发表论文目录示例。演示 `\resumeitem`、反悬挂 enumerate | 是 |
| `data/denotation.tex` | 符号表示例 | 是（不用则删 `\include`） |
| `ref/refs.bib` | 13 条示例条目（@article/@book/@incollection/@phdthesis/@patent/@standard/@online） | **是**（替换为自己的） |
| `figures/` | `htu-logo.pdf`、`htu-text-logo.pdf`（校徽/校名图）、`golfer.eps`/`qingming.eps`/`fanfu.eps`（示例图） | 替换为自己的图 |
| `tools/calibrate.tex` | 独立 A4 标尺页（`\documentclass{article}`，非 htuthesis）。镜像 .def 边距 | 否（`make calibrate` 构建） |
| `tools/calibrate-overlay.cfg` | 可选 overlay（改色，演示 `\InputIfFileExists`） | 否 |
| `verify/checklist.md` | 格式审查清单（#1 交付物）：~95 规则行，自动/人工标注 | 否（参考文档） |
| `verify/baseline/page-count.txt` | 快照：`total_pages = 52` | 否（回归参考） |
| `verify/baseline/chapter-start-pages.txt` | 各章起始页快照 | 否 |
| `tests/` | ATDD 测试套件（73 个 .sh，Epic 1-4）。命名 `test-story-{E}.{S}-{unit\|integration}.sh` | 否 |
| `spine.tex` / `a3cover.tex` | 书脊 / A3 封面生成器 | 否 |

---

## 6. 编译工作流

### 推荐：latexmk（自动多遍）

```bash
latexmk -xelatex main
```

`LATEXMKOPTS = -xelatex -file-line-error -halt-on-error -interaction=nonstopmode`（Makefile:3）。自动 xelatex → biber → xelatex ×N 直至交叉引用收敛。

### 原始序列（改了 `refs.bib` 或无 latexmk 时）

> ⚠ 本模板用 **biber**（非 bibtex）——`biblatex[backend=biber]`（cls:139）。`bibtex main` **不生效**。

```bash
xelatex main      # 第 1 遍：生成 .aux/.bcf
biber main         # 处理文献 → .bbl（必须 biber）
xelatex main      # 第 2 遍：应用 .bbl
xelatex main      # 第 3 遍：解析交叉引用
```

**biber 必须重跑的时机**：改 `.bib` 后、增删 `\footfullcite` 后、改 `\nocite` 后。`latexmk` 自动检测；手跑需完整 4 命令。

### Make 目标

| 目标 | 作用 |
|------|------|
| `make` / `make all` | `thesis` + `a3cover` |
| `make thesis` | `latexmk main` → main.pdf |
| `make a3cover` | 构建 spine.pdf → a3cover.pdf |
| `make clean` | `latexmk -c` + 删 `*.bbl *.exa *.xdv data/*.aux` |
| `make test` | compile-check + lint-check + structure-check |
| `make compile-check` | 构建 main.pdf，rc=0 |
| `make lint-check` | `chktex -q -l .chktexrc` |
| `make structure-check` | `bash tests/check-structure.sh`（必需文件/章数/图引用/bib key/编码） |
| `make calibrate` | `cd tools && xelatex calibrate.tex` → calibrate.pdf（**可选**，不在 all/test） |
| `make debug-check` | sed-copy main.tex → `.debug-main.tex` 加 `[doctor,debug]`，编译，grep 6 类 NFR-5 warning 签名，命中即 exit 1（**可选**） |

### Windows 无 make 回退

- 编译：`latexmk -xelatex main`（latexmk 随 TeX Live 提供）
- 标尺：`cd tools && xelatex calibrate.tex`
- 结构检查：`bash tests/check-structure.sh`

---

## 7. 可调参数（htuthesis.def）

`.def` 分 **User Zone**（def:9-110，常调）+ **Advanced Zone**（def:112-180，少动）。每项带 `[基础]` 真值源注释。改法：编辑 `\def\htu@...{...}` 值，重编译。

### 7.1 学校身份

| 参数 | 行 | 默认 |
|------|----|----|
| `\htu@schoolname` | def:17 | `河南师范大学` |
| `\htu@schoolname@en` | def:20 | `Henan Normal University` |
| `\htu@schoolcode@value` | def:23 | `10476` |

### 7.2 页面几何（spec §2.3）

| 参数 | 行 | 默认 | 约束 |
|------|----|----|------|
| `\htu@topmargin` | def:30 | `22mm` | 页顶到页眉顶。约束：top + headheight + headsep = 30mm（正文顶） |
| `\htu@bottommargin` | def:35 | `17.5mm` | 页脚基线到页底。约束：footskip + bottom = 25mm（正文底） |
| `\htu@leftmargin` / `\htu@rightmargin` | def:38/41 | `25mm` | §2.3 左右边距 |
| `\htu@headerheight` | def:45 | `5.6mm` | fancyhdr headheight（≥ 五号字 + 2pt + 横线） |
| `\htu@headsep` | def:50 | `2.4mm` | 派生：30 − 22 − 5.6 |
| `\htu@footskip` | def:54 | `7.5mm` | 派生：25 − 17.5 |

### 7.3 正文字体/间距（spec §2.7/§2.9）

| 参数 | 行 | 默认 | 说明 |
|------|----|----|------|
| `\htu@body@fontsize` | def:59 | `12bp` | 小四 |
| `\htu@body@baselineskip` | def:66 | `23.4bp` | **Word 1.5× 语义**（非朴素 1.5×12=18）。参考 PDF 行隙实测标定（Story 3.11，G-D） |
| `\htu@display@skip` / `\htu@display@stretch` | def:69/72 | `12bp`/`2bp` | 展示式间距 |

### 7.4 标题间距（spec §2.10）

| 参数 | 行 | 默认 | = |
|------|----|----|----|
| `\htu@chapter@beforeskip` / `afterskip` | def:77/80 | `46.8bp` | 2 行（2×23.4） |
| `\htu@chapter@linespread` | def:83 | `1` | L1 |
| `\htu@section@beforeskip` / `afterskip` | def:86/89 | `11.7bp` | 0.5 行 |
| `\htu@section@linespread` | def:92 | `1.429` | L2 |
| `\htu@subsection@...` | def:95-101 | `11.7bp` / `1.538` | L3 |
| `\htu@subsubsection@...` | def:104-110 | `11.7bp` / `1.667` | L4 |

### 7.5 Advanced Zone（def:112-180）

浮动体布局（`\htu@floatsep` `12bp`、`\htu@textfraction` `0.15`、`\htu@topfraction` `0.85`、`\htu@bottomfraction` `0.50`、`\htu@floatpagefraction` `0.80`）、题注间距（图表上下 `6bp`、图下 `12bp`、子图 `6bp`）、计数器分隔符 `\htu@counter@separator{-}`（§2.11/12/13 用 `-` 非 `.`）、页眉横线 `\htu@header@rule@thickness{.4\p@}`、脚注行距 `1.5`、`\htu@secnumdepth{3}`、`\htu@tocdepth{2}`、摘要关键词间距 `12bp`。

---

## 8. 自检与验证基础设施

### 8.1 `\htucheck` 输出（cls:1067-1165，`\AtEndDocument` 自动）

`main.log` 末尾的 `=== HTU Layout Self-Check ===` 块结构：

```
=== HTU Layout Self-Check ===
textheight = <pt>          ← 8 个尺寸行（不可变契约，勿改）
textwidth = <pt>
baselineskip = <pt>
headheight = <pt>
evensidemargin = <pt>
oddsidemargin = <pt>
total pages = <N>
page counter = <N>
[WARNING 段：margin 漂移 >1mm 或 baselineskip 漂移 >0.5bp 时 \PackageWarning]
--- font check ---
SimSun/SimHei/KaiTi/FangSong/Times New Roman: found [PASS] | missing [ERROR]
--- silent-failure coverage map (15 lines) ---
[01] body baselineskip ~23bp (Word 1.5x): ASSERTED
[02] EN-abstract baselineskip 23.4bp: PROXIED -- rendered guard ATDD-3.4-I06
... [03]-[15]
--- assertion audit ---
PROXIED: [01] baselineskip-for-spacing, [02] EN-abstract baselineskip
[--- debug diagnostics ---  仅 [debug] 选项]
[debug] 实际值 vs baseline 对比
--- NFR-5 warning-as-error watch list ---
[1] Overfull \hbox  [2] geometry Over-specification  [3] fancyhdr headheight too low
[4] natbib/biblatex undefined Citation  [5] hyperref Token not allowed  [6] caption option reset
=== End Self-Check ===
```

**三档证据语义**（关键）：
- **ASSERTED**：编译期可观测（`\the<dim>`、.aux、.log 扫描）。绿 = 真证据。
- **PROXIED**：内部尺寸代理了渲染属性（如 baselineskip 代理行距）。**绿 ≠ spec 合规**——真证据是所引的 fitz ATDD（R-25 wrong-target-AC 纪律）。
- **RENDERED**：由 fitz/PyMuPDF ATDD 测试拥有（span 级字体/字号/位置），非 `\htucheck`。

**WARNING 档**（cls:1082-1097，`\PackageWarning` 非致命）：margin 漂移 >1mm、baselineskip 漂移 >0.5bp、total pages=0。记日志+继续（exit 0，PDF 生成）。

**ERROR 档**（cls:1102-1106，`\PackageError` 致命）：自检块内发现缺字（cls:78-97 应已先 halt，此为 defense-in-depth）。

### 8.2 `[debug]` 选项输出

ADD-only（4.2 段始终开，AC-8）。报告实际 vs baseline 尺寸 + 列 NFR-5 监视列表，让开发者知道 `make debug-check` 会强制什么。

### 8.3 `make calibrate`

独立 TikZ 标尺页（`tools/calibrate.tex`，`\documentclass{article}` 非 htuthesis）。镜像 .def 正文边距：正文 160mm × 242mm、顶 30、底 25、左右 25、页眉横线 27.5、页脚 17.5（mm）。打印后 overlay 比对 main.pdf。

### 8.4 `make debug-check`

sed-copy main.tex → `.debug-main.tex` 加 `[doctor,debug]`，编译，grep `.log` 6 类 NFR-5 签名（排除自身监视列表行）。命中即 exit 1；干净树 exit 0。SUT（main.tex）不动。

### 8.5 `verify/checklist.md` 结构

- 真值源层次（spec 优先）
- 图例：自动检查 / 人工确认 / PROXIED 警示
- ~95 规则行：§1.1-§1.5 结构 + §2.1-§2.17 排版 + §3 通用标准
- 透明偏差表：G-C（Title Case）/ G-D（行距 23.4bp 巧合）/ G-E（内联 ASCII 12pt）
- 附录 A（`\htucheck` 输出参考）/ B（开发工具）/ C（ATDD 索引）

### 8.6 `verify/baseline/`

- `page-count.txt`：`total_pages = 52`
- `chapter-start-pages.txt`：ch1=1, ch2=7, ch3=9, ch4=18, refs=30, appA=32, appB=38, appC=39, ack=40, resume=41, declaration=42

---

## 9. 关键机制深解

### 9.1 `\sffamily\htu@tnr` 模式（CJK 黑体 + Latin TNR）

`\sffamily` 把 CJK 切到 SimHei（`\setCJKsansfont{SimHei}` cls:119），但其 Latin 会泄漏到 LMSans（默认无衬线 Latin）。所以标题里的「TeX/LaTeX」会渲染成 LMSans 而非 TNR。

解法：`\newfontfamily\htu@tnr{Times New Roman}`（cls:130，**只切 Latin，不动 CJK**）。`{\sffamily\htu@tnr...}` = CJK 黑体 + Latin TNR。全模板所有 `\sffamily` 站点（标题/目录/封面/定理头/文献分节/resumeitem）都已配 `\htu@tnr`（Epic 3 retro action #5 + 2026-06-21 补全 6 处）。

### 9.2 `numbering=sc|hs` 双模式标题

**hs 默认**（cls:493-535）：`第一章/第一节/一、/（1）`。L1-L2 居中，L3+ 左缩进 2\ccwd，`aftername={}`（不空格，§2.10 HS）。

**sc 可选**（cls:540-561）：`1/1.1/1.1.1/（1）`。全顶格（无 `\centering`），`aftername=\hspace{0.5\ccwd}`（空半格，§2.10 NS）。

**AC-3a 守卫**（cls:562-568，关键）：`\thechapter` 防御性锁为 `\@arabic\c@chapter`。因 ctex `number=\chinese{chapter}` 只写 `\CTEXthechapter`（显示），不写 `\thechapter`（计数器宏）。此锁确保图表公式编号保持 `图 1-1`/`表 1-1`/`(1-1)`（阿拉伯，§2.11/12/13），即使章显示是 `第一章`。`\appendix` 运行时 `\gdef\thechapter=\@Alph` 覆盖此锁以生成附录 `A-1`。

**副作用**（2026-06-19 代码评审接受）：章 `\ref{ch:X}` 渲染中文（`一/二`），图 `\ref{fig:X}` 渲染阿拉伯——双轨符合 HS 惯例。

### 9.3 biblatex gb7714-2015 + biber + 双模式引文

本模板支持 **两种引用模式**（同一 `ref/refs.bib`，仅正文命令不同，按学科惯例选）：

**case-1 顺序编码制（一般学科默认，GB/T 7714 标准）**
- 正文：`\cite{key}` 或 `\parencite{key}` → `[N]` 方括号编号（读者按 N 查文末表）。
- 上标式：`\supercite{key}` 或 `\textsuperscript{\cite{key}}` → `^[N]`。
- 文末表：`\makebibliography`（推荐，按类型分节）或 `\printbibliography`（仅列已引用条目，按 `sorting=nyt` 作者序）。

**case-2 分页脚注（政治学等需页下完整著录的学科，§2.14 + §1.2.4）**
- 正文：`\footfullcite{key}` → 完整 GB/T 7714 条目作**每页脚注**，小五号宋体，每页重置（`footmisc[perpage]` cls:401）。
- 带页号：`\footfullcite[][26]{key}`。
- 文末表：`\makebibliography`（与 case-1 同）。

**两种模式共用**
- `\makebibliography`（cls:1007-1019）= `\nocite{*}`（含全部条目：引用的 + 只读的）+ 6 类过滤 `\printbibliography`（每类 `resetnumbers=true`，从 [1] 重启）：
  - 一、期刊论文（article）/ 二、著作（book）/ 三、论文集章节（incollection）/ 四、学位论文（thesis，biber 映射 @phdthesis→thesis）/ 五、专利（patent）/ 六、电子资源（online）/ 七、其他（catch-all，`\htu@printbibother` cls:1023-1029）
- 后端 = **biber**（非 bibtex）。样式 = **gb7714-2015**。sorting=nyt（文末表作者序）；defernumbers=true + 每节 resetnumbers。
- **示例论文（`data/*.tex`）默认用 case-2**（对齐参考博士论文，政治与公共管理学院）。改 case-1：把正文 `\footfullcite{...}` 全换 `\cite{...}`，`\makebibliography` 不变；若文末表只想列已引用条目（非 `\nocite{*}` 全量），用 `\printbibliography` 替换 `\makebibliography`。

### 9.4 `\appendix` 命令式 + 下游字体自重置

`\renewenvironment{appendix}`（cls:1034-1055）使 `\appendix` 成为**命令式**（main.tex:49 用 `\appendix` 非 `\begin{appendix}`）。后果：BEGIN 子句 `\xiaosi\songti` 执行，但 END 子句 `{}` **永不触发**（只有 `\end{appendix}` 会触发——从不调用）。所以 G5a 字体重置不能依赖 END。

缓解（cls:1049-1054）：下游 backmatter 环境各自在入口重置字体——`ack`（`\songti\xiaosi[1.524]`）、`resume`（`\wuhao[1.524]`）、`\makedeclaration`（`\xiaosi[1.6]`）。故附录 `\xiaosi\songti` **不泄漏**到致谢/简历/声明（TC-E4-08 验证）。选命令式而非环境式，因 `\include` 跨文件 + 环境作用域脆弱。

附录编号：`\appendix` 使 `\thechapter` = `\@Alph` → `\thefigure/\thetable/\theequation` 自动渲染 `A-1`（§2.11/12/13）。

### 9.5 透明偏差（已记录，非 bug）

| ID | 偏差 | 真值源 | 理由 |
|----|------|--------|------|
| **G-C** | 英文题目用 **Title Case** 非 ALL CAPS | 参考 PDF（通过评审）+ spec §1.1.1「用大写字母」读作「正规大写」 | ALL CAPS 非论文题目惯例；参考论文以 Title Case 通过 |
| **G-D** | 中文正文 + 英文摘要 baselineskip 均为 **23.4bp**（巧合） | 参考 PDF 行隙实测 + spec §2.7（1.5 倍）/§2.8（2 倍） | 1.5×小四 ≈ 2×五号 ≈ 23.4bp；两者均 spec 合规。非 31.2bp |
| **G-E** | 正文内联 ASCII = **小四（12pt）** 非五号 | 参考 PDF | 贴 CJK 网格；§2.9 管 CJK 正文（小四），内联 ASCII 从之。低影响 |
| 封面日期 | 用**编译日**中文数字 | spec §1.1.1「用中文表示」（字形合规） | 日期值非显式提交日；可 `\cdate{二〇二五年五月}` 覆盖 |

### 9.6 不可变 `\htucheck` 输出契约

**勿改** 8 个尺寸 `\typeout` 行（cls:1071-1078）或段标记（cls:1068,1101,1111,1132,1144,1164）。22+ Epic 2-3 ATDD 消费者 + Story 4.4 checklist 都 grep 这些精确 `name = value` 前缀。

`\typeout` 文本里**避免**字面 `!` / `!=`（cls:1130-1131 注）：换行日志行若以 `!` 起会误触标准 `^!` TeX 错误 grep。

### 9.7 每页脚注重置（cls:391-401）

`footmisc[perpage]` 强制每页脚注重编号（§1.2.4 line 109、§2.14 line 291）。替代旧 `\@addtoreset{footnote}{page}`（biblatex 的 AtBeginDocument 覆盖使其失效）。footmisc 作用于 `\footnote` 层 → `\footnote` 与 biblatex `\footfullcite`（经 `\footnote`）均每页重置。**不影响**页码计数器（页码连续）。

### 9.8 公式全角括号 `（1-1）`（cls:447-452）

`\renewcommand{\tagform@}` 覆盖 amsmath 默认 ASCII `(...)` 为全角 `（...）`（§2.13 line 279）。同时作用于公式标签（`\@eqnnum`）和 `\eqref` 交叉引用。

### 9.9 题注标签分隔符 = 空半格（cls:420）

`\DeclareCaptionLabelSeparator{htu}{\hspace{0.5\ccwd}}` = 0.5 字距。spec §2.11/§2.12 **优先**（CLAUDE.md Decision 4 fix）。参考 PDF 用全角冒号「：」（Word 填充实例，偏离 spec）——**不从**。

### 9.10 宋体加粗 via AutoFakeBold（cls:98-101）

SimSun 无原生粗体。ctex 默认把 CJK 粗体映射到 SimHei。但 L4 标题需「小四宋体加粗」（§2.10），模板定义 `\newCJKfontfamily\htu@songtibold{SimSun}[AutoFakeBold=2.5]`，用 `\htu@songtibold\bfseries`（cls:530）→ 字体名仍 SimSun，算法加粗。ATDD-2.5-28 用墨密度验证（**非** font flags——G-B 教训）。

### 9.11 空白 verso 页清空（cls:321-331）

`\cleardoublepage` 重定义：空白 verso 页赋 `\thispagestyle{empty}` + `\hbox{}\newpage`——确保真正空白（无页眉/页码残留）。Story 3.14 把 `\htu@chapter*` 的 `\cleardoublepage` 改 `\clearpage`，使仅 2 处起始须右页（中文摘要起 + 绪论起），空白页 ≤2。

### 9.12 前置 matter 页眉自禁用（cls:362-367）

`htu@headings` 样式检查 `\if@mainmatter`：前置 matter 中自禁用 headrule（`\headrulewidth=0pt`，无 `\fancyhead`）——等价 `htu@plain`。一处覆盖所有前置章页（摘要/目录/清单/符号表），按 spec §2.5「从主体部分开始」。

---

## 10. 常见任务速查

### 改页边距
编辑 `.def` §7.2：如左边距改 30mm → `\def\htu@leftmargin{30mm}`（def:38）。约束保持：top+headheight+headsep=30mm、footskip+bottom=25mm。重编译。

### 切自然科学编号
`\documentclass[doctor,numbering=sc]{htuthesis}`（main.tex:8）。

### 改行距
`.def` `\htu@body@baselineskip{23.4bp}`（def:66）。⚠ 这是 Word 1.5× 语义值，非朴素 ×fontsize。改前测参考 PDF 行隙。

### 加新文献类型分节
`\makebibliography` 已硬编码 6 类 + catch-all。新类型走「七、其他」catch-all 即可（`\htu@printbibother`）。若需独立分节，编辑 cls:1007-1019 加 `\printbibliography[type=xxx,heading=htu-refs-sub,title={八、xxx}]`。

### 覆盖封面日期
`data/cover.tex`：`\cdate{二〇二五年五月}` / `\edate{May 2025}`。

### 加图并引用
1. 放 `figures/foo.pdf`。2. 正文 `\begin{figure}\centering\includegraphics{foo}\caption{说明}\label{fig:foo}\end{figure}`。3. 引用 `图~\ref{fig:foo}`。

### 调标题间距
`.def` §7.4：如 L1 段前后改 3 行 → `\def\htu@chapter@beforeskip{70.2bp}` + `afterskip`（3×23.4）。

### 用定理
`\begin{theorem}\label{thm:1}...内容...\end{theorem}` → `\begin{proof}证明...\end{proof}`。引用 `定理~\ref{thm:1}`。

---

## 11. 故障排查

| 症状 | 原因 | 修法 |
|------|------|------|
| `! Class htuthesis Error: Font 'SimSun' not found` | 缺字体 | 装 5 字体（Windows 自带；Linux 用 fontconfig 装） |
| `! You must use XeLaTeX` | 用了 pdflatex/lualatex | 改用 `xelatex` 或 `latexmk -xelatex` |
| `Please (re)run Biber` / `[?]` 未定义引用 | 用了 `bibtex` 或未重跑 biber | `biber main` 然后 `xelatex × 2`；或 `latexmk -xelatex`（自动） |
| `bachelor`/`master` 报错 | 传了已移除选项 | 改 `\documentclass[doctor]{htuthesis}` |
| 封面 halt：`ctitle empty` | 没设 `\ctitle` | `data/cover.tex` 填 `\ctitle{...}` |
| `\classification` 未定义 | 用了错命令 | 改 `\secretlevel{...}`（分类号） |
| 标题里 TeX/LaTeX 渲染成奇怪字体 | （已修，全站点加 `\htu@tnr`）若仍出现，检查是否新加了无 `\htu@tnr` 的 `\sffamily` | 配 `\sffamily\htu@tnr` |
| 自检 WARNING：baselineskip drift | 正文末尾字体未重置（如删了 `\makedeclaration`） | 保留声明页，或忽略（非致命，4.2 Completion Notes #3） |
| `Overfull \hbox` 在 `make debug-check` 报错 | 内容超 textwidth | `make debug-check` 视为 error；修排版（断行/缩放） |
| 章引用显示「一」而非「1」 | HS 模式双轨（章中文、图阿拉伯） | 正常，符合 HS 惯例 |
| 附录编号还是 1-1 非 A-1 | 漏 `\appendix` 命令 | `\makebibliography` 后、`\include{data/ack}` 前加 `\appendix` |
| `\begin{appendix}` 报错 | 应为命令式 | 用 `\appendix`（非环境） |

---

## 12. FAQ

**Q: 为什么英文题目是 Title Case 不是 ALL CAPS？**
A: spec §1.1.1「用大写字母」解读为「正规大写」。参考论文以 Title Case 通过评审。ALL CAPS 非论文题目惯例。（G-C 透明偏差）

**Q: 为什么行距是 23.4bp 不是 18bp（1.5×12）？**
A: 「1.5 倍行距」是 Word 语义（×自然行高），非 ×fontsize。参考 PDF 行隙实测 = 23.4bp。（G-D，word-vs-latex-line-spacing）

**Q: 为什么用 `\appendix` 而非 `\begin{appendix}`？**
A: `\renewenvironment{appendix}` 使 `\appendix` 成为命令式；`\include` 跨文件 + 环境作用域脆弱。下游环境自重置字体。（§9.4）

**Q: 章引用是「一」，图引用是「1-1」，正常吗？**
A: 正常。AC-3a 守卫锁 `\thechapter` 为阿拉伯（保图表公式编号），但 ctex 章显示用中文。双轨符合 HS。

**Q: 可以删 `denotation.tex`（符号表）吗？**
A: 可以。`main.tex` 删掉对应 `\include{data/denotation}`。

**Q: 本科/硕士能用吗？**
A: 不能。模板仅支持博士（Story 1.3 移除本/硕分支）。

**Q: 能用 bibtex 吗？**
A: 不能。biblatex `backend=biber`（cls:139）。必须 `biber main`。

**Q: `make calibrate` / `make debug-check` 是干啥的？**
A: 开发工具，非必需。calibrate 生成物理边距标尺页（打印 overlay 比对）；debug-check 把 6 类 LaTeX warning 视为 error（开发期排错）。

**Q: 如何贡献/报 bug？**
A: 见 `verify/checklist.md`（规则→impl 映射）+ `_bmad-output/` 的 epic/retro 记录。

---

## 13. 依赖清单

### 宏包（cls:55-151 加载）

| 类别 | 宏包 |
|------|------|
| 基类 | `ctexbook` |
| 引擎门 | `ifxetex` |
| 布局/工具 | `environ` `xparse` `zhnumber` `tikz`(+calc) `etoolbox` `calc` `enumitem` `titletoc` |
| 数学 | `amsmath` `amsthm` `unicode-math` |
| 字体 | fontspec（`\setmainfont{TNR}` `\setCJKsansfont{SimHei}` 等） |
| 页面 | `geometry` `fancyhdr` |
| 表格 | `tabularx` `multirow` `longtable` `booktabs` `subcaption` |
| 图形 | `graphicx` |
| 文献 | `biblatex[backend=biber,style=gb7714-2015]`（+ `biblatex-gb7714-2015`） |
| 超链 | `hyperref` |
| 脚注 | `footmisc[perpage]` |
| 外置参数 | `\input{htuthesis.def}` |
| 示例专用 | `xcolor` `listings` `metalogo` `xspace`（docutils.sty） |

### 字体（5，cls:78-97）

SimSun（宋体）/ SimHei（黑体）/ KaiTi（楷体）/ FangSong（仿宋）/ Times New Roman。缺一即 `\PackageError` halt。

### 环境

- XeLaTeX 唯一（NFR-1）
- TeX Live 2025 起

---

## 14. 测试套件

`tests/` 含 73 个 ATDD 脚本（Epic 1-4），命名 `test-story-{E}.{S}-{unit|integration}.sh`。

### 跑测试

```bash
bash tests/test-story-3.6-integration.sh --run    # 跑单个（GREEN guards）
bash tests/test-story-3.6-integration.sh          # RED 相（SKIP）
bash tests/check-structure.sh                      # 结构检查
```

`--run` 激活（默认 `ATDD_SKIP=1` 跳过，避免 CI 里每个测试都重编译）。

### TC 编号

- TC-E4-01..04：Story 4.1（附录 + sc 编译）
- TC-E4-11..18：Story 4.2（自检基础设施）
- TC-E4-19..24：Story 4.3（debug + 标尺）
- TC-E4-25..31：Story 4.4（清单 + README）
- TC-E4-35：test-hardening gate sweep（R-26，~23 项，延后至 v1.x）

### 验证层级

- **Unit**：源码 grep / `.aux`/`.log`/`.bbl` 扫描 / Makefile grep
- **Integration**：编译 + fitz/PyMuPDF 行为测试（span 级字体/字号/位置 + `get_drawings` 规则线）
- **Visual**：overlay 比对参考 PDF（人工 epic gate）

---

**本文档基于** 2026-06-21 代码状态（v1.0.0）。所有命令/环境/参数引用均带 cls/def 行号，可回溯源码。
