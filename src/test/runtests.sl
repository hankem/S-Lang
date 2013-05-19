#!/usr/bin/env slsh

define slsh_main ()
{
   if (__argc == 1)
     {
	vmessage (`Usage:
  %s TEST_SCRIPTS TEST_SCRIPTS_SLC
  where TEST_SCRIPTS     = test1.sl test2.sl ...
        TEST_SCRIPTS_SLC = test1.slc ...`, __argv[0]);
	return;
     }
   variable run_test_pgm = "./sltest";

   message(`
Running tests:`);
   variable failed = 0;
   variable test;
   foreach test (__argv[[1:]])
     {
	if (system ("$run_test_pgm $test"$))
	  failed++;
	if (system ("$run_test_pgm -utf8 $test"$))
	  failed++;
     }
   if (failed)
     vmessage ("%d tests failed", failed);
   else
     message ("All tests passed.");
   exit (failed);
}
