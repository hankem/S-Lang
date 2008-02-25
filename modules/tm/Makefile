# -*- sh -*-
#
# To create the SGML files, you will need to install the tm-utils
# package.  See http://www.jedsoft.org/ for more information.
#
TMEXPAND = $(HOME)/lib/tmexpand/bin/tmexpand
MACRODIR = $(HOME)/lib/tmexpand/macros

HLP_FILES = pngfuns.hlp pcrefuns.hlp sockfuns.hlp onigfuns.hlp randfuns.hlp

all: help-files
help-files: $(HLP_FILES)
pngfuns.hlp: pngfuns.tm
	$(TMEXPAND) -I$(MACRODIR) -Mslhlp pngfuns.tm pngfuns.hlp
pcrefuns.hlp: pcrefuns.tm
	$(TMEXPAND) -I$(MACRODIR) -Mslhlp pcrefuns.tm pcrefuns.hlp
sockfuns.hlp: sockfuns.tm
	$(TMEXPAND) -I$(MACRODIR) -Mslhlp sockfuns.tm sockfuns.hlp
onigfuns.hlp: onigfuns.tm
	$(TMEXPAND) -I$(MACRODIR) -Mslhlp onigfuns.tm onigfuns.hlp
randfuns.hlp: randfuns.tm
	$(TMEXPAND) -I$(MACRODIR) -Mslhlp randfuns.tm randfuns.hlp
#----------------------------------------------------------------------------
clean:
	-rm -f *~ *.dvi *.log *.aux *.toc *.bak
distclean: clean
	-rm -f *.html *.ps $(HLP_FILES)
install: $(HLP_FILES)
	-mv $(HLP_FILES) ../help
