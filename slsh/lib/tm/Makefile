# -*- sh -*-
#
# To create the SGML files, you will need to install the tm-utils
# package.  See http://www.jedsoft.org/ for more information.
#
TMEXPAND = tmexpand

HLP_FILES = arrayfuns.hlp glob.hlp require.hlp structfuns.hlp cmdopt.hlp \
            readascii.hlp profile.hlp print.hlp process.hlp setfuns.hlp

all: help-files
help-files: $(HLP_FILES)
arrayfuns.hlp: arrayfuns.tm
	$(TMEXPAND) -Mslhlp arrayfuns.tm arrayfuns.hlp
glob.hlp: glob.tm
	$(TMEXPAND) -Mslhlp glob.tm glob.hlp
require.hlp: require.tm
	$(TMEXPAND) -Mslhlp require.tm require.hlp
structfuns.hlp: structfuns.tm
	$(TMEXPAND) -Mslhlp structfuns.tm structfuns.hlp
cmdopt.hlp: cmdopt.tm
	$(TMEXPAND) -Mslhlp cmdopt.tm cmdopt.hlp
print.hlp: print.tm
	$(TMEXPAND) -Mslhlp print.tm print.hlp
readascii.hlp: readascii.tm
	$(TMEXPAND) -Mslhlp readascii.tm readascii.hlp
profile.hlp: profile.tm
	$(TMEXPAND) -Mslhlp profile.tm profile.hlp
process.hlp: process.tm
	$(TMEXPAND) -Mslhlp process.tm process.hlp
setfuns.hlp: setfuns.tm
	$(TMEXPAND) -Mslhlp setfuns.tm setfuns.hlp
#----------------------------------------------------------------------------
clean:
	-rm -f *~ *.dvi *.log *.aux *.toc *.bak
distclean: clean
	-rm -f *.html *.ps $(HLP_FILES)
install: $(HLP_FILES)
	-mv $(HLP_FILES) ../help
