() = evalfile("./test.sl");
require ("zlib");

private define silly_deflate (z, str)
{
   variable x = "";
   foreach (str)
     {
	variable ch = ();
	x = x + z.deflate (pack("C", ch); flush=ZLIB_NO_FLUSH);
     }
   x = x + z.flush ();
   return x;
}

private define silly_inflate (z, zstr)
{
   variable x = "";
   foreach (zstr)
     {
	variable ch = ();
	x = x + z.inflate(pack("C", ch); flush=ZLIB_NO_FLUSH);
     }
   x = x + z.flush ();
   return x;
}

define test_zlib (str0)
{
   variable zstr = zlib_deflate (str0);
   variable str1 = zlib_inflate (zstr);
   if (str1 != str0)
     {
	failed ("to deflate/inflate %s", str0);
	return;
     }

   variable z = zlib_deflate_new ();
   variable zstr1 = silly_deflate (z, str0);
   if (zstr1 != zstr)
     {
	failed ("to deflate %s via multiple calls", str0);
	return;
     }
   % Repeat using the same object
   z.reset ();
   zstr1 = silly_deflate (z, str0);
   if (zstr1 != zstr)
     {
	failed ("to deflate %s via multiple calls", str0);
	return;
     }

   z = zlib_inflate_new ();
   str1 = silly_inflate (z, zstr1);
   if (str1 != str0)
     {
	failed ("to inflate %s via multiple calls", str0);
	return;
     }
   % Repeat using the same object
   z.reset ();
   str1 = silly_inflate (z, zstr1);
   if (str1 != str0)
     {
	failed ("to inflate %s via multiple calls", str0);
	return;
     }
}

private define check_usage ()
{
   foreach (["zlib_inflate()", "zlib_deflate()",
	     "zlib_inflate_new().inflate()",
	     "(@zlib_inflate_new().flush)()",
	     "zlib_deflate_new().deflate()",
	     "(@zlib_deflate_new().flush)()",
	     ])
     {
	variable f = ();
	try
	  {
	     eval (f);
	     failed ("%s usage", f);
	  }
	catch UsageError;
     }
}

define slsh_main ()
{
   testing_module ("zlib");

   check_usage ();
   test_zlib ("");
   test_zlib ("\0");
   test_zlib ("\0\0\0");
   test_zlib ("A");
   test_zlib ("AA");
   test_zlib ("AAA");
   test_zlib ("AAAAAAAA");
   test_zlib ("AAAAAAAABBBBBBB");
   test_zlib ("AAAAAAAABBBBBBBAAAAAAA");
   test_zlib ("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
   test_zlib ("ABCDEFGHIJKLMNOPQRSTUVWXYZ\0");
   test_zlib ("\0ABCDEFGHIJKLMNOPQRSTUVWXYZ\0");

   end_test ();
}
