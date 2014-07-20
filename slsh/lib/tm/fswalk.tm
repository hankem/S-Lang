\function{fswalk_new}
\synopsis{Create an object to walk the filesystem tree}
\usage{obj = fswalk_new (Ref_Type dirfunc, Ref_Type filefunc; qualifiers)}
\description
  The \sfun{fswalk_new} function creates an object that is useful
  for exploring a filesystem tree.  It requires two arguments that
  are references to functions to be called when a directory or file is
  encountered.  Each of these functions is passed at least two
  arguments: the name of the file or directory (including leading path
  elements relative to the directory where processing started), and
  the stat structure of the of the file or directory.  Qualifiers may
  be used to specify additional arguments.

  The object's \exmp{walk} method is the one that actually walks the
  filesystem.

  The directory callback function must return an integer value that
  indicates how it should be processed.  If the function returns 0,
  then the directory will be skipped (pruned).  A positive value
  indicates that the directory will processed.  If the function
  returns a negative value, then no further processing by the walk
  function will take place and control will pass to the user.

  The file callback function must also return an integer that
  indicates how processing should continue.  If it returns a positive
  value, then additional files in the corresponding directory will be
  processed.  If it returns 0, then no further files or subdirectories
  of the directory will be processed, and processing will continue to
  take place in the parent directory.  Otherwise, the return value is
  negative, which indicates that processing should be stopped and
  control will pass back to the caller.

\qualifiers
  The following qualifiers are supported:
#v+
   dargs={args...}
#v-
    \exmp{dargs} is a list of additional arguments that will be added when
    calling the directory callback function.
#v+
   fargs={args...}
#v-
    \exmp{fargs} is a list of additional arguments that will be added when
    calling the file callback function.
#v+
   followlinks[=val]
#v-
    The \exmp{followlinks} qualifier may be used to indicate whether
    or not directories that are symbolic links are to be followed.  By
    default, they are not.  If \exmp{followlinks} is present with no
    value, or has a non-zero value, then symbolic links will be
    followed.  Otherwise, if \exmp{followlinks} is not present, or is
    set to 0, then directories that are symbolic links will be skipped.

\methods
#v+
   .walk (String_Type top_dir)
#v-
    The \exmp{.walk} function walks the filesystem starting at the
    specified top-level directory calling the directory and file
    callback functions as it goes.

\example
  Print a list of all files containing a \exmp{.png} extension under
  the current directory:
#v+
     private define file_callback (name, st)
     {
        if (".png" == path_extname (name))
          message (name);
        return 1;
     }
     variable w = fswalk_new (NULL, &file_callback);
     w.walk (".");
#v-

  Get a list of all directories that are symbolic links under /usr.
#v+
     private define dir_callback (name, st, list)
     {
        st = lstat_file (name);
        if (stat_is ("lnk", st.st_mode))
          {
            list_append (list, name);
            return 0;
          }
        return 1;
     }

     define get_symdir_list (top)
     {
        variable list = {};
        variable w = fswalk_new (&dir_callback, NULL
                                 ;dargs={list}, followlinks);
        w.walk (top);
        return list;
     }
     symdirlist = get_symdir_list ("/usr");
#v-
  Note that in this example, the dir_callback function returns 0 if
  the directory corresponds to a symbolic link.  This causes the link
  to not be followed.

  Get a list of dangling symbolic links:
#v+
     private define file_callback (name, st, list)
     {
        if (stat_is ("lnk", st.st_mode))
          {
             if ((NULL == stat_file (name))
                 && (errno == ENOENT))
               list_append (list, name);
          }
        return 1;
     }

     define get_badlinks (top)
     {
        variable list = {};
        variable w = fswalk_new (NULL, &file_callback ;fargs={list});
        w.walk (top);
        return list;
     }
#v-
\seealso{glob, stat_file, lstat_file, listdir};
\done

