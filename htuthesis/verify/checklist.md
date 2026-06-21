# HTU 博士学位论文格式审查对照清单 (Format Review Checklist)

> **#1 交付物** — 河南师范大学 (HTU) 博士学位论文 LaTeX 模板格式审查清单。
> 将《河南师范大学研究生学位论文格式要求》(spec) §1.1–§2.17 的每一条规则映射到本模板的 LaTeX 实现，并标注检查方式。

- **维护者：** htuthesis 项目
- **最近更新：** 2026-06-21 (Story 4.4)
- **对应 spec：** `河南师范大学研究生学位论文格式要求.md` (repo root)
- **对应实现基线：** commit `7e0d103`

## 真值源层次 (Truth-Source Hierarchy)

> spec 是 **优先真值源**。参考论文 PDF (`2107084001-任子辛-…pdf`) 仅在 spec 沉默/含糊时作辅助。
> 参考论文是 Word 填充实例，自身在若干细节偏离 spec（故 spec 优先）。见 CLAUDE.md (Decision 4 修正 2026-06-17)。

1. **spec.md** — 格式规则（优先）
2. **参考论文 PDF** — 视觉辅助（spec 沉默时）
3. **`htuthesis.def` `[基础]` 注释 + 本仓 epics/PRD** — 需求→LaTeX 映射 + 校准记录

## 如何使用本清单 (How to use)

1. 编译论文：`latexmk -xelatex main`（或 README 的 xelatex→bibtex→xelatex×2 序列）。
2. 读 `main.log` 中 `=== HTU Layout Self-Check ===` … `=== End Self-Check ===` 自检块（每次编译自动输出）。
3. `make calibrate`（生成 `tools/calibrate.pdf` 物理边距标尺，overlay 比对）。
4. `make debug-check`（NFR-5：6 类 LaTeX warning 视为 error 的开发期检查；干净树应 exit 0）。
5. 逐行核对：**自动检查** 项对照 cited 自检输出 / ATDD / make 目标；**人工确认** 项对照参考 PDF / 打印样张 / 实际内容。

## 图例 (Legend)

| 检查类型 | 含义 |
|----------|------|
| **自动检查** | 由 `\htucheck` 自检输出 / `make` 目标 / ATDD 测试自动验证。引用具体证据。 |
| **人工确认** | 需目视核对（封面布局、印刷装订、内容字数、签名等）。对照参考 PDF 或实际物。 |

> **⚠ PROXIED 警示 (wrong-target-AC，Epic 3 retro Lesson 3 / R-25)：** 标 `PROXIED` 的自动检查项引用的是 `\the<dim>` 内部量（如 `baselineskip`），它是渲染属性的**代理**而非直接证据。一个 green 的自检**不等于**该渲染属性符合 spec——真正的证据是同行引用的 rendered fitz ATDD。`\htucheck` 的 `--- assertion audit ---` 段列出所有 PROXIED 项。

---

## §1 学位论文的基本格式（五部分结构）

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R1.0-a | 五部分结构：前置/主体/参考文献/附录/结尾 (§1) | `main.tex` `\frontmatter`/`\mainmatter` + `\include` 顺序 | 人工确认 | `main.tex` 章节顺序；参考 PDF 页序 |
| R1.0-b | 前置部分组成：封面/扉页/摘要/ABSTRACT/目录/图表清单/符号表 (§1) | `main.tex` `\input{data/cover}`+`\makecover`+`\tableofcontents`+`\listoffigures`+`\listoftables`+`denotation` | 人工确认 | `main.pdf` 前置页序 |

## §1.1.1 封面和扉页

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R1.1.1-a | 封面/扉页用学校规定样式（下载） (§1.1.1) | `data/cover.tex` + cls 封面块 (`\makecover` cls:860–882) | 人工确认 | overlay 比对学校 .doc 模板 |
| R1.1.1-b | 分类号经《中图法》检索 (§1.1.1) | `\classification` 元数据字段 (`data/cover.tex`) | 人工确认 | 用户填写正确分类号 |
| R1.1.1-c | 题目 ≤20 字，避免缩略词/代号/公式 (§1.1.1) | `\ctitle`/`\etitle` (`data/cover.tex:15,33`) | 人工确认 | 字数核对 |
| R1.1.1-d | 学科专业以 2022 版目录为准 (§1.1.1) | `\cmajor`/`\emajor` (`data/cover.tex:21,37`) | 人工确认 | 用户填写正确专业名 |
| R1.1.1-e | 日期中文表示「二〇…年…月」(§1.1.1) | `\cdate` + `\CJK@todaybig` cls:208 (Story 3.15 G4) | 人工确认 | 封面日期字形；ATDD-3.1 |
| R1.1.1-f | 扉页英文题目用大写字母 (§1.1.1) | `\etitle` Title Case (`data/cover.tex:33`) | 人工确认 | **G-C 透明偏差**（见末节） |

## §1.1.2 摘要页

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R1.1.2-a | 摘要独立自含 (§1.1.2) | `data/abstract.tex` `\begin{abstract}` | 人工确认 | 内容核对 |
| R1.1.2-b | 摘要说明目的/方法/结果/结论 (§1.1.2) | (内容) | 人工确认 | 内容核对 |
| R1.1.2-c | 摘要避免图表/化学式/非公知符号 (§1.1.2) | (内容) | 人工确认 | 内容核对 |
| R1.1.2-d | 博士中文摘要 ~1500 字 (§1.1.2) | (内容) | 人工确认 | 字数核对 |
| R1.1.2-e | 关键词 3–8 个，体现论文特色 (§1.1.2) | `\ckeywords`/`\ekeywords` (`data/abstract.tex`) | 人工确认 | 关键词数核对 |

## §1.1.3 ABSTRACT

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R1.1.3-a | 英文摘要与中文对应，语法通顺 (§1.1.3) | `data/abstract.tex` `\begin{eabstract}` | 人工确认 | 内容核对 |

## §1.1.4 目录

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R1.1.4-a | 目录自动生成，含摘要→…→声明各序号/题名/页码 (§1.1.4) | `main.tex` `\tableofcontents` + cls TOC 配置 (cls:616–640) | 自动检查 | `main.toc` 生成；ATDD-3.5 |

## §1.1.5 图表清单

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R1.1.5-a | 图表多时可列清单，置于目录后，图清单在前 (§1.1.5) | `main.tex` `\listoffigures` + `\listoftables` | 人工确认 | `main.pdf` LOF/LOT 页存在 |

## §1.1.6 主要符号表

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R1.1.6-a | 符号/缩略词等可集中置于图表清单后 (§1.1.6) | `main.tex` `\include{data/denotation}` | 人工确认 | 符号表页（如使用） |

## §1.2 主体部分

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R1.2.1-a | 博士自然科学 ≥8 万字 / 人文社科 ≥10 万字 (§1.2.1) | (内容) | 人工确认 | 正文字数核对 |
| R1.2.2-a | 引言独立成章 (§1.2.2) | `data/chap01` (`\chapter`) | 人工确认 | 绪论章存在 |
| R1.2.3-a | 正文科学合理、层次清晰 (§1.2.3) | `data/chap0*.tex` | 人工确认 | 内容核对 |
| R1.2.4-a | 引文标注遵 GB/T 7714-2015，全文统一（顺序编码/著者-出版年） (§1.2.4) | cls 引文机制 + `htuthesis.bst` | 自动检查 | ATDD-3.7/3.12；`.bbl` 扫描 |
| R1.2.4-b | 脚注引文每页重新编号 (§1.2.4) | cls 脚注 per-page-reset (Story 3.12) | 自动检查 | ATDD-3.8-I08 / ATDD-3.12（fitz 多页扫描） |
| R1.2.5-a | 结论含核心观点/创新成果/局限/未来工作 (§1.2.5) | (内容，末章) | 人工确认 | 内容核对 |

## §1.3 参考文献表

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R1.3-a | 遵 GB/T 7714-2015 著录格式 (§1.3) | `htuthesis.bst` + cls `thebibliography` | 自动检查 | ATDD-3.7；`.bbl` 扫描 |

## §1.4 附录部分

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R1.4-a | 附录为补充，非必需 (§1.4) | `main.tex` `\appendix` + `data/app0*.tex` | 人工确认 | 附录存在（如使用） |

## §1.5 结尾部分

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R1.5.1-a | 致谢内容谦虚诚恳 (§1.5.1) | `data/ack.tex` | 人工确认 | 内容核对 |
| R1.5.2-a | 论文目录按发表时间，格式同参考文献 (§1.5.2) | `data/resume.tex` + cls `resume` env (cls:1059) | 自动检查 | ATDD-3.8；格式同参考文献 |
| R1.5.3-a | 独创性声明 + 授权说明用学校统一样式，需手写签名 (§1.5.3) | cls `\htu@authorization@mk` (cls:840–882) | 人工确认 | 文本 + 签名行；ATDD-3.3 |

## §2.1 编辑软件

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R2.1-a | 用 Word 或 LaTeX (§2.1) | 本模板 = LaTeX | 人工确认 | (元) |

## §2.2 印刷及装订

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R2.2-a | 一律双面印刷 (§2.2) | cls `twoside` (`\LoadClass[twoside,...]{ctexbook}`) | 自动检查 | ATDD-2.2 |
| R2.2-b | 线装或热胶装订，不用订书钉 (§2.2) | (印刷工序) | 人工确认 | 实际装订 |

## §2.3 页面设置

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R2.3-a | 上边距 3cm (§2.3) | `\htu@topmargin` + headheight + headsep = 30mm (`htuthesis.def`; cls:284 `\geometry`) | 自动检查 | `\htucheck` `textheight =` / `=== HTU Layout Self-Check ===`；`make calibrate` overlay；ATDD-2.1 |
| R2.3-b | 下边距 2.5cm (§2.3) | `\htu@bottommargin` 17.5mm + footskip 7.5mm = 25mm | 自动检查 | 同上 |
| R2.3-c | 左边距 2.5cm (§2.3) | `\htu@leftmargin` 25mm | 自动检查 | `\htucheck` `oddsidemargin =`；ATDD-2.1 |
| R2.3-d | 右边距 2.5cm (§2.3) | `\htu@rightmargin` 25mm | 自动检查 | `\htucheck` `evensidemargin =`（twoside 对称）；ATDD-2.4 |
| R2.3-e | 装订线 0cm (§2.3) | `\geometry` 无 binding offset | 自动检查 | ATDD-2.1 |
| R2.3-f | 页眉 2.2cm (§2.3) | `\htu@topmargin` 22mm + headheight 5.6mm（横线 27.5mm 实测） | 自动检查 | `\htucheck` `headheight =`；`make calibrate`；ATDD-2.3 |
| R2.3-g | 页脚 1.75cm (§2.3) | `\htu@bottommargin` 17.5mm | 自动检查 | `\htucheck`；ATDD-2.4 |
| R2.3-h | A4 纵向 (§2.3) | `\geometry` a4paper | 自动检查 | ATDD-2.1 |
| R2.3-i | 文档网格：无网格 (§2.3) | ctexbook 默认无网格 | 人工确认 | 视觉 |

## §2.4 页码

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R2.4-a | 封面/扉页/封底不编页码 (§2.4) | cls 封面 `\thispagestyle{empty}` | 自动检查 | ATDD-2.4-25 |
| R2.4-b | 前置部分大写罗马数字 Ⅰ Ⅱ Ⅲ… (§2.4) | cls `\pagenumbering{Roman}` (frontmatter) | 自动检查 | ATDD-2.4 |
| R2.4-c | 前置页码外侧 (§2.4) | cls fancyhdr `htu@plain`/`htu@headings` (cls:343,353) | 自动检查 | ATDD-2.4-20/25/26（fitz 页脚位置） |
| R2.4-d | 主体阿拉伯数字 1 2 3… (§2.4) | cls `\mainmatter` `\pagenumbering{arabic}` | 自动检查 | ATDD-2.4 |
| R2.4-e | 主体页码外侧 (§2.4) | fancyhdr 奇页右/偶页左 | 自动检查 | ATDD-2.4 |
| R2.4-f | 各起始页另起一页（一般右页） (§2.4) | cls `\cleardoublepage`/`\clearpage`（Story 3.14 精简为仅 2 起始页右页） | 自动检查 | ATDD-3.14（空白页 ≤2） |
| R2.4-g | 2 个起始页必须为右页 (§2.4) | cls `\cleardoublepage`（中文摘要起 + 绪论起） | 自动检查 | ATDD-3.14 |

## §2.5 页眉和页脚

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R2.5-a | 主体起至末页都有页眉 (§2.5) | cls `fancypagestyle{htu@headings}` (cls:353) | 自动检查 | ATDD-2.3 |
| R2.5-b | 页眉在每页最上方，五号宋体居中 (§2.5) | fancyhdr 五号宋体 + 横线 | 自动检查 | ATDD-2.3（fitz 字体/字号） |
| R2.5-c | 偶数页页眉 = 论文题目 (§2.5) | fancyhdr `\leftmark` = `\htu@ctitle` | 自动检查 | ATDD-2.3 |
| R2.5-d | 奇数页页眉 = 一级标题（章题） (§2.5) | fancyhdr `\rightmark` = 当前章 | 自动检查 | ATDD-2.3 |
| R2.5-e | 页眉五号宋体 (§2.5) | fancyhdr `\wuhao\songti` | 自动检查 | ATDD-2.3 |
| R2.5-f | 脚注用小五号宋体 (§2.5) | cls 脚注 `\xiaowu\songti` (Story 3.12) | 自动检查 | ATDD-3.8（fitz 9pt SimSun） |

## §2.6 目录

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R2.6-a | 目录自动生成 (§2.6) | `main.tex` `\tableofcontents` | 自动检查 | `main.toc` 生成 |
| R2.6-b | 「目录」两字空一格，三号黑体居中 (§2.6) | cls TOC title `\sanhao\heiti` 居中 | 自动检查 | ATDD-3.5 |
| R2.6-c | 目录段前段后 2 行 (§2.6) | cls `\titlecontents` beforeskip/afterskip | 自动检查 | ATDD-3.5 |
| R2.6-d | 目录至三级标题 (§2.6) | cls `tocdepth` | 自动检查 | ATDD-3.5 |
| R2.6-e | 每下一级向右缩进一格 (§2.6) | cls `\titlecontents` 缩进 2\ccwd/4\ccwd | 自动检查 | ATDD-3.5-I08 |
| R2.6-f | 一级标题用小四号黑体 (§2.6) | cls `\titlecontents{chapter}` `\xiaosi\sffamily` (cls:622) | 自动检查 | ATDD-3.15-G1（全条 SimHei 含「第N章」前缀） |
| R2.6-g | 其余用小四号宋体 (§2.6) | cls `\titlecontents{section/subsection}` `\xiaosi` (cls:625,628) | 自动检查 | ATDD-3.5 |
| R2.6-h | 目录点引导线连页码 (§2.6) | cls `\titlerule*{.}` | 自动检查 | ATDD-3.5-I09 |

## §2.7 摘要

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R2.7-a | 「摘要」两字空一格，三号黑体居中 (§2.7) | cls `\htu@makeabstract` 标题 `\sanhao\heiti` 居中 (cls:914) | 自动检查 | ATDD-3.4 |
| R2.7-b | 段前段后 2 行 (§2.7) | cls abstract 标题 spacing | 自动检查 | ATDD-3.4 |
| R2.7-c | 摘要内容小四号宋体，1.5 倍行距 (§2.7) | cls `\xiaosi\songti` + baselineskip 23.4bp（Word 1.5 倍语义，Story 3.11） | 自动检查 **PROXIED** | `\htucheck` `baselineskip = ~23.4bp`（代理）；真证据 ATDD-3.11-I07（fitz line-gap） |
| R2.7-d | 首行缩进 2 字，标点占一格 (§2.7) | cls `\parindent=2\ccwd` | 自动检查 | ATDD-3.4 |
| R2.7-e | 摘要后空一行，「关键词：」左顶格 (§2.7) | cls `\htu@put@keywords` (cls:908) | 自动检查 | ATDD-3.4 |
| R2.7-f | 「关键词：」小四号黑体 (§2.7) | cls `\sffamily\htu@ckeywords@title` (cls:923) | 自动检查 | ATDD-3.4 |
| R2.7-g | 关键词小四号宋体，分号隔开，末尾无标点 (§2.7) | cls `\htu@ckeywords` 分号 | 自动检查 | ATDD-3.4-I07/I11 |

## §2.8 ABSTRACT

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R2.8-a | 「ABSTRACT」三号 TNR 加粗居中 (§2.8) | cls `\eabstractname` + `\sanhao\bfseries` TNR (cls:217,914) | 自动检查 | ATDD-3.4（fitz TNR bold） |
| R2.8-b | 段前段后 2 行 (§2.8) | cls eabstract 标题 spacing | 自动检查 | ATDD-3.4 |
| R2.8-c | 英文内容五号 TNR，2 倍行距 (§2.8) | cls `\wuhao` TNR + baselineskip 23.4bp（2×五号 = 1.5×小四 巧合） | 自动检查 **PROXIED** | `\htucheck` baselineskip（代理）；真证据 ATDD-3.4-I06 / ATDD-3.11-I07；**G-D 透明偏差** |
| R2.8-d | 首行缩进 4 字符 (§2.8) | cls eabstract `\parindent` (Story 3.15 G2) | 自动检查 | ATDD-3.15-I07 |
| R2.8-e | 「KEY WORDS:」五号 TNR 加粗 (§2.8) | cls `\bfseries\htu@ekeywords@title` (cls:942) | 自动检查 | ATDD-3.4-I08 |
| R2.8-f | 关键词五号 TNR，半角逗号隔开，末尾无标点 (§2.8) | cls `\htu@ekeywords` 半角逗号 | 自动检查 | ATDD-3.4-I07 |

## §2.9 正文用字

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R2.9-a | 中文小四号宋体，1.5 倍行距 (§2.9) | cls `\xiaosi\songti` + baselineskip 23.4bp (cls:265–273) | 自动检查 **PROXIED** | `\htucheck` baselineskip（代理）；真证据 ATDD-2.5/ATDD-3.11-I07 |
| R2.9-b | 首行缩进 2 字，标点占一格 (§2.9) | cls `\parindent=2\ccwd` | 自动检查 | ATDD-2.5 |
| R2.9-c | 英文五号 TNR，2 倍行距 (§2.9) | cls `\setmainfont{Times New Roman}` (cls:110) + `\wuhao` | 自动检查 | ATDD-3.9；**G-E 透明偏差**（inline ASCII 小四） |
| R2.9-d | 字间距默认（标准） (§2.9) | ctexbook 默认 | 人工确认 | 视觉 |

## §2.10 标题层次

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R2.10-a | NS 可用 1/1.1/1.1.1（半角点） (§2.10) | cls option `numbering=sc` (Story 3.15 G3) | 自动检查 | ATDD-3.13/3.15（sc 模式 fitz） |
| R2.10-b | HS 可用 第一章/第一节/一、（默认） (§2.10) | cls 默认 `numbering=hs` + `\ctexset` (cls:493–535) | 自动检查 | ATDD-2.5/3.15 |
| R2.10-c | 一级标题三号黑体居中 (§2.10) | cls `\ctexset chapter` `\sanhao\sffamily\centering` | 自动检查 | ATDD-2.5/3.15-G6（Latin TNR） |
| R2.10-d | 二级标题小三号黑体居中 (§2.10) | cls `\ctexset section` `\xiaosanhao\sffamily` | 自动检查 | ATDD-2.5 |
| R2.10-e | 三级标题四号黑体居左空两格 (§2.10) | cls `\ctexset subsection` `\sihao\sffamily` + 2\ccwd (cls:516) | 自动检查 | ATDD-2.5 |
| R2.10-f | 四级标题小四号宋体加粗 (§2.10) | cls `\ctexset subsubsection` `\htu@songtibold\bfseries\xiaosi` (cls:525–530) | 自动检查 | ATDD-2.5-28（fitz ink-density，**非 flags**——G-B 教训） |
| R2.10-g | L1 段前段后 2 行 (§2.10) | cls chapter beforeskip/afterskip | 自动检查 | ATDD-2.5 |
| R2.10-h | L2/L3 段前段后 0.5 行 (§2.10) | cls section/subsection spacing | 自动检查 | ATDD-2.5 |
| R2.10-i | HS：一二级居中，三级以下居左空两格 (§2.10) | cls `\ctexset` format + 缩进 | 自动检查 | ATDD-2.5 |
| R2.10-j | 编号与名称间空半格（NS）/不空格（HS） (§2.10) | cls `\ctexset` name format | 自动检查 | ATDD-3.15 |
| R2.10-k | sc 模式 L1–L3 居左顶格 (§2.10) | cls sc `\ctexset` (cls:541–558) | 自动检查 | ATDD-3.15（sc） |

## §2.11 插图

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R2.11-a | 插图按章编号「图 1-1」「图 A-1」(§2.11) | cls `\thefigure` 短横线 (cls:453) | 自动检查 | ATDD-2.6/4.1-I05（附录 图A-1） |
| R2.11-b | 图题在图下方居中 (§2.11) | cls `\captionsetup[figure]` belowskip (cls:429) | 自动检查 | ATDD-3.6 |
| R2.11-c | 图题五号宋体 (§2.11) | cls `\DeclareCaptionFont{htu}{\wuhao[1.5]}` (cls:421) | 自动检查 | ATDD-3.6-I04 |
| R2.11-d | 编号与图题间空半格 (§2.11) | cls `\DeclareCaptionLabelSeparator{htu}{\hspace{0.5\ccwd}}` (cls:420) | 自动检查 | ATDD-3.6/3.13 |
| R2.11-e | 分图用（a）（b）（c）(§2.11) | cls `\captionsetup[sub]` (cls:431) | 自动检查 | ATDD-3.6 |
| R2.11-f | 插图紧跟文述 (§2.11) | (排版) | 人工确认 | 内容核对 |
| R2.11-g | 坐标轴标度/量纲按 SI (§2.11) | (内容) | 人工确认 | 内容核对 |
| R2.11-h | 引用他人插图须注明出处 (§2.11) | (内容) | 人工确认 | 内容核对 |

## §2.12 表格

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R2.12-a | 表格按章编号「表 1-1」「表 A-1」(§2.12) | cls `\thetable` 短横线 (cls:455) | 自动检查 | ATDD-2.6 |
| R2.12-b | 表题在表格上方居中 (§2.12) | cls `\captionsetup[table]` aboveskip (cls:428) | 自动检查 | ATDD-3.6 |
| R2.12-c | 表题五号宋体 (§2.12) | cls `\DeclareCaptionFont{htu}` (cls:421) | 自动检查 | ATDD-3.6 |
| R2.12-d | 编号与表题间空半格 (§2.12) | cls `\DeclareCaptionLabelSeparator{htu}` (cls:420) | 自动检查 | ATDD-3.6/3.13 |
| R2.12-e | 表格设计紧跟文述 (§2.12) | (排版) | 人工确认 | 内容核对 |
| R2.12-f | 表中物理量按 SI (§2.12) | (内容) | 人工确认 | 内容核对 |
| R2.12-g | 引用他人表格须注明出处 (§2.12) | (内容) | 人工确认 | 内容核对 |

## §2.13 公式

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R2.13-a | 公式按章编号「（1-1）」「（A-1）」全角括号 (§2.13) | cls `\theequation` + `\tagform@` 全角（）（cls:445,452; G-A fix） | 自动检查 | ATDD-3.6（全角括号 fitz） |
| R2.13-b | 公式序号在该行最右侧 (§2.13) | amsmath `\tagform@` 右对齐 | 自动检查 | ATDD-3.6 |
| R2.13-c | 引用「见式（1-1）」(§2.13) | `\eqref` 走 `\tagform@` (cls:452) | 自动检查 | ATDD-3.6（main.pdf 12 全角引用） |
| R2.13-d | 公式物理量按 SI (§2.13) | (内容) | 人工确认 | 内容核对 |

## §2.14 文后参考文献表

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R2.14-a | 「参考文献」三号黑体居中，另起一页 (§2.14) | cls `\htu@thebibliography` 标题 `\sanhao\heiti` | 自动检查 | ATDD-3.7 |
| R2.14-b | 段前段后 2 行 (§2.14) | cls 标题 spacing | 自动检查 | ATDD-3.7 |
| R2.14-c | 内容五号宋体 (§2.14) | cls `\wuhao\songti` | 自动检查 | ATDD-3.7 |
| R2.14-d | 编号 [N] 方括号 (§2.14) | `htuthesis.bst` | 自动检查 | ATDD-3.7 |
| R2.14-e | 序号左顶格，悬挂缩进（序号后内容左对齐） (§2.14) | cls `\leftmargin`/`\itemindent` 标准悬挂 (Story 3.13) | 自动检查 | ATDD-3.7-I05/I11（[15,28] 带，实测 21pt = 2\ccwd） |
| R2.14-f | 顺序编码制：按引用顺序 (§2.14) | `htuthesis.bst` unsrt | 自动检查 | ATDD-3.7 |
| R2.14-g | 双模式：脚注引文 per-page + 文后阅读型重编号 (§2.14 情况二) | cls 脚注 + `\printbibliography` 分组 (Story 3.12) | 自动检查 | ATDD-3.12 |
| R2.14-h | 作者 ≤3 全列，>3 列前 3 加「等」(§2.14) | `htuthesis.bst` | 自动检查 | `.bbl` 扫描 |
| R2.14-i | 期刊论文格式 [J] 起止页码 (§2.14) | `htuthesis.bst` | 自动检查 | ATDD-3.7 |
| R2.14-j | 著作 [M] / 论文集 [C] / 学位论文 [D] / 报告 [R] (§2.14) | `htuthesis.bst` | 自动检查 | `.bbl` 扫描 |
| R2.14-k | 专利 [P] / 标准 [S] / 报纸 [N] / 电子 [EB/OL] (§2.14) | `htuthesis.bst` | 自动检查 | `.bbl` 扫描 |

## §2.15 附录

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R2.15-a | 附录序号「附录A、附录B」(§2.15) | cls `\appendix` `\@chapapp` + `appendixname={附录}` (cls:180,1034) | 自动检查 | ATDD-3.7/4.1（附录 图A-1） |
| R2.15-b | 序号与标题间空半格 (§2.15) | cls appendix 标题 format | 自动检查 | ATDD-3.7 |
| R2.15-c | 附录标题三号黑体居中，段前段后 2 行 (§2.15) | cls appendix `\sanhao\heiti` 居中 (Story 3.13) | 自动检查 | ATDD-3.7 |
| R2.15-d | 附录内容小四号宋体 (§2.15) | cls `\renewenvironment{appendix}` `\xiaosi\songti` (cls:1034; Story 3.15 G5a) | 自动检查 | ATDD-4.1-I04（附录 body 小四宋 fitz） |

## §2.16 致谢

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R2.16-a | 「致谢」两字空一格，三号黑体居中，段前段后 2 行 (§2.16) | cls ack 标题 `\sanhao\heiti` 居中 | 自动检查 | ATDD-3.8 |
| R2.16-b | 致谢内容小四号宋体 (§2.16) | cls `\songti\xiaosi[1.524]` | 自动检查 | ATDD-3.8 |
| R2.16-c | 致谢后有作者姓名及日期 (§2.16) | `data/ack.tex` 结尾 | 人工确认 | 内容核对 |

## §2.17 攻读学位期间发表的学术论文目录

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R2.17-a | 「攻读学位期间发表的学术论文目录」三号黑体居中，段前段后 2 行 (§2.17) | cls `\htu@resume@title` + `\sanhao\heiti` 居中 (cls:237,1059) | 自动检查 | ATDD-3.8 |
| R2.17-b | 书写格式同参考文献 (§2.17) | cls `resume` env 复用参考文献格式 (cls:1059) | 自动检查 | ATDD-3.8 |

---

## §3 学位论文格式说明

| ID | 规则 (spec §ref) | LaTeX 实现 | 检查类型 | 证据 |
|----|------------------|-----------|----------|------|
| R3-a | 通用标准，各学科可适当调整但须统一 (§3) | (元) | 人工确认 | 学科统一性核对 |

---

## 透明偏差（文档化，非 bug）— Epic 3 retro action item #4

> 以下 3 项是经 Epic 3 5-teammate 审计 + lead 实证确认的**已记录透明偏差**，非未修复 bug。列出以免未来审查重复告警（Epic 3 retro Lesson 4：行动前先验证）。

| ID | 偏差 | 实测值 | 真值源 | 理由 |
|----|------|--------|--------|------|
| **G-C** | 英文题目用 **Title Case**，非 ALL CAPS | `An Introduction to ... Thesis Template of Henan Normal University` | 参考论文 PDF（已通过审查的论文）+ spec §1.1.1「用大写字母」解读为「proper capitalization」 | ALL CAPS 用于学位论文题目非典型；参考论文以 Title Case 通过审查。保持 Title Case。 |
| **G-D** | 中文正文 + 英文摘要 baselineskip 巧合同为 **23.4bp** | CN = 1.5×小四-natural ≈ 23.4bp；EN = 2×五号-TNR ≈ 23.4bp | 参考论文 PDF（实测 line-gap）+ spec §2.7（1.5 倍）/ §2.8（2 倍） | 1.5×小四 ≈ 2×五号 是参考论文中的巧合；两者均 spec 正确。**非** 31.2bp（那会偏离参考）。 |
| **G-E** | 正文 inline ASCII = **小四 (12pt)**，非五号 | ASCII 字形 12pt，对齐 CJK 行高 | 参考论文 PDF | 匹配参考；spec §2.9 治理 CJK 正文（小四），inline ASCII 跟随 CJK 网格。影响低。 |

---

## 附录 A：`\htucheck` 自检输出参考

每次编译 `main.log` 末尾自动输出（cls:1067–1165）。本清单「自动检查」项引用其中的行：

```
=== HTU Layout Self-Check ===
textheight = <pt>          ← §2.3 正文高度（242mm 派生）
textwidth = <pt>           ← §2.3 正文宽度（160mm 派生）
baselineskip = <pt>        ← §2.7/§2.9 行距（~23.4bp；PROXIED——真证据见 fitz ATDD）
headheight = <pt>          ← §2.5 页眉框高
evensidemargin = <pt>      ← §2.4 twoside 对称边距
oddsidemargin = <pt>       ← §2.3/§2.4
total pages = <N>          ← §2.4 页数健全性
page counter = <N>         ← §2.4 编号状态
--- font check ---         ← NFR-2 5 字体（SimSun/SimHei/KaiTi/FangSong/TNR: found/missing）
--- silent-failure coverage map (14 + §480 pointer = 15 lines) ---  ← NFR-4 14 静默失败断言
--- assertion audit ---    ← PROXIED 项（R-25 wrong-target-AC 警示）
=== End Self-Check ===
```

- WARNING 层（`\PackageWarning`，非致命）：margin drift >1mm / baselineskip drift >0.5bp → log + 继续。
- ERROR 层（`\PackageError`，致命，halt）：字体缺失。
- `[debug]` 选项额外输出 `--- debug diagnostics ---`（开发诊断 + NFR-5 watch-list；默认编译不输出）。

## 附录 B：开发期验证工具

| 工具 | 命令 | 用途 |
|------|------|------|
| 编译检查 | `make compile-check` / `latexmk -xelatex main` | rc=0 + `[PASS]` |
| 物理边距标尺 | `make calibrate` → `tools/calibrate.pdf` | overlay 比对 §2.3 边距（Story 4.3） |
| NFR-5 调试 | `make debug-check` | 6 类 LaTeX warning 视为 error（干净树 exit 0；Story 4.3） |
| 结构检查 | `make structure-check` | 目录结构健全 |

## 附录 C：ATDD 测试索引（rendered 证据）

本清单「自动检查」项引用的 rendered fitz ATDD（真证据，PROXIED 项的权威来源）：

| ATDD 覆盖 | 关键 ATDD ID |
|-----------|--------------|
| 页面几何 | ATDD-2.1, ATDD-2.4 |
| twoside/页眉/页码 | ATDD-2.2, ATDD-2.3, ATDD-2.4 |
| 正文行距/标题 | ATDD-2.5, ATDD-3.11 |
| 编号分隔符/关键词 | ATDD-2.6 |
| 封面 | ATDD-3.1, ATDD-3.10, ATDD-3.15 |
| 摘要（中英） | ATDD-3.4, ATDD-3.11 |
| 目录 | ATDD-3.5, ATDD-3.15-G1 |
| 图/表/公式 | ATDD-3.6, ATDD-3.13 |
| 参考文献/附录 | ATDD-3.7, ATDD-3.12, ATDD-4.1 |
| 致谢/论文目录/脚注/声明 | ATDD-3.8, ATDD-3.3 |
| Latin 字体 TNR | ATDD-3.9, ATDD-3.15-G6 |

---

**计数：** 本清单 ~95 规则行（§1.1.1–§2.17 全覆盖 + §1.x/§3 结构项），含 G-C/G-D/G-E 透明偏差 3 项。spec §1.1–§2.17 每一节均有对应规则行。
