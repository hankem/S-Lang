() = evalfile ("./common.sl");

require ("print");

private define test_print (x)
{
   variable ref_x, file_x, fp_x, pager_x;

   % Wrie to a reference
   print (x, &ref_x);

   % Write to a named file
   variable file = sprintf ("/tmp/test_print_%X_%d", _time(), getpid());
   print (x, file);
   variable fp = fopen (file, "r");
   () = fread_bytes (&file_x, 2*strlen (ref_x), fp);
   () = fclose (fp);

   % Write to a file pointer
   fp = fopen (file, "wb");
   print (x, fp);
   () = fclose (fp);
   fp = fopen (file, "r");
   () = fread_bytes (&fp_x, 2*strlen (ref_x), fp);
   () = fclose (fp);

   % write to a pager
   print (x; pager="cat > $file"$);
   fp = fopen (file, "r");
   () = fread_bytes (&pager_x, 2*strlen (ref_x), fp);
   () = fclose (fp);

   () = remove (file);
   if ((ref_x != file_x) || (ref_x != fp_x) || (pager_x != file_x))
     {
	failed ("Failed: print failed to produce identical results\n");
     }
}

define slsh_main ()
{
   start_test ("print");
   % The test_print function cannot be used to print strings
   % since the print function treats strings differently depending
   % upon the device.
   test_print ([1:20:0.1]);
   test_print (_reshape ([1:20], [2,10]));
   test_print (_reshape ([1:20], [2,5,2]));
   test_print (struct {x = {}, y = [1:3], });
   test_print ([struct {x = {}, y = [1:3], }]);
   test_print ({struct {x = {}, y = [1:3], }});
   test_print (Int_Type);

   % For the use of a pager
   print_set_pager ("cat > /dev/null");
   print_set_pager_lines (0);

   print ("1\n\2\n\3\n");
   print ("1\n\2\0\n\3\n");
   print (struct {x = {1}, y = [1:3], });
   print ([struct {x = {2}, y = [1:3], }]);
   print ({struct {x = {3}, y = [1:3], z = "\0"B}});

   print_set_pager_lines (NULL);
   print (array_map (String_Type, &sprintf, "%d\n", [1:1000]));


   % Force an exception
   try
     {
	print ("x"; pager='x');
	failed ("Expected an invalid pager to produce an exception");
     }
   catch AnyError;

   end_test ();
}

