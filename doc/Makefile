##
## Makefile for Mizar Mode.
##
## Modified from ProofGeneral Makefile.doc by David Aspinall.
##
###########################################################################
##
## Use:
##	make info,dvi,pdf,html    - build respective docs from texi source.
##	make doc		  - make default kinds of doc (dvi, info).
##
###########################################################################

DOCNAME  = MizarMode
MAKEINFO = makeinfo
TEXI2DVI = texi2dvi

DVI2PS = dvips -Pcmz
TEXI2PDF = texi2pdf
TEXI2HTML = texi2html -expandinfo -number -split_chapter
EMACS = emacs -batch
TAR	= tar
GZIP	= gzip -f
DOCARCHIVE = MizarModeDoc.tar.gz

MIZARMODE = ../mizar.el

TMPFILE=pgt

tardist: $(DOCARCHIVE)

$(DOCARCHIVE): dist 
	@echo Creating $(DOCARCHIVE) 
	@rm -r -f $(DOCARCHIVE)
	@rm -r -f html
	@mkdir html
	@cp -a -L *.html html
	$(TAR) -cvzf $(DOCARCHIVE) html $(DOCNAME).{info,ps.gz,pdf} 
	@echo $(DOCARCHIVE) created

# .SUFFIXES:  .texi .info .dvi .html .pdf .ps .gz


%.info: %.texi
	$(MAKEINFO) $<

%.dvi: %.texi
	$(TEXI2DVI) $<

%.pdf:  %.texi
	$(TEXI2PDF) $<

%.ps: %.dvi
	$(DVI2PS) $< -o $*.ps

%.html:	%.texi
	$(TEXI2HTML) $<

%.gz : %
	$(GZIP) $*

all:    dvi ps html info pdf

##
## dist: build distribution targets
##
dist:   info html psz pdf

dvi:    $(DOCNAME).dvi
ps:	dvi $(DOCNAME).ps
psz:	ps $(DOCNAME).ps.gz
pdf:    $(DOCNAME).pdf
html:   $(DOCNAME).html
	ln -sf $(DOCNAME)_toc.html index.html
info:   $(DOCNAME).info

##
## clean: Remove subsidiary documentation files
##
clean:
	rm -f $(DOCNAME).{cp,fn,vr,tp,ky,pg} 
	rm -f $(DOCNAME).{fns,vrs,cps,aux,log,toc,kys,cp0}
	rm -f *~

##
## distclean: Remove documentation targets too
##
distclean:   clean
	rm -r -f $(DOCNAME).info* $(DOCNAME).dvi $(DOCNAME)*.ps $(DOCNAME).pdf $(DOCNAME)*.html html

##
## texi: update magic comments in texi from docstrings in code.
##	  (developer use only!)
##
$(DOCNAME).texi: $(MIZARMODE)
	$(MAKE) magic
magic:
	$(EMACS) -q -l texi-docstring-magic.el -l $(MIZARMODE) $(DOCNAME).texi -f texi-docstring-magic -f save-buffer






