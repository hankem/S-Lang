% -*- mode: slang; mode: fold -*-

() = evalfile ("./test.sl");

require ("termios");

define slsh_main ()
{
   testing_module ("termios"); ()=fputs("(module loaded)...", stdout);
   end_test ();
}
