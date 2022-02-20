% Functions to walk the file system
% Copyright (C) 2012-2021,2022 John E. Davis
%
% This file is part of the S-Lang Library and may be distributed under the
% terms of the GNU General Public License.  See the file COPYING for
% more information.

private define get_stat (w, file)
{
   variable st = (@w.stat_func)(file);
   if (st == NULL)
     () = fprintf (stderr, "Unable to stat %s: %s\n", file, errno_string (errno));
   return st;
}

private define process_dir (w, dir, dir_st);
private define process_dir (w, dir, dir_st)
{
   variable status = 1;

   EXIT_BLOCK
     {
	if ((status != -1) && (w.leavedir_method != NULL))
	  {
	     if (-1 == (@w.leavedir_method)(dir, dir_st, __push_list (w.leavedir_method_args)))
	       return -1;
	  }
	return status;
     }

   if (w.enterdir_method != NULL)
     {
	status = (@w.enterdir_method) (dir, dir_st, __push_list (w.enterdir_method_args));
	if (status <= 0)
	  return;
     }

   foreach (listdir (dir))
     {
	variable file = ();
	file = path_concat (dir, file);

	variable st = get_stat (w, file);
	if (st == NULL)
	  continue;

	if (stat_is ("dir", st.st_mode))
	  {
	     status = process_dir (w, file, dir_st);
	     if (status < 0)
	       return status;

	     continue;
	  }

	if (w.file_method == NULL)
	  continue;
	status = (@w.file_method) (file, st, __push_list(w.file_method_args));
	if (status <= 0)
	  return;
     }
   status = 1;
}

private define fswalk (w, start)
{
   variable st = get_stat (w, start);
   if (st == NULL) return;

   if (stat_is ("dir", st.st_mode))
     () = process_dir (w, start, st);
   else if (w.file_method_args != NULL)
     () = (@w.file_method) (start, st, __push_list(w.file_method_args));
}

define fswalk_new ()
{
   ifnot (2 <= _NARGS <= 3)
     usage ("\n\
w = fswalk_new (enterdir_func, file_func [, leavedir_func] [; qualifiers]);\n\
w.walk (topdir);\n\
\n\
Qualifiers:\n\
  dargs={args,...}   Additional arguments to be passed to enterdir_func\n\
  fargs={args,...}   Additional arguments to be passed to file_func\n\
  largs={args,...}   Additional arguments to be passed to leavedir_func\n\
  followlinks[=0|1]  Indicates whether or not symbolic links will be followed\n\
");

   variable enterdir_method, leavedir_method = NULL, file_method;
   if (_NARGS == 3) leavedir_method = ();
   (enterdir_method, file_method) = ();

   variable enterdir_method_args = qualifier ("dargs", {});
   variable file_method_args = qualifier ("fargs", {});
   variable leavedir_method_args = qualifier ("largs", {});

   if (typeof (enterdir_method_args) != List_Type)
     enterdir_method_args = {enterdir_method_args};
   if (typeof (file_method_args) != List_Type)
     file_method_args = {file_method_args};
   if (typeof (leavedir_method_args) != List_Type)
     leavedir_method_args = {leavedir_method_args};
   variable followlinks
     = (qualifier_exists ("followlinks") && (0 != qualifier ("followlinks")));

   variable w = struct
     {
	walk = &fswalk,
	file_method = file_method,
	file_method_args = file_method_args,
	enterdir_method = enterdir_method,
	enterdir_method_args = enterdir_method_args,
	leavedir_method = leavedir_method,
	leavedir_method_args = leavedir_method_args,
	stat_func = (followlinks ? &stat_file : &lstat_file),
     };
   return w;
}
