@echo off

if x%1 == x goto noparam
echo - building Makefile in src...
src\mkfiles\mkmake %1 %2 %3 %4 %5 %6 %7 %8 %9 < src\mkfiles\makefile.all > src\Makefile

echo - building Makefile in slsh...
src\mkfiles\mkmake %1 %2 %3 %4 %5 %6 %7 %8 %9 < slsh\mkfiles\makefile.all > slsh\Makefile

echo - building Makefile in modules...
src\mkfiles\mkmake %1 %2 %3 %4 %5 %6 %7 %8 %9 < modules\mkfiles\makefile.all > modules\Makefile

set NAME=slang
cd src
nmake
if errorlevel 1 goto error

set NAME=slsh
cd ..\slsh
nmake
if errorlevel 1 goto error

set NAME=modules
cd ..\modules
nmake
if errorlevel 1 goto error

goto out


:error
echo ERROR: failed to build %NAME%

rem goto out

:out
cd ..
set NAME=
goto exit

:noparam
echo ERROR: need some parameters!
goto exit


:exit
