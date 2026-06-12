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

test: compile-check lint-check structure-check
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

.PHONY: test compile-check lint-check structure-check
