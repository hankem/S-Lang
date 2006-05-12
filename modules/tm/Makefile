# -*- sh -*-
#
# To create the SGML files, you will need to install the tm-utils
# package.  See http://www.jedsoft.org/ for more information.
#
TMEXPAND = /aluche/d1/web/tm-dist/bin/tmexpand
MACRODIR = /aluche/d1/web/tm-dist/macros

HLP_FILES = pngfuns.hlp pcrefuns.hlp

all: help-files
help-files: $(HLP_FILES)
pngfuns.hlp: pngfuns.tm
	$(TMEXPAND) -I$(MACRODIR) -Mslhlp pngfuns.tm pngfuns.hlp
pcrefuns.hlp: pcrefuns.tm
	$(TMEXPAND) -I$(MACRODIR) -Mslhlp pcrefuns.tm pcrefuns.hlp
#----------------------------------------------------------------------------
clean:
	-rm -f *~ *.dvi *.log *.aux *.toc
distclean: clean
	-rm -f *.html *.ps $(HLP_FILES)
install: $(HLP_FILES)
	-mv $(HLP_FILES) ../help
