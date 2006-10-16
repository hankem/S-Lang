# -*- sh -*-
#
# To create the SGML files, you will need to install the tm-utils
# package.  See http://www.jedsoft.org/ for more information.
#
TM2SGML = $(HOME)/lib/tmexpand/bin/tmexpand
MACRODIR = $(HOME)/lib/tmexpand/macros

DOCBOOK2MAN = docbook2man

slsh.1: slsh.sgml
	$(DOCBOOK2MAN) slsh.sgml
slsh.sgml: slsh.tm
	$(TM2SGML) -I$(MACRODIR) slsh.tm slsh.sgml
view: slsh.1
	nroff -man slsh.1 | most
#----------------------------------------------------------------------------
clean:
	-rm -f *~ *-error manpage.refs manpage.links
distclean: clean
	-rm -f slsh.1 slsh.sgml
install: slsh.1
	-mkdir ../man
	-mv slsh.1 ../man
