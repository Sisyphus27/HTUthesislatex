# HTUthesislatex — Project Conventions

Auto-loaded by Claude Code for this project. Operational conventions for formatting-correctness work. Codified from Epic 2 retrospective Decision 4 (see `_bmad-output/implementation-artifacts/epic-2-retro-2026-06-14.md`).

## Truth Sources & Empirical Verification

CJK / font / formatting correctness rests on THREE truth sources. Triangulate against all three — a single source is insufficient.

### The three truth sources (priority for visual/formatting decisions)

> **Priority hierarchy (corrected 2026-06-17, Zy ruling — supersedes Epic 2 retro Decision 4):** **spec.md is the PRIORITY truth source.** Where spec has explicit text, follow spec regardless of the reference PDF. The reference PDF is auxiliary — used only where spec is silent/ambiguous (e.g. to interpret "倍数行距" = Word semantics = 23.4pt). The reference PDF is a filled Word instance and itself deviates from spec in places (reverse-hanging refs vs §2.14, left-aligned appendix vs §2.15, non-bold KEY WORDS vs §2.8, colon caption vs §2.11/2.12 "空半格") — it is NOT ground truth. See `sprint-change-proposal-2026-06-17.md`.

1. **Official format spec** — `河南师范大学研究生学位论文格式要求.md`. **PRIORITY truth source** (the rules). Authoritative where it has explicit text, even if the reference PDF renders differently. Self-contradictory in places (header "centered" vs page-number "outer"); resolve those by the spec's own structure, not by the reference PDF.
2. **Reference thesis PDF** — `2107084001-任子辛-政治与公共管理学院.pdf` (completed HTU doctoral dissertation, 262pp). **Auxiliary** visual truth. Use to interpret ambiguous spec text (e.g. "1.5倍行距" → measure line-gap = Word semantics) and where spec is silent. Do NOT override explicit spec text — the reference is a filled Word instance that deviates from spec in several details.
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
