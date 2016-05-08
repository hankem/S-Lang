% -*- mode: slang; mode: fold -*-

() = evalfile ("./test.sl");

require ("select");

define slsh_main ()
{
   testing_module ("select"); ()=fputs("(module loaded)...", stdout);
   end_test ();
}
