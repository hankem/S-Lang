% -*- mode: slang; mode: fold -*-

() = evalfile ("./test.sl");

require ("fork");

private define test_fork ()
{
   variable _ppid = getpid ();
   variable pid = fork ();

   if (pid == 0)
     {
	% child
	if (_ppid == getpid ())
	  {
	     () = fprintf (stderr, "fork did not change pid\n");
	     _exit (1);
	  }

#ifexists getppid
	if (_ppid != getppid ())
	  {
	     () = fprintf (stderr, "getppid failed in child\n");
	     _exit (1);
	  }
#endif
	_exit(123);
     }

   variable w = waitpid (pid, 0);
   if (w.exited)
     {
	if (w.exit_status != 123)
	  failed ("child exited with unexpected status of %d", w.exit_status);
     }
}

private define test_pipe ()
{
   variable fdr, fdw, buf, n;
   (fdr, fdw) = pipe ();

   while (-1 == write (fdw, "hello"))
     {
	if (errno == EINTR)
	  continue;
	failed ("write to pipe failed: %S", errno_string);
     }
   n = read (fdr, &buf, 10);
   if ((buf != "hello") || (n != 5))
     {
	failed ("pipe failed");
     }
}

define slsh_main ()
{
   testing_module ("fork");
   test_fork ();
   test_pipe ();
   %test_exec ();
   end_test ();
}
