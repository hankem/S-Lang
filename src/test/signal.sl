() = evalfile ("inc.sl");

testing_feature ("signals\n");

private variable Signal = 0;

private define handle_hup (sig)
{
   Signal = sig;
}

private define test_signal (sig, func, old_func)
{
   variable old;
   signal (sig, func, &old);
   if (_eqs (old, old_func))
     return;
   failed ("signal ($sig,$func,$old_func), got $old"$);
}

test_signal (SIGHUP, &handle_hup, SIG_DFL);
test_signal (SIGHUP, SIG_APP, &handle_hup);
test_signal (SIGHUP, SIG_DFL, SIG_DFL);
test_signal (SIGHUP, SIG_IGN, SIG_DFL);
test_signal (SIGHUP, &handle_hup, SIG_IGN);

private define test_signal (sig, func)
{
   Signal = 0;
   signal (sig, func);
   () = kill (getpid (), sig);
   variable count = 10;
   while (count and (Signal == 0))
     {
	sleep (1);
	count--;
     }
   if (Signal != sig)
     failed ("signal %d not caught, count=%d", sig, count);
}
test_signal (SIGHUP, &handle_hup);

private define sigalrm_handler (sig)
{
   if (sig != SIGALRM)
     failed ("alarm");
   throw MathError;
}
signal (SIGALRM, &sigalrm_handler);

private define test_sigalarm ()
{
   print ("\tPausing for 2 seconds for alarm test");
   alarm (2);
   try
     {
	while (1)
	  {
	     sleep (1);
	     print (".");
	  }
     }
   catch MathError;
   print ("\n");
}

private define test_getsetitimer ()
{
#ifexists setitimer
   % check syntax
   signal (SIGALRM, SIG_IGN);
   variable interval = 10.0, value = 3.1, old_interval, old_value;
   setitimer (ITIMER_REAL, value, interval);
   setitimer (ITIMER_REAL, value, interval, &old_value, &old_interval);
   if (abs (old_interval-interval) > 0.1)   %  adjust for timer resolution
     failed ("setitimer: unexpected old interval");
   (old_value, old_interval) = getitimer (ITIMER_REAL);
   if (abs (old_interval-interval) > 0.1)   %  adjust for timer resolution
     failed ("getitimer: unexpected old interval");

   setitimer (ITIMER_REAL, interval, value, &old_interval);

   signal (SIGALRM, &sigalrm_handler);
   print ("\tPausing for 2.5 seconds for setitimer test");
   setitimer (ITIMER_REAL, 2.5, 2.5);
   try
     {
	while (1)
	  {
	     sleep (1);
	     print (".");
	  }
     }
   catch MathError:
     {
	setitimer (ITIMER_REAL, 0);
     }
   print ("\n");
#endif
}

private define sigint_handler (sig)
{
   if (sig != SIGINT)
     failed ("sigint_handler");
   throw UserBreakError;
}

private define test_sigsuspend ()
{
   if (NULL != getenv ("MAKERUNNING"))
     {
	print ("\t(make detected: skipping test_sigsuspend)\n");
	return;
     }

   signal (SIGINT, &sigint_handler);
   print ("\tNow try pressing ^C in next 5 seconds...");
   alarm (5);
   try
     sigsuspend ([SIGINT, SIGTSTP]);
   catch UserBreakError;
   catch MathError;
   print ("\n");
}

private define test_sigprocmask ()
{
   variable oldmask, origmask;
   sigprocmask (SIG_SETMASK, SIGHUP, &origmask);
   sigprocmask (SIG_BLOCK, SIGINT, &oldmask);

   if (orelse
       {length (oldmask) != 1}
       {oldmask[0] != SIGHUP})
     failed ("sigprocmask: expected to see SIGHUP in the mask");

   sigprocmask (SIG_UNBLOCK, SIGHUP, &oldmask);
   if (orelse
       {length (oldmask) != 2}
       {(0 == length (where (oldmask == SIGHUP)))}
       {(0 == length (where (oldmask == SIGINT)))})
     failed ("sigprocmask: expected to see SIGINT and SIGHUP in the mask");

   sigprocmask (SIG_SETMASK, origmask, &oldmask);
   if (orelse
       {length (oldmask) != 1}
       {oldmask[0] != SIGINT})
     failed ("sigprocmask: expected to see SIGINT in the mask");
}

$1 = getenv ("SLSYSWRAP_TEST");

if (($1 == NULL) || (atoi ($1) == 0))
{
   test_sigalarm ();
   test_getsetitimer ();
   test_sigsuspend ();
}

test_sigprocmask ();

% Interrupts are tiggered by signals that interrupt system calls.
% These tests here are design to exercise that library interrupt hook
% data structures.
private variable Interrupt_Hook_A_Fired = 0;
private variable Interrupt_Hook_B_Fired = 0;
private define interrupt_hook_a ()
{
   Interrupt_Hook_A_Fired = 1;
   return 0;
}

private define interrupt_hook_b ()
{
   Interrupt_Hook_B_Fired = 1;
   return 0;
}

private define add_interrupt_hooks ()
{
   sltest_add_interrupt_hook (&interrupt_hook_a);
   sltest_add_interrupt_hook (&interrupt_hook_b);
   sltest_add_interrupt_hook (&interrupt_hook_a);
}

private define remove_interrupt_hooks ()
{
   sltest_remove_interrupt_hook (&interrupt_hook_a);
   sltest_remove_interrupt_hook (&interrupt_hook_b);
   sltest_remove_interrupt_hook (&interrupt_hook_a);
}

private define test_interrupts ()
{
   add_interrupt_hooks ();

   () = sltest_invoke_interrupts ();

   ifnot (Interrupt_Hook_A_Fired && Interrupt_Hook_B_Fired)
     failed ("Interrupt_Hooks were not activated");

   remove_interrupt_hooks ();
}
test_interrupts ();

print ("Ok\n");

exit (0);

