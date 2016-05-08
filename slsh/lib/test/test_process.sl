() = evalfile ("./common.sl");

require ("process");

private define pre_exec_hook (fdlist, optarg)
{
   putenv ("TEST_OPTARG=$optarg");
}

private define test_process ()
{
   % This is a silly example.  echo write to fd=12, which has stdout
   % dup'd to it.  wc reads from echo via fd=16, which has stdin dup'd
   % to it.
   variable echo = new_process (["echo", "foo bar"]; write=12, dup1=12,
				pre_exec_hook=&pre_exec_hook,
				pre_exec_hook_optarg="FOOBAR");

   variable wc = new_process ("wc"; write=10, dup1=10, fd16=echo.fd12, dup0=16);

   variable line;
   if (-1 == fgets (&line, wc.fp10))
     failed ("Failed to read from wc process: " + errno_string ());
   line = strcompress (line, " \t\n");
   if (line != "1 2 8")
     {
	failed ("Expected 1 2 8, got %s\n", line);
     }
   variable status = echo.wait ();
   if (status == NULL)
     failed ("wait method failed for echo");
   status = wc.wait ();
   if (status == NULL)
     failed ("wait method failed for echo");
}

define slsh_main ()
{
   start_test ("process");
   test_process ();
   end_test ();
}
