%!%+
%\function{glob}
%\synopsis{Find files using wildcards}
%\usage{files = glob (pattern1, ..., patternN);
%\description
%  This function returns a list of files whose names match the specified
%  globbing patterns.  A globbing pattern is one in which '?' matches a
%  single character, and '*' matches 0 or more characters.
%\example
%   files = glob ("*.c", "*.h");
%\seealso{glob_to_regexp}
%!%-

private define needs_globbing (path)
{
   return (path != str_delete_chars (path, "*?["));
}

private define do_the_glob (dir, pat)
{
   variable files = listdir (dir);
   if (files == NULL)
     return String_Type[0];

   if (length (files) == 0)
     return files;

   pat = glob_to_regexp (pat);
   variable i = where (array_map (Int_Type, &string_match, files, pat, 1));
   if (length (i) == 0)
     return String_Type[0];

   files = files[i];
   return array_map (String_Type, &path_concat, dir, files);
}

define glob ();		       %  recursion
define glob ()
{
   variable patterns = __pop_args (_NARGS);
   if (length (patterns) == 0)
     throw UsageError, "files = glob (patterns...)";

   patterns = [__push_args (patterns)];

   variable list = String_Type[0];
   foreach (patterns)
     {
	variable pat = ();

	!if (needs_globbing (pat))
	  {
	     if (NULL != stat_file (pat))
	       list = [list, pat];

	     continue;
	  }

	variable dir = path_dirname (pat);
	variable base = path_basename (pat);

	if (needs_globbing (dir))
	  {
	     variable dirs = glob (dir);
	     !if (strlen (base))
	       {
		  list = [list, dirs];
		  continue;
	       }

	     foreach dir (glob (dir))
	       list = [list, do_the_glob (dir, base)];

	     continue;
	  }

	list = [list, do_the_glob (dir, base)];
     }
   return list;
}

#ifntrue
define slsh_main ()
{
   variable files = glob (__argv[[1:]]);
   foreach (files)
     {
	variable f = ();
	fprintf (stdout, "%s\n", f);
     }
}
#endif

provide ("glob");
