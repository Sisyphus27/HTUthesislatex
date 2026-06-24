%%================================================
%% Filename: htuthesis.cls
%% Encoding: UTF-8
%% Author: Yuan Xiaoshuai - yxshuai@gmail.com
%% Created: 2012-01-08 13:11
%% Last modified: 2020-04-05 20:27
%%================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 标识节(Identification)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{htuthesis}
[2026/06/12 1.0.0 HTU Doctoral Thesis Template]
\hyphenation{Htu-Thesis}
\def\htuthesis{HtuThesis}
\def\version{1.0.0}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 声明选项(Declaration options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\newif\ifhtu@doctor\htu@doctortrue
\newif\ifhtu@openright\htu@openrightfalse
\newif\ifhtu@debug\htu@debugfalse
\DeclareOption{doctor}{\htu@doctortrue}
\DeclareOption{bachelor}{\ClassError{htuthesis}{bachelor option removed: this template now only supports doctoral theses}{}}
\DeclareOption{master}{\ClassError{htuthesis}{master option removed: this template now only supports doctoral theses}{}}
\DeclareOption{openright}{\htu@openrighttrue}
% [基础] debug 模式选项（architecture §342 decision 4b；Story 4.3；NFR-5 调试标准）。
%   \documentclass[doctor,debug]{htuthesis} 置 \ifhtu@debug=true，\htucheck 额外输出 --- debug diagnostics --- 段
%   （基线值对照、headheight head-room 计算、NFR-5 六警告 watch-list）。AC-2：仅 [debug] 时输出；默认编译
%   self-check 块不变（AC-8 —— 22 个 Epic 2-3 ATDD consumer + Story 4.2 I02/I06/I07 依赖默认输出，4.3 ADD-only）。
%   关联 Makefile `debug-check` target（[doctor,debug] 编译 + NFR-5 六签名 grep → warnings-as-errors）。
\DeclareOption{debug}{\htu@debugtrue}
% [基础] 标题编号制 numbering=sc|hs（spec §2.10 line 235；Story 3.15 G3 / D-22）。
%   false(默认)=人文社科 hs（第一章/第一节/一、/（1）；Story 3.13 实现）；
%   true=自然科学 sc（opt-in：1/1.1/1.1.1 半角 + 编号名空半格 §2.10 line 237；Story 3.13 曾删此路径，G3 恢复为可选）。
%   spec §2.10 列 NS 为主路径、HS 为人文备选——模板为对齐参考论文（参考博士论文，政治与公共管理学院）默认 hs，sc 供理科 opt-in。
%   ✅ Zy 批准 2026-06-20 code-review：默认 hs（D-22 已批 + review 再确认）。透明偏离 = spec §2.10 列 NS 为主路径，
%      默认 hs 为参考论文（文科实例）对齐 + 保持当前行为；参考 PDF 按 D-20 仅辅助，此偏离记入此注释 + story Review Findings。
\newif\ifhtu@numbersc\htu@numberscfalse
\DeclareOption{numbering=sc}{\htu@numbersctrue}
\DeclareOption{numbering=hs}{\htu@numberscfalse}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{ctexbook}}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 选项处理 (Option processing)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\ProcessOptions\relax
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 装载类与宏包 (Loading classes & packages)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\ifhtu@openright
  \LoadClass[zihao=-4,a4paper,twoside,openright,UTF8,scheme=plain]{ctexbook}
\else
  \LoadClass[zihao=-4,a4paper,twoside,openany,UTF8,scheme=plain]{ctexbook}
\fi
\RequirePackage{ifxetex}
\ifxetex\else
  \ClassError{htuthesis}{You should use XeLaTeX}{}
  \end{document}
\fi
\RequirePackage{environ}
\RequirePackage{xparse}
\RequirePackage{zhnumber}% Story 3.15 G4：封面日期中文数字（\zhdigits/\zhnumber；spec §1.1.1 二〇…年…月）。
\RequirePackage{tikz}
\usetikzlibrary{calc}% Story 3.1 封面绝对定位（$(current page) + (offset)$ 坐标计算）
\RequirePackage{etoolbox}
\RequirePackage{calc}%算术运算
\RequirePackage[shortlabels]{enumitem}
\RequirePackage{titletoc}%目录格式
\RequirePackage{amsmath,amsthm}
\RequirePackage{unicode-math}
\unimathsetup{
  math-style = ISO,
  bold-style = ISO,
  nabla      = upright,
  partial    = upright,
}
% Font availability check — fail early with clear error
\IfFontExistsTF{SimSun}{}{%
  \PackageError{htuthesis}{Font 'SimSun' not found. Please install 'SimSun' (Chinese: 宋体).\\
   Required fonts: SimSun (宋体), SimHei (黑体), KaiTi (楷体), FangSong (仿宋), Times New Roman.%
  }{Verify your TeX Live installation and system fonts.}}
\IfFontExistsTF{SimHei}{}{%
  \PackageError{htuthesis}{Font 'SimHei' not found. Please install 'SimHei' (Chinese: 黑体).\\
   Required fonts: SimSun (宋体), SimHei (黑体), KaiTi (楷体), FangSong (仿宋), Times New Roman.%
  }{Verify your TeX Live installation and system fonts.}}
\IfFontExistsTF{KaiTi}{}{%
  \PackageError{htuthesis}{Font 'KaiTi' not found. Please install 'KaiTi' (Chinese: 楷体).\\
   Required fonts: SimSun (宋体), SimHei (黑体), KaiTi (楷体), FangSong (仿宋), Times New Roman.%
  }{Verify your TeX Live installation and system fonts.}}
\IfFontExistsTF{FangSong}{}{%
  \PackageError{htuthesis}{Font 'FangSong' not found. Please install 'FangSong' (Chinese: 仿宋).\\
   Required fonts: SimSun (宋体), SimHei (黑体), KaiTi (楷体), FangSong (仿宋), Times New Roman.%
  }{Verify your TeX Live installation and system fonts.}}
\IfFontExistsTF{Times New Roman}{}{%
  \PackageError{htuthesis}{Font 'Times New Roman' not found. Please install 'Times New Roman'.\\
   Required fonts: SimSun (宋体), SimHei (黑体), KaiTi (楷体), FangSong (仿宋), Times New Roman.%
  }{Verify your TeX Live installation and system fonts.}}
% 宋体加粗族（HTU §2.10 四级标题用）：SimSun 无原生粗体，启用 AutoFakeBold 算法加粗。
% 用法：\htu@songtibold\bfseries —— \htu@songtibold 切换到带 AutoFakeBold 的 SimSun 族，
% \bfseries 触发算法加粗（字体名仍为 SimSun，区别于 ctex 默认把 CJK 粗体映射到 SimHei）。
\newCJKfontfamily\htu@songtibold{SimSun}[AutoFakeBold=2.5]
% [基础] 拉丁主字体 = Times New Roman（真值来源：HTU 格式要求 §2.7/§2.8/§2.9 + architecture.md:83 硬约束）。
%   cls 上方 \IfFontExistsTF{Times New Roman} 已保证 TNR 存在（缺失则 \PackageError 终止），
%   此处再次门控为防御性双保险（AC-1, NFR-2）。
%   修复 deferred-work §2.5 review 的 Latin-Modern 缺口：全模板此前无 \setmainfont，Latin 文本
%   缺省渲染为 Latin Modern（如 L4 标题 Latin 数字为 LMRoman12-Bold）。本行将其切换为 TNR。
%   影响：所有 \rmfamily Latin 文本（英文封面/英文摘要正文/Latin 数字/交叉引用标记）。
%   不影响：CJK 字体（ctex 独立管理）、数学字体（unicode-math 用 Latin Modern Math，独立于 \setmainfont）。
%   实测确认（AC-5 三源之一）：参考论文 参考博士论文 page 1-14 Latin 主字体 = TimesNewRomanPSMT。
\IfFontExistsTF{Times New Roman}{\setmainfont{Times New Roman}}{}
% [基础] CJK 无衬线（\sffamily）= SimHei（真值来源：HTU 格式要求 §2.10 标题黑体 + 参考论文 PDF 实测）。
%   ctex scheme=plain 在本系统自动检测 \sffamily CJK 为 Microsoft YaHei（ATDD-3.9-18 实测确认），
%   与参考论文标题字体 SimHei（参考 PDF p15/p22「第一节/第二节」15.0pt 实测）及 spec §2.10 黑体不一致。
%   显式 \setCJKsansfont{SimHei} 强制传统黑体字面，与参考论文 + spec 对齐（AC-4 决策：SimHei）。
%   影响所有 \sffamily CJK 文本：章/节/小节标题（cls \ctexset chapter/section/subsection）、
%   定理头、原创性声明标题等。
%   不影响：\htu@songtibold（上方 \newCJKfontfamily，L4 加粗宋体，独立显式族）、
%   CJK 主字体（SimSun 经 ctex 默认，\setCJKsansfont 只改 sans 族）。
\setCJKsansfont{SimHei}
% [基础] 封面专用 Latin 字体开关（Story 3.1）——Word 把 ASCII 打包进中文字体 run（参考论文 PDF page 2
%   实测：元数据 10476/D669.3 = FangSong，日期 2025 = SimHei）。xelatex 默认 \fangsong/\sffamily 只切
%   CJK，Latin 数字回落到 \rmfamily(TNR) 或 Latin Modern Sans。下列 \newfontfamily 让封面元数据/日期的
%   ASCII 也走对应中文字体，精确匹配参考论文渲染（三源之一 = 参考 PDF page 2 span 级字体）。
%   仅封面 \htu@first@titlepage 使用，不影响正文（正文 Latin 仍走 \rmfamily=TNR）。
\newfontfamily\htu@fangsong@latin{FangSong}
\newfontfamily\htu@heiti@latin{SimHei}
% [基础] Latin Times New Roman 开关（Story 3.15 G6）——\sffamily 实现 CJK 黑体（via \setCJKsansfont{SimHei}
%   cls:102）但其 Latin 泄漏至 LMSans（章节/目录标题的 Latin「TEX/LaTeX」渲染 LMSans 非 TNR）。\htu@tnr 在
%   \sffamily 后显式钉 Latin = TNR（\newfontfamily 仅切 Latin，不动 CJK）→ CJK 黑体 + Latin TNR。spec §2.6/§2.10。
\newfontfamily\htu@tnr{Times New Roman}
\RequirePackage{geometry}%页边距设置
\RequirePackage{fancyhdr}%页眉页脚管理
\RequirePackage{tabularx}%表格宽度控制
\RequirePackage{multirow}%跨行表格
\RequirePackage{longtable}%长表格，可替换supertabular
\RequirePackage{booktabs}%三线表格
\RequirePackage[labelformat=simple]{subcaption}% subcaption with labelformat=simple
\RequirePackage{graphicx}%图形支持
\RequirePackage[backend=biber,style=gb7714-2015,sorting=nyt,defernumbers=true]{biblatex}% biblatex GB/T 7714-2015 (Story 3.12 Option A, §2.14 case-2 双模式). 替换 natbib [numbers,super] 末端 case-1。sorting=nyt = 文末表按作者姓名序（§2.14 line 291 每一类再按照作者姓氏字母顺序编号；CJK 为 Unicode 码点序≈拼音需 .bib sortkeys 精化，4.1）；defernumbers=true + 每节 resetnumbers=true = 每类 [1] 重启（§2.14 line 291 重新编号）。
\addbibresource{ref/refs.bib}% 参考文献（GB/T 7714-2015；Zy 决策 2026-06-17 Option A）
\RequirePackage{hyperref}%超链接、书签
  \hypersetup{%
    linktoc=all,
    bookmarksnumbered=true,%节的标号放入标签
    bookmarksopen=true,
    bookmarksopenlevel=1,
    breaklinks=true,
    plainpages=false,
    hidelinks}
  \urlstyle{same}%相同字体
\input{htuthesis.def}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 文前，正文，文后格式
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\renewcommand\frontmatter{%
  \clearpage
  \ifhtu@numbersc\else\ctexset{chapter/format+=\centering}\fi% sc 模式章标题顶格不居中（§2.10 NS；Story 3.15 G3）
  \@mainmatterfalse
  \pagenumbering{Roman}
  \pagestyle{htu@plain}}
\renewcommand\mainmatter{%
  %% [基础] header-mark fix（2026-06-24）：此处【不】清洗前置 marks。fitz 实测发现 \markboth{}{}
  %%   的空 mark 会浮到正文首章首页（\clearpage 不运走 mark-only 页）成为该页 \firstmark，
  %%   rightmark="" → 章首页页眉空（与首章自身 \markboth 冲突：p11 实测空、p13 才显章名）。
  %%   故前置 mark 残留改由各章自身 mark 覆盖：无编号章在 \chapter* 后 \markboth{标题}{标题}
  %%   （见 v1.0.0 data/chap01.tex 绪论）；编号章由 ctex \@chapter→\chaptermark 自动设。
  %%   spec §2.5「正文奇数页=一级标题」；三源三角（spec/参考PDF/.cls）。
  \cleardoublepage
  \ifhtu@numbersc\else\ctexset{chapter/format+=\centering}\fi% sc 模式章标题顶格不居中（§2.10 NS；Story 3.15 G3）
  \@mainmattertrue
  \pagenumbering{arabic}%
  \pagestyle{htu@headings}}
\renewcommand\backmatter{%
  \clearpage
  \ifhtu@numbersc\else\ctexset{chapter/format+=\centering}\fi% sc 模式章标题顶格不居中（§2.10 NS；Story 3.15 G3）
  \@mainmattertrue}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 中文配置
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\ctexset{%
  contentsname={目\hspace{\ccwd} 录},
  listfigurename={插图清单},
  listtablename={表格清单},
  figurename={图},
  tablename={表},
  appendixname={附录},
  bibname={参考文献},
  proofname={证明}
}
\newcommand\equationname{公式}
\newcommand\htu@definition@name{定义}
\newcommand\htu@theorem@name{定理}
\newcommand\htu@lemma@name{引理}
\newcommand\htu@corollary@name{推论}
\providecommand\htu@schoolname{}
\providecommand\htu@schoolname@en{}
% \htu@schoolname and \htu@schoolname@en are defined in htuthesis.def (user zone)
\def\htu@title@sep{：}
  % [基础] 封面元数据标签（真值来源：参考论文 PDF page 2 + .doc 空白模板「博士学位论文封面（电子版用）」）
  \def\htu@schoolcode@title{单位代码}
  \def\htu@id@title{学号}
  \def\htu@secretlevel@title{分类号}
  \def\htu@subtitle{博士学位论文}
  % [基础] 封面五字段标签（真值来源：参考论文 PDF page 2 + .doc 空白模板；学科、专业 为合并字段）
  \def\htu@author@title{申请人}
  \def\htu@supervisor@title{指导教师}
  \def\htu@subject@title{学科、专业}
  \def\htu@researchdirection@title{研究方向}
  \def\htu@degreecategory@title{申请学位类别}
\let\CJK@todaysave=\today
\def\CJK@todaysmall@short{\the\year 年 \the\month 月}
\def\CJK@todaysmall{\CJK@todaysmall@short \the\day 日}
\def\CJK@todaybig@short{\CJKdigits{\the\year} 年 \CJKnumber{\the\month} 月}
\def\CJK@todaybig{\CJK@todaybig@short \CJKnumber{\the\day} 日}
\def\CJK@today{\CJK@todaysmall}
\renewcommand\today{\CJK@today}
\newcommand\CJKtoday[1][1]{%
  \ifcase#1\def\CJK@today{\CJK@todaysave}
    \or\def\CJK@today{\CJK@todaysmall}
    \or\def\CJK@today{\CJK@todaybig}
  \fi}
\newcommand{\cabstractname}{摘\hspace{\ccwd} 要}
% [基础] 英文摘要标题 = ABSTRACT（大写）。三号 TNR 加粗居中——字体在 \htu@makeabstract 的标题调用中
%   覆盖章节 \sffamily 格式（避免 Latin 渲染为 LMSans；Story 3.4 AC-4，闭合 Story 3.9 遗留缺口）。
%   真值源：HTU 格式要求 §2.8 + 参考论文 PDF page 6（TimesNewRomanPS-BoldMT 15.9pt）。
\newcommand{\eabstractname}{ABSTRACT}
\def\htu@ckeywords@separator{；}
% [基础] 英文关键词分隔符 = 半角逗号 + 空格。真值源：HTU 格式要求 §2.8 "半角逗号" + 参考论文 PDF page 9
%   "governance, Responsive politics"。\htu@parse@keywords 按逗号切分 \ekeywords 参数后用此分隔符重组输出。
\def\htu@ekeywords@separator{, }
\newcommand{\htu@ckeywords@title}{关键词：}
% [基础] 英文关键词标签 = KEY WORDS 后接半角冒号（U+003A），冒号后无间距，标签加粗。真值源：spec §2.8 line 223
%   PRIORITY「'KEY WORDS：'用五号'Times New Roman'字体，加粗」（CLAUDE.md Decision 4 修正 2026-06-17）。半角冒号
%   保留（参考论文 PDF page 9 实测半角冒号紧接首关键词；Epic 2 retro D-14 已闭合冒号宽度问题）。加粗 = Story 3.13
%   翻案 Story 3.4（2026-06-16 reference-wins 非加粗）→ 回归 spec §2.8 加粗（gap 1b）；仅标签加粗，关键词非加粗
%   （§2.8「其后的关键词用五号 TNR」）。加粗在 \htu@makeabstract 的 \htu@put@keywords 调用处 \bfseries 包裹。
\newcommand{\htu@ekeywords@title}{KEY WORDS:}
\newcommand{\htu@denotation@name}{主要符号对照表}
\newcommand{\htu@ackname}{致\hspace{\ccwd} 谢}
  % [基础] 发表论文目录标题文本（真值来源：spec §2.17「攻读学位期间发表的学术论文目录」用三号黑体字居中）。
  %   原上游模板的合并式「个人简历、在学期间发表的学术论文与研究成果」偏离 spec §2.17；参考 PDF 对此标题静默
  %   （无 致谢/攻读 锚点）→ 按 CLAUDE.md Decision 4，spec 文本主导（用户决策 2026-06-16，Story 3.8 AC-3 Option A1）。
\newcommand{\htu@resume@title}{攻读学位期间发表的学术论文目录}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  字号设置
%%  模板使用thuthesis论文模板的字号定义
%%  使用时可加入行距参数，如\chuhao[1.25]表示初号字体，1.25倍行距
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\def\htu@def@fontsize#1#2{%
  \expandafter\newcommand\csname #1\endcsname[1][1.3]{%
    \fontsize{#2}{##1\dimexpr #2}\selectfont}}
\htu@def@fontsize{chuhao}{42bp}
\htu@def@fontsize{xiaochu}{36bp}
\htu@def@fontsize{yihao}{26bp}
\htu@def@fontsize{xiaoyi}{24bp}
\htu@def@fontsize{erhao}{22bp}
\htu@def@fontsize{xiaoer}{18bp}
\htu@def@fontsize{sanhao}{16bp}
\htu@def@fontsize{xiaosan}{15bp}
\htu@def@fontsize{sihao}{14bp}
\htu@def@fontsize{banxiaosi}{13bp}
\htu@def@fontsize{xiaosi}{12bp}
\htu@def@fontsize{dawu}{11bp}
\htu@def@fontsize{wuhao}{10.5bp}
\htu@def@fontsize{xiaowu}{9bp}
\htu@def@fontsize{liuhao}{7.5bp}
\htu@def@fontsize{xiaoliu}{6.5bp}
\htu@def@fontsize{qihao}{5.5bp}
\htu@def@fontsize{bahao}{5bp}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 正文字体及行距
%% 博士：小四号 (12bp) 字，行距 23.4bp = Word「1.5 倍行距」(1.5×小四宋体 natural-line-height，参考 PDF 实测 23.4pt)
%% spec §2.7/§2.9「1.5 倍行间距」= Word 倍数行距语义（非 naive 1.5×fontsize=18bp）；Story 3.11 校准 18bp→23.4bp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\renewcommand\normalsize{%
  \@setfontsize\normalsize{\htu@body@fontsize}{\htu@body@baselineskip}%
  \abovedisplayskip=\htu@display@skip \@plus \htu@display@stretch \@minus \htu@display@stretch
  \abovedisplayshortskip=\htu@display@skip \@plus \htu@display@stretch \@minus \htu@display@stretch
  \belowdisplayskip=\abovedisplayskip
  \belowdisplayshortskip=\abovedisplayshortskip}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 页面设置
%% 博士（includeheadfoot 模式）：
%%   页眉距顶 2.2cm、页脚距底 1.75cm
%%   正文起始距顶 3cm（= top 2.2cm + headheight 5mm + headsep 3mm）
%%   正文结束距底 2.5cm（= footskip 7.5mm + bottom 1.75cm）
%%   左右各 2.5cm、装订线 0cm
%% 真值来源：HTU 格式要求 §2.3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\geometry{
  a4paper,
  includeheadfoot,
  nomarginpar,
  top=\htu@topmargin,
  bottom=\htu@bottommargin,
  left=\htu@leftmargin,
  right=\htu@rightmargin,
  headheight=\htu@headerheight,
  headsep=\htu@headsep,
  footskip=\htu@footskip}
%% --- Dimension output for geometry verification (Story 2.1 AC-4) ---
%% Outputs physical dimensions for ATDD verification.
\typeout{htu@geometry@textheight=\the\textheight}
\typeout{htu@geometry@textwidth=\the\textwidth}
\typeout{htu@geometry@topmargin=\the\dimexpr\topmargin+1in\relax}
\typeout{htu@geometry@oddsidemargin=\the\dimexpr\oddsidemargin+1in\relax}
\typeout{htu@geometry@headheight=\the\headheight}
\typeout{htu@geometry@footskip=\the\footskip}
%% --- Story 4.2: self-check baseline capture (WARNING threshold reference, architecture §345-353) ---
%% Captures cls-load textheight/textwidth so \htucheck detects USER preamble drift at \AtEndDocument
%%   (e.g. \geometry{textheight=240mm} → drift > 1mm → WARNING). Captured HERE (post-geometry,
%%   pre-\begin{document}) so a preamble geometry override is caught. baselineskip is captured at
%%   \AtBeginDocument instead (it is not final until \normalsize is selected at \begin{document};
%%   cls-load \baselineskip is the base-class default, not the 23.4bp body value -- would false-WARN).
%%   Self-calibrating: if .def geometry changes, baselines updates -- no false WARNING.
\edef\htu@base@textheight{\the\textheight}
\edef\htu@base@textwidth{\the\textwidth}
\AtBeginDocument{\edef\htu@base@baselineskip{\the\baselineskip}}
%% --- End dimension output ---
\ctexset{%
  punct=quanjiao,
  space=auto,
  autoindent=true}
%% [ThuThesis 移植] 开始 cleardoublepage 处理
%% 参考源：ThuThesis v7.7.1 thuthesis.dtx 行 3214-3229
%% 许可证：LPPL（与 ThuThesis 一致）
\def\cleardoublepage{%
  \clearpage
  \if@twoside
    \ifodd\c@page
    \else
      \thispagestyle{empty}%
      \hbox{}%
      \newpage
    \fi
  \fi
}
%% [ThuThesis 移植] 结束 cleardoublepage 处理
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 页眉页脚
%% 页眉：居中显示章节名称；宋体10.5磅居中，Abstract用Roman字体
%% 页脚：居中显示页码；宋体10.5磅居中
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\fancypagestyle{htu@empty}{%
  \fancyhf{}%
  \renewcommand{\headrulewidth}{0pt}%
  \renewcommand{\footrulewidth}{0pt}%
}
\fancypagestyle{htu@plain}{%
  \fancyhf{}%
  \renewcommand{\headrulewidth}{0pt}%
  \renewcommand{\footrulewidth}{0pt}%
  % HTU 定制（spec §2.4）：页码置于页脚外侧——偶数页左下、奇数页右下
  \fancyfoot[LE,RO]{\wuhao\thepage}%
}
%% [ThuThesis 移植] 开始 headings 页面样式 + chaptermark
%% 参考源：ThuThesis v7.7.1 thuthesis.dtx 行 3274-3336
%% 许可证：LPPL（与 ThuThesis 一致）
\fancypagestyle{htu@headings}{%
  \fancyhf{}%
  \if@mainmatter
    %% HTU 定制（spec §2.5）：正文奇偶页居中页眉——偶数页=论文题目，奇数页=一级标题，五号宋体
    \fancyhead[CE]{\wuhao\rmfamily\protect\htu@ctitle}%
    \fancyhead[CO]{\wuhao\rmfamily\rightmark}%
    \renewcommand{\headrulewidth}{\htu@header@rule@thickness}%
    %% HTU 定制：恢复页眉线与文字间距（重连 .def 中 \htu@header@rule@gap；2.2 迁移至 fancyhdr 后此间距一度丢失）
    \renewcommand{\headruleskip}{\htu@header@rule@gap}%
  \else
    %% HTU 定制（spec §2.5「从主体部分开始」）：前置部分无页眉。ctex 在每个章节首页注入
    %% \thispagestyle{htu@headings}，故在此按 \if@mainmatter 自废页眉（headrulewidth=0、不设
    %% \fancyhead），等效 htu@plain，一处覆盖所有前置章节页（摘要/目录/插图清单/表格清单/符号表）。
    \renewcommand{\headrulewidth}{0pt}%
  \fi
  %% HTU 定制（spec §2.4）：页码置于页脚外侧——偶数页左下、奇数页右下
  \fancyfoot[LE,RO]{\wuhao\thepage}%
  \let\@mkboth\markboth
  \def\chaptermark##1{%
    \markboth{%
      \CTEXifname{\CTEXthechapter\quad}{}##1%
    }{%
      \CTEXifname{\CTEXthechapter\quad}{}##1%
    }%
  }%
  \let\sectionmark\@gobble
}
%% [ThuThesis 移植] 结束 headings 页面样式 + chaptermark
\newcommand*{\htu@textcircled}[1]{\lower.7ex\hbox{\tikz\draw (0pt, 0pt)%
    circle (.5em) node {\makebox[1em][c]{\small #1}};}}
\robustify{\htu@textcircled}
\setlist[enumerate,1]{label = (\arabic*)}
\setlist[enumerate,2]{label =  \arabic*)}
\setlist[enumerate,3]{label =  \htu@textcircled{\arabic*}}
\setlist{leftmargin=*, nosep}
\setlist[1]{labelindent=\parindent} % Only the level 1
\let\htu@footnotesize\footnotesize%脚注字体及行距
\renewcommand\footnotesize{\htu@footnotesize\xiaowu[\htu@footnote@linespread]}
% [基础] 脚注每页重新编号（真值来源：spec §1.2.4 line 109「页下注（脚注）…每页重新编号」+ §2.14 line 291
%   case-2「每页重新编号」+ 参考论文 PDF p20=[1]/p21=[1] 实测每页重启）。
%   机制（Story 3.12 切换）：原 Story 3.8 Option A 无包 \@addtoreset{footnote}{page}（cls:369 旧）在 biblatex
%   后端下失效——biblatex \footfullcite 引文脚注 + 解释性 \footnote 共用 footnote 计数器，但 biblatex
%   AtBeginDocument 重定义覆盖了 \@addtoreset 的每页重置（实测：引文脚注跨页连续编号 [2][3]…、解释脚注 p32
%   缺 [1]）。改用 \usepackage[perpage]{footmisc}（Story 3.8 Option B，3.8 code review 2026-06-16 已记录为
%   未来加固路径；Story 3.12 biblatex 切换正是该时机）。footmisc[perpage] 在 \footnote 层面强制每页归零，
%   biblatex \footfullcite 经 \footnote → 同样每页重置（引文脚注 [1] 每页重现，AC-2/I05）。Decision 2：
%   Story 3.8 ATDD-3.8-09/I08 接受 footmisc[perpage]（OR 模式），无需重指向；行为等价（每页重置）。
%   仅重置 footnote，不影响 page 计数器（页码连续性不受影响，AC-6）。
\usepackage[perpage]{footmisc}%每页脚注重置（Story 3.12 Option A biblatex 下替换 \@addtoreset；§1.2.4 line 109）
% [基础] 脚注标记 [N] 方括号化（Story 5.4，2026-06-23；FR-24 refined）. 真值来源：spec §1.2.4 示例1/2 + line 99
%   （顺序编码制 = 方括号 [N]，EXPLICIT — 行内引用标记）+ §2.14 line 289（文末表 [1],[2]… 与正文一致，EXPLICIT）；
%   §1.2.4 line 109（每页重新编号）+ §2.5 line 197（脚注小五号宋体）对标记【形状】沉默 → 参考论文 PDF p20-36（行内
%   上标 + 页下行首均 [N]，实测 57+24 命中 0 裸数）+ GB/T 7714-2015（spec §1.3 / §1.2.4 line 89 引用为著录规则，默认
%   [N]）辅助 → CLAUDE.md Decision 4 辅助层（assumption 8，spec 沉默非违反）. 原 footmisc 默认
%   \thefootnote=\arabic{footnote} → 裸数字 1,2,3（行内上标 + 页下行首两路）；\renewcommand 方括号化. 正交性：
%   footmisc[perpage] 重置计数器（§1.2.4 line 109 每页重置保留），\thefootnote 仅改打印形式 → 两路（\@makefnmark
%   上标 + \@makefntext 页下行首）共用 \thefootnote，一处改两路修. 不影响文末参考文献表（cls:139 gbt7714-2015 已 [N]）.
\renewcommand\thefootnote{[\arabic{footnote}]}%脚注标记 [N]（Story 5.4；spec §1.2.4 示例 + 参考 PDF p20-36 + GB/T 7714-2015）
% [基础] 页下脚注行首标记行内化（Story 5.4 code-review fix，2026-06-23）. 默认 \@makefntext 经 \@makefnmark
%   （=\@textsuperscript）将行首标记上标化（缩小+抬高，实测 6pt raised），与参考论文 PDF p20-24 不符——参考论文
%   页下注行首 [N] 与脚注正文同字号（小五 9pt SimSun）同行行内排列（[1] 陈军亚... flush-left 同 span），非上标.
%   改用 \@thefnmark（原始 [N]，未经 \@textsuperscript 包裹）行内渲染；字号继承脚注正文 \footnotesize（小五 9pt）.
%   行内引用上标（\@footnotemark → \@makefnmark）不变仍上标——仅改页下行首. 真值源：参考论文 PDF p20-24
%   （[N] 9pt SimSun 行内）+ spec §2.5 line 197「脚注用小五号宋体字」（标记同字号隐含）. 闭合 AC-2 真实形态.
\renewcommand\@makefntext[1]{\parindent\z@\noindent\@thefnmark\enspace#1}%页下注行首 [N] 行内（非上标；Story 5.4 code-review fix）
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%    浮动对象、图片、表格、公式设置
%% 1. 若插入的图片未指定扩展名，则在指定文件路径搜索pdf，eps，png，jpg，jpeg文件
%%    搜索路径在主文件中定义；
%% 2. 定义tabularx环境中的Z选项，用于居中自动调整，定义命令\Xhline
%% 3. 公式、图片、表格编号分隔符为句号，即“3.1”的形式
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\setlength{\floatsep}{\htu@floatsep \@plus4\p@\@minus\p@}%浮动对象和文字间的距离
\setlength{\intextsep}{\htu@floatsep \@plus4\p@\@minus\tw@\p@}
\setlength{\textfloatsep}{\htu@floatsep \@plus4\p@\@minus2\p@}
\setlength{\@fptop}{0bp \@plus1.0fil}
\setlength{\@fpsep}{\htu@floatsep \@plus2.0fil}
\setlength{\@fpbot}{0bp \@plus1.0fil}
\renewcommand{\textfraction}{\htu@textfraction}%页面文本的最小比例(0.2)
\renewcommand{\topfraction}{\htu@topfraction}%页顶浮动对象高/页高的最大值(0.7)
\renewcommand{\bottomfraction}{\htu@bottomfraction}%页底浮动对象高/页高的最大值(0.3)
\renewcommand{\floatpagefraction}{\htu@floatpagefraction}%浮动页由浮动对象占用的最小比例(0.5)
\DeclareGraphicsExtensions{.pdf,.eps,.png,.jpg,.jpeg}%搜索指定扩展名
\DeclareCaptionLabelSeparator{htu}{\hspace{0.5\ccwd}}%图表序与图表名之间空半格（spec §2.11/§2.12「编号和图题间空半格」= 0.5\ccwd 半字距）。真值源：spec PRIORITY（CLAUDE.md Decision 4 修正 2026-06-17）。参考论文 PDF pp.58/95/138/140/207 实测为全角冒号「：」（参考为 Word 填充实例，此处偏离 spec）。Story 3.13 翻案 Story 3.6 Option A（2026-06-16 reference-wins 取冒号）→ 回归 spec 空半格（gap 1a）。
\DeclareCaptionFont{htu}{\wuhao[1.5]}
\captionsetup{
  font           = htu,
  labelsep       = htu,
  figureposition = bottom,
  tableposition  = top,
}
\captionsetup[table]{belowskip={\htu@caption@table@belowskip},aboveskip=\htu@caption@table@aboveskip}
\captionsetup[figure]{%段前空6磅，段后空12磅
  belowskip={\htu@caption@figure@belowskip-\intextsep},aboveskip=\htu@caption@figure@aboveskip}
\captionsetup[sub]{font=htu,skip=\htu@caption@sub@skip}
\renewcommand{\thesubfigure}{(\alph{subfigure})}%子图形编号：字母
\renewcommand{\thesubtable}{(\alph{subtable})}%子表格编号：字母
\let\old@tabular\@tabular
\def\htu@tabular{\wuhao[1.5]\old@tabular}%
\let\htu@LT@array\LT@array%长表格
\def\LT@array{\wuhao[1.5]\htu@LT@array}
\newcolumntype{Z}{>{\centering\arraybackslash}X}%居中自动调整
\newcommand\Xhline[1]{\noalign{\ifnum0=`}\fi\arrayrulewidth#1%
        \ifx\hline\LT@hline\let\@xhline\LT@@hline\fi
        \hrule\@height\arrayrulewidth\futurelet\reserved@a\@xhline}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 数学相关
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\renewcommand\theequation{%公式编号分隔符（HTU §2.13 短横线）
  \ifnum \c@chapter>\z@ \thechapter\htu@counter@separator\fi\@arabic\c@equation}
% [基础] 公式序号外层括号 = 全角（）(HTU §2.13 line 279「（1-1）」；amsmath 默认 ASCII () 不符)。
%   override amsmath \tagform@ (amsmath.sty:1212「\def\tagform@#1{\maketag@@@{(...)}}」)，同时作用于行间公式
%   tag (\@eqnnum = \tagform@\theequation) 与 \eqref 交叉引用（amsmath.sty:1143「\eqref = \tagform@{\ref{}}」）。
%   全角括号走 CJK 字体(SimSun)，编号走 \rmfamily(TNR)，匹配 spec 示例「（1-1）」混排。
%   Story 3 retro 2026-06-20 规则审计 G-A：原默认 ASCII (4-1)，spec §2.13 要全角（4-1）。
\renewcommand{\tagform@}[1]{\maketag@@@{（\ignorespaces#1\unskip\@@italiccorr）}}
\renewcommand\thefigure{%插图编号分隔符（HTU §2.11 短横线）
  \ifnum \c@chapter>\z@ \thechapter\htu@counter@separator\fi\@arabic\c@figure}
\renewcommand\thetable{%表格编号分隔符（HTU §2.12 短横线）
  \ifnum \c@chapter>\z@ \thechapter\htu@counter@separator\fi\@arabic\c@table}
\allowdisplaybreaks[4]%允许公式断行分页
\def\htu@theorem@separator{：}%
\newtheoremstyle{theorem}%定理类型
  {0.5ex}%Space above
  {0.5ex}%Space below
  {\rmfamily}%Body font
  {}%Indent amount 
  {\sffamily\htu@tnr}%Theorem head font (Latin→TNR, G6 structural; Epic 3 retro action #5 2026-06-21)
  {\htu@theorem@separator}%Punctuation after theorem head
  {1em}%Space after theorem head
  {}%Theorem head spec
\renewenvironment{proof}[1][\proofname]{\par%证明
  \pushQED{\qed}%
  \normalfont \topsep6\p@\@plus6\p@\relax
  \trivlist
  \item[\hskip\labelsep
  \sffamily\htu@tnr
  #1\@addpunct{\quad}]\ignorespaces}
  {\popQED\endtrivlist\@endpefalse}
\theoremstyle{theorem}
\newtheorem{definition}{\htu@definition@name}[chapter]
\newtheorem{theorem}{\htu@theorem@name}[chapter]
\newtheorem{lemma}[theorem]{\htu@lemma@name}
\newtheorem{corollary}[theorem]{\htu@corollary@name}
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 章节标题
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [基础] 标题编号 = 人文社科制 第一章/第一节/一、/（1）（spec §2.10 line 239-243 PRIORITY，CLAUDE.md Decision 4
%   修正 2026-06-17）。参考论文 PDF（政治与公共管理学院，人文社科）用同制印证。Story 3.13 翻案 Story 2.5 自然科学制
%   Arabic（name=\relax）→ 人文社科制（sprint-change-proposal-2026-06-17 gap M4）。机制：ctex name={前,后} + number=
%   显示键。§2.10 人文社科「标题编号和标题名称间不空格」→ aftername={}（原 \hskip\ccwd 半字距为自然科学制，删除）。
%   AC-3a 关键护栏：number= 仅改 \CTEXthechapter 显示（第一章），绝不可重定义 \thechapter（否则图表编号 图 一-1 灾难）；
%   下方 \thechapter 防御性锁定 \@arabic\c@chapter，图表编号仍 图 1-1（Arabic，§2.11/2.12/2.13）。
%   副作用（code review 2026-06-19 决策 b 接受）：ctex number=\chinese{chapter} 把中文写入 .aux label → \ref{ch:X}
%   渲染「一/二」（章交叉引用），而图表式引用 \ref{fig:X} 仍 Arabic（图 1-1）。人文社科惯例：章引用用中文、图表式用
%   Arabic——双轨符合 spec 意图（§2.10 人文社科 + §2.11/2.12/2.13 图表 Arabic）。已确认接受。
\ctexset{%
  chapter={%一级标题：黑体三号(16bp)，居中，段前段后2行（HTU §2.10 人文社科 第一章）
    afterindent=true,
    pagestyle={htu@headings},
    beforeskip=\htu@chapter@beforeskip,
    aftername={},%§2.10 人文社科「标题编号和标题名称间不空格」（原 \hskip\ccwd 为自然科学制，删）
    afterskip=\htu@chapter@afterskip,
    format={\sffamily\htu@tnr\sanhao[\htu@chapter@linespread]},
    name={第,章},
    number=\chinese{chapter},
    nameformat=\relax,
    titleformat=\relax,
    lofskip=0pt,
    lotskip=0pt,
  },
  section={%二级标题：黑体小三号(15bp)，居中，段前段后0.5行（HTU §2.10 人文社科 第一节）
    afterindent=true,
    beforeskip={\htu@section@beforeskip \@plus .5ex \@minus .2ex},
    afterskip={\htu@section@afterskip \@plus .2ex},
    format={\sffamily\htu@tnr\xiaosan[\htu@section@linespread]\centering},
    name={第,节},
    number=\chinese{section},
  },
  subsection={%三级标题：黑体四号(14bp)，居左空两格，段前段后0.5行（HTU §2.10 人文社科 一、）
    afterindent=true,
    indent=2\ccwd,
    beforeskip={\htu@subsection@beforeskip \@plus .5ex \@minus .2ex},
    afterskip={\htu@subsection@afterskip \@plus .2ex},
    format={\sffamily\htu@tnr\sihao[\htu@subsection@linespread]},
    name={,、},
    number=\chinese{subsection},
  },
  subsubsection={%四级标题：宋体小四号(12bp)加粗，居左空两格（HTU §2.10 人文社科 L4 （1）；段前段后为推断值）
    afterindent=true,
    indent=2\ccwd,
    beforeskip={\htu@subsubsection@beforeskip \@plus .5ex \@minus .2ex},
    afterskip={\htu@subsubsection@afterskip \@plus .2ex},
    format={\htu@songtibold\bfseries\xiaosi[\htu@subsubsection@linespread]},
    name={（,）},
    number=\arabic{subsubsection},
  },
  paragraph/afterindent=true,
  subparagraph/afterindent=true}
% [基础] 自然科学制（numbering=sc）ctex 覆盖（spec §2.10 line 235-237；Story 3.15 G3 / D-22）。
%   默认 hs（上方 \ctexset）。sc 模式覆盖：name={,}（去 第/章 节 包装）+ number=Arabic（章 1，节 1.1，小节 1.1.1 半角）
%   + aftername=\hspace{0.5\ccwd}（编号名空半格 §2.10 line 237）+ format 不居中（顶格；章/节标题）。
%   beforeskip/afterskip/indent 沿用 hs 默认。\thechapter Arabic 锁（cls 下方）+ 图表编号 图 1-1 不受影响（§2.11/2.12/2.13）。
\ifhtu@numbersc
  \ctexset{%
    chapter={%一级标题：黑体三号(16bp)，顶格，段前段后2行（NS §2.10「1」）
      aftername=\hspace{0.5\ccwd},%§2.10 NS 编号名空半格（hs 为不空格）
      format={\sffamily\htu@tnr\sanhao[\htu@chapter@linespread]},%顶格（sc 不居中；format 无 \centering）
      name={,},%NS 去包装（hs name={第,章}）
      number=\arabic{chapter},%NS Arabic（hs \chinese{chapter}）
    },
    section={%二级标题：黑体小三号(15bp)，顶格（NS §2.10「1.1」）
      aftername=\hspace{0.5\ccwd},
      format={\sffamily\htu@tnr\xiaosan[\htu@section@linespread]},%顶格（hs 含 \centering，NS 去）
      name={,},
      number=\arabic{chapter}.\arabic{section},%NS 1.1 半角
    },
    subsection={%三级标题：黑体四号(14bp)，顶格（NS §2.10「1.1.1」）
      aftername=\hspace{0.5\ccwd},
      format={\sffamily\htu@tnr\sihao[\htu@subsection@linespread]},
      name={,},
      number=\arabic{chapter}.\arabic{section}.\arabic{subsection},%NS 1.1.1 半角
    },
  }%
\fi
% [基础] AC-3a 防御护栏：锁定 \thechapter = Arabic 计数器（Story 3.13 Task 3.2，code review 2026-06-19 注释订正）。
%   ctex number=\chinese{chapter} 写入 \CTEXthechapter（标题显示 第一章），不写 \thechapter（计数器宏）——ctex 源
%   ctex-heading-book.def 验证。base book.cls 已定义 \thechapter=\@arabic\c@chapter，故此 \renewcommand 当前为 no-op，
%   仅作防御性锁：若未来 ctex/其他宏包改写 \thechapter，此行将其钉回 Arabic，确保 \thefigure/\thetable/\theequation
%   （cls 上方 cls:413-418）仍呈 图 1-1 / 表 1-1 / (1-1)（§2.11/2.12/2.13）。\appendix 运行时（文档体内，晚于此处）
%   \gdef \thechapter=\@Alph（附录 A）覆盖此行，故附录 A-1 编号不受影响。ATDD I05（rendered 24 Arabic）+ unit-09/10 守卫。
\renewcommand{\thechapter}{\@arabic\c@chapter}
\newcounter{htu@bookmark}
\def\htu@chapter*{%\htu@chapter*[tocline]{title}[header]
  %% \@ifnextchar peeks at the following character and compares it with its first argument. 
  %% If both are the same it executes its second argument, otherwise its third.
  \@ifnextchar [ % ]
    {\htu@@chapter}
    {\htu@@chapter@}}
\def\htu@@chapter@#1{\htu@@chapter[#1]{#1}}
\def\htu@@chapter[#1]#2{%
  \@ifnextchar [ % ]
    {\htu@@@chapter[#1]{#2}}
    {\htu@@@chapter[#1]{#2}[]}}
\def\htu@@@chapter[#1]#2[#3]{%
  \clearpage\phantomsection%
  \def\@tmpa{#1}
  \def\@tmpb{#3}
  \ifx\@tmpa\@empty
    \addtocounter{htu@bookmark}\@ne
    \pdfbookmark[0]{#2}{htuchapter.\thehtu@bookmark}
  \else
    \addcontentsline{toc}{chapter}{#1}
  \fi
  \chapter*{#2}
  \ifx\@tmpb\@empty
    \@mkboth{#2}{#2}
  \else
    \@mkboth{#3}{#3}
  \fi}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 目录及图表清单
%% 目录利用titletoc宏包对目录进行定制
%% 
%% 目录（HTU §2.6 目录 + §1.1.4；参考论文 p10 实测，三源三角 Decision 4）：
%%   标题"目 录"= 三号黑体居中（\htu@chapter* → \sffamily\sanhao，cls:510）。
%%   一级标题（章）= 小四号黑体（\xiaosi[1]\sffamily → 12pt SimHei，via 3.9 \setCJKsansfont{SimHei}）。
%%   二级/三级标题（节/小节）= 小四号宋体（\xiaosi[1] → 12pt SimSun，文档默认 CJK 面）。
%%   每下一级向右缩进一格（[0]/[2\ccwd]/[4\ccwd]；参考 p10 delta=24pt=2\ccwd/级）。
%%   点引导线 \titlerule*{.}；显示至三级标题（\htu@tocdepth=2）。
%%   Latin（页码/章号/点引导线）：label + leader 内 \rmfamily 守卫渲染 TNR（防 \sffamily→LMSans 退化；Story 3.5）。
%%   [基础] 旧 zzuthesis 原始值（章 14 磅宋体 / 小节 10.5 磅）已按 HTU §2.6 校正——spec+参考 PDF 一致，
%%          纯实现漂移修正（非透明偏离）。图表清单（插图/表格清单）仍用 \wuhao[1.524]（§1.1.5，非 §2.6，FR-17 范围外）。
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\setcounter{secnumdepth}{\htu@secnumdepth}%章节编号深度：4
\setcounter{tocdepth}{\htu@tocdepth}%目录深度：2
\renewcommand\tableofcontents{%
  \htu@chapter*[]{\contentsname}
  \@starttoc{toc}\normalsize}
\renewcommand\listoffigures{%
  \htu@chapter*[]{\listfigurename}
  \@starttoc{lof}}
\renewcommand\listoftables{%
  \htu@chapter*[]{\listtablename}
  \@starttoc{lot}}
\titlecontents{chapter}[\z@]{\vspace{6bp}\xiaosi[1]\sffamily\htu@tnr}
  {\thecontentslabel\quad}{}
  {\rmfamily\hspace{.5em}\titlerule*{.}\xiaosi\contentspage}
\titlecontents{section}[2\ccwd]{\vspace{6bp} \xiaosi[1]}
  {\thecontentslabel\quad}{}
  {\hspace{.5em}\titlerule*{.}\xiaosi\contentspage}
\titlecontents{subsection}[4\ccwd]{\vspace{6bp} \xiaosi[1]}
  {\thecontentslabel\quad}{}
  {\hspace{.5em}\titlerule*{.}\xiaosi\contentspage}
\titlecontents{figure}[\z@]{\wuhao[1.524]}%10.5bp，16bp
  {\makebox[3.5em][l]{\figurename~\thecontentslabel\quad}}{}
  {\hspace{.5em}\titlerule*{.}\contentspage}
\titlecontents{table}[\z@]{\wuhao[1.524]}%10.5bp，16bp
  {\makebox[3.5em][l]{\tablename~\thecontentslabel\quad}}{}
  {\hspace{.5em}\titlerule*{.}\contentspage}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 封面
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\def\htu@def@term#1{%定义封面的一些替换命令
  \expandafter\gdef\csname #1\endcsname##1{%
    \expandafter\gdef\csname htu@#1\endcsname{##1}}
  \csname #1\endcsname{}}
\htu@def@term{schoolcode}
\htu@def@term{id}
\htu@def@term{secretlevel}
\htu@def@term{protitle}
\htu@def@term{ctitle}
\htu@def@term{cauthor}
\htu@def@term{stuno}
\htu@def@term{csupervisor}
\htu@def@term{csubject}
\htu@def@term{cmajor}
\htu@def@term{researchdirection}
\htu@def@term{degreecategory}
\htu@def@term{cdepartment}
\htu@def@term{cdate}
\htu@def@term{etitle}
\htu@def@term{eauthor}
\htu@def@term{esupervisor}
\htu@def@term{emajor}
\htu@def@term{edepartment}
\htu@def@term{edate}
\htu@def@term{edegree}
  % [基础] 封面日期 = 中文数字（spec §1.1.1 line 33「封面上的日期…用中文表示，如二〇二四年五月」；Story 3.15 G4）。
  %   原用 \CJK@todaysmall@short（\the\year 年 \the\month 月 = 阿拉伯数字）—— 2026-06-19 审计 G4 gap。
  %   改用 zhnumber 宏包（cls 顶部载入）：\zhdigits{2026}=二〇二六（逐位，匹配 spec「二〇二四」 digit 形），
  %   \zhnumber{6}=六（月）。注：cls:186 \CJK@todaybig@short 依赖未定义的 \CJKdigits/\CJKnumber（xeCJK 不提供），
  %   故用 zhnumber 直接渲染而非 \CJK@todaybig。
  %   设计决策（story Dev Notes §G4）：保留模板既有「编译日期」设计（\the\year/\the\month）；G4 闭合「字形」gap
  %   （阿拉伯→中文数字）。论文实际提交日 ≈ 编译日；若需显式论文年/月，未来增强暴露 \cdateyear/\cdatemonth。
  %   ✅ Zy 批准 2026-06-20 code-review：选项 (a) 编译日 + 中文数字字形（spec §1.1.1「用中文表示」合规；
  %      透明偏离 = 日期值用编译日非显式提交日，记入此注释 + story Review Findings）。
  \cdate{\zhdigits{\the\year} 年 \zhnumber{\the\month} 月}%
\edate{\ifcase \month \or January\or February\or March\or April\or May%
       \or June\or July \or August\or September\or October\or November
       \or December\fi\unskip,\ \ \the\year}
% [基础] 英文学位类别默认值（真值来源：.doc「博士学位论文扉页」"Doctor of Philosophy in Science/Engineering Science"）。
%   学生按学科门类在 data/cover.tex 用 \edegree{} 覆盖（法学→Doctor of Law 等，见
%   「硕士学位论文扉页及学位类别术语英文标准翻译.doc」，博士将 Master 替换为 Doctor）。
\edegree{Doctor of Philosophy in Science/Engineering Science}
\newcommand\htu@underline[2][6em]{%
  \hskip\p@\underline{\hb@xt@ #1{\hss#2\hss}}\hskip3\p@}
\newcommand{\htu@first@titlepage}{%论文中文封面（博士学位论文封面）
  \thispagestyle{htu@empty}%
  % [基础] 封面布局：TikZ remember-picture overlay 绝对定位（mm 坐标，原点=current page 节点）。
  %   真值来源（三源三角，CLAUDE.md Decision 4）：
  %     1) 参考论文 参考博士论文.pdf page 2（已完成 HTU 博士封面，视觉真值）
  %     2) .doc 空白模板「博士学位论文封面（电子版用）」（官方下载，权威空白形式）
  %     3) 本 [基础] 注释（实现层映射）
  %   字体（双源一致）：元数据=仿宋12pt；校名=书法体图像91mm×27.3mm；「博士学位论文」=宋体45pt；
  %                    论文题目=黑体小二(18pt)；五字段=黑体小三(15pt)；日期=黑体小三(15pt)。
  %   日期格式=阿拉伯数字+年/月（.doc 空白模板 + 参考论文双源确认；spec §1.1.1「二〇二四年五月」为理想化文本，
  %     按 Word 模板 > spec 的真值源层次，阿拉伯胜出——Decision 4 透明偏离）。
  %   R-9（score 6）：9 个元素绝对定位，±3mm 容差；R-6（score 6）：绝对定位相对纸张（非 \textwidth），
  %     消除 includeheadfoot 后 textwidth 146→160mm 变化对封面的耦合（Story 2.1 deferred 债）。
  \begin{tikzpicture}[remember picture, overlay]
    % --- 元数据表格（4H×3V 边框；FR-11，spec §1.1.1）---
    %   真值源（三源三角，CLAUDE.md Decision 4，spec 优先）：
    %     1) spec §1.1.1「封面统一使用学校规定的样式」→ 委托学校 .doc（权威空白形式）
    %     2) 参考论文 参考博士论文 page 2（辅助视觉真值）：7 线段表格 =
    %        4 横线 y=20.5/29.5/38.4/47.4mm + 3 竖线 x=21.4/45.7/74.3mm；
    %        label 列 21.4→45.7mm(24.3mm) + value 列 45.7→74.3mm(28.6mm)
    %     3) 本 [基础] 注释（实现层映射）
    %   Story 3.1 已把文本行放对 y 位置（22.8/31.9/40.8mm = 参考精确匹配）；Story 3.10 仅：
    %     (a) 拆 label/value 为双节点落进各自列（实现真 2 列），(b) 补 7 条 \draw 边线。
    %   纯 frame-ADD，不挪文本 y → R-9 ±3mm + ATDD-3.1-I06 不变。
    %   \htu@fangsong@latin：ASCII 数字/字母也走 FangSong（匹配参考论文 page 2 span 级字体）。
    %   放弃 \htu@underline（原 value 下划线）—— 单元格边框取代之。Story 3.14 (2026-06-19)
    %   删除 \htu@abstractcover 后，\htu@underline 零调用（死代码，留待 Epic 4 cleanup）。
    \draw[thin] ($(current page.north west)+(21.4mm,-20.5mm)$) -- ($(current page.north west)+(74.3mm,-20.5mm)$);% 上边
    \draw[thin] ($(current page.north west)+(21.4mm,-29.5mm)$) -- ($(current page.north west)+(74.3mm,-29.5mm)$);% 行1/2 分隔
    \draw[thin] ($(current page.north west)+(21.4mm,-38.4mm)$) -- ($(current page.north west)+(74.3mm,-38.4mm)$);% 行2/3 分隔
    \draw[thin] ($(current page.north west)+(21.4mm,-47.4mm)$) -- ($(current page.north west)+(74.3mm,-47.4mm)$);% 下边
    \draw[thin] ($(current page.north west)+(21.4mm,-20.5mm)$) -- ($(current page.north west)+(21.4mm,-47.4mm)$);% 左边
    \draw[thin] ($(current page.north west)+(45.7mm,-20.5mm)$) -- ($(current page.north west)+(45.7mm,-47.4mm)$);% 列分隔
    \draw[thin] ($(current page.north west)+(74.3mm,-20.5mm)$) -- ($(current page.north west)+(74.3mm,-47.4mm)$);% 右边
    % --- 元数据文本（label 列 x=23.3 / value 列 x=50；仿宋小四 12pt）---
    \node[anchor=north west, inner sep=0pt]
      at ($(current page.north west) + (23.3mm, -22.8mm)$)
      {\fangsong\htu@fangsong@latin\xiaosi\makebox[20mm][s]{\htu@schoolcode@title}};
    \node[anchor=north west, inner sep=0pt]
      at ($(current page.north west) + (50mm, -22.8mm)$)
      {\fangsong\htu@fangsong@latin\xiaosi\htu@schoolcode};
    \node[anchor=north west, inner sep=0pt]
      at ($(current page.north west) + (23.3mm, -31.9mm)$)
      {\fangsong\htu@fangsong@latin\xiaosi\makebox[20mm][s]{\htu@id@title}};
    \node[anchor=north west, inner sep=0pt]
      at ($(current page.north west) + (50mm, -31.9mm)$)
      {\fangsong\htu@fangsong@latin\xiaosi\htu@id};
    \node[anchor=north west, inner sep=0pt]
      at ($(current page.north west) + (23.3mm, -40.8mm)$)
      {\fangsong\htu@fangsong@latin\xiaosi\makebox[20mm][s]{\htu@secretlevel@title}};
    \node[anchor=north west, inner sep=0pt]
      at ($(current page.north west) + (50mm, -40.8mm)$)
      {\fangsong\htu@fangsong@latin\xiaosi\htu@secretlevel};
    % --- 校名（书法体图像，居中，91mm×27.3mm；y=58.5mm 顶部）---
    \node[anchor=north, inner sep=0pt]
      at ($(current page.north) + (0mm, -58.5mm)$)
      {\includegraphics[width=91mm]{htu-text-logo}};
    % --- 「博士学位论文」标签（宋体45pt，居中，y=89.1mm）---
    \node[anchor=north, inner sep=0pt]
      at ($(current page.north) + (0mm, -89.1mm)$)
      {\fontsize{45bp}{54bp}\selectfont\htu@subtitle};
    % --- 论文题目（黑体小二18pt，居中，y=133.4mm）---
    \node[anchor=north, inner sep=0pt, text width=160mm, align=center]
      at ($(current page.north) + (0mm, -133.4mm)$)
      {\sffamily\htu@tnr\xiaoer[1.5]\htu@ctitle};
    % --- 五字段（黑体小三15pt，左 x=60mm，label：value 格式）---
    \node[anchor=north west, inner sep=0pt]
      at ($(current page.north west) + (60.3mm, -191.9mm)$)
      {\sffamily\htu@tnr\xiaosan\htu@subject@title\htu@title@sep\htu@csubject\htu@cmajor};
    \node[anchor=north west, inner sep=0pt]
      at ($(current page.north west) + (60.3mm, -200.1mm)$)
      {\sffamily\htu@tnr\xiaosan\htu@researchdirection@title\htu@title@sep\htu@researchdirection};
    \node[anchor=north west, inner sep=0pt]
      at ($(current page.north west) + (60.3mm, -208.2mm)$)
      {\sffamily\htu@tnr\xiaosan\htu@degreecategory@title\htu@title@sep\htu@degreecategory};
    \node[anchor=north west, inner sep=0pt]
      at ($(current page.north west) + (60.3mm, -216.3mm)$)
      {\sffamily\htu@tnr\xiaosan\htu@author@title\htu@title@sep\htu@cauthor};
    \node[anchor=north west, inner sep=0pt]
      at ($(current page.north west) + (60.3mm, -224.4mm)$)
      {\sffamily\htu@tnr\xiaosan\htu@supervisor@title\htu@title@sep\htu@csupervisor};
    % --- 完成日期（黑体小三15pt，居中，y=247.7mm；阿拉伯数字+年/月）---
    %   \htu@heiti@latin：ASCII 数字也走 SimHei（匹配参考论文 page 2 日期全 SimHei run）
    \node[anchor=north, inner sep=0pt]
      at ($(current page.north) + (0mm, -247.7mm)$)
      {\sffamily\htu@heiti@latin\xiaosan\htu@cdate};
  \end{tikzpicture}%
  \null% 确保仅含 overlay 的 titlepage 页正常 shipout（overlay 零尺寸，\null 提供可输出内容）
} % end of titlepage
\newcommand{\htu@engcover}{%博士论文英文扉页（FR-13）
  \thispagestyle{htu@empty}%
  % [基础] 英文扉页布局：TikZ remember-picture overlay 绝对定位（mm，原点=current page 节点）。
  %   真值来源（三源三角，CLAUDE.md Decision 4）：
  %     1) 参考论文 参考博士论文.pdf page 3（已完成 HTU 博士英文扉页，视觉真值）
  %     2) .doc 空白模板「博士学位论文扉页」（官方下载，权威空白形式）
  %     3) 本 [基础] 注释（实现层映射）
  %   全页 Times New Roman（Story 3.9 \setmainfont{TNR} → \rmfamily Latin = TNR），居中。
  %   结构（参考 page 3 + .doc 扉页）：
  %     标题(TNR 18pt regular) → 学位陈述 5 行（A Dissertation Submitted to the Graduate School of
  %     Henan Normal University in Partial Fulfillment of the Requirements for the Degree of [degree]，
  %     TNR 15pt）→ By [author] / Supervisor: Prof. [supervisor] / [date]（TNR 15pt）。
  %   AC-4：不渲染 \htu@emajor/\htu@edepartment（参考论文 page 3 + .doc 扉页均无此两行）。
  %   R-6（score 6）：消除英文封面 \parbox 的硬编码纸张宽度（Story 2.1 deferred 债）→ 纸张绝对定位。
  \begin{tikzpicture}[remember picture, overlay]
    % --- 论文题目（TNR 18pt regular，居中，y≈36mm；长标题自然换行）---
    % [基础] 英文论文题目 = UPPERCASE (ALL CAPS)，真值源 spec §1.1.1 line 35「扉页上的英文论文题目用大写字母」
    %   (D-20 spec-priority; D-23 2026-06-22 resolves prior Title Case deferral)。机制：cls 端 \MakeUppercase
    %   强制大写——无论用户 \etitle{} 输入何种 case，输出均 ALL CAPS（architecture §用户分层设计「默认正确」，
    %   用户无需手记大写规则）。仅作用于 \htu@etitle（论文题目）；学位陈述/作者/导师/日期不在 spec 大写要求内，
    %   保持 Title Case。参考论文 Title Case 是其自身对 spec 的偏离，非权威（D-20）。
    \node[anchor=north, inner sep=0pt, text width=160mm, align=center]
      at ($(current page.north) + (0mm, -36mm)$)
      {\rmfamily\fontsize{18bp}{22bp}\selectfont\MakeUppercase{\htu@etitle}};
    % --- 学位陈述（TNR 15pt，居中，5 行；y=98/109/120/131/142mm 对齐参考 page 3）---
    \node[anchor=north, inner sep=0pt]
      at ($(current page.north) + (0mm, -98mm)$)
      {\rmfamily\fontsize{15bp}{18bp}\selectfont A Dissertation Submitted to};
    \node[anchor=north, inner sep=0pt]
      at ($(current page.north) + (0mm, -109mm)$)
      {\rmfamily\fontsize{15bp}{18bp}\selectfont the Graduate School of Henan Normal University};
    \node[anchor=north, inner sep=0pt]
      at ($(current page.north) + (0mm, -120mm)$)
      {\rmfamily\fontsize{15bp}{18bp}\selectfont in Partial Fulfillment of the Requirements};
    \node[anchor=north, inner sep=0pt]
      at ($(current page.north) + (0mm, -131mm)$)
      {\rmfamily\fontsize{15bp}{18bp}\selectfont for the Degree of};
    \node[anchor=north, inner sep=0pt]
      at ($(current page.north) + (0mm, -142mm)$)
      {\rmfamily\fontsize{15bp}{18bp}\selectfont\htu@edegree};
    % --- 作者块（TNR 15pt，居中，4 行；y=190/201/212/223mm；作者名斜体匹配参考 page 3）---
    \node[anchor=north, inner sep=0pt]
      at ($(current page.north) + (0mm, -190mm)$)
      {\rmfamily\fontsize{15bp}{18bp}\selectfont By};
    \node[anchor=north, inner sep=0pt]
      at ($(current page.north) + (0mm, -201mm)$)
      {\rmfamily\fontsize{15bp}{18bp}\selectfont\itshape\htu@eauthor};
    \node[anchor=north, inner sep=0pt]
      at ($(current page.north) + (0mm, -212mm)$)
      {\rmfamily\fontsize{15bp}{18bp}\selectfont Supervisor: \htu@esupervisor};
    \node[anchor=north, inner sep=0pt]
      at ($(current page.north) + (0mm, -223mm)$)
      {\rmfamily\fontsize{15bp}{18bp}\selectfont\htu@edate};
  \end{tikzpicture}%
  \null% 确保 overlay-only 页正常 shipout
}
% Story 3.14 (2026-06-19): \htu@abstractcover「摘要封面」DELETED — spec §1.1 line 5 前置部分枚举
%   （封面、扉页、摘要、ABSTRACT、目录…）无「摘要封面」；参考论文 PDF pp.1-12 亦无（p3 英文扉页 →
%   p4 中文摘要连续）。原 3.2 误加该 HTU-unique 封面；spec PRIORITY (CLAUDE.md Decision 4 修正) 删除之。
%   FR-12 (abstract cover) RETIRED。其唯一 \htu@underline 调用归零（见 first@titlepage 注释）。
% [基础] 声明文本真值源 = 学校统一规定的样式《独创性声明和关于论文使用授权的说明》(.doc)，
%   spec §1.5.3（研究生本人和导师手写签名）。参考论文 PDF 不含声明页（三源空缺，Decision 4），
%   故 .doc 为唯一 verbatim 文本源。正文用字面“河南师范大学”（法律文本安全，不用 \htu@schoolname 宏）。
%   Story 3.3 (2026-06-15)：替换旧模板文本为 HTU .doc verbatim；标题/签名/日期标签同步对齐。
\newcommand{\htu@declarename}{独创性声明}
\newcommand{\htu@authtitle}{关于论文使用授权的说明}
\newcommand{\htu@declaretocname}{独创性声明和关于论文使用授权的说明}
\newcommand{\htu@authorsigtitle}{作者签名：}
\newcommand{\htu@supervisorsigtitle}{导师签名：}
\newcommand{\htu@datesigtitle}{日期：}
\newcommand{\htu@declaretext}{\hspace{2\ccwd}本人郑重声明：所呈交的学位论文是我个人在导师指导下进行的研究工作及取得的研究成果。尽我所知，除了文中特别加以标注和致谢的地方外，论文中不包含其他人已经发表或撰写的研究成果，也不包含为获得河南师范大学或其他教育机构的学位或证书所使用过的材料。与我一同工作的同志对本研究所做的任何贡献均已在论文中作了明确的说明并表示了谢意。}
\newcommand{\htu@authorization}{\hspace{2\ccwd}本人完全了解河南师范大学有关保留、使用学位论文的规定，即：有权保留并向国家有关部门或机构送交论文的复印件和磁盘，允许论文被查阅和借阅。本人授权河南师范大学可以将学位论文的全部或部分内容编入有关数据库进行检索，可以采用影印、缩印或扫描等复制手段保存、汇编学位论文。（保密的学位论文在解密后适用本授权书）}
\newcommand{\htu@authorization@mk}{%独创性声明 + 授权说明（HTU 后置页；spec §1.1 结尾部分末项；FR-14）
  % 复用 Epic 2 \htu@chapter* 机制：独立页 + 三号黑体居中标题 + 目录条目（组合名）+ 页眉 + 阿拉伯页码（spec §2.4/§1.1.4）。
  \htu@chapter*[\htu@declaretocname]{\htu@declarename}[\htu@declarename]
  \xiaosi[1.6]\htu@declaretext
  \vskip 16pt
  \htu@authorsigtitle\,\underline{\hspace{3cm}}\hfill\htu@datesigtitle\,\underline{\hspace{2cm}}\par
  \vskip 22pt
  \begin{center}\sffamily\htu@tnr\sanhao \htu@authtitle\end{center}
  \vskip 10pt
  \xiaosi[1.6]\htu@authorization
  \vskip 16pt
  \htu@authorsigtitle\,\underline{\hspace{2.5cm}}\hfill\htu@supervisorsigtitle\,\underline{\hspace{2.5cm}}\hfill\htu@datesigtitle\,\underline{\hspace{2cm}}\par
  \normalsize% 恢复正文字号/行距（R-3：声明页为 \AtEndDocument 前最后内容，避免 \xiaosi[1.6] 行距泄漏到自检的 baselineskip 读数）
}
\def\htu@setup@pdfinfo{%pdf文档信息
  \hypersetup{%
    pdftitle={\htu@ctitle},
    pdfauthor={\htu@cauthor},
    pdfsubject={\htu@schoolname\htu@subtitle},
    pdfkeywords={\htu@ckeywords},
    pdfcreator={\htuthesis-v\version}}}
\newcommand{\makecover}{%制作封面
  \ifx\htu@ctitle\@empty\PackageError{htuthesis}{htuthesis ERROR: Chinese title (\string\ctitle) is empty -- cover cannot render without a title (Story 4.2, deferred-work §3.2).}{Set the title via \string\ctitle{...} in the preamble.}\fi
  \ifx\htu@etitle\@empty\PackageError{htuthesis}{htuthesis ERROR: English title (\string\etitle) is empty (Story 4.2, deferred-work §3.2).}{Set the title via \string\etitle{...} in the preamble.}\fi
  \htu@setup@pdfinfo
  \phantomsection
  \pdfbookmark[-1]{\htu@ctitle}{ctitle}
  \normalsize%
  \begin{titlepage}
    \htu@first@titlepage
    \clearpage
    \htu@engcover
    % 声明页在后置部分渲染（main.tex \makedeclaration，spec §1.1 结尾部分末项；FR-14），
    %   不在前置 \makecover（Story 3.2 移除；Story 3.3 在后置恢复）。
    %   Story 3.14 (2026-06-19)：\htu@abstractcover「摘要封面」从 \makecover 删除（spec §1.1 line 5 无）；
    %     \clearpage（非 cleardoublepage）— spec §2.4 line 189 仅 2 个起始页须右页（绪论 + 中文摘要）。
  \end{titlepage}
  \normalsize
  \htu@makeabstract
  \let\@tabular\htu@tabular
}
\newcommand{\makedeclaration}{%原创性声明 + 授权说明（结尾部分末项，spec §1.1；FR-14 后置）
  \htu@authorization@mk}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 中英文摘要及关键词
%% 中文摘要部分的标题为"摘要"
%%   关键词之间空两个汉字符宽度，悬挂缩进
%% 英文摘要部分的标题为 Abstract，用 Arial 体三号字
%%   关键词之间空四个英文字符宽度，悬挂缩进
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\newcommand{\htu@@cabstract}[1]{\long\gdef\htu@cabstract{#1}}
\newenvironment{cabstract}{\Collect@Body\htu@@cabstract}{}
\newcommand{\htu@@eabstract}[1]{\long\gdef\htu@eabstract{#1}}
\newenvironment{eabstract}{\Collect@Body\htu@@eabstract}{}
\def\htu@parse@keywords#1{
  \define@key{htu}{#1}{\csname #1\endcsname{##1}}
  \expandafter\gdef\csname htu@#1\endcsname{}
  \expandafter\gdef\csname #1\endcsname##1{
    \@for\reserved@a:=##1\do{
      \expandafter\ifx\csname htu@#1\endcsname\@empty\else
        \expandafter\g@addto@macro\csname htu@#1\endcsname{%
          \ignorespaces\csname htu@#1@separator\endcsname}
      \fi
      \expandafter\expandafter\expandafter\g@addto@macro%
        \expandafter\csname htu@#1\expandafter\endcsname\expandafter{\reserved@a}}}}
\htu@parse@keywords{ckeywords}
\htu@parse@keywords{ekeywords}
\newbox\htu@kw
\newcommand\htu@put@keywords[2]{%
  \begingroup
    \setbox\htu@kw=\hbox{#1}
    \noindent\hangindent\wd\htu@kw\hangafter1%
    \box\htu@kw#2\par
  \endgroup}
\newcommand{\htu@makeabstract}{%
  \cleardoublepage
  \htu@chapter*[]{\cabstractname} % no tocline；中文标题 摘 要 = SimHei 三号（\sffamily CJK via 3.9）
  \pagestyle{htu@plain}
  \pagenumbering{Roman}
  \htu@cabstract
  \vskip\htu@abstract@keywordskip
  % 中文关键词标签 = 黑体（SimHei via 3.9 \setCJKsansfont）。\sffamily 仅限标签 \hbox，关键词仍宋体。
  %   Story 3.4 AC-3：原 \textbf 渲染为 SimSun（非黑体），改 \sffamily（RED-confirmed SimSun→SimHei）。
  \htu@put@keywords{\sffamily\htu@ckeywords@title}{\htu@ckeywords}
  % 英文标题：覆盖章节 \sffamily 格式（Latin→LMSans 缺口）使标题渲染为 TNR 加粗三号居中（Story 3.4 AC-4，
  %   闭合 Story 3.9 ATDD-3.9-16 的 1 个 LMSans span）。三号行距/居中由 chapter 格式提供。
  %   \texorpdfstring：文本态用 \rmfamily\bfseries（渲染 TNR Bold），PDF 书签/页眉标记态用空（洁净 ABSTRACT，
  %   避免 hyperref "Token not allowed in a PDF string"；Story 3.4 code-review patch）。
  \htu@chapter*[]{\texorpdfstring{\rmfamily\bfseries}{}\eabstractname} % no tocline
  % 英文摘要正文 + 关键词 scope：五号 TNR + 独立行距 ≈23.4bp（参考论文 page 6 Word "2倍行距"=2×自然行高，
  %   非 2×字号 21bp；Story 3.4 R-14/AC-5，透明偏离 architecture.md:151 的 21bp 假设，用户决策 2026-06-16）。
  %   显式 baselineskip + 锁 baselinestretch=1 防 ctex 1.2× 系数（R-3 陷阱）；不用拉伸类行距命令（architecture.md:84）。
  \begingroup
    \rmfamily
    \renewcommand{\baselinestretch}{1}% 先锁系数=1，再设字号（避免首个 \selectfont 以环境 \baselinestretch 瞬态算错；Story 3.4 code-review patch）
    \fontsize{10.5bp}{23.4bp}\selectfont
    % [基础] 英文摘要首行缩进 = 4 字符（spec §2.8 line 221「每段开头空 4 个字符」；Story 3.15 G2）。
    %   原继承正文 2\ccwd（≈2 字）；G2 显式设 4\ccwd（4 字，五号 \ccwd≈10.5pt → ≈42pt）。ATDD-3.15-I07 4-字区间 [24,44]。
    \setlength{\parindent}{4\ccwd}%
    \htu@eabstract
    \vskip\htu@abstract@keywordskip
    % 英文关键词标签加粗（spec §2.8 line 223「加粗」，Story 3.13 翻案 3.4 reference-wins 非加粗）；分隔符为半角逗号。
    \htu@put@keywords{\bfseries\htu@ekeywords@title}{\htu@ekeywords}%
  \endgroup
  \normalsize% R-3 leak guard：恢复正文 12pt/23.4bp，防 scope 泄漏到 \AtEndDocument 自检（Story 3.3 模式；3.11 重校准正文行距 18→23.4bp）
}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 主要符号对照表
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\newenvironment{denotation}[1][2.5cm]{
  \clearpage
  \htu@chapter*[]{\htu@denotation@name}
  \noindent\begin{list}{}%
    {\vskip-30bp\wuhao[1.524]%宋体五号(10.5磅)，行距16磅
     \renewcommand\makelabel[1]{##1\hfil}
     \setlength{\labelwidth}{#1}%标签盒子宽度
     \setlength{\labelsep}{0.5cm}%标签与列表文本距离
     \setlength{\itemindent}{0cm}%标签缩进量
     \setlength{\leftmargin}{\labelwidth+\labelsep}%左边界
     \setlength{\rightmargin}{0cm}
     \setlength{\parsep}{0cm}%段落间距
     \setlength{\itemsep}{0cm}%标签间距
    \setlength{\listparindent}{0cm}%段落缩进量
    \setlength{\topsep}{\z@}%标签与上文的间距
   }}{\end{list}}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 致谢
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\newenvironment{ack}{%
    \clearpage
    \htu@chapter*{\htu@ackname}
    % [基础] 致谢正文字体 = 小四号宋体（真值来源：spec §2.16 line 445「致谢内容一般用小四号宋体字」）。
    %   原上游模板用 \fangsong（仿宋小四）偏离 spec；参考 PDF 对致谢正文静默 → 按 Decision 4 spec 主导
    %   （用户决策 2026-06-16，Story 3.8 AC-2 Option A：\fangsong → \songti）。\xiaosi[1.524] = 小四固定行距 16 磅。
    \songti\xiaosi[1.524]%宋体小四，固定行距16磅
  }{}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%    参考文献环境（Story 3.12 Option A — biblatex GB/T 7714-2015，§2.14 case-2 双模式）
%% [基础] 真值来源（spec PRIORITY，CLAUDE.md Decision 4 修正 2026-06-17）：
%%   1. spec §2.14 line 291（case-2 PRIORITY）「引文参考文献已出现在文中的页下注（脚注），每页
%%      重新编号，需标注引文内容在原文献中的具体页码。文后参考文献可将引文参考文献和阅读型参考
%%      文献放在一起重新编号，先按照文献类型分类，每一类再按照作者姓氏字母顺序编号。」
%%   2. spec §1.2.4 line 109「若文中引文文献采用页下注（脚注）的形式，每页重新编号。」
%%   3. spec §2.4 line 197「脚注用小五号宋体字。」+ §2.14 line 285「参考文献的内容使用五号宋体字」
%%      + line 293「序号左顶格，悬挂缩进」（标准悬挂，biblatex gb7714-2015 默认已满足；Story 3.13 实测确认 [N] flush-left
%%        x0=70.9pt vs body-left-margin 64.4pt，delta=6.5pt 对齐 → 序号左顶格；无需 \bibhang 改动。ATDD I10 守卫）。
%%   机制（Zy 决策 2026-06-17 Option A）：natbib+bibtex 末端 [N] 上标（case-1）→ biblatex+biber
%%   +biblatex-gb7714-2015 双模式（case-2）。引文 → \footfullcite 每页脚注（完整 GB/T 7714 条目，
%%   小五号宋体；per-page reset 复用 \@addtoreset{footnote}{page} cls:369 Story 3.8）；文末表 →
%%   \makebibliography 按文献类型分节重组（§2.14 line 291 先按照文献类型分类）。
%%   参考 PDF（参考博士论文...pdf）p20-36（引文脚注：[N] author.title[TYPE].pub,year，每页
%%   重置，SimSun 9pt）+ p227（类型分节文末表：一、党的文献…每类 [1] 起）印证。
%%   Option B（natbib + footmisc + 手维护宏表）已拒绝（重复 .bib 漂移、违反成熟库优先规则）。
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% biblatex GB/T 7714-2015 文末表正文字体 = 五号宋体（Story 3.7 AC-2 §2.14 line 285）
\renewcommand*{\bibfont}{\wuhao[1.524]}%
% [基础] htu-refs（主标题+子标题）——Story 5.1（2026-06-23）后不再挂任何分节：入口 \htu@chapter*{\bibname}
%   已独立 emit 主标题（见 \makebibliography）。定义保留供溯源；如需清理可删（htu-refs-sub 已覆盖全部分节）。
\defbibheading{htu-refs}[1]{\htu@chapter*{\bibname}\par\vspace{0.6\baselineskip}{\xiaosi\sffamily\htu@tnr\centerline{#1}}\par\vspace{0.3\baselineskip}}%
% [基础] 文末表类型分节子标题：一、期刊论文 … 六、电子资源（§2.14 line 291 按文献类型分类）。
%   Story 5.1 Change 1（sprint-change-proposal-2026-06-23）：宋体小四【左对齐】——参考论文 p228-249 实测
%   font=SimSun size=12.0 x0=114/595（非居中）；spec §2.14 对分节标题格式沉默 → 参考 PDF 辅助 → 原
%   \sffamily(SimHei)+\centerline(居中) 是偏离。改 \songti(SimSun) + 去 \centerline(左对齐)。保留
%   \htu@tnr Latin 守卫（F2 结构性，Epic 4 retro；分节标题为 CJK 无实时 Latin 泄漏，守卫作结构性保留）。
%   Epic 5 复盘修复（2026-06-24，Zy 裁决；spec §2.14 对分节标题格式沉默→允许）：
%   (a) 加粗：\songti→\htu@songtibold\bfseries（cls:98-101 SimSun+AutoFakeBold=2.5 算法粗宋；字体名仍
%       SimSun，不退化成 SimHei，区别于 ctex 默认 CJK 粗体映射；复用四级标题 cls:546 已验机制）。原因：
%       宋体 12pt 标题 vs 宋体 10.5pt 条目同族仅差字号、无层级区分度（Zy 目视）；加粗增区分度且保留宋体字面。
%   (b) \noindent 顶格：原继承正文 \parindent 2 字缩进（实测 x0=94.9）偏离参考 flush-left（x0=114≈条目 111）。
%   (c) 标题后 \vspace{0.3\baselineskip}→-0.2：标题→首条目实测 37→25.2pt 对齐参考 24.1pt
%       （Story 5.1 Change 1 原 AC 漏检间距维度——"渲染存在≠正确形态"）。
%   fitz 实证（4 维）：font=SimSun(非 SimHei) + 粗体墨度比 1.59-1.77(同文 regular 对照,>1.3,L4=1.48) + x0=70.9(原 94.9) + 标题→首条目 25.2pt(原 37,参考 24.1)。
\defbibheading{htu-refs-sub}[1]{\par\vspace{0.6\baselineskip}{\noindent\xiaosi\htu@songtibold\bfseries\htu@tnr #1}\par\vspace{-0.2\baselineskip}}%
% [基础] 文末表：按文献类型分节重组（引文 + 阅读型，§2.14 case-2 line 291）。
%   Story 5.1（2026-06-23，NFR-6）：入口无条件 emit \htu@chapter*{\bibname}——章标题独立于分节数据分布。
%   Story 3.12 曾将主标题 heading（htu-refs）只挂 type=article 分节；真实 refs.bib 无 @article 时该节空
%   → biblatex 跳过空节 heading → "参考文献"章蒸发 + 不入目录（FR-20/NFR-6 违反，Story 3.12 盲点）。
%   7 个 \printbibliography 全部改用 htu-refs-sub（仅子标题）。见 architecture.md §参考文献章标题与分节数据分布解耦。
%   R-34（空节警告 gate）：外层 \begingroup 静默 \blx@warn@bibempty——任何分布（含真实稀疏 bib，如仅
%   @online → 5 个具名分节空）都不超 NFR-1 ≤3 警告门。空节仍不渲染（行为不变，仅去警告）。
\BiblatexSplitbibDefernumbersWarningOff
\newcommand{\makebibliography}{%
  \nocite{*}% 收录全部参考文献（引文 + 阅读型，§2.14 line 291）
  % [基础] 参考文献 章标题入口（Story 5.1 解耦，NFR-6）：\htu@chapter*{\bibname} 无条件 emit
  %   章标题（三号黑体居中 + \clearpage + \addcontentsline{toc}）——独立于下述 7 个分节的空/非空。
  \htu@chapter*{\bibname}%
  \begingroup
    % R-34：静默 biblatex 空节 "Empty bibliography" 警告（\blx@warn@bibempty，biblatex.sty）——真实稀疏
    %   refs.bib（如仅 @online → 5 具名分节空）不再触发 NFR-1 ≤3 警告门。空节仍不渲染（行为不变）。
    \def\blx@warn@bibempty{}%
    \printbibliography[type=article,heading=htu-refs-sub,title={一、期刊论文},resetnumbers=true]%
    \printbibliography[type=book,heading=htu-refs-sub,title={二、著作},resetnumbers=true]%
    \printbibliography[type=incollection,heading=htu-refs-sub,title={三、论文集（章节）},resetnumbers=true]%
    \printbibliography[type=thesis,heading=htu-refs-sub,title={四、学位论文},resetnumbers=true]%
    \printbibliography[type=patent,heading=htu-refs-sub,title={五、专利},resetnumbers=true]%
    \printbibliography[type=online,heading=htu-refs-sub,title={六、电子资源},resetnumbers=true]%
    % 七、其他 catch-all（code review 2026-06-17 决策 a）：未映射到前 6 类的条目（@report/@manual/
    %   @misc/@unpublished/@software 等，biblatex 别名→@misc）。\htu@printbibother 内含自身空节静默。
    \htu@printbibother{七、其他}%
  \endgroup
}%
% \htu@printbibother{<title>} — guarded catch-all（code review 2026-06-17 F2 决策 a）。本地静默 biblatex 空节
%   警告 \blx@warn@bibempty（biblatex.sty:1511），再无条件 \printbibliography：空时节头不渲染、无输出、
%   无警告；非空时正常打印 七、其他。比 \ifboolexpr{citecount}（用户态不可读 biber 计数）简单且稳健。
\newcommand{\htu@printbibother}[1]{%
  \begingroup
    % 静默 biblatex 空节 "Empty bibliography" 警告（仅此组，仅当七、其他 实际为空时触发）
    \def\blx@warn@bibempty{}%
    \printbibliography[nottype=article,nottype=book,nottype=incollection,nottype=thesis,nottype=patent,nottype=online,heading=htu-refs-sub,title={#1}]%
  \endgroup
}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 附录
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\let\htu@appendix\appendix
\renewenvironment{appendix}{%
  \htu@appendix
  \gdef\@chapapp{\appendixname~\thechapter}%
  % [基础] 附录章节 aftername + 居中本地恢复（Story 3.13 code review 2026-06-19 决策 a，§2.15 line 437）：
  %   全局 chapter aftername={}（cls:458）服从 §2.10 正文「不空格」，但 §2.15 要求附录「序号和标题间空半格」。
  %   \appendix 后（其后无正文章）本地覆盖 aftername=半字距 + 防御性重申居中（不依赖 \backmatter format+= 持久）。
  %   Story 4.1 接入 main.tex \appendix 渲染验证：TC-E4-02 (G5a 正文小四宋体) + TC-E4-03 (G5b 图A-1 counter)。
  \ctexset{chapter/aftername=\hspace{0.5\ccwd}}%
  \ctexset{chapter/format+=\centering}%
  % [基础] 附录正文字体 = 小四号宋体（spec §2.15 line 439「附录内容一般用小四号宋体字」；Story 3.15 G5a）。
  %   原依赖隐式 \normalsize；G5a 显式 \xiaosi\songti。Story 4.1 接入 main.tex \appendix → 首次渲染验证 TC-E4-02。
  \xiaosi\songti%
  % 附录编号沿用全局定义：\appendix 令 \thechapter 为字母（A、B…），
  % 故 \thefigure/\thetable/\theequation 自动呈 A-1 形式（HTU §2.11/§2.12/§2.13）。
  %
  % [基础] 字体恢复策略（Story 4.1 R-23 mitigation #1；deferred-work §3.15 字体泄漏）：
  %   \renewenvironment{appendix} 使 \appendix 命令形（main.tex 用 \appendix，非 \begin{appendix}）——BEGIN 子句
  %   \xiaosi\songti 生效，END 子句 {} 在命令形下【永不触发】（仅 \end{appendix} 才执行）。故 G5a 字体恢复不能依赖 END。
  %   下游后置 env 各自 entry 自重置字体：ack (cls \songti\xiaosi[1.524])、resume (\wuhao[1.524])、
  %   \makedeclaration (\xiaosi[1.6]) ——附录 \xiaosi\songti 不泄漏进致谢/简历/声明（TC-E4-08 fitz 渲染验证）。
  %   不改用 \begin{appendix}...\end{appendix} env 形：\include 跨文件 + 环境作用域组合脆弱。命令形 + 下游自重置 = 稳健。
  }{}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 个人简历、在学期间发表的学术论文及研究成果
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\newenvironment{resume}[1][\htu@resume@title]{%
  \htu@chapter*{#1}\wuhao[1.524]}{}
\newcommand{\resumeitem}[1]{\vspace{2em}{\sihao\sffamily\htu@tnr{#1}}\vspace{.5em}\par}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Self-Check Infrastructure (Story 2.2)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\newcounter{htu@totalpages}
\AddToHook{shipout/after}{\stepcounter{htu@totalpages}}
\newcommand{\htucheck}{%
  \typeout{=== HTU Layout Self-Check ===}%
  %% --- dimension report (these 8 lines + markers are IMMUTABLE — Epic 2-3 ATDD greps + Story 4.4 ---
  %%     checklist depend on the 'name = value' prefix; Story 4.2 appends verdict/sections only, AC-8)
  \typeout{textheight = \the\textheight}%
  \typeout{textwidth = \the\textwidth}%
  \typeout{baselineskip = \the\baselineskip}%
  \typeout{headheight = \the\headheight}%
  \typeout{evensidemargin = \the\evensidemargin}%
  \typeout{oddsidemargin = \the\oddsidemargin}%
  \typeout{total pages = \the\numexpr\c@htu@totalpages+1\relax}%
  \typeout{page counter = \the\c@page}%
  %% --- WARNING tier (non-fatal, \PackageWarning; architecture §345-353) ---
  %%     margin deviation >1mm or baselineskip drift >0.5bp → log + continue (exit 0, pdf built).
  %%     ERROR tier (font missing) handled by cls:71-88 gates + the font-block defense-in-depth below.
  \ifdim\textheight>\dimexpr\htu@base@textheight+1mm\relax
    \PackageWarning{htuthesis}{WARNING: textheight = \the\textheight\space (expected \htu@base@textheight, drift > 1mm)}%
  \else\ifdim\textheight<\dimexpr\htu@base@textheight-1mm\relax
    \PackageWarning{htuthesis}{WARNING: textheight = \the\textheight\space (expected \htu@base@textheight, drift > 1mm)}%
  \fi\fi
  \ifdim\textwidth>\dimexpr\htu@base@textwidth+1mm\relax
    \PackageWarning{htuthesis}{WARNING: textwidth = \the\textwidth\space (expected \htu@base@textwidth, drift > 1mm)}%
  \else\ifdim\textwidth<\dimexpr\htu@base@textwidth-1mm\relax
    \PackageWarning{htuthesis}{WARNING: textwidth = \the\textwidth\space (expected \htu@base@textwidth, drift > 1mm)}%
  \fi\fi
  \ifdim\baselineskip>\dimexpr\htu@base@baselineskip+0.5bp\relax
    \PackageWarning{htuthesis}{WARNING: baselineskip = \the\baselineskip\space (expected approx \htu@base@baselineskip, drift > 0.5bp)}%
  \else\ifdim\baselineskip<\dimexpr\htu@base@baselineskip-0.5bp\relax
    \PackageWarning{htuthesis}{WARNING: baselineskip = \the\baselineskip\space (expected approx \htu@base@baselineskip, drift > 0.5bp)}%
  \fi\fi
  \ifnum\c@htu@totalpages<1 \PackageWarning{htuthesis}{WARNING: total pages = 0 (no pages shipped -- possible compile anomaly)}\fi
  %% --- font check (defense-in-depth; cls:71-88 gates already halt on missing font, so all 5 are ---
  %%     found here on a correct compile. A 'missing' line means the earlier gate failed silently ---
  %%     = R-24 residual concern caught -> \PackageError halt. NFR-2.)
  \typeout{--- font check ---}%
  \IfFontExistsTF{SimSun}{\typeout{SimSun: found [PASS]}}{\typeout{SimSun: missing [ERROR]}\PackageError{htuthesis}{htuthesis ERROR: self-check font SimSun missing (cls:71 gate should have halted earlier -- R-24 residual)}{}}%
  \IfFontExistsTF{SimHei}{\typeout{SimHei: found [PASS]}}{\typeout{SimHei: missing [ERROR]}\PackageError{htuthesis}{htuthesis ERROR: self-check font SimHei missing}{}}%
  \IfFontExistsTF{KaiTi}{\typeout{KaiTi: found [PASS]}}{\typeout{KaiTi: missing [ERROR]}\PackageError{htuthesis}{htuthesis ERROR: self-check font KaiTi missing}{}}%
  \IfFontExistsTF{FangSong}{\typeout{FangSong: found [PASS]}}{\typeout{FangSong: missing [ERROR]}\PackageError{htuthesis}{htuthesis ERROR: self-check font FangSong missing}{}}%
  \IfFontExistsTF{Times New Roman}{\typeout{Times New Roman: found [PASS]}}{\typeout{Times New Roman: missing [ERROR]}\PackageError{htuthesis}{htuthesis ERROR: self-check font Times New Roman missing}{}}%
  %% --- 14 silent-failure coverage map (architecture §155-174; NFR-4) ---
  %%     ASSERTED = compile-time-observable (\the<dim>/.aux/.log). rendered = fitz ATDD owns it ---
  %%     (wrong-target-AC discipline, Epic 3 retro Lesson 3 / R-25: self-check does NOT assert a ---
  %%     rendered property via a \the<dim> proxy; it maps it to the fitz ATDD that probes the span).
  \typeout{--- silent-failure coverage map (14 + §480 pointer = 15 lines) ---}%
  \typeout{[01] body baselineskip ~23bp (Word 1.5x): ASSERTED (WARNING above if drift > 0.5bp)}%
  \typeout{[02] EN-abstract baselineskip 23.4bp: PROXIED -- rendered guard ATDD-3.4-I06 / ATDD-3.11-I07}%
  \typeout{[03] counter separators '-' not '.': ASSERTED via .aux scan (ATDD-2.6 unit)}%
  \typeout{[04] even-page rightmark/leftmark: rendered -- ATDD-2.3}%
  \typeout{[05] fancyhdr header-truncation (head-room): ASSERTED via .log overflow-grep (ATDD-2.2)}%
  \typeout{[06] blank-page header/number residue: rendered -- ATDD-2.4-25 / ATDD-3.14}%
  \typeout{[07] makecaption CN/EN switch: rendered -- ATDD-3.6}%
  \typeout{[08] TOC dot-leader width overflow: rendered -- ATDD-3.5-I09}%
  \typeout{[09] spine page-number position: rendered -- ATDD-2.4}%
  \typeout{[10] TOC dot-leader + pagenum align: rendered -- ATDD-3.5-I09}%
  \typeout{[11] references style detail: ASSERTED via .bbl scan (ATDD-3.7 / ATDD-3.12)}%
  \typeout{[12] PDF bookmark hierarchy: rendered -- manual epic-gate}%
  \typeout{[13] TOC L1 number-prefix font SimHei (G1): rendered -- ATDD-3.15-G1}%
  \typeout{[14] heading/TOC Latin TNR not LMSans (G6): rendered -- ATDD-3.15-G6}%
  \typeout{[15] evensidemargin-twoside configuration (architecture §480 enhanced check): rendered -- ATDD-2.4 (outer-side page-number/margin position); no compile-time proxy (§480 'unset/default' undetectable post-geometry; HTU symmetric margins make even==odd the correct state; a dim-proxy self-check would violate R-25 wrong-target-AC)}%
  %% --- assertion audit (wrong-target-AC, Epic 3 retro action #3, R-25) ---
  %%     flags which self-check assertions are PROXIED (internal dim for a rendered property) so a ---
  %%     reviewer knows a green self-check is NOT spec-compliance evidence for those properties.
  %%     (Avoid the literal '!=' / '!' in \typeout text -- a wrapped log line starting with '!' ---
  %%     falsely trips the standard '^!' TeX-error grep; Story 4.2 I01 regression-guard.)
  \typeout{--- assertion audit ---}%
  \typeout{PROXIED: [01] baselineskip-for-spacing, [02] EN-abstract baselineskip (scope not isolated here)}%
  \typeout{RENDERED-DIRECT evidence lives in the fitz ATDDs cited above}%
  \typeout{(a green self-check is NOT spec-compliance evidence for the proxied properties)}%
  %% --- debug diagnostics (Story 4.3；\ifhtu@debug gated；AC-1/2；ADD-only — the 4.2 sections above stay always-on, AC-8) ---
  %%     REPORTS dims (does NOT assert them as spec-compliance evidence — R-25 wrong-target-AC: a green self-check
  %%     is NOT spec compliance for rendered properties; this section is a diagnostic DUMP for developers, verdict
  %%     logic stays in the WARNING/ERROR tiers above). Names the NFR-5 watch-list so a developer running [debug]
  %%     knows what `make debug-check` enforces (6 LaTeX warnings treated as errors during development, NFR-5).
  %%     (Watch-list phrases use the natural warning text — safe because this block prints ONLY under [doctor,debug],
  %%     never on the default compile that the Epic 2-3 headheight/overfull greps scan.)
  \ifhtu@debug
    \typeout{--- debug diagnostics ---}%
    \typeout{[debug] htuthesis verbose self-check active (documentclass debug option)}%
    \typeout{[debug] textheight actual=\the\textheight\space baseline=\htu@base@textheight}%
    \typeout{[debug] textwidth actual=\the\textwidth\space baseline=\htu@base@textwidth}%
    \typeout{[debug] baselineskip actual=\the\baselineskip\space baseline=\htu@base@baselineskip}%
    \typeout{[debug] headheight actual=\the\headheight\space headsep=\the\headsep\space footskip=\the\footskip}%
    \typeout{[debug] evensidemargin=\the\evensidemargin\space oddsidemargin=\the\oddsidemargin\space (twoside symmetric)}%
    \typeout{--- NFR-5 warning-as-error watch list (Makefile debug-check enforces these) ---}%
    %% NFR-5 watch-list literal signatures — source-of-truth (ATDD-4.3-07 source-grep + Makefile debug-check grep
    %%   both anchor here). Bare \hbox is safe in a comment (not executed); the \typeout lines below use \string\hbox
    %%   to print the same signature to the debug .log for developer UX, and Makefile debug-check grep -v excludes
    %%   these watch-list lines so the checker does not self-trip on its own documentation.
    %%   Signatures: Overfull \hbox | geometry Over-specification | fancyhdr headheight too low | natbib undefined Citation | hyperref Token not allowed in PDF string | caption option reset
    \typeout{[1] Overfull \string\hbox — content wider than textwidth}%
    \typeout{[2] geometry Over-specification (Package geometry) — redundant margin dims}%
    \typeout{[3] fancyhdr headheight too low (Package fancyhdr) — header truncation risk}%
    \typeout{[4] natbib/biblatex undefined Citation — missing .bbl entry}%
    \typeout{[5] hyperref Token not allowed in PDF string — bookmark glyph issue}%
    \typeout{[6] caption option reset (Package caption) — labelsep override lost}%
  \fi
  \typeout{=== End Self-Check ===}%
}
\AtEndDocument{%
  \htucheck
}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 延迟的代码 (Delaying code)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\AtEndOfClass{\sloppy}
\endinput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% End of file `htuthesis.cls'.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%