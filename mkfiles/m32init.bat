@echo off
echo - generating Makefile in src...
src\mkfiles\mkmake WIN32 MINGW32 DLL < src\mkfiles\makefile.all > src\Makefile

echo - generating Makefile in slsh...
src\mkfiles\mkmake WIN32 MINGW32 DLL < slsh\mkfiles\makefile.all > slsh\Makefile

echo - generating Makefile in modules...
src\mkfiles\mkmake WIN32 MINGW32 DLL < modules\mkfiles\makefile.all > modules\Makefile

copy src\slconfig.h src\config.h
copy mkfiles\makefile.m32 Makefile

echo Now run mingw32-make to build the library.  But first, you should
echo look at Makefile and change the installation locations if
echo necessary.  In particular, the PREFIX variable in the top-level
echo Makefile controls where the library will be installed.
echo -
