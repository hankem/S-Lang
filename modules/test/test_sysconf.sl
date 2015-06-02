() = evalfile ("./test.sl");
require ("sysconf");

define slsh_main ()
{
   variable names = sysconf_names (), name, val;

   foreach name (names)
     {
	val = sysconf (name);
     }
   if (7 != sysconf ("FOOBAR_BAZ", 7))
     failed ("sysconf FOOBAR_BAZ with default");

   names = pathconf_names ();

   variable fd = fileno (stdin);
   foreach name (names)
     {
	val = pathconf (stdin, name);
	val = pathconf (fd, name);
	val = pathconf ("/", name);
	%vmessage ("%S=%S", name, val);
     }

   names = confstr_names ();
   foreach name (names)
     {
	val = confstr (name);
     }
   if ("xxyyzz" != confstr ("FOOBAR_BAZ", "xxyyzz"))
     failed ("confstr FOOBAR_BAZ with default");
}

