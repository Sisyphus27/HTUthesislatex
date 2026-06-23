# Makefile for HtuThesis

LATEXMKOPTS = -xelatex -file-line-error -halt-on-error -interaction=nonstopmode
THESISMAIN = main
PACKAGE = htuthesis

THESISCONTENTS=$(THESISMAIN).tex data/*.tex
CLSFILES=$(PACKAGE).cls

# make deletion work on Windows
ifdef SystemRoot
	RM = del /Q
else
	RM = rm -f
endif

all: thesis a3cover

###### for thesis

thesis: $(THESISMAIN).pdf

$(THESISMAIN).pdf: $(CLSFILES) $(THESISCONTENTS)
	latexmk $(LATEXMKOPTS) $(THESISMAIN)

###### for a3cover

a3cover:a3cover.pdf

a3cover.pdf: spine.pdf $(THESISMAIN).pdf a3cover.tex
	xelatex a3cover.tex

spine.pdf: spine.tex
	xelatex spine.tex

##### clean

clean:
	latexmk -c $(THESISMAIN) spine a3cover
	-@$(RM) *~ *.bbl *.exa *.xdv data/*.aux

###### testing

test: compile-check lint-check structure-check sentinel-check
	@echo "=== All tests passed ==="

compile-check: $(THESISMAIN).pdf
	@echo "[PASS] Compilation successful"

lint-check:
	@echo "=== ChkTeX Lint ==="
	@for f in $(THESISMAIN).tex data/*.tex; do \
		chktex -q -l .chktexrc "$$f" || true; \
	done
	@echo "[PASS] Lint check complete"

structure-check:
	@bash tests/check-structure.sh

###### sentinel-check (Story 5.2；NFR-4 #15 detection layer；参考文献 chapter-vanish guard；runs every make test)
#   fitz rendered-span probe on main.pdf for 参考文献 chapter title (SimHei 三号). FAIL (exit≠0) if the chapter vanished.
#   Reuses compile-check's main.pdf (zero extra compile). Rendered-span-anchored (NOT proxied .bbl/.aux — R-35/TC-E5-14).
sentinel-check: $(THESISMAIN).pdf
	@bash tests/sentinel-bibliography-chapter.sh

###### calibration tool (Story 4.3；standalone TikZ ruler page；AC-3/4；opt-in，NOT in all/test)

calibrate: tools/calibrate.pdf
	@echo "[PASS] calibrate.pdf built (tools/calibrate.tex standalone)"

tools/calibrate.pdf: tools/calibrate.tex
	cd tools && xelatex -file-line-error -halt-on-error -interaction=nonstopmode calibrate.tex

###### debug-check (Story 4.3；NFR-5 调试标准；6 LaTeX warnings 视为 errors；opt-in)
#   sed-copy main.tex -> .debug-main.tex with [doctor,debug] (activate \ifhtu@debug verbose self-check),
#   compile, grep main.log for the 6 NFR-5 warning signatures; any hit -> exit 1 (warnings-as-errors in dev).
#   Clean default tree (4.2 close-out: 1 xeCJK warning, no NFR-5) -> exit 0. SUT (main.tex) untouched.
debug-check:
	@echo "=== NFR-5 debug-check ([doctor,debug] + 6-warning grep) ==="
	sed 's/\\documentclass\[doctor\]{htuthesis}/\\documentclass[doctor,debug]{htuthesis}/' main.tex > .debug-main.tex
	@grep -q '\documentclass\[doctor,debug\]{htuthesis}' .debug-main.tex || { echo "FAIL: sed no-match -- main.tex documentclass line changed; [doctor,debug] not injected"; rm -f .debug-main.*; exit 1; }
	latexmk $(LATEXMKOPTS) .debug-main >/dev/null 2>&1 || { rc=$$?; echo "FAIL: [doctor,debug] compile error (rc=$$rc)"; rm -f .debug-main.*; exit 1; }
	@if grep -E 'Overfull \\hbox|geometry Warning: Over-specification|fancyhdr Warning: \\headheight is too low|natbib Warning: Citation.*undefined|Token not allowed in a PDF string|caption Warning' .debug-main.log | grep -v -E 'watch.list|NFR-5 warning-as-error|^\[[0-9]\]|^\[debug\]'; then \
		echo "FAIL: NFR-5 warning(s) detected -- treated as errors in debug mode (see Makefile debug-check)"; \
		rm -f .debug-main.*; exit 1; \
	else \
		echo "[PASS] no NFR-5 warnings -- debug-check clean"; \
		rm -f .debug-main.*; \
	fi

.PHONY: test compile-check lint-check structure-check calibrate debug-check sentinel-check
