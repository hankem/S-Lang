prepend_to_slang_load_path ("..");
set_import_module_path ("../${ARCH}objs:"$ + get_import_module_path ());

define testing_module (m)
{
   () = fprintf (stdout, "Testing %s module...", m);
   () = fflush (stdout);
}

private variable tests_failed = 0;

define failed ()
{
   variable s = __pop_args (_NARGS);
   s = sprintf (__push_args(s));
   () = fprintf (stderr, "Failed: %s\n", s);
   tests_failed++;
}

define end_test ()
{
   ifnot (tests_failed)
     {
	() = fprintf(stdout, "OK\n");
	() = fflush (stdout);
     }
   exit (tests_failed);
}
