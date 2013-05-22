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


define expect_type (var, expected_type)
{
   if (typeof (var) != expected_type)
     failed ("expected type %S, but was %S", expected_type, typeof (var));
}

define expect_value (var, expected_value)
{
   if (var != expected_value)
     failed ("expected value `%S', but was `%S'", expected_value, var);
}

define expect_size (var, expected_size)
{
   if (typeof (var) == Assoc_Type)
     var = assoc_get_keys (var);
   variable len = length (var);
   if (len != expected_size)
     failed ("expected size %d, but was %d", expected_size, len);
}

define expect_assoc_key (assoc, key)
{
   ifnot (assoc_key_exists (assoc, key))
     failed (`expected assoc key "$key"`$);
}

define expect_assoc_key_value (assoc, key, expected_value)
{
   ifnot (assoc_key_exists (assoc, key))
     failed (`expected assoc key "$key"`$);
  else
     expect_value (assoc[key], expected_value);
}

private define descr (error)
{
   try
     throw error;
   catch error:
     return __get_exception_info().descr;
}

define expect_error(function, expected_error, expected_message);
define expect_error(function, expected_error, expected_message)
{
   if (typeof (function) == Array_Type)
     return array_map (&expect_error, function, expected_error, expected_message);

   variable expected_error_descr = sprintf ("`%s'", descr (expected_error));

   variable e;
   try (e)
     {
	@function();
	failed ("expected %S to throw %s, but did not occur", function, expected_error_descr);
     }
   catch expected_error:
     ifnot (string_match (e.message, expected_message))
       failed (`expected %S to throw %s with message matching "%s", but got "%s"`, function, expected_error_descr, expected_message, e.message);
   catch AnyError:
     failed (`expected %S to throw %s, but got %s "%s"`, function, expected_error_descr, e.descr, e.message);
}
