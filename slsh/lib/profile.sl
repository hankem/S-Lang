% See the slprof script for an example of using the profiler.
%
_boseos_info=0;
_bofeof_info=0;

private variable Counts = Assoc_Type[Int_Type, 0];
private variable Child_Counts = Assoc_Type[Int_Type, 0];
private variable Times = Assoc_Type[Double_Type, 0.0];
private variable Stack_Depth = 0;
private variable Times_Stack = Double_Type[4096];
private variable Lines_Stack = String_Type[4096];
private variable Counts_Stack = Int_Type[4096];

private variable Num_Counts;
private variable Overhead_Per_Call = 0.0;
private variable Error_Per_Call = 0.0;

private define bos_handler (file, line)
{
   variable s = Stack_Depth;
   Stack_Depth++;
   file = sprintf ("%s:%d", file, line);
   Counts[file] += 1;
   Lines_Stack[s] = file;
   Counts_Stack[s] = Num_Counts;
   Num_Counts++;
   Times_Stack[s] = toc();
}

private define eos_handler ()
{
   variable t = toc();
   Stack_Depth--;
   variable file = Lines_Stack[Stack_Depth];
#iffalse
   Times[file] += (t - Times_Stack[Stack_Depth] - Error_Per_Call)
     - Overhead_Per_Call * ((Num_Counts-1) - Counts_Stack[Stack_Depth]);
#else
   Times[file] += (t - Times_Stack[Stack_Depth]);
#endif
   Child_Counts[file] += (Num_Counts-Counts_Stack[Stack_Depth]) - 1;
}

private define bof_handler (fun, file)
{
   variable s = Stack_Depth;
   Stack_Depth++;
   file = sprintf ("%S:%S", file, fun);
   Counts[file] += 1;
   Lines_Stack[s] = file;
   Counts_Stack[s] = Num_Counts;
   Num_Counts++;
   Times_Stack[s] = toc();
}

private define eof_handler ()
{
   variable t = toc();
   Stack_Depth--;
   variable file = Lines_Stack[Stack_Depth];
   Times[file] += (t - Times_Stack[Stack_Depth]);
   Child_Counts[file] += (Num_Counts-Counts_Stack[Stack_Depth]) - 1;
}

define profile_on (fun)
{
   if (fun)
     {
	_boseos_info = 0;
	_bofeof_info = 1;
     }
   else
     {
	_boseos_info = 3;
	_bofeof_info = 0;
     }
}

define profile_off ()
{
   _boseos_info = 0;
}

define profile_begin ()
{
   ()=_set_bos_handler (&bos_handler);
   ()=_set_eos_handler (&eos_handler);
   ()=_set_bof_handler (&bof_handler);
   ()=_set_eof_handler (&eof_handler);
   Stack_Depth = 0;
   Times = Assoc_Type[Double_Type, 0.0];
   Counts = Assoc_Type[Int_Type, 0];
   Child_Counts = Assoc_Type[Int_Type, 0];
   Counts_Stack = Int_Type[4096];
   Num_Counts = 0;
   _boseos_info = 3;
   tic ();
}

define profile_end ()
{
   ()=_set_bos_handler (NULL);
   ()=_set_eos_handler (NULL);
   ()=_set_bof_handler (NULL);
   ()=_set_eof_handler (NULL);
   profile_off ();
}

profile_off ();
private define calibrate_fun_0 (n)
{
   loop (n) 
     {
	() = 1;	() = 1;	() = 1;	() = 1; () = 1;
     }
}

profile_on (0);
private define calibrate_fun_1 (n)
{
   loop (n) 
     {
	() = 1;	() = 1;	() = 1;	() = 1; () = 1;
     }
}
profile_off ();

#ifnexists sum
private define sum (x)
{
   variable s = 0.0;
   foreach (x) s += ();
   return s;
}
#endif

define profile_calibrate ()
{
   if (_NARGS == 0) 1000;
   variable n1 = ();
   variable n0 = 1000*n1;
   
   Overhead_Per_Call = 0.0;
   Error_Per_Call = 0.0;
   tic();
   calibrate_fun_0 (n0);
   variable t0 = toc;
   variable t_expected = ((t0*n1)/n0);
   
   profile_begin ();
   tic ();
   calibrate_fun_1 (n1);
   variable t_elapsed = toc ();
   profile_end ();
   variable num_calls = sum (assoc_get_values (Counts));
   variable t_obs = sum(assoc_get_values(Times));
   Error_Per_Call = (t_obs - t_expected)/num_calls;
   Overhead_Per_Call = (t_elapsed-t_expected)/num_calls;
}

define profile_report (fp)
{
   if (typeof (fp) == String_Type)
     fp = fopen (fp, "w");

   variable key;
   % When the profiler is turned off, the last statement profiled will not
   % have executed its EOS hook.  So remove that statement.
   foreach (assoc_get_keys (Counts))
     {
	key = ();
	if (0 == assoc_key_exists (Times, key))
	  assoc_delete_key (Counts, key);
     }
   
   variable keys = assoc_get_keys (Times);
   variable n = length (keys);
   variable times = Double_Type[n];
   variable ncalls = Int_Type[n];
   variable childcalls = Int_Type[n];
   variable i;
   _for i (0, n-1, 1)
     {
	key = keys[i];
	times[i] = Times[key];
	ncalls[i] = Counts[key];
	childcalls[i] = Child_Counts[key];
     }

   times -= Error_Per_Call * ncalls + Overhead_Per_Call*childcalls;
   variable rates = times/ncalls;

   i = array_sort (times);
   i = i[[-1::-1]];

   times = times[i];
   rates = rates[i];
   keys = keys[i];
   childcalls = childcalls[i];
   ncalls = ncalls[i];

   variable total_counts = sum(ncalls);
   () = fprintf (fp, "#Total Calls: %g, Profiler overhead: %g secs\n\n", 
		 total_counts, Overhead_Per_Call * total_counts);

   () = fprintf (fp, "#NCalls   msecs/Call     Tot Secs #ChildCalls File:line\n");

   _for i (0, n-1, 1)
     {
	key = keys[i];
	() = fprintf (fp, "%7d %12.5f %12.5f %7d %s\n", 
		      ncalls[i], rates[i]*1e3, times[i], childcalls[i], key);
     }
}
	
provide ("profile");
