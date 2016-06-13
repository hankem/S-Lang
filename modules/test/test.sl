% These tests load the uninstalled version of slsh.rc.  The
% installation script appends code for SLSH_PATH processing.  Since
% the uninstalled version of slsh.rc lacks this code, it is added here.
prepend_to_slang_load_path(getenv("SLSH_PATH"));

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
   throw RunTimeError;
}

define end_test ()
{
   if (tests_failed)
     exit (tests_failed);

   () = fprintf(stdout, "OK\n");
   () = fflush (stdout);
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
   if (typeof (var) == Struct_Type)
     var = get_struct_field_names (var);
   variable len = length (var);
   if (len != expected_size)
     failed ("expected size %d, but was %d", expected_size, len);
}

define expect_assoc_key (assoc, key)
{
   expect_type (assoc, Assoc_Type);
   ifnot (assoc_key_exists (assoc, key))
     failed (`expected assoc key "$key"`$);
}

define expect_assoc_key_value (assoc, key, expected_value)
{
   expect_type (assoc, Assoc_Type);
   ifnot (assoc_key_exists (assoc, key))
     failed (`expected assoc key "$key"`$);
   else
     expect_value (assoc[key], expected_value);
}

define expect_struct_key (s, key)
{
   ifnot (is_struct_type (s))
     failed ("expected struct, but was %S", typeof (s));
   ifnot (any (get_struct_field_names(s) == key))
     failed (`expected struct key "$key"`$);
}

define expect_struct_field_names (s, expected_field_names)
{
   ifnot (is_struct_type (s))
     failed ("expected struct, but was %S", typeof (s));
   variable struct_field_names = get_struct_field_names (s);
   if (any (struct_field_names != expected_field_names))
     failed ("expected struct field names [%s], but got [%s]",
	     strjoin (expected_field_names, ", "),
	     strjoin (struct_field_names, ", "));
}

define expect_struct_key_value (s, key, expected_value)
{
   ifnot (any (get_struct_field_names(s) == key))
     failed (`expected struct key "$key"`$);
   else
     expect_value (get_struct_field (s, key), expected_value);
}

private define descr (error)
{
   try
     throw error;
   catch error:
     return __get_exception_info().descr;
}

define expect_error();
define expect_error(%expected_error, expected_message, function, [args...]
		                                                          )
{
   variable args = __pop_list (_NARGS-3);
   variable function = ();
   variable expected_message = ();
   variable expected_error = ();

   if (typeof (function) == Array_Type)
     return array_map (&expect_error, expected_error, expected_message, function, __push_list (args));

   variable expected_error_descr = sprintf ("`%s'", descr (expected_error));

   variable e;
   try (e)
     {
	@function(__push_list (args));
	failed ("expected %S to throw %s, but did not occur", function, expected_error_descr);
     }
   catch expected_error:
     ifnot (string_match (e.message, expected_message))
       failed (`expected %S to throw %s with message matching "%s", but got "%s"`, function, expected_error_descr, expected_message, e.message);
   catch AnyError:
     failed (`expected %S to throw %s, but got %s "%s"`, function, expected_error_descr, e.descr, e.message);
}

private variable Random_Number = _time ();
$1 = getenv ("SLSYSWRAP_RANDSEED");
if ($1 != NULL) Random_Number = typecast (atol($1), ULong_Type);

define urand_1 (x)
{
   Random_Number = typecast (Random_Number * 69069UL + 1013904243UL, UInt32_Type);
   return Random_Number/4294967296.0;
}
define urand (n)
{
   if (n == 0)
     return Double_Type[0];

   return array_map (Double_Type, &urand_1, [1:n]);
}

$1 = path_concat (path_dirname(__FILE__), "../objs");
set_import_module_path ($1);
if ($1 != get_import_module_path ())
{
   () = fprintf (stderr, "\n\n***WARNING: get_import_module_path ==> %S, expected %S\n\n",
		 get_import_module_path(), $1);
}


try
{
   import ("fofofof", "foobar");
}
catch ImportError;
