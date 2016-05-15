() = evalfile ("inc.sl");

testing_feature ("proc");

private define test_getsetid_funcs ()
{
   variable func, funcp, i;
   foreach func (["getpid", "getppid", "getgid", "getegid",
	     "geteuid", "getuid", "getpgrp", "getsid"])
     {
	funcp = __get_reference (func);
	if (funcp == NULL)
	  continue;
	i = (@funcp)();
	if (typeof(i) != Int_Type)
	  failed ("%s did not return an integer", func);
     }

   variable pid = getpid ();

#ifexists setgid
   i = setgid (getgid ());
   if (typeof(i) != Int_Type)
     failed ("setgid did not return an integer");
#endif
#ifexists setpgid
   i = setpgid (pid, getpgid (0));
   if (typeof(i) != Int_Type)
     failed ("setpgid did not return an integer");
#endif
#ifexists setuid
   i = setuid (pid);
   if (typeof(i) != Int_Type)
     failed ("setuid did not return an integer");
#endif
#ifexists getsid
   i = getsid (pid);
   if (typeof(i) != Int_Type)
     failed ("getsid(pid) did not return an integer");
#endif
#ifexists setsid
   % Do not call it-- I do not want to create a new session.
#endif
}
test_getsetid_funcs ();

private define test_getsetpriority ()
{
#ifexists getpriority
   variable p = getpriority (PRIO_PROCESS, 0);
   if (p == NULL)
     failed ("getpriority failed: %S", errno_string());

   if (-1 == setpriority (PRIO_PROCESS, 0, p))
     failed ("setpriority failed: %S", errno_string());

   % Try to trigger an error to exercise that bit of code.
   () = getpriority (-1, -1);
   () = setpriority (-1, p-1, -10000);
#endif
}
test_getsetpriority ();

private define test_getrusage ()
{
   variable fields =
     {
	"ru_utimesecs",
	"ru_stimesecs",
	"ru_maxrss",
	"ru_minflt",
	"ru_majflt",
	"ru_inblock",
	"ru_oublock",
	"ru_nvcsw",
	"ru_nivcsw",
	"ru_ixrss",
	"ru_idrss",
	"ru_isrss",
	"ru_nswap",
	"ru_msgsnd",
	"ru_msgrcv",
	"ru_nsignals",
     };
#ifexists getrusage
   foreach ({
# ifexists RUSAGE_SELF
      RUSAGE_SELF,
# endif
# ifexists RUSAGE_CHILDREN
      RUSAGE_CHILDREN,
# endif
# ifexists RUSAGE_THREAD
      RUSAGE_THREAD,
# endif
   })
     {
	variable w = ();
	variable s = getrusage (w);
	if (s == NULL)
	  failed ("getrusage failed: %S", errno_string ());
	foreach (fields)
	  {
	     variable f = ();
	     try
	       {
		  () = get_struct_field (s, f);
	       }
	     catch InvalidParmError:
	       failed ("getrusage struct does not contain field %s", f);
	  }
     }
   % Try to trigger an error to exercise the error handling code
   () = getrusage (0x800);
#endif
}
test_getrusage ();

#ifexists killpg
if (typeof (killpg(0,0)) != Int_Type) failed ("killpg did not return an integer");
#endif

print ("Ok\n");

exit (0);

