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
\DeclareOption{doctor}{\htu@doctortrue}
\DeclareOption{bachelor}{\ClassError{htuthesis}{bachelor option removed: this template now only supports doctoral theses}{}}
\DeclareOption{master}{\ClassError{htuthesis}{master option removed: this template now only supports doctoral theses}{}}
\DeclareOption{openright}{\htu@openrighttrue}
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
%   实测确认（AC-5 三源之一）：参考论文 2107084001-任子辛 page 1-14 Latin 主字体 = TimesNewRomanPSMT。
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
\RequirePackage{geometry}%页边距设置
\RequirePackage{fancyhdr}%页眉页脚管理
\RequirePackage{tabularx}%表格宽度控制
\RequirePackage{multirow}%跨行表格
\RequirePackage{longtable}%长表格，可替换supertabular
\RequirePackage{booktabs}%三线表格
\RequirePackage[labelformat=simple]{subcaption}% subcaption with labelformat=simple
\RequirePackage{graphicx}%图形支持
\RequirePackage[numbers,super,sort&compress]{natbib}% natbib with numbers,super,sort&compress
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
  \cleardoublepage
  \ctexset{chapter/format+=\centering}
  \@mainmatterfalse
  \pagenumbering{Roman}
  \pagestyle{htu@plain}}
\renewcommand\mainmatter{%
  \cleardoublepage
  \ctexset{chapter/format+=\centering}
  \@mainmattertrue
  \pagenumbering{arabic}%
  \pagestyle{htu@headings}}
\renewcommand\backmatter{%
  \cleardoublepage
  \ctexset{chapter/format+=\centering}
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
  \def\htu@major@title{专业名称}% 保留（inert；学科、专业 字段值 = \csubject+\cmajor 合并）
\def\htu@cdate@title{完成时间}% 保留（inert；日期已移至字段下方居中，见 \htu@first@titlepage）
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
\newcommand{\eabstractname}{Abstract}
\def\htu@ckeywords@separator{；}
\def\htu@ekeywords@separator{; }
\newcommand{\htu@ckeywords@title}{关键词：}
% [基础] 英文关键词标签：冒号为半角 ":"（U+003A)。真值源 = 参考论文 PDF
%   (2107084001-任子辛-政治与公共管理学院.pdf) page 9 "KEY WORDS:Digitalization..."；
%   按真值源层次（参考论文 > spec §2.8 全角"："），半角胜出（PRD decision-log D-14）。
\newcommand{\htu@ekeywords@title}{KEY WORDS:\enskip}
\newcommand{\htu@denotation@name}{主要符号对照表}
\newcommand{\htu@ackname}{致\hspace{\ccwd} 谢}
  \newcommand{\htu@resume@title}{个人简历、在学期间发表的学术论文与研究成果}
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
%% 博士：小四号 (12bp) 字，固定行距 20bp
%% Word 小四号字 1.25 倍行距与固定行距 20bp 较接近
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
\DeclareCaptionLabelSeparator{htu}{\hspace{\ccwd}}%图表序与图表名之间空一个汉字
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
  {\sffamily}%Theorem head font
  {\htu@theorem@separator}%Punctuation after theorem head
  {1em}%Space after theorem head
  {}%Theorem head spec
\renewenvironment{proof}[1][\proofname]{\par%证明
  \pushQED{\qed}%
  \normalfont \topsep6\p@\@plus6\p@\relax
  \trivlist
  \item[\hskip\labelsep
  \sffamily
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
\ctexset{%
  chapter={%一级标题：黑体三号(16bp)，居中，段前段后2行(36bp)（HTU §2.10）
    afterindent=true,
    pagestyle={htu@headings},
    beforeskip=\htu@chapter@beforeskip,
    aftername=\hskip\ccwd,
    afterskip=\htu@chapter@afterskip,
    format={\sffamily\sanhao[\htu@chapter@linespread]},
    name=\relax,
    nameformat=\relax,
    titleformat=\relax,
    lofskip=0pt,
    lotskip=0pt,
  },
  section={%二级标题：黑体小三号(15bp)，居中，段前段后0.5行(9bp)（HTU §2.10）
    afterindent=true,
    beforeskip={\htu@section@beforeskip \@plus .5ex \@minus .2ex},
    afterskip={\htu@section@afterskip \@plus .2ex},
    format={\sffamily\xiaosan[\htu@section@linespread]\centering},
  },
  subsection={%三级标题：黑体四号(14bp)，居左空两格，段前段后0.5行(9bp)（HTU §2.10）
    afterindent=true,
    indent=2\ccwd,
    beforeskip={\htu@subsection@beforeskip \@plus .5ex \@minus .2ex},
    afterskip={\htu@subsection@afterskip \@plus .2ex},
    format={\sffamily\sihao[\htu@subsection@linespread]},
  },
  subsubsection={%四级标题：宋体小四号(12bp)加粗，居左空两格，段前段后0.5行(9bp)（HTU §2.10；段前段后为推断值）
    afterindent=true,
    indent=2\ccwd,
    beforeskip={\htu@subsubsection@beforeskip \@plus .5ex \@minus .2ex},
    afterskip={\htu@subsubsection@afterskip \@plus .2ex},
    format={\htu@songtibold\bfseries\xiaosi[\htu@subsubsection@linespread]},
  },
  paragraph/afterindent=true,
  subparagraph/afterindent=true}
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
  \cleardoublepage\phantomsection%
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
%% 各章目录：宋体14磅，单倍行距，段前6磅，段后0磅
%%           两端对齐，页码右对齐
%% 一级标题：宋体12磅，单倍行距，段前6磅，段后0磅
%%           左缩进2字符，两端对齐，页码右对齐
%% 二级标题：宋体10.5磅，单倍行距，段前6磅，段后0磅
%%           左缩进4字符，两端对齐，页码右对齐
%% 图和附表清单：宋体10.5磅，行距16磅
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
\titlecontents{chapter}[\z@]{\vspace{6bp}\sihao[1]}
  {{\thecontentslabel}\quad}{}
  {\hspace{.5em}\titlerule*{.}\xiaosi\contentspage}
\titlecontents{section}[2\ccwd]{\vspace{6bp} \xiaosi[1]}
  {\thecontentslabel\quad}{}
  {\hspace{.5em}\titlerule*{.}\xiaosi\contentspage}
\titlecontents{subsection}[4\ccwd]{\vspace{6bp} \wuhao[1]}
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
  \cdate{\CJK@todaysmall@short}%
\edate{\ifcase \month \or January\or February\or March\or April\or May%
       \or June\or July \or August\or September\or October\or November
       \or December\fi\unskip,\ \ \the\year}
\newcommand\htu@underline[2][6em]{%
  \hskip\p@\underline{\hb@xt@ #1{\hss#2\hss}}\hskip3\p@}
\newlength{\htu@title@width}
\def\htu@put@title#1{\makebox{\hb@xt@\htu@title@width{#1}}}
\newcommand{\htu@first@titlepage}{%论文中文封面（博士学位论文封面）
  \thispagestyle{htu@empty}%
  % [基础] 封面布局：TikZ remember-picture overlay 绝对定位（mm 坐标，原点=current page 节点）。
  %   真值来源（三源三角，CLAUDE.md Decision 4）：
  %     1) 参考论文 2107084001-任子辛-政治与公共管理学院.pdf page 2（已完成 HTU 博士封面，视觉真值）
  %     2) .doc 空白模板「博士学位论文封面（电子版用）」（官方下载，权威空白形式）
  %     3) 本 [基础] 注释（实现层映射）
  %   字体（双源一致）：元数据=仿宋12pt；校名=书法体图像91mm×27.3mm；「博士学位论文」=宋体45pt；
  %                    论文题目=黑体小二(18pt)；五字段=黑体小三(15pt)；日期=黑体小三(15pt)。
  %   日期格式=阿拉伯数字+年/月（.doc 空白模板 + 参考论文双源确认；spec §1.1.1「二〇二四年五月」为理想化文本，
  %     按 Word 模板 > spec 的真值源层次，阿拉伯胜出——Decision 4 透明偏离）。
  %   R-9（score 6）：9 个元素绝对定位，±3mm 容差；R-6（score 6）：绝对定位相对纸张（非 \textwidth），
  %     消除 includeheadfoot 后 textwidth 146→160mm 变化对封面的耦合（Story 2.1 deferred 债）。
  \begin{tikzpicture}[remember picture, overlay]
    % --- 元数据（左上 x≈23mm，仿宋小四≈12pt）：单位代码 / 学号 / 分类号 ---
    %   \htu@fangsong@latin：ASCII 数字/字母也走 FangSong（匹配参考论文 page 2 span 级字体）
    \node[anchor=north west, inner sep=0pt]
      at ($(current page.north west) + (23.3mm, -22.8mm)$)
      {\fangsong\htu@fangsong@latin\xiaosi\htu@schoolcode@title\hspace{1em}%
       \htu@underline[25mm]{\htu@schoolcode}};
    \node[anchor=north west, inner sep=0pt]
      at ($(current page.north west) + (23.3mm, -31.9mm)$)
      {\fangsong\htu@fangsong@latin\xiaosi\htu@id@title\hspace{1em}%
       \htu@underline[25mm]{\htu@id}};
    \node[anchor=north west, inner sep=0pt]
      at ($(current page.north west) + (23.3mm, -40.8mm)$)
      {\fangsong\htu@fangsong@latin\xiaosi\htu@secretlevel@title\hspace{1em}%
       \htu@underline[25mm]{\htu@secretlevel}};
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
      {\sffamily\xiaoer[1.5]\htu@ctitle};
    % --- 五字段（黑体小三15pt，左 x=60mm，label：value 格式）---
    \node[anchor=north west, inner sep=0pt]
      at ($(current page.north west) + (60.3mm, -191.9mm)$)
      {\sffamily\xiaosan\htu@subject@title\htu@title@sep\htu@csubject\htu@cmajor};
    \node[anchor=north west, inner sep=0pt]
      at ($(current page.north west) + (60.3mm, -200.1mm)$)
      {\sffamily\xiaosan\htu@researchdirection@title\htu@title@sep\htu@researchdirection};
    \node[anchor=north west, inner sep=0pt]
      at ($(current page.north west) + (60.3mm, -208.2mm)$)
      {\sffamily\xiaosan\htu@degreecategory@title\htu@title@sep\htu@degreecategory};
    \node[anchor=north west, inner sep=0pt]
      at ($(current page.north west) + (60.3mm, -216.3mm)$)
      {\sffamily\xiaosan\htu@author@title\htu@title@sep\htu@cauthor};
    \node[anchor=north west, inner sep=0pt]
      at ($(current page.north west) + (60.3mm, -224.4mm)$)
      {\sffamily\xiaosan\htu@supervisor@title\htu@title@sep\htu@csupervisor};
    % --- 完成日期（黑体小三15pt，居中，y=247.7mm；阿拉伯数字+年/月）---
    %   \htu@heiti@latin：ASCII 数字也走 SimHei（匹配参考论文 page 2 日期全 SimHei run）
    \node[anchor=north, inner sep=0pt]
      at ($(current page.north) + (0mm, -247.7mm)$)
      {\sffamily\htu@heiti@latin\xiaosan\htu@cdate};
  \end{tikzpicture}%
  \null% 确保仅含 overlay 的 titlepage 页正常 shipout（overlay 零尺寸，\null 提供可输出内容）
} % end of titlepage
\newcommand{\htu@engcover}{%博士论文英文封面
  \thispagestyle{htu@empty}
  \vspace*{1cm}
  \begin{center}
    \parbox[t][5.8cm][t]{\paperwidth-7.2cm}{
      \renewcommand{\baselinestretch}{1.5}
        \begin{center}
          \sanhao A dissertation submitted to\\
          {\bfseries \htu@schoolname@en}\\
          for the degree of Doctor\\
        \end{center}}
    \vskip \stretch{1}
    \parbox[t][5.2cm][t]{\paperwidth-7.2cm}{
      \renewcommand{\baselinestretch}{1.5}
      \begin{center}
        \sanhao\bfseries\htu@etitle
      \end{center}}
    \vskip \stretch{2}
    \parbox[t][3.6cm][b]{\paperwidth-7.2cm}{
      \renewcommand{\baselinestretch}{1.5}
      \begin{center}
        \sanhao
        By\quad{}\htu@eauthor\par
        Supervisor :\quad\htu@esupervisor\par
        \htu@emajor\par
        \htu@edepartment\par
        \htu@edate
      \end{center}}
  \vfill
  \end{center}}
\newcommand{\htu@declarename}{学位论文原创性声明}
\newcommand{\htu@authtitle}{学位论文使用授权声明}
\newcommand{\htu@authorsig}{学位论文作者：}
\newcommand{\htu@declaretext}{\hspace{2\ccwd}
本人郑重声明：所呈交的学位论文，是本人在导师的指导下，独立进行研究所取得的成果
。除文中已经注明引用的内容外，本论文不包含任何其他个人或集体已经发表或撰写过的
科研成果。对本文的研究做出重要贡献的个人和集体，均已在文中以明确方式标明。本声
明的法律责任由本人承担。}
\newcommand{\htu@declaredate}{日\hspace{\ccwd} 期：\hspace{4\ccwd} 年\hspace{2\ccwd} 月\hspace{2\ccwd} 日}
\newcommand{\htu@authorization}{\hspace{2\ccwd}
本人在导师指导下完成的论文及相关的职务作品，知识产权归属\htu@schoolname。根据\htu@schoolname
有关保留、使用学位论文的规定，同意学校保留或向国家有关部门或机构送交论文的复印
件和电子版，允许论文被查阅和借阅；本人授权\htu@schoolname 可以将本学位论文的全部或部分
编入有关数据库进行检索，可以采用影印、缩印或其他复制手段保存论文和汇编本学位论
文。本人离校后发表、使用学位论文或与该学位论文直接相关的学术论文或成果时，第一
署名单位仍然为\htu@schoolname。保密论文在解密后应遵守此规定。}
\newcommand{\htu@authdate}{日\hspace{\ccwd} 期：\hspace{4\ccwd} 年\hspace{2\ccwd} 月\hspace{2\ccwd} 日}
\newcommand{\htu@authorization@mk}{%原创性声明及授权声明
  \thispagestyle{htu@empty}
  \vspace*{\stretch{1}}
  \begin{center}
    \sffamily\sanhao \htu@declarename
  \end{center}
  \vskip 20pt
  \xiaosi[2]\htu@declaretext
  \vskip 20pt
  \htu@authorsig\hfill\htu@declaredate\hspace*{2\ccwd}
  \vspace*{\stretch{2}}
  \begin{center}
    \sffamily\sanhao \htu@authtitle
  \end{center}
  \vskip 20pt
  \xiaosi[2]\htu@authorization
  \vskip 20pt
  \htu@authorsig\hfill\htu@authdate\hspace*{2\ccwd}
  \vspace*{\stretch{2}}}
\def\htu@setup@pdfinfo{%pdf文档信息
  \hypersetup{%
    pdftitle={\htu@ctitle},
    pdfauthor={\htu@cauthor},
    pdfsubject={\htu@schoolname\htu@subtitle},
    pdfkeywords={\htu@ckeywords},
    pdfcreator={\htuthesis-v\version}}}
\newcommand{\makecover}{%制作封面
  \htu@setup@pdfinfo
  \phantomsection
  \pdfbookmark[-1]{\htu@ctitle}{ctitle}
  \normalsize%
  \begin{titlepage}
    \htu@first@titlepage
    \cleardoublepage
    \htu@engcover
    \cleardoublepage
    \htu@authorization@mk
  \end{titlepage}
  \normalsize
  \htu@makeabstract
  \let\@tabular\htu@tabular
}
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
  \htu@chapter*[]{\cabstractname} % no tocline
  \pagestyle{htu@plain}
  \pagenumbering{Roman}
  \htu@cabstract
  \vskip\htu@abstract@keywordskip
  \htu@put@keywords{\textbf\htu@ckeywords@title}{\htu@ckeywords}
  \htu@chapter*[]{\eabstractname} % no tocline
  \htu@eabstract
  \vskip\htu@abstract@keywordskip
  \htu@put@keywords{%
    \textbf\htu@ekeywords@title}{\htu@ekeywords}%
}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 主要符号对照表
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\newenvironment{denotation}[1][2.5cm]{
  \cleardoublepage
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
    \cleardoublepage
    \htu@chapter*{\htu@ackname}
    \fangsong\xiaosi[1.524]%仿宋五号，固定行距16磅
  }{}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%    参考文献环境
%% 1. 文献作者不超过3位时，全部列出；超过时只列前3位，后面加“等”或相应外文；
%% 2. 作者姓名之间用“,”分开，建议根据《中国高校自然科学学报编排规范》的要求
%%    书写参考文献，并按引用顺序将其附于文末，该规范建议根据国标书写参考文献。
%% 3. 引用参考文献的位置，上标标注[参考文献序号]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\bibpunct{[}{]}{,}{s}{}{,}
\renewcommand\NAT@citesuper[3]{\ifNAT@swa%
  \unskip\kern\p@\textsuperscript{\NAT@@open #1\NAT@@close}%
  \if*#3*\else\ (#3)\fi\else #1\fi\endgroup}
\DeclareRobustCommand\onlinecite{\@onlinecite}
\def\@onlinecite#1{\begingroup\let\@cite\NAT@citenum\citep{#1}\endgroup}
\renewenvironment{thebibliography}[1]{%
   \htu@chapter*{\bibname}%
   \wuhao[1.524]%宋体五号，行距16磅
   \list{\@biblabel{\@arabic\c@enumiv}}%
        {\renewcommand{\makelabel}[1]{##1\hfill}
         \settowidth\labelwidth{1.1cm}
         \setlength{\labelsep}{0.4em}
         \setlength{\itemindent}{\z@}
         \setlength{\leftmargin}{\labelwidth+\labelsep}
         \addtolength{\itemsep}{-0.7em}
         \usecounter{enumiv}%
         \let\p@enumiv\@empty
         \renewcommand\theenumiv{\@arabic\c@enumiv}}%
    \sloppy\frenchspacing
    \clubpenalty4000
    \@clubpenalty \clubpenalty
    \widowpenalty4000%
    \interlinepenalty4000%
    \sfcode`\.\@m}
   {\def\@noitemerr
     {\@latex@warning{Empty `thebibliography' environment}}%
    \endlist\frenchspacing}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 附录
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\let\htu@appendix\appendix
\renewenvironment{appendix}{%
  \htu@appendix
  \gdef\@chapapp{\appendixname~\thechapter}%
  % 附录编号沿用全局定义：\appendix 令 \thechapter 为字母（A、B…），
  % 故 \thefigure/\thetable/\theequation 自动呈 A-1 形式（HTU §2.11/§2.12/§2.13）。
  }{}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 个人简历、在学期间发表的学术论文及研究成果
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\newenvironment{resume}[1][\htu@resume@title]{%
  \htu@chapter*{#1}\wuhao[1.524]}{}
\newcommand{\resumeitem}[1]{\vspace{2em}{\sihao\sffamily{#1}}\vspace{.5em}\par}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Self-Check Infrastructure (Story 2.2)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\newcounter{htu@totalpages}
\AddToHook{shipout/after}{\stepcounter{htu@totalpages}}
\newcommand{\htucheck}{%
  \typeout{=== HTU Layout Self-Check ===}%
  \typeout{textheight = \the\textheight}%
  \typeout{textwidth = \the\textwidth}%
  \typeout{baselineskip = \the\baselineskip}%
  \typeout{headheight = \the\headheight}%
  \typeout{evensidemargin = \the\evensidemargin}%
  \typeout{oddsidemargin = \the\oddsidemargin}%
  \typeout{total pages = \the\numexpr\c@htu@totalpages+1\relax}%
  \typeout{page counter = \the\c@page}%
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