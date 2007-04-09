../configure: aclocal.m4 configure.ac
	cd autoconf && autoconf && mv ./configure ..
update: config.sub config.guess
config.guess: /usr/share/misc/config.guess
	/bin/cp -f /usr/share/misc/config.guess config.guess
config.sub: /usr/share/misc/config.sub
	/bin/cp -f /usr/share/misc/config.sub config.sub
