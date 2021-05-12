() = evalfile ("./common.sl");

require ("process");

private define pre_exec_hook2 (fdlist, optarg)
{
   putenv ("TEST_OPTARG=$optarg");
}

private define pre_exec_hook1(fdlist)
{
   return pre_exec_hook2 (fdlist, "unused");
}

#ifexists slcov_write_report
private variable Start_Dir = getcwd ();
private define exit_hook (argv, cd)
{
   variable file = path_concat (Start_Dir, sprintf ("%s-%d", cd, getpid()));
   slcov_write_report (fopen (file, "w"), 1);
}
private define exec_hook (argv, cd)
{
   variable file = path_concat (Start_Dir, sprintf ("%s-%d", cd, getpid()));
   slcov_write_report (fopen (file, "w"), 1);
   return execvp (argv[0], argv);
}

#endif

private define test_process ()
{
   % This is a silly example.  echo write to fd=12, which has stdout
   % dup'd to it.  wc reads from echo via fd=16, which has stdin dup'd
   % to it.
   variable echo = new_process (["echo", "foo bar"]; write=12, dup1=12,
				read={4,5,6,7},
				stdin="</dev/null",
				stdout=1,
#ifexists slcov_write_report
				exec_hook = &exec_hook,
				exec_hook_arg = "test_process.slcov",
#endif
				pre_exec_hook=&pre_exec_hook2,
				pre_exec_hook_optarg="FOOBAR");

   variable wc = new_process ("wc"; write=10, dup1=10, fd16=echo.fd12, dup0=16,
			      read=[3:9],
			      pre_exec_hook=&pre_exec_hook1,
#ifexists slcov_write_report
			      exec_hook = &exec_hook,
			      exec_hook_arg = "test_process.slcov",
#endif
			     );

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

   % Force an exception
   try
     {
	echo = new_process (["echo", "foo bar"];
			    stdout="/",
#ifexists slcov_write_report
			    exit_hook = &exit_hook,
			    exit_hook_arg = "test_process.slcov",
#endif
			   );
	failed ("failed to force an exception");
     }
   catch OSError;

   variable p = new_process (["pwd"]; dir="/", write=1,
#ifexists slcov_write_report
			     exec_hook = &exec_hook,
			     exec_hook_arg = "test_process.slcov",
#endif
			    );
   if (-1 == fgets (&line, p.fp1))
     failed ("Failed to read from pwd process: " + errno_string ());
   if ("/" != strtrim(line))
     failed ("Failed dir qualifier");
   p.wait (0);
}

define slsh_main ()
{
   start_test ("process");
   test_process ();
   end_test ();
}
