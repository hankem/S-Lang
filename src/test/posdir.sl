() = evalfile ("inc.sl");

testing_feature ("posdir");

private define test_listdir (dir)
{
   variable i, file, files;

   files = listdir (dir);
   if (length(files))
     {
	failed ("listdir returned %d files for new dir", length(files));
     }

   _for i (1, 4, 1)
     {
	file = "$dir/$i"$;
	if (NULL == open (file, O_WRONLY|O_CREAT))
	  failed ("fopen %S failed", file);
	files = listdir (dir);
	if (length (files) != i)
	  failed ("listdir %S failed to produce %d items", dir, i);
	files = atoi (files);
	files = files[array_sort (files)];
	ifnot (_eqs (files, [1:i]))
	  failed ("listdir %S failed to produce the proper list of files", dir);
     }

   foreach file (files)
     {
	file = "$dir/$file"$;
	if (-1 == remove (file))
	  failed ("remove %S failed: %S", file, errno_string());
     }
}

private define test_posdir ()
{
   variable dir = util_make_tmp_dir ("tmpdir");

   test_listdir (dir);

   if (-1 == rmdir (dir))
     failed ("rmdir %s: %s", dir, errno_string());
}
test_posdir ();

private define test_non_exist_file_ops ()
{
   variable badfile = "/122345 user";
   if (NULL == stat_file (badfile))
     () = remove (badfile);	       %  should fail
   variable tmpfile = util_make_tmp_file ("tmpfileX", NULL);
   variable tmpfile1 = tmpfile + "-tmp";
   variable tmpdir = util_make_tmp_dir ("tmpdir");
   variable dir = getcwd ();
#ifexists lstat_file
   if (NULL != lstat_file (badfile))
     failed ("lstat_file %S succeeded", badfile);
#endif

#ifexists access
   if (-1 == access (tmpfile, R_OK))
     failed ("access %s R_OK", tmpfile);
   if (0 == access (badfile, R_OK))
     failed ("access %s R_OK", badfile);
#endif
#ifexists chdir
   if (-1 == chdir (tmpdir))
     failed ("chdir %S", tmpdir);
   if (-1 == chdir (dir))
     failed ("chdir %S", dir);
   if (0 == chdir (badfile))
     failed ("chdir %S succeeded", badfile);
#endif
#ifexists symlink
   if (-1 == symlink (tmpfile, tmpfile1))
     failed ("symlink %s -> %s: %S", tmpfile1, tmpfile, errno_string());
   variable st = lstat_file (tmpfile1);
   if ((st == NULL) || (0 == stat_is  ("lnk", st.st_mode)))
     failed ("stat_is lnk for %s", tmpfile1);
   if (-1 != symlink ("", ""))
     failed ("expected symlink to fail for empty strings");
# ifexists readlink
   if (tmpfile != readlink (tmpfile1))
     failed ("readlink %s: %s", tmpfile1, errno_string());
   if (NULL != readlink (tmpfile))
     failed ("Expected readlink to fail when reading a regular file");
# endif
   if (-1 == remove (tmpfile1))
     failed ("remove %s: %s", tmpfile1, errno_string());
#endif

#ifexists hardlink
   if (0 == hardlink (badfile, tmpfile1))
     failed ("hardlink to bad file succeeded");
   if (-1 == hardlink (tmpfile, tmpfile1))
     failed ("hardlink %s -> %s failed: %s", tmpfile1, tmpfile, errno_string());
   () = remove (tmpfile1);
#endif

   if (-1 != rename (tmpfile1, tmpfile1))
     failed ("Expected rename to fail to rename a non-existent file to itself");
   if (0 != rename (tmpfile, tmpfile1))
     failed ("rename %s->%s; %s", tmpfile, tmpfile1, errno_string());
   if (0 != rename (tmpfile1, tmpfile))
     failed ("rename %s->%s; %s", tmpfile, tmpfile1, errno_string());
   if (0 == rmdir (tmpfile))
     failed ("Expected rmdir to fail to remove %S", tmpfile);

#ifexists utime
   if (-1 != utime (badfile, 2000.0, 3000.0))
     failed ("Expected utime to fail on a non-existent file");
   if (-1 == utime (tmpfile, 2000.0, 3000))
     failed ("utime %s: %s", tmpfile, errno_string());
   st = stat_file (tmpfile);
   if (st == NULL)
     failed ("stat_file %S failed: %S", tmpfile, errno_string());
   if ((st.st_atime != 2000) || (st.st_mtime != 3000))
     failed ("stat_file times differ from utime values");
#endif
#ifexists chmod
   if (-1 == chmod (tmpfile, S_IWUSR))
     failed ("chmod %s failed: %s", tmpfile, errno_string());
   st = stat_file (tmpfile);
   if (st == NULL)
     failed ("stat_file %s failed: %s", tmpfile, errno_string());
   if ((st.st_mode&0777) != S_IWUSR)
     failed ("chmod %s mode=%d does not match stat_file mode=%d",
	     tmpfile, S_IWUSR, st.st_mode);
   if (-1 != chmod (badfile, S_IWUSR))
     failed ("expected chmod to fail on a non-existent file");
#endif
#ifexists chown
   if (-1 != chown ("", 0, 0))
     failed ("chown of an empty string succeeded");
   st = stat_file (tmpfile);
   if (-1 == chown (tmpfile, st.st_uid, st.st_gid))
     failed ("chown %s failed: %s", errno_string());
#endif
#ifexists lchown
   % FIXME: Add a better test
   if (-1 != lchown ("", 0, 0))
     failed ("chown of an empty string succeeded");
#endif
   () = rmdir (tmpdir);
   () = remove (tmpfile);
}
test_non_exist_file_ops ();

#ifexists statvfs
private define test_statvfs ()
{
   () = statvfs (".");
   () = statvfs (stdout);
   () = statvfs (1);
   () = statvfs (fileno(stdout));
   try
     {
	() = statvfs (1.2);
     }
   catch TypeMismatchError;
   catch AnyError: failed ("expected statvfs to fail on an invalid object");

   if (NULL != statvfs ("/* non * existent * file *"))
     failed ("Expected statvfs to fail on a non-existent file");
}
test_statvfs ();
#endif

#ifexists umask
private define test_umask ()
{
   variable m = umask (022);
   if (022 != umask (m))
     failed ("umask 022");
   if (m != umask (m))
     failed ("umask m");
}
test_umask ();
#endif

print ("Ok\n");
exit (0);
