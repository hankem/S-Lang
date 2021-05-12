() = evalfile ("./common.sl");

require ("glob");
require ("setfuns");

define slsh_main ()
{
   start_test ("glob");

   variable files, files1, files2;

   files = glob (__FILE__, "foo.xxyu.zz");
   if ((length (files) != 1)
       || (path_basename (files[0]) != path_basename (__FILE__)))
     {
	failed ("glob __FILE__");
     }

   files = glob ("*.sl");
   files1 = listdir (".");
   files1 = files1[where (".sl" == array_map (String_Type, &path_extname, files1))];
   files = files[array_sort (files)];
   files1 = files1[array_sort (files1)];

   ifnot (_eqs (files, files1))
     {
	failed ("glob 1");
     }

   variable dir = getcwd ();
   % The getcwd function returns the CWD with a trailing slash.
   % That is not wanted here.
   if (strbytelen(dir) > 1) dir = dir[[:-2]];
   files1 = glob (path_concat (dir + "*", "*.sl"));

   % A an equivalent variant
   dir = glob (dir + "*/"); % returns an array, so use array_map below
   files2 = glob (array_map (String_Type, &path_concat, dir, "*.sl"));

   if ((length (files1) != length (files2))
       || length (complement (files1, files2)))
     {
	failed ("glob file1 vs files2");
     }

   % There may be more than one directory matching dir*.  So just
   % look for a subset of matching files, i.e., files \in files1
   files1 = array_map (String_Type, &path_basename, files1);
   if (length (complement (files, files1)) != 0)
     {
	failed ("glob 2: some files were not found in files1");
     }

   end_test();
}
