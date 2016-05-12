() = evalfile ("inc.sl");

testing_feature ("debugger support");
#ifnexists _set_frame_variable
print ("not implemented");
#stop
#endif

static define debug ()
{
   variable depth = 0;
   variable info;

   do
     {
	depth++;
	info = _get_frame_info (depth);
     }
   while (info.function != "fun0");
   _set_frame_variable (depth, "fun0_3", 3);
   if (_get_frame_variable (depth, "fun0_3") != 3)
     failed ("_get/set_frame_variable fun0_3");
}

static define fun2()
{
   if (_get_frame_depth () != 4)
     failed ("fun2 not at depth 4");
   variable foo = "zero";

   variable frame_info = _get_frame_info (0);
   if (length (frame_info.locals) != 2)
     failed ("length of frame_info");
   if (frame_info.function != "fun2")
     failed ("fun2: frame_info.function=%S", frame_info.function);
   if (frame_info.locals[1] != "frame_info")
     failed ("fun2: frame_info[1]=%S", frame_info.locals[1]);
   _set_frame_variable (0, "foo", 0);
   if (foo != 0)
     foo ("fun2: _set_frame_variable");
   if (0 != _get_frame_variable (0, "foo"))
     foo ("fun2: _get_frame_variable");
   debug();
}

static define fun1()
{
   if (_get_frame_depth () != 3)
     failed ("fun1 not at depth 3");
   fun2 ();
}
static define fun0()
{
   variable depth = _get_frame_depth ();
   if (_get_frame_depth () != 2)
     failed ("fun0 at depth %d, not at depth 2", depth);

   variable fun0_1 = "one";
   variable fun0_2 = "two";
   variable fun0_3 = "three";

   fun1 ();
   if (fun0_3 != 3)
     failed ("to set fun0_3");
}

fun0 ();

#ifneval (path_extname (__argv[-1]) == ".slc")

_bofeof_info = 1;
_boseos_info = 3;
private define debug_me ()
{
   () = 1;
   () = 2;
   return 3;
}
_boseos_info = 0;
_bofeof_info = 0;

private variable Statement_Count0, Statement_Count1;
private variable Function_Count0, Function_Count1;
private define bos_handler (file, line)
{
   Statement_Count0++;
}
private define eos_handler ()
{
   Statement_Count1++;
}
private define bof_handler (fun, file)
{
   if (fun != "debug_me")
     failed ("count_funcs: unexpected function %S",fun);
   Function_Count0++;
}
private define eof_handler ()
{
   Function_Count1++;
}

private variable Debug_Hook_Called = 0;
private define debug_hook (file, line)
{
   Debug_Hook_Called++;
}

private define test_handlers ()
{
   Debug_Hook_Called = 0;
   () = _set_debug_hook (&debug_hook);

   () = _set_bos_handler (&bos_handler);
   () = _set_eos_handler (&eos_handler);
   () = _set_bof_handler (&bof_handler);
   () = _set_eof_handler (&eof_handler);
   Statement_Count0 = 0; Statement_Count1 = 0;
   Function_Count0 = 0; Function_Count1 = 0;
   variable s = debug_me() + debug_me () + debug_me () + debug_me ();
   if (Function_Count0 != 4)
     failed ("bof_handler produced %d, expected 4", Function_Count0);
   if (Statement_Count0 != s)
     failed ("bos_handler produced %d, expected %d", Statement_Count0, s);
   if (Function_Count1 != 4)
     failed ("eof_handler produced %d, expected 4", Function_Count1);
   if (Statement_Count1 != s)
     failed ("eos_handler produced %d, expected %d", Statement_Count1, s);

   % Trigger a bad handler
   if (&eof_handler != _set_eof_handler (&bos_handler))
     failed ("_set_eof_handler returned incorrect value");

   if (Debug_Hook_Called)
     failed ("Did not expect the debug hook to be called");

   variable bad = 1;
   try
     {
	() = debug_me();
     }
   catch AnyError: bad = 0;
   if (bad)
     failed ("Expected a malformed eof_handler to produce an error");
   % Check to see the handler was deactivated
   if (NULL != _set_eof_handler (&eof_handler))
     failed ("Expected _set_eof_handler to return NULL");

   if (&eos_handler != _set_eos_handler (&bos_handler))
     failed ("_set_eos_handler returned incorrect value");
   bad = 1;
   try
     {
	() = debug_me();
     }
   catch AnyError: bad = 0;
   if (bad)
     failed ("Expected a malformed eos_handler to produce an error");
   if (NULL != _set_eos_handler (&eos_handler))
     failed ("Expected _set_eos_handler to return NULL");

   if (Debug_Hook_Called == 0)
     failed ("debug hook did not trigger");
   if (&debug_hook != _set_debug_hook (NULL))
     failed ("_set_debug_hook returned non-NULL");
}
test_handlers ();

#endif				       %  ifndef .slc

print ("Ok\n");

exit (0);

