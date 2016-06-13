% -*- mode: slang; mode: fold -*-

() = evalfile ("./test.sl");

require ("socket");

define slsh_main ()
{
   testing_module ("socket");

   variable s;

   try
     {
	s = socket (PF_INET, SOCK_STREAM, 0);
     }
   catch SocketError:
     failed ("socket failed");

   if (-1 == close (s))
     failed ("close socket failed: %S", errno_string());

   end_test ();
}
