#!/usr/bin/env slsh

private variable run_test_pgm = "./sltest";

private variable failed = 0;

define run_test (cmd)
{
   if (system (cmd))
     failed++;
}

define slsh_main ()
{
   if (__argc == 1)
     {
	vmessage (`Usage:
  %s TEST_SCRIPTS TEST_SCRIPTS_SLC API_TESTS
  where TEST_SCRIPTS     = test1.sl test2.sl ...
        TEST_SCRIPTS_SLC = test1.slc ...
        API_TESTS        = ctest1 ctest2 ...`, __argv[0]);
	return;
     }

   message(`
Running tests:`);
   variable test;
   foreach test (__argv[[1:]])
     if (string_matches (test, `\.slc?$`) != NULL)
       {
	  run_test ("$run_test_pgm $test"$);
	  run_test ("$run_test_pgm -utf8 $test"$);
       }
     else
       {
	  run_test ("./$test"$);
       }

   message (failed ? "$failed tests failed!!!"$ : "All tests passed.");
   exit (failed);
}
