# HTUthesislatex — Project Conventions

Auto-loaded by Claude Code for this project. Operational conventions for formatting-correctness work. Codified from Epic 2 retrospective Decision 4 (see `_bmad-output/implementation-artifacts/epic-2-retro-2026-06-14.md`).

## Truth Sources & Empirical Verification

CJK / font / formatting correctness rests on THREE truth sources. Triangulate against all three — a single source is insufficient.

### The three truth sources (priority for visual/formatting decisions)

1. **Reference thesis PDF** — `2107084001-任子辛-政治与公共管理学院.pdf` (completed HTU doctoral dissertation, 262pp). Primary VISUAL truth (what reviewers compare against; what "done" looks like). When spec text and the reference PDF disagree on a visual detail, the **reference PDF wins**. (Stands in for the Word template — the theoretical ideal we do not hold directly.)
2. **Official format spec** — `河南师范大学研究生学位论文格式要求.md`. TEXTUAL truth (the rules). Authoritative for stated requirements, but self-contradictory in places (header "centered" vs page-number "outer") and silent on rendering realities.
3. **Implementation spec / `.def` truth-source comments** — `htuthesis.def` `[基础]` annotations + this repo's epics/PRD. The MAPPING from requirements to LaTeX; the record of how each parameter was calibrated and why.

### Empirical verification is mandatory for CJK / font / formatting ACs

Never verify a CJK/font/formatting acceptance criterion by reading the spec alone — the spec cannot encode rendering realities (e.g., `\rmfamily\bfseries` renders as SimHei, not bold-SimSun; found only by empirical test in Story 2.5). Verify against the COMPILED PDF:

- Use fitz/PyMuPDF behavior tests (`get_text('dict')` span-level font/size, `get_drawings` for rules/positions) on the compiled output.
- For "absence of X" ACs where X's content may overlap other elements (headers, page numbers, blank-page styles), check X's VISUAL SIGNATURE (rule drawing / span font / position), not a text proxy. (Retro Decision 1.)

### Transparent-deviation workflow (when the prescribed form fails empirically)

When an implementation deviates from the spec/prescribed form:

1. **Diagnose empirically** — confirm the deviation against compiled output + the reference PDF.
2. **Anchor to a truth source** — cite which of the three justifies it (e.g., "reference PDF page 9 shows half-width colon").
3. **Document transparently** — record in story Dev Notes + `.def` `[基础]` comment. No silent deviations.
4. **Get user approval** — surface before proceeding.

### Related

- `_bmad-output/planning-artifacts/architecture.md` §真值源层次与冲突解决协议 — design-level protocol.
- `_bmad-output/implementation-artifacts/epic-2-retro-2026-06-14.md` Decision 4 — origin of this convention.
