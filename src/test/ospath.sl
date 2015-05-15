() = evalfile ("inc.sl");

testing_feature ("ospath");

static define test_path (path, dir, base, ext, dirbase, sansext)
{
   if (dir != path_dirname (path))
     failed ("path_dirname " + path);

   if (base != path_basename (path))
     failed ("path_basename " + path);

   if (ext != path_extname (path))
     failed ("path_extname " + path);

   if (dirbase != path_concat (dir, base))
     failed ("path_concat(%s,%s)", dir, base);

   if (sansext != path_basename_sans_extname (path))
     failed ("path_basename_sans_extname " + path);
}

#ifdef UNIX
test_path ("etc/rc.d", "etc", "rc.d", ".d", "etc/rc.d", "rc");
test_path ("etc", ".", "etc", "", "./etc", "ext");
test_path ("usr/etc/", "usr/etc", "", "", "usr/etc/", "");
test_path ("/", "/", "", "", "/", "");
test_path (".", ".", ".", ".", "./.", "");
test_path ("/a./b", "/a.", "b", "", "/a./b", "b");
test_path (".c", ".", ".c", ".c", "./.c", "");

if (':' != path_get_delimiter ()) failed ("path_get_delimiter");
#elifndef VMS
test_path ("etc\\rc.d", "etc", "rc.d", ".d", "etc\\rc.d");
test_path ("etc", ".", "etc", "", ".\\etc");
test_path ("usr\\etc\\", "usr\\etc", "", "", "usr\\etc\\");
test_path ("\\", "\\", "", "", "\\");
test_path (".", ".", ".", ".", ".\\.");
test_path ("\\a.\\b", "\\a.", "b", "", "\\a.\\b");
test_path (".c", ".", ".c", ".c", ".\\.c");
#else
message ("**** NOT IMPLEMENTED ****");
#endif
print ("Ok\n");

exit (0);

