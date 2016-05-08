% -*- mode: slang; mode: fold -*-

() = evalfile ("./test.sl");

require ("socket");

define slsh_main ()
{
   testing_module ("socket"); ()=fputs("(module loaded)...", stdout);
   end_test ();
}
