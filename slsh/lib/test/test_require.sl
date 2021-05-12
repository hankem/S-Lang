() = evalfile ("./common.sl");

require ("./common.sl", "r");
require ("common", "s", "./common.sl");

define slsh_main ()
{
   try
     {
	r->start_test ("require");
	s->end_test ();
	exit (0);
     }
   catch AnyError:
     {
	failed ("require");
     }
   end_test ();
}

