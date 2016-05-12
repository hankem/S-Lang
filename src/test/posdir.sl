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

print ("Ok\n");
exit (0);
