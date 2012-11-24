rem This batch file may be used to create mkmake using mingw32 gcc.
copy ..\slconfig.h ..\config.h
gcc -DWIN32 -DSLANG_DLL=0 -I.. ./mkmake.c ../slprepr.c -o mkmake.exe
