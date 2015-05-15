() = evalfile ("./inc.sl");

testing_feature ("path");

static define test_path_concat (a, b, c)
{
   variable d = path_concat (a, b);
   if (c != d)
     failed ("path_concat(%s,%s) --> %s, not %s", a,b,d,c);
}

static define test_path (path, dir, base, ext, dirbase, sansextname)
{
   if (dir != path_dirname (path))
     failed ("path_dirname " + path + sprintf (" ;got %S", path_dirname(path)));

   if (base != path_basename (path))
     failed ("path_basename " + path);

   if (ext != path_extname (path))
     failed ("path_extname " + path);

   test_path_concat (dir, base, dirbase);

   if (sansextname != path_sans_extname (path))
     failed ("path_sans_extname(\""+ path+ "\")");

   if (path_basename_sans_extname (path) != path_basename (sansextname))
     failed ("path_basename_sans_extname path");
}

private define test_is_absolute (path, yesno)
{
   if (yesno == path_is_absolute (path))
     return;

   failed ("%d != path_is_absolute %S", yesno, path);
}


#ifdef UNIX
test_path ("etc/rc.d", "etc", "rc.d", ".d", "etc/rc.d", "etc/rc");
test_path ("etc", ".", "etc", "", "./etc", "etc");
test_path ("usr/etc/", "usr/etc", "", "", "usr/etc/", "usr/etc/");
test_path ("/", "/", "", "", "/", "/");
test_path (".", ".", ".", ".", "./.", "");
test_path ("/a./b", "/a.", "b", "", "/a./b", "/a./b");
test_path (".c", ".", ".c", ".c", "./.c", "");
test_path ("foo/bar/../up", "foo", "up", "", "foo/up", "foo/bar/../up");
test_path ("foo/bar/./up", "foo/bar", "up", "", "foo/bar/up", "foo/bar/./up");
test_path ("./x.c", ".", "x.c", ".c", "./x.c", "./x");
test_path ("/./x.c", "/", "x.c", ".c", "/x.c", "/./x");
%"/tmp/jedtest4775.7430/dev/foo"

test_is_absolute ("/", 1);
test_is_absolute ("", 0);
test_is_absolute ("./foo", 0);
test_is_absolute ("../foo/", 0);
test_is_absolute ("/foo", 1);
test_is_absolute ("/foo/bar", 1);
test_is_absolute ("foo/bar", 0);
test_is_absolute ("foo", 0);

#elifdef VMS

test_path_concat ("drive:[dir.dir]", "a/b.c", "drive:[dir.dir.a]b.c");
test_path_concat ("drive:", "/a/b/c.d", "drive:[a.b]c.d");
test_path_concat ("drive:", "a/b/c.d", "drive:[a.b]c.d");
test_path_concat ("drive:", "/a.b", "drive:a.b");

test_path_concat ("[dir.dir]", "a/b.c", "[dir.dir.a]b.c");
test_path_concat ("", "/a/b/c.d", "[a.b]c.d");
test_path_concat ("", "a/b/c.d", "[a.b]c.d");
test_path_concat ("", "/a.b", "a.b");

#else
message ("**** NOT IMPLEMENTED ****");
#endif

private define test_getset_load_path ()
{
   variable a = get_slang_load_path ();
   variable b = sprintf ("%s%c%s", a, path_get_delimiter (), "foobar");
   set_slang_load_path (b);
   variable c = get_slang_load_path ();
   if (b != c)
     failed ("set_slang_load_path %S ==> %S", b, c);

   set_slang_load_path (a);
   b = get_slang_load_path ();
   if (a != get_slang_load_path ())
     failed ("resetting set_slang_load_path %S ==> %S", a, b);
}
test_getset_load_path ();

print ("Ok\n");

exit (0);

