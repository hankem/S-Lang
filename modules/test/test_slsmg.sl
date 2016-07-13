() = evalfile ("./test.sl");

% TODO:
% The test plan is to write output to a file and compare that output to a
% validated output file.  Such a test cannot rely upon using a system
% provided terminfo database, which could vary from system to system.
% As such, a TERMCAP environment variable will be used.

try
{
   if (NULL == getenv("TERM"))
     {
	() = fprintf (stderr, "TERM environment variable not set--- slsmg-module test not performed\n");
	exit (0);
     }
#if$TERM unknown
   () = fprintf (stderr, "TERM is unknown-- slsmg-module not tested\n");
   exit (0);
#endif
   require ("slsmg");
}
catch ImportError:
{
   () = fprintf (stderr, "slsmg-module not available.  Test not performed\n");
   exit (1);
}

private define test_smg ()
{
   slsmg_init_smg ();
   slsmg_refresh ();
   variable line;
   () = fgets (&line, stdin);
   slsmg_reset_smg ();
}

define slsh_main ()
{
   testing_module ("slsmg"); ()=fputs("(module loaded)...", stdout);
   %test_smg ();
   end_test ();
}
