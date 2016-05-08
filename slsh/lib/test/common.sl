% These tests load the uninstalled version of slsh.rc.  The
% installation script appends code for SLSH_PATH processing.  Since
% the uninstalled version of slsh.rc lacks this code, it is added here.
prepend_to_slang_load_path(getenv("SLSH_PATH"));

define start_test (m)
{
   () = fprintf (stdout, "Testing %s functions...", m);
   () = fflush (stdout);
}

private variable tests_failed = 0;

define failed ()
{
   variable s = __pop_args (_NARGS);
   s = sprintf (__push_args(s));
   () = fprintf (stderr, "Failed: %s\n", s);
   tests_failed++;
   throw RunTimeError;
}

define end_test ()
{
   if (tests_failed)
     exit (tests_failed);

   () = fprintf(stdout, "OK\n");
   () = fflush (stdout);
}


