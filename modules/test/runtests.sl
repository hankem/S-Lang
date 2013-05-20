#!/usr/bin/env slsh

private variable run_test_pgm = "slsh";

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
  %s test1.sl test2.sl ...`, __argv[0]);
        return;
     }

   message ("\nRunning module tests:\n");
   variable test;
   foreach test (__argv[[1:]])
     run_test ("$run_test_pgm $test"$);

   message (failed ? "$failed tests failed!!!"$ : "All tests passed.");
   exit (failed);
}
