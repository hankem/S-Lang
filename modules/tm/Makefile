# -*- sh -*-
#
# To create the SGML files, you will need to install the tm-utils
# package.  See http://www.jedsoft.org/ for more information.
#
#TMEXPAND = $(HOME)/lib/tmexpand/bin/tmexpand
TMEXPAND=tmexpand
MACRODIR = -I$(HOME)/lib/tmexpand/macros

HLP_FILES = pngfuns.hlp pcrefuns.hlp sockfuns.hlp onigfuns.hlp \
  randfuns.hlp forkfuns.hlp

all: help-files
help-files: $(HLP_FILES)
pngfuns.hlp: pngfuns.tm
	$(TMEXPAND) $(MACRODIR) -Mslhlp pngfuns.tm pngfuns.hlp
pcrefuns.hlp: pcrefuns.tm
	$(TMEXPAND) $(MACRODIR) -Mslhlp pcrefuns.tm pcrefuns.hlp
sockfuns.hlp: sockfuns.tm
	$(TMEXPAND) $(MACRODIR) -Mslhlp sockfuns.tm sockfuns.hlp
onigfuns.hlp: onigfuns.tm
	$(TMEXPAND) $(MACRODIR) -Mslhlp onigfuns.tm onigfuns.hlp
randfuns.hlp: randfuns.tm
	$(TMEXPAND) $(MACRODIR) -Mslhlp randfuns.tm randfuns.hlp
forkfuns.hlp: forkfuns.tm
	$(TMEXPAND) $(MACRODIR) -Mslhlp forkfuns.tm forkfuns.hlp
#----------------------------------------------------------------------------
clean:
	-rm -f *~ *.dvi *.log *.aux *.toc *.bak
distclean: clean
	-rm -f *.html *.ps $(HLP_FILES)
install: $(HLP_FILES)
	-mv $(HLP_FILES) ../help
